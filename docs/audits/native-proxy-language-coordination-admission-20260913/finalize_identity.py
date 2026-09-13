"""Preserve the first plan and bind its corrected native-image selection."""

import copy
import hashlib
import json
import os
from pathlib import Path
import sys

from contract import BASE, ROOT, OWNER
from local_files import pin
from runtime import process_reader
from toolchain import binary_pin, entry_paths, native_candidate, resolve


def main():
    if sys.argv[1:] != ['--emit']:
        raise ValueError('expected explicit identity-plan finalization')
    original_bytes = (BASE / 'first-source/plan.json.source').read_bytes()
    if (BASE / 'plan.json').read_bytes() != original_bytes:
        raise ValueError('first plan already changed')
    original = json.loads(original_bytes)
    current = copy.deepcopy(original)
    entries = entry_paths()
    reader = process_reader()
    python_image = reader.executable(os.getpid())
    selected = entries['python'].parent / current['toolchains']['python']['selected_sibling_basename']
    candidate = native_candidate(selected, 'python_framework')
    if candidate != python_image or selected == python_image:
        raise ValueError('installed Python does not match the observed fixed framework layout')
    current['toolchains']['python']['native_image'] = dict(kind='python_framework', binary=binary_pin(candidate))
    current['toolchains']['perl']['native_image'] = dict(kind='same_binary', binary=current['toolchains']['perl']['selected_binary'])
    current['runtime_pins'] = [pin(row['path']) for row in original['runtime_pins']]
    current['interpreter_identity_scope'] = (
        'Invocation and kernel executable identities are distinct. The selected Python framework image '
        'is observed read-only in this source-phase process and separately byte-pinned. Perl retains a '
        'same-binary prospective selection; actual native worker/probe path, birth and group joins remain '
        'required during the first admitted execution. No basename or worker self-report substitutes for '
        'the selected full native image and its bytes. This does not establish a native-proxy startup cause.'
    )
    resolve(current)
    body = (json.dumps(current, sort_keys=True, indent=2) + '\n').encode()
    if len(body) > 65536:
        raise ValueError('corrected plan exceeds its admitted source-reader bound')
    (BASE / 'plan.json').write_bytes(body)
    os.chmod(BASE / 'plan.json', 0o644)
    changed = [dict(old=old, new=new) for old, new in zip(original['runtime_pins'], current['runtime_pins']) if old != new]
    review = dict(schema='fsmgen.language_coordination_identity_repair.v1', owner=OWNER + '.1',
                  original_plan=dict(path=(BASE / 'first-source/plan.json.source').relative_to(ROOT).as_posix(),
                                     size_bytes=len(original_bytes), sha256=hashlib.sha256(original_bytes).hexdigest()),
                  corrected_plan=pin((BASE / 'plan.json').relative_to(ROOT).as_posix()),
                  changed_runtime_sources=changed, python_native_image=current['toolchains']['python']['native_image'],
                  source_observation='python-identity-observation.json',
                  primary_source='https://raw.githubusercontent.com/python/cpython/v3.14.7/Mac/Tools/pythonw.c',
                  primary_markers=['get_python_path', 'Resources/Python.app/Contents/MacOS/', 'POSIX_SPAWN_SETEXEC', '__PYVENV_LAUNCHER__'],
                  root_cause='The initial draft equated the invocation path with the kernel executable. The observed framework installation uses distinct launcher and application-bundle images; upstream CPython explains the preserved invocation name and replacement of the process image.',
                  limit='Upstream source explains the observed layout; it is not an attestation that the installed binary was built from unmodified upstream source.',
                  native_proxy_startup_cause_established=False, actual_worker_execution=False)
    with (BASE / 'identity-repair.json').open('x') as stream:
        json.dump(review, stream, sort_keys=True, indent=2)
        stream.write('\n')
    print('Exact invocation/native-image identity repair retained; no worker executed.')


if __name__ == '__main__':
    main()
