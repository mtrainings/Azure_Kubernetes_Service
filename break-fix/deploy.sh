#!/usr/bin/env bash
# Deploy the LAB15 break-fix scenarios into the namespace "bf"
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
source ./env.sh >/dev/null
envsubst '$ACR' < break-fix/scenarios.yaml | kubectl apply -f -
echo
echo "Scenarios deployed. Investigate with:  kubectl -n bf get all,pvc,netpol"
echo "Score yourself with:                  ./break-fix/check.sh"
