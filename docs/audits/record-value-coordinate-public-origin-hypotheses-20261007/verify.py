"""Fix own public origin alternatives without interpreting captured trace text."""
import argparse
import copy
import hashlib
import io
import json
import subprocess
import tarfile
from pathlib import Path

BASE = Path('docs/audits/record-value-coordinate-public-origin-hypotheses-20261007')
SOURCE = Path('docs/audits/record-value-coordinate-public-hypotheses-20261007')
CALLERS = Path('docs/audits/record-value-coordinate-public-caller-selection-20261007')
PROFILE = Path('docs/audits/record-value-public-framework-profile-20261006')
REVISION = '52e2769325318ba5e9f79ff84353e32b44d7b086'
ROOTS = [SOURCE, PROFILE, CALLERS,
         Path('docs/audits/coordinate-public-caller-selection-checks-20261007')]
ROLE = ('Pure-source finite public longmess/confess origin alternatives only. '
        'No captured trace/error origin text is interpreted and no alternative '
        'is selected. Public global/private formatter state and every original '
        'coordinate/identity meaning remain unmeasured.')
SUCCESS = 'PASS complete pure-source public origin hypotheses and genuine controls; trace/error origin interpretation remains pending.\n'
CLAUSES = {
    'full_trace': ('Carp', 'that context is a summary of every call in the call-stack; "longmess()" returns the contents of the error message.'),
    'global_logic': ('Carp', 'You can also alter the way the output and logic of "Carp" works, by changing some global variables in the "Carp" namespace.'),
    'internal_skip': ('Carp', 'the stack backtrace will not start inside packages that are listed in %Carp::CarpInternal.'),
    'confess_not_carp': ('Carp', 'the full stack backtrace from "confess" will not start inside of "Carp"'),
    'formatter': ('Carp', 'For any type of reference, $Carp::RefArgFormatter is checked'),
    'eval_failure': ('eval', '"eval" returns "undef" in scalar context, or an empty list in list context, and $@ is set to the error message.'),
}
OUTER = {
    'single':'CoordinatePublic::single();',
    'multiline':'CoordinatePublic::multiline();',
    'postfix':'CoordinatePublic::postfix();',
    'block-eval':'CoordinatePublic::block_eval();',
    'anonymous':'CoordinatePublic::anonymous();',
    'do-load':'CoordinatePublic::load();',
    'require-load':'CoordinatePublic::load();',
    'module-call':'CoordinateDependency::module_call();',
    'subtest':"$subtest->('public coordinate callback', sub {\n    CoordinatePublic::observe('subtest'); # site subtest\n    pass('public callback ran');\n}); # end subtest boundary",
}
BOUNDARIES = {'block_eval':'block-eval', 'anonymous_delegate':'anonymous',
              'do_load':'do-load', 'require_load':'require-load', 'module_delegate':'module-call'}


def require(value, cause):
    if not value:
        raise ValueError(cause)


def pin(raw):
    return dict(bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())


def same(a, b):
    return json.dumps(a, sort_keys=True) == json.dumps(b, sort_keys=True)


def load(path):
    return json.loads(path.read_bytes())


def namespace(path):
    result = {'__name__':'origin_source_dependency'}
    exec(compile(path.read_bytes(), str(path), 'exec'), result)
    return result


def binding():
    members = {}
    for root in ROOTS:
        paths = list(root.iterdir())
        require(all(p.is_file() and not p.is_symlink() for p in paths), 'complete regular flat source/document/caller prerequisite domain')
        raw = subprocess.check_output(['git','archive',REVISION,str(root)])
        with tarfile.open(fileobj=io.BytesIO(raw)) as archive:
            fixed = {m.name:archive.extractfile(m).read() for m in archive.getmembers() if m.isfile()}
        require({str(p):p.read_bytes() for p in paths} == fixed, 'complete fixed committed source/document/caller/actual members')
        members[str(root)] = {p:pin(raw) for p,raw in fixed.items()}
    task = subprocess.check_output(['git','show',REVISION+':docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md']).decode()
    owners = {}
    for root in (SOURCE, PROFILE, CALLERS):
        owner = (root/'scope.txt').read_text().splitlines()[0].removeprefix('Owner: ')
        a = task.index('- ID: `'+owner+'`'); b = task.index('\n- ID:',a+1)
        owners[owner] = task[a:b]
        require('\n  Status: `done`\n' in owners[owner], 'complete committed source/document/caller completed owner')
    return dict(revision=REVISION,members=members,owners=owners,task_identity=pin(task.encode()),role=ROLE)


