#!/usr/bin/env bash

set -euo pipefail

INSTANCE_ID=""
REGION=""
REPO_URL="https://github.com/pupapaik/f5-arcadia.git"
REPO_REF="main"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --instance-id)
      INSTANCE_ID="$2"
      shift 2
      ;;
    --region)
      REGION="$2"
      shift 2
      ;;
    --repo-url)
      REPO_URL="$2"
      shift 2
      ;;
    --repo-ref)
      REPO_REF="$2"
      shift 2
      ;;
    *)
      echo "Unsupported argument: $1" >&2
      exit 1
      ;;
  esac
done

if [[ -z "$INSTANCE_ID" || -z "$REGION" ]]; then
  echo "--instance-id and --region are required" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
COMPOSE_FILE="$REPO_ROOT/arcadia/docker-compose.yml"

if [[ ! -f "$COMPOSE_FILE" ]]; then
  echo "Compose file not found at $COMPOSE_FILE" >&2
  exit 1
fi

COMPOSE_B64="$(base64 < "$COMPOSE_FILE" | tr -d '\n')"

for attempt in {1..30}; do
  ping_status="$(aws ssm describe-instance-information \
    --region "$REGION" \
    --filters "Key=InstanceIds,Values=$INSTANCE_ID" \
    --query 'InstanceInformationList[0].PingStatus' \
    --output text 2>/dev/null || true)"

  if [[ "$ping_status" == "Online" ]]; then
    break
  fi

  if [[ "$attempt" -eq 30 ]]; then
    echo "Instance ${INSTANCE_ID} did not become available in SSM within the expected time." >&2
    exit 1
  fi

  echo "Waiting for instance ${INSTANCE_ID} to appear as Online in SSM..."
  sleep 10
done

COMMAND_ID="$(aws ssm send-command \
  --region "$REGION" \
  --instance-ids "$INSTANCE_ID" \
  --document-name "AWS-RunShellScript" \
  --comment "Install Arcadia application" \
  --parameters commands="[
    \"set -euo pipefail\",
    \"sudo dnf install -y git docker || sudo yum install -y git docker\",
    \"sudo systemctl enable --now docker\",
    \"sudo usermod -aG docker ec2-user || true\",
    \"sudo mkdir -p /opt\",
    \"sudo rm -rf /opt/f5-arcadia\",
    \"sudo git clone --depth 1 --branch ${REPO_REF} ${REPO_URL} /opt/f5-arcadia\",
    \"sudo mkdir -p /opt/f5-arcadia/arcadia-unit-kic/1.docker-images-preparation\",
    \"printf %s ${COMPOSE_B64} | base64 --decode | sudo tee /opt/f5-arcadia/arcadia-unit-kic/1.docker-images-preparation/docker-compose.yml >/dev/null\",
    \"cd /opt/f5-arcadia/arcadia-unit-kic/1.docker-images-preparation && sudo docker compose build\",
    \"cd /opt/f5-arcadia/arcadia-unit-kic/1.docker-images-preparation && sudo docker compose up -d\",
    \"curl -fsS http://localhost/ >/tmp/arcadia-index.html\"
  ]" \
  --query 'Command.CommandId' \
  --output text)"

aws ssm wait command-executed \
  --region "$REGION" \
  --command-id "$COMMAND_ID" \
  --instance-id "$INSTANCE_ID"

STATUS="$(aws ssm get-command-invocation \
  --region "$REGION" \
  --command-id "$COMMAND_ID" \
  --instance-id "$INSTANCE_ID" \
  --query 'Status' \
  --output text)"

if [[ "$STATUS" != "Success" ]]; then
  aws ssm get-command-invocation \
    --region "$REGION" \
    --command-id "$COMMAND_ID" \
    --instance-id "$INSTANCE_ID" \
    --query 'StandardErrorContent' \
    --output text >&2
  exit 1
fi

echo "Arcadia installation completed on instance ${INSTANCE_ID}."
