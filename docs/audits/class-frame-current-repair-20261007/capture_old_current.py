"""Fresh controlled old-role reproduction; restore every live source/projection."""
import json
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, 'scripts')
import check_record_value_publication as current

BASE = Path('docs/audits/class-frame-current-repair-20261007')
REVISION = '9d604ce1311678a4fa1c34e800e0eb57019722e0'
CAUSE = 'whole current physical member and non-target source conservation'


def main():
    products = [BASE / name for name in ('old-current-input.json', 'old-current-actual.json', 'old-current-sources.json')]
    current.require(not any(p.exists() for p in products), 'fresh old-current capture cannot overwrite evidence')
    prior = current.historical()
    paths = [*prior['PATHS'], str(prior['CHAPTER'])]
    original = {p: Path(p).read_bytes() for p in paths}
    projection = {str(p): p.read_bytes() for p in [Path('KNOWLEDGE_MAP.md'), *Path('knowledge-map/generated').glob('*.md')]}
    current.require(all(original[p] == text.encode() for p, text in current.expected_cards(prior).items()),
                    'exact reviewed current targets before controlled old-role reproduction')
    try:
        for p, text in prior['model']['cards']().items():
            current.require(subprocess.check_output(['git', 'show', REVISION + ':' + p]) == text.encode(),
                            'complete fixed old target source epoch')
            Path(p).write_text(text)
        Path(prior['CHAPTER']).write_bytes(subprocess.check_output(['git', 'show', REVISION + ':' + str(prior['CHAPTER'])]))
        subprocess.run(['knowledge-map/scripts/gen_knowledge_map.sh'], check=True, capture_output=True)
        canonical = current.sources()
        names = subprocess.check_output(['git', 'ls-tree', '-r', '--name-only', REVISION, '--', 'docs/knowledge', 'docs/decisions'], text=True).splitlines()
        before = prior['metadata']['git_blobs'](REVISION, sorted(p for p in names if p.endswith('.md')))
        proposal = Path('docs/audits/decision-git-inventory-20261007/git-fact-proposal.md.txt').read_bytes()
        expected = {**before, 'docs/knowledge/decision-record-exact-retrieval.md': proposal}
        current.require(canonical == expected, 'complete old target/current unrelated-extension source epoch')
        record = prior['current_input']()
        current.require(all(actual['stdout'] == prior['metadata']['allocation'](canonical)['rows']
                            for actual in record['queries'].values()), 'complete actual source-derived old-role query allocation')
        products[0].write_text(json.dumps(record, sort_keys=True, indent=2) + '\n')
        products[2].write_text(json.dumps(dict(revision=REVISION,
            proposal=dict(path='docs/audits/decision-git-inventory-20261007/git-fact-proposal.md.txt', identity=current.identity(proposal)),
            members={p: current.identity(raw) for p, raw in canonical.items()},
            scope='Fresh controlled live epoch: fixed committed original targets/book and one independently reviewed unrelated decision-card extension. Every current logical member authenticates; this is not the earlier uncaptured full input.'), sort_keys=True, indent=2) + '\n')
        command = ['python3', '-B', str(current.HISTORICAL / 'verify.py'), '--current']
        execution = subprocess.run(command, capture_output=True, text=True)
        products[1].write_text(json.dumps(dict(command=command, status=execution.returncode, stdout=execution.stdout,
            stderr=execution.stderr, input_identity=current.identity(products[0].read_bytes()),
            programme=current.identity((current.HISTORICAL / 'verify.py').read_bytes())), sort_keys=True, indent=2) + '\n')
        current.require(execution.returncode == 1 and not execution.stdout and execution.stderr.endswith('ValueError: ' + CAUSE + '\n'),
                        'old complete current CLI reaches intended unrelated-epoch refusal')
    finally:
        for p, raw in original.items():
            Path(p).write_bytes(raw)
        subprocess.run(['knowledge-map/scripts/gen_knowledge_map.sh'], check=True, capture_output=True)
        after = {str(p): p.read_bytes() for p in [Path('KNOWLEDGE_MAP.md'), *Path('knowledge-map/generated').glob('*.md')]}
        current.require(projection == after and all(Path(p).read_bytes() == raw for p, raw in original.items()),
                        'every controlled live source/projection restores')
    print('PASS complete actual old-current refusal with fixed targets and unrelated extension; live sources/projections restored.')


if __name__ == '__main__':
    main()
