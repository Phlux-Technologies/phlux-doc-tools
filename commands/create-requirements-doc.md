# Create Requirements Document

Generate a professional Phlux-branded PDF from structured requirements markdown files. This skill parses requirement IDs, statuses, and traceability links, then produces a PDF with clickable cross-references, status-colored requirement boxes, and TikZ traceability diagrams. The original source files are never modified.

## Instructions

Execute the phases below in order. Do not skip phases. If a phase fails, stop and report the error.

The user may pass source file path(s) as the skill argument: `$ARGUMENTS`

---

### Phase 0: Preflight

Check that the build toolchain is available. Run these commands:

```bash
pandoc --version
xelatex --version
```

If either fails, stop and tell the user:

> **Document toolchain not installed.** You need:
>
> - **Pandoc:** https://pandoc.org/installing.html
> - **TeX distribution:** MiKTeX (Windows) or TeX Live (macOS/Linux)
>
> Install both, restart your terminal, and try `/create-requirements-doc` again.

Do NOT proceed until both tools are confirmed working.

Verify the document build infrastructure exists:

```bash
ls tools/doc-tools/documents/scripts/build.sh
ls tools/doc-tools/documents/preamble.tex
ls tools/doc-tools/documents/templates/phlux-article.tex
ls tools/doc-tools/documents/images/logos/phlux_no_tech.png
```

If any are missing, stop and report.

---

### Phase 1: Understand the Request

Ask the user a single structured question with these fields:

1. **Source file(s)** — Path(s) to the requirements `.md` files (L1 system requirements and/or L2 derived requirements). May already be provided as skill argument `$ARGUMENTS`.
2. **Audience** — Who will read this? (engineers, management, certification body)
3. **Scope:**
   - **Full document** (default) — Both L1 and L2 requirements with traceability
   - **L1 only** — System-level requirements only
   - **L2 only** — Derived requirements only
   - **Specific domains** — Only certain requirement domains/categories

Accept short answers. Default to **full document** if not specified. Bias toward action.

---

### Phase 2: Parse & Analyze Requirements

Read all provided requirements markdown files. Extract and catalog:

1. **Requirement inventory:**
   - All requirement IDs (e.g., `SRS-DET-001`, `DR-CAL-001`)
   - Title, obligation keyword (SHALL/SHOULD/MAY), status (Demonstrated/Gap/Broken/TBD)
   - Traces (parent IDs for L2, child IDs for L1)
   - Domain/category grouping

2. **Cross-reference graph:**
   - Which L1 IDs are referenced by L2 requirements
   - Which L2 IDs trace back to which L1 requirements
   - Any broken references (IDs referenced but not defined)

3. **Statistics:**
   - Total count by level (L1 vs L2)
   - Count by status (Demonstrated / Gap / Broken / TBD)
   - Count by domain/category
   - Count by obligation (SHALL vs SHOULD vs MAY)
   - Gap percentage per domain

4. **Open items:** Extract any TBD entries, open decisions, or unresolved items.

Present a brief summary of findings to the user:

```
## Requirements Analysis Summary

**L1 System Requirements:** N total (X demonstrated, Y gaps, Z broken)
**L2 Derived Requirements:** N total (X demonstrated, Y gaps, Z broken)
**Cross-references:** N unique traces, M broken references
**Domains:** list of domains with gap %
```

---

### Phase 3: Generate Markdown

Create a new `.md` file in a `pdfs/` directory next to the primary source file. The filename should be descriptive (e.g., `requirements-report.md`).

**IMPORTANT: Never modify the original requirements files. All output goes to the new file in `pdfs/`.**

Generate the markdown document with the following structure:

#### 3.1 YAML Front Matter

```yaml
---
title: "System Requirements Specification"
subtitle: "Light Curtain Safety System"
author: "Phlux Technologies"
date: "YYYY-MM-DD"
abstract: "Requirements report covering N L1 system requirements and M L2 derived requirements. Overall compliance: X% demonstrated, Y% gap, Z% broken."
toc-depth: 2
---
```

