# Create Presentation

Generate a professional Phlux-branded PDF presentation from source material. This skill automatically discovers content, generates slides, builds the PDF, visually inspects it, and fixes formatting problems.

## Instructions

Execute the phases below in order. Do not skip phases. If a phase fails, stop and report the error.

---

### Phase 0: Preflight

Check that the build toolchain is available. Run these commands:

```bash
pandoc --version
xelatex --version
```

If either fails, stop and tell the user:

> **Presentation toolchain not installed.** Run the setup script first:
>
> - **Windows (PowerShell):** `powershell -ExecutionPolicy Bypass -File tools\doc-tools\presentations\scripts\setup.ps1`
> - **macOS / Linux:** `bash tools/doc-tools/presentations/scripts/setup.sh`
>
> Then restart your terminal and try `/create-presentation` again.

Do NOT proceed until both tools are confirmed working.

Also check for ImageMagick (optional — image optimization will be skipped if unavailable):

```bash
magick --version
```

Record whether `magick` is available for Phase 5.

---

### Phase 1: Understand the Request

Ask the user a single structured question with these fields:

1. **Topic** — What is this presentation about?
2. **Audience** — Who will see this? (engineers, management, customers, mixed)
3. **Purpose** — What should the audience walk away with? (decision, understanding, status update)
4. **Key messages** (optional) — Any specific points to emphasize?
5. **Source material** (optional) — Specific files or docs to draw from?
6. **Constraints** (optional) — Slide count, time limit, specific sections to include/exclude?

Accept short answers. Infer reasonable defaults for anything not specified. Bias toward action — do not ask follow-up questions unless the topic is genuinely ambiguous.

---

### Phase 2: Content Discovery (Auto-Scan)

Automatically scan the repository for relevant source material:

1. **Research docs:** Glob `docs/research/*.md` — read headings and first paragraph of each, rate relevance to the topic as HIGH / MEDIUM / LOW
2. **Analysis docs:** Glob `docs/analysis/*.md` — same treatment
3. **Design docs:** Glob `docs/design/*.md` — same treatment
4. **Existing presentations:** Glob `docs/presentations/*.md` — check for prior art on this topic
5. **Image inventory:** Glob `docs/presentations/images/*` (excluding `logos/` and `.originals/`) — list available images with descriptions
6. **Image sizing:** For each image that might be used, run `bash tools/doc-tools/presentations/scripts/tools.sh info docs/presentations/images/<image>` to check dimensions

Present a brief summary of what you found:
- List of HIGH-relevance source docs (these will feed content)
- List of MEDIUM-relevance docs (available if needed)
- Available images that match the topic
- Any prior presentations on the same topic

---

### Phase 2b: Image Search & Download

For slides that would benefit from visuals (product comparisons, hardware boards, architecture concepts, logos of external products):

1. **Web search** for relevant images: product photos, board images, official diagrams, data sheet figures
   - Example searches: "TI SK-TDA4VM board photo", "AMD Kria KR260 product image", "NXP S32G board"
   - Prefer: official product photos, high-res board shots, architecture block diagrams from vendors
   - Avoid: low-res thumbnails, watermarked images, marketing collateral without substance
2. **Download** images using `curl` to `docs/presentations/images/` with descriptive filenames
   - Use kebab-case names: `kr260-board.png`, `tda4vm-starter-kit.jpg`, `s32g-block-diagram.png`
3. **Immediately process** each downloaded image:
   - `bash tools/doc-tools/presentations/scripts/tools.sh fit docs/presentations/images/<file>` (resize to max 1920x1080)
   - `bash tools/doc-tools/presentations/scripts/tools.sh compress docs/presentations/images/<file>` (reduce file size)
4. **Track** which images were downloaded vs already existed — note this for the outline

Skip this phase if ImageMagick is unavailable (downloaded images may be oversized but will still work).

---

### Phase 3: Outline + User Approval

Generate a slide-by-slide outline in this format:

