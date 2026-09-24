# Inactive Proxy Lifetimes

Combined lifetime qualification now has a source-bound ordering contract.
It connects the current cleanup, observation, archive, release and maintenance
rules to their exact implementation bodies. A complete archive must precede
release of its observation hold. Private retirement and every reference to the
selected image must finish before that image becomes eligible for maintenance.

The planned profiles distinguish owners of the same image from owners of
another complete, valid image. An unrelated image's owner does not pin the
selected image. Archival can precede or follow private retirement because it
uses the retained snapshots. Repeated live-source checks still require current
runtime and private-source custody.

This verifies the proposed ordering domain, not the resulting runtime behavior.
Independent enumeration rejects missing source links, missing orders, weakened
dependencies and an incorrect dependency on another image's owner. The checks
below qualify modeled states, complete file lifetimes and synchronous control effects.
No native process, original qualifier or live canonical store is accessed.

```sh
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/native-proxy-lifetime-contracts-20260913/audit_corrected.py --verify-saved
```

The combined lifetime model now separates live sources from retained bytes.
Its same-image and different-image profiles start with distinct runtime owners
and observers sharing the same target snapshot. Every declared ordering is
checked at each prefix against an independent projection of completed events.

For example, retiring the target workspace makes fresh and repeated live-source
checks unavailable while observation holds continue retaining the image.
Archival can use the saved bytes after private retirement. Releasing an
observation requires its matching archive and complete settled work records.
Failed or cancelled command outcomes can still have settled cleanup.

Maintenance removes only the selected image after every reference to it is gone;
a healthy owner of another image does not prevent that removal. Invalid or
uncertain records preserve the corresponding hold. A modeled failure after
unlink reports failure while keeping the modeled removal visible; it does not
infer rollback from the returned verdict.

These are modeled effects, not filesystem observations. Constructed identities
and inert byte carriers are checked by the unchanged record codecs. The first
independent auditor failed on its own malformed-reference display assumption;
that failure and its narrow correction remain retained. The file checks below
qualify selected actual lifetimes and synchronous controls; native/live integration remains open.

```sh
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/native-proxy-lifetime-model-20260913/audit_corrected.py --verify-saved
```

The isolated-file lifetime harness has passed source and data admission.
Its selected schedules cover runtime retirement before observation release,
observation release before runtime retirement, archival after retirement, and
maintenance while a healthy owner of another image remains. Repeated
observations must preserve the original hold and strict source snapshots.

The planned file checks compare complete directory membership, bytes, modes and
native identities before and after each operation. They include the image
manifest and the archive's reused content files. An independent journal reader
also checks API receipts, descriptor closure and private-before-global removal.
Successful calls can retain a nonzero errno; that alone is not a failed call.

Cleanup is limited to newly created objects whose observed identities still
match. The first operation outcome is retained before cleanup. Unknown objects,
changed identities and journal failures preserve the affected files for recovery;
separate descriptor recovery cannot turn an incomplete operation into success.

Admission used inert data only. The tracing hook's initial optional-argument
signature error and the auditor's source-reconstruction errors remain retained
with their corrections. Actual file effects required the separately owned
execution checks below. Separate synchronous controls follow. Synthetic births and settled
work records do not authenticate a native process or authorize the live store.

```sh
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/native-proxy-lifetime-files-admission-20260913/audit.py --verify-saved
```

The selected isolated-file lifetimes now pass independent execution review.
The harness creates fresh private workspaces, runtime references, observation
holds and image files from inert bytes. Its full journal preserves source and
directory identities, API inputs and results, descriptor outcomes, and the
physical state before and after each selected operation.

For example, target retirement removes its private workspace before releasing
the runtime reference. Observation holds still retain the image, and archival
then copies the saved bytes even though the private source paths are gone.
Conversely, releasing archived observations first leaves runtime ownership
intact. Repeated observations preserve the original hold and strict snapshots.

Explicit maintenance removes the selected image only after its owners release
it. The different-image case also verifies that another healthy image and its
runtime survive that removal. The harness's final fixture cleanup is recorded
separately and removes only matching objects that the run created.

Independent checks confirm every selected complete state, matching archive and
settlement receipts, observed descriptor closure and absence of all fixture
roots. Altered ownership, archive identity, close outcomes and removal order
are rejected. The complete first-run journal is recoverable from tracked files;
verification reads that evidence without replaying the harness.

These results cover the selected complete file lifetimes. They do not qualify
interruption behavior, native process authentication or live-store integration.

```sh
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/native-proxy-lifetime-files-20260913/audit.py --verify-saved
```

The interruption-control matrix now has source and retained-call evidence.
The selected cases distinguish runtime references from observation holds,
reject release before archival or with unsettled work, and keep unknown owners
from making an image eligible for maintenance. A rejected repeated observation
after retirement is paired with successful archival from retained bytes.

The planned after-removal controls preserve the physical effect separately
from the API verdict. An interruption after private workspace removal should
leave the global runtime reference retaining the image. An interruption after
that global reference or the last observation hold is unlinked should expose
its absence while leaving image removal to explicit maintenance. A release
attempt can return a failure envelope after the unlink has happened; its
completion flags must not be promoted from an independently observed absence.

These are prospective predictions checked against current source bodies,
retained successful call prefixes and the earlier inert model. Changed
selectors, rollback assumptions and premature maintenance are rejected by the
matrix review. The following harness and final-admission sections qualify the
selected source/data paths. The matrix itself executes no interruption file test.

```sh
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/native-proxy-lifetime-controls-admission-20260913/audit.py --verify-saved
```

The control harness and independent reader now pass source and inert-data
qualification. The harness records each selected operation's exact return or
failure envelope, before/after file state and descriptor outcomes before
checking the expected rejection or beginning cleanup. Each opened object's
identity also joins an independently observed named object.

The planned fault mechanism raises a synchronous Perl exception after the
observer records the original successful removal call. Its scope ends
before subsequent probes, explicit maintenance and cleanup. This mechanism
does not simulate an operating-system kill or concurrent process interference.

Inert checks caught and corrected a missing-archive lookup that added a null
member to the original context. The corrected caller-input copy preserves
absence while still passing an explicit missing archive to release validation.
The failed first check and its source remain retained alongside the correction.

This qualifies the selected source/data paths and rejection checks. The final
admission below closes reader integration; actual execution is reviewed at the end of this chapter.

Final control admission now selects a corrected descriptor identity reader.
It follows recorded creation, writes and permission changes in call order,
then joins each open to the independently observed object and final state.
For example, publication creates a payload with read-only file permissions,
writes through its already opened descriptor, and later seals the executable
permissions. The reader must recognize the earlier mode while checking a
reread before sealing; assuming every new file starts writable is incorrect.

The first setup check exposed that assumption. Its failure and original reader
remain retained. The corrected reader passes the retained complete file
journals, including setup, archival and cleanup. Synthetic complete journals
also exercise rejected release, rejected retirement, retained ownership and
final cleanup. Altered creation metadata, missing writes, changed sealing and
incorrect cleanup evidence are rejected. These synthetic journals are reader
tests and do not establish actual interruption effects.

The execution permit requires committed final admission, unchanged pinned
sources, the active execution task, a normal user and fresh fixture/journal
paths. An existing permit cannot be overwritten. The separately owned execution
results follow below; native/live integration and startup qualification remain open.

The new synchronous control file run now passes independent execution review.
Runtime references and observation holds each prevent image maintenance while
present. Releasing before archival, repeating a release, supplying unsettled
or unsealed work, and retiring with incomplete cleanup all reject. Unknown
reference records also block maintenance. A rejected live-source reuse after
retirement leaves the retained archive available.

The after-removal controls confirm the predicted partial effects. After private
workspace removal, the injected error leaves the global runtime reference and
image present. After global reference removal, the injected error leaves the
image present until explicit maintenance removes it. The last observation-hold
unlink likewise removes the hold while returning a failed release envelope:
attempted remains set, while completion and verified-absence flags stay unset.
An independently observed absence does not rewrite that original API verdict.

The journal reader verifies the matching call, private-before-global order,
resource closure and the observed state on either side of the exception.
Only recorded descriptor closes follow each injected effect within its operation;
subsequent maintenance and final cleanup have their own recorded stages.
Cleanup removes only unchanged objects created by the run. Every selected
fixture root is absent afterward, and separate descriptor recovery is unused.

The complete first journal, permit, active task snapshot and raw outcomes are
retained. Missing records, changed errors or flags, reordered effects, open
handles and incomplete cleanup evidence reject. The current command verifies
these saved results and authenticates the retained source-admission chain;
it never replays the qualifier. These checks cover synchronous exceptions in
isolated files with synthetic process ownership. Operating-system kills,
concurrency, native process authentication and live-store integration remain
outside this result.

```sh
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/native-proxy-lifetime-controls-20260913/audit.py --verify-saved
```

The combined inactive lifetime contract is now closed for its declared scope.
The source ordering contract and independently checked state model describe the
same complete serial domain. Selected actual complete lifetimes and rejection
prefixes fit that domain, including archival after private retirement and
maintenance while an unrelated image retains its own healthy owner.

