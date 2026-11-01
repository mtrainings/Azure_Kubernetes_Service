#!/usr/bin/env bash
# Score the LAB15 break-fix challenge
set -uo pipefail
NS=bf
pass=0; total=8
ok()  { echo "  PASS  $1"; pass=$((pass+1)); }
bad() { echo "  FAIL  $1"; }
ready() { # deployment fully available?
  [[ "$(kubectl -n $NS get deploy "$1" -o jsonpath='{.status.availableReplicas}' 2>/dev/null)" == \
     "$(kubectl -n $NS get deploy "$1" -o jsonpath='{.spec.replicas}' 2>/dev/null)" ]] && \
  [[ -n "$(kubectl -n $NS get deploy "$1" -o jsonpath='{.status.availableReplicas}' 2>/dev/null)" ]]
}

echo "Break-fix challenge"
ready bf1-release && ok "BF1 image"          || bad "BF1 image (kubectl -n bf describe pod -l app=bf1-release)"
ready bf2-restarts && ok "BF2 crash loop"    || bad "BF2 crash loop (kubectl -n bf logs deploy/bf2-restarts --previous)"
ready bf3-pending && ok "BF3 scheduling"     || bad "BF3 scheduling (kubectl -n bf describe pod -l app=bf3-pending)"

eps=$(kubectl -n $NS get endpointslices -l kubernetes.io/service-name=bf4-api -o jsonpath='{.items[*].endpoints[*].addresses[*]}')
[[ -n "$eps" ]] && ok "BF4 service endpoints" || bad "BF4 service endpoints (compare selector and pod labels)"

ready bf5-notready && ok "BF5 readiness"     || bad "BF5 readiness (kubectl -n bf describe pod -l app=bf5-notready)"

[[ "$(kubectl -n $NS get pvc bf6-data -o jsonpath='{.status.phase}' 2>/dev/null)" == "Bound" && \
   "$(kubectl -n $NS get pod bf6-db -o jsonpath='{.status.phase}' 2>/dev/null)" == "Running" ]] \
  && ok "BF6 volume" || bad "BF6 volume (kubectl -n bf describe pvc bf6-data)"

kubectl auth can-i list pods -n $NS --as system:serviceaccount:bf:bf7-lister >/dev/null 2>&1 \
  && ok "BF7 RBAC" || bad "BF7 RBAC (kubectl -n bf logs deploy/bf7-inventory)"

last=$(kubectl -n $NS logs deploy/bf8-client --tail=1 2>/dev/null)
[[ "$last" == "200" ]] && ok "BF8 DNS / egress" || bad "BF8 DNS / egress (last result: ${last:-none})"

echo
echo "Score: $pass / $total"
