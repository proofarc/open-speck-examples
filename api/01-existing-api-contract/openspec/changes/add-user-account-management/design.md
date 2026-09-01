# Design

## Why verification runs rather than reads

OpenSpec's default verify step is static: it reads code, matches keywords, and
maps scenarios to files. From its own skill definition, it validates
*"without running tests"* and is instructed to *"use keyword search, file path
analysis, reasonable inference — don't require perfect certainty."*

That is the right default. It is fast, it needs no environment, and for most
changes it is enough.

It is not enough for a requirement whose failure looks like success in the source.
The uniqueness requirement in this change is exactly that case: there is
validation code, there is a create handler, and the words line up with the spec.
The constraint is simply absent, and only a request that sends the same username
twice reveals it.

## The split

| verify by reading | verify by running |
|---|---|
| Are all tasks complete? | Does the endpoint return what the spec says? |
| Does an implementation exist for each requirement? | Does the change persist? |
| Does the code follow project conventions? | Is the constraint actually enforced? |
| Is the design decision honoured? | Is the malformed case handled? |

Reading answers *"was it built?"*. Running answers *"does it do what we agreed?"*.
A change should not archive on the first alone when the second is available.

## Why the tests live in ProofArc rather than in the repo

A test in the repo runs on the machine that has the repo. These requirements are
about a deployed service, so the test needs an environment, a credential, and a
host that differ per environment.

A ProofArc scenario carries `{{baseUrl}}` plus an `appTag` so the same test runs
against any environment, references a credential by tag so no secret is written
down, and stores every request and response so the evidence outlives the run.
The artifact is a record with an id, not a file that has to be re-executed to
mean anything.

## What this does not change

The OpenSpec flow is untouched: explore, propose, apply, verify, archive. The
`verification/` artifact is additive. A change that needs no runtime evidence
simply produces an empty one, and the static verify step continues to do the
work it is good at.
