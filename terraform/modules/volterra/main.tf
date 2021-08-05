terraform {
  required_providers {
    volterra = {
      source  = "volterraedge/volterra"
      version = "0.8.1"
    }
  }
}

provider "volterra" {
  api_p12_file = var.api_p12_file
  url          = var.api_url
}

locals {
  default_namespace = var.create_namespace ? volterra_namespace.ns[0] : data.volterra_namespace.ns[0]
}

resource "volterra_namespace" "ns" {
  count = var.create_namespace ? 1 : 0
  name  = var.namespace
}

data "volterra_namespace" "ns" {
  count = var.create_namespace ? 0 : 1
  name  = var.namespace
}

//Consistency issue with provider response for NS resource
//https://github.com/volterraedge/terraform-provider-volterra/issues/53
resource "time_sleep" "ns_wait" {
  depends_on      = [local.default_namespace]
  create_duration = "5s"
}

resource "volterra_virtual_site" "main" {
  name       = format("%s-vs", local.default_namespace.name)
  namespace  = local.default_namespace.name
  depends_on = [time_sleep.ns_wait]

  site_selector {
    expressions = var.main_site_selector
  }
  site_type = "REGIONAL_EDGE"
}

resource "volterra_virtual_site" "state" {
  name       = format("%s-state", local.default_namespace.name)
  namespace  = local.default_namespace.name
  depends_on = [time_sleep.ns_wait]

  site_selector {
    expressions = var.state_site_selector
  }
  site_type = "REGIONAL_EDGE"
}

resource "volterra_virtual_k8s" "vk8s" {
  name       = format("%s-vk8s", local.default_namespace.name)
  namespace  = local.default_namespace.name
  depends_on = [time_sleep.ns_wait]

  vsite_refs {
    name      = volterra_virtual_site.main.name
    namespace = local.default_namespace.name
  }
  vsite_refs {
    name      = volterra_virtual_site.state.name
    namespace = local.default_namespace.name
  }
}

//Consistency issue with vk8s resource response
//https://github.com/volterraedge/terraform-provider-volterra/issues/54
resource "time_sleep" "vk8s_wait" {
  depends_on      = [volterra_virtual_k8s.vk8s]
  create_duration = "90s"
}

resource "volterra_api_credential" "cred" {
  name                  = format("%s-api-cred", var.namespace)
  api_credential_type   = "KUBE_CONFIG"
  virtual_k8s_namespace = local.default_namespace.name
  virtual_k8s_name      = volterra_virtual_k8s.vk8s.name
  depends_on            = [time_sleep.vk8s_wait]
}

resource "local_file" "kubeconfig" {
  content  = base64decode(volterra_api_credential.cred.data)
  filename = format("%s/../../creds/%s", path.module, format("%s-vk8s.yaml", terraform.workspace))
}

resource "volterra_app_type" "at" {
  // This naming simplifies the 'mesh' cards
  name      = var.namespace
  namespace = "shared"
  features {
    type = "BUSINESS_LOGIC_MARKUP"
  }
  features {
    type = "USER_BEHAVIOR_ANALYSIS"
  }
  features {
    type = "PER_REQ_ANOMALY_DETECTION"
  }
  features {
    type = "TIMESERIES_ANOMALY_DETECTION"
  }
  business_logic_markup_setting {
    enable = true
  }
}

resource "volterra_origin_pool" "frontend" {
  name                   = format("%s-frontend", var.namespace)
  namespace              = local.default_namespace.name
  depends_on             = [time_sleep.ns_wait]
  description            = format("Origin pool pointing to frontend k8s service running in main-vsite")
  loadbalancer_algorithm = "ROUND ROBIN"
  origin_servers {
    k8s_service {
      inside_network  = false
      outside_network = false
      vk8s_networks   = true
      service_name    = format("frontend.%s", local.default_namespace.name)
      site_locator {
        virtual_site {
          name      = volterra_virtual_site.main.name
          namespace = local.default_namespace.name
        }
      }
    }
  }
  port               = 80
  no_tls             = true
  endpoint_selection = "LOCAL_PREFERRED"
}

resource "volterra_origin_pool" "redis" {
  name                   = format("%s-redis", var.namespace)
  namespace              = local.default_namespace.name
  depends_on             = [time_sleep.ns_wait]
  description            = format("Origin pool pointing to redis k8s service running in state-vsite")
  loadbalancer_algorithm = "ROUND ROBIN"
  origin_servers {
    k8s_service {
      inside_network  = false
      outside_network = false
      vk8s_networks   = true
      service_name    = format("redis-cart.%s", local.default_namespace.name)
      site_locator {
        virtual_site {
          name      = volterra_virtual_site.state.name
          namespace = local.default_namespace.name
        }
      }
    }
  }
  port               = 6379
  no_tls             = true
  endpoint_selection = "LOCAL_PREFERRED"
}

resource "volterra_waf" "waf" {
  name        = format("%s-waf", var.namespace)
  description = format("WAF in block mode for %s", var.namespace)
  namespace   = local.default_namespace.name
  depends_on  = [time_sleep.ns_wait]
  app_profile {
    cms       = []
    language  = []
    webserver = []
  }
  mode = "BLOCK"
  lifecycle {
    ignore_changes = [
      app_profile
    ]
  }
}

resource "volterra_http_loadbalancer" "frontend" {
  name                            = format("%s-fe", var.namespace)
  namespace                       = local.default_namespace.name
  depends_on                      = [time_sleep.ns_wait]
  description                     = format("HTTPS loadbalancer object for %s origin server", var.namespace)
  domains                         = [var.app_fqdn]
  advertise_on_public_default_vip = true
  labels                          = { "ves.io/app_type" = volterra_app_type.at.name }
  default_route_pools {
    pool {
      name      = volterra_origin_pool.frontend.name
      namespace = local.default_namespace.name
    }
  }
  https_auto_cert {
    add_hsts      = false
    http_redirect = true
    no_mtls       = true
  }
  waf {
    name      = volterra_waf.waf.name
    namespace = local.default_namespace.name
  }
  disable_waf                     = false
  disable_rate_limit              = true
  round_robin                     = true
  service_policies_from_namespace = true
  no_challenge                    = true
}

resource "volterra_tcp_loadbalancer" "redis" {
  name                 = format("%s-redis", var.namespace)
  namespace            = local.default_namespace.name
  depends_on           = [time_sleep.ns_wait]
  description          = format("TCP loadbalancer object for %s redis service", var.namespace)
  domains              = ["redis-cart.internal"]
  dns_volterra_managed = false
  listen_port          = 6379
  origin_pools_weights {
    pool {
      name      = volterra_origin_pool.redis.name
      namespace = local.default_namespace.name
    }
  }
  advertise_custom {
    advertise_where {
      vk8s_service {
        virtual_site {
          name      = volterra_virtual_site.main.name
          namespace = local.default_namespace.name
        }
      }
      port = 6379
    }
  }
  retract_cluster                = true
  hash_policy_choice_round_robin = true
}
