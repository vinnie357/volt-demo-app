variable "namespace" {
  description = "your namespace in the tenant where you have rights for vk8s"
}
variable "create_namespace" {
  description = "if we should create your namespace or not"
}
variable "app_fqdn" {
  description = "the requested fqdn for your example application"
}

variable "api_url" {
  description = "the api end point of your volterra subscription [tenant].ves.volterra.io/api"
}

variable "api_p12_file" {
  description = "the local file path to your api-cert in .p12 format"
}

variable "main_site_selector" {
  description = "the regional edges to deploy your services in"
}

variable "state_site_selector" {
  description = "the regional edges to store your state in"
}
