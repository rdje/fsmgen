# Selected release readback and syscall-report qualification

Owner: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.2.15.7.3.12.4.1.3.4.4.3.10.1`.

This is a prospective execution contract. Its selector audit checks retained
healthy evidence and domain construction; it executes no release or file
fixture and does not qualify the failures described below. The enclosing
task owns their implementation and evidence join.

## Source domain

Use all source occurrences in the previously qualified ordinary-retired,
equal-reference-retired, active-runtime and last-observation healthy basis.
Resolve `NativeProxyImageCustody::_source` and its zero-based occurrence from
each new fixture's source-derived flow before entering release. Baseline
numeric IDs, paths, byte digests and descriptor numbers are provenance only.
Refuse a missing, duplicated, out-of-range or changed-profile selector before
allocation or execution as applicable. Bind the actual path, mode, bound and
original bytes before the selected read. Never throw after source return merely
to imitate a reader failure: that would change handle ownership.

At each occurrence select exactly one control:

| Control | Actual I/O | Report delivered to the unchanged reader | Expected handoff |
| --- | --- | --- | --- |
| `first-eio` | Open the original file; suppress the first read | Undefined count and EIO | Reader fails before returning a source |
| `partial-eio` | Delegate exactly one byte, then suppress the next read | First byte, then undefined count and EIO | Reader fails before returning a source |
| `early-eof` | Open the original nonempty file; suppress the first read | Empty buffer and zero count | Bounded reader rejects length mismatch |
| `body-xor` | Perform the real read; retain its complete actual result | XOR the first returned byte with hexadecimal 80; preserve count and remaining bytes | Reader and source return; the original consumer must reject altered content |

Each profile also has a fresh healthy case and a positive control which
delegates only one byte on its first source read, then delegates normally.
That positive case checks short-read continuation at the shared seam; it is
not a claim of every chunk size at every source occurrence. Empty sources are
outside this healthy basis. The earlier dedicated lower-reader empty, size,
mode and namespace controls remain separately dated support, not newly run
cross products.

Instrument sysopen and sysread before the original reader compiles. Preserve
argument aliases, arity, caller-sensitive paths and nonselected results. Keep
only a weak alias for a selected reader handle until the original reader
returns or unwinds. Probe that exact descriptor immediately at the boundary,
before another open could reuse its number. Record weak liveness and an actual
descriptor probe with observer-owned duplicates closed separately. A strong
alias counterexample must demonstrate that an observer could otherwise keep a
lexical handle open; any such recovery is explicit and excluded from genuine
implementation closure. Existing returned-source observations cannot prove
closure of a descriptor which never returned.

Record actual count, errno and bytes separately from reported count, errno and
bytes. A suppressed call has no actual syscall result. One-byte delegation has
the original requested count and the separately reduced delegated count. A
body alteration changes only the reported buffer, never the file or original
archive. Successful handoff must be followed through the real consumer and
its original cleanup owner; do not invent a source-close event for lexical
reader destruction. Verify complete source, directory and lock custody and
primary error precedence for the resulting actual prefix.

## Unlink and absence reports

For each profile select one failed-unlink control and both absence phases
(`after_unlink`, `finish`) crossed with modeled error and modeled presence.
Include one healthy case per profile in this partition.

For failed unlink, authenticate the sole selected hold path, suppress the
syscall and report zero with EACCES. Preserve the physically present original
hold. `unlink_attempted` is true; `unlink_completed` and historical absence
are false, and the latest check remains unset. This qualifies response to a
reported failure, not a naturally occurring operating-system rejection.

For absence controls the original unlink actually succeeds. At the selected
`lstat` inside the unchanged private absence helper, suppress the syscall and
either report no metadata with EIO or report the original admitted metadata
as modeled presence. Preserve the actual absent path. The error path must
retain latest state `unknown`; the presence path must retain latest state
`present`. Historical absence is false at the first check and remains true
when the later check fails. Do not relabel modeled presence as a physically
recreated hold or erase an earlier successful observation. Suppression and
actual named-state evidence must be independently distinguishable.

## Evidence and applicability

Each execution partition pins its sources, independent oracle and original
inputs before allocation. Preserve the first unexpected result, exact source
epoch, raw streams and exit without rerunning a producer to overwrite it.
Publish each complete immutable case only after its owned roots are absent.
Retain byte-exact recovery copies and a read-only saved-data audit.

The oracle must independently check selection, attempted versus real I/O,
actual versus reported bytes and errno, first failure, exact current effects,
historical/latest absence, input types and original archive/image/other-owner
identities. Keep active-runtime workspace/reference state and authenticated
last-observation setup distinct. In every profile final-reference removal
leaves the selected image intact. Require hostile evidence controls for lost
or invented reads, weak/strong ownership confusion, lost genuine closure,
counterfeit source handoff, lost original bytes, false unlink or absence,
foreign mutation, recovery masking and native authority. Keep caller-sealed
rejection and process/private-read/publication traps active.

Re-derivation of this plan uses the saved chronological events and source
handoff records. Its independent audit instead uses the ordered call forest
and completed absence intervals. Domain corruption controls must reject
omissions, duplicates, order changes, invented effects, source metadata
changes and widened authority. Exact input hashes, prospective script pins,
raw audit output, this contract, task tree, book and Git provide durability.
Execution, reader/consumer composition and syscall-report evidence are
explicitly missing until their owned children pass. Close-report/omission
cross products, arbitrary concurrent writers, native lifetime and historical
startup/parent qualification remain outside this plan; full CI/push stay gated.
