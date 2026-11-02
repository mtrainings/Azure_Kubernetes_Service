#!/usr/bin/env bash
# Lab variables - load them in every new shell:   source env.sh
# Override before sourcing, e.g.:   LOCATION=northeurope source env.sh

LAB_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export LAB_ROOT

# a short random suffix, generated once - keeps globally unique names stable across shells
if [[ ! -f "$LAB_ROOT/.lab-suffix" ]]; then
  tr -dc 'a-z0-9' </dev/urandom | head -c 5 > "$LAB_ROOT/.lab-suffix"
fi
SUFFIX="$(cat "$LAB_ROOT/.lab-suffix")"

export PREFIX="${PREFIX:-$(whoami | tr -cd 'a-z0-9' | cut -c1-6)}"
export LOCATION="${LOCATION:-westeurope}"
export RG="rg-akslab-${PREFIX}"
export CLUSTER="aks-lab-${PREFIX}"
export ACR="acrlab${PREFIX}${SUFFIX}"          # 5-50 alphanumeric, globally unique
export KV="kv-lab-${PREFIX}${SUFFIX}"          # 3-24 characters, globally unique
# node size: remembered once set (NODE_SIZE=... source env.sh), so new shells pick it up
if [[ -n "${NODE_SIZE:-}" ]]; then
  echo "$NODE_SIZE" > "$LAB_ROOT/.lab-node-size"
elif [[ -f "$LAB_ROOT/.lab-node-size" ]]; then
  NODE_SIZE="$(cat "$LAB_ROOT/.lab-node-size")"
fi
export NODE_SIZE="${NODE_SIZE:-Standard_D2s_v5}"
export DNS_LABEL="cloudcart-${PREFIX}${SUFFIX}"
export APP_HOST="${DNS_LABEL}.${LOCATION}.cloudapp.azure.com"

# chart versions used in the labs (check for newer ones before a course)
export CERT_MANAGER_VERSION="v1.21.3"
export ALB_CONTROLLER_VERSION="1.13.0"

echo "RG=$RG  CLUSTER=$CLUSTER  ACR=$ACR  KV=$KV  LOCATION=$LOCATION  NODE_SIZE=$NODE_SIZE"
