# PDF Extraction Workflow

Status: active workflow guidance for source-anchored PDF evidence extraction.

Task tree:
[docs/tasks/PDF-EXTRACTION-WORKFLOW-CAPTURE.md](tasks/PDF-EXTRACTION-WORKFLOW-CAPTURE.md).

## Purpose

This document captures the workflow used to extract source-anchored facts from
chip-spec PDFs such as the tracked AXI specification. It is written for this
repo and for other projects that want to replicate the same disciplined
approach.

The goal is not to mirror a PDF into the repository. The goal is to extract
only the facts needed for a task-tree-owned slice, preserve reviewable source
anchors, verify tables and diagrams when text extraction is ambiguous, and
commit a curated note instead of raw copyrighted dumps.

Whenever this workflow improves, update this document in the same task-scoped
slice that improves the flow.

## Invariants

- Create or activate a task-tree owner before extracting, rendering, or
  tracking any PDF-derived artifact.
- Track the source PDF only when the user provided it or the project needs a
  durable local reference. Do not track temporary text dumps or rendered page
  images.
- Record the source path relative to the repository root and a strong hash,
  usually SHA-256.
- Keep extraction products in `/tmp` or another disposable path unless a
  curated repo document explicitly owns them.
- Preserve source anchors by section, table/figure name, and PDF page number.
- Paraphrase source text. Do not paste long copyrighted passages into tracked
  docs.
- Separate source facts from inferred rules, abstractions, unsupported
  residue, and future implementation choices.
- If a table or diagram matters, verify it visually as well as through text
  extraction.
- If a missing tool would materially improve the extraction, say exactly what
  tool will be installed and why before installing or requesting approval.

## Tool Sequence

Use the smallest tool sequence that answers the owned question.

1. Confirm the source artifact:

   ```bash
   pdfinfo docs/vendor/arm/amba/axi/IHI0022_L_2025-08_AMBA_AXI_Protocol_Specification.pdf
   sha256sum docs/vendor/arm/amba/axi/IHI0022_L_2025-08_AMBA_AXI_Protocol_Specification.pdf
   ```

   Capture page count, encryption status, and hash in the curated note.

2. Extract a broad temporary text view when the topic is not yet localized:

   ```bash
   pdftotext -layout -enc UTF-8 SOURCE.pdf /tmp/project_pdf_layout.txt
   ```

   Use `-layout` first because chip-spec tables and signal lists often rely on
   columns.

3. Locate candidate sections with fast text search:

   ```bash
   rg -n "transaction identifier|ordering|interleav|outstanding|response" /tmp/project_pdf_layout.txt
   ```

   Search for exact signal names, table names, section titles, and likely
   synonyms. Prefer `rg` over manual scanning.

4. Extract only the relevant page window:

   ```bash
   pdftotext -f 90 -l 102 -layout -enc UTF-8 SOURCE.pdf /tmp/project_axi_a5.txt
   ```

   Work from a focused page-window file when writing the curated note. Keep
   the broad extraction only for navigation.

5. Review nearby pages, not only the matching line:

   ```bash
   sed -n '1,260p' /tmp/project_axi_a5.txt
   rg -n "A5\\.3|A5\\.5|A5\\.6|same ID|RID|BID" /tmp/project_axi_a5.txt
   ```

   Important rules often depend on surrounding scope, exceptions, or
   component-role sections.

## Tables

For tables:

- Use `pdftotext -layout` and inspect the whole table block.
- Cross-check table captions and row labels visually if the table is narrow,
  wrapped, or column-aligned.
- In the curated note, record the table name and the facts needed, not the
  whole table.
- If a row wraps across lines, rewrite the row as a paraphrased fact and keep
  the table anchor.
- If the table is too complex for text extraction, render the page and inspect
  it visually before deciding whether a fact is safe to record.

## Diagrams And Images

For diagrams, timing waveforms, and figures:

1. Render the exact PDF page to a temporary image. The available renderer may
   vary by machine. On this repo's current macOS environment, Xpdf
   `pdftoppm` is available:

   ```bash
   pdftoppm -f 100 -l 100 -r 144 SOURCE.pdf /tmp/project_page
   ```

   Xpdf writes zero-padded filenames such as
   `/tmp/project_page-000100.ppm`.

2. Convert if the inspection tool needs PNG:

   ```bash
   sips -s format png /tmp/project_page-000100.ppm --out /tmp/project_page_100.png
   ```

3. Inspect the rendered image with the available image viewer. Confirm labels,
   arrows, timing order, color/legend meaning, and captions against the text
   extraction.

4. Track only the conclusion in the curated note. Do not commit rendered page
   images unless a separate task explicitly owns them and licensing allows it.

Preferred alternatives when installed:

- `pdftocairo -png -f PAGE -l PAGE SOURCE.pdf /tmp/project_page`
- ImageMagick `magick` for conversion/cropping
- `mutool draw` for difficult PDFs

If none of the renderers are installed and visual verification is required,
state the missing tool and install or request approval before proceeding.

## Problem Handling

Use these fallbacks when extraction is poor:

- **Garbled text:** try `pdftotext -raw`, `pdftotext -layout`, and a smaller
  page range. Compare results.
- **Missing text:** check whether the PDF is scanned. If it is scanned, OCR is
  required; state the tool needed before installing it.
- **Broken columns:** render the page and inspect visually; record only
  verified facts.
- **Large diagrams:** render at a higher DPI such as `-r 200` or `-r 300`,
  then inspect/crop in `/tmp`.
- **Font-cache warnings:** if rendering succeeds and the visual output is
  readable, record the warning as non-blocking. If rendering quality is bad,
  fix the tool environment or use another renderer.
- **Encrypted or restricted PDF:** stop and record the blocker. Do not bypass
  access controls.
- **Spec ambiguity:** record the ambiguity as an open question or residue
  instead of forcing a design conclusion.

## Curated Note Pattern

A good evidence note should include:

- status and task-tree owner,
- source artifact path and SHA-256,
- extraction method and temporary-tool summary,
- source anchors with section/table/figure names and PDF pages,
- source facts,
- inferred rules or candidate design needs,
- explicit abstractions,
- unsupported residue,
- current conclusion and next exact owner,
- validation commands.

Do not claim implementation behavior unless code, tests, docs, and task-tree
ownership for that implementation have actually shipped.

## Cleanup

Temporary products should stay outside the repo. Typical temporary files:

- `/tmp/project_pdf_layout.txt`
- `/tmp/project_section_pages.txt`
- `/tmp/project_page-000100.ppm`
- `/tmp/project_page_100.png`

Remove large temporary files when they are no longer needed. Do not use
destructive cleanup commands in the repo unless the task explicitly owns them
and the files are known-safe generated artifacts.

## Validation

For a documentation-only extraction slice, run the checks that match the
changed surfaces. The current baseline used for AXI evidence/doc slices is:

```bash
mdbook build docs/book
prove -Iperl t/1256-feature-backlog-status-audit.t t/1303-isf-public-live-book-paths-audit.t t/1414-docs-relative-paths-audit.t
knowledge-map/scripts/check_knowledge_map.sh
scripts/check_memory_architecture.sh
git diff --check
```

If the slice adds code, generated artifacts, or user-visible behavior, expand
the validation set accordingly.

## Maintenance Rule

This document is the durable home for the PDF extraction flow. Every time the
flow improves, update this file in the same task-tree-owned slice and commit
that update with the rest of the work.
