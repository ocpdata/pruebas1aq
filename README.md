# Arcadia on AWS with F5 XC

This repository provisions an Arcadia lab in three automated jobs triggered manually from GitHub Actions:

1. `aws_infra` creates the EC2 host and supporting AWS resources with Terraform.
2. `arcadia_app` installs and starts Arcadia on the EC2 instance through AWS Systems Manager.
3. `f5_dcs_config` configures the public F5 Distributed Cloud HTTP load balancer and baseline WAAP settings with Terraform.

It also provides a manual destroy workflow that removes the lab in reverse order:

1. `collect_aws_context` reads the AWS Terraform state and captures the origin outputs needed for teardown.
2. `f5_dcs_destroy` removes the F5 XC configuration first.
3. `aws_destroy` tears down the EC2 instance and AWS resources.

## Workflow model

- Trigger: `workflow_dispatch`
- Manual execution without runtime inputs
- Execution after trigger: fully automatic through `needs`
- State backend: Terraform Cloud remote backend in local execution mode
- Available workflows: `Deploy Arcadia` and `Destroy Arcadia`

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

## Workflow configuration

- `AWS_REGION` must exist as a GitHub Actions repository variable.
- The workflow automatically discovers the default VPC and the first public subnet in that VPC for the selected region.
- `XC_NAMESPACE` is fixed to `nathan`.
- `ARCADIA_DOMAIN` and `ARCADIA_REPO_REF` are fixed in [.github/workflows/deploy-arcadia.yml](/Users/ocarrillo/Labs/pruebas1aq/.github/workflows/deploy-arcadia.yml).
- `ARCADIA_REPO_REF` is set to `master` because that is the current default branch of `pupapaik/f5-arcadia`.
- The AWS account must have a default VPC and at least one subnet with `MapPublicIpOnLaunch=true` in the configured region.
- The destroy workflow expects the `arcadia-aws` Terraform Cloud workspace to still contain state so it can read the origin IP and DNS before removing F5 XC.

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
