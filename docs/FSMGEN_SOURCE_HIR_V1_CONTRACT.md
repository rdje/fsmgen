# FSMGen SourceHIR version-1 private contract

Date: 2026-07-30
Owner: `FSMGEN-HIR-ROADMAP-FRONTIER.3`
Status: selected and implemented privately by `.4`

The three private packages and `t/1547-source-hir-valid-ready.t` implement and
prove this exact contract without adding a public surface.

Post-prototype audit `.5` retains this version-1 contract privately and selects
a separate concrete-control-to-IAL1 design leaf before promotion is
reconsidered. This version-1 contract remains unchanged.

## Scope

This document freezes the first executable contract for the private
`FSM::IR::SourceHIR` architecture selected by decision `0028` and
`docs/FSMGEN_SOURCE_HIR_ARCHITECTURE_SELECTION.md`.

Version 1 models exactly one protocol-platform intent containing exactly one
protocol-neutral valid-ready channel. It does not model AXI aliases, APB, AHB,
bundles, concrete FSM/control intent, scheduling, lowered RTL, structural
connectivity, target HDL, or a public host-language API.

No implementation or public behavior changes in this contract-selection
slice.

## Package and method contract

The implementation leaf owns exactly these three private files:

- `perl/FSM/IR/SourceHIR.pm`
- `perl/FSM/IR/SourceHIRBuilder.pm`
- `perl/FSM/IR/SourceHIRPPIFRenderer.pm`

### `FSM::IR::SourceHIRBuilder`

The builder is a class-method-only private construction boundary:

```perl
my $diagnostics = FSM::IR::SourceHIRBuilder->validate_valid_ready($input);
my $source_hir = FSM::IR::SourceHIRBuilder->build_valid_ready($input);
```

- `validate_valid_ready($input)` accepts exactly one argument and returns a
  new array reference of private diagnostic hash references. It never mutates
  `$input`. An accepted input returns `[]`.
- `build_valid_ready($input)` accepts exactly one argument, performs the same
  validation and normalization, and returns `FSM::IR::SourceHIR`. If validation
  fails, it `confess`es the formatted first diagnostic. It never returns a
  partial object.
- Both methods reject function-style calls, object invocants, extra arguments,
  and non-hash input deterministically.
- The builder collects validation diagnostics in the field order specified
  below; unknown fields within one object are reported in lexical order.

This is an internal Perl construction path, not a supported Perl builder API
and not arbitrary-Perl-to-hardware compilation.

### `FSM::IR::SourceHIR`

Only the builder calls private constructor `_new_validated($normalized)`.
There is no supported `new` method. The object exposes these read-only methods:

```text
schema_version
root_kind
intent_name
profile
source_object
valid_ready_channel
provenance
source_location_for
as_hashref
```

`source_location_for($semantic_path)` resolves the exact path, then its nearest
ancestor, then `/`. The structured accessors, `source_location_for`, and
`as_hashref` return defensive clones. Scalar accessors return scalars. There
are no mutation methods.

### `FSM::IR::SourceHIRPPIFRenderer`

The renderer is also class-method-only:

```perl
my $rendered = FSM::IR::SourceHIRPPIFRenderer->render_ppif($source_hir);
my $diagnostic = FSM::IR::SourceHIRPPIFRenderer
    ->diagnostic_from_ppif_error($rendered, $error_text);
```

- `render_ppif($source_hir)` accepts exactly one validated SourceHIR object,
  mutates nothing, and returns the renderer result below.
- `diagnostic_from_ppif_error($rendered, $error_text)` accepts exactly one
  renderer-result hash and one scalar error, then returns one private
  diagnostic. It does not throw for a well-shaped renderer result.
- The existing `FSM::Adapter::IAL2::PPIF->parse_source($text, $source_label)`
  remains the only PPIF parser/validator handoff. The renderer does not call a
  generator directly.

## Exact input and object shape

Every object level is closed: an unlisted key is an error. Every listed key is
required, including `spans` even when it contains only `/`.

```text
SourceHIR v1
├── schema_version: integer 1
├── root_kind: "protocol_platform_intent"
├── intent_name: ISF identifier
├── profile: "valid-ready"
├── source_object
│   ├── id: PPIF atom
│   └── anchors: non-empty ordered array
│       └── anchor
│           ├── document: PPIF atom
│           ├── section: PPIF atom
│           └── page: PPIF atom
├── valid_ready_channel
│   ├── name: ISF identifier
│   ├── channel: ISF identifier
│   ├── role: "producer-to-consumer" | "consumer-to-producer"
│   ├── clock: ISF identifier
│   ├── reset
│   │   ├── signal: ISF identifier
│   │   ├── active_level: integer 0 | 1
│   │   └── kind: "async" | "sync"
│   ├── valid: ISF identifier
│   ├── ready: ISF identifier
│   └── payload: non-empty ordered array
│       └── item
│           ├── name: ISF identifier
│           └── width: positive integer
└── provenance
    ├── source_name: repository-relative or stable logical name
    └── spans: hash keyed by semantic path; `/` is required
        └── span
            ├── start_line: positive integer
            ├── start_column: positive integer
            ├── end_line: positive integer
            └── end_column: positive integer
```

