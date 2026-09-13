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
dependencies and an incorrect dependency on another image's owner. State changes,
actual isolated-file effects and interruption behavior remain separately owned.
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
that failure and its narrow correction remain retained. Actual isolated-file
lifetimes, interruptions and native/live integration remain separately owned.

```sh
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/native-proxy-lifetime-model-20260913/audit_corrected.py --verify-saved
```

[Return to runtime measurement](16dc-vial-portable-verilator-runtime-measurement.md).