The final review joins source identity, archive and work receipts, actual
partial effects, original return flags and exact cleanup. It authenticates the
committed phase files and their pinned imports, and verifies retained original
raw evidence, including earlier nonzero outcomes. Changed ordering, missing
cases or cleanup roots, overlapping run ownership and promoted native authority
are rejected. The original qualifiers are not replayed.

Modeled coverage and actual-file coverage remain distinct: the finite serial
model is exhausted, while filesystem evidence covers the explicitly selected
complete and control cases. All their fixture roots are absent. Original clock
domains remain separate; no timing is inferred across language boundaries.

This also closes the inactive observation-custody activity together with its
record, census, acquisition, settled-release and frozen-version children.
Actual language-worker cooperation is qualified below. Native-proxy authentication,
real receipt transport, late-launch prevention, live-store/public integration
and the original startup/parent qualification still have explicit owners.

```sh
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/native-proxy-lifetime-closure-20260913/audit.py --verify-saved
```

Cross-language coordination now passes its admitted actual-worker qualification.
The selected macOS checks use preinitialized empty private stores, the current
Perl inspection transaction and an independent Python coordination peer.
For example, an actual Perl holder keeps a Python reader outside the protected
inspection until release; an actual Python holder likewise excludes the Perl reader.
Other selected cases cover a pending reader's deadline or cancellation, rejection
of a replaced lock and descriptor inheritance across exec. Descriptor probes run
before lock acquisition, including a deliberate omitted-seal countercontrol.

Admission binds the worker sources, installed interpreters, private process
ownership, storage, capture and wall limits. A worker receives commands only
after its native identity is admitted. Kernel ownership is recorded separately
so executable rejection does not strand an owned process. First outputs and
errors remain preserved, including bounded overflow evidence; uncertain process
or file state cannot be reported as successful cleanup.

The source review caught and corrected an interpreter identity assumption.
This installed Python uses a framework launcher and a distinct native application
image. The corrected admission checks exact paths and bytes for each, waits for
worker readiness before admitting the native image, and retains the observed
kernel image receipt. Substituting the launcher, another path with the same
basename, changed bytes or missing receipts rejects. This does not identify the
cause of the historical native-proxy startup failure.

The first admitted run succeeds in both language directions. A pending reader
reaches its own admission deadline while the holder keeps the lock. Terminating
a pending reader settles its process group before the holder is released;
this cancellation does not claim that the reader explicitly closed its descriptor.
Replacing the permanent lock makes both transactions reject its changed identity.
Sealed descriptors disappear across exec; the deliberately unsealed controls
observe the inherited descriptor and reject before lock acquisition.

The independent review joins the original worker output to the journal,
committed source admission, actual native executable receipts and exact cleanup.
Every worker and exec probe is reaped. A separate native census finds the original
controller and child births absent, and all worker groups absent. Only the run's
unchanged private objects are removed; every selected fixture root is absent.
First evidence is retained without replay, hidden recovery or discarded output.
Changed image receipts, cancellation verdicts, inherited descriptors, cleanup
records, raw streams or ownership-absence evidence reject.

The event reader, supervisor fault states, identity controls and permit states
retain their separate source/data qualification. Actual filesystem cooperation
now closes this selected empty-store scope. Native-proxy authentication, real
receipt transport, late-launch prevention, live/public integration and the
historical startup qualification remain pending. These checks do not publish or
execute a proxy image, exercise live capture, or activate the canonical store.
Recheck the retained actual result without launching any worker:

```sh
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/native-proxy-language-coordination-20260913/audit.py --verify-saved
```

The remaining protocol requirements now have an explicit source/evidence map.
Passing empty-store coordination does not establish populated publication,
authentic runtime receipts or canonical native execution. The closure audit
keeps these scopes distinct and assigns the missing work before activation.

The generated-wrapper permission mismatch is repaired in the inactive retirement
prototype. Its exception matches only `rust-tool-resolution` directly inside the
owned private workspace. Generic file permissions, ownership, link counts,
byte limits and stable-identity checks retain their prior rules.

The retained inert run reproduces the original rejection without changing the
workspace, then completes retirement with the repaired guard. It checks existing
private modes, nearby names, nested paths, aliases and the file-size boundary.
For example, a sibling named `rust-tool-resolution.extra` or a wrapper inside a
nested directory gains no permission exception. The private workspace disappears;
the released reference disappears; the shared image remains unchanged.

These process-cleanup receipts are synthetic. The result establishes the narrow
filesystem compatibility repair; authentic compiler-workspace profiles and
capacity remain unqualified. Earlier audits remain evidence for their pinned
source revisions. The current re-verification commands below check this repair
and the retained compiler-profile inventory.

The original compiler receipts retain generated C and executable identities;
the successful observer also retains the wrapper. These selected files do not
prove which other files the compiler left in its cache or temporary directory,
their permissions, directory depth or total size. The inventory preserves those
original records and tests hypothetical omitted files that leave the selected
identities unchanged while violating cleanup policy. These examples demonstrate
missing evidence; they are not observed compiler defects.

The separately admitted compiler-only census now retains complete settled
workspaces for the fixed nonzero and decoy modes. It records actual files and
ownership before cleanup while preserving current limits. It does not execute
a generated proxy, wrapper, original test or collector.

Read-only installation checks found that both the compiler bytes and the default
SDK now differ from the original admissions. The older SDK version remains
installed, but its directory identity also changed. A matching old version label
does not establish identical SDK contents. The new census must use the current
fixed builder selection and revalidate its exact epoch before execution.

This establishes an installation change, not a cause for the historical startup
failure or a prediction of new output bytes. SDK dependency contents and loaded
compiler libraries are not exhaustively attested. The required installed OS and
toolchain inputs are read-only dependencies on the OS volume; project evidence
continues to stay on the repository volume.

The compiler-only census completed after its committed source admission and
fresh installed-input checks. Its one-use permit is consumed. The original
builder kept its existing arguments, environment and supervision limits.
Do not repeat the issuer, runner or cleanup commands; use the saved audit below.

The procedure records the original compiler exit and settled process group,
then accounts for every workspace directory, file and link. A separate reader
compares complete membership, identities, permissions and file contents before
exact cleanup. The source-derived wrapper and relative Cargo link are controlled
additions; neither is executed. A missing entry, changed file, incomplete capture
or failed compiler stops the sequence and preserves the workspace for diagnosis.
The actual profiles now agree with the independent complete-node census.

The first invocation stopped at Git preflight, before permit consumption,
workspace creation or compiler launch. Ordinary Git used a personal ignore rule
for `.claude/settings.local.json`; the closed environment exposed that file as
untracked work. A repository-only ignore check reproduced the difference.
The original permit and failed output remain preserved and cannot be reused.
The repaired admission selects repository-local Git ignore policy explicitly.
Only the exact local settings file is ignored; shared configuration remains
visible. Ordinary and closed Git views now agree. The installed Git launcher is
pinned and checked before admission queries; this does not attest its loaded
image or libraries. The fresh committed admission subsequently produced the
selected authentic profiles without consuming or clearing the original permit.

Source checks must also produce their required evidence. An stdin-fed Python
check returned success without running its program because the RAM guard starts
its command asynchronously with empty default stdin. The corrected invocation
passes a tracked script by filename and verifies the resulting installed-input
record. The original empty output remains retained as a failed qualification.

Original compiler receipts record successful exits and settled process groups.
The retained full-byte captures and independent node maps agree on every owned
entry. Both selected profiles fit the existing node, depth, per-file and total
byte limits. Cache and temporary directories contain no leftover entries.

Independent review also reconstructs every recorded remaining-workspace hash
through the exact removal sequence. Both private roots are absent. This proves
these selected compiler profiles and their controlled unexecuted roles; it does
not qualify generated-proxy execution, populated workers or live integration.

The workspace compatibility join now connects the wrapper repair and actual
compiler profiles to the same unchanged retirement source. It preserves the
exact wrapper mode exception and all existing capacity limits. The inert
wrapper test's cleanup receipts remain synthetic; they do not authenticate real
compiler, outer or inner ownership. This join runs no compiler or fixture.
The populated-store worker results below extend that inactive evidence.

The selected populated-worker cases cover equal and different publication,
independent runtime references, observation holds across retirement, and
cancellation of runtime or observer owners. They use inert bytes through the
current Perl transaction APIs; a Python controller supervises the workers.
The earlier Python peer remains qualified only for empty-store coordination.
The one-use run is complete; its first records and independent review are retained.

The fresh controller repairs the inherited recovery gap. A no-process model
showed that an exited child can still have unread output: inherited recovery
required native admission before draining it. The original source and first
result remain preserved. The repaired controller collects that terminal result
and output without signaling the dead child or inventing native admission.

For example, a child that exits before its identity check now keeps its original
admission failure while recovery drains its pipes. A live child that fails
admission can receive bounded termination through its exclusively owned Popen
handle. Native executable admission remains a separate prerequisite for commands.
This requires a main-thread controller, default SIGCHLD handling, no other
waiters, and a fixed worker that does not fork. A surviving group remains
unresolved; the controller never signals an unknown surviving member.

Source models exercise partial launches, parser errors, output limits, deadlines,
cancellation and close failures. Recovery preserves the first failure; incomplete
cleanup or missing output cannot become a successful worker result. The admitted
workers completed the fixed cases, and independent review confirms their
original records and cleanup. The final cooperative-lifetime evidence join is
complete. Retirement and observation-work settlement records remain synthetic; the
worker cancellations now have separate actual process evidence.

