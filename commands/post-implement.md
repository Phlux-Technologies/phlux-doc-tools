# Post-Implementation Pipeline

Run this after completing a feature or significant code change. It triggers review, testing, safety audit, and documentation checks — in parallel where possible.

## Instructions

You MUST run ALL FOUR of these checks. Launch them as parallel Task agents:

### Agent 1: Safety Code Review
Launch a Task agent with subagent_type "general-purpose" to perform a safety code review:
- Read `docs/process/review-checklists.md` and `docs/process/coding-standards.md`
- Review all files changed since the last commit on develop (or as specified by user)
- Classify each file as SR or NSR
- Check every item on the Code Review Checklist (REV-CL-004)
- Produce a review record with findings

### Agent 2: Test Runner
Run the test suite and check coverage:
- Run `npm run test:coverage` (or `npx vitest run --coverage`)
- Run `cd src/native && cargo test` if Rust code exists
- Compare coverage against SIL 2 targets (100% statement on SR, 90% overall)
- Report any failures or coverage gaps

### Agent 3: Safety Compliance Check
Launch a Task agent with subagent_type "general-purpose" to scan for safety violations:
- Search SR code for prohibited patterns (`any`, `@ts-ignore`, `unsafe`, `unwrap`)
- Check SR functions have `@safety` and `@requirements` tags
- Check complexity metrics (cyclomatic <= 10, length <= 75, nesting <= 4)
- Check SR/NSR import boundaries
- Check dependency versions are pinned exactly

### Agent 4: Documentation Gap Check
Launch a Task agent with subagent_type "general-purpose" to check documentation:
- Identify which docs need updating based on code changes
- Check traceability: every SR function should have `@requirements SSRS-XXX`
- Flag any implemented features without SSRS requirements
- Flag any SSRS requirements without test cases

## After All Agents Complete

Compile a summary report:

```
## Post-Implementation Report

**Feature/Change:** [description]
**Date:** [today]

### Results Summary

| Check | Status | Critical Issues |
|-------|--------|----------------|
| Code Review | PASS/FAIL | [count] |
| Tests & Coverage | PASS/FAIL | [count] |
| Safety Compliance | PASS/FAIL | [count] |
| Documentation | PASS/FAIL | [count] |

### Action Items
[List all critical and major findings that must be resolved]

### Ready for Merge?
[YES — all checks pass / NO — resolve action items first]
```
