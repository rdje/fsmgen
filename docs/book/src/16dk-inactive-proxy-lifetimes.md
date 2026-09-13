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

The next step is a separately admitted, finite compiler-only census of the
complete settled workspace. It must record actual files and ownership before
cleanup while preserving current limits. It will not execute a generated proxy,
wrapper, original test or collector.

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

| Remaining work | Required result |
| --- | --- |
| Workspace profiles | The narrow wrapper repair is qualified; establish authentic compiler-workspace profiles and capacity evidence. |
| Populated-store workers | Qualify equal/different publication, separate references and observation holds through actual cancellation and retirement. |
| Real receipt binding | Prove complete compiler/outer/inner ownership and prevent launches after settlement. |
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
```

[Return to runtime measurement](16dc-vial-portable-verilator-runtime-measurement.md).
