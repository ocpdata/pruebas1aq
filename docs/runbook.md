# Runbook

## Execution order

Trigger the `Deploy Arcadia` workflow manually. It does not request runtime inputs.

Before running it:

- Define the repository variable `AWS_REGION`.
- Confirm the target region has a default VPC and at least one public subnet with automatic public IP assignment enabled.
- The F5 XC namespace is fixed to `nathan`.

The workflow will then run the three jobs in order:

1. AWS infrastructure
2. Arcadia application installation
3. F5 DCS configuration

## What each job does

### AWS infrastructure

- Creates an EC2 instance in an existing VPC and public subnet.
- Creates a key pair from `SSH_PUBLIC_KEY`.
- Creates a security group for HTTP and SSH.
- Creates an instance profile with SSM access.
- Prepares the instance with Docker, Git and the SSM-ready baseline.

### Arcadia application

- Waits for the EC2 instance to be managed by SSM.
- Clones the Arcadia repository on the instance.
- Writes the repository's `docker-compose.yml` into the Arcadia build directory.
- Builds and starts the Arcadia containers.
- Validates that the frontend responds locally on the instance.

### F5 DCS configuration

- Reconstructs the XC P12 file from GitHub Secrets.
- Creates an origin pool that points to the AWS public IP.
- Creates an App Firewall policy in monitoring mode.
- Creates an HTTP load balancer for the requested domain.
- Enables API discovery on the HTTP load balancer.
- Exposes the resulting load balancer CNAME and IP through Terraform outputs.

## Post-deploy checks

1. Confirm the EC2 instance is online in AWS Systems Manager.
2. Confirm Arcadia returns HTML on `http://<instance-public-ip>/`.
3. Check the F5 XC workspace outputs for the load balancer CNAME and IP.
4. Point the external DNS record for `arcadia.digitalvs.com` at the F5 XC load balancer according to the output values.
5. Generate browser traffic and review WAAP and API discovery telemetry in the F5 XC console.

## Residual F5 follow-up

The code automates the F5 XC baseline safely. Depending on tenant entitlements and existing API definitions, you may still need to tune:

- API protection rules for specific paths or API groups
- Bot Defense advanced policies and JavaScript insertion scope
- WAF exclusions for application-specific false positives