```
# Section: <section title>
  (dark divider slide)

## Slide: <slide title>
   Content: <1-2 sentence description of what goes on this slide>
   Source: <which doc(s) feed this slide's data>
   Visual: <image filename, TikZ diagram type, or "none">

## Slide: <slide title>
   ...
```

Show the complete outline to the user. Present it clearly.

Accept "looks good", "approved", "yes", "go", "lgtm", or similar as approval. If the user requests changes, revise the outline. **Maximum 2 revision rounds** — after 2 rounds, proceed with the latest version.

---

### Phase 4: Write the Full Presentation

Generate the complete markdown file following these rules precisely:

**File naming:**
- Look at existing files in `docs/presentations/` to determine the next sequential number
- Format: `NN-kebab-case-topic-YYYY-MM-DD.md`
- Use today's date

**YAML front matter:**
```yaml
---
title: "TITLE"
subtitle: "SUBTITLE"
author: "Phlux Technologies"
date: "YYYY-MM-DD"
theme: "metropolis"
fonttheme: "default"
fontsize: 10pt
aspectratio: 169
classoption:
  - "compress"
---
```

**Slide density and formatting rules (CRITICAL — these prevent Beamer overflow):**

| Rule | Value |
|------|-------|
| Bullet items per slide | 4-8 (never more than 8) |
| Default font size | `\small` at top of dense slides |
| Dense tables | `\footnotesize` before the table |
| Very dense data | `\scriptsize` sparingly |
| Table columns | Maximum 6 columns |
| Table text alignment | Left-align text, center-align numbers |
| Image width | `{width=95%}` for full-width, `{width=45%}` in columns |
| TikZ diagram width | Keep under 12cm wide |
| Two-column splits | Use `{.columns}` with `{.column width="50%"}` |

**Content rules:**
- Extract real data from source docs — **never invent numbers, specs, or claims**
- Every data point must trace back to a source doc or be clearly marked as an estimate
- Use section dividers (`# Section Title`) to organize into logical groups
- End with "Key Takeaways" or "Next Steps" or "Recommendation" slide
- Include comparison tables where trade-offs exist
- Use TikZ diagrams for architecture and data flow (see Appendix B for templates)
- Reference only images confirmed to exist in `docs/presentations/images/`

**Slide structure reference:**
- `# Section Title` = dark background section divider
- `## Slide Title` = white background content slide
- Content below `##` becomes the slide body

See **Appendix A** (Formatting Cheatsheet) and **Appendix B** (TikZ Diagram Guide) below for detailed syntax reference.

---

### Phase 5: Image Optimization

For every image referenced in the presentation markdown:

1. **Check size:** `bash tools/doc-tools/presentations/scripts/tools.sh info docs/presentations/images/<file>`
2. **Fit** if dimensions exceed 1920x1080: `bash tools/doc-tools/presentations/scripts/tools.sh fit docs/presentations/images/<file>`
3. **Compress** if file size > 500 KB: `bash tools/doc-tools/presentations/scripts/tools.sh compress docs/presentations/images/<file>`
4. **Trim** if it's a screenshot with whitespace borders: `bash tools/doc-tools/presentations/scripts/tools.sh trim docs/presentations/images/<file>`

Skip this entire phase if ImageMagick (`magick`) was not found in Phase 0.

---

### Phase 6: Build PDF

Build the presentation:

```bash
bash tools/doc-tools/presentations/scripts/build.sh docs/presentations/<filename>.md
```

**If the build fails**, diagnose and fix automatically:

| Error Type | Fix Strategy |
|------------|-------------|
| TikZ syntax error | Fix the TikZ code in the markdown, rebuild |
| Missing image | Remove the image reference or fix the path, rebuild |
| Undefined control sequence | Fix the LaTeX command, rebuild |
| Missing package (MiKTeX) | Tell the user to click "Install" in the MiKTeX popup, then rebuild |
| Missing package (TeX Live) | Tell the user to run `sudo tlmgr install <package>`, then rebuild |
| Font warnings | Ignore — preamble has fallback fonts |
| Overfull hbox warnings | Note for Phase 7 QA inspection |

