---
id: pdf-extraction-workflow
title: PDF extraction workflow for source-anchored evidence
answers:
  - "how should agents extract facts from chip-spec PDFs?"
  - "what is the PDF extraction workflow?"
  - "how do we extract PDF tables and diagrams?"
  - "where is the AXI PDF extraction approach documented?"
  - "what should be updated when the PDF extraction flow improves?"
date: 2026-06-12
status: current
tags: [pdf, workflow, source-anchors, documentation, chip-spec]
evidence: docs/PDF_EXTRACTION_WORKFLOW.md; docs/tasks/PDF-EXTRACTION-WORKFLOW-CAPTURE.md
reverify: rg -n "Tool Sequence|Tables|Diagrams And Images|Maintenance Rule" docs/PDF_EXTRACTION_WORKFLOW.md
---

`docs/PDF_EXTRACTION_WORKFLOW.md` is the durable workflow home for extracting
source-anchored facts from chip-spec PDFs such as the tracked AXI reference.

The workflow covers task-tree ownership, PDF metadata/hash checks, text
extraction, targeted search, page-window extraction, table handling,
diagram/image rendering, troubleshooting, cleanup, validation, copyright
hygiene, and the rule that every future improvement to the extraction flow
must update the document in the same task-owned slice.
