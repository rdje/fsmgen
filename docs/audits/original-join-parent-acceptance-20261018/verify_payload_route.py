"""Verify native payload admission and complete prior byte-part route conservation."""
import argparse
import copy
import gzip
import io
import json

import allocation_proof_parts as prior_parts
import live_operand_route as route
import payload_proof_parts as parts

SELF = route.AUDIT + 'verify_payload_route.py'
OUTPUT = route.AUDIT + 'payload-native-admission-query-corrected.json.gz'
FIRST = route.AUDIT + 'payload-native-first-query-refusal-20261021.json.gz'
FIRST_SOURCE = route.AUDIT + 'verify_payload_route.first.py.source'
FIRST_SHA = '30cc084b2e035736537f5d3cc6c7f3d1d67e87df63f9e9b1738f4b37fd6a535d'
ADDED_QUESTIONS = ('how are large proof archives stored?',)
BASE = '0e6c3199b0cb0f60a178028ec6acdb63321e07d3'
SCOPE = ('Complete native payload reader/wrapper/role-proof and semantic-record admission; '
         'whole prior byte-part archive, authority/source/proof/helper protocol/member/'
         'order and control conservation; actual listing/public-query receipts and '
         'genuine structural controls only. Native Git, fixed byte codecs, finite shell '
         'parsing and previously qualified source/data/Python/API premises retain. '
         'No listed reader/helper or original model/recipe/cohort executes. Original '
         'source/default/effect/runtime/custody/private/HIAL/full-CI gaps remain.')


def native(path):
    return route.native(path, revision=BASE)


def decoded(raw):
    # Avoid retaining a whole decompressed byte copy alongside the JSON decoder.
    with gzip.GzipFile(fileobj=io.BytesIO(raw)) as compressed:
        with io.TextIOWrapper(compressed, encoding='utf-8') as stream:
            return json.load(stream)


def prior_archive():
    references = {}
    def read(path):
        reference = native(path)
        body = route.unblob(reference.pop('body'))
        reference['identity'] = route.identity(body)
        references[path] = reference
        return body
    route.frozen.equal(route.card.read_file(prior_parts.SELF), read(prior_parts.SELF))
    manifest = json.loads(read(prior_parts.MANIFEST))
    raw = prior_parts.recover(manifest, read)
    route.frozen.equal(route.identity(raw), prior_parts.EXPECTED)
    return raw, references


def query_conservation(before, current, old_card, new_card):
    old_questions = route.card.questions(old_card)
    route.frozen.equal([row['question'] for row in before], old_questions)
    route.query_review(current, new_card)
    retained = [row for row in current if row['question'] in old_questions]
    route.frozen.equal(retained, before)
    added = [row for row in current if row['question'] not in old_questions]
    route.frozen.equal([row['question'] for row in added], list(ADDED_QUESTIONS))
    for row in added:
        expected = ('\t'.join((row['question'], route.card.SOURCE_ID, route.card.SOURCE)) + '\n').encode()
        route.frozen.equal(route.unblob(row['stdout']), expected)
    return dict(prior_questions=old_questions, added=added)


def query_controls(before, current, old_card, new_card):
    outcomes = []
    for label in ('omitted-added-query','reordered-prior-queries','changed-prior-receipt',
                  'borrowed-query-command','changed-added-answer','extra-added-answer','float-query-size'):
        candidate = copy.deepcopy(current)
        if label == 'omitted-added-query': candidate.pop()
        elif label == 'reordered-prior-queries': candidate[0], candidate[1] = candidate[1], candidate[0]
        elif label == 'changed-prior-receipt': candidate[0]['stdout'] = route.frozen.blob(b'changed prior receipt\n')
        elif label == 'borrowed-query-command': candidate[-1]['command'][-1] = before[0]['question']
        elif label == 'changed-added-answer': candidate[-1]['stdout'] = route.frozen.blob(b'changed added answer\n')
        elif label == 'extra-added-answer':
            candidate[-1]['stdout'] = route.frozen.blob(route.unblob(candidate[-1]['stdout']) + b'extra answer\n')
        else: candidate[-1]['stdout']['bytes'] = float(candidate[-1]['stdout']['bytes'])
        try:
            query_conservation(before, candidate, old_card, new_card)
        except AssertionError as error:
            if label == 'float-query-size': assert str(error) == 'JSON value kind'
            outcomes.append(dict(label=label, candidate=candidate, refusal=str(error)))
        else:
            raise AssertionError('changed native query addition admitted: ' + label)
    return outcomes


def first_refusal():
    raw = parts.read_regular(FIRST)
    assert route.identity(raw)['sha256'] == FIRST_SHA, 'immutable complete first query refusal'
    value = decoded(raw)
    route.frozen.equal(value['schema'], 'fsmgen.payload_native_first_query_refusal.v1')
    route.frozen.equal(value['sequence_status'], 1)
    route.frozen.equal(value['command'], ['python3','-B',SELF,'--write'])
    route.frozen.equal(value['source'], route.frozen.blob(parts.read_regular(FIRST_SOURCE)))
    route.frozen.equal(value['prior_archive'], prior_parts.EXPECTED)
    route.frozen.equal(value['current_archive'], parts.EXPECTED)
    route.frozen.equal(value['native_revision'], BASE)
    route.frozen.equal(value['complete_field_delta'], dict(archive=[],caps=[],descriptor=[],queries=[[20]]))
    stream = route.unblob(value['stream']['normalized'])
    assert stream.endswith(b'AssertionError: complete array membership\n')
    assert b'ram-guard: host memory' not in stream and b'ram-guard: descendant' not in stream
    queries = query_conservation(value['prior_queries'],value['current_queries'],
        route.unblob(value['prior_card']),route.unblob(value['current_card']))
    return dict(identity=route.identity(raw), source=value['source'], queries=queries)