The worker accepts only its declared case, role and next command. Small commands
select fixed operations; source-bound files carry activation and original handoff
records by digest. Snapshot bytes travel as hexadecimal octets, including NUL and
non-ASCII bytes. A recovery peer adopts the original acquisition after the
controller settles the cancelled owner; it never reconstructs custody from files
that happen to survive.

For example, an observer can retain the original wrapper, reference pair and
source image while the publisher retires its private workspace. Maintenance must
still reject that image until the observer archives those original snapshots,
settles its selected work and releases its hold. The fixed cases exercise:

| Case | Selected actual lifetime check |
| --- | --- |
| Equal publication | Shared bytes retain independent runtime references. |
| Different publication | Removing an unreferenced image preserves the other image. |
| Observation across retirement | The hold survives removal of the private workspace. |
| Equal references with an observer | Remaining runtime and observation owners prevent maintenance. |
| Cancelled runtime owner | Its reference remains until the peer adopts and retires the original acquisition. |
| Cancelled observer owner | Its original snapshots remain usable after publisher retirement and handoff. |

Cancellation cuts occur after lock acquisition and before census or mutation.
The selected actual run records native ownership and busy-lock events before
commands advance. Original handoffs survive the held cancellation cuts; recovery
peers adopt them only after the cancelled owners settle.

A release success flag alone is insufficient. The worker requires the complete
receipt to retain the original lock, image, archive and settlement bindings, plus
the final reference-absence result. An adversarial missing-receipt check exposed
this gap in the draft protocol; the repair and first failure are retained.

The final admission binds the exact committed controller, worker, installed
interpreters and selected modules to the active execution task. It retains the
authorizing task and memory bytes with the permit, so later pointer updates do
not erase the original authorization. Existing output, changed source, stale
frontiers or incomplete qualification reject before fixture allocation.

During equal publication, the driver must observe the peer report a busy lock
before releasing the first publisher. Before a cancelled-owner handoff, it seals
the original acquisition and settles the actual child and process group. Only
then may the recovery peer adopt that acquisition. The selected run supplies
actual contention and process records, which the independent reviewer joins.

Cleanup requires the original object identity and final mode as well as known
bytes. An equal-byte replacement does not inherit custody. Model checks exposed
missing inode and final-mode checks in the draft cleanup; both are repaired with
their first failures retained. Unknown objects remain unresolved and owned.
Known partial publication bytes are removable only before complete custody was
retained, and only after every constructed worker has settled.

An independent reviewer reconstructs the command order, original snapshots,
remaining references, archives and cleanup from the complete retained records.
It separately checks actual native births and terminal/group-absence evidence.
All selected worker groups settled and every case root was removed. Original
snapshots and archive bytes survive in the retained result records. The cancelled
workers exited on the requested termination signal; their terminal captures and
group-absence checks are complete. Source bounds remain prospective model
encodings; the actual run has separately retained measured records.

The selected populated-worker activity is complete. Its results are joined with
the earlier empty-store qualification through the same coordination and custody
code and recorded interpreter byte identities. Each run keeps its own process
and clock records. The Python peer remains qualified only for empty-store
coordination; populated publication and observation use the fixed Perl worker.

The final review also challenges altered actual records. For example, changing
the lock inode in a handoff and updating the file and command digests still
rejects: it no longer describes the original acquisition. Changing a cancelled
worker's terminal exit to successful completion also rejects, even with matching
controller receipt copies. Missing source archives, release custody, native
absence, process-group closure or owned-root evidence cannot become success.
These checks use retained records without repeating the worker run.

Actual-wrapper observation also remains an owned integration repair. Observation
acquisition currently requires wrapper mode `0700`, while the retained actual
compiler profiles use `0755`. The inert worker cases keep their established mode;
the integration task must qualify an exact compatibility exception before using
the actual wrapper. No actual-wrapper observation attempt is claimed here.

The receipt-ownership inventory is now explicit. The public supervisor result
records cleanup flags, wait classification and timing, but not the process or
group identity used to settle the child. That identity remains in private
supervisor state. The compiler census observer reads that private state and
retains two direct-fork receipts; their public results still omit the identity.
Retirement of the proxy workspace inspects only the caller-supplied cleanup
flags. The populated worker constructs a fixed compiler/outer/inner tuple, so
those records remain synthetic and distinct from its actual worker absence
receipts. No launch frontier is closed by this inventory, and no compiler,
worker, proxy or collector is rerun.

The inactive adapter now reviews private supervisor states rather than a
caller-built cleanup array. Compiler, outer and inner roles must appear in
that order, each with a distinct birth, a finished capture and the original
cleanup hash stored by that state. Copying the flags into a new hash fails.
An open frontier cannot count as settled ownership, and a closed frontier
rejects another launch. This check launches nothing. It does not prove that a
live compiler or worker produced the state.

Retained compiler journals do not close that proof. Each settled row keeps a
process id, a finished phase and copied cleanup flags for compilation only.
It omits the birth clock, the group identity and the private cleanup identity
the adapter requires. Its recorded scope is the original direct fork, not a
general receipt. The populated worker still emits a fixed synthetic
compiler/outer/inner tuple. Those records remain evidence of earlier runs;
they cannot settle the adapter.

The admission plan names the current compiler, probe and tool-resolution
stages in order, with private process identity and cleanup identity required
for review. The compiler uses `rust_proxy_compiler_group`, the outer probe uses
`rust_tool_resolution_probe_group`, and the inner stage uses
`rust_parity_process_group`. Admission rejects the formerly mistaken inner
policy that copied the outer probe. A process-free test intercepts the actual
Rust parity stage request to keep admission aligned with its producer.
Replay of an original fixture or proxy and live collection remain rejected.
The admission module itself launches nothing. These policy names do not prove
nested cleanup: an outer group's absence cannot settle a separate inner group.

The current supervisor makes each child its own process-group leader, then
checks group absence with that same identity. The inactive adapter now accepts
a finished private state only when its group identity equals its leader birth.
A group that names a different process still fails, as do a copied cleanup
hash, a caller-supplied cleanup array, a missing stage and a closed frontier
that tries to launch again. No compiler, probe or tool-resolution process has
run under this contract.

The public supervisor result still omits the process id, birth clock and
original cleanup identity. It now returns a copy of the cleanup flags, so a
caller cannot mutate the private hash the receipt review binds. That key set
stays on schema version 1. A sealed caller can read a finished job and receive
one observation that returns the private process id, birth clock and own-group
identity while keeping the original cleanup hash. Copying that hash still
fails the aligned review. An unsealed caller and an unfinished job are
rejected. No compiler, probe or tool-resolution process runs to produce the
observation.

The sealed launch returns the finished private job for both pre-process
failure and a completed process; ordinary callers still receive only the
public result. A supplied environment replaces the child's environment and
stays on the private job. The receipt observation derives its role from the
stage: compiler, outer probe, or inner tool resolution. A finished compiler
observation can bind on its own; the complete ordered receipt set also binds.
These paths have proof-process coverage, without a compiler capture.

`receipt_bound` also reviews one original outer or inner observation against
its expected role while the issuing supervisor still holds its private state.
Each role must match its exact stage; an outer receipt labelled with an inner
stage rejects. The existing `receipts_bound` ordered-prefix review uses the
same checks and rejects reused identities. Both require a closed frontier,
settled cleanup and the original cleanup hash. Independent stage acceptance
does not prove a complete stage set, authenticate a process, authorize another
launch or make a serialized cleanup address reusable in a later process.

Launch admission and finished-job review are separate. After issuing and
consuming a matching revision-bound permit, `begin_compiler_capture` grants a
compiler attempt before a job exists. It burns that grant before returning;
a repeated request, changed revision, altered token, replay or live collector
is rejected. Failure or later receipt review never restores the grant.
`execution_allowed` retains its compatibility name but only reviews a job
already returned; it does not authorize a process launch or prove receipt
ownership. The separate receipt adapter still owns that review.

This grant is process-local. The fixed audit driver in
`docs/audits/native-proxy-receipt-capture-20260923/capture.pl` adds an exclusive
attempt record before preparation and a launch record before the supervisor
call. Records are flushed and synced, including their directory entries. A
restart encounters the original attempt and rejects before another grant.
The driver wraps the existing compiler fixture, preserving its command,
environment and public result while retaining the sealed private observation.
It writes that first observation before accepting cleanup or success, and
keeps evidence and the workspace on failure. It does not execute the generated
proxy or clean up the workspace automatically.

The capture test models success, launch refusal, compiler failure, copied
cleanup, unsettled cleanup and native-wait disagreement. These controls launch
no compiler. The separate compiler-only capture has now completed from a clean
committed revision. Its first native wait status and public result agree on
success; leader reaping, group absence and original cleanup sharing passed.
An independent read-only process-table observation confirmed dated absence.
The first records and exact unexecuted output bytes are retained under
`docs/audits/native-proxy-receipt-capture-20260923/result/`. The original
workspace remains for later owned stages; its compiler attempt is permanently
spent. Saved review checks the original Git sources and artifact bytes without
rerunning the producer. This proves only the compiler stage. Recorded birth
values are the supervisor's wall-clock observations, not kernel-authenticated
births. Zero microseconds at a second boundary are valid; negative, fractional
and out-of-range microseconds reject. A serialized cleanup address cannot
restore live receipt authority.
Probe and tool-resolution admission, native proxy execution and live collection
remain closed.

