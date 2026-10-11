"""Save whole body-conservation candidates before actual independent native outcomes."""
import copy
import subprocess
from common import *
import intake

SUCCESS = 'PASS independent original UTF-8 body, empty membership and lossless physical byte conservation; semantics remain pending.\n'


def first(candidate):
    return candidate['modes'][0]['domains']['api']['records'][0]['original']


def cases():
    return [
        ('positive', None, None),
        ('changed-body-tail', lambda c: first(c).update(body=first(c)['body'] + '\n'), 'complete original native body bytes'),
        ('missing-empty', lambda c: c['modes'][0]['domains']['api']['empty_string_members'].pop(), 'complete original empty and nonempty body allocation'),
        ('missing-nonempty', lambda c: c['modes'][0]['domains']['api']['records'].pop(), 'complete original empty and nonempty body allocation'),
        ('borrowed-body', lambda c: first(c).update(body=c['modes'][1]['domains']['api']['records'][0]['original']['body']), 'complete original native body bytes'),
        ('segment-offset', lambda c: first(c)['segments'][0].update(offset_bytes=1), 'complete original physical segment byte partition'),
        ('missing-segment', lambda c: first(c)['segments'].pop(), 'complete original physical segment reconstruction'),
        ('wire-kind', lambda c: first(c).update(wire_kind='object'), 'complete original native wire kind'),
        ('body-digest', lambda c: first(c)['body_identity'].update(sha256='f' * 64), 'complete original native body identity'),
        ('mode-order', lambda c: c['modes'].reverse(), 'complete candidate original mode order'),
        ('boolean-population', lambda c: c['modes'][0]['domains']['api'].update(population=True), 'complete original empty and nonempty body allocation'),
    ]


def main():
    original = product('candidate.json.gz')
    before = intake.derive()
    save('control-source-before.json', before)
    outcomes = []
    for name, mutation, diagnostic in cases():
        candidate = copy.deepcopy(original)
        if mutation is not None:
            mutation(candidate)
            need(canonical(candidate) != canonical(original), 'genuine whole candidate intervention: ' + name)
        member = 'control-' + name + '.json.gz'
        save_product(member, candidate)
        command = ['perl', str(BASE / 'native.pl'), str(BASE / member)]
        epoch = programs()
        stdout, stderr = BASE / ('control-' + name + '.stdout.txt'), BASE / ('control-' + name + '.stderr.txt')
        save('control-' + name + '-started.json', dict(command=command, programmes=epoch,
             candidate=pin(local(BASE / member).read_bytes()), stdout_path=str(stdout), stderr_path=str(stderr)))
        with stdout.open('xb', buffering=0) as out, stderr.open('xb', buffering=0) as err:
            result = subprocess.run(command, stdout=out, stderr=err)
        after = {path: pin(local(path).read_bytes()) for path in epoch}
        actual = dict(command=command, programmes=epoch, inputs_after=after, status=result.returncode,
                      candidate=pin(local(BASE / member).read_bytes()), stdout=stdout.read_bytes().decode(),
                      stderr=stderr.read_bytes().decode(), stdout_path=str(stdout), stderr_path=str(stderr))
        save('control-' + name + '-actual.json', actual)
        need(all(after[path] == row['identity'] for path, row in epoch.items()), 'whole native body control programme epoch')
        if diagnostic is None:
            need(type(actual['status']) is int and actual['status'] == 0 and actual['stdout'] == SUCCESS and actual['stderr'] == '',
                 'complete actual positive independent body conservation')
        else:
            need(type(actual['status']) is int and actual['status'] != 0 and actual['stdout'] == ''
                 and actual['stderr'].startswith(diagnostic + ' at ' + str(BASE / 'native.pl') + ' line '),
                 'actual intended independent body refusal: ' + name)
        outcomes.append(dict(name=name, member=member, diagnostic=diagnostic, actual='control-' + name + '-actual.json'))
        print('qualified independent body control', name, flush=True)
    after = intake.derive()
    save('control-source-after.json', after)
    need(before == after == load('intake-before.json'), 'complete inherited source meanings conserve across genuine body controls')
    save('body-controls.json', dict(cases=outcomes, source_before=pin(canonical(before)), source_after=pin(canonical(after)),
        scope='Independent original captured body/empty/byte conservation only. New full semantic association separating controls remain .5.2.2.2.'))
    print('PASS complete independent body conservation and genuine whole candidate refusals; semantic qualification remains pending.')


if __name__ == '__main__':
    main()
