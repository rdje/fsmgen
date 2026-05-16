# Downstream Issue Reporting

Primary audience: SPECFORGE and other downstream tools that call FSMGen.

This is a strict, format-agnostic bug-report protocol. SPECFORGE does not need
to classify an issue as `.fsm`, `.isf`, parser, lowering, HDL, or API-specific
before filing it. It only needs to provide the exact FSMGen-facing artifacts,
the exact invocation, and the captured results. FSMGen maintainers will use
that bundle to reproduce locally, identify the root cause, and decide whether
the bug lives in FSMGen or in the downstream source generator.

Use this flow whenever FSMGen rejects something SPECFORGE expected to work,
accepts something SPECFORGE expected to fail, emits unexpected artifacts,
returns unexpected JSON, produces different CLI/API behavior, or fails during
HDL/external validation.

The simplest path is to run the helper from the FSMGen repository root:

```bash
./bin/fsmgen-issue-bundle \
  --case path/to/fsmgen-facing-artifact \
  --issue-id short-id \
  --speforge-version "speforge commit or version" \
  --failure-class unknown \
  --expected "what SPECFORGE expected FSMGen to do" \
  --observed "what FSMGen actually did" \
  -- <exact fsmgen options SPECFORGE used>
```

Then send the generated `fsmgen-issue-short-id/` directory. The report is
complete only when a maintainer can unpack the bundle in the FSMGen checkout,
run `commands.sh`, and observe the same result.

## 1. Required Summary

Every issue report must start with this plain-text summary.

```text
Title:
FSMGen command or public API entrypoint:
FSMGen-facing primary artifact path:
Failure class: unknown | rejected-input | accepted-invalid-input | wrong-output | wrong-json | wrong-diagnostic | crash | CLI-API-mismatch | external-tool-failure
FSMGen commit or capability-manifest producer commit:
SPECFORGE version/commit:
Expected behavior:
Observed behavior:
First failing command or API call:
Exit status or exception:
Is the attached artifact bundle minimized: yes | no
Does the minimized/redacted bundle still reproduce: yes | no
```

`unknown` is an acceptable failure class. Do not guess. The attached artifacts
and command transcript are more important than the label.

The expected behavior must be concrete. Prefer "the generated output should
contain one public `rx_done` signal" or "this input should be rejected with a
diagnostic that names duplicate transaction `read`" over general statements
such as "it should compile".

## 2. Required Bundle Layout

Provide one archive or directory with this shape.

```text
fsmgen-issue-<short-id>/
  README.md
  commands.sh
  env.txt
  sources/
    fsmgen-input/
      primary-input
      all-other-files-needed-by-the-invocation
    specforge-context/
      optional-upstream-context-or-generation-log
  observed/
    command-logs/
    stdout/
    stderr/
    json/
    generated/
  expected/
    expected-notes.md
    optional-known-good-artifacts
```

Requirements:

- `README.md` contains the summary from section 1.
- `commands.sh` runs from the FSMGen repository root and reproduces the issue
  using only files inside the bundle.
- `env.txt` records operating system, Perl version, FSMGen revision or
  capability manifest identity, SPECFORGE revision, and external tool versions
  when external tools are involved.
- `sources/fsmgen-input/` contains every file passed to FSMGen or discovered
  by FSMGen during the failing invocation. Treat these as opaque files; do not
  omit them because they look like generated intermediate files.
- `sources/specforge-context/` is optional. Include upstream SPECFORGE intent,
  logs, or generator metadata only when it helps explain expected behavior.
- `observed/` contains stdout, stderr, exit status, JSON outputs, generated
  artifacts, and external validation logs for the failing command and for the
  nearest successful preceding command if one exists.

Do not send only screenshots, prose, or a stack trace. They can be helpful
context, but they are not a reproduction bundle.

## 3. One-Command Bundle Capture

Use `bin/fsmgen-issue-bundle` unless the failing path is API-only and cannot
be driven through the CLI.

Minimal command:

```bash
./bin/fsmgen-issue-bundle \
  --case path/to/fsmgen-facing-artifact \
  --issue-id sf-0001 \
  --speforge-version "SPECFORGE_COMMIT" \
  --failure-class unknown \
  --expected "FSMGen should accept this generated artifact" \
  --observed "FSMGen rejects it" \
  -- --strict --check --json
```

What the helper does:

- copies the primary FSMGen-facing artifact into
  `sources/fsmgen-input/`;
- captures FSMGen commit, Perl version, capability manifest, and external tool
  version probes;
- reruns the exact original FSMGen command;
- runs generic diagnostic probes for check JSON, strict check JSON, semantic
  JSON, schedule JSON, and SystemVerilog generation;
- writes stdout, stderr, exit status, command lines, JSON outputs, and
  generated artifacts under `observed/`;
- writes an executable `commands.sh` that FSMGen maintainers can rerun from
  the repository root after the bundle has been moved or unpacked.

If the invocation needs additional files, repeat `--extra-source`:

```bash
./bin/fsmgen-issue-bundle \
  --case generated/main.artifact \
  --issue-id sf-0002 \
  --extra-source generated/imports \
  --extra-source generated/support-file \
  --failure-class wrong-output \
  --expected "generated output should contain rx_done" \
  --observed "rx_done is missing" \
  -- -l sv
```

The helper intentionally does not require SPECFORGE to know whether the
artifact is `.fsm`, `.isf`, or another FSMGen-facing file. Commands that do not
apply still leave stdout, stderr, and exit-status evidence in the bundle.

## 4. Manual Environment Capture

Run these from the FSMGen repository root and include their outputs. If an
external tool is not installed, keep its failed version command output and
exit status in the bundle.

