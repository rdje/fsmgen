"""In-memory admission, selected-input I/O and journal failure qualification."""
import copy
from contextlib import ExitStack
import hashlib
import json
import os
import stat
from unittest.mock import patch

import admission
from contract import OWNER, EXECUTION_OWNER, OUTPUT, TASK
import installed_inputs
from journal import Journal
from qualify_files import ModelPath, World


class InstalledPath(ModelPath):
    def is_absolute(self):
        return self.path.startswith('/')

    def is_relative_to(self, root):
        return False

    def resolve(self, strict=False):
        return self


def state():
    task = lambda execution: '- ID: `' + OWNER + '`\n  Status: `done`\n- ID: `' + EXECUTION_OWNER + '`\n  Status: `' + execution + '`\n'
    return dict(revision='a' * 40, subject=OWNER + ': exact source admission',
        committed_task=task('proposed'), current_task=task('active'),
        memory='- active_work_unit: `' + EXECUTION_OWNER + '`\n', dirty_paths=['MEMORY.md', 'docs/TASK_TREE.md', TASK],
        staged_paths=[], untracked_paths=[], uid=501, euid=501, platform='darwin')


def qualify():
    checks, rejected = [], []

    def check(name, value):
        if not value or name in checks:
            raise AssertionError(name)
        checks.append(name)

    def reject(name, operation, expected=ValueError, contains=None):
        try:
            operation()
        except expected as error:
            if contains and contains not in str(error):
                raise AssertionError(name + ': wrong primary error') from error
            rejected.append(name)
            return error
        raise AssertionError(name + ': unexpectedly accepted')

    baseline = state()
    check('exact committed admission and separately active execution accepted', admission.validate_state(baseline) == baseline['revision'])
    for name, mutation in [
        ('abbreviated commit', lambda value: value.update(revision='a' * 12)),
        ('nonhex commit', lambda value: value.update(revision='z' * 40)),
        ('wrong commit owner', lambda value: value.update(subject=EXECUTION_OWNER + ': execution')),
        ('unfinished committed admission', lambda value: value.update(committed_task=value['committed_task'].replace('`done`', '`active`'))),
        ('unfinished current admission', lambda value: value.update(current_task=value['current_task'].replace('`done`', '`active`'))),
        ('execution already active in admission commit', lambda value: value.update(committed_task=value['current_task'])),
        ('execution not separately activated', lambda value: value.update(current_task=value['committed_task'])),
        ('duplicate owner', lambda value: value.update(current_task=value['current_task'] + value['current_task'])),
        ('wrong memory owner', lambda value: value.update(memory='- active_work_unit: `' + OWNER + '`\n')),
        ('duplicate memory pointer', lambda value: value.update(memory=value['memory'] * 2)),
        ('dirty implementation', lambda value: value['dirty_paths'].append('perl/source.pm')),
        ('staged live pointer', lambda value: value['staged_paths'].append('MEMORY.md')),
        ('untracked implementation', lambda value: value['untracked_paths'].append('new.py')),
        ('root identity', lambda value: value.update(uid=0, euid=0)),
        ('elevated identity', lambda value: value.update(euid=0)),
        ('boolean identity', lambda value: value.update(uid=True, euid=True)),
        ('wrong platform', lambda value: value.update(platform='linux'))]:
        changed = copy.deepcopy(baseline)
        mutation(changed)
        reject('admission rejects ' + name, lambda: admission.validate_state(changed))
    with patch.object(admission.subprocess, 'check_output', return_value=b'closed view') as call:
        check('Git policy returns the exact selected output', admission.git('rev-parse', 'HEAD') == b'closed view')
        args, kwargs = call.call_args
        check('Git launcher and repository ignore policy are fixed', args[0] == ['/usr/bin/git', '-c', 'core.excludesFile=.gitignore', 'rev-parse', 'HEAD'])
        check('Git environment has no inherited global or personal settings', set(kwargs['env']) == {'PATH', 'LC_ALL', 'LANG', 'TMPDIR'}
            and kwargs['env']['PATH'] == '/usr/bin:/bin' and kwargs['env']['TMPDIR'].endswith('/.artifacts/tmp') and kwargs['timeout'] == 30)

    path, body = '/installed/model-perl', b'selected installed input\0\xff'
    pin = dict(size_bytes=len(body), sha256=hashlib.sha256(body).hexdigest())
    world = World()
    with ExitStack() as stack:
        world.activate(stack)
        stack.enter_context(patch.object(installed_inputs, 'Path', lambda name: InstalledPath(world, name)))
        world.add(path, stat.S_IFREG | 0o555, body)
        result = installed_inputs.read_pin(path, pin)
        check('installed input preserves exact bounded bytes and identity', result['sha256'] == pin['sha256'] and result['read_only'] is True and not world.fds)
        reject('installed input rejects changed digest', lambda: installed_inputs.read_pin(path, dict(pin, sha256='0' * 64)))
        check('digest mismatch closes its owned descriptor', not world.fds)
        world.nodes[path]['st_uid'] = 999999
        reject('installed input rejects foreign owner', lambda: installed_inputs.read_pin(path, pin))
        world.nodes[path]['st_uid'] = os.getuid()
        world.change_on_read = True
        reject('installed input rejects changing file identity', lambda: installed_inputs.read_pin(path, pin), contains='changed')
        world.change_on_read = False
        world.read_error = True
        world.close_errors.add(world.next_fd)
        error = reject('installed read failure survives close failure', lambda: installed_inputs.read_pin(path, pin), OSError, 'model read failure')
        check('installed input retains its additional close error', len(error.__notes__) == 1 and 'model close failure' in error.__notes__[0])

    for scenario in ('success', 'partial_write', 'zero_write', 'close_error', 'event_bound', 'byte_bound', 'envelope'):
        world = World()
        world.add(OUTPUT, stat.S_IFDIR | 0o700)
        with ExitStack() as stack:
            world.activate(stack)
            # Journal derives project paths from its own imported ROOT.
            import journal as journal_module
            stack.enter_context(patch.object(journal_module, 'ROOT', ModelPath(world)))
            journal = Journal()
            journal.open()
            if scenario == 'partial_write':
                world.write_chunk = 3
            if scenario in ('success', 'partial_write'):
                journal('selected', value='original')
                receipt = journal.close()
                check(scenario + ' journal retains complete original rows', world.nodes[journal.path]['body'] == journal.prefix and receipt['completed_rows'] == 1 and not world.fds)
                continue
            if scenario == 'close_error':
                journal('selected', value='original')
                world.close_errors.add(journal.descriptor)
                reject('journal close failure remains explicit', journal.close, OSError)
            else:
                if scenario == 'zero_write':
                    world.zero_write = True
                elif scenario == 'event_bound':
                    journal.limits['journal_events'] = 0
                elif scenario == 'byte_bound':
                    journal.limits['journal_bytes'] = 1
                fields = {'sequence': 999} if scenario == 'envelope' else {'value': 'original'}
                reject(scenario + ' journal failure is explicit', lambda: journal('selected', **fields), (OSError, ValueError))
                journal.close()
            check(scenario + ' freezes the first journal failure', journal.failed is not None)
            reject(scenario + ' cannot resume normal journaling', lambda: journal('later'))
            world.zero_write = False
            if scenario == 'byte_bound':
                check('rejected oversize journal row is not retained as a completed write', not journal.prefix and journal.count == 0)
            saved = journal.preserve_failed_prefix()
            check(scenario + ' preserves its exact bounded intended prefix', world.nodes[saved['path']]['body'] == journal.prefix)

    return dict(schema='fsmgen.inactive_populated_admission_models.v1', checks=checks, rejected=rejected,
        actual_fixture_allocation=False, actual_worker_execution=False, actual_permit_issued=False,
        scope='Admission state, selected-input I/O and journal failures in memory; full preflight and driver models are separate checks.')


if __name__ == '__main__':
    print(json.dumps(qualify(), sort_keys=True, indent=2))
