"""Capture selected read-only interpreter inputs; launch no worker or probe."""
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import stat
import sys

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]


def load(name, relative):
    spec = importlib.util.spec_from_file_location(name, ROOT / relative)
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    spec.loader.exec_module(module)
    return module


def binary(path):
    path = path.resolve(strict=True)
    before = path.stat()
    if not stat.S_ISREG(before.st_mode) or not 0 < before.st_size <= 64 * 1024 * 1024:
        raise ValueError('selected interpreter must be a bounded regular file')
    digest = hashlib.sha256()
    count = 0
    with path.open('rb') as stream:
        opened = os.fstat(stream.fileno())
        while block := stream.read(65536):
            count += len(block)
            if count > 64 * 1024 * 1024:
                raise ValueError('selected interpreter exceeded its bound')
            digest.update(block)
        after = os.fstat(stream.fileno())
    identity = lambda info: tuple(getattr(info, key) for key in (
        'st_dev', 'st_ino', 'st_size', 'st_mode', 'st_uid', 'st_nlink', 'st_mtime_ns', 'st_ctime_ns'))
    if len({identity(info) for info in (before, opened, after, path.stat())}) != 1 or count != before.st_size:
        raise ValueError('selected interpreter changed during read')
    return dict(size_bytes=count, sha256=digest.hexdigest())


def main():
    if sys.platform != 'darwin' or os.getuid() == 0 or os.getuid() != os.geteuid():
        raise ValueError('selected ordinary-user Darwin scope required')
    native = load('populated_admission_native_reader', 'scripts/fixture_kernel_sampler.py').NativeProcesses()
    python = Path(sys.executable).resolve(strict=True)
    perl = Path('/usr/bin/perl').resolve(strict=True)
    prior = json.loads((ROOT / 'docs/audits/native-proxy-language-coordination-admission-20260913/plan.json').read_bytes())
    if python.parent.name != 'bin' or python.name != prior['toolchains']['python']['selected_sibling_basename']:
        raise ValueError('current Python invocation differs from the qualified framework layout')
    python_image = python.parent.parent / 'Resources/Python.app/Contents/MacOS/Python'
    if python_image.resolve(strict=True) != python_image or native.executable(os.getpid()) != python_image:
        raise ValueError('current Python native executable differs from its selected framework image')
    toolchains = {}
    for language, invocation, image, kind in [('python', python, python_image, 'python_framework'),
                                               ('perl', perl, perl, 'same_binary')]:
        toolchains[language] = dict(selected_sibling_basename=invocation.name,
            invocation_binary=binary(invocation), native_image=dict(kind=kind, binary=binary(image)),
            invocation_path=str(invocation), native_path=str(image), read_only_toolchain_input=True)
    # Perl's same-binary layout is supported by the retained actual native-image
    # records only while those selected bytes remain exact. The future worker
    # still requires its own fresh native path/birth/byte admission.
    if toolchains['perl']['invocation_binary'] != prior['toolchains']['perl']['selected_binary']:
        raise ValueError('Perl bytes changed; historical native-image layout needs new owned review')
    result = dict(schema='fsmgen.inactive_populated_installed_inputs.v1', toolchains=toolchains,
        current_python_identity=native.identity(os.getpid()), platform=sys.platform,
        uname=dict(system=os.uname().sysname, release=os.uname().release, version=os.uname().version, machine=os.uname().machine),
        project_device=ROOT.stat().st_dev, native_reader_dependency='/usr/lib/libproc.dylib',
        actual_worker_execution=False, actual_probe_execution=False,
        complete_native_dependency_closure=False,
        locality_exception='Selected installed interpreters, standard modules and libproc are required read-only OS/toolchain dependencies. No project data is written outside the repository volume.')
    print(json.dumps(result, sort_keys=True, indent=2))


if __name__ == '__main__':
    main()
