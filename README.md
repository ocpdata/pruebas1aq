# Arcadia on AWS with F5 XC

This repository provisions an Arcadia lab in three automated jobs triggered manually from GitHub Actions:

1. `aws_infra` creates the EC2 host and supporting AWS resources with Terraform.
2. `arcadia_app` installs and starts Arcadia on the EC2 instance through AWS Systems Manager.
3. `f5_dcs_config` configures the public F5 Distributed Cloud HTTP load balancer and baseline WAAP settings with Terraform.

## Workflow model

- Trigger: `workflow_dispatch`
- Execution after trigger: fully automatic through `needs`
- State backend: Terraform Cloud remote backend in local execution mode

## Required GitHub secrets

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `TFC_TOKEN`
- `TFC_ORG`
- `XC_API_P12_FILE`
- `XC_API_URL`
- `XC_P12_PASSWORD`
- `SSH_PUBLIC_KEY`

`XC_API_P12_FILE` must contain the P12 bundle content encoded in base64 so the workflow can reconstruct it on the runner.

## Required workflow inputs

- `aws_region`
- `aws_vpc_id`
- `aws_public_subnet_id`
- `arcadia_domain`
- `xc_namespace`
- `arcadia_repo_ref`

## Local validation

Validate the AWS stack:

```bash
cd terraform/aws
terraform init -backend=false
terraform validate
```

Validate the F5 XC stack:

```bash
cd terraform/f5xc
terraform init -backend=false
terraform validate
```

## Notes

- Arcadia is deployed on a single public EC2 instance intended for lab use.
- The F5 load balancer is configured for HTTP only.
- The Terraform stack automates the F5 XC baseline: origin pool, app firewall in monitoring mode, API discovery enablement and public HTTP load balancer publication.
- API protection rules and Bot Defense tuning often depend on tenant features and can require follow-up adjustments. The current code leaves the environment ready for that follow-up without blocking the pipeline.
