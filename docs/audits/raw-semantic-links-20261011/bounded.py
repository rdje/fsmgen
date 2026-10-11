"""Run each complete semantic intervention in a fresh, resumable process."""
import argparse
import copy
import gc
import subprocess
from common import *
import controls
import intake
import reader


def validate(row):
    epoch = programs()
    name, cause, member = row['name'], row['cause'], row['member']
    for kind, command, success in (
        ('native', ['perl', str(BASE / 'native.pl'), str(BASE / member)], controls.NATIVE_SUCCESS),
        ('semantic', ['python3', '-B', str(BASE / 'reader.py'), str(BASE / member)], reader.SUCCESS)):
        result = load(row[kind])
        need(result['command'] == command and result['programmes'] == result['programmes_after'] == epoch
             and result['inputs'] == result['inputs_after']
             and all(identity(path) == value for path, value in result['inputs'].items())
             and result['candidate'] == result['candidate_after'] == identity(BASE / member)
             and local(result['stdout_path']).read_bytes() == result['stdout'].encode()
             and local(result['stderr_path']).read_bytes() == result['stderr'].encode(),
             'whole current-epoch bounded case custody: ' + name)
        if kind == 'native' or cause is None:
            need(type(result['status']) is int and result['status'] == 0 and result['stdout'] == success and result['stderr'] == '',
                 'actual complete bounded positive or unchanged body predicate: ' + name)
        else:
            need(type(result['status']) is int and result['status'] != 0 and result['stdout'] == ''
                 and result['stderr'].endswith('ValueError: ' + cause + '\n'), 'actual intended bounded semantic refusal: ' + name)


def one(name, attempt):
    matches = [(n, mutation, cause) for n, mutation, cause in controls.cases() if n == name]
    need(len(matches) == 1, 'one declared complete bounded semantic case')
    _, mutation, cause = matches[0]
    original = product('candidate.json.gz')
    candidate = copy.deepcopy(original)
    if mutation is not None:
        mutation(candidate)
        need(not reader.same(candidate, original), 'genuine complete bounded semantic intervention')
    baseline = inherited()
    need(reader.same({k: v for k, v in candidate.items() if k != 'semantic_links'}, baseline),
         'every whole inherited component conserves before bounded judgement')
    member = 'control-' + name + '.json.gz'
    if (BASE / member).exists():
        need(reader.same(product(member), candidate), 'whole saved bounded candidate equals exact declared intervention')
    else:
        save_product(member, candidate)
    # Drop all full decoded products before native or semantic subprocesses.
    # The outer process also exits after this one case; no allocator lifetime
    # spans the corpus. The unchanged RAM guard measures the actual outcome.
    del original, candidate, baseline
    gc.collect()
    prefix = 'bounded-' + attempt + '-control-' + name
    controls.run(prefix + '-native', ['perl', str(BASE / 'native.pl'), str(BASE / member)], member)
    controls.run(prefix + '-semantic', ['python3', '-B', str(BASE / 'reader.py'), str(BASE / member)], member)
    row = dict(name=name, cause=cause, member=member, native=prefix + '-native-actual.json',
               semantic=prefix + '-semantic-actual.json', attempt=attempt)
    validate(row)
    save('bounded-case-' + name + '-' + attempt + '.json', row)
    print('PASS bounded complete semantic case ' + name, flush=True)


def complete(name, cause):
    for path in sorted(BASE.glob('bounded-case-' + name + '-*.json')):
        row = load(path.name)
        need(row['name'] == name and row['cause'] == cause, 'exact bounded resume case identity')
        validate(row)
        return row
    return None


def audit(name):
    saved = load('bounded-controls.json')
    rows = [row for row in saved['cases'] if row['name'] == name]
    cases = [(n, mutation, cause) for n, mutation, cause in controls.cases() if n == name]
    need(len(rows) == len(cases) == 1, 'one complete current bounded audit case')
    row, (_, mutation, cause) = rows[0], cases[0]
    need(row['cause'] == cause, 'exact current bounded assertion contract')
    expected = product('candidate.json.gz')
    if mutation is not None:
        mutation(expected)
    observed = product(row['member'])
    need(reader.same(expected, observed)
         and reader.same({k: v for k, v in observed.items() if k != 'semantic_links'}, inherited()),
         'whole current bounded intervention and every inherited component')
    del expected, observed
    gc.collect()
    validate(row)
    print('PASS current bounded complete candidate and result ' + name, flush=True)


def main(attempt):
    before = intake.derive()
    source_before = 'bounded-source-before-' + attempt + '.json'
    save(source_before, before)
    outcomes = []
    for name, mutation, cause in controls.cases():
        row = complete(name, cause)
        if row is None:
            prefix = 'bounded-driver-' + attempt + '-' + name
            command = ['python3', '-B', str(BASE / 'bounded.py'), '--case', name, '--attempt', attempt]
            epoch = programs()
            stdout, stderr = BASE / (prefix + '.stdout.txt'), BASE / (prefix + '.stderr.txt')
            save(prefix + '-started.json', dict(command=command, programmes=epoch,
                stdout_path=str(stdout), stderr_path=str(stderr), outcome='missing terminal result is non-success'))
            with stdout.open('xb', buffering=0) as out, stderr.open('xb', buffering=0) as err:
                result = subprocess.run(command, stdout=out, stderr=err)
            actual = dict(command=command, programmes=epoch, programmes_after=programs(), status=result.returncode,
                stdout=stdout.read_bytes().decode(), stderr=stderr.read_bytes().decode(),
                stdout_path=str(stdout), stderr_path=str(stderr))
            save(prefix + '-actual.json', actual)
            need(actual['programmes'] == actual['programmes_after'] and type(actual['status']) is int
                 and actual['status'] == 0 and actual['stderr'] == ''
                 and actual['stdout'] == 'PASS bounded complete semantic case ' + name + '\n',
                 'actual fresh bounded complete-case process: ' + name)
            row = complete(name, cause)
            need(row is not None, 'terminal bounded case exists after actual successful process')
        outcomes.append(row)
        print('qualified fresh-process complete semantic control', name, flush=True)
    after = intake.derive()
    source_after = 'bounded-source-after-' + attempt + '.json'
    save(source_after, after)
    need(before == after == load('intake-before.json'), 'whole inherited source/native/product epoch across bounded controls')
    save('bounded-controls.json', dict(cases=outcomes, source_before=source_before, source_after=source_after, scope=SCOPE,
        limits='Every complete case releases its decoded products before actual child judgements and exits afterward. Resume accepts only complete individual results under the identical current programme/source/candidate epoch. Interrupted groups and partial cases never qualify; original body predicates use only the explicit sole namespace relocation.'))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--case')
    parser.add_argument('--audit-case')
    parser.add_argument('--attempt')
    args = parser.parse_args()
    if args.audit_case is not None:
        need(args.case is None and args.attempt is None, 'read-only current bounded audit role')
        audit(args.audit_case)
    elif args.case is None:
        need(args.attempt is not None and args.attempt.isalnum(), 'plain bounded attempt identity')
        main(args.attempt)
    else:
        need(args.attempt is not None and args.attempt.isalnum(), 'plain bounded attempt identity')
        one(args.case, args.attempt)