**Maximum 3 rebuild attempts** for code-level errors. If still failing after 3 attempts, stop and report the error to the user.

---

### Phase 7: Visual QA Inspection

Read the built PDF page-by-page using the Read tool. Inspect **every page** against this checklist:

| Check | Severity | What to Look For |
|-------|----------|-----------------|
| Text overflow | CRITICAL | Text running off the right or bottom edge of a slide |
| Table overflow | CRITICAL | Table columns extending beyond slide margins |
| Missing/broken images | CRITICAL | White boxes, error placeholders, or missing figures |
| Invisible text | CRITICAL | White text on white background, or dark text on dark background |
| TikZ diagram clipping | CRITICAL | Diagram elements cut off at slide edges |
| Orphaned content | HIGH | A single bullet point or item alone on a slide |
| Tiny unreadable text | HIGH | Text smaller than `\scriptsize` that can't be read |
| Broken LaTeX rendering | HIGH | Raw LaTeX commands visible instead of rendered output |
| Empty/sparse slides | MEDIUM | Slides with fewer than 3 items (wasted space) |
| Giant text (wasted space) | MEDIUM | Default large font with only 2-3 items (should use more space or merge) |
| Back-to-back section dividers | MEDIUM | Two `# Section` slides in a row with no content between them |

**Fix loop (CRITICAL and HIGH issues only):**

1. If issues found, apply targeted fixes to the markdown:

   | Issue | Fix |
   |-------|-----|
   | Text overflow | Add `\small` or `\footnotesize`, or split slide into two |
   | Table overflow | Reduce columns, abbreviate headers, add `\footnotesize`, or split table |
   | Missing image | Remove reference or fix path |
   | Invisible text | Fix color commands |
   | TikZ clipping | Reduce diagram scale, use `[scale=0.9]`, or reduce `\w` value |
   | Orphaned content | Merge with adjacent slide |
   | Tiny text | Increase font size and split content across slides |
   | Broken LaTeX | Fix syntax |
   | Sparse slides | Merge with adjacent slide or add more content |

2. Rebuild the PDF (`bash tools/doc-tools/presentations/scripts/build.sh docs/presentations/<filename>.md`)
3. Re-inspect the changed pages

**Maximum 3 fix-rebuild-inspect iterations.** After 3 iterations, report any remaining issues to the user but deliver the PDF as-is.

---

### Phase 8: Delivery

Report to the user:

1. **PDF path:** Full path to the generated PDF
2. **Slide count:** Total number of slides
3. **Sources used:** List of source docs that fed content into the presentation
4. **Images:** Count of images used (noting any downloaded in Phase 2b)
5. **QA status:** PASS (no issues), PASS WITH NOTES (medium issues only), or ISSUES REMAINING (with details)

Offer:
- "Want me to adjust any slides?"
- "Want me to rebuild with changes?"

---
---

## Appendix A: Formatting Cheatsheet

### Slide Structure
- `# Section Title` — dark background section divider slide
- `## Slide Title` — white background content slide
- Content under `##` becomes the slide body

### Brand Colors (defined in preamble.tex, matched to phlux.io)
| Color | Hex | Usage |
|-------|-----|-------|
| `phluxdark` | #2D3039 | Dark charcoal slate (backgrounds) |
| `phluxaccent` | #FBAA36 | Golden amber accent (highlights) |
| `phluxsafe` | #2E7D32 | Safety green |
| `phluxwarn` | #E74C3C | Warning red |
| `phluxblue` | #1565C0 | Info blue |

### Slide Backgrounds
- Title slide (`\maketitle`): **dark** phluxdark background, white text, white logo
- Section dividers (`# Section`): **dark** phluxdark background, white text
- Content slides (`## Slide`): white background, dark text

### Logos
- `images/logos/phlux_no_tech.png` — white/light text, for dark backgrounds (title slide)
- `images/logos/phlux_white_gray_no_tech.png` — dark text, for light backgrounds

