# HOSTED-VIAL-REGRESSION-GATE-RESULT: hosted gate result

## Metadata

- Tree ID: `HOSTED-VIAL-REGRESSION-GATE-RESULT`
- Status: `active`
- Roadmap lane: `verification architecture`
- Created: `2026-09-22`
- Last updated: `2026-09-22`
- Owner: repo-local workflow

## Goal

Make the hosted VIAL regression gate agree with one published result.

## Non-Goals

- Do not treat a failed or unavailable hosted run as support or capacity.
- Do not rewrite the local exact-pinned observation.

## Acceptance Criteria

- The failed hosted step is diagnosed from its released log.
- The workflow, verifier, public contract, and mdBook name one hosted result.
- Focused checks and the doctrine gate pass.

## Task Tree

- ID: `HOSTED-VIAL-REGRESSION-GATE-RESULT`
  Status: `active`
  Goal: `Publish one hosted VIAL regression result that the workflow, verifier, contract, and book all name.`
  Acceptance: `Diagnose the failed hosted command, then align the workflow and published contract with the result that command produces.`
  Verification: `pending`
  Commit: `pending`
  Children: `HOSTED-VIAL-REGRESSION-GATE-RESULT.1`
- ID: `HOSTED-VIAL-REGRESSION-GATE-RESULT.1`
  Status: `active`
  Goal: `Diagnose the first hosted gate failure and own the contract contradiction.`
  Acceptance: `Record that push 54ac1c22d ran the public vial-gate command and that step failed while the published contract still requires an unavailable aggregate. Keep diagnosis open until the failed-step log is released. Do not infer support or capacity.`
  Verification: `The hosted job completed with a failed real command and a skipped independent verifier. The registered placement claim remains unchanged. The book states the contradiction outside that claim block.`
  Commit: `this commit`
