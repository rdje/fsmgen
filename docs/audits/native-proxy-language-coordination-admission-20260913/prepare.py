"""Pin the source-only admission before any real worker or fixture is created."""

import errno
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys

from contract import BASE, ROOT, BOUNDS, OWNER, PARENT, EXECUTION_OWNER, OUTPUT, SCOPE, cases
from local_files import direct, pin
from toolchain import binary_pin, entry_paths

REVISION = 'bac04aab6b27c90b1efe9217a8f7751005b716ab'
OLD_INPUTS = (
    'docs/audits/native-proxy-canonical-contract-20260910/contract.json',
    'docs/audits/native-proxy-image-coordination-20260910/Coordination.pm',
    'docs/audits/native-proxy-image-custody-20260910/ImageCustody.pm',
    't/lib/FSM/Test/RustProxyFixture.pm',
    't/lib/FSM/Test/ProcessSupervisor.pm',
    'perl/FSM/Support/ProcessSupervisor.pm',
    'perl/FSM/ProjectDataLocality.pm',
    'scripts/fixture_kernel_sampler.py',
    'docs/audits/native-proxy-lifetime-closure-20260913/plan.json',
    'docs/audits/native-proxy-lifetime-closure-20260913/review.json',
)
RUNTIME = ('contract.py', 'wire.py', 'probe.py', 'peer.py', 'worker.pl', 'probe.pl',
           'local_files.py', 'runtime.py', 'qualify.py', 'oracle.py', 'capability.py',
           'toolchain.py', 'admit_execution.py')


def main():
    if sys.argv[1:] != ['--emit']:
        raise ValueError('expected explicit source-plan emission')
    if subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT).decode().strip() != REVISION:
        raise ValueError('source baseline changed before admission preparation')
    task = (ROOT / 'docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md').read_text()
    if '- ID: `' + OWNER + '`\n  Status: `active`' not in task:
        raise ValueError('prospective owning leaf is not active')
    inputs = []
    for relative in OLD_INPUTS:
        row = pin(relative)
        if subprocess.check_output(['git', 'show', REVISION + ':' + relative], cwd=ROOT) != (ROOT / relative).read_bytes():
            raise ValueError('old source differs from selected Git revision')
        inputs.append(row)
    selected = cases()
    objects = [relative for case in selected for relative in (case['store'], case['retired_lock']) if relative]
    outputs = [OUTPUT + '/journal.jsonl', OUTPUT + '/attempt.json']
    for case in selected:
        roles = ('holder', 'waiter') if case['kind'] == 'pair' else ('inheritance',)
        for role in roles:
            outputs.extend(OUTPUT + '/' + case['name'] + '.' + role + '.' + suffix for suffix in ('stdout', 'stderr'))
    for relative in objects + outputs + [OUTPUT + '/execution-admission.json']:
        if direct(relative, absent_ok=True) is not None:
            raise FileExistsError('prospective allocation already exists: ' + relative)
    entries = entry_paths()
    # This fixed source-phase interpreter query is not a coordination worker.
    query = subprocess.run([str(entries['perl']), '-e', 'print "$^X\\n";'], cwd=ROOT,
                           env=dict(PATH=os.defpath, LC_ALL='C', LANG='C', TMPDIR=str(ROOT / '.artifacts/tmp')),
                           capture_output=True, timeout=5, check=True)
    if len(query.stdout) > 4096 or query.stderr:
        raise ValueError('unexpected installed Perl identity query output')
    perl_actual = Path(os.fsdecode(query.stdout).strip()).resolve(strict=True)
    if perl_actual.parent != entries['perl'].parent:
        raise ValueError('installed Perl selection is not the admitted sibling layout')
    tools = {}
    for language, entry in entries.items():
        actual = perl_actual if language == 'perl' else entry
        tools[language] = dict(invocation_binary=binary_pin(entry), selected_binary=binary_pin(actual),
                               selected_sibling_basename=actual.name)
    runtime = [pin((BASE / name).relative_to(ROOT).as_posix()) for name in RUNTIME]
    runtime += [row for row in inputs if row['path'].endswith(('.pm', '.py'))]
    plan = dict(schema='fsmgen.language_coordination_source_admission.v1', owner=OWNER,
                parent=PARENT, execution_owner=EXECUTION_OWNER, source_revision=REVISION,
                platform='darwin', scope=SCOPE, bounds=BOUNDS, cases=selected,
                inputs=inputs, runtime_pins=runtime, toolchains=tools,
                prospective_objects=objects, prospective_outputs=outputs,
                native_constants=dict(busy_errno=sorted({errno.EAGAIN, errno.EWOULDBLOCK})),
                interpretation=dict(worker_output_overflow_evidence_extra_bytes=1,
                                    perl_clock_quantization_tolerance_ns=1000,
                                    process_groups_counted_by_birth_not_reusable_pid=True),
                toolchain_query=dict(argv=['perl', '-e', 'print "$^X\\n";'], exit_code=query.returncode,
                                     stdout_hex=query.stdout.hex(), stderr_hex=query.stderr.hex()),
                external_read_only_dependencies=[
                    'Installed Perl/Python executables, their standard-library files and required OS loader/runtime files.',
                    'Darwin /usr/lib/libproc.dylib through the unchanged native identity/executable reader; no command or privileged sampler call.',
                    'The fixed Perl interpreter identity query runs only during this source phase. No coordination worker is launched.'
                ],
                project_storage='All fixture stores, evidence, temporary paths and outputs derive from the current repository root; no global cache or external temporary store.',
                first_failure_policy='One finite execution only. Retain the first complete bounded output or overflow prefix, native identities and exact state; stop and separately settle owned processes before exact cleanup. No replay or guessed cleanup.',
                missing_legs=['Actual contention, deadline, cancellation and exec-descriptor behavior under the selected worker sources.',
                              'Native-proxy authentication, real receipt/late-launch/live integration, historical startup/parent qualification and full CI/push.'])
    body = (json.dumps(plan, sort_keys=True, indent=2) + '\n').encode()
    if len(body) > 65536:
        raise ValueError('source plan exceeds worker admission reader bound')
    with (BASE / 'plan.json').open('xb') as stream:
        stream.write(body)
    os.chmod(BASE / 'plan.json', 0o644)
    print(json.dumps(dict(source_inputs=len(inputs), runtime_inputs=len(runtime),
                          prospective_cases=len(selected), actual_worker_execution=False), sort_keys=True))


if __name__ == '__main__':
    main()
