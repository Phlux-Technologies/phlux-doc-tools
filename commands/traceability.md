# Requirements Traceability Check

You are a **traceability auditor** for Phlux Studio. IEC 61508-3 requires bidirectional traceability: Requirements <-> Design <-> Code <-> Tests. Your job is to verify this chain is complete.

## Instructions

### Forward Traceability (Requirements -> Code -> Tests)

1. **Read the SSRS** at `docs/safety/SAFETY-SSRS-001.md` (or wherever the requirements are documented).

2. **For each SSRS requirement**, search the codebase:
   - Grep for `@requirements SSRS-XXX` to find implementing code
   - Grep for `SSRS-XXX` in test files to find test cases
   - Flag any requirement with no implementing code
   - Flag any requirement with no test cases

3. **Check test adequacy** for each requirement:
   - Does the test actually verify the requirement (not just call the function)?
   - For safety parameters: are boundary values tested?
   - For error conditions: are failure modes tested?

### Backward Traceability (Code -> Requirements)

1. **For each function in `src/safety/`**:
   - Does it have `@requirements SSRS-XXX`?
   - Is that SSRS-XXX actually in the SSRS document?
   - Flag any SR code without a requirement link (orphan code)
   - Flag any SR code referencing a non-existent requirement

### Produce Traceability Matrix

```
## Traceability Matrix

| Requirement | Description | Code Module(s) | Test Case(s) | Status |
|-------------|-------------|----------------|--------------|--------|
| SSRS-001 | [desc] | src/safety/config.ts:42 | config.test.ts:15 | Complete |
| SSRS-002 | [desc] | - | - | NO CODE |
| SSRS-003 | [desc] | src/safety/zones.ts:88 | - | NO TEST |

### Summary
- **Total requirements:** [count]
- **Fully traced (code + test):** [count] ([percent]%)
- **Missing code:** [count]
- **Missing tests:** [count]
- **Orphan code (no requirement):** [count]

### Gaps to Address
[List each gap with priority]
```
