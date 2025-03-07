namespace          = "demo-app"
create_namespace   = true
app_fqdn           = "test-shop.tenant.example.com"
api_url            = "https://tenant.console.ves.volterra.io/api"
api_p12_file       = "./creds/tenant.api-creds.p12"
main_site_selector = ["ves.io/siteName in (ves-io-ny8-nyc, ves-io-wes-sea)"]

registry_password = "2string:///some_b64e_password"
registry_username = "user"
registry_server   = "registry.example.com"
