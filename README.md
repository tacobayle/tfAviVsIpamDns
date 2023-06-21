# tfAviVsIpamDns

## Goals
Configure a Health Monitor, Pool and VS through Terraform (via Avi provider)

## Prerequisites:
- TF is installed
- Avi Controller is reachable from your terraform host
- IPAM and DNS profiles configured in the Avi Controller

## Environment:

Terraform script has/have been tested against:

### terraform

```
Terraform v1.0.6
on linux_amd64
+ provider registry.terraform.io/vmware/avi v21.1.4
```

### Avi version

```
Avi 21.1.4
```

### Avi Environment

- vCenter


## Input/Parameters:

1. Make sure you have a json file with the Avi credentials like the following:

```
{"avi_credentials": {"api_version": "21.1.4", "controller": "10.41.135.72", "password": "******", "username": "terraform"}}
```

2. All the other variables are stored in variables.tf.
The below variable(s) called need(s) to be adjusted:
- poolServers
- dns
- ipam
- avi_cloud
- avi_tenant
- network_name
- domain_name

The other variables don't need to be adjusted.

## Use the the terraform script to:
1. Create a Health Monitor
2. Create a Pool (based on the Health Monitor previously created)
3. Create a vsvip (based on Avi IPAM and DNS)
4. Create a VS based on the pool previously created

## Run the terraform:
- apply:
```
cd ~ ; git clone https://github.com/tacobayle/tfAviVsIpamDns ; cd tfAviVsIpamDns ; terraform init ; terraform apply -var-file=creds.json -auto-approve
```
- destroy:
```
terraform destroy -var-file=creds.json -auto-approve
```