```sh
python3 -B docs/audits/native-proxy-receipt-ownership-inventory-20260922/audit.py --verify-saved
perl docs/audits/native-proxy-receipt-adapter-20260922/qualify.t
perl docs/audits/native-proxy-receipt-admission-20260922/qualify.t
perl t/1818-process-supervisor-receipt-observation.t
perl t/1820-native-proxy-receipt-capture.t
perl t/1821-native-proxy-receipt-stage-contract.t
python3 -B docs/audits/native-proxy-receipt-capture-20260923/review.py --verify-saved
python3 -B docs/audits/native-proxy-receipt-capture-20260923/qualify_review.py
```

| Remaining work | Required result |
| --- | --- |
| Real receipt binding | Compiler evidence is retained. Admit and capture the probe and tool-resolution stages without replaying the compiler or borrowing serialized receipt authority. |
| Inactive adapter composition | Join preparation, native path/reference admission and observation custody before the separate native experiment. |
| Final protocol join | Check current evidence together and retain native, live/public and startup/benefit gates. |

The current builder still returns private preparation records, the live sampler
still admits private proxy paths, and path-scoped collection still uses the
private fixture prefix. Qualified private format codecs do not change those
consumers. Live collector outcomes, policy records and public projection support
remain required before any product activation.

```sh
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/native-proxy-wrapper-compatibility-20260913/audit.py --verify-saved
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/native-proxy-compiler-profile-inventory-20260913/audit.py --verify-saved
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/native-proxy-compiler-profile-admission-20260913/epoch.py --verify-saved
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/native-proxy-populated-controller-20260913/audit.py --verify-saved
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/native-proxy-populated-worker-execution-20260914/audit.py --verify-saved
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/native-proxy-populated-lifetime-join-20260914/audit.py --verify-saved
```

[Return to runtime measurement](16dc-vial-portable-verilator-runtime-measurement.md).

## Private process handoff

A private reservation component now establishes a process group and can move
back to its caller's group while retaining its unreaped child identity. Its
owner explicitly retires group signalling before releasing and reaping that
child. Unexpected departure or EOF preserves the first failure; unknown wait
status and uncertain group absence cannot count as cleanup. The focused
controls use independent child membership and wait observations, including a
silent handoff and a stuck release. They exercise the current host; Linux
execution remains a missing qualification leg.

The private gated pair now records a direct command child before allowing it
to join that reserved group. Join acknowledgment precedes reservation departure;
departure acknowledgment precedes an explicit exec release. Advancing a ready
pair alone cannot execute the command. Cancellation revokes queued release,
and partial handoff failures preserve the original cause and actual child waits.
The focused controls also bypass the exec gate deliberately: independent output
observations detect that broken behavior even when the release flag stays false.

Before release, a capture owner can receive the pair's streams in a retained
record. The handoff publishes that ownership while signals are masked; an
interrupted return leaves the receiver available for cleanup. Pair retirement
cannot close those transferred handles again. The shared reader keeps the
existing separate-stream, aggregate-prefix and control-EOF behavior.

The private group-closure driver now cancels exec before signalling, stops an
unjoined command by its owned PID, and uses the reserved group only after
acknowledged departure. All affected jobs can receive the same remaining
cleanup deadline. TERM, KILL and reservation release/reaping share that wall;
advancement never waits synchronously or starts a second cleanup allowance.

Cancellation can move the reservation even when the command has not joined.
A stopped command can therefore remain in the caller's group after the reserved
group becomes empty. Cleanup keeps the owned positive command PID eligible for
KILL until join acknowledgment; it also handles any remaining reserved group.
Group-only escalation would miss that command. The native control observes
both memberships and requires the engine to consume both child waits before
its independent rescue can run. Caller-group signalling is never substituted.

For example, after a joined command ignores TERM, group KILL can finish it
while its reservation still needs release or termination. Exact reservation
reaping proves that resource closed even if its wait reports a signal; its
original status and failure remain separate observations. Successful resource
closure cannot erase command failure or surviving descendants. The driver
harvests the direct command before probing group absence, requires actual
ESRCH, and retires group signalling before releasing the reservation. Unknown
waits, uncertain absence and missed closure deadlines remain incomplete.

Independent tests query group absence before reservation retirement and retain
the native result for final assertions. After reaping, a numeric PID or PGID
may be reused; probing it cannot prove the earlier closure. Exact child-wait
consumption remains a separate check and requires ECHILD after the owned wait.

Native controls also kill the retained reservation on both sides of departure.
Before acknowledgment, both child waits can settle while group closure remains
unproved. After acknowledgment, actual group disappearance can close resources
even though reservation death remains the job's original host failure. A stopped,
joined command forces escalation in both cases; independent EOF proves it never
executes. These checks observe the dead reservation without reaping it early.

The inactive reserved job now composes launch, capture, cleanup and terminal
results. Its invocation wall includes admission and launch; a ready command
still waits for explicit publication-controlled release. Separate binary output
uses the existing aggregate prefix limit. The first observed failure survives
later cancellation or cleanup failure, while the exact command wait and later
closure observations remain independently visible.

For example, a command's nonzero exit remains its reported failure if a later
cleanup observation is incomplete; the result also retains false cleanup flags.
The public result has the same closed fields. Its private receipt keeps the
original cleanup hash and names distinct command and reservation/group births.
The historical own-group receipt adapter still refuses that distinct-group
receipt. Separate reserved receipt review now checks the original receipt and
cleanup against records retained by the creating job. It requires distinct
command/group births, exact command and reservation waits, retired signal
authority, closed capture and proved group disappearance. Copies, replacements,
changed stages and incomplete closure cannot substitute for those records.

For example, replacing a returned receipt and its cleanup address does not
replace the creator's retained originals. A nonzero or signaled command may
still have settled resources. Review itself performs no process operation and
grants no launch or release authority. Stage models and an ordinary Perl child
qualify this boundary; they do not authenticate kernel birth, establish complete
stage transport or qualify the retained compiler/proxy captures.

The coordinator can now borrow creator-bound descriptor inventories from the
endpoint, service and reserved job. They include the endpoint directory anchor,
accepted sockets and transferred capture streams, and exclude closed handles
and borrowed close lists. Independent children verify the complete foreign set
is closed before handoff acknowledgment. Inspection duplicates no handle and
grants no admission credit or cleanup authority.

The inactive admission ledger now retains the root and nested jobs before any
native preparation. Each job reserves a job slot, two direct-child slots and
the pair's peak of sixteen descriptors. Run and connection owners reserve
additional descriptor capacity from the same total. The ledger distinguishes
unallocated reservations from reported live resources; a reduction cannot
silently reacquire released capacity. These are trusted owner reports, not
kernel observations or proof of cleanup.

The selected inclusive bounds remain eight jobs, eight logical levels, sixteen
direct children and 128 descriptors. Closed results retain their job slots
until delivery is settled. For example, eight retained jobs still block another
job even if one has closed all its resources but its result remains pending.
Parent retirement also waits for every descendant outcome to retire.

Original invocation time determines the wall, including admission. A root
starting at second 99 with a twenty-second timeout expires at second 119.
A child starting at second 100 with a thirty-second timeout also expires at
119 because its ancestor expires first. Preparation and launch cannot renew
either deadline. Cancellation revokes the retained subtree before cleanup;
possible partial effects remain charged until the owner reconciles them.

Only the creator's original retained grants authorize ledger transitions.
Copied grants, another ledger's grants, inherited owners and replayed starts
reject. Wire job numbers are monotonic and never reused after retirement;
exhausting the unsigned identity range rejects further admission. This pure
model creates no descriptors or processes. The coordinator now binds native run
construction, root/nested gated jobs and accepted peers to these reservations.
Execution publication and nested caller transport remain open.

Endpoint construction now offers a resource-free prepared run and a separate,
single-use start. The owner can retain that run before entropy, directory or
socket effects begin. Signals stay masked through construction publication;
a pending handler may interrupt the return, but the original owner still holds
the endpoint and its cleanup state. Partial failures preserve their first
cause, while the existing convenience constructor closes its local owner if
its return is interrupted. A prepared or failed run cannot publish authority.

The run descriptor budget includes the saved caller directory and the directory
iterator beside the listener and directory anchor. Native allocation observers
qualify this peak and the temporary cleanup handles. Aggregate integration must
reserve this scratch capacity as well as the steady descriptors. This retained
endpoint interface creates no process; the coordinator owner described below
binds it to the admission ledger.

The reserved job, gated pair and group reservation also expose resource-free
records before pipe allocation. Their original objects survive allocation;
there is no returned replacement that the coordinator must recover after a
signal. Allocation rechecks borrowed descriptor inventories and the original
wall before each pipe, and publishes every prepared state before unmasking
signals. A preparation failure remains the first cause through cancellation.
An interrupted successful allocation leaves its live handles with the retained
owner; the convenience preparers close their local owners before propagating
such an interruption. None of these preparation paths may fork or release exec.

