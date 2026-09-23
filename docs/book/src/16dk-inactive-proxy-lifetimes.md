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

The next capture is now admitted and still closed. It must observe the current
public compiler, probe and tool-resolution stages, in that order, and retain
each private process id, birth clock, group identity and cleanup identity.
Opening execution, issuing a permit early, or replaying an original, proxy or
live collector rejects. The admission itself launches nothing.

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

A sealed caller can receive a finished private job it already holds. That
hand-back carries the process id, birth clock and own-group identity, and it
keeps the original cleanup hash. The ordinary sealed launch still returns only
the public result, which copies cleanup flags and omits that identity. A
separate sealed launch now returns the finished private job when the request
fails before a process starts, including a named program that is not
executable. An executable program now returns that job and stops before
fork. One proof process now crosses that fork, exits, and returns the
private job with its process id. A compiler, probe or tool-resolution
process remains closed. One fresh permit names the sealed private
return and the current source revision. The matching closed plan consumes
that permit once. A different revision, a replay, a live collector and a
second consume are rejected. One consumed permit now admits one finished
private job. An unfinished job and a public supervisor name still refuse.
No compiler, probe or tool-resolution process runs in this step.

```sh
python3 -B docs/audits/native-proxy-receipt-ownership-inventory-20260922/audit.py --verify-saved
perl docs/audits/native-proxy-receipt-adapter-20260922/qualify.t
perl docs/audits/native-proxy-receipt-admission-20260922/qualify.t
perl t/1818-process-supervisor-receipt-observation.t
```

| Remaining work | Required result |
| --- | --- |
| Real receipt binding | One consumed permit admits one finished private job. The compiler, probe and tool-resolution launch remains the next capture. |
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