### File Locations
- Presentations: `docs/presentations/*.md`
- Images: `docs/presentations/images/`
- Logos (infrastructure): `tools/doc-tools/presentations/images/logos/`
- Preamble (styling): `tools/doc-tools/presentations/preamble.tex`
- Build script: `tools/doc-tools/presentations/scripts/build.sh`
- Image/PDF tools: `tools/doc-tools/presentations/scripts/tools.sh`
- Template: `docs/presentations/template.md`

### Tables
```markdown
| Column A | Column B |
|:---------|:---------|
| Data     | Data     |
```
For dense tables, prefix with `\footnotesize` or `\scriptsize`.

### Two-Column Layouts
```markdown
:::::::::::::: {.columns}
::: {.column width="50%"}
Left content
:::
::: {.column width="50%"}
Right content
:::
::::::::::::::
```

### Images
Path is relative to the presentation `.md` file's directory:
```markdown
![](images/filename.png){width=95%}
```

### LaTeX Sizing Helpers
- `\small`, `\footnotesize`, `\scriptsize` — shrink text to fit more content
- `\vspace{0.3em}` — vertical spacing
- `\alert{text}` — orange accent highlight (uses phluxaccent color)

### Block Quotes
```markdown
> Important insight or summary statement.
```

### Code Blocks
````markdown
```language
code here
```
````

### Numbered Lists
Use LaTeX for better Beamer rendering:
```latex
\begin{enumerate}
\item \textbf{First item} -- description
\item \textbf{Second item} -- description
\end{enumerate}
```

---

## Appendix B: TikZ Diagram Guide

TikZ diagrams render directly in slides as vector graphics. They look professional, scale perfectly, and use the Phlux color palette. Use them for architecture diagrams, data flows, comparisons, timelines, and memory maps.

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

**Brand colors in TikZ:**

| Color | Hex | Tint examples |
|-------|-----|---------------|
| `phluxdark` | #2D3039 | `phluxdark!40` (40%), `phluxdark!8` (very light) |
| `phluxaccent` | #FBAA36 | `phluxaccent!20` (light amber fill) |
| `phluxsafe` | #2E7D32 | `phluxsafe!10` (light green fill) |
| `phluxwarn` | #E74C3C | `phluxwarn!80!black` (dark red text) |
| `phluxblue` | #1565C0 | `phluxblue!12` (light blue fill) |

### Template: Block Diagram (Components + Connections)

Use for showing how boards, chips, or modules connect to each other.

```latex
\begin{center}
\begin{tikzpicture}
  \node[board] (a) {Component A};
  \node[board, right=2cm of a] (b) {Component B};
  \node[board, right=2cm of b] (c) {Component C};
  \draw[conn] (a.east) -- (b.west)
    node[midway, above, lbl] {Interface};
  \draw[connline] (b.east) -- (c.west)
    node[midway, above, lbl] {Cable}
    node[midway, below, lbl] {\$15};
\end{tikzpicture}
\end{center}
```

### Template: Adapter Chain (Multiple Hops)

Use for showing physical connection paths with adapters, cables, cost annotations.

```latex
\begin{center}
\begin{tikzpicture}[node distance=0.15cm]
  \node[board, minimum width=1.3cm, font=\tiny\bfseries] (src) {Source};
  \node[adapter, right=0.3cm of src] (a1) {Adapter\\A};
  \node[adapter, right=0.15cm of a1] (a2) {Adapter\\B};
  \node[board, minimum width=1.3cm, font=\tiny\bfseries, right=0.3cm of a2] (dst) {Destination};
  \draw[connline] (src.east) -- (a1.west);
  \draw[connline] (a1.east) -- (a2.west);
  \draw[connline] (a2.east) -- (dst.west);
  \node[lbl, below=3pt of a1] {\$200};
  \node[lbl, below=3pt of a2] {\$25};
\end{tikzpicture}
\end{center}
```

