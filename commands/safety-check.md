# Safety Compliance Audit

You are a **functional safety auditor** for Phlux Studio, a T3 tool under IEC 61508 (SIL 2). Your job is to scan the entire codebase for safety standard violations and produce an audit report.

## Instructions

Run these checks in parallel where possible:

### 1. Prohibited Patterns Scan

Search the codebase for violations of PROC-002 (Coding Standards):

**In `src/safety/` and `src/native/src/safety/` (SR code):**
- Search for `: any` or `as any` — PROHIBITED
- Search for `@ts-ignore` or `@ts-expect-error` — PROHIBITED
- Search for `eval(` or `new Function(` — PROHIBITED
- Search for `var ` declarations — PROHIBITED
- Search for `== ` or `!= ` (loose equality) — PROHIBITED
- Search for `.unwrap()` or `.expect(` in Rust SR modules — PROHIBITED
- Search for `unsafe` blocks in Rust SR modules — PROHIBITED
- Search for `console.log` in SR code — should use structured logging

**In all code:**
- Search for `@ts-ignore` — should be zero project-wide
- Search for `eval(` — should be zero project-wide

### 2. Safety Documentation Check

For every function in `src/safety/`:
- Does it have a `@safety` JSDoc tag? List any missing.
- Does it have a `@requirements` JSDoc tag linking to SSRS-XXX? List any missing.
- Does it have an explicit return type? List any missing.

### 3. Complexity Metrics

For all functions in `src/safety/` and `src/native/src/safety/`:
- Identify any function with cyclomatic complexity > 10
- Identify any function longer than 75 executable lines
- Identify any nesting deeper than 4 levels
- Identify any function with more than 5 parameters

### 4. Dependency Audit

- Check `package.json` for any dependency using `^` or `~` (must be exact)
- Check if `package-lock.json` and `Cargo.lock` exist and are committed
- Cross-reference dependencies against `docs/process/tool-register.md` — flag any T3 dependency not in the register

### 5. SR/NSR Boundary Check

- Check that no SR module (`src/safety/`) imports from NSR modules (`src/ui/`, `src/visualization/`)
- SR modules may only import from: other SR modules, `src/shared/`, external libraries listed in tool register
- Flag any import that crosses the SR/NSR boundary in the wrong direction

### 6. Audit Report

```
## Safety Compliance Audit Report

**Date:** [today]
**Scope:** Full codebase
**Standard:** IEC 61508-3 (SIL 2), PROC-002

### Summary
- **Critical violations:** [count] (must fix before release)
- **Major violations:** [count] (should fix soon)
- **Minor violations:** [count] (fix when convenient)
- **Observations:** [count] (informational)

### Prohibited Pattern Violations
| # | Severity | File:Line | Pattern Found | Rule |
|---|----------|-----------|---------------|------|

### Missing Safety Documentation
| # | File:Line | Function | Missing Tag |
|---|-----------|----------|-------------|

### Complexity Violations
| # | File:Line | Function | Metric | Value | Limit |
|---|-----------|----------|--------|-------|-------|

### Dependency Issues
| # | Issue | Details |
|---|-------|---------|

### SR/NSR Boundary Violations
| # | SR Module | Imports From (NSR) | Fix |
|---|-----------|-------------------|-----|

### Verdict
[CLEAN / VIOLATIONS FOUND — fix critical/major before release]
```