An ISF identifier is `[A-Za-z_][A-Za-z0-9_]*`. A PPIF atom is a non-empty
scalar containing no whitespace, `(`, or `)`. Integers must be canonical Perl
integer scalars or digit-only scalar spellings accepted by the stated range;
the normalized object stores numeric integers.

The `valid`, `ready`, every payload `name`, and derived done endpoint
`<name>_valid_ready_monitor_done` must be pairwise unique, matching the current
ValidReadyChannel boundary. Payload order and anchor order are semantic and
must be preserved.

The builder checks fields in this deterministic order:

1. input kind and top-level unknown keys;
2. `schema_version`, `root_kind`, `intent_name`, `profile`;
3. `source_object.id`, then anchors in array order and
   `document`, `section`, `page` order;
4. `valid_ready_channel.name`, `channel`, `role`, `clock`, reset
   `signal`, `active_level`, `kind`, then `valid`, `ready`, payload items in
   array order and `name`, `width` order;
5. interface-name uniqueness; and
6. `provenance.source_name`, span keys in lexical order, then each span's
   `start_line`, `start_column`, `end_line`, `end_column`.

Validation may report more than one independent error, but it must not emit a
cascade below a value whose container kind is already invalid.

## Semantic paths and provenance

Semantic paths use RFC-6901-style JSON Pointer spelling. The root is `/`.
Version 1 recognizes the container and leaf paths implied by the tree above,
including decimal array indices, for example:

```text
/intent_name
/source_object/anchors/0/document
/valid_ready_channel/reset/active_level
/valid_ready_channel/payload/0/width
```

No `~` escaping is needed because all contract key names are fixed and contain
neither `~` nor `/`. A span key that does not identify a present version-1
container or leaf is invalid.

`provenance.source_name` must not be empty, machine-absolute, home-relative,
Windows-drive-prefixed, contain a backslash or NUL, or contain a `..` path
segment. Forward-slash repository-relative names and stable logical names are
accepted. The golden builder input uses
`source-hir/valid_ready_handshake.hir`.

Span coordinates are one-based and inclusive. The end must not precede the
start. Only `/` is mandatory. A missing leaf span resolves through the nearest
present parent span, so every diagnostic still has stable root provenance.

## Normalized golden input

The exact first input is semantically equivalent to this Perl structure:

```perl
{
    schema_version => 1,
    root_kind => 'protocol_platform_intent',
    intent_name => 'valid_ready_handshake',
    profile => 'valid-ready',
    source_object => {
        id => 'fsmgen-valid-ready-profile',
        anchors => [
            {
                document => 'FSMGEN-IAL2-VALID-READY-PROFILE',
                section => 'monitor',
                page => 'contract',
            },
        ],
    },
    valid_ready_channel => {
        name => 'data_link',
        channel => 'data_link',
        role => 'producer-to-consumer',
        clock => 'clk',
        reset => {
            signal => 'rst_n',
            active_level => 0,
            kind => 'async',
        },
        valid => 'valid',
        ready => 'ready',
        payload => [
            { name => 'data', width => 8 },
        ],
    },
    provenance => {
        source_name => 'source-hir/valid_ready_handshake.hir',
        spans => {
            '/' => {
                start_line => 1,
                start_column => 1,
                end_line => 14,
                end_column => 29,
            },
        },
    },
}
```

The input is cloned before normalization. Deliberately different Perl hash
insertion orders must produce deeply equal `as_hashref` results and identical
rendered bytes.

## Renderer result and source map

`render_ppif` returns a fresh closed hash with exactly:

```text
schema_version: 1
format: "ppif"
source_label: "source-hir-generated/<intent_name>.ppif"
text: canonical PPIF text ending in exactly one newline
source_map: ordered array of entries
```

Each source-map entry has exactly:

```text
semantic_path: recognized version-1 path
generated_span:
  start_line, start_column, end_line, end_column
source_location:
  source_name, start_line, start_column, end_line, end_column
```

Generated spans are one-based and inclusive and never include the newline.
`source_location` is the already-resolved exact/ancestor/root provenance for
the entry's semantic path. Entries are ordered by generated start line,
generated start column, shortest containing span, then semantic path.

The renderer emits clauses in this fixed order regardless of input hash order:

