variable "namespace" {
  description = "your namespace in the tenant where you have rights for vk8s"
  default     = "demo-app"
}
variable "create_namespace" {
  description = "if we should create your namespace or not"
  default     = false
}
variable "app_fqdn" {
  description = "the requested fqdn for your example application"
  default     = "demo-app.tenant.example.com"
}

variable "api_url" {
  description = "the api end point of your volterra subscription [tenant].ves.volterra.io/api"
  default     = "https://tenant.ves.volterra.io/api"
}

variable "api_p12_file" {
  description = "the local file path to your api-cert in .p12 format"
  default     = "./creds/tenant.api-creds.p12"
}

variable "main_site_selector" {
  description = "the regional edges to deploy your services in"
  default     = ["ves.io/siteName in (ves-io-ny8-nyc, ves-io-wes-sea)"]
}

variable "state_site_selector" {
  description = "the regional edges to store your state in"
  default     = ["ves.io/siteName in (ves-io-dc12-ash)"]
}

variable "registry_password" {
  default = "2string:///some_b64e_password"
}

variable "registry_username" {
  default = "some_user"
}

variable "registry_server" {
  default = "some_registry.example.com"
}
