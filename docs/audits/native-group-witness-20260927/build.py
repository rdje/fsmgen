#!/usr/bin/env python3
"""Build a native read-only context helper against the running Perl's public ABI."""
import hashlib
import json
import os
from pathlib import Path
import shlex
import subprocess

ROOT = Path(__file__).resolve().parents[3]
SOURCE = Path(__file__).resolve().parent
WORK = ROOT / '.artifacts/native-group-witness'
WORK.mkdir(parents=True, exist_ok=True)
(WORK / 'module-cache').mkdir(exist_ok=True)
flags = subprocess.check_output(['perl', '-MExtUtils::Embed', '-e', 'ccopts'], text=True)
environment = dict(os.environ)
environment['TMPDIR'] = str(ROOT / '.artifacts/tmp')
environment['CLANG_MODULE_CACHE_PATH'] = str(WORK / 'module-cache')
command = ['clang', '-bundle', '-undefined', 'dynamic_lookup', '-Wall', '-Wextra',
           '-Werror', '-O0', *shlex.split(flags), f'-ffile-prefix-map={ROOT}=.',
           f'-fdebug-prefix-map={ROOT}=.', str((SOURCE / 'context.c').relative_to(ROOT)),
           '-o', str(WORK / 'context.bundle')]
subprocess.run(command, env=environment, cwd=ROOT, check=True, timeout=60)
manifest = {
    'schema': 'fsmgen.native_group_witness_build.v1',
    'source_sha256': hashlib.sha256((SOURCE / 'context.c').read_bytes()).hexdigest(),
    'binary_sha256': hashlib.sha256((WORK / 'context.bundle').read_bytes()).hexdigest(),
    'perl_version': subprocess.check_output(['perl', '-MConfig', '-e', 'print $Config{version}'], text=True),
    'compiler': subprocess.check_output(['clang', '--version'], text=True),
}
(WORK / 'build.json').write_text(json.dumps(manifest, indent=2, sort_keys=True) + '\n')
print('Built repository-local native context helper.')