### Template: Safety Boundary Diagram

Use for showing trusted vs untrusted regions with bidirectional data flow.

```latex
\begin{center}
\begin{tikzpicture}[node distance=0.3cm]
  \node[font=\scriptsize\bfseries, text=phluxsafe!80!black] at (1.8,2.5) {TRUSTED};
  \node[font=\scriptsize\bfseries, text=phluxwarn!80!black] at (6,2.5) {UNTRUSTED};
  \node[font=\scriptsize\bfseries, text=phluxsafe!80!black] at (10.2,2.5) {TRUSTED};

  \node[safebox, minimum height=3cm, text width=2.8cm] (left) at (1.8,0.5) {
    \textbf{Safety Module A}\\[3pt]
    Function 1\\
    Function 2\\
    Watchdog
  };
  \node[unsafebox, minimum height=3cm, text width=2.8cm] (mid) at (6,0.5) {
    \textbf{Black Channel}\\[3pt]
    Transport layer\\
    \textit{Opaque byte forwarding}
  };
  \node[safebox, minimum height=3cm, text width=2.8cm] (right) at (10.2,0.5) {
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

Use for showing byte layouts, packet formats, register maps.

```latex
\begin{center}
\begin{tikzpicture}
  \node[pdufield, fill=phluxblue!12, minimum width=1.8cm] (f1) {Field A\\(4B)};
  \node[pdufield, fill=phluxblue!6, minimum width=1.8cm, right=-0.4pt of f1] (f2) {Field B\\(4B)};
  \node[pdufield, fill=phluxblue!12, minimum width=2.4cm, right=-0.4pt of f2] (f3) {Payload\\(NB)};
  \node[pdufield, fill=phluxaccent!15, minimum width=1.8cm, right=-0.4pt of f3] (f4) {CRC\\(4B)};

  \draw[decorate, decoration={brace, mirror, amplitude=4pt}, thick, phluxdark!70]
    ([yshift=-2pt]f1.south west) -- ([yshift=-2pt]f4.south east)
    node[midway, below=5pt, font=\tiny] {CRC covers all fields};
\end{tikzpicture}
\end{center}
```

### Template: Memory Map (Stacked Regions)

Use for showing address spaces, memory layouts, storage allocation.

```latex
\begin{center}
\begin{tikzpicture}
  \def\w{9}
  \fill[phluxblue!12] (0,0) rectangle (\w,-1.5);
  \draw[phluxdark!50, thick] (0,0) rectangle (\w,-1.5);
  \node[font=\footnotesize, align=center] at (\w/2,-0.75) {\textbf{Region A} (large)};

  \fill[phluxsafe!10] (0,-1.5) rectangle (\w,-2.2);
  \draw[phluxdark!50] (0,-1.5) rectangle (\w,-2.2);
  \node[font=\footnotesize] at (\w/2,-1.85) {Region B};

  \fill[phluxdark!4] (0,-2.2) rectangle (\w,-3.5);
  \draw[phluxdark!50] (0,-2.2) rectangle (\w,-3.5);
  \node[font=\footnotesize, text=phluxdark!60] at (\w/2,-2.85) {\textit{Free / Reserved}};

  % Address labels on left
  \node[font=\tiny\ttfamily, anchor=east] at (-0.15,0) {0x0000\_0000};
  \node[font=\tiny\ttfamily, anchor=east] at (-0.15,-1.5) {0x0100\_0000};
  \node[font=\tiny\ttfamily, anchor=east] at (-0.15,-3.5) {0x3FFF\_FFFF};

  % Total size brace on right
  \draw[decorate, decoration={brace, amplitude=5pt}, thick, phluxdark!50]
    (\w+0.15,0) -- (\w+0.15,-3.5)
    node[midway, right=7pt, font=\scriptsize] {1 GiB Total};
