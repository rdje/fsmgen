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

[Return to runtime measurement](16dc-vial-portable-verilator-runtime-measurement.md).
