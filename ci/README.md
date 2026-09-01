# Triggering runs from CI

**The agent authors tests. Running them needs nothing but a token.**

Everything here was verified against the live API on 2026-09-01.

## The one call CI needs

```bash
curl -sf -X POST "https://app.proofarc.ai/api/scenarios/${SCENARIO_ID}/execute" \
  -H "Authorization: Bearer ${PROOFARC_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"environmentId": 575, "tags": ["openspec","ci","req:anonymous-access-is-refused"]}'
```

Returns **202** with the execution record:

```json
{ "id": 1724, "scenarioId": 1565, "environmentId": 575, "status": "PENDING" }
```

Then poll:

```bash
curl -sf "https://app.proofarc.ai/api/scenarios/executions/1724" \
  -H "Authorization: Bearer ${PROOFARC_TOKEN}"
```

```json
{ "status": "COMPLETED", "totalSteps": 3, "successRate": 100.0 }
```

## Tag every run

Pass `tags` on every execution, not just the first:

```json
"tags": ["openspec", "change:add-user-account-management", "req:anonymous-access-is-refused"]
```

`run_by_tag` derives its matches from **execution history**, so an untagged run
leaves the requirement unfindable by name. See `BINDING.md`.

## A whole gate in one script

```bash
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
```

The exit code gates the build. The execution ids are the evidence, and they
outlive the CI log.

## GitHub Actions

```yaml
name: Verify requirements
on: [push, pull_request]

jobs:
  proofarc:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run bound scenarios
        env:
          PROOFARC_TOKEN: ${{ secrets.PROOFARC_TOKEN }}
        run: ./ci/verify-requirements.sh
```

Store the token as a repository secret. Never commit it, and never put it in a
scenario — credentials belong in the environment vault, referenced by tag.

## What CI cannot do

**`run_by_tag` has no REST route.** `/api/scenarios/run-by-tag` returns
`400 — Path/query parameter 'id' expects a Long`, so the path does not exist.
It is an MCP-level fan-out: it resolves tags to scenarios, then executes each.

So CI must hold the requirement → scenario id map itself. That map is the
`Bindings` table in each change's `verification/proofarc-evidence.md`, which is
committed alongside the spec precisely so a script can read it without the
platform.

If you want tag-based fan-out in CI, either mirror the table as above, or have
an agent do the resolution step.

## Other triggers

| what | call |
|---|---|
| one scenario | `POST /api/scenarios/{id}/execute` |
| a data set | `run_data_driven(name, version, environment)` — MCP |
| an ordered sequence | `run_pipeline(pipeline, environment)` — MCP |
| gate a release tag | `run_quality_gate(gate, version)` — MCP |
