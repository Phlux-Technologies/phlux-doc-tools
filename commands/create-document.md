# Create Document

Enhance an existing Markdown document into a professional Phlux-branded PDF. This skill copies the source `.md` file into a `pdfs/` folder next to it, applies enhancements to the **copy** (never the original), then builds a polished PDF in that same folder. The original file is never modified.

## Instructions

Execute the phases below in order. Do not skip phases. If a phase fails, stop and report the error.

The user may pass a source file path as the skill argument: `$ARGUMENTS`

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
> Install both, restart your terminal, and try `/create-document` again.

Do NOT proceed until both tools are confirmed working.

Also check for ImageMagick (optional — image optimization will be skipped if unavailable):

```bash
magick --version
```

Record whether `magick` is available for Phase 4.

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

1. **Source file** — Path to the `.md` file to enhance (may already be provided as skill argument `$ARGUMENTS`)
2. **Audience** — Who will read this? (engineers, management, mixed)
3. **Enhancement level:**
   - **Minimal** — Brand formatting only (title page, TOC, headers/footers, styled tables)
   - **Moderate** (default) — + TikZ diagrams where helpful, callout boxes for key insights/decisions/warnings, image search for product photos
   - **Full** — + restructure sections for clarity, rewrite prose for the audience, add missing context

Accept short answers. Default to **moderate** if not specified. Bias toward action.

---

### Phase 2: Analyze the Source Document

Read the entire source markdown file. Identify:

1. **Structure:** Count headings at each level, sections, subsections
2. **Heading numbering issues:**
   - **Manual numbers in headings:** Do headings contain manual numbers (e.g., `## 1. Product Overview`)? Since the build uses `--number-sections`, these create redundant double-numbering (e.g., "0.1 1. Product Overview"). Manual numbers must be stripped.
   - **Heading level gaps:** Is the top-level heading `#` or `##`? If the document uses `##` as the highest level (no `#` headings), LaTeX numbers them as subsections (0.1, 0.2, ...) instead of sections (1, 2, ...). All heading levels must be promoted: `##` → `#`, `###` → `##`, `####` → `###`.
3. **Tables:** Count and note any that are very wide (>5 columns or long cell text)
4. **Code blocks:** Count, note languages
5. **Existing images:** List any image references
6. **YAML front matter:** Present or absent? What fields?
7. **Markdown TOC:** Is there a manually-written table of contents? (LaTeX auto-generates one, so the manual one should be removed)
8. **Horizontal rules (`---`):** Count them (sections provide structure in LaTeX, so `---` should be removed)
9. **Enhancement opportunities:**
   - Text describing architectures, data flows, or system diagrams → TikZ candidates
   - Comparison tables or trade-off discussions → visual diagram candidates
   - Key insights, conclusions, recommendations → `\begin{insight}` callout
   - Decisions or choices made → `\begin{decision}` callout
   - Warnings, risks, gotchas → `\begin{warning}` callout
   - Safety-related notes → `\begin{safetynote}` callout
   - References to hardware, boards, chips → image search candidates

Present a brief summary of findings to the user.

---

### Phase 3: Enhancement Plan + Approval

Present a structured enhancement plan:

```
## Enhancement Plan

### Front Matter
- [Add/Update] title: "..."
- [Add/Update] subtitle: "..."
- author: "Phlux Technologies"
- date: YYYY-MM-DD

### Formatting Fixes
- [ ] Strip manual numbers from headings (e.g., `## 1. Overview` → `## Overview`)
- [ ] Promote heading levels if no `#` headings exist (`##` → `#`, `###` → `##`, `####` → `###`)
- [ ] Remove markdown TOC (LaTeX auto-generates)
- [ ] Remove --- horizontal rules
- [ ] Add \small before wide tables (list which)
- [ ] Fix any markdown formatting issues

### Callout Boxes (N total)
- [ ] Section X.Y: insight — "brief description"
- [ ] Section X.Y: decision — "brief description"
- [ ] Section X.Y: warning — "brief description"

### TikZ Diagrams (N total)
- [ ] Section X.Y: block diagram — "what it shows"
- [ ] Section X.Y: data flow — "what it shows"

### Images to Find (N total)
- [ ] Section X.Y: "description of image to search for"

