"""Genuine whole prospective-canonical interventions within a native guarded run."""
import copy

from canonical_common import *
import reader


def cases():
    return [
        ('omitted-source', lambda row: row['canonical_members'].pop(next(iter(row['canonical_members']))), 'complete own canonical source membership and bodies'),
        ('borrowed-beforeimage', lambda row: row.update(before='Unrelated original card'), 'whole original canonical target beforeimage'),
        ('wrong-consumer-meaning', lambda row: row.update(after=row['after'].replace('Independent source models qualify typed consumer operands/truth', 'Native passed flags qualify consumer truth')), 'whole independently declared finite consumer meanings'),
        ('omitted-question', lambda row: row.update(after=row['after'].replace('  - "what qualifies original T1986 candidate primary causes and acceptance?"\n', '', 1)), 'whole independently declared finite consumer meanings'),
        ('omitted-paragraph', lambda row: row['correspondence'].pop(), 'complete ordered whole meaning correspondence population'),
        ('borrowed-paragraph', lambda row: row['correspondence'][1].update(before=row['correspondence'][2]['before']), 'whole own old new paragraph and reviewed meaning allocation'),
        ('borrowed-review', lambda row: row['review']['changes'][0].update(meaning='Original native private identity is measured'), 'whole explicit review and every declared change consumed once'),
        ('boolean-metric', lambda row: row['proposed'].update(files=True), 'complete independently measured canonical capacity'),
        ('widened-authority', lambda row: row['authority']['enforcement_ceilings'].update(bytes_total=999999999), 'unchanged complete canonical capacity authority'),
        ('boolean-query', lambda row: row['queries']['direct'].update(status=False), 'typed actual original query success'),
        ('borrowed-query', lambda row: row['queries']['direct'].update(command=row['queries']['cached']['command']), 'whole own source-derived actual direct cached question allocation'),
        ('native-promotion', lambda row: row['scope'].update(condition='Original native class and private identities measured'), 'whole original consumer Storable synthetic native private source boundary'),
    ]


def qualify(candidate, inputs):
    outcome = reader.check(candidate, inputs)
    rows = []
    for name, mutate, cause in cases():
        bad = copy.deepcopy(candidate)
        mutate(bad)
        need(not same(bad, candidate), 'genuine changed canonical candidate')
        try:
            reader.check(bad, inputs)
        except ValueError as error:
            need(str(error) == cause, 'intended complete canonical intervention refusal: ' + name)
            rows.append(dict(name=name, candidate=bad, exception='ValueError', cause=str(error)))
        else:
            raise ValueError('false-green canonical proposal: ' + name)
    return dict(positive=outcome, controls=rows,
        role='Actual intended ValueError refusals within this native guarded qualification, not separate child native status1 measurements. Complete hostile products retain; every underlying original source/native/cause product is unchanged.')


if __name__ == '__main__':
    candidate = json.loads((BASE / 'candidate.json').read_bytes())
    result = qualify(candidate, reader.context())
    save_product('controls.json.gz', result)
    print('PASS complete genuine prior-preserving canonical proposal controls; original native and private limits retain.')