Adjust the title, subtitle, and abstract based on scope selection from Phase 1.

#### 3.2 Executive Summary

Write a concise executive summary section with:
- Total requirement counts by level and status
- Key findings and gap percentages
- Critical gaps or broken requirements highlighted

Include a TikZ gap analysis bar chart — horizontal stacked bars per domain, green (demonstrated) + amber (gap) + red (broken), with counts labeled:

````markdown
```{=latex}
\begin{center}
\begin{tikzpicture}
  % Scale: 1cm = N requirements (choose scale so chart is ~12cm wide)
  \def\barheight{0.5}
  \def\barsep{0.9}

  % For each domain, draw a stacked horizontal bar:
  % Green (demonstrated) then amber (gap) then red (broken)
  % Example for one domain row:
  % \fill[phluxsafe!70] (0, 0) rectangle (6, \barheight);           % demonstrated
  % \fill[phluxaccent!70] (6, 0) rectangle (8, \barheight);          % gap
  % \fill[phluxwarn!70] (8, 0) rectangle (9, \barheight);            % broken
  % \node[font=\scriptsize, anchor=east] at (-0.2, \barheight/2) {Detection};
  % \node[font=\tiny, text=white] at (3, \barheight/2) {6};          % count label

  % Build actual bars from the parsed data.
  % Adjust y-offset for each domain: row N is at y = -N * \barsep

  % Legend at bottom
  \node[font=\scriptsize] at (2, -N*\barsep - 0.5) {
    \tikz{\fill[phluxsafe!70] (0,0) rectangle (0.3,0.2);} Demonstrated \quad
    \tikz{\fill[phluxaccent!70] (0,0) rectangle (0.3,0.2);} Gap \quad
    \tikz{\fill[phluxwarn!70] (0,0) rectangle (0.3,0.2);} Broken
  };
\end{tikzpicture}
\end{center}
```
````

Fill in actual data from Phase 2. Choose scale so the widest bar is ~12cm.

#### 3.3 L1 System Requirements

Organize by domain (Detection, Safety, Communication, etc.). For each domain, create a subsection:

```markdown
# L1 System Requirements

## Detection Requirements
```

For each requirement within the domain, render as a status-colored box with cross-reference anchors:

````markdown
```{=latex}
\reqtarget{SRS-DET-001}
\begin{reqdemonstrated}{SRS-DET-001 --- Object Detection}
The system \textbf{SHALL} detect objects within the defined curtain boundary with a minimum detection probability of 99.9\%.

\smallskip
\textit{Traces to:} \reqref{DR-DET-001}, \reqref{DR-DET-002}, \reqref{DR-DET-003}
\end{reqdemonstrated}
```
````

**Status-to-environment mapping:**
- Status contains "Demonstrated" or "Demo" → `reqdemonstrated`
- Status contains "Gap" → `reqgap`
- Status contains "Broken" → `reqbroken`
- Status is "TBD" or unknown → `reqgap` (treat as gap)

**Formatting rules:**
- Use `---` (em dash) in the title, not `—` (Unicode), for LaTeX compatibility
- Bold the obligation keyword: `\textbf{SHALL}`, `\textbf{SHOULD}`, `\textbf{MAY}`
- Escape LaTeX special characters in requirement text: `%`, `&`, `#`, `_`, `$`, `{`, `}`
- Use `\smallskip` before the traces line
- Only include "Traces to" line if there are actual trace references
- Use `\reqref{ID}` for each traced requirement (creates clickable link)

**Diagram visualization:** After rendering each requirement box, evaluate whether the requirement describes something that would benefit from a visual diagram. Add a TikZ diagram immediately after the requirement box if the requirement describes any of:

