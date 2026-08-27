# Decision 0089: Linux logical-core discovery uses bounded kernel authorities

- **Status:** Accepted
- **Date:** 2026-08-27
- **Owner:** `DARWIN-INLINE-VERILATOR-RUNTIME-QUALIFICATION.3.2.2.2`
- **Refines:** [0056](0056-vial-scale-measurements-use-pinned-evidence-and-bounded-failure.md)

## Context

Architecture-scale evidence records a closed host profile, including the
online logical-core count. The original Linux implementation called
`POSIX::sysconf(POSIX::_SC_NPROCESSORS_ONLN())`. Exact pushed revision
`c7a222ac41db7b28d502accbb75fcdc6ed579754` showed that setup-Perl 5.32 does
not expose that constant: hosted shards 14 and 15 both aborted during host
profiling before their independent `t/1656` and `t/1657` oracles could run.

Linux already publishes the authoritative online CPU mask through sysfs. The
[kernel CPU topology ABI](https://docs.kernel.org/admin-guide/cputopology.html)
defines `online` as `cpu_online_mask`, whose CPUs are online and schedulable,
defines its format through `cpulist_parse`, and exposes `kernel_max` as the
maximum possible CPU index. `/proc/cpuinfo` supplies an independent, widely
available fallback when sysfs is unavailable or malformed.

## Decision

1. On Linux, read `online` and `kernel_max` directly from the kernel's CPU
   sysfs ABI. Parse only canonical decimal singleton/range lists that are
   strictly increasing, non-overlapping, and bounded by the reported kernel
   maximum. The count of listed online IDs is the logical-core count.
2. If either sysfs input is absent or invalid, count distinct exact
   `processor` identities from `/proc/cpuinfo`. Reject missing, malformed, or
   duplicate identities instead of inventing a value.
3. Bound every new operating-system read: 1 MiB for the compact online mask,
   64 bytes for `kernel_max`, and 64 MiB for the fallback CPU inventory. CPU
   indices must be canonical unsigned decimals no greater than signed 32-bit
   maximum. Oversize, reordered, overlapping, descending, or
   ambiguous input fails closed.
4. Preserve the host-profile schema and Darwin behavior exactly. These Linux
   kernel files are explicit read-only operating-system dependencies; project
   data, staging, publication, and persisted paths remain repository-local.

## Rationale

The kernel ABI is more portable across Perl builds than an optional POSIX
constant and more direct than launching `getconf` or `nproc` through mutable
`PATH`. Pairing the online mask with `kernel_max` prevents unconstrained input
from manufacturing impossible CPU identities. The independently structured
procfs fallback keeps ordinary Linux hosts measurable without converting a
missing primary authority into a guessed default.

Strict canonical parsing is intentional. Kernel-produced cpulists already use
that form, while rejecting exotic or redundant representations gives hostile
fixtures one deterministic outcome and keeps arithmetic bounded. This repairs
host evidence only; it changes no measurement schema, workload, backend,
runtime, support, performance, or capacity claim.

## Alternatives rejected

- **Keep `POSIX::_SC_NPROCESSORS_ONLN`.** Its availability varies with the Perl
  build and caused the exact hosted failure this decision repairs.
- **Run `getconf`, `nproc`, or shell text processing.** That adds executable,
  `PATH`, process, capture, and timeout dependencies to a simple kernel read.
- **Count `/sys/devices/system/cpu/cpu*` directories.** Present CPU directories
  need not mean online and schedulable CPUs.
- **Default to one core.** A fabricated value would corrupt pinned-host
  identity and could admit incomparable measurement evidence.

## Claim verification

- **Re-derivation:** parse representative sysfs masks against `kernel_max`,
  then independently count exact procfs processor identities when the primary
  pair is absent or malformed.
- **Falsification:** reject gaps in list grammar, overlap, descending or
  unsorted ranges, leading-zero ambiguity, out-of-range IDs, an oversized
  maximum, duplicate procfs identities, malformed records, and no authority.
- **Durability:** retain this decision, the owning task evidence, the canonical
  Knowledge Map card, mdBook rationale, and focused `t/1656` parser/runtime
  oracles; hosted routing keeps `t/1656` and `t/1657` in separate required
  shards so the exact setup-Perl boundary is exercised again at push cadence.