For example, if the original wall expires between two pipes, the second pipe
is not created and the already retained ends close during failure cleanup.
If a signal is queued while a pipe is created, the handler runs after the full
job, pair and reservation are published. The interrupted job cannot start,
and its owner can finish cleanup using the existing bounded closure driver.
Independent native handoff checks now also use this retained-record path;
the coordinator now binds root and nested gated jobs to original ledger grants.

The inactive coordinator now binds native run construction to the original
root admission record. It retains separate credits for the steady endpoint
and temporary construction/cleanup handles before creating any of them.
Every creation allocation checks the original root lifetime and the creator's
original grants. Cleanup retains its scratch credit after root admission is
revoked and uses the original bounded closure envelope. The root job's unused
preparation capacity remains reserved during this run-only stage.

Copied or reused credits, cancellation, insufficient aggregate capacity and
an expired root reject creation before native effects. A later failure keeps
the original cause and all outstanding charges until cleanup is consumed.
Unexpected directory contents prevent retirement and keep those charges, even
when the native descriptors have closed; retry cannot turn that failure into
success.
Actual pending-signal controls observe both the retained endpoint and its
reconciled descriptor charges before the coordinator return is interrupted.
The coordinator then refuses context publication and can close the exact run.
Accepted-connection accounting now joins the same original ledger, as described
below. The coordinator can create gated jobs but cannot release execution.

Root preparation now retains the complete native job before creating any pipe.
Each pipe checks the original grant, its preparation phase, remaining lifetime
and aggregate capacity. Successful preparation replaces descriptor reservations
with actual retained handles while keeping future child slots and cleanup
scratch reserved. The coordinator includes those job handles in its aggregate
inventory; the native job borrows the run handles for later child closure.

For example, cancellation between pipes refuses the next allocation and keeps
the original job reachable for cleanup. A pending creator signal sees both the
prepared native graph and reconciled ledger before it can interrupt the return.
That interruption revokes future admission. Unstarted cleanup consumes the
original native closure result before retiring the root and endpoint; neither
a copied observation nor closed pipe ends alone can release its ownership.

Native start now accepts an optional owner check at each fork. The check runs
inside that fork's signal mask and returns the current foreign descriptor set.
The component validates the actual union with its own handles, including
closed or duplicated entries, before forking. For example, a descriptor added
after preparation or between reservation and command creation must appear in
the corresponding fresh inventory. Independent children check those actual
handles are closed before acknowledging handoff.

The command retains the caller's original exec mask and prepared dispositions;
it does not inherit the temporary admission mask. Both child identities are
published before restoring signals. A pending creator interruption remains the
job's first error while cleanup retains the recorded reservation's handshake.
Treating that interruption as a failed native handshake would prevent group
closure. A reported mask-restoration failure remains a separate native failure.
The coordinator now binds these hooks to original starting grants. Each fork
checks admission, ancestor lifetimes and retained capacity again. These checks
grant no exec release.

Repeated cancellation can now shorten cleanup that is already running. An
earlier shared ancestor wall advances the group escalation threshold and any
pending reservation retirement to that same deadline. Later requests cannot
renew the original grace. The masked update rechecks the current wall, so an
earlier deadline installed by a handler just before masking cannot be
overwritten. First failure, retired signal authority and exact wait ownership
remain unchanged. A pending creator signal observes both clipped
walls before it can interrupt the return.

For example, a stopped command or a stopped reservation already being retired
must receive KILL under the shorter wall, then have its exact wait consumed.
Independent native controls observe that escalation and retain group absence
before identity retirement. The coordinator uses this clipping when cancellation
joins already-running cleanup into an affected subtree.

The inactive coordinator now retains detached nested requests and their original
grants under a signal mask before returning admission. An interrupted return
revokes the request while leaving its grant reachable for cleanup. A nested
preparation or start failure preserves healthy root and sibling admission.
Native start and advancement use each fork's own mask so the command retains
the original caller's exec signal state. Only the actual ready handoff changes
reserved child credit into retained child accounting.

For example, preparing a sibling after a reservation fork adds descriptors that
the later command fork must close. Each fork gets a fresh aggregate inventory
excluding only its own job. Copied grants and excess capacity cannot reach a
native effect. Cancellation revokes the entire selected subtree before native
cleanup and publishes a common remaining wall, including any earlier native
cleanup already in progress. A settled descendant retains its result slot;
its spent cleanup clock cannot expire a later live sibling or parent.

Whole-run close advances bounded cleanup without sleeping. It reports pending
while a child remains and retains resource charges and the endpoint. Once exact
native closure is established, it closes the endpoint and retires descendants
before parents. Closed descriptors alone cannot release an incomplete native
closure. In this pre-exec scope, cancelled outcomes keep their logical slots
until whole-run close consumes them; result delivery belongs to later work.

The transport service now has an explicit shared-endpoint constructor. Closing
that service revokes parent authority and closes accepted sockets while leaving
the original endpoint with the aggregate owner. Expiry, root revocation and a
fatal accept use the same lifetime boundary. The standalone constructor still
retires its own endpoint. A closed shared service reports the remaining borrowed
endpoint handles until the aggregate owner retires them.

For example, an accept failure can stop admission while gated native jobs still
need cleanup; it must leave the listener and directory identities with their
original owner. Service close masks signals until accepted-peer outcomes and
the complete cleanup result are published. A pending creator handler can then
interrupt return without stranding resources. Re-entry before masking rechecks
completion, and a partial close with no completed result remains retryable.
Uncertain accepted-socket cleanup stays failed even if the handles closed.
Copied service records cannot retire the original owner's custody.

Accept now creates the original ticket before invoking an optional admission
callback. `advance($check)` calls that callback with the original service and
ticket under the preparation signal mask, immediately before native accept.
Returning false defers the effect; invalid returns or exceptions fail admission.
The service rechecks its original wall and authority before the syscall. The
socket is written directly into the retained ticket, and connection construction
borrows that handle. Pending creator signals see complete sealing and ownership
publication before they can interrupt the return.

For example, a constructor exception after accepting a socket still leaves the
original service holding that socket for cleanup. A transient accept with no
socket can discard its empty record. Both deferred and transient attempts spend
their ticket identities; they never reuse an identity. A partial accept with a
live handle remains owned even if its return also reports a transient error.
The original authentication wall is never extended by an admission callback.

`tickets` and `ticket_observation` return copied observations; `handles` includes
the retained raw socket even if Connection has already removed its own handle
field. Closing retries any remaining actual socket without erasing an earlier
failure. While native closure is pending, even a standalone service retains its
endpoint. Closed outcomes occupy admission slots until explicitly consumed, and
`take_closed` refuses any record that still owns a live handle. Its
`resources_closed` flag also preserves an uncertain native close verdict.
The aggregate coordinator now retains grants and consumed outcomes before
unmasking their caller's return.

Opening a coordinator run retains a shared service with the original root
deadline. `advance_service` first records the service's ticket, then checks live
authority and reserves its descriptor before native accept. Even expiry inside
that callback leaves a recoverable failed ticket. Full descriptor capacity
defers accept without a native effect. Empty transient attempts release only
their own unused reservation; actual sockets become held descriptor charges
under the same aggregate signal mask.

`peer_tickets` and `peer_observation` expose copied ownership observations.
`retire_peer` closes a selected connection, preserving its first cause. In this
pre-execution integration, closed peer outcomes keep their slots and conservative
descriptor credit until whole-run close, just as native job outcomes do. A
closed slot therefore cannot admit another peer prematurely. Per-peer result
delivery, acknowledgement and slot reuse belong to the later publication work.

For example, a second socket accepted between a reservation fork and its command
fork appears in the latter fork's fresh foreign inventory. That child closes
the socket before its handoff acknowledgment. Subtree cancellation revokes both
ledger and existing transport parent authority before native job cleanup; root
cancellation closes all admission. Registering and publishing new parent
contexts automatically still belongs to ACCEPT delivery, before exec release.

Whole-run close advances native cleanup even when transport closure throws.
The first exception survives a later successful resource cleanup. A pending or
uncertain peer close retains the endpoint and aggregate charges. Only verified
closure of jobs and peers allows outcome consumption and endpoint retirement.
The coordinator stores every original peer outcome before asking the service to
consume it, so an interrupted consumption return remains recoverable through
`peer_observation`. Copied observations grant no native authority.

Service now also offers `transfer_request($ticket, \$slot)` for a destination
that its caller retained before the call. It transfers the selected original
pending request into an empty, untied scalar slot. The packet carries the
original ticket, parent, detached request, clipped execution `deadline_ns` and
separate fixed `admission_deadline_ns`. This moves the existing snapshot; it
does not create a second retained copy or reserve a job.

For example, an aggregate owner can pass `\$peer->{request}` after retaining
that peer entry. Service publishes the packet there before deleting its own
snapshot and marking the ticket `handed`. A pending creator signal observes
both completed custody changes. Even if that handler interrupts the return,
the original peer entry still holds the full request. The legacy `take_request`
API retains its existing return-value contract.

