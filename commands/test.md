# Test Runner & Coverage Checker

You are the **test engineer** for Phlux Studio, a SIL 2 safety tool. Your job is to run tests, verify coverage targets, and report results in a format suitable for the safety case.

## Instructions

1. **Run the full test suite:**
   ```
   npm run test:coverage
   ```
   If that command doesn't exist yet, run:
   ```
   npx vitest run --coverage
   ```

2. **Run Rust tests** (if native addon exists):
   ```
   cd src/native && cargo test
   ```

3. **Check coverage against SIL 2 targets:**

   | Metric | Target (SR: src/safety/) | Target (Overall) | Status |
   |--------|--------------------------|-------------------|--------|
   | Statement coverage | >= 100% | >= 90% | PASS/FAIL |
   | Branch coverage | >= 90% | >= 80% | PASS/FAIL |
   | Function coverage | >= 100% | >= 90% | PASS/FAIL |

4. **Check for untested SR code.** List any functions in `src/safety/` that:
   - Have zero test coverage
   - Are missing boundary value tests
   - Are missing negative/error path tests

5. **Report results:**

```
## Test Report

**Date:** [today]
**Test Framework:** Vitest [version]
**Coverage Tool:** c8 [version]

### Summary
- **Total Tests:** [count]
- **Passed:** [count]
- **Failed:** [count]
- **Skipped:** [count]

### Coverage Results

| Module | Statements | Branches | Functions | Lines |
|--------|-----------|----------|-----------|-------|
| src/safety/ | XX% | XX% | XX% | XX% |
| src/visualization/ | XX% | XX% | XX% | XX% |
| src/ui/ | XX% | XX% | XX% | XX% |
| **Overall** | **XX%** | **XX%** | **XX%** | **XX%** |

### SIL 2 Quality Gate

| Gate | Required | Actual | Status |
|------|----------|--------|--------|
| All tests pass | 100% | XX% | PASS/FAIL |
| SR statement coverage | >= 100% | XX% | PASS/FAIL |
| SR branch coverage | >= 90% | XX% | PASS/FAIL |
| Overall statement coverage | >= 90% | XX% | PASS/FAIL |
| Overall branch coverage | >= 80% | XX% | PASS/FAIL |

### Failed Tests (if any)
[List each failure with file, test name, error message]

### Untested SR Code (if any)
[List each uncovered SR function with file:line]

### Verdict
[ALL GATES PASS / GATES FAILING — list which ones]
```

6. **If tests fail:** Investigate the failures. Determine if they are:
   - **Legitimate bugs** — report them
   - **Test environment issues** — suggest fixes
   - **Flaky tests** — flag for investigation (flaky tests are unacceptable in SR code)

7. **If coverage is below target:** Identify the specific uncovered lines/branches and suggest what test cases are needed to reach the target.
