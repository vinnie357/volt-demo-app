terraform {
  required_providers {
    volterra = {
      source = "volterraedge/volterra"
      version = "0.6.0"
    }
  }
}

provider "volterra" {
  api_p12_file = var.api_p12_file
  url          = var.api_url
}

resource "volterra_namespace" "ns" {
  name = var.base
}

//Consistency issue with provider response for NS resource
//https://github.com/volterraedge/terraform-provider-volterra/issues/53
resource "time_sleep" "ns_wait" {
  depends_on = [volterra_namespace.ns]
  create_duration = "5s"
}

resource "volterra_virtual_site" "vs" {
  name      = format("%s-vs", volterra_namespace.ns.name)
  namespace = volterra_namespace.ns.name
  depends_on = [time_sleep.ns_wait]

  site_selector {
    expressions = var.vs_site_selector
  }
  site_type = "REGIONAL_EDGE"
}

resource "volterra_virtual_k8s" "vk8s" {
  name      = format("%s-vk8s", volterra_namespace.ns.name)
  namespace = volterra_namespace.ns.name
  depends_on = [time_sleep.ns_wait]

  vsite_refs {
    name      = volterra_virtual_site.vs.name
    namespace = volterra_namespace.ns.name
  }
}

//Consistency issue with vk8s resource response
//https://github.com/volterraedge/terraform-provider-volterra/issues/54
resource "time_sleep" "vk8s_wait" {
  depends_on = [volterra_virtual_k8s.vk8s]
  create_duration = "90s"
}

resource "volterra_api_credential" "cred" {
  name      = format("%s-api-cred", var.base)
  api_credential_type = "KUBE_CONFIG"
  virtual_k8s_namespace = volterra_namespace.ns.name
  virtual_k8s_name = volterra_virtual_k8s.vk8s.name
  depends_on = [time_sleep.vk8s_wait]
}

resource "local_file" "kubeconfig" {
    content = base64decode(volterra_api_credential.cred.data)
    filename = "${path.module}/../../creds/vk8s.yaml"
}

resource "volterra_app_type" "at" {
  name      = format("%s-app-type", var.base)
  namespace = "shared"
  features = [
    "BUSINESS_LOGIC_MARKUP",
    "USER_BEHAVIOR_ANALYSIS",
    "PER_REQ_ANOMALY_DETECTION",
    "TIMESERIES_ANOMALY_DETECTION"
  ]
}

resource "volterra_origin_pool" "op" {
  name                   = format("%s-server", var.base)
  namespace              = volterra_namespace.ns.name
  depends_on             = [time_sleep.ns_wait]
  description            = format("Origin pool pointing to frontend k8s service running on vsite")
  loadbalancer_algorithm = "ROUND ROBIN"
  origin_servers {
    k8s_service {
      inside_network  = false
      outside_network = false
      vk8s_networks   = true
      service_name    = format("frontend.%s", volterra_namespace.ns.name)
      site_locator {
        virtual_site {
          name      = volterra_virtual_site.vs.name
          namespace = volterra_namespace.ns.name
        }
      }
    }
  }
  port               = 80
  no_tls             = true
  endpoint_selection = "LOCAL_PREFERRED"
}

resource "volterra_waf" "waf" {
  name        = format("%s-waf", var.base)
  description = format("WAF in block mode for %s", var.base)
  namespace   = volterra_namespace.ns.name
  depends_on = [time_sleep.ns_wait]
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

resource "volterra_http_loadbalancer" "lb" {
  name                            = format("%s-lb", var.base)
  namespace                       = volterra_namespace.ns.name
  depends_on                      = [time_sleep.ns_wait]
  description                     = format("HTTPS loadbalancer object for %s origin server", var.base)
  domains                         = [var.app_fqdn]
  advertise_on_public_default_vip = true
  default_route_pools {
    pool {
      name      = volterra_origin_pool.op.name
      namespace = volterra_namespace.ns.name
    }
  }
  https_auto_cert {
    add_hsts      = false
    http_redirect = true
    no_mtls       = true
  }
  waf {
    name      = volterra_waf.waf.name
    namespace = volterra_namespace.ns.name
  }
  disable_waf                     = false
  disable_rate_limit              = true
  round_robin                     = true
  service_policies_from_namespace = true
  no_challenge                    = true
}