Transfer rechecks destination occupancy, original ticket state, parent authority
and all original walls after masking. An occupied or tied destination,
unknown/repeated ticket or copied/inherited Service cannot transfer custody.
If native scalar assignment fails, Service keeps its pending snapshot. Expiry
returns false with an empty destination and retains the timeout cause. A signal
that fills the destination or retires the peer before masking cannot be
overwritten by stale state. Later EOF or repeated SPAWN closes the transport
while the caller keeps any already-transferred packet for its own cleanup.
This packet conveys data custody only. The aggregate now joins it to original
peer/job admission and gated ACCEPT as described below; nested exec release remains open.

Parent registration now retains its original `preparing` record and spends
its monotonic job identity before requesting a token from the OS random source.
Preparation and publication share the signal mask. The service rechecks the
original parent/run deadlines and endpoint before and after token/context
construction; only a fully `ready` record can authenticate HELLO.

`parent_context($id)` recovers that same original ready context after checking
current authority and lifetime. It creates no new token. For example, a pending
creator handler can interrupt `register_parent` after publication; the original
Service still holds the completed context for recovery. The original root
context remains unchanged. `parent_observation($id)` copies the preparation
state, deadline and failure without exposing a token. Its `ready` state records
completed preparation; a later expired or closed endpoint still refuses context
recovery and provides no live submission authority.

A failed token or context return leaves a failed parent record and a spent
identity. The record occupies its bounded logical slot until explicit revocation,
and a partially constructed context cannot authenticate it. Revoking a failed
slot permits a fresh higher identity; it cannot reuse the old one. Invalid
lifetimes refuse before spending an identity or reading entropy. Pre-mask
re-entry also cannot overwrite a registration completed by the handler.

`register_parent($id, $deadline_ns, $check)` now accepts an optional allocation
check. Before each native token-source open or read, it receives the original
Service, parent identity, `create` role and `entropy_open` or `entropy_read`
operation. Registration keeps its preparation mask and rechecks the original
parent, endpoint and lifetime both before and after that callback. These internal
checks also run when the optional callback is absent.

Allocation checks refuse by throwing; their return value is ignored, matching
the existing endpoint allocation contract. For example, a check can reject an
expired grant before the OS source opens, or before another short read. A check
that revokes the parent or consumes its remaining lifetime cannot authorize the
following effect by returning normally. Failure preserves the spent parent
identity and first preparation cause; the local entropy scope releases its handle.

The lower-level `Endpoint::new_job_token($check)` passes only role and operation;
its caller owns authority checks and signal-mask scope. Its original no-argument
form remains valid.
Native read observers verify each attempt without publishing token bytes, and
weak handle observations avoid prolonging the local source during unwinding.
The aggregate coordinator now binds these checks to its original grant and
separately retained scratch descriptor credit, as described below.

For example, expiry between token generation and context construction retains
a timeout, not a ready authority. A lost native token return retains a host
failure even though the OS read occurred. A signal observes the complete ready
record and closed entropy handle before interrupting return. Context recovery
still grants only submission under that logical parent. Ledger binding now
precedes native preparation; command release remains a subsequent step.

`Wire::snapshot_with_context($snapshot, $context)` now creates a detached SPAWN
snapshot with exactly `FSMGEN_PROCESS_COORDINATOR_CONTEXT` inserted or replaced.
It validates both the incoming snapshot and context syntax, normalizes execution
scalars through the byte codec, then checks the complete transformed frame again.
It preserves the original invocation start, arguments, cwd, umask and every
unrelated environment entry in strict byte order. It never merges the
coordinator's current environment into another invocation.

For example, replacing an old private context leaves an empty argument, a
newline-bearing environment value and a similarly prefixed environment key
unchanged. Inserting a missing context needs an available environment slot;
replacement at the full pair count does not add a slot. A longer context can
exceed the aggregate execution-byte bound even when the original snapshot fits.
Either refusal leaves the original snapshot and live environment untouched.

This pure transformation checks syntax and byte bounds. A syntactically valid
context is not evidence of live authority. The aggregate coordinator obtains
the original context from its admitted Service/grant; final checks before command
release remain separately owned. Literal wire
frames and inclusive count/byte boundaries qualify the helper without an endpoint
or command process.

The coordinator now binds the root snapshot while opening its original run.
Nested admission retains the original grant and snapshot, registers that job's
context, then replaces only the private environment entry before native
preparation. Registration follows admission order even when native jobs start
in a different order. For example, jobs two and three receive their own contexts
when reserved; preparing job three first cannot spend or substitute job two's
identity. The caller's snapshot stays unchanged.

Every nested token open/read checks the original Service, grant, job identity,
reserved job capacity and clipped deadline. Steady run credit and unused scratch
credit must remain separate and sufficient. Snapshot replacement then rechecks
the ledger and original Service authority before publishing `context_state` as
`ready`. An oversized transformed snapshot fails while its original snapshot
and run remain owned for cleanup.

The complete context/snapshot binding is retained before unmasking creator
signals. A pending handler can interrupt the admission return, but it sees the
matching completed state; failure revokes further job admission and preserves
cleanup ownership. Copied observations expose only the preparation state, not
the context bytes. Fresh authority checks also precede native preparation,
each pipe, each fork and live advancement. Revocation refuses the next effect.
The original native fork masks remain responsible for the eventual exec mask.
These changes create gated processes but do not release commands. Original
accepted-request ownership now joins them through the admission and gated ACCEPT
paths below; explicit root release follows below and nested release remains open.

The aggregate also retains the identities of its original Endpoint, Service and
job entries. Every later owner lookup checks the complete retained job inventory;
a missing entry cannot silently remove its native descriptors from that inventory.
Service separately retains the identity of the Endpoint it borrows. A different
original Service exposing identical context bytes still cannot replace the
Service that bound the invocation.

Each job retains the exact context value used to transform its snapshot. Fresh
context lookup requires both live Service authority and equality with that
original value. For example, replacing a nested job's context with its parent's
still-live context refuses preparation. Copying the job entry while keeping its
original grant also refuses; grant identity alone does not establish entry custody.
These checks preserve the original snapshot bytes and invocation deadlines.

Native wrapper identity is retained before its first pipe allocation and remains
required for observation, inventory and advancement. A different original wrapper,
a shallow copy or a lost wrapper cannot substitute for the job already admitted.
Creator signals see the completed owner/context associations before an interrupted
return; cleanup retains the first failure. The focused controls restore deliberately
substituted references before closing their original resources and independently
check pipe EOF, exact child waits and endpoint removal. These private integrity
checks add no aggregate execution-release API.

`Coordinator::admit_request($ticket)` explicitly selects one original accepted
peer. Under the preparation mask, it transfers that peer's validated request
directly into its retained record, joins the submitting parent's original active
grant, and reserves one child grant. Both peer and child retain their association
before the first token-source open or read. The method returns the original
grant; the original inventory and copied peer observation also preserve its
identity if a creator handler interrupts the return.

For example, admitting the second of two pending requests cannot consume the
first request or reuse its ticket. A repeated admission refuses without
revoking the completed association. A handler that admits the same peer just
before masking wins that single-use transition; the interrupted caller cannot
overwrite or cancel it. A peer retired at that boundary creates no child grant.

Each token and later native admission checks the original peer and transferred
packet, matching parent and child grants, original source-parent authority,
clipped execution deadline and fixed admission wall. None of these steps renews
the handshake budget. Capacity refusal retains the transferred request without
inventing a grant. Later failures preserve any spent original grant and their
first cause for cleanup. Completed snapshot binding releases the redundant
source snapshot slot; copied observations omit packet and context bytes.

When service advancement observes EOF or an unexpected repeated request, or the
owner explicitly retires the peer, reconciliation fails its request and cancels
the associated job before further preparation. Descriptor charges remain held
until exact whole-run cleanup. This admission method creates no job pipes or
children and queues no ACCEPT. The explicit start/advance composition below
matches native gated readiness to the original peer before publication.

Connection now offers `queue_accept($job)` for one tracked ACCEPT on the
original connection, and `accept_publication` for a copied observation. The
original record exists before queue admission and retains its job, encoded
frame size, confirmed byte count and state. Generic `queue` remains available;
only the explicitly tracked frame updates this observation.

For example, if READY precedes ACCEPT and a stream frame follows it, completing
READY confirms no ACCEPT bytes. Completing ACCEPT publishes its own result even
while the stream queue remains nonempty. An already partially written stream
must finish first so the wire framing stays contiguous. Byte-at-a-time writes
confirm each successful byte; EAGAIN confirms none. The final byte changes the
state from `writing` to `written` and makes `published` true.

Write effects, queue credit and the original publication record update under
the preparation signal mask. A pending creator handler sees the complete
retained result and restored SIGPIPE disposition before it can interrupt the
return. Re-entry just before masking rechecks closure and the original walls.
Queue activity cannot renew a no-progress deadline, and partial progress cannot
extend the invocation deadline. The tracked frame uses the existing encoded
control-queue capacity without a second transcript or growing receipt registry.

A partial frame that closes becomes `failed`, retaining its first cause and
confirmed prefix. An uncertain native write return or SIGPIPE restoration
failure cannot confirm completion, even if an independent peer received bytes.
A completed local-write fact remains observable after later closure. It proves
neither remote acknowledgement nor current peer health or authority to execute.
Copied and inherited Connection records cannot inspect or change the original
publication; inherited cleanup closes only the child's descriptors. Binding this
observation to original Service requests is described below; native gated-job
readiness and final release remain the aggregate coordinator's responsibility.