- **Architecture or topology** (e.g., "The system shall consist of a Jetson device, Teensy MCU, and PC client") → block diagram showing components and connections
- **Data flow or pipeline** (e.g., "Raw frames shall pass through ambient subtraction, blur, and threshold stages") → flow diagram with processing stages
- **Timing or sequencing** (e.g., "The camera shall trigger within 50us of VSYNC") → timeline diagram showing signal relationships
- **Safety boundaries** (e.g., "Safety processing shall run independently of the application processor") → boundary diagram with trusted/untrusted zones using `safebox`/`unsafebox` styles
- **State machines** (e.g., "The system shall transition from INIT to RUNNING to SAFE-STATE") → state diagram with transitions
- **Spatial/geometric relationships** (e.g., "The curtain shall span a 3D volume defined by...") → spatial layout diagram
- **Communication protocols** (e.g., "Commands are sent as [size][id][type][payload]") → protocol field diagram using `pdufield` style

Do NOT add diagrams for:
- Simple boolean requirements ("The system shall support feature X")
- Numeric thresholds only ("Detection probability shall be ≥ 99.9%")
- Requirements that are already clear without visualization
- Requirements where the text is too vague to produce an accurate diagram

When adding a diagram, place it immediately after the requirement box's closing `\end{req...}` but still inside the same `{=latex}` fence:

````markdown
```{=latex}
\reqtarget{SRS-COM-001}
\begin{reqdemonstrated}{SRS-COM-001 --- Dual TCP Architecture}
The system \textbf{SHALL} provide dual TCP sockets: a command socket (port 19870) for low-latency control and a data socket (port 19871) for high-throughput frame streaming.

\smallskip
\textit{Traces to:} \reqref{DR-COM-001}, \reqref{DR-COM-002}
\end{reqdemonstrated}

\begin{center}
\begin{tikzpicture}
  \node[board] (pc) at (0,0) {PC Client};
  \node[board] (cmd) at (5, 0.6) {Command Socket\\{\tiny Port 19870}};
  \node[board] (data) at (5,-0.6) {Data Socket\\{\tiny Port 19871}};
  \node[board] (dev) at (10,0) {Jetson Device};
  \draw[conn] (pc.east) -- (cmd.west) node[midway, above, lbl] {GET/SET};
  \draw[conn] (pc.east) -- (data.west) node[midway, below, lbl] {Frames};
  \draw[conn] (cmd.east) -- (dev.west);
  \draw[conn] (data.east) -- (dev.west);
\end{tikzpicture}
\end{center}
```
````

Use the predefined TikZ styles from the preamble (`board`, `adapter`, `safebox`, `unsafebox`, `pdufield`, `iicblock`, `conn`, `biconn`, `connline`, `lbl`). Keep diagrams at most 14cm wide. The diagram content must faithfully represent only what the requirement text states — do not invent details.

#### 3.4 L2 Derived Requirements

Same pattern as L1, organized by category instead of domain. Use compact formatting:

````markdown
```{=latex}
\reqtarget{DR-CAL-001}
\begin{reqgap}{DR-CAL-001 --- Calibration Data Validation}
The device \textbf{SHALL} validate calibration data integrity on startup using CRC-32 checksums.

\smallskip
\textit{Parent:} \reqref{SRS-CAL-001}
\end{reqgap}
```
````

Use "Parent:" instead of "Traces to:" for L2→L1 links.

**Diagram visualization:** Apply the same diagram evaluation as L1 (section 3.3). If an L2 requirement describes an implementation detail that benefits from visualization (e.g., a calibration data flow, an image processing pipeline stage, a protocol field layout), add a TikZ diagram after the requirement box. L2 diagrams tend to be more implementation-focused and detailed than L1 diagrams.

#### 3.5 Traceability

Include two traceability views:

**View 1: TikZ Traceability Overview Diagram**

A domain-to-category mapping diagram using the existing `board` and `conn` styles. Show L1 domains on the left connected to L2 categories on the right:

````markdown
```{=latex}
\begin{center}
\begin{tikzpicture}[node distance=0.3cm]
  % L1 domains on the left
  \node[board, minimum width=3cm] (det) at (0, 0) {Detection\\{\tiny N requirements}};
  \node[board, minimum width=3cm] (saf) at (0, -1.2) {Safety\\{\tiny N requirements}};
  % ... more domains

  % L2 categories on the right
  \node[board, minimum width=3cm, fill=phluxblue!8] (cal) at (8, 0) {Calibration\\{\tiny N requirements}};
  \node[board, minimum width=3cm, fill=phluxblue!8] (img) at (8, -1.2) {Image Processing\\{\tiny N requirements}};
  % ... more categories

  % Connection lines (domain → category relationships)
  \draw[conn] (det.east) -- (img.west);
  \draw[conn] (saf.east) -- (cal.west);
  % ... more connections

  % Labels
  \node[font=\small\bfseries, text=phluxdark] at (0, 1) {L1 Domains};
  \node[font=\small\bfseries, text=phluxdark] at (8, 1) {L2 Categories};
\end{tikzpicture}
\end{center}
```
````

Build actual connections from the cross-reference graph in Phase 2. Only show connections where at least one L2 requirement in that category traces to an L1 requirement in that domain.

**View 2: Traceability Table**

A markdown table mapping L1 → L2:

```markdown
| L1 Requirement | L2 Requirements | Count |
|----------------|-----------------|-------|
| SRS-DET-001    | DR-DET-001, DR-DET-002, DR-DET-003 | 3 |
| SRS-SAF-001    | DR-SAF-001, DR-SAF-002 | 2 |
```

Add `\small` before the table if it has many rows.

#### 3.6 Summary Tables

Create color-coded summary tables. Use raw LaTeX for colored status cells:

````markdown
```{=latex}
\small
```

| Domain | Total | Demonstrated | Gap | Broken | Coverage |
|--------|-------|-------------|-----|--------|----------|
| Detection | 8 | 6 | 2 | 0 | 75% |
| Safety | 12 | 4 | 5 | 3 | 33% |
````

Include separate tables for L1 and L2 if both are in scope.

#### 3.7 Open Items

Table of TBD/open decisions:

```markdown
| ID | Description | Status | Priority |
|----|-------------|--------|----------|
| TBD-001 | Safety integrity level target | Open | High |
```

**Content rules (same as create-document):**
- **Never invent requirements** — all content must come from the source files
- Requirement text should be quoted exactly, with only LaTeX formatting applied
- Cross-references must map to actual IDs found in the source files
- Statistics must match the actual parsed data

---

### Phase 4: Build PDF

First, write the generated markdown file to the `pdfs/` directory. Then build:

```bash
bash tools/doc-tools/documents/scripts/build.sh <generated-markdown-path>
```

