"""The repaired exact reader must refuse genuine first-admission contract changes."""
import contextlib
import copy
import io
import json
from pathlib import Path
from unittest import mock

BASE = Path('docs/audits/address-publication-preparation-20261010')
CASE = BASE / 'schema-first-admission'


def main():
    programme = BASE / 'verify.py'; original_read = Path.read_bytes; original_exists = Path.exists
    real = original_read(BASE / 'proposal.json'); normal = json.loads(real)
    cases = []
    unknown = json.loads(original_read(CASE / 'candidate.json'))
    cases.append(('exact-prior-unknown-native-field', unknown, 'closed complete prospective publication'))
    core = 'docs/knowledge/record-value-finite-copy-probe-reader.md'
    unknown_card = copy.deepcopy(normal); unknown_card['cards'][core]['native_identity'] = True
    cases.append(('unknown-card-native-field', unknown_card, 'closed complete prospective card'))
    scope = copy.deepcopy(normal); scope['scope'] = 'Native identity is proved and current cards are published'
    cases.append(('native-scope', scope, 'exact prospective role and missing publication/native legs'))
    review = copy.deepcopy(normal); review['cards'][core]['paragraphs'][0]['review'] = 'Native identity is proved'
    cases.append(('native-review', review, 'complete ordered reviewed proposition correspondence'))
    beforeimage = copy.deepcopy(normal); beforeimage['beforeimages'][core]['locator'] = 'README.md'
    cases.append(('borrowed-beforeimage-locator', beforeimage, 'whole independent beforeimage membership and schema'))
    outcomes = []
    for name, candidate, cause in cases:
        assert candidate != normal
        namespace = {'__name__': 'repaired_first_admission', '__file__': str(programme)}
        exec(compile(original_read(programme), str(programme), 'exec'), namespace)
        raw = json.dumps(candidate, sort_keys=True, indent=2).encode() + b'\n'
        def read(path):
            return raw if path == BASE / 'proposal.json' else original_read(path)
        def exists(path):
            return False if path == BASE / 'final-proof.json' else original_exists(path)
        def write(*args, **kwargs):
            raise AssertionError('rejected first admission must not write a proof')
        output = io.StringIO()
        with mock.patch.object(Path, 'read_bytes', read), mock.patch.object(Path, 'exists', exists), mock.patch.object(Path, 'write_text', write), contextlib.redirect_stdout(output):
            try:
                namespace['main']()
            except ValueError as error:
                assert str(error) == cause, (name, str(error))
            else:
                raise AssertionError('repaired first-admission false green: ' + name)
        assert output.getvalue() == ''
        outcomes.append({'name': name, 'whole_candidate': namespace['pin'](raw), 'refusal': cause})
    assert original_read(BASE / 'proposal.json') == real
    result = {'scope': 'Genuine first-admission input interception only; no earlier proof is required and no source or status is changed.',
              'programme': namespace['pin'](original_read(programme)), 'cases': outcomes}
    (CASE / 'repair.json').write_text(json.dumps(result, sort_keys=True, indent=2) + '\n')
    print('PASS repaired first-admission root/card/scope/review/beforeimage contracts reject without a prior seal; all original inputs conserve.')


if __name__ == '__main__':
    main()