`Connection::advance($write_check)` now optionally admits each socket write
through a trusted owner's callback. It receives the original Connection under
the preparation signal mask, after read progress and before the native write.
Returning `0` defers output without consuming queue bytes or renewing the
no-progress deadline. Returning `1` permits the attempt only after fresh closure
and original invocation/no-progress checks. The guard applies to that advancement;
an owner that requires admission must supply it on every pass.

For example, an ACCEPT written one byte at a time requires admission for every
attempt. A callback that closes the peer's record prevents the following write,
even if it returns success. A callback that throws or returns anything except a
boolean closes the connection, retains its first failure and propagates the
refusal; a later unguarded call cannot release those queued bytes. Pending creator
signals observe the completed write transaction and confirmed publication before
interrupting the return. The no-callback API retains its existing behavior.

`Connection::inspect_input()` gives its original owner a fresh read-only pass.
It performs at most one bounded nonblocking read or peek and returns a copied
observation with `state`, `buffered_bytes`, `frame_ready` and `failure`. `quiet`
means an actual empty `EAGAIN`/`EWOULDBLOCK` read with no retained input or frame;
`pending` includes partial input, a completed frame awaiting `take_frame()`, and
an interrupted read. `closed` retains the first failure. Inspection sends no
queued output and confirms no ACCEPT bytes.

For example, receiving part of a CANCEL header reports `pending`. A later empty
kernel read still reports `pending` because the earlier bytes remain buffered.
Completing CANCEL also stays pending until its owner consumes and handles that
frame. A later fresh empty read may report quiet; the observation itself grants
no job or execution authority. A queued ACCEPT keeps its original bytes and
delivery deadline throughout these inspections.

Inspection checks the original invocation, partial-frame and delivery walls
before and after the read. Finishing a frame cannot erase the deadline that
governed its final read. Read bytes and decoded frames are retained under creator
signal masking before pending handlers run. A lost native read return or thrown
handler closes the original Connection, preserves its first failure and cannot
leave a later quiet result. The ordinary combined `advance()` API is unchanged.

Service now uses this boundary to enforce its narrower original admission wall
immediately before each bound peer write. `queue_accept($ticket, $job)` requires
an original handed request and a ready child context whose lifetime fits that
request. It retains the association and spends the context's request binding
before calling Connection's tracked queue. A repeated request or another ticket
cannot reuse that binding, including after its closed outcome is consumed.

For example, a signal can interrupt queue publication after the association and
Connection record are complete. `accept_publication($ticket)` recovers a copied
view containing the original ticket, parent, job, execution/admission deadlines,
Service state/failure and nested Connection `write` observation. Before any queue
record exists, `write` is explicitly undefined. Changing this view cannot change
the original association or confirmed byte count. A queue failure closes the
peer and preserves the association for cleanup and its eventual closed outcome.

Every bound write rechecks the original request, submitting parent, job context,
root and endpoint. The fixed admission wall remains in force after a complete
local write until an original admitted execution report; publication never renews
it. A fully decoded matching CANCEL closes
that peer before another write; an early ACK, foreign identity or repeated
request is a protocol failure. EOF, revocation and expiry also close the original
peer. A partial write retains its confirmed prefix and cannot become published.
A previously completed local write remains a historical fact after closure.

Service also accepts `advance($accept_check, $bound_write_check)`. The second
callback receives the original Service, ticket and bound job immediately before
each native write. It returns a boolean: false defers without renewing a wall;
true still requires fresh Service authority and lifetime checks after the callback.
A thrown or malformed result closes the original peer and preserves the refusal.
The existing zero-callback and accept-only forms retain their behavior.

`Service::execution_admission($ticket, $job)` now checks the matching original
bound peer before a native gate attempt. It rechecks retained parent/job authority
and the original admission wall, inspects only that Connection, and requires
complete matching ACCEPT plus quiet input. It accepts no other connection and
writes no queued bytes. A partial ACCEPT or partial/interrupted client frame
returns `0`; a decoded matching CANCEL closes the peer as cancellation, while
foreign or repeated control closes it as a protocol failure. EOF and original
expiry also prevent admission. Only a fresh successful check returns `1`.

For example, a positive check followed by one new CANCEL byte requires deferral
at the next attempt. An empty kernel buffer cannot bypass that retained byte.
Once the full control message arrives, the check consumes it and closes the
matching peer. A check that crosses its fixed wall or loses authority during
inspection also refuses, without extending the deadline.

`execution_observation($ticket)` returns copied `latest` and `admitted` checks,
the original association and both deadlines, plus any retained failure. The last
positive check remains historical when a later check defers or the peer closes.
Creator signals see the completed check before interrupting its return; ordinary
return also rechecks any closure performed by a handler. These records contain
transport-check times, not native execution timestamps. Positive admission alone
changes no lifetime and establishes no execution effect.

The optional `execution_admission($ticket, $job, \$grant)` form publishes one
original grant into an empty untied scalar slot before creator signals resume.
A deferred check leaves that slot empty. A later successful retry returns the
same original grant without renewing its issue time. Even if a signal interrupts
the return, the retained slot permits the aggregate to reconcile what happened;
it does not prove that a native execution byte was written.

Only after independently observing its original Pair's confirmed release may
the trusted aggregate call `record_execution($grant)`. Service validates the
original Service, grant and retained peer association, then retains the first
report under masking. Copied observations, copied grants and matching numeric
IDs cannot substitute for that handle. The report records its own reporting
time, the original grant issue time and the execution deadline; its timestamp
is not the command's native start time. Repeated reports preserve the first one.

Reporting selects the execution deadline frozen when the job was bound, clipped
to both the original request and job context. For example, a delayed report
arriving after the admission window can keep a still-bound peer live until that
original execution deadline. No report renews a clock. Observations retain the
old admission deadline and expose `active_deadline_ns` separately. All original
root, parent and job authority, cancellation, EOF and framing limits still apply.
Further execution admission is refused once a report exists.

A report arriving after closure preserves history and the first failure while
leaving the peer closed. Its detached execution observation travels in the
consumed closed outcome. The aggregate must reconcile the original native effect
before consuming that outcome; afterward, the spent grant cannot report again.
The Service fixture supplies trusted reports and literal socket traffic; actual
native-effect reconciliation remains part of aggregate integration below.

The aggregate now joins that boundary to the original ready gated process.
`start_request($ticket)` prepares and starts its associated original grant;
`advance_request($ticket)` advances native handoff and queues the matching ACCEPT
only when both native roles are retained and ready. Native launch advancement
stays outside the publication mask because it may still fork the command.
Actual child checks verify the saved caller exec mask and dispositions.

Each bound write rechecks the original peer/grant association and advances only
an already-ready pair before permitting the attempt. This catches observed native
loss between partial writes without starting a process under the write mask.
For example, losing the gated command after an ACCEPT prefix leaves that prefix
in the historical publication, cancels the matching job and writes no remainder.
Original EOF, decoded cancellation/protocol failure and fixed-wall expiry also
prevent further publication and retain exact bounded cleanup ownership.

Copied peer observations now include the nested Service/Connection publication.
Publication is retained before creator signals are unmasked, including a queued
frame with no confirmed bytes, a partial write and a completed local write.
An interrupted return preserves the matching job and first failure; later cleanup
does not erase previously confirmed bytes. A complete ACCEPT still leaves the
command gated. Neither its numeric job identity nor its copied publication grants
exec permission; final live rechecks and post-exec result streaming remain open.

The native pair now accepts `release($check)` as well as its existing no-argument
form. Queuing release invokes no callback. Each later attempted execution byte
calls the retained check with the original pair, under creator signal masking.
Only scalar `1` permits the attempt; scalar `0` defers it without resetting the
invocation wall. A transient write repeats admission on its next attempt. For
example, a callback that permits the first attempt must still permit a retry
following `EAGAIN`; its earlier answer does not authorize that retry.

Before and after the callback, the pair verifies its original object and
reservation identity, held command, original deadline and gate handles. A copied
or inherited pair cannot release the creator's command. Cancellation, stale
custody, a thrown callback or a malformed answer revokes the pending byte and
retains the first failure. Queue-time refusal is also retained before pending
creator signals run. These checks never advance native launch under a mask.

A confirmed execution byte and both gate closes are published before creator
signals resume. The copied observation keeps `released` true even when a later
close or signal interrupts the return. If the native write itself loses its
return, `release_attempted` and `release_uncertain` preserve that ambiguity and
prevent retries; `released == 0` then proves no absence of execution. The focused
fixture independently observes command output, original exec masks, pipe EOF and
exact child waits, including a deliberately lost return after a real byte.
`ReservedJob::release($check)` now forwards a retained check to that original
Pair while preserving the existing no-callback form. The wrapper and its Pair
must both be the original objects; copied wrappers, inherited wrappers and a
substituted original Pair cannot act for the job. Wrapper identity is retained
before any native allocation.

