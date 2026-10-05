"""Replay complete scoped source/rendered/native classification and rejecting controls."""
import copy
import hashlib
import importlib.util
import json
import subprocess
import sys
from pathlib import Path

BASE = Path('docs/audits/book-reference-classification-20261005')
spec = importlib.util.spec_from_file_location('scoped_link_classification', BASE / 'classify.py')
classifier = importlib.util.module_from_spec(spec); spec.loader.exec_module(classifier)


def same(a, b):
    return json.dumps(a, sort_keys=True, allow_nan=False) == json.dumps(b, sort_keys=True, allow_nan=False)


def check(source, exported, native, supplement):
    for row in list(exported['responses'].values()) + [r['entry'] for r in exported['chapters'].values()] + [exported['missing_control']]:
        assert type(row['status']) is int, 'captured HTTP status retains producer integer kind'
        raw = row['body'].encode()
        assert same({'bytes': row['bytes'], 'sha256': row['sha256']}, {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}), 'whole actual export HTTP body identity'
    assert all(type(row['status']) is int for row in list(native['responses'].values()) + [native['missing_control']]), 'native HTTP status retains producer integer kind'
    for path, body in source['sources'].items():
        assert subprocess.check_output(['git', 'show', source['revision'] + ':' + path]).decode() == body, 'complete actual committed source/render configuration'
    return classifier.classify(source, exported, native, supplement)


def main():
    source = json.loads((BASE / 'source.json').read_text()); exported = json.loads((BASE / 'served.json').read_text())
    native = json.loads((BASE / 'native-served.json').read_text()); supplement = json.loads((BASE / 'provenance-supplement.json').read_text())
    result = check(source, exported, native, supplement)
    assert same(result, json.loads((BASE / 'classification.json').read_text())), 'exact derived classified population and producer forms'
    controls = []
    for name in ('lost-rendered-member', 'false-outside-success', 'lost-canonical-source', 'lost-native-anchor', 'Boolean-native-outcome', 'float-native-status', 'live-export-server'):
        a, b, c, d = copy.deepcopy(source), copy.deepcopy(exported), copy.deepcopy(native), copy.deepcopy(supplement)
        if name == 'lost-rendered-member':
            b['chapters']['90-reference-map']['links'].pop()
        elif name == 'false-outside-success':
            target = result['classified_links'][0]['resolved_path']
            b['responses'][target]['status'] = c['responses'][target]['status'] = 200
        elif name == 'lost-canonical-source':
            target = result['classified_links'][0]['source']['canonical']
            canonical = a['canonical'].get(target) or d[target]
            canonical['text'] = canonical['text'][:-1]
        elif name == 'lost-native-anchor':
            target = '/90-reference-map.html'
            c['responses'][target]['body'] = c['responses'][target]['body'].replace('id="knowledge-map-architecture"', 'id="missing-architecture"')
        elif name == 'Boolean-native-outcome':
            c['server_status'] = True
        elif name == 'float-native-status':
            target = result['classified_links'][0]['resolved_path']; c['responses'][target]['status'] = 404.0
        else:
            b['server_stopped'] = False
        try:
            check(a, b, c, d)
        except AssertionError as error:
            controls.append({'control': name, 'refusal': str(error)})
        else:
            raise AssertionError('false-green classified route boundary: ' + name)
    proof = {'revision': source['revision'], 'controls': controls,
             'prior_adjudication': 'docs/knowledge/downstream-consumer-contract-lockstep.md already records the same outside-book delivery mechanism for a different downstream chapter; this scoped native capture does not contradict its completed include repair.',
             'scope': result['scope']}
    target = BASE / 'controls.json'
    if target.exists():
        assert same(json.loads(target.read_text()), proof)
    else:
        target.write_text(json.dumps(proof, sort_keys=True, indent=2) + '\n')
    if '--current' in sys.argv:
        assert all(Path(path).read_text() == text for path, text in source['sources'].items()), 'complete current admitted source/include/config/SUMMARY identity'
    manifest = BASE / 'manifest.json'
    if manifest.exists():
        for path, pin in json.loads(manifest.read_text()).items():
            raw = Path(path).read_bytes()
            assert same(pin, {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}), 'complete immutable capture/programme/control identity'
    print('PASS complete scoped canonical-source/rendered/native-export classification; genuine source/member/status/anchor/kind/shutdown controls reject.')


if __name__ == '__main__':
    main()