\end{tikzpicture}
\end{center}
```

### Template: Timeline (Parallel Pipelines)

Use for showing concurrent operations, scheduling, buffering.

```latex
\begin{center}
\begin{tikzpicture}
  \node[font=\scriptsize\bfseries, anchor=east] at (-0.2, 0.6) {Writer:};
  \node[font=\scriptsize\bfseries, anchor=east] at (-0.2,-0.3) {Reader:};

  % Writer row
  \fill[phluxblue!20] (0,0.2) rectangle (2.5,1);
  \draw[phluxdark!40] (0,0.2) rectangle (2.5,1);
  \node[font=\tiny] at (1.25,0.6) {Write A};

  \fill[phluxblue!20] (2.7,0.2) rectangle (5.2,1);
  \draw[phluxdark!40] (2.7,0.2) rectangle (5.2,1);
  \node[font=\tiny] at (3.95,0.6) {Write B};

  % Reader row (offset by one slot)
  \fill[phluxaccent!20] (2.7,-0.7) rectangle (5.2,0.1);
  \draw[phluxdark!40] (2.7,-0.7) rectangle (5.2,0.1);
  \node[font=\tiny] at (3.95,-0.3) {Read A};

  \fill[phluxaccent!20] (5.4,-0.7) rectangle (7.9,0.1);
  \draw[phluxdark!40] (5.4,-0.7) rectangle (7.9,0.1);
  \node[font=\tiny] at (6.65,-0.3) {Read B};
\end{tikzpicture}
\end{center}
```

### Template: Bus Diagram (Hub with Multiple Ports)

Use for showing interconnects, arbitration, multiplexing.

```latex
\begin{center}
\begin{tikzpicture}
  % Central hub
  \draw[phluxdark, thick, rounded corners=3pt, fill=phluxdark!5]
    (4,0.2) rectangle (7,-2.8);
  \node[font=\scriptsize\bfseries, phluxdark] at (5.5,-0.15) {Interconnect};

  % Input ports
  \node[font=\tiny, anchor=east] (p0) at (3.8,-0.6) {Port A (W)};
  \node[font=\tiny, anchor=east] (p1) at (3.8,-1.2) {Port B (R/W)};
  \node[font=\tiny, anchor=east] (p2) at (3.8,-1.8) {Port C (R)};
  \node[font=\tiny, anchor=east] (p3) at (3.8,-2.4) {Port D (W)};
  \draw[phluxdark!40] (p0.east) -- (4,-0.6);
  \draw[phluxdark!40] (p1.east) -- (4,-1.2);
  \draw[phluxdark!40] (p2.east) -- (4,-1.8);
  \draw[phluxdark!40] (p3.east) -- (4,-2.4);

  % Output
  \node[board, minimum width=2cm, minimum height=1.2cm] (out) at (9.5,-1.3)
    {Target\\{\tiny specs here}};
  \draw[conn, line width=1.5pt] (7,-1.3) -- (out.west);
\end{tikzpicture}
\end{center}
```

### Template: Interface Block Diagram (Boundary + Peripherals)

Use for showing a chip/FPGA boundary with internal blocks connecting to external devices.

```latex
\begin{center}
\begin{tikzpicture}
  % External source
  \node[board, minimum width=1.8cm] (src) at (0,0) {Source};

  % FPGA/chip boundary
  \draw[phluxdark, thick, rounded corners=5pt, fill=phluxdark!4]
    (2.5,1.5) rectangle (7,-1.5);
  \node[font=\scriptsize\bfseries, phluxdark, anchor=north west] at (2.6,1.4) {Chip Boundary};

  % Internal blocks
  \node[iicblock, minimum width=2.8cm] (b0) at (4.8, 0.7) {Block A};
  \node[iicblock, minimum width=2.8cm] (b1) at (4.8,-0.7) {Block B};

  % External targets
  \node[board, minimum width=2cm, minimum height=0.6cm] (t0) at (10, 0.7) {Device A};
  \node[board, minimum width=2cm, minimum height=0.6cm] (t1) at (10,-0.7) {Device B};

  % Connections
  \draw[connline] (b0.east) -- (t0.west) node[midway, above, lbl] {Bus 0};
  \draw[connline] (b1.east) -- (t1.west) node[midway, above, lbl] {Bus 1};
  \draw[conn, line width=1.2pt] (src.east) -- (2.5,0)
    node[midway, above, lbl] {Control};
