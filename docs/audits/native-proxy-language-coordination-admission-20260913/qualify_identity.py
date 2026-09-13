"""Reproduce the draft rejection and falsify the exact native-image repair."""

import argparse
import copy
import importlib.machinery
import importlib.util
import json
import os
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch

from contract import BASE
import runtime
from toolchain import native_candidate, resolve
from image_receipts import verify as verify_images


def qualify():
    plan = json.loads((BASE / 'plan.json').read_bytes())
    tools = resolve(plan)
    selected = tools['python']
    actual = runtime.process_reader().executable(os.getpid())
    assert actual == Path(selected['native_image']) and actual != Path(selected['invocation'])
    original_path = BASE / 'first-source/runtime.py.source'
    loader = importlib.machinery.SourceFileLoader('first_coordination_runtime', str(original_path))
    spec = importlib.util.spec_from_loader(loader.name, loader)
    original = importlib.util.module_from_spec(spec)
    loader.exec_module(original)
    value = dict(pid=123, ppid=456, uid=os.getuid(), ruid=os.getuid(), start_sec=100, start_usec=1)

    def worker(cls):
        result = cls.__new__(cls)
        result.process = SimpleNamespace(pid=123, poll=lambda: None)
        result.executable = Path(selected['invocation'])
        result.native_executable = Path(selected['native_image'])
        result.native_binary = selected['native_binary']
        result.reader = SimpleNamespace(identity=lambda pid: dict(value), executable=lambda pid: actual)
        return result

    controls = []
    with patch.object(runtime.os, 'getpgid', lambda pid: 123), patch.object(runtime.os, 'getsid', lambda pid: 123):
        try:
            worker(original.Worker).native_identity(123, 456)
        except ValueError:
            original_rejection_reproduced = True
        else:
            raise AssertionError('first draft unexpectedly admitted the observed framework image')
        assert worker(runtime.Worker).native_identity(123, 456) == value
        for name, changed in (
            ('invocation_substituted_for_native_image', Path(selected['invocation'])),
            ('same_basename_elsewhere', Path('/readonly-altered-identity/Python')),
        ):
            target = worker(runtime.Worker)
            target.reader.executable = lambda pid, path=changed: path
            try:
                target.native_identity(123, 456)
            except ValueError:
                controls.append(name)
            else:
                raise AssertionError('native-path substitution accepted: ' + name)
        with patch.object(runtime, 'binary_pin', lambda path: dict(size_bytes=33568, sha256='0' * 64)):
            try:
                worker(runtime.Worker).native_identity(123, 456)
            except ValueError:
                controls.append('changed_bytes_at_native_path')
            else:
                raise AssertionError('native image byte change accepted')
        rejected = worker(runtime.Worker)
        rejected.reader.executable = lambda pid: Path('/readonly-altered-identity/Python')
        rejected.native = rejected.owned_identity(123, 456)
        rejected.key = 'synthetic_rejected_worker'
        rejected.journal = lambda event, **fields: None
        calls = []
        with patch.object(runtime.os, 'getpid', lambda: 456), patch.object(runtime.os, 'killpg', lambda group, number: calls.append((group, number))):
            rejected.signal(15)
        assert calls == [(123, 15)]
    for name, mutate in (
        ('unknown_native_layout', lambda row: row['native_image'].update(kind='any_python_basename')),
        ('launcher_promoted_to_native_image', lambda row: row['native_image'].update(kind='same_binary')),
        ('native_digest_changed', lambda row: row['native_image']['binary'].update(sha256='0' * 64)),
        ('native_identity_omitted', lambda row: row.pop('native_image')),
    ):
        changed = copy.deepcopy(plan)
        mutate(changed['toolchains']['python'])
        try:
            resolve(changed)
        except (ValueError, KeyError):
            controls.append(name)
        else:
            raise AssertionError('altered interpreter selection accepted: ' + name)
    try:
        native_candidate(Path('/readonly-altered-identity/python3.14'), 'python_framework')
    except ValueError:
        controls.append('framework_anchor_changed')
    else:
        raise AssertionError('unanchored framework image accepted')
    carrier = json.loads((BASE / 'synthetic-carrier.json').read_bytes())
    rows = carrier['rows']
    rows[0]['toolchains'] = tools
    languages = {row['worker']: row['language'] for row in rows if row['event'] == 'launch_intent'}
    for row in rows:
        if row['event'] in ('native_admitted', 'probe_native_admitted'):
            tool = tools[languages[row['worker']]]
            row['native_image'] = dict(path=tool['native_image'], **tool['native_binary'])
    assert verify_images(rows, plan)['native_image_records'] == 24
    for name, mutate in (
        ('native_receipt_omitted', lambda r: next(row for row in r if row['event'] == 'native_admitted').pop('native_image')),
        ('native_receipt_path_changed', lambda r: next(row for row in r if row['event'] == 'native_admitted')['native_image'].update(path='/readonly-altered-identity/Python')),
        ('native_receipt_bytes_changed', lambda r: next(row for row in r if row['event'] == 'native_admitted')['native_image'].update(sha256='0' * 64)),
        ('native_tool_identity_promoted', lambda r: r[0]['toolchains']['python']['native_binary'].update(sha256='0' * 64)),
    ):
        changed = copy.deepcopy(rows)
        mutate(changed)
        try:
            verify_images(changed, plan)
        except (ValueError, AssertionError, KeyError):
            controls.append(name)
        else:
            raise AssertionError('altered kernel image receipt accepted: ' + name)
    return dict(schema='fsmgen.language_coordination_identity_review.v1',
                original_rejection_reproduced=original_rejection_reproduced,
                read_only_current_python_native_match=True, rejected_controls=controls,
                rejected_owned_worker_termination_qualified_with_mocked_signal=True,
                simulated_native_image_receipts=24,
                native_worker_cases_executed=0, native_proxy_startup_cause_established=False,
                actual_perl_worker_identity_pending=True)


def main():
    parser = argparse.ArgumentParser()
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument('--retain', action='store_true')
    group.add_argument('--verify-saved', action='store_true')
    args = parser.parse_args()
    result = qualify()
    if args.retain:
        with (BASE / 'identity-review.json').open('x') as stream:
            json.dump(result, stream, sort_keys=True, indent=2)
            stream.write('\n')
    else:
        assert result == json.loads((BASE / 'identity-review.json').read_bytes())
    print(json.dumps(dict(original_rejection_reproduced=True, controls=len(result['rejected_controls']),
                          actual_worker_execution=False), sort_keys=True))


if __name__ == '__main__':
    main()
