# Native group timing discriminator

Owner: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.2.10.2`.

Preserve the original T1972 `pid=43538 setpgid undef errno=1` failure at
`7ee298c6958a61ff5600c22d1de164ff23b4f6ca`. This standalone native experiment
is not an original-test retry, containment bypass or repair.

Before execution the finite matrix is fixed: one child-only, parent-first,
child-first and intentional session-leader control, then 64 simultaneous
parent/child group-creation trials. A pipe holds each exact child for independent
parent PGID/SID queries. Child syscall return and errno are captured before any
query; each side observes the same live identity. No child executes another
program or creates descendants. Transfer waits, child/parent alarms and the
outer RAM guard bound failure; successful records require exact reaping and
include an independent post-wait liveness check. Timeout/protocol failure is
failure, never an admitted observation.

Compile and run once from the repository root with repository-local caches:

```sh
mkdir -p .artifacts/native-group-discriminator/module-cache
scripts/run_with_ram_guard.sh env \
  TMPDIR="$PWD/.artifacts/tmp" \
  CLANG_MODULE_CACHE_PATH="$PWD/.artifacts/native-group-discriminator/module-cache" \
  clang -std=c11 -Wall -Wextra -Werror -O0 \
  docs/audits/native-group-discriminator-20260927/probe.c \
  -o .artifacts/native-group-discriminator/probe
scripts/run_with_ram_guard.sh .artifacts/native-group-discriminator/probe \
  > .artifacts/native-group-discriminator/result.jsonl
```

The installed operating system, SDK and compiler are necessary read-only
external dependencies; no project output or cache is placed outside this volume.
Apple's published setpgid manual and open XNU source distinguish session-leader
rejection from parent/target and destination-group constraints. Published source
is not assumed to match the installed Darwin 27 kernel (xnu-13432.1.9).

Sources reviewed:
- <https://developer.apple.com/library/archive/documentation/System/Conceptual/ManPages_iPhoneOS/man2/setpgid.2.html>
- <https://github.com/apple-oss-distributions/xnu/blob/main/bsd/kern/kern_prot.c>
- <https://github.com/apple-oss-distributions/xnu/blob/main/bsd/kern/kern_proc.c>

A passing matrix cannot explain a spent failed child. A reproduced failure must
be classified using the recorded native state and independently checked cleanup
before selecting any production change. The retained result passes every ordinary timing control and records native EPERM
for the deliberate session leader. `python3 -B
docs/audits/native-group-discriminator-20260927/verify.py` verifies source/result
hashes, native identities, cleanup and corrupt-record rejection. Task `.10.3.1`
qualifies native syscall context capture before `.10.3.2` observes an original.