\end{tikzpicture}
\end{center}
```

### TikZ Tips

- **Positioning:** Use `right=2cm of nodeA` (requires no manual coordinates)
- **Multi-line nodes:** Use `\\` for line breaks inside nodes (e.g., `{Line 1\\Line 2}`)
- **Vertical spacing in nodes:** `\\[3pt]` adds extra space between lines
- **Arrow offset trick:** `([yshift=6pt]node.east)` shifts the anchor up for parallel forward/return paths
- **Color tinting:** `phluxblue!12` = 12% blue (very light fill), `phluxdark!40` = 40% dark (medium gray)
- **Negative spacing:** `right=-0.4pt of node` eliminates gaps between adjacent fields
- **Boundary boxes:** Use `\draw[..., fill=...] (x1,y1) rectangle (x2,y2)` for chip/FPGA boundaries, then place nodes inside with absolute `at (x,y)` coordinates
- **Braces:** `\draw[decorate, decoration={brace, mirror, amplitude=4pt}]` for annotations
- **Sizing:** For full-width diagrams, use `\def\w{9}` or `\def\w{11}` and reference `\w`
- **Always wrap in** `\begin{center}...\end{center}` for proper slide alignment
- **Max width:** Keep diagrams under 12cm to avoid clipping on 16:9 slides

---

## Appendix C: Image Tools Quick Reference

Run from the project root:

```bash
bash tools/doc-tools/presentations/scripts/tools.sh <command> [args...]
```

| Scenario | Command |
|----------|---------|
| Check image dimensions/size | `bash tools/doc-tools/presentations/scripts/tools.sh info docs/presentations/images/photo.png` |
| Downloaded image is huge (>2 MB) | `bash tools/doc-tools/presentations/scripts/tools.sh fit docs/presentations/images/photo.png` then `compress` |
| Screenshot has extra whitespace | `bash tools/doc-tools/presentations/scripts/tools.sh trim docs/presentations/images/screenshot.png` |
| Need format conversion | `bash tools/doc-tools/presentations/scripts/tools.sh convert images/input.svg images/output.png` |
| Side-by-side comparison | `bash tools/doc-tools/presentations/scripts/tools.sh montage images/compare.png images/a.png images/b.png` |
| Remove EXIF/GPS data | `bash tools/doc-tools/presentations/scripts/tools.sh strip docs/presentations/images/photo.jpg` |
| Optimize all images before build | `bash tools/doc-tools/presentations/scripts/tools.sh optimize-all docs/presentations/images` |
| Crop to specific region | `bash tools/doc-tools/presentations/scripts/tools.sh crop docs/presentations/images/photo.png 400x300+50+100` |
| Extract PDF page as image | `bash tools/doc-tools/presentations/scripts/tools.sh pdf-extract-page deck.pdf 3 slide3.png` |

**Notes:**
- Commands modify in-place and create `.bak` backups (pass `--no-backup` to skip)
- `optimize-all` copies originals to `images/.originals/` first — non-destructive
- `fit` defaults to 1920x1080 and never upscales
- All commands require ImageMagick v7 (`magick` command)

---

## Appendix D: Build Error Troubleshooting

| Error | Solution |
|-------|----------|
| Missing package (MiKTeX) | Click "Install" when prompted, or set auto-install in MiKTeX Console |
| Missing package (TeX Live) | `sudo tlmgr install <package-name>` |
| Font warnings | Non-fatal — preamble falls back to default fonts |
| Image not found | Check path is relative to the presentation `.md` file's directory |
| Overfull hbox | Content too wide — add `\small` or reduce table columns |
| TikZ dimension too large | Reduce diagram scale or width |
| Undefined control sequence | Typo in LaTeX command — check spelling |
