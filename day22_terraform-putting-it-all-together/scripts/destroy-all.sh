#!/usr/bin/env bash
# scripts/destroy-all.sh
# Destroys all live environments in reverse order (prod → stage → dev).
# USE WITH EXTREME CAUTION — this destroys real infrastructure.
#
# Usage: ./scripts/destroy-all.sh
# Requires: TF_VAR_db_username and TF_VAR_db_password set in environment

set -euo pipefail

RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo ""
echo -e "${RED}=========================================="
echo "  WARNING: This will destroy ALL infrastructure"
echo "  in dev, stage, and prod environments."
echo -e "==========================================${NC}"
echo ""
read -r -p "Type 'destroy everything' to confirm: " confirm

if [ "$confirm" != "destroy everything" ]; then
  echo "Aborted."
  exit 1
fi

# Destroy in reverse promotion order
ENVS=(
  "live/prod/services/hello-wadondera-app"
  "live/stage/services/hello-wadondera-app"
  "live/dev/services/hello-wadondera-app"
)

for env in "${ENVS[@]}"; do
  if [ -d "$env" ]; then
    echo ""
    echo -e "${YELLOW}Destroying $env ...${NC}"
    cd "$env"
    terraform init -input=false
    terraform destroy -auto-approve -input=false
    cd - > /dev/null
  fi
done

echo ""
echo "All environments destroyed."
echo "Run bootstrap/main.tf again if you want to start fresh."