### No Changes
- List sections that need no enhancement
```

Accept "looks good", "approved", "yes", "go", "lgtm", or similar as approval. If the user requests changes, revise the plan. **Maximum 2 revision rounds** — after 2 rounds, proceed with the latest version.

---

### Phase 4: Image Search & Download

For content that would benefit from visuals (product photos, board images, architecture diagrams):

1. **Web search** for relevant images: product photos, board images, official diagrams
   - Prefer: official product photos, high-res board shots, vendor diagrams
   - Avoid: low-res thumbnails, watermarked images, marketing fluff
2. **Download** images using `curl` to the `pdfs/images/` subdirectory (next to the working copy, not the original)
   - Use kebab-case names: `kr260-board.png`, `tda4vm-starter-kit.jpg`
3. **Process** each downloaded image (if ImageMagick available):
   - `bash tools/doc-tools/presentations/scripts/tools.sh fit <path>` (resize to max 1920x1080)
   - `bash tools/doc-tools/presentations/scripts/tools.sh compress <path>` (reduce file size)
4. **Track** which images were downloaded vs already existed

Skip this phase entirely if:
- Enhancement level is "minimal"
- No image opportunities were identified in Phase 2
- ImageMagick is unavailable (download but skip processing)

---

### Phase 5: Apply Enhancements

**IMPORTANT: Never modify the original file. All edits go to the working copy in `pdfs/`.**

First, run the build script to create the working copy and initial (unenhanced) PDF:

```bash
bash tools/doc-tools/documents/scripts/build.sh <source-file-path>
```

This creates `<source-dir>/pdfs/<filename>.md` (copy) and `<source-dir>/pdfs/<filename>.pdf` (initial build). All edits below target the **working copy** at `<source-dir>/pdfs/<filename>.md`. The original file is never touched.

Apply changes to the working copy in this order:

**1. YAML Front Matter** — Add or update at the top of the file:

```yaml
---
title: "Document Title"
subtitle: "Subtitle if appropriate"
author: "Phlux Technologies"
date: "YYYY-MM-DD"
abstract: "Optional 1-2 sentence abstract"
toc-depth: 2
---
```

Note: `toc-depth: 2` keeps the TOC to sections and subsections only. This prevents TOC overflow on documents with many sections. Use `toc-depth: 3` only for short documents (<5 sections).

**2. Strip Manual Heading Numbers** — If headings contain manual numbers (e.g., `## 1. Product Overview`, `## 2. Safety Requirements`), strip the numbers. The build uses `--number-sections` which auto-numbers them, so manual numbers create redundant double-numbering like "0.1 1. Product Overview".

Example: `## 1. Product Overview` → `## Product Overview`

**3. Promote Heading Levels** — If the document has no `#` (H1) headings and uses `##` as the top level, LaTeX treats them as subsections numbered 0.1, 0.2, etc. Promote ALL heading levels by one:
- `##` → `#` (sections)
- `###` → `##` (subsections)
- `####` → `###` (subsubsections)

**IMPORTANT:** Do promotions in reverse order (`####` first, then `###`, then `##`) to avoid double-promoting. Use a script for reliability:

```python
import re
with open(filepath, 'r', encoding='utf-8') as f:
    lines = f.read().split('\n')
result = []
for line in lines:
    if re.match(r'^####\s', line):
        result.append(line.replace('#### ', '### ', 1))
    elif re.match(r'^###\s', line):
        result.append(line.replace('### ', '## ', 1))
    elif re.match(r'^##\s', line):
        result.append(line.replace('## ', '# ', 1))
    else:
        result.append(line)
with open(filepath, 'w', encoding='utf-8') as f:
    f.write('\n'.join(result))
```

**4. Remove Markdown TOC** — Delete any manually-written table of contents section. LaTeX `\tableofcontents` replaces it automatically.

**5. Remove Horizontal Rules** — Delete `---` separators. Section headings provide document structure in LaTeX.

**7. Insert Callout Boxes** — Use raw LaTeX blocks:

````markdown
```{=latex}
\begin{insight}
Key finding or important observation goes here.
\end{insight}
```
````

Available environments: `insight` (blue), `warning` (red), `decision` (amber), `safetynote` (green).

**8. Insert TikZ Diagrams** — Use raw LaTeX blocks with predefined styles:

````markdown
```{=latex}
\begin{center}
\begin{tikzpicture}
  % Diagram code using predefined styles (board, adapter, safebox, etc.)
\end{tikzpicture}
\end{center}
```
````

For article format, diagrams can be wider than slides — use up to 15cm width.

**9. Insert Image References:**