```bash
mkdir -p observed/json observed/stdout observed/stderr observed/command-logs

git rev-parse HEAD > observed/command-logs/fsmgen-git-head.txt
perl -v > observed/command-logs/perl-version.txt
./bin/fsmgen --capability-manifest \
  > observed/json/fsmgen-capability-manifest.json \
  2> observed/stderr/fsmgen-capability-manifest.stderr
echo $? > observed/command-logs/fsmgen-capability-manifest.exit

verilator --version > observed/command-logs/verilator-version.txt 2>&1
echo $? > observed/command-logs/verilator-version.exit
yosys -V > observed/command-logs/yosys-version.txt 2>&1
echo $? > observed/command-logs/yosys-version.exit
```

If the failure depends on environment variables, include only the relevant
ones. For path variables such as `FSMLIB`, convert machine-local absolute
paths into bundle-relative paths in `commands.sh` and put the referenced files
under `sources/fsmgen-input/`.

## 5. Reproduction Script Contract

`commands.sh` must be executable and must not depend on files outside the
bundle except for the FSMGen checkout itself.

Minimum shape:

```bash
#!/usr/bin/env bash
set -u

CASE="sources/fsmgen-input/primary-input"
mkdir -p observed/json observed/stdout observed/stderr observed/generated observed/command-logs

# Re-run the exact command or API wrapper that failed for SPECFORGE.
./bin/fsmgen <exact-options-used-by-speforge> "$CASE" \
  > observed/stdout/original.stdout \
  2> observed/stderr/original.stderr
echo $? > observed/command-logs/original.exit
```

The `<exact-options-used-by-speforge>` placeholder must be replaced by the real
options. If SPECFORGE used an in-process API instead of the CLI, `commands.sh`
must invoke the minimal included API reproduction script and capture its
stdout, stderr, and exit status the same way.

## 6. Diagnostic Capture

After the original failing command, add these best-effort probes to
`commands.sh`. They are intentionally generic. SPECFORGE does not need to know
which source family is involved; commands that do not apply should still leave
their stdout, stderr, and exit status in the bundle.

```bash
./bin/fsmgen --check --json "$CASE" \
  > observed/json/check-default.json \
  2> observed/stderr/check-default.stderr
echo $? > observed/command-logs/check-default.exit

./bin/fsmgen --strict --check --json "$CASE" \
  > observed/json/check-strict.json \
  2> observed/stderr/check-strict.stderr
echo $? > observed/command-logs/check-strict.exit

./bin/fsmgen --emit-semantic-json "$CASE" \
  > observed/json/semantic-default.json \
  2> observed/stderr/semantic-default.stderr
echo $? > observed/command-logs/semantic-default.exit

./bin/fsmgen --emit-schedule-json "$CASE" \
  > observed/json/schedule.json \
  2> observed/stderr/schedule.stderr
echo $? > observed/command-logs/schedule.exit

./bin/fsmgen --outdir observed/generated -l sv "$CASE" \
  > observed/stdout/generate-sv.stdout \
  2> observed/stderr/generate-sv.stderr
echo $? > observed/command-logs/generate-sv.exit
```

If the issue involves generated SystemVerilog or external validation, also add:

```bash
./bin/fsmgen --verify-hdl --outdir observed/generated -l sv "$CASE" \
  > observed/stdout/verify-hdl.stdout \
  2> observed/stderr/verify-hdl.stderr
echo $? > observed/command-logs/verify-hdl.exit
```

Keep generated files even when the command later fails. Partial artifacts are
often the fastest way to find the boundary where behavior diverged.

## 7. API Mismatch Reports

If SPECFORGE calls FSMGen in process and the issue is not reproducible through
the CLI alone, include a minimal API driver in the bundle.

Required API-side evidence:

- The script that calls FSMGen.
- Constructor options.
- Public method name and arguments.
- Captured return summary or scalar diagnostic.
- The closest CLI command that should behave equivalently, even if it does not
  reproduce.

The API driver should use public modules only. It should not reach into
private FSMGen internals to create the reproduction.

## 8. Minimization And Redaction

A minimized bundle is preferred, but the first priority is reproducibility.

Provide:

- `sources/fsmgen-input/original/` when policy allows it.
- `sources/fsmgen-input/minimized/` when a smaller artifact set still
  reproduces.
- A short note listing every redaction or simplification.

Safe reductions:

- Rename proprietary identifiers while preserving arity, widths, clock/reset
  relationships, file layout, imports, and control structure.
- Replace constants only when the replacement still reproduces.
- Remove unrelated files or declarations one at a time, rerunning
  `commands.sh` after each reduction.

Unsafe reductions:

- Rewriting the generated FSMGen-facing artifact into a different construct.
- Removing files discovered by path search, imports, bindings, parameter
  overrides, clock/reset metadata, or generated intermediate files that may be
  part of the bug.
- Reporting expected behavior that depends on a proprietary original source
  but not on the attached minimized bundle.

## 9. Triage Contract

FSMGen maintainers can treat the issue as directly actionable when:

- `commands.sh` runs from the repository root;
- all referenced files are inside the bundle;
- the original failing command or API call is captured exactly;
- observed exit status, stdout, stderr, JSON, and generated artifacts are
  present where applicable;
- expected behavior is specific enough to distinguish a FSMGen bug from a
  downstream source-generation bug or feature request;
- the bundle identifies the FSMGen revision or capability manifest producer
  identity.

If the attached bundle shows FSMGen following the current public contract, the
issue may be reclassified as a downstream source-generation bug or a FSMGen
feature request. If the public docs say the attached artifact is supported and
FSMGen rejects it, accepts it incorrectly, or emits wrong artifacts, the report
is a FSMGen bug and the bundle is the starting point for the local regression.
