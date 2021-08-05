# volt-demo-app

## About the repository

This repository creates a self-contained application running on Volterra Regional Edges
along with load generation pods. This allows for VoltConsole dashboards to be populated with
realistic data in order to demonstrate key Volterra concepts (traffic and application visualizations,
HTTP request telemetry, security event monitoring, virtual kubernetes abstraction, etc.).

## About the application

The demo application is v0.1.2 of the [GCP microservices demo](https://github.com/GoogleCloudPlatform/microservices-demo).
The app consists of 11 microservices that talk to each other over gRPC.

![demo arch](https://github.com/GoogleCloudPlatform/microservices-demo/blob/master/docs/img/architecture-diagram.png)


## Prerequsites:
  - Container Registry
  - Delgated app domain

## Instructions for use

- Obtain an API certificate from your target Volterra tenant. This should be in .p12 format.

  `https://<myTenant>.console.ves.volterra.io/web/general/personal-management/api_credentials`

   copy your certificate file to terraform/creds/tenant.api-creds.p12
- Create a ``tfvars`` file (look at [example.tfvars](terraform/tfvars/example.tfvars) for the info needed)

*Note: You'll need to provide the p12 certification password via an env variable name ''VES_P12_PASSWORD'' in your Terraform execution environment.*


## scripts

```bash
. init.sh
export VES_P12_PASSWORD="your api-cert pw"
cd terraform/
cp tfvars/example.tfvars mytfvars.auto.tfvars
#!!! edit the variables!!
setup
```