Release queuing publishes the wrapper's `releasing` phase under masking before
calling Pair. A creator handler therefore sees both retained owners, and a
handler's newer cleanup phase is never overwritten by the returning call. Queue
failures retain the first cause and revoke pending E before signals resume;
interrupted returns also revoke the queued byte. This refusal path works even
when restoring or blocking signals fails; it needs no further successful mask
operation. None of this queue work forks.

Each actual attempt checks the original wrapper, Pair, releasing phase, first
failure and unchanged invocation deadline before and after the caller's check.
For example, a callback that cancels the wrapper and then returns `1` still
refuses E: native Pair readiness alone cannot override wrapper cleanup. Deferral
and transient retries keep the same deadlines and repeat the checks. Confirmed
or uncertain native execution observations survive interrupted advancement.
The fixture observes actual gate writes, binary command output, original exec
masks, exact waits and closed pipe inventories, including its failure cleanup.

`ReservedJob::check_custody()` inspects an original ready, queued or executing
parent without advancing launch, capture or a pending E. Under creator signal
masking it checks the original wrapper, Pair, reservation, command identity and
fixed wall, inspects reservation control and polls only the original command.
A positive answer describes that inspection only; every later dependent effect
must make its own fresh check. An observation copy grants no authority.

For example, after `release()` queues E, `check_custody()` can still return `1`
while leaving the command gated. It returns `0` for cancellation, expired custody,
uncertain execution or a completed released command. Invalid ownership or native
loss throws and retains the first failure; a dead reservation stays unharvested
until group cleanup. Creator cancellation at signal restoration revokes a positive
answer, and restoration failure revokes pending E without requiring another mask.

An actual completed command keeps its original terminal status. Inspection returns
`0`; subsequent ordinary capture still classifies exit zero as success, exit 23 as
nonzero exit, or termination by a signal as signaled. Inspection itself introduces
no host error for that completion. Confirmed or uncertain execution truth remains
unchanged. The fixture uses actual stop/continue barriers, terminal waits, pipe EOF,
creator signals and independent cleanup censuses to check these boundaries.

`Coordinator::release_root($grant)` now queues execution for the original active,
ready root job. The original grant must come from that coordinator; copied,
foreign, inherited, nested and unready owners refuse. Queuing is single-use and
performs no E write. A creator request that wins just before masking remains
the sole request; a later caller cannot overwrite or cancel it.

Every actual E attempt rechecks the original open aggregate, active root ledger,
bound context, native wrapper/Pair and live command/reservation custody. The
ledger wall must still match both the queued wall and the native Pair's original
invocation deadline. Context lookup is followed by another admission check, so
revocation during that lookup cannot authorize E. Deferral and transient writes
repeat these checks. Closed authority, changed walls or an existing failure
refuse execution and retain bounded cleanup ownership.

For example, after preparing and starting a root, advance it until its copied
native phase is `ready`, call `release_root($coordinator->root)`, then continue
`advance_job($coordinator->root)`. `release_requested` records the request only.
Fresh original native observations retain `released` after a confirmed E, or
`release_uncertain` after a lost syscall return; an interrupted return erases
neither fact and never permits replay. Failed signal-mask restoration publishes
aggregate refusal without depending on another successful mask operation.
The root fixture checks actual argument/environment/context bytes, cwd, umask,
exec signals, native child loss, pipe EOF and exact waits through cleanup.

The coordinator now has a private final check for nested E. Its focused fixture
retains that check as the original wrapper's release callback and records the
request's release intent. The aggregate request-release entrypoint and reporting
of original native effects remain separate work.

Each attempt verifies the original peer, transferred request, child grant,
wrapper/Pair, submitting parent and bound contexts. Both jobs must remain active,
the run must remain open, and the original admission and execution walls still
apply. Fresh parent custody inspection occurs before and after Service admission.
It can inspect a root or another nested parent while leaving that parent's own
queued E untouched. A completed parent refuses execution without changing its
original result classification.

Service must observe quiet current input and a complete matching ACCEPT. A
partial frame, interrupted read or incomplete publication defers the native
attempt. On the first positive check, Service publishes its original grant
directly into the retained peer before any E. Transient writes reuse that exact
grant and its original issue time while repeating admission; a previous positive
answer cannot override new cancellation or pending input. Lost, copied, foreign
or externally populated grant custody refuses.

After the last parent inspection, the check authenticates the retained grant
again and requires its original Service peer to remain live and unreported.
Removing or copying the grant, retiring that peer, or spending its report authority
at this return boundary cannot authorize E. Once callback ownership is established,
failures retain the original request cause before cleanup and signal restoration,
including failed remasking. Confirmed and uncertain native writes retain their
original grant; this prerequisite fabricates no execution report. The fixture
checks literal socket frames, actual nested invocation/context bytes, native
parent loss, creator signals, exact child waits and independent resource closure.

Normal callers retain the existing own-group supervisor. Nested execution
release and Service lifetime reconciliation, routing and complete subtree qualification
still have separate open owners. These private components
establish no nested result or permission to run the retained startup proxy.
Their tests exercise the current host; Linux qualification remains open.
The component regression band includes existing ReservedJob tests that explicitly
release and execute bounded fixture commands, as well as legacy-facade checks.
The newer Connection/Service APIs grant no exec release; that narrower statement
does not describe every test in the band. These controls do not run the retained
original startup/proxy/compiler producers.
Re-run the bounded component controls with:

```bash
scripts/run_with_ram_guard.sh -- prove -Iperl -It/lib t/1823-process-group-reservation.t t/1824-process-gated-pair.t t/1825-process-capture-stream-ownership.t t/1826-process-group-closure.t t/1827-process-reserved-job.t t/1828-process-reserved-receipt.t t/1829-process-unjoined-closure.t t/1830-process-reservation-death.t t/1831-process-private-descriptors.t
scripts/run_with_ram_guard.sh -- prove -Iperl -It/lib t/1832-process-coordinator-admission.t
scripts/run_with_ram_guard.sh -- prove -Iperl -It/lib t/1833-process-retained-endpoint.t
scripts/run_with_ram_guard.sh -- prove -Iperl -It/lib t/1834-process-retained-preparation.t
scripts/run_with_ram_guard.sh -- prove -Iperl -It/lib t/1835-process-coordinator-run-ownership.t
scripts/run_with_ram_guard.sh -- prove -Iperl -It/lib t/1836-process-coordinator-job-preparation.t
scripts/run_with_ram_guard.sh -- prove -Iperl -It/lib t/1837-process-admitted-forks.t
scripts/run_with_ram_guard.sh -- prove -Iperl -It/lib t/1838-process-cleanup-wall-clipping.t
scripts/run_with_ram_guard.sh -- prove -Iperl -It/lib t/1839-process-coordinator-lifecycle.t
scripts/run_with_ram_guard.sh -- prove -Iperl -It/lib t/1840-process-service-shared-endpoint.t
scripts/run_with_ram_guard.sh -- prove -Iperl -It/lib t/1841-process-service-retained-accept.t
scripts/run_with_ram_guard.sh -- prove -Iperl -It/lib t/1842-process-coordinator-accepted-peers.t
scripts/run_with_ram_guard.sh -- prove -Iperl -It/lib t/1843-process-accept-publication.t
scripts/run_with_ram_guard.sh -- prove -Iperl -It/lib t/1844-process-retained-request-transfer.t
scripts/run_with_ram_guard.sh -- prove -Iperl -It/lib t/1845-process-retained-parent-context.t
scripts/run_with_ram_guard.sh -- prove -Iperl -It/lib t/1846-process-snapshot-context.t
scripts/run_with_ram_guard.sh -- prove -Iperl -It/lib t/1847-process-write-admission.t
scripts/run_with_ram_guard.sh -- prove -Iperl -It/lib t/1848-process-service-job-publication.t
scripts/run_with_ram_guard.sh -- prove -Iperl -It/lib t/1849-process-parent-token-admission.t
scripts/run_with_ram_guard.sh -- prove -Iperl -It/lib t/1850-process-aggregate-context.t t/1851-process-request-association.t t/1852-process-gated-accept.t
scripts/run_with_ram_guard.sh -- prove -Iperl -It/lib t/1858-process-aggregate-owners.t
scripts/run_with_ram_guard.sh -- prove -Iperl -It/lib t/1859-process-root-execution.t
scripts/run_with_ram_guard.sh -- prove -Iperl -It/lib t/1860-process-native-custody.t
scripts/run_with_ram_guard.sh -- prove -Iperl -It/lib t/1861-process-nested-execution-admission.t
scripts/run_with_ram_guard.sh -- prove -Iperl -It/lib t/1853-process-exec-admission.t
scripts/run_with_ram_guard.sh -- prove -Iperl -It/lib t/1854-process-input-inspection.t
scripts/run_with_ram_guard.sh -- prove -Iperl -It/lib t/1855-process-service-execution-admission.t
scripts/run_with_ram_guard.sh -- prove -Iperl -It/lib t/1856-process-service-execution-report.t
scripts/run_with_ram_guard.sh -- prove -Iperl -It/lib t/1857-process-reserved-execution-admission.t
```

For native stopped-child observations, decode `${^CHILD_ERROR_NATIVE}` with
POSIX `WIFSTOPPED` and `WSTOPSIG`. The control initially read Perl's normalized
`$?`, which was zero for this stopped child on the current host; it did not
establish the stop until corrected to the native status field.
