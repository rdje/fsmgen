# Native setpgid context witness

Owner: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.2.10.3.1`.

The original T1972 EPERM remains unexplained. This diagnostic-only witness
captures native state around the existing supervisor POSIX call. Production
code, arguments, call count, admission, deadlines and cleanup are unchanged.
It uses a Perl wrapper plus a read-only native context helper, without
process-wide DYLD injection or host-security changes.

`context.c` uses public getpid/getppid/getpgid/getsid and the running Perl's
public XS ABI. The native helper reports both caller and target PGID/SID plus
query errno. Queries are sequential snapshots, not an atomic kernel trace.
The wrapper saves incoming errno, calls the original POSIX function once,
captures its return/errno before another query, records the result, and restores
that errno before returning. Successful syscalls may retain incoming errno;
only a failed return makes that errno evidence of syscall rejection.

The context helper is qualified on the installed Darwin host and system Perl.
The system SDK, Perl headers and compiler are necessary read-only external
inputs. `build.py` derives their flags at runtime and places all outputs,
temporaries and compiler cache under `.artifacts/`. Compiler prefix mapping
keeps project debug paths relocatable. A scoped Clang diagnostic pragma handles
the installed Perl 5.34 XSRETURN macro; other warnings remain errors.

Verify the sealed qualification without running processes:

```sh
python3 -B docs/audits/native-group-witness-20260927/verify.py
```

To repeat only the bounded qualification from the repository root:

```sh
scripts/run_with_ram_guard.sh python3 -B docs/audits/native-group-witness-20260927/build.py
scripts/run_with_ram_guard.sh prove -Iperl -It/lib \
  docs/audits/native-group-witness-20260927/qualify.t :: unique_capture_name
python3 -B docs/audits/native-group-witness-20260927/verify.py \
  .artifacts/native-group-witness/unique_capture_name.jsonl
```

The capture name is exclusive; old evidence is never overwritten. The selected
fixture has one parent and one live child at a time. Rows use single O_APPEND
writes and are limited to 4096 bytes; complete accepted captures must fit
1,048,576 bytes. Pre-write size checks are defensive, not a global concurrent
reservation. The closed fixture's finite calls remain well inside that limit;
the verifier rejects partial, missing, duplicate-key, excess or foreign data.
This is not a generic logger for arbitrary concurrent producers.

Qualification covers ordinary, parent-first, child-first, actual session-leader
EPERM and successful stale-errno controls. Diagnostic writes deliberately set
EIO afterward to prove they cannot corrupt the real call's errno. The result
joins each native call to the unchanged supervisor outcome, executed child PID
or failed-child diagnostic, and exact cleanup. Independent postchecks find the
captured child PIDs and groups absent. Byte/row excess controls preserve existing
capture bytes. The verifier rejects altered syscall returns/errno, foreign PIDs,
wrong sessions, missing calls, false cleanup and malformed capture boundaries.

`manifest.json` binds producer, verifier and captured evidence bytes plus the
actual helper build identity. `qualification.jsonl` and `postcheck.json` retain
the complete observations. The helper binary is a local build artifact; its
recorded digest identifies that captured build, not a reproducible-binary claim.
The native matrix in `../native-group-discriminator-20260927/` supplies separate
public-call timing controls.

Next owner `.10.3.2` must consume this qualification and commit identity before
one instrumented original T1972 run. A successful original does not repair or
explain the previous failure. No original replay occurs in this slice.
