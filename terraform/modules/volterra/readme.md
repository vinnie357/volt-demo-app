# volterra
<!-- markdownlint-disable no-inline-html -->
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| volterra | 0.8.1 |

## Providers

| Name | Version |
|------|---------|
| local | n/a |
| time | n/a |
| volterra | 0.8.1 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| api\_p12\_file | the local file path to your api-cert in .p12 format | `any` | n/a | yes |
| api\_url | the api end point of your volterra subscription [tenant].ves.volterra.io/api | `any` | n/a | yes |
| app\_fqdn | the requested fqdn for your example application | `any` | n/a | yes |
| create\_namespace | if we should create your namespace or not | `any` | n/a | yes |
| main\_site\_selector | the regional edges to deploy your services in | `any` | n/a | yes |
| namespace | your namespace in the tenant where you have rights for vk8s | `any` | n/a | yes |
| state\_site\_selector | the regional edges to store your state in | `any` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| app\_url | Domain VIP to access the web app |
| kubecfg | kubeconfig file |
| main\_vsite | Virtual site for the application |
| namespace | Namespace created for this app |
| state\_vsite | Virtual site for the state service |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
<!-- markdownlint-enable no-inline-html -->
