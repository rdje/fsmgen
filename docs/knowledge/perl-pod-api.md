---
id: perl-pod-api
title: POD API reference
answers:
  - "where is the Perl POD API reference?"
date: 2026-10-23
tags: [mdbook]
evidence: docs/book/src/11a-perl-api-reference.md
reverify: python3 -B scripts/generate_pod_reference.py --check
---
mdBook HTML build/serve generates this reference; see the guide.
