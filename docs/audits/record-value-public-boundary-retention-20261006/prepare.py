"""Prepare a superseding proposal and an explicit source-to-survivor review."""
import json
from pathlib import Path

BASE = Path('docs/audits/record-value-public-boundary-retention-20261006')
DRAFT = Path('docs/audits/record-value-public-boundary-draft-20261006')


def save(name, value):
    path = BASE / name
    raw = json.dumps(value, sort_keys=True, indent=2) + '\n'
    if path.exists():
        assert path.read_text() == raw, 'existing retention input differs: ' + name
    else:
        assert not (BASE / 'manifest.json').exists(), 'sealed retention cannot prepare'
        path.write_text(raw)


def main(quiet=False):
    draft = json.loads((DRAFT / 'first-card-proposal.json').read_text())
    before = draft['before']
    blocks = before.split('---', 2)[2].strip().split('\n\n')
    assert len(blocks) == 9
    after = draft['after']
    begin = after.index('Full subtest/require,')
    end = after.index('\nRelated:', begin)
    gaps = (
        'Full observer/display/frame/class-frame/raw-coordinate/address, subtest/load,\n'
        'framework/quoting/truncation and parser-internal meanings stay open.\n'
        'Original provider/hook/class measurements and callback/regex/object/native\n'
        'identity stay unmeasured. Consumer, alias, complete semantic/cold/\n'
        'candidate-parent and permanent/hot/host-native repairs stay open; visual\n'
        'mdBook QA is pending.\n')
    after = after[:begin] + gaps + after[end:]
    after = after.replace('\nObserver models join',
        '\nOwn observer/callback source roles/bodies/allocations inventory.\nObserver models join', 1)
    after = after.replace('Named helper models preserve complete source graphs and active paths.',
                          'Named helpers preserve complete source graphs and active paths.')
    after = after.replace('The complete source join now binds every helper allocation, full supplied/default',
                          'Source join binds every helper allocation, full supplied/default')
    after = after.replace(
        'through both nested throw phases. Source models construct the intended join before\n'
        'recorded contiguous function order and visible argument roles are compared.',
        'through both nested throw phases. Source models construct the intended join\n'
        'before comparing recorded contiguous function order and visible argument roles.')
    after = after.replace('Returned helpers remain separate from active frames.',
                          'Returned helpers are separate from active frames.')
    after = after.replace('title: Original observer and helper source paths',
                          'title: Original observer/helper source paths')
    old_fact = after[after.index('Original Test::Builder/Test::More headers'):]
    fact = (
        'Original Test::Builder/Test::More headers match authored-name prefixes/CODE\n'
        'kinds and body/delegate/entry/do-load order at every throw phase. Independent\n'
        'dated public fixtures select them. Receiver tokens/private eval intervals stay\n'
        'opaque. Wrong name/kind/population/order rejects.\n')
    assert old_fact == (
        'Original Test::Builder/Test::More headers match authored-name prefixes, CODE\n'
        'kinds and body/delegate/entry/do-load order through every throw phase. Separate\n'
        'dated public fixtures select these signatures; receiver tokens and private eval\n'
        'intervals stay opaque. Wrong public name/kind/population/order rejects.\n')
    after = after[:-len(old_fact)] + fact
    # The complete original prose is partitioned independently of the draft's
    # replacement list. Every original paragraph receives a reviewed disposition.
    facts = []

    def add(key, source_blocks, source, targets, rationale):
        facts.append(dict(id=key, blocks=source_blocks, source=source,
                          targets=targets, review=rationale))

    add('observer-inventory', [0], 'Own observer/callback source roles, bodies and operation allocations now inventory.',
        ['Own observer/callback source roles/bodies/allocations inventory.'],
        'Re-form the same source inventory explicitly; do not infer it from helper allocations.')
    add('observer-operation-roles', [0],
        'Observer models join every API/parser operation, eval and installed wrapper with source argument roles.',
        ['Observer models join every API/parser operation, eval and installed wrapper with source argument roles.'],
        'Retain every operation and the source argument qualification literally.')
    add('parser-receiver-boundary', [0], 'The parser receiver role is declared; identity is unmeasured.',
        ['The parser receiver role is declared; identity is unmeasured.'],
        'Unique receiver declaration and identity gap must survive together.')
    add('helper-graphs-active-paths', [0],
        'Named helper models preserve supplied/default inputs, complete source graphs, returned argument-building calls and active paths through both throw phases.',
        ['Named helpers preserve complete source graphs and active paths.',
         'Source join binds every helper allocation, full supplied/default inputs, returned argument-building operations and compiled callback/refusal paths through both nested throw phases.'],
        'Complete graphs and active paths stay explicit; the richer retained join owns supplied/default, returned-call and phase details.')
    add('compiled-footprints-and-gaps', [0],
        'Compiled callback/refuses/helper-wrapper paths bind parameterless operation, source regex-body and label displays; identity and full formatting remain open. Paths now join.',
        ['Compiled callback/refuses/helper-wrapper paths bind parameterless operation, source regex-body and label displays; identity and full formatting remain open.',
         'Source join binds every helper allocation, full supplied/default inputs, returned argument-building operations and compiled callback/refusal paths through both nested throw phases.'],
        'Retain parameterless, regex-body, label, identity and formatting roles; generic joined status is duplicate of the full retained join.')
    add('complete-helper-join', [0],
        'The complete source join now binds every helper allocation, full supplied/default inputs, returned argument-building operations and compiled callback/refusal paths through both nested throw phases.',
        ['Source join binds every helper allocation, full supplied/default inputs, returned argument-building operations and compiled callback/refusal paths through both nested throw phases.'],
        'Only redundant The/complete/now narration is removed; every allocation, full input set and both nested phases remain exact.')
    add('source-before-observation', [0],
        'Source models construct the intended join before recorded contiguous function order and visible argument roles are compared.',
        ['Source models construct the intended join before comparing recorded contiguous function order and visible argument roles.'],
        'Retain the direction of derivation and both visible observation dimensions.')
    add('returned-versus-active', [0], 'Returned helpers remain separate from active frames.',
        ['Returned helpers are separate from active frames.'], 'Only verb tense changes; returned calls remain excluded from active frames.')
    add('separating-controls', [0], 'Complete model/allocation/phase/member/order/operand corruptions reject.',
        ['Complete model/allocation/phase/member/order/operand corruptions reject.'], 'Retain the complete existing corruption vocabulary.')
    for key, source, target in (
        ('subtest-load-gap', 'Full subtest/require', 'subtest/load'),
        ('framework-format-gap', 'public framework/quoting/truncation', 'framework/quoting/truncation'),
        ('parser-internal-gap', 'parser internal paths', 'parser-internal meanings stay open.'),
        ('class-coordinate-gap', 'observer/class-frame/raw coordinates', 'observer/display/frame/class-frame/raw-coordinate/address'),
        ('callback-regex-object-gap', 'actual callback/regex/object/address identity remain separately owned.',
         'callback/regex/object/native identity stay unmeasured.'),
        ('original-profile-gap', 'Original provider/hook/class measurements stay unmeasured.',
         'Original provider/hook/class measurements'),
        ('consumer-alias-gap', 'Consumer, alias, complete semantic/cold/candidate-parent and permanent/hot/native repairs remain open.',
         'Consumer, alias, complete semantic/cold/candidate-parent and permanent/hot/host-native repairs stay open;'),
        ('visual-gap', 'Visual mdBook QA is pending.', 'mdBook QA is pending.'),
    ):
        add(key, [1], source, [target, 'meanings stay open.', 'identity stay unmeasured.'],
            'Merge overlapping open-boundary narration; retain each listed scope explicitly and never promote an unmeasured meaning.')
    add('broader-observer-frame-gap', [2, 3], blocks[3],
        ['Full observer/display/frame/class-frame/raw-coordinate/address',
         'Consumer, alias, complete semantic/cold/candidate-parent', 'hot/host-native repairs stay open;'],
        'The finite-copy introduction is editorial duplication, but its full observer/display/frame/coordinate/address and consumer/alias/cold/hot/host-native boundaries are unique obligations, now explicit in the merged gap.')
    add('reader-topic', [4], blocks[4], [blocks[4]], 'Keep the exact related reader topic and route.')
    add('own-source-heading', [5], blocks[5], [blocks[5]], 'Keep the exact authored-section boundary.')
    add('whole-authored-subtest', [6], blocks[6], [blocks[6]],
        'Byte-exact retention preserves every source-body/delegate/callback/extra-argument/name/kind/identity/opaque-frame fact.')
    add('whole-authored-load', [7], blocks[7], [blocks[7]],
        'Byte-exact retention preserves do, file identifier, error/return accessors, displayed require, formatter boundary, published interfaces and current/original version distinction.')
    add('refined-gap-and-native-identity', [8], blocks[8],
        [blocks[6], blocks[7], 'framework/quoting/truncation',
         'Full observer/display/frame/class-frame/raw-coordinate/address',
         'callback/regex/object/native identity stay unmeasured.', fact],
        'The retained own-source section and completed finite public join explain the refinement; full display/framework/native identity gaps stay explicit. This does not qualify private purposes or historical identity.')
    dispositions = [dict(block=i, source=block, fact_ids=[f['id'] for f in facts if i in f['blocks']],
                         role='exact retained' if i in (4, 5, 6, 7) else 'reviewed re-form or duplicate; see each fact review')
                    for i, block in enumerate(blocks)]
    save('proposal.json', dict(before=before, after=after, role='Semantic retention proposal only; live publication remains separate.',
                              revision='89631f67061eb741a95a06e3ec6eb6fa1df335da'))
    save('retention-map.json', dict(blocks=dispositions, facts=facts,
        semantic_review='Explicit engineer review of every source paragraph and each target equivalence. The checker proves exact census/target presence and demonstrated loss rejection, not unrestricted natural-language equivalence.',
        new_fact=fact, new_fact_authority='docs/audits/record-value-public-boundary-join-20261006/scope.txt',
        unpublished_routes='Proposed evidence/reverify paths belong to .5.4.2.2 and are not executed or advertised as current here.'))
    if not quiet:
        print('PASS exact retained proposal constructor and reviewed map; no live mutation.')


if __name__ == '__main__':
    main()
