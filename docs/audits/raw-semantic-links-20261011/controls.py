"""Whole new-link interventions; all inherited components and body predicates conserve."""
import copy
import subprocess
from common import *
import intake
import reader

NATIVE_SUCCESS = 'PASS independent original UTF-8 body, empty membership and lossless physical byte conservation; semantics remain pending.\n'


def first(candidate):
    return candidate['semantic_links']['records'][0]


def nested(candidate):
    return next(r for r in candidate['semantic_links']['records'] if r['forwarding'] is not None)


def argument(candidate):
    return next(h for h in first(candidate)['phases'][0]['headers'] if h['arguments'])['arguments'][0]['source']['input']


def cases():
    return [
        ('positive', None, None),
        ('full-stack', lambda c: first(c)['stack']['frames'].reverse(), 'semantic full stack and complete ordered body'),
        ('first-cause', lambda c: first(c)['first_cause'].update(primary='Unrelated first cause'), 'semantic complete source first cause'),
        ('wrong-caller', lambda c: first(c)['phases'][0]['callers'][0].update(frame_index=-1), 'semantic source caller and coordinate association'),
        ('borrowed-address', lambda c: first(c)['phases'][0]['address']['numbers']['references'][0].update(
            source=copy.deepcopy(first(c)['phases'][0]['address']['numbers']['references'][1]['source'])),
            'semantic whole simultaneous address/holder association'),
        ('header-order', lambda c: first(c)['phases'][0]['headers'].reverse(), 'semantic complete ordered source header and arguments'),
        ('argument-role', lambda c: argument(c).update(role='borrowed_role'), 'semantic complete ordered source header and arguments'),
        ('opaque-promotion', lambda c: first(c)['opaque']['allocation'].update(meaning='native private meanings established'), 'semantic complete opaque allocation'),
        ('scope-promotion', lambda c: c['semantic_links'].update(scope='Original native identities established'), 'semantic scope and original native/private boundary'),
        ('omitted-record', lambda c: c['semantic_links']['records'].pop(), 'semantic complete original member allocation'),
        ('nested-cause', lambda c: nested(c)['forwarding'].update(inner_record=copy.deepcopy(nested(c)['record'])), 'semantic whole nested inner/outer cause association'),
        ('phase-order', lambda c: nested(c)['phases'].reverse(), 'semantic complete ordered throw-phase allocation'),
        ('class-promotion', lambda c: first(c)['phases'][0]['classification'].update(inferred_class='native_blessed'), 'semantic whole source guard class and phase'),
        ('public-header', lambda c: first(c)['phases'][0]['public_headers'][0]['allocation'].update(frame_position=-1), 'semantic complete public header association'),
        ('load-operator', lambda c: first(c)['phases'][0]['loads'][0]['allocation'].update(source_operator='require'), 'semantic whole source do and diagnostic load association'),
        ('boolean-phase', lambda c: first(c)['phases'][0]['domain'].__setitem__(3, False), 'semantic complete ordered throw-phase allocation'),
    ]


def run(name, command, member):
    original = local(CONSTRUCTION / 'native.pl').read_bytes()
    need(local(BASE / 'native.pl').read_bytes() == original.replace(
        b"my $base = 'docs/audits/raw-semantic-association-product-20261011';",
        b"my $base = 'docs/audits/raw-semantic-links-20261011';", 1), 'whole original native predicate with sole explicit candidate-namespace relocation')
    epoch = programs()
    selected = {str(Path('docs/audits') / path): identity(Path('docs/audits') / path) for path in PATHS.values()}
    selected[str(CONSTRUCTION / 'native.pl')] = identity(CONSTRUCTION / 'native.pl')
    selected[str(CONSTRUCTION / 'candidate.json.gz')] = identity(CONSTRUCTION / 'candidate.json.gz')
    stdout, stderr = BASE / (name + '.stdout.txt'), BASE / (name + '.stderr.txt')
    started = dict(command=command, programmes=epoch, inputs=selected,
        candidate=identity(BASE / member), stdout_path=str(stdout), stderr_path=str(stderr))
    save(name + '-started.json', started)
    with stdout.open('xb', buffering=0) as out, stderr.open('xb', buffering=0) as err:
        result = subprocess.run(command, stdout=out, stderr=err)
    after = {path: identity(path) for path in selected}
    actual = dict(**started, status=result.returncode, stdout=stdout.read_bytes().decode(), stderr=stderr.read_bytes().decode(),
        inputs_after=after, programmes_after=programs(), candidate_after=identity(BASE / member))
    save(name + '-actual.json', actual)
    need(after == selected and epoch == actual['programmes_after'] and actual['candidate'] == actual['candidate_after'],
         'whole actual semantic control programme/source/candidate epoch conserved')
    return actual


def main():
    original, baseline = product('candidate.json.gz'), inherited()
    before = intake.derive(); save('qualified-control-source-before.json', before)
    outcomes = []
    for name, mutation, cause in cases():
        candidate = copy.deepcopy(original)
        if mutation is not None:
            mutation(candidate)
            need(not reader.same(candidate, original), 'genuine whole semantic-link intervention: ' + name)
        need(reader.same({k: v for k, v in candidate.items() if k != 'semantic_links'}, baseline),
             'every inherited complete component conserves for the actual semantic intervention')
        member = 'control-' + name + '.json.gz'
        if (BASE / member).exists():
            need(reader.same(product(member), candidate), 'whole first saved candidate reused unchanged before fresh judgement')
        else:
            save_product(member, candidate)
        native_command = ['perl', str(BASE / 'native.pl'), str(BASE / member)]
        native = run('qualified-control-' + name + '-native', native_command, member)
        need(type(native['status']) is int and native['status'] == 0 and native['stdout'] == NATIVE_SUCCESS and native['stderr'] == '',
             'actual prior whole-body predicate accepts the unchanged inherited components: ' + name)
        command = ['python3', '-B', str(BASE / 'reader.py'), str(BASE / member)]
        actual = run('qualified-control-' + name + '-semantic', command, member)
        if cause is None:
            need(type(actual['status']) is int and actual['status'] == 0 and actual['stdout'] == reader.SUCCESS and actual['stderr'] == '',
                 'actual independent complete positive semantic qualification')
        else:
            need(type(actual['status']) is int and actual['status'] != 0 and actual['stdout'] == ''
                 and actual['stderr'].endswith('ValueError: ' + cause + '\n'), 'actual intended separating semantic refusal: ' + name)
        outcomes.append(dict(name=name, member=member, cause=cause, native='qualified-control-' + name + '-native-actual.json',
                             semantic='qualified-control-' + name + '-semantic-actual.json'))
        print('qualified prior-preserving complete semantic control', name, flush=True)
    after = intake.derive(); save('qualified-control-source-after.json', after)
    need(before == after == load('intake-before.json'), 'complete inherited source/native/product epoch conserved across semantic controls')
    save('qualified-controls.json', dict(cases=outcomes, source_before=pin(canonical(before)), source_after=pin(canonical(after)), scope=SCOPE,
        limits='Each full candidate preserves the exact inherited projection and passes the actual namespace-adapted prior native body predicate. Fresh whole predecessor defaults before and after the group qualify their unchanged inputs; no sealed whole-copy reader is claimed to accept a changed new product.'))


if __name__ == '__main__':
    main()