```markdown
![Caption text](images/filename.png){width=80%}
```

Use `width=80%` for most images, `width=60%` for smaller ones, `width=95%` for full-width.

**10. Table Sizing** — Add `\small` or `\footnotesize` before wide tables:

````markdown
```{=latex}
\small
```

| Column A | Column B | Column C | Column D | Column E |
|----------|----------|----------|----------|----------|
| data     | data     | data     | data     | data     |
````

**Content rules:**
- **Never invent data** — all content must come from the source document
- Callout boxes should wrap existing text, not add new claims
- TikZ diagrams should visualize relationships already described in text
- Keep the document's original structure and voice unless enhancement level is "full"

---

### Phase 6: Rebuild PDF

Rebuild the PDF from the enhanced working copy:

```bash
bash tools/doc-tools/documents/scripts/build.sh <original-source-file-path>
```

The build script is safe to re-run — it only copies the original `.md` on the **first** call (when `pdfs/<filename>.md` doesn't exist yet). On subsequent calls it rebuilds from the existing working copy, preserving your Phase 5 edits.

**If the build fails**, diagnose and fix the **working copy** (`pdfs/<filename>.md`) automatically:

| Error Type | Fix Strategy |
|------------|-------------|
| TikZ syntax error | Fix the TikZ code in the markdown, rebuild |
| Missing image | Remove the image reference or fix the path, rebuild |
| Undefined control sequence | Fix the LaTeX command, rebuild |
| Missing package (MiKTeX) | Tell the user to click "Install" in the MiKTeX popup, rebuild |
| Missing package (TeX Live) | Tell the user to run `sudo tlmgr install <package>`, rebuild |
| Font warnings | Ignore — preamble has fallback fonts |
| Overfull hbox warnings | Note for Phase 7 QA inspection |
| tcolorbox/mdframed errors | Check callout syntax, ensure `{=latex}` fence is used |

**Maximum 3 rebuild attempts** for code-level errors. If still failing after 3 attempts, stop and report the error to the user.

---

### Phase 7: Visual QA Inspection

Read the built PDF page-by-page using the Read tool. Inspect **every page** against this checklist:

| Check | Severity | What to Look For |
|-------|----------|-----------------|
| Text overflow past margins | CRITICAL | Text running off the right or bottom edge |
| Table overflow | CRITICAL | Table columns extending beyond page margins |
| TOC overflow | CRITICAL | TOC entries cut off at bottom of page (missing entries, no footer visible). Fix: set `toc-depth: 1` in YAML or reduce sections |
| Missing/broken images | CRITICAL | White boxes, error placeholders, missing figures |
| TikZ diagram clipping | CRITICAL | Diagram elements cut off at page edges |
| Broken LaTeX rendering | HIGH | Raw LaTeX commands visible instead of rendered output |
| Orphaned section headings | HIGH | Section or subsection heading alone at page bottom with no content following it. Check EVERY page bottom carefully. |
| Orphan figures | HIGH | Figure caption separated from its image by a page break |
| Redundant section numbering | HIGH | Double numbers like "0.1 1. Product Overview" — means manual numbers weren't stripped or headings weren't promoted |
| Title page rendering | MEDIUM | Dark header block, logo, title, subtitle, author, date all present |
| TOC present and correct | MEDIUM | Table of contents appears after title page, entries are clickable, content starts on next page |
| Headers/footers working | MEDIUM | Logo top-left, section name top-right, page number bottom-center |
| Callout boxes rendering | MEDIUM | Colored borders, titles, proper text wrapping |
| Code block highlighting | LOW | Syntax highlighting applied, text fits within margins |

**Fix loop (CRITICAL and HIGH issues only):**

1. If issues found, apply targeted fixes to the **working copy** (`pdfs/<filename>.md`):

   | Issue | Fix |
   |-------|-----|
   | Text overflow | Add `\small` or `\footnotesize`, reduce content width |
   | Table overflow | Reduce columns, abbreviate headers, add `\footnotesize`, or use `longtable` |
   | TOC overflow | Reduce `toc-depth` in YAML (2 → 1), or verify `\small` is active in template |
   | Missing image | Remove reference or fix path |
   | TikZ clipping | Reduce diagram width, use `[scale=0.85]` |
   | Broken LaTeX | Fix syntax, ensure `{=latex}` fences are correct |
   | Orphaned heading | Add `\newpage` raw LaTeX block before the orphaned heading in the markdown |
   | Orphan figures | Add `\FloatBarrier` or use `[H]` float placement |
   | Redundant numbering | Go back to Phase 5 steps 2-3: strip manual numbers, promote heading levels |

2. Rebuild the PDF
3. Re-inspect the changed pages

**Maximum 3 fix-rebuild-inspect iterations.** After 3 iterations, report any remaining issues to the user but deliver the PDF as-is.

---

### Phase 8: Delivery

Report to the user:

1. **PDF path:** Full path to the generated PDF in `pdfs/`
2. **Working copy:** Path to the enhanced `.md` in `pdfs/` (original is untouched)
3. **Page count:** Total number of pages
4. **Enhancements applied:** Summary of what was added (callout boxes, TikZ diagrams, images, formatting fixes)
5. **QA status:** PASS (no issues), PASS WITH NOTES (medium issues only), or ISSUES REMAINING (with details)

Offer:
- "Want me to adjust any sections? (edits go to the working copy in pdfs/)"
- "Want me to rebuild with changes?"

---
---

## Appendix A: Brand Colors

| Color | Hex | LaTeX Name | Usage |
|-------|-----|------------|-------|
| Dark charcoal | #1E2028 | `phluxdark` | Title page bg, section headings, text |
| Golden amber | #FBAA36 | `phluxaccent` | Accent rules, highlights, decision boxes |
| Safety green | #2E7D32 | `phluxsafe` | Safety notes, safe boundary regions |
| Warning red | #E74C3C | `phluxwarn` | Warnings, risk callouts |
| Info blue | #1565C0 | `phluxblue` | Insights, info callouts, links |

---

## Appendix B: Callout Box Syntax

Use raw LaTeX blocks in markdown. Each environment has a colored border, title, and can break across pages.

### Insight (blue) — key findings, observations

````markdown
```{=latex}
\begin{insight}
The AM69x provides 8 Cortex-A72 cores at 2.0 GHz, making it the most powerful
option for parallel image processing workloads.
\end{insight}
```
````

### Warning (red) — risks, gotchas, limitations

````markdown
```{=latex}
\begin{warning}
The SPC58 uses Power Architecture, not ARM. This means no Linux support,
no standard networking stack, and a completely separate toolchain from the
application processor.
\end{warning}
```
````

### Decision (amber) — choices made, recommendations

````markdown
```{=latex}
\begin{decision}
\textbf{Recommendation:} Option A (KR260 + Aurora over SFP+) provides the best
balance of FPGA interface bandwidth, Linux ecosystem maturity, and production
upgrade path.
\end{decision}
```
````

### Safety Note (green) — safety-related requirements or constraints

````markdown
```{=latex}
\begin{safetynote}
The safety core must run a certified RTOS (SafeRTOS or QNX) to achieve
SIL~2 certification. Bare-metal or Linux on the safety core is not acceptable
for IEC~61508 compliance.
\end{safetynote}
```
````

---

## Appendix C: TikZ Diagram Templates

All styles from the presentation system are available. In article format, diagrams can be **wider (up to 15cm)** since the page is wider than a slide.

### Available Styles (predefined in preamble.tex)

**Node styles:**

| Style | Look | Use for |
|-------|------|---------|
| `board` | Dark outline, light fill, rounded, bold text | Major components (processors, FPGAs, boards) |
| `adapter` | Lighter, smaller, thin outline | Secondary components (adapters, cables, connectors) |
| `safebox` | Green outline, green tint, solid | Safety-related boundary regions |
| `unsafebox` | Gray outline, gray tint, dashed | Non-safety / untrusted boundary regions |
| `pdufield` | Thin outline, no fill | Data structure fields (protocol bytes, registers) |
| `iicblock` | Blue outline, blue tint | Interface/peripheral blocks (I2C, SPI, UART) |

**Label styles:**

| Style | Size | Use for |
|-------|------|---------|
| `lbl` | `\tiny` | Small annotations on arrows and connections |
| `lbls` | `\scriptsize` | Slightly larger labels |

**Connection styles:**

| Style | Look | Use for |
|-------|------|---------|
| `conn` | Orange arrow (one-way) | Data flow, signals, one-directional |
| `biconn` | Orange arrow (both ends) | Bidirectional communication |
| `connline` | Orange line (no arrowhead) | Physical connections, cables, buses |

### Template: Block Diagram (Components + Connections)

```latex
\begin{center}
\begin{tikzpicture}
  \node[board] (a) {Component A};
  \node[board, right=2.5cm of a] (b) {Component B};
  \node[board, right=2.5cm of b] (c) {Component C};
  \draw[conn] (a.east) -- (b.west)
    node[midway, above, lbl] {Interface};
  \draw[connline] (b.east) -- (c.west)
    node[midway, above, lbl] {Cable}
    node[midway, below, lbl] {\$15};
\end{tikzpicture}
\end{center}
```

### Template: Safety Boundary Diagram

```latex
\begin{center}
\begin{tikzpicture}[node distance=0.3cm]
  \node[font=\scriptsize\bfseries, text=phluxsafe!80!black] at (2.2,2.5) {TRUSTED};
  \node[font=\scriptsize\bfseries, text=phluxwarn!80!black] at (7,2.5) {UNTRUSTED};
  \node[font=\scriptsize\bfseries, text=phluxsafe!80!black] at (11.8,2.5) {TRUSTED};

  \node[safebox, minimum height=3cm, text width=3.2cm] (left) at (2.2,0.5) {
    \textbf{Safety Module A}\\[3pt]
    Function 1\\
    Function 2\\
    Watchdog
  };
  \node[unsafebox, minimum height=3cm, text width=3.2cm] (mid) at (7,0.5) {
    \textbf{Black Channel}\\[3pt]
    Transport layer\\
    \textit{Opaque byte forwarding}
  };
  \node[safebox, minimum height=3cm, text width=3.2cm] (right) at (11.8,0.5) {
    \textbf{Safety Module B}\\[3pt]
    State machine\\
    Validation\\
    Watchdog
  };

  \draw[conn, line width=1.2pt] ([yshift=-6pt]left.east) -- ([yshift=-6pt]mid.west);
  \draw[conn, line width=1.2pt] ([yshift=-6pt]mid.east) -- ([yshift=-6pt]right.west);
  \draw[conn, line width=1.2pt] ([yshift=6pt]right.west) -- ([yshift=6pt]mid.east);
  \draw[conn, line width=1.2pt] ([yshift=6pt]mid.west) -- ([yshift=6pt]left.east);
\end{tikzpicture}
\end{center}
```

### Template: Data Structure / Protocol Fields

```latex
\begin{center}
\begin{tikzpicture}
  \node[pdufield, fill=phluxblue!12, minimum width=2.2cm] (f1) {Field A\\(4B)};
  \node[pdufield, fill=phluxblue!6, minimum width=2.2cm, right=-0.4pt of f1] (f2) {Field B\\(4B)};
  \node[pdufield, fill=phluxblue!12, minimum width=3cm, right=-0.4pt of f2] (f3) {Payload\\(NB)};
  \node[pdufield, fill=phluxaccent!15, minimum width=2.2cm, right=-0.4pt of f3] (f4) {CRC\\(4B)};

  \draw[decorate, decoration={brace, mirror, amplitude=4pt}, thick, phluxdark!70]
    ([yshift=-2pt]f1.south west) -- ([yshift=-2pt]f4.south east)
    node[midway, below=5pt, font=\tiny] {CRC covers all fields};
\end{tikzpicture}
\end{center}
```

### Template: Memory Map (Stacked Regions)

```latex
\begin{center}
\begin{tikzpicture}
  \def\w{12}
  \fill[phluxblue!12] (0,0) rectangle (\w,-1.5);
  \draw[phluxdark!50, thick] (0,0) rectangle (\w,-1.5);
  \node[font=\footnotesize, align=center] at (\w/2,-0.75) {\textbf{Region A} (large)};

  \fill[phluxsafe!10] (0,-1.5) rectangle (\w,-2.2);
  \draw[phluxdark!50] (0,-1.5) rectangle (\w,-2.2);
  \node[font=\footnotesize] at (\w/2,-1.85) {Region B};

  \fill[phluxdark!4] (0,-2.2) rectangle (\w,-3.5);
  \draw[phluxdark!50] (0,-2.2) rectangle (\w,-3.5);
  \node[font=\footnotesize, text=phluxdark!60] at (\w/2,-2.85) {\textit{Free / Reserved}};

  \node[font=\tiny\ttfamily, anchor=east] at (-0.15,0) {0x0000\_0000};
  \node[font=\tiny\ttfamily, anchor=east] at (-0.15,-1.5) {0x0100\_0000};
  \node[font=\tiny\ttfamily, anchor=east] at (-0.15,-3.5) {0x3FFF\_FFFF};

  \draw[decorate, decoration={brace, amplitude=5pt}, thick, phluxdark!50]
    (\w+0.15,0) -- (\w+0.15,-3.5)
    node[midway, right=7pt, font=\scriptsize] {1 GiB Total};
\end{tikzpicture}
\end{center}
```

### Template: Adapter Chain

```latex
\begin{center}
\begin{tikzpicture}[node distance=0.15cm]
  \node[board, minimum width=1.5cm, font=\tiny\bfseries] (src) {Source};
  \node[adapter, right=0.4cm of src] (a1) {Adapter\\A};
  \node[adapter, right=0.2cm of a1] (a2) {Adapter\\B};
  \node[board, minimum width=1.5cm, font=\tiny\bfseries, right=0.4cm of a2] (dst) {Destination};
  \draw[connline] (src.east) -- (a1.west);
  \draw[connline] (a1.east) -- (a2.west);
  \draw[connline] (a2.east) -- (dst.west);
  \node[lbl, below=3pt of a1] {\$200};
  \node[lbl, below=3pt of a2] {\$25};
\end{tikzpicture}
\end{center}
```

### Template: Timeline (Parallel Pipelines)

```latex
\begin{center}
\begin{tikzpicture}
  \node[font=\scriptsize\bfseries, anchor=east] at (-0.2, 0.6) {Writer:};
  \node[font=\scriptsize\bfseries, anchor=east] at (-0.2,-0.3) {Reader:};

  \fill[phluxblue!20] (0,0.2) rectangle (3,1);
  \draw[phluxdark!40] (0,0.2) rectangle (3,1);
  \node[font=\tiny] at (1.5,0.6) {Write A};

  \fill[phluxblue!20] (3.2,0.2) rectangle (6.2,1);
  \draw[phluxdark!40] (3.2,0.2) rectangle (6.2,1);
  \node[font=\tiny] at (4.7,0.6) {Write B};

  \fill[phluxaccent!20] (3.2,-0.7) rectangle (6.2,0.1);
  \draw[phluxdark!40] (3.2,-0.7) rectangle (6.2,0.1);
  \node[font=\tiny] at (4.7,-0.3) {Read A};

  \fill[phluxaccent!20] (6.4,-0.7) rectangle (9.4,0.1);
  \draw[phluxdark!40] (6.4,-0.7) rectangle (9.4,0.1);
  \node[font=\tiny] at (7.9,-0.3) {Read B};
\end{tikzpicture}
\end{center}
```

### Template: Bus Diagram (Hub with Multiple Ports)

```latex
\begin{center}
\begin{tikzpicture}
  \draw[phluxdark, thick, rounded corners=3pt, fill=phluxdark!5]
    (4,0.2) rectangle (8,-2.8);
  \node[font=\scriptsize\bfseries, phluxdark] at (6,-0.15) {Interconnect};

  \node[font=\tiny, anchor=east] (p0) at (3.8,-0.6) {Port A (W)};
  \node[font=\tiny, anchor=east] (p1) at (3.8,-1.2) {Port B (R/W)};
  \node[font=\tiny, anchor=east] (p2) at (3.8,-1.8) {Port C (R)};
  \node[font=\tiny, anchor=east] (p3) at (3.8,-2.4) {Port D (W)};
  \draw[phluxdark!40] (p0.east) -- (4,-0.6);
  \draw[phluxdark!40] (p1.east) -- (4,-1.2);
  \draw[phluxdark!40] (p2.east) -- (4,-1.8);
  \draw[phluxdark!40] (p3.east) -- (4,-2.4);

  \node[board, minimum width=2.5cm, minimum height=1.2cm] (out) at (11,-1.3)
    {Target\\{\tiny specs here}};
  \draw[conn, line width=1.5pt] (8,-1.3) -- (out.west);
\end{tikzpicture}
\end{center}
```

### Template: Interface Block Diagram

```latex
\begin{center}
\begin{tikzpicture}
  \node[board, minimum width=2cm] (src) at (0,0) {Source};

  \draw[phluxdark, thick, rounded corners=5pt, fill=phluxdark!4]
    (3,1.5) rectangle (8.5,-1.5);
  \node[font=\scriptsize\bfseries, phluxdark, anchor=north west] at (3.1,1.4) {Chip Boundary};

  \node[iicblock, minimum width=3.2cm] (b0) at (5.8, 0.7) {Block A};
  \node[iicblock, minimum width=3.2cm] (b1) at (5.8,-0.7) {Block B};

  \node[board, minimum width=2.5cm, minimum height=0.6cm] (t0) at (12, 0.7) {Device A};
  \node[board, minimum width=2.5cm, minimum height=0.6cm] (t1) at (12,-0.7) {Device B};

  \draw[connline] (b0.east) -- (t0.west) node[midway, above, lbl] {Bus 0};
  \draw[connline] (b1.east) -- (t1.west) node[midway, above, lbl] {Bus 1};
  \draw[conn, line width=1.2pt] (src.east) -- (3,0)
    node[midway, above, lbl] {Control};
\end{tikzpicture}
\end{center}
```

### TikZ Tips (Article Format)

- **Max width:** 15cm for article (vs 12cm for slides) — more room for detail
- **Font sizes:** Can use `\footnotesize` and `\small` (more readable on paper than slides)
- **Always wrap in** `\begin{center}...\end{center}`
- **Positioning:** Use `right=2.5cm of nodeA` (slightly wider spacing than slides)
- **Multi-line nodes:** `{Line 1\\Line 2}`, with `\\[3pt]` for extra vertical space
- **Color tinting:** `phluxblue!12` = 12% blue (very light), `phluxdark!40` = 40% dark
- **Boundary boxes:** `\draw[..., fill=...] (x1,y1) rectangle (x2,y2)`
- **Braces:** `\draw[decorate, decoration={brace, mirror, amplitude=4pt}]`

---

## Appendix D: Image Tools Quick Reference

The presentation system's `tools.sh` works for document images too. Run from the project root:

```bash
bash tools/doc-tools/presentations/scripts/tools.sh <command> [args...]
```

| Scenario | Command |
|----------|---------|
| Check image dimensions/size | `bash tools/doc-tools/presentations/scripts/tools.sh info <path>` |
| Downloaded image is huge (>2 MB) | `bash tools/doc-tools/presentations/scripts/tools.sh fit <path>` then `compress` |
| Screenshot has extra whitespace | `bash tools/doc-tools/presentations/scripts/tools.sh trim <path>` |
| Need format conversion | `bash tools/doc-tools/presentations/scripts/tools.sh convert <input> <output>` |
| Side-by-side comparison | `bash tools/doc-tools/presentations/scripts/tools.sh montage <output> <img1> <img2>` |
| Remove EXIF/GPS data | `bash tools/doc-tools/presentations/scripts/tools.sh strip <path>` |
| Crop to specific region | `bash tools/doc-tools/presentations/scripts/tools.sh crop <path> <geometry>` |

**Notes:**
- Commands modify in-place and create `.bak` backups (pass `--no-backup` to skip)
- `fit` defaults to 1920x1080 and never upscales
- All commands require ImageMagick v7 (`magick` command)

---

## Appendix E: Build Error Troubleshooting

| Error | Solution |
|-------|----------|
| Missing package (MiKTeX) | Click "Install" when prompted, or set auto-install in MiKTeX Console |
| Missing package (TeX Live) | `sudo tlmgr install <package-name>` |
| Font warnings | Non-fatal — preamble falls back to default fonts |
| Image not found | Check path is relative to the source file's directory |
| Overfull hbox | Content too wide — add `\small` or reduce table columns |
| TikZ dimension too large | Reduce diagram scale or width |
| Undefined control sequence | Typo in LaTeX command — check spelling |
| tcolorbox error | Ensure callout block uses `` ```{=latex} `` fence, not plain ``` |
| Longtable error | Ensure `longtable` package is loaded (it is, in preamble) |
| TEXINPUTS / image path | Build script sets TEXINPUTS; check that `cd` to DOC_DIR succeeded |

---

## Appendix F: Document File Locations

| Item | Path |
|------|------|
| Build script | `tools/doc-tools/documents/scripts/build.sh` |
| Preamble (styling) | `tools/doc-tools/documents/preamble.tex` |
| Template | `tools/doc-tools/documents/templates/phlux-article.tex` |
| Logos | `tools/doc-tools/documents/images/logos/` |
| Image tools | `tools/doc-tools/presentations/scripts/tools.sh` (shared) |
| Light logo (dark bg) | `images/logos/phlux_no_tech.png` |
| Dark logo (light bg) | `images/logos/phlux_white_gray_no_tech.png` |
