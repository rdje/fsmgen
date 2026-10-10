"""Independent whole Git/source inventory and actual fresh prerequisite gate."""
import hashlib
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/address-source-integration-20261010')


def pin(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def qualify(spec, binding):
    checks = json.loads((BASE / 'checks.json').read_bytes())
    actual = checks['first-source']
    expected = 'PASS complete corrected source frontier and whole fixed-Git models; integration awaits independent qualification.\n'
    if (type(actual['status']) is not int or actual['status'] != 0 or actual['stdout'] != expected
            or actual['instruments'][str(BASE / 'source.py')] != pin((BASE / 'source.py').read_bytes())):
        raise ValueError('actual fresh complete source frontier qualification')
    for path, identity in binding['inputs'].items():
        raw = Path(path).read_bytes()
        committed = subprocess.check_output(['git', 'show', binding['revision'] + ':' + path])
        if pin(raw) != identity or raw != committed:
            raise ValueError('whole fixed Git source integration input: ' + path)
    expected_names = {'operation', 'private', 'value', 'metadata', 'nested', 'helper',
                      'entry', 'actor', 'contexts', 'parser', 'holders'}
    if set(spec['models']) != expected_names:
        raise ValueError('complete integration prerequisite registry')
    for name, parts in spec['models'].items():
        if set(parts) != {'inputs', 'hypotheses'}:
            raise ValueError('complete source model and input pair')
        for row in parts.values():
            if row['path'] not in binding['inputs'] or pin(Path(row['path']).read_bytes()) != row['identity']:
                raise ValueError('complete source model/input bytes')
    value = Path('perl/FSM/Support/ISFRecordPortValues.pm').read_text()
    required = ["$source = dclone($source) if ref($source) eq 'HASH';",
                "$target = dclone($target) if ref($target) eq 'HASH';",
                'my $root = $scope->{$name};', '$root = dclone($root);',
                'my $spec = $root->{type_spec};', 'for my $layer (qw(outer local))',
                '$scope{$name} = {', 'type_spec => FSM::Package::AggregatePathSupport->clone_structured_value($spec),']
    if not all(text in value for text in required):
        raise ValueError('complete private source assignment/retention contracts')
    return {'fixed_git_inputs': len(binding['inputs']), 'complete_models': len(spec['models']),
            'actual_fresh_frontier': pin(json.dumps(actual, sort_keys=True).encode()),
            'scope': 'Source assignments and whole fixed-Git bytes; independent role/graph/lifetime oracle supplies semantic qualification.'}