def source_inputs():
    selected = namespace(SOURCE/'verify.py')
    source = load(SOURCE/'inputs.json')
    hypotheses = selected['derive'](source)
    require(same(hypotheses,load(SOURCE/'hypotheses.json')), 'whole independently declared pre-native source hypotheses')
    return dict(source=source['source'],source_pins=source['source_pins'],hypotheses=hypotheses,
                documents=load(PROFILE/'public-profile.json'),role=ROLE)


def public_clauses(documents):
    result = {}
    for name, (document, clause) in CLAUSES.items():
        row = documents['commands'][document]
        require(type(row['status']) is int and row['status']==0, 'integer complete public origin document success')
        for stream in ('stdout','stderr'):
            identity_key = 'identity' if stream == 'stdout' else 'stderr_identity'
            require(type(row[stream]) is str and same(row[identity_key],pin(row[stream].encode())),
                    'complete public origin documentation wire identity')
        require(clause in ' '.join(row['stdout'].split()), 'independently selected public origin clause: '+name)
        result[name] = dict(document=document,clause=clause)
    return result


def span(raw, text):
    encoded = text.encode('utf-8')
    require(raw.count(encoded)==1, 'unique independently authored own outer invocation source')
    offset = raw.index(encoded)
    return dict(text=text,offset_bytes=offset,identity=pin(encoded),
                first_line=raw[:offset].count(b'\n')+1,
                closing_line=raw[:offset+len(encoded)].count(b'\n')+1)


def alternative(name, unit, source, filenames):
    return dict(name=name,unit=unit,source=source,filename_hypotheses=filenames,
                line_hypotheses=dict(first=source['first_line'],closing=source['closing_line']))


def derive(inputs):
    require(inputs['role']==ROLE, 'source-only origins cannot select or promote native/original meaning')
    fixed = load(SOURCE/'inputs.json')
    require(same(inputs['source'],fixed['source']) and same(inputs['source_pins'],fixed['source_pins']),
            'whole independently fixed own source identity')
    hypotheses = load(SOURCE/'hypotheses.json')
    require(same(inputs['hypotheses'],hypotheses), 'whole pre-native call/boundary/origin source hypotheses')
    clauses = public_clauses(inputs['documents'])
    calls = hypotheses['calls']; boundaries = hypotheses['boundaries']
    require(set(OUTER)=={r['role'] for r in calls} and set(BOUNDARIES)==set(boundaries),
            'complete own public observation and outer/boundary allocation')
    primary = inputs['source']['fixture.pl'].encode('utf-8')
    rows = []
    for call in calls:
        role = call['role']
        shared = [alternative('observer-call',call['unit'],call['source'],call['filename_hypotheses']),
                  alternative('own-outer-invocation','fixture.pl',span(primary,OUTER[role]),['fixture.pl'])]
        for name, owner in BOUNDARIES.items():
            if owner==role:
                shared.append(alternative('own-boundary:'+name,'fixture.pl',boundaries[name]['source'],['fixture.pl']))
        origins = {}
        for field, origin_name, message in (
                ('trace','longmess_call','public coordinate fixture\n'),
                ('guard_error','confess_call','public coordinate guard\n')):
            origin = hypotheses['trace_origin_sources'][origin_name]
            origins[field] = dict(message=message,
                alternatives=[alternative('own-'+origin_name,'fixture.pl',origin,['fixture.pl']),*shared],
                selected=None,
                unresolved='Any origin outside these independently declared own statements remains unqualified; private external source and formatter/global state are not inferred.')
        rows.append(dict(role=role,origins=origins))
    return dict(cases=rows,clauses=clauses,invocations=hypotheses['invocations'],source_pins=inputs['source_pins'],
                configuration='Public Carp global/internal/formatter states were not measured in the retained captures; public version metadata and own source do not establish them.',role=ROLE)


