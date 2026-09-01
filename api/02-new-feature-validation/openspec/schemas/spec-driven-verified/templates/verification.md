# Verification evidence — ProofArc

<!--
INSTRUCTIONS FOR THE AGENT

Produce runtime evidence for every scenario in this change's delta specs. Do not
write a judgement about whether the code looks correct — the static verify step
already does that. This artifact records what happened when the requirement was
executed.

1. RESOLVE THE TARGET
   list_projects, then get_project_setup_status on the project for this service.
   You need a project, an application with an appTag, an environment, and a
   target. If any is missing, call find_playbooks('onboard a project') and follow
   what it returns rather than improvising.

2. READ THE API CHEAPLY
   detect_api_spec, then get_api_digest. Never read the full OpenAPI document.
   Read the `gaps` and `inferred` fields: they name the facts the spec does not
   establish. If a requirement depends on one of them, settle it with
   observe_api_digest before writing assertions — a spec is a claim, a response
   is evidence.

3. CHECK WHAT ALREADY EXISTS — DO THIS BEFORE CREATING ANYTHING

   Verification runs many times over a change's life. It must be safe to run
   twice. Tests are bound by tag, and the binding is deterministic:

     name  "[<change-id>] <Requirement Name>"
     tags  openspec, change:<change-id>, req:<requirement-slug>

   where <requirement-slug> is the requirement heading lowercased and
   hyphenated. Both are derived from the spec, so the same requirement always
   produces the same key on every run and on every machine.

   Look it up first:

     find_scenarios(project=<id>, tags=["req:<requirement-slug>"])

   - MATCH FOUND -> that requirement is already bound. Do NOT create another.
     Reuse the id, run it, and record the result.
   - NO MATCH    -> create it, tagging it as above.

   Two independent guards back this up, so a mistake cannot silently duplicate:

   - Scenario names are unique per project. A second create with the same name
     is refused with HTTP 409 "Scenario with name ... already exists". Treat a
     409 as "already bound", look it up by name, and carry on.
   - The evidence file in this change records every requirement's scenario id.
     It is committed alongside the spec, so the binding survives even when the
     platform is unreachable. Read it before searching.

   HAS THE REQUIREMENT CHANGED SINCE IT WAS BOUND?
   A reused test is only valid if it still asserts what the spec now says.
   Compare the requirement's WHEN/THEN clauses against the bound scenario's
   steps (get_scenario_yaml). If the spec has moved on:

     - update the scenario in place with update_api_scenario_from_yaml, and
     - note in the evidence file that the binding was revised.

   Known limitation: update_api_scenario_from_yaml takes no `environment`, so a
   scenario referencing an environment property ({{tenantCode}}) cannot be
   updated and must be deleted and recreated, which changes its id. If that
   happens, record the new id in the evidence file so the binding stays true.

   NEVER delete a bound scenario merely because a run was red. A red test is
   the finding. Deleting it destroys the evidence that the requirement is unmet.

4. BIND EACH SCENARIO
   For every `#### Scenario:` in the delta specs, create or reuse a ProofArc
   scenario asserting exactly what its WHEN/THEN clauses state.
   - Prefer act_on_intent with the requirement in plain words, then
     instantiate_playbook.
   - Otherwise compose YAML and call validate_scenario_yaml first — it writes no
     state, so iterate freely — then create_scenario_from_yaml.
   - A scenario that names several inputs is a data set: declare dataColumns and
     use create_data_driven_set, giving every row a testName. One verdict per row
     beats one aggregate.

5. ASSERT THE CLAUSE, NOT THE CALL
   A status code alone rarely proves a requirement. If a THEN says the change
   persists, re-read it. If it says a value is absent, assert its absence. If it
   says a duplicate is refused, send the duplicate.
   Before trusting a green assertion, invert it once and confirm it fails. An
   assertion that passes both ways is testing nothing.

6. RUN AND RECORD
   execute_scenario against the environment, then record for each requirement:
   the scenario id, the execution id, the per-step verdict, and the HTTP codes.
   Report failures as failures. Never widen an expectation to make a test pass —
   a red test is the finding, and rebaselining destroys it permanently.

7. STATE READINESS
   If every bound test is green, say so. If any requirement is contradicted by
   the service, this change is NOT ready to archive, and the failing requirement
   is named at the top.

Non-negotiable: never write a credential into a scenario. Store it once in the
environment vault and reference it by credentialTag. Negative tests probe
non-existent ids, never real ones.
-->

Project {{project}} · environment {{environment}} · captured {{date}}

## Summary

| requirement | scenarios | test | verdict |
|---|---|---|---|
| | | | |

## Requirement: <name> — PASS | FAIL | PARTIAL

Scenario <id>, execution <id>, <n>/<n>.

| spec scenario | step | result |
|---|---|---|

## How to re-run

```
execute_scenario(scenario=<id>, environment=<id>)
```
