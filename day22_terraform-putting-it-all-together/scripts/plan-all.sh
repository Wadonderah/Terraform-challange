#!/usr/bin/env bash
# scripts/plan-all.sh
# Run terraform plan across all live environments and report status.
# Use this at the start of every sprint to verify the Golden Rule:
#   "main branch = what is actually deployed"
#
# Usage: ./scripts/plan-all.sh
# Expected output for a healthy repo: "No changes" in every environment.

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ENVS=(
  "live/dev/services/hello-wadondera-app"
  "live/stage/services/hello-wadondera-app"
  "live/prod/services/hello-wadondera-app"
)

PASS=0
FAIL=0
DRIFT=()

echo ""
echo "=========================================="
echo "  Golden Rule check — terraform plan all"
echo "=========================================="
echo ""

for env in "${ENVS[@]}"; do
  echo -n "  Checking $env ... "

  if [ ! -d "$env" ]; then
    echo -e "${YELLOW}SKIP (directory not found)${NC}"
    continue
  fi

  output=$(cd "$env" && terraform init -backend=false -input=false -no-color 2>&1) || true
  result=$(cd "$env" && terraform plan -detailed-exitcode -input=false -no-color 2>&1) || exit_code=$?

  case "${exit_code:-0}" in
    0)
      echo -e "${GREEN}✓ No changes${NC}"
      ((PASS++))
      ;;
    1)
      echo -e "${RED}✗ Error${NC}"
      echo "$result" | tail -5
      ((FAIL++))
      DRIFT+=("$env")
      ;;
    2)
      echo -e "${RED}✗ DRIFT DETECTED${NC}"
      echo "$result" | grep "^  [~+-]" | head -10
      ((FAIL++))
      DRIFT+=("$env")
      ;;
  esac
done

echo ""
echo "=========================================="
printf "  Result: ${GREEN}%d clean${NC} / ${RED}%d drifted${NC}\n" "$PASS" "$FAIL"

if [ ${#DRIFT[@]} -gt 0 ]; then
  echo ""
  echo -e "${RED}  Drift detected in:${NC}"
  for d in "${DRIFT[@]}"; do
    echo "    - $d"
  done
  echo ""
  echo "  These are the highest-priority issues this sprint."
  echo "  The Golden Rule is broken until all environments show 'No changes'."
  exit 1
else
  echo ""
  echo -e "${GREEN}  Golden Rule holds. All environments match their code.${NC}"
  echo ""
fi