def controls(inputs, expected):
    def lost_clause(candidate):
        row = candidate['documents']['commands']['Carp']
        row['stdout'] = row['stdout'].replace('stack backtrace will not start inside','borrowed backtrace will not start inside',1)
        row['identity'] = pin(row['stdout'].encode())
    cases = [
        ('borrowed-source',lambda c,i:i['source'].update({'fixture.pl':i['source']['load-body.pl']}), 'whole independently fixed own source identity'),
        ('lost-public-clause',lambda c,i:lost_clause(i), 'independently selected public origin clause: internal_skip'),
        ('Boolean-document-status',lambda c,i:i['documents']['commands']['eval'].update(status=False), 'integer complete public origin document success'),
        ('lost-origin-case',lambda c,i:c['cases'].pop(), 'complete pure-source origin alternatives and unresolved scope'),
        ('borrowed-origin-line',lambda c,i:c['cases'][0]['origins']['trace']['alternatives'][0]['line_hypotheses'].update(first=99999), 'complete pure-source origin alternatives and unresolved scope'),
        ('premature-origin-selection',lambda c,i:c['cases'][0]['origins']['guard_error'].update(selected='own-confess_call'), 'complete pure-source origin alternatives and unresolved scope'),
        ('formatter-state-promotion',lambda c,i:c.update(configuration='Original formatter/global state is measured.'), 'complete pure-source origin alternatives and unresolved scope'),
        ('lost-invocation',lambda c,i:c['invocations'].pop(), 'complete pure-source origin alternatives and unresolved scope'),
    ]
    rows = []
    for name, mutate, cause in cases:
        candidate, source = copy.deepcopy(expected), copy.deepcopy(inputs)
        mutate(candidate,source)
        require(not same(candidate,expected) or not same(source,inputs), 'genuine source-only origin hypothesis control')
        try:
            derived = derive(source)
            require(same(candidate,derived), 'complete pure-source origin alternatives and unresolved scope')
        except ValueError as error:
            require(str(error)==cause, 'intended pure-source origin refusal: '+name)
            rows.append(dict(control=name,status=1,cause=cause))
        else:
            raise ValueError('false-green source-only origin control: '+name)
    return rows


def members():
    require(all(p.is_file() and not p.is_symlink() for p in BASE.iterdir()), 'whole flat regular origin source member domain')
    return {p.name:pin(p.read_bytes()) for p in BASE.iterdir() if p.name!='manifest.json'}


def save(name,value):
    path = BASE/name; encoded = json.dumps(value,sort_keys=True,indent=2)+'\n'
    if path.exists():
        require(path.read_text()==encoded,'whole retained pure-source origin product: '+name)
    else:
        require(not (BASE/'manifest.json').exists(),'sealed source-only origin hypotheses cannot publish')
        path.write_text(encoded)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--seal',action='store_true')
    args = parser.parse_args()
    if (BASE/'manifest.json').exists():
        require(same(load(BASE/'manifest.json'),members()), 'whole immutable pure-source origin seal')
    before = binding(); save('binding.json',before)
    inputs = source_inputs(); save('inputs.json',inputs)
    expected = derive(inputs); save('hypotheses.json',expected)
    save('controls.json',controls(inputs,expected))
    require(same(binding(),before),'every complete source/document/caller prerequisite conserves')
    if args.seal:
        save('manifest.json',members())
    print(SUCCESS,end='')


if __name__ == '__main__':
    main()