Note: Since the generated file IS the working copy (it's already in `pdfs/`), we need to handle this differently from create-document. Create the `pdfs/` directory manually, write the file there, then call the build script with a dummy source path or build directly:

**Build approach:**
1. Create `pdfs/` directory next to the primary source file
2. Write the generated `.md` directly into `pdfs/`
3. Copy the images/logos directory structure so the build can find logos
4. Run the build script, pointing it at a copy of the generated file in the source directory (the script will find the existing `pdfs/` copy and use it)

Alternatively, if the generated file exists as a temporary file in the source directory:
1. Write a temporary `.md` to the source directory
2. Run `bash tools/doc-tools/documents/scripts/build.sh <temp-file>`
3. The script copies it to `pdfs/` and builds there
4. Remove the temporary file from the source directory

Use whichever approach works with the build script. The key: the final PDF ends up in `pdfs/`.

**If the build fails**, diagnose and fix automatically:

| Error Type | Fix Strategy |
|------------|-------------|
| TikZ syntax error | Fix the TikZ code in the generated markdown, rebuild |
| Undefined control sequence | Fix the LaTeX command, rebuild |
| Missing package (MiKTeX) | Tell user to click "Install" in the MiKTeX popup, rebuild |
| Missing package (TeX Live) | Tell user to run `sudo tlmgr install <package>`, rebuild |
| Font warnings | Ignore — preamble has fallback fonts |
| Overfull hbox warnings | Note for Phase 5 QA |
| tcolorbox errors | Check requirement box syntax, ensure `{=latex}` fences are used |
| Hyperref errors | Check for special characters in requirement IDs (use only alphanumeric + hyphen) |

**Maximum 3 rebuild attempts** for code-level errors. If still failing after 3 attempts, stop and report.

---

### Phase 5: Visual QA Inspection

Read the built PDF page-by-page using the Read tool. Inspect **every page** against this checklist:

| Check | Severity | What to Look For |
|-------|----------|-----------------|
| Text overflow past margins | CRITICAL | Text running off the right or bottom edge |
| Requirement box overflow | CRITICAL | Requirement text or traces extending beyond box boundaries |
| TOC overflow | CRITICAL | TOC entries cut off at bottom of page |
| TikZ diagram clipping | CRITICAL | Diagram elements cut off at page edges |
| Broken LaTeX rendering | HIGH | Raw LaTeX commands visible instead of rendered output |
| Missing status colors | HIGH | Requirement boxes all same color (environments not loading) |
| Orphaned section headings | HIGH | Section heading alone at page bottom |
| Broken cross-references | HIGH | `\reqref` links not clickable or showing raw text |
| Title page rendering | MEDIUM | Dark header block, logo, title, subtitle, author, date all present |
| TOC present and correct | MEDIUM | Table of contents appears, entries are clickable |
| Headers/footers working | MEDIUM | Logo top-left, section name top-right, page number bottom-center |
| Status badges rendering | MEDIUM | Colored pill badges in requirement box titles |
| TikZ bar chart readable | MEDIUM | Bars properly scaled, labels visible, legend present |
| Traceability diagram | MEDIUM | Domain/category boxes connected, no overlapping lines |

**Requirements-specific checks:**
- Click-test: Verify `\reqref` links jump to the correct `\reqtarget` anchors
- Count-check: Spot-check that the number of rendered requirement boxes matches Phase 2 counts
- Status-check: Verify a few known Demonstrated, Gap, and Broken requirements show correct box colors
- Diagram-check: Verify inline TikZ diagrams render correctly after their requirement boxes, don't clip, and accurately represent the requirement text

**Fix loop (CRITICAL and HIGH issues only):**

1. Apply targeted fixes to the generated markdown in `pdfs/`:

   | Issue | Fix |
   |-------|-----|
   | Text overflow | Add `\small` or `\footnotesize`, shorten text |
   | Box overflow | Check for unescaped LaTeX characters in requirement text |
   | TikZ clipping | Reduce diagram width, use `[scale=0.85]` |
   | Broken LaTeX | Fix syntax, ensure `{=latex}` fences are correct |
   | Missing colors | Check environment names match preamble definitions |
   | Broken cross-refs | Check ID escaping — only use `[A-Za-z0-9-]` in IDs |
   | Orphaned heading | Add `\newpage` raw LaTeX block before the heading |

2. Rebuild the PDF
3. Re-inspect the changed pages

**Maximum 3 fix-rebuild-inspect iterations.** After 3 iterations, report remaining issues and deliver as-is.

---

### Phase 6: Delivery

Report to the user:

1. **PDF path:** Full path to the generated PDF in `pdfs/`
2. **Generated markdown:** Path to the `.md` file in `pdfs/` (source files untouched)
3. **Page count:** Total number of pages
4. **Requirement counts:**
   - L1: N total (X demonstrated, Y gap, Z broken)
   - L2: N total (X demonstrated, Y gap, Z broken)
   - Cross-references: N total, M broken
5. **QA status:** PASS, PASS WITH NOTES, or ISSUES REMAINING (with details)

Offer:
- "Want me to adjust any sections? (edits go to the generated file in pdfs/)"
- "Want me to rebuild with different scope (L1 only, specific domains, etc.)?"
- "Want me to export the requirements data in another format?"

---
---

## Appendix A: Requirement Box Syntax Reference

### Demonstrated (green border + badge)

````markdown
```{=latex}
\reqtarget{SRS-DET-001}
\begin{reqdemonstrated}{SRS-DET-001 --- Object Detection}
The system \textbf{SHALL} detect objects within the defined curtain boundary.

\smallskip
\textit{Traces to:} \reqref{DR-DET-001}, \reqref{DR-DET-002}
\end{reqdemonstrated}
```
````

### Gap (amber border + badge)

````markdown
```{=latex}
\reqtarget{SRS-SAF-005}
\begin{reqgap}{SRS-SAF-005 --- Watchdog Timer}
The system \textbf{SHALL} implement a hardware watchdog timer with a maximum timeout of 2.5 seconds.

\smallskip
\textit{Traces to:} \reqref{DR-SAF-010}
\end{reqgap}
```
````

### Broken (red border + badge)

````markdown
```{=latex}
\reqtarget{SRS-SAF-012}
\begin{reqbroken}{SRS-SAF-012 --- Safe State on Communication Loss}
The system \textbf{SHALL} enter a safe state within 100ms of detecting communication loss.

\smallskip
\textit{Traces to:} \reqref{DR-SAF-020}, \reqref{DR-SAF-021}
\end{reqbroken}
```
````

---

## Appendix B: Cross-Reference Macros

| Macro | Renders As | Purpose |
|-------|-----------|---------|
| `\reqref{SRS-DET-001}` | Clickable monospace `SRS-DET-001` | Link TO a requirement (reader clicks this) |
| `\reqtarget{SRS-DET-001}` | Invisible anchor | Link TARGET at the requirement definition |
| `\statusbadge{TEXT}{color}` | Colored pill label | Status indicator in box title |

**ID format rules:**
- Use only `[A-Za-z0-9-]` characters in requirement IDs
- The `\reqtarget` must appear before the `\begin{req...}` environment
- The `\reqref` ID must exactly match a `\reqtarget` ID for the link to work

---

## Appendix C: TikZ Diagram Templates

### Gap Analysis Bar Chart

```latex
\begin{center}
\begin{tikzpicture}
  \def\barheight{0.5}
  \def\scale{0.3}  % 1 requirement = 0.3cm width

  % Row 0: Detection (6 demo, 2 gap, 0 broken)
  \fill[phluxsafe!70] (0, 0) rectangle ({6*\scale}, \barheight);
  \fill[phluxaccent!70] ({6*\scale}, 0) rectangle ({8*\scale}, \barheight);
  \node[font=\scriptsize, anchor=east] at (-0.2, \barheight/2) {Detection};
  \node[font=\tiny, text=white] at ({3*\scale}, \barheight/2) {6};
  \node[font=\tiny, text=white] at ({7*\scale}, \barheight/2) {2};

  % Row 1: Safety (4 demo, 5 gap, 3 broken) — offset y by -0.9
  \fill[phluxsafe!70] (0, -0.9) rectangle ({4*\scale}, {-0.9+\barheight});
  \fill[phluxaccent!70] ({4*\scale}, -0.9) rectangle ({9*\scale}, {-0.9+\barheight});
  \fill[phluxwarn!70] ({9*\scale}, -0.9) rectangle ({12*\scale}, {-0.9+\barheight});
  \node[font=\scriptsize, anchor=east] at (-0.2, {-0.9+\barheight/2}) {Safety};

  % ... repeat for each domain

  % Legend
  \node[font=\scriptsize, anchor=west] at (0, -3.5) {
    \tikz{\fill[phluxsafe!70] (0,0) rectangle (0.3,0.2);} Demonstrated \quad
    \tikz{\fill[phluxaccent!70] (0,0) rectangle (0.3,0.2);} Gap \quad
    \tikz{\fill[phluxwarn!70] (0,0) rectangle (0.3,0.2);} Broken
  };
\end{tikzpicture}
\end{center}
```

### Traceability Overview (Domain → Category)

```latex
\begin{center}
\begin{tikzpicture}[node distance=0.3cm]
  % L1 domains (left column)
  \node[board, minimum width=3.5cm] (d1) at (0, 0) {Detection\\{\tiny 8 reqs}};
  \node[board, minimum width=3.5cm] (d2) at (0, -1.3) {Safety\\{\tiny 12 reqs}};
  \node[board, minimum width=3.5cm] (d3) at (0, -2.6) {Communication\\{\tiny 6 reqs}};

  % L2 categories (right column)
  \node[board, minimum width=3.5cm, fill=phluxblue!8] (c1) at (9, 0) {Image Processing\\{\tiny 15 reqs}};
  \node[board, minimum width=3.5cm, fill=phluxblue!8] (c2) at (9, -1.3) {Calibration\\{\tiny 10 reqs}};
  \node[board, minimum width=3.5cm, fill=phluxblue!8] (c3) at (9, -2.6) {Safety Logic\\{\tiny 8 reqs}};

  % Connections
  \draw[conn] (d1.east) -- (c1.west);
  \draw[conn] (d2.east) -- (c3.west);
  \draw[conn] (d1.east) -- (c2.west);

  % Column labels
  \node[font=\small\bfseries, text=phluxdark] at (0, 1) {L1 System Domains};
  \node[font=\small\bfseries, text=phluxdark] at (9, 1) {L2 Derived Categories};
\end{tikzpicture}
\end{center}
```

---

## Appendix D: LaTeX Escaping Quick Reference

Requirements text often contains characters that are special in LaTeX. Escape them:

| Character | LaTeX Escape | Notes |
|-----------|-------------|-------|
| `%` | `\%` | Comment character |
| `&` | `\&` | Table column separator |
| `#` | `\#` | Parameter character |
| `_` | `\_` | Subscript in math mode |
| `$` | `\$` | Math mode delimiter |
| `{` | `\{` | Group open |
| `}` | `\}` | Group close |
| `~` | `\textasciitilde{}` | Non-breaking space |
| `^` | `\textasciicircum{}` | Superscript in math mode |
| `<` | `\textless{}` | Use in text mode |
| `>` | `\textgreater{}` | Use in text mode |
| `\` | `\textbackslash{}` | Escape character itself |

**In requirement IDs:** Only use `[A-Za-z0-9-]` to avoid hyperref issues.

---

## Appendix E: Build Error Troubleshooting

| Error | Solution |
|-------|----------|
| Missing package (MiKTeX) | Click "Install" when prompted |
| Missing package (TeX Live) | `sudo tlmgr install <package-name>` |
| Font warnings | Non-fatal — preamble falls back to default fonts |
| Overfull hbox | Content too wide — add `\small` or shorten requirement text |
| TikZ dimension too large | Reduce diagram scale or width |
| Undefined control sequence | Check macro spelling: `\reqref`, `\reqtarget`, `\statusbadge` |
| tcolorbox error | Ensure requirement box uses `` ```{=latex} `` fence |
| Hyperref duplicate target | Two `\reqtarget` with same ID — deduplicate |
| Inner sep syntax | Use `inner xsep=4pt, inner ysep=2pt` (not `inner sep=2pt 4pt`) |

---

## Appendix F: File Locations

| Item | Path |
|------|------|
| Build script | `tools/doc-tools/documents/scripts/build.sh` |
| Preamble (requirement envs) | `tools/doc-tools/documents/preamble.tex` |
| Template | `tools/doc-tools/documents/templates/phlux-article.tex` |
| Logos | `tools/doc-tools/documents/images/logos/` |
| Requirements source (example) | `claude/system-requirements.md` |
| Derived requirements (example) | `claude/derived-requirements.md` |