def derive():
    prior_raw, prior_references = prior_archive()
    prior_identity = route.identity(prior_raw)
    prior = decoded(prior_raw)
    route.frozen.equal(prior['schema'], 'fsmgen.live_operand_route.v11')
    before = prior['inputs']
    prior_labels = [row['label'] for row in prior['controls']]
    prior_commands = prior['result']['commands']
    del prior, prior_raw
    raw = parts.read()
    product = decoded(raw)
    route.frozen.equal(product['schema'], 'fsmgen.live_operand_route.v12')
    value = product['inputs']
    fixed = route.authority()
    route.frozen.equal(value['programme'], route.frozen.blob(route.card.read_file(route.SELF)))
    route.frozen.equal(product['result'], route.review(value, fixed))
    old_authority = before['authority']
    projected = copy.deepcopy(fixed)
    projected_sources, projected_proofs = dict(value['sources']), dict(value['frozen_inputs'])
    reader = route.AUDIT + 'payload_closure.py'
    wrapper = route.PAYLOAD_COMMAND[-1]
    del projected['sources'][wrapper]
    projected['sources'][reader] = old_authority['sources'][reader]
    del projected['replaced_sources'][reader]
    del projected['frozen_inputs'][route.PAYLOAD_PROOF]
    route.frozen.equal(fixed['replaced_sources'][reader], old_authority['sources'][reader])
    del projected_sources[wrapper]
    projected_sources[reader] = before['sources'][reader]
    del projected_proofs[route.PAYLOAD_PROOF]
    route.frozen.equal(projected, old_authority)
    route.frozen.equal(projected_sources, before['sources'])
    route.frozen.equal(projected_proofs, before['frozen_inputs'])
    for field in ('archive','caps','descriptor'):
        route.frozen.equal(value[field], before[field])
    card_reference = native(route.frozen.CARD)
    route.frozen.equal(value['card'], card_reference['body'])
    route.card.live_questions_retained(route.unblob(before['card']), route.unblob(value['card']))
    query_result = query_conservation(before['queries'], value['queries'],
        route.unblob(before['card']), route.unblob(value['card']))
    query_outcomes = query_controls(before['queries'], value['queries'],
        route.unblob(before['card']), route.unblob(value['card']))
    original_refusal = first_refusal()
    previous_helper = route.unblob(before['helper'])
    expected = previous_helper.replace(b'qualify_allocation_data_roles; do',
        b'qualify_allocation_data_roles qualify_payload_roles; do')
    assert expected != previous_helper, 'exact payload wrapper addition'
    route.frozen.equal(route.unblob(value['helper']), expected)
    route.frozen.equal(product['result']['commands'], prior_commands[:-1] + [route.PAYLOAD_COMMAND] + prior_commands[-1:])
    reference = native(route.AUDIT + 'payload-role-record-controls.json.gz')
    record_raw = route.unblob(reference.pop('body'))
    reference['identity'] = route.identity(record_raw)
    record = decoded(record_raw)
    route.frozen.equal(record['conservation']['after'], fixed['sources'][reader]['body'])
    role = native(route.PAYLOAD_PROOF)
    role_raw = route.unblob(role['body'])
    route.frozen.equal(record['input'], route.frozen.blob(role_raw))
    route.frozen.equal(route.identity(role_raw), fixed['frozen_inputs'][route.PAYLOAD_PROOF]['identity'])
    labels = [row['label'] for row in product['controls']]
    assert len(labels) == len(set(labels)), 'unique genuine route controls'
    assert [label for label in labels if label in prior_labels] == prior_labels, 'every prior control retains order'
    new_labels = [label for label in labels if label not in prior_labels]
    assert new_labels and all('payload' in label for label in new_labels), 'only payload controls added'
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
            if row['label'] == 'float-payload-proof-size':
                assert str(error) == 'JSON value kind'
            outcomes.append(dict(label=row['label'], refusal=str(error)))
        else:
            raise AssertionError('changed payload-admitted route candidate accepted: ' + row['label'])
    route.frozen.equal(route.identity(parts.read()), route.identity(raw))
    return dict(schema='fsmgen.payload_native_admission.v1', scope=SCOPE, native_revision=BASE,
        prior=dict(identity=prior_identity, references=prior_references), proof=route.identity(raw),
        programmes={path: route.frozen.blob(route.card.read_file(path))
                    for path in (SELF, route.SELF, route.HELPER, parts.SELF, prior_parts.SELF)},
        storage=dict(manifest=route.frozen.blob(parts.read_regular(parts.MANIFEST)),
                     contract='Complete first compressed archive from fixed authenticated regular same-volume parts.'),
        semantic_record=reference, original_commands=prior_commands,
        admitted_commands=product['result']['commands'],
        card_epochs=dict(prior=before['card'], committed=card_reference),
        preserved_authority=route.identity(json.dumps(old_authority, sort_keys=True,
            separators=(',', ':'), allow_nan=False).encode()),
        prior_controls=prior_labels, new_controls=new_labels, outcomes=outcomes,
        queries=dict(conservation=query_result, controls=query_outcomes, first_refusal=original_refusal))


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
        route.frozen.equal(decoded(route.card.read_file(OUTPUT)), value)
    print('Native payload admission conserves the complete prior byte-part archive, every earlier authority/source/proof/helper/order/control contract and native semantic-record binding; genuine controls qualify without child execution.')
