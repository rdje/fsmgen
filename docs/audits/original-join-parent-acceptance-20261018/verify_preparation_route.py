"""Verify native preparation admission and conserve every earlier route epoch."""
import argparse
import copy
import gzip
import json

import live_operand_route as route

SELF = route.AUDIT + 'verify_preparation_route.py'
OUTPUT = route.AUDIT + 'preparation-native-admission-qualified.json.gz'
PRIOR = route.AUDIT + 'ast-input-live-route-qualified.json.gz'
BASE = 'fecc3ff3b4d81d25f1bd9c357d7d2af7b743eb65'
SCOPE = ('Complete native source/proof epoch and published helper protocol/order '
         'conservation plus saved actual listing/query receipts and genuine route '
         'candidate review. Native Git, finite shell parsing and prior source-role '
         'qualification remain premises. No listed reader, historical body, '
         'model/recipe/cohort or complete helper executes. Source/data/default/'
         'effect/runtime/custody/private/HIAL/full-CI qualification remains open.')


def native(path):
    return route.native(path, revision=BASE)


def derive():
    prior_reference = native(PRIOR)
    prior_raw = route.unblob(prior_reference.pop('body'))
    prior_reference['identity'] = route.identity(prior_raw)
    prior = json.loads(gzip.decompress(prior_raw))
    before = prior['inputs']
    prior_labels = [row['label'] for row in prior['controls']]
    prior_commands = prior['result']['commands']
    del prior, prior_raw

    raw = route.card.read_file(route.OUTPUT)
    product = json.loads(gzip.decompress(raw))
    route.frozen.equal(product['schema'], 'fsmgen.live_operand_route.v9')
    value = product['inputs']
    fixed = route.authority()
    route.frozen.equal(value['programme'], route.frozen.blob(route.card.read_file(route.SELF)))
    route.frozen.equal(product['result'], route.review(value, fixed))

    # Compare whole previous source/proof frames after removing exactly the
    # admitted AST addition and restoring its authenticated prior reader row.
    old_authority = before['authority']
    projected = copy.deepcopy(fixed)
    del projected['sources'][route.PREPARATION_COMMAND[-1]]
    reader = route.AUDIT + 'preparation_correction.py'
    projected['sources'][reader] = old_authority['sources'][reader]
    del projected['replaced_sources'][reader]
    del projected['frozen_inputs'][route.PREPARATION_PROOF]
    route.frozen.equal(projected, old_authority)
    route.frozen.equal(fixed['replaced_sources'][reader], old_authority['sources'][reader])

    projected_sources = dict(value['sources'])
    del projected_sources[route.PREPARATION_COMMAND[-1]]
    projected_sources[reader] = before['sources'][reader]
    route.frozen.equal(projected_sources, before['sources'])
    projected_proofs = dict(value['frozen_inputs'])
    del projected_proofs[route.PREPARATION_PROOF]
    route.frozen.equal(projected_proofs, before['frozen_inputs'])
    for field in ('archive', 'caps', 'descriptor', 'queries'):
        route.frozen.equal(value[field], before[field])
    # The committed diagnosis already added preparation to the bounded card.
    # Preserve both dated bodies; compare this admission with its actual
    # committed predecessor rather than imposing an obsolete card snapshot.
    card_reference = native(route.frozen.CARD)
    route.frozen.equal(value['card'], card_reference['body'])
    route.card.live_questions_retained(route.unblob(before['card']), route.unblob(value['card']))

    previous_helper = route.unblob(before['helper'])
    current_helper = route.unblob(value['helper'])
    expected = previous_helper.replace(b'qualify_ast_input_roles; do',
        b'qualify_ast_input_roles qualify_preparation_roles; do')
    assert expected != previous_helper, 'one literal preparation wrapper addition'
    route.frozen.equal(current_helper, expected)
    route.frozen.equal(product['result']['commands'],
                       prior_commands[:-1] + [route.PREPARATION_COMMAND] + prior_commands[-1:])

    labels = [row['label'] for row in product['controls']]
    assert len(labels) == len(set(labels)), 'unique genuine route controls'
    assert [label for label in labels if label in prior_labels] == prior_labels, 'all earlier controls retain order'
    new_labels = [label for label in labels if label not in prior_labels]
    assert new_labels and all('preparation' in label for label in new_labels), 'only preparation controls added'
    outcomes = []
    for row in product['controls']:
        if row['label'] == 'native-qualified-additive-reader':
            route.review(row['candidate'], fixed)
            outcomes.append(dict(label=row['label'], result=row['result']))
            continue
        try:
            route.review(row['candidate'], fixed)
        except AssertionError as error:
            route.frozen.equal(str(error), row['refusal'])
            if row['label'] == 'float-preparation-proof-size':
                assert str(error) == 'JSON value kind', 'float candidate reaches strict kind comparison'
            outcomes.append(dict(label=row['label'], refusal=str(error)))
        else:
            raise AssertionError('changed route candidate admitted: ' + row['label'])

    route.frozen.equal(route.identity(route.card.read_file(route.OUTPUT)), route.identity(raw))
    return dict(schema='fsmgen.preparation_native_admission.v1', scope=SCOPE,
        prior=prior_reference, proof=route.identity(raw),
        programmes={path: route.frozen.blob(route.card.read_file(path))
                    for path in (SELF, route.SELF, route.HELPER)},
        native_revision=BASE, original_commands=prior_commands,
        admitted_commands=product['result']['commands'],
        card_epochs=dict(prior=before['card'], committed=card_reference),
        preserved_authority=route.identity(
            json.dumps(old_authority, sort_keys=True, separators=(',', ':'), allow_nan=False).encode()),
        prior_controls=prior_labels, new_controls=new_labels, outcomes=outcomes)


if __name__ == '__main__':
    if not __debug__:
        raise SystemExit('Acceptance assertions must be enabled.')
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write', action='store_true')
    args = parser.parse_args()
    value = derive()
    if args.write:
        route.card.save_record(OUTPUT, value)
    else:
        route.frozen.equal(json.loads(gzip.decompress(route.card.read_file(OUTPUT))), value)
    print('Native preparation reader/proof admission conserves every prior epoch, helper protocol, published order and genuine control.')
