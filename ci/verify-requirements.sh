#!/usr/bin/env bash
set -euo pipefail

API="https://app.proofarc.ai"
ENV_ID=575
AUTH=(-H "Authorization: Bearer ${PROOFARC_TOKEN}" -H "Content-Type: application/json")

# requirement slug -> scenario id, mirroring the evidence file's Bindings table
declare -A BOUND=(
  ["anonymous-access-is-refused"]=1565
)

fail=0
for req in "${!BOUND[@]}"; do
  sid="${BOUND[$req]}"
  exec_id=$(curl -sf -X POST "$API/api/scenarios/$sid/execute" "${AUTH[@]}" \
    -d "{\"environmentId\":$ENV_ID,\"tags\":[\"ci\",\"req:$req\"]}" \
    | python3 -c 'import json,sys; print(json.load(sys.stdin)["id"])')

  for _ in $(seq 1 60); do
    body=$(curl -sf "$API/api/scenarios/executions/$exec_id" "${AUTH[@]}")
    status=$(printf '%s' "$body" | python3 -c 'import json,sys; print(json.load(sys.stdin)["status"])')
    case "$status" in RUNNING|PENDING) sleep 2;; *) break;; esac
  done

  rate=$(printf '%s' "$body" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("successRate"))')
  if [ "$status" = "COMPLETED" ]; then
    echo "PASS  $req  (execution $exec_id, $rate%)"
  else
    echo "FAIL  $req  (execution $exec_id, $status, $rate%)"
    fail=1
  fi
done

exit $fail