1. root and intent name;
2. profile;
3. source opener, object, anchors in input order;
4. valid-ready-channel opener and name;
5. channel, role, clock, reset, valid, ready;
6. payload opener and items in input order; and
7. closing parentheses on the final payload item line.

Reset renders as `<signal> active_low|active_high async|sync`, derived from
`active_level` and `kind`. Width always renders explicitly, including width 1.
There is no quoting or escaping because version-1 strings are restricted to
identifiers or PPIF atoms.

## Byte-for-byte golden oracle

The rendered golden must equal `ppif/valid_ready_handshake.ppif` byte-for-byte:

- lines: 14;
- bytes: 428;
- SHA-256:
  `6cbc68152c9e1658a341994bc2ccdd83bdb94b26aedd20d4180c996b5124f7ac`;
- line endings: LF; and
- final newline: present exactly once.

The implementation test reads the tracked fixture as bytes. It must not copy
or regenerate the fixture in the repository.

## Private diagnostic shape

Each diagnostic is a fresh closed hash with required keys:

```text
schema_version: 1
severity: "error"
code: stable code below
phase: "source_hir_validation" | "ppif_handoff"
message: one-line scalar without trailing newline
semantic_path: recognized path or `/`
source_location:
  source_name
  start_line, start_column, end_line, end_column when available
```

PPIF-handoff diagnostics additionally contain:

```text
downstream_message: first non-empty logical line of the caught PPIF error
generated_location: source_label plus line/column when extracted
```

The stable private codes are:

- `FSMGEN_SOURCE_HIR_INVALID` for input/schema/invariant failures; and
- `FSMGEN_SOURCE_HIR_PPIF_REJECTED` for a caught existing-adapter rejection.

The formatted `build_valid_ready` failure is exactly:

```text
Error [<code>] <source_name>[:<line>:<column>] <semantic_path>: <message>\n
```

Only the first diagnostic is thrown. Callers needing all failures use
`validate_valid_ready`.

## Downstream diagnostic remapping

`diagnostic_from_ppif_error` keeps only the first non-empty logical line of the
caught error so Perl stack paths cannot become persisted project diagnostics.
It searches that line in this order:

1. `<source_label>:<line>[:<column>]`; then
2. `line <line>` optionally followed by `column <column>`.

When a generated position exists, matching source-map entries are those whose
generated span contains the position. Selection prefers the smallest
containing line span, then the smallest column span, then lexical
`semantic_path`. The diagnostic uses that entry's path and resolved original
location.

When the current PPIF adapter supplies no generated position, or no entry
contains it, the diagnostic deterministically uses semantic path `/` and the
SourceHIR root location. The original first-line downstream message remains in
`downstream_message`; it is not rewritten as a SourceHIR validation claim.

## Focused implementation test owner

Implementation leaf `.4` creates only
`t/1547-source-hir-valid-ready.t` for this new boundary. The test proves:

- three packages compile and enforce class/argument boundaries;
- golden validation/build/accessors and defensive clones;
- closed-object unknown-key rejection and deterministic diagnostic order;
- missing/wrong schema/root/profile/container fields;
- invalid identifiers/atoms, roles, reset level/kind, empty payload,
  non-positive width, duplicate interface/derived-done names;
- invalid source names, semantic paths, span coordinates, and nearest-ancestor
  source-location resolution;
- deterministic normalization/rendering from reordered hashes;
- renderer-result and source-map closed shapes and defensive separation;
- exact 14-line/428-byte/SHA-256/final-newline golden equality;
- successful parse through `FSM::Adapter::IAL2::PPIF` with no direct generator
  call;
- deep equality of generated IAL1 text, generated IAL0 files, schedule report,
  and protocol report against parsing the tracked fixture;
- generated-line remapping plus the current no-line root fallback; and
- absence of a new CLI, normalized semantic/report key, capability-manifest
  field, or support-accounting entry.

The implementation also reruns the current forward-IR/normalized-contract and
valid-ready baseline used by `.2`, then the documentation, Knowledge Map,
memory, mdBook, task-acceptance, and doctrine gates.

## Public and retirement boundary

All APIs and diagnostic codes in this document are private. Version `1` is an
internal object contract, not a public schema advertisement. The implementation
must not add SourceHIR to CLI help, capability manifests, normalized reports,
`module_info`, support accounting, or installed public-language packages.

Audit `.5` rejects retirement and immediate promotion. These packages and
`t/1547` remain private while separate `.6` selects a concrete-control-to-IAL1
contract. That later contract must select its own migration/versioning rules;
version 1 does not imply them, and any public promotion must coordinate with
`IAL2-HOST-LANGUAGE-BUILDER-FRONTIER`.
