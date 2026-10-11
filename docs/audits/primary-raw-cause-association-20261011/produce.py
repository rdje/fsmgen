"""Build a proposed cause join from separately qualified retained products."""
from cause_common import *


def proposed():
    data, identities = inputs()
    raw = {(mode['mode'], domain, record['index']): record
           for mode in data['raw']['inventories'] for domain, group in mode['domains'].items()
           for record in group['nonempty']}
    semantics = {tuple(row['record']): row for row in data['semantic']['semantic_links']['records']}
    modes = []
    for mi, mode in enumerate(MODES):
        native = data[mode]
        primary = data['primary']['proofs'][mi]
        context = data['contexts']['proofs'][mi]
        domains = {}
        for domain in DOMAINS:
            members = native[domain] if domain != 'test_run' else [native['test_run']]
            records, empty, nonempty = [], [], []
            for index, actual in enumerate(members):
                key = mode, domain, index
                source = (primary['complete_source_API_primary_models'][index] if domain == 'api' else
                          context['parsers'][index] if domain == 'parses' else None)
                message = (source['primary'] if domain == 'api' else primary['parsers'][index]['primary'] if domain == 'parses' else None)
                error = actual['error']
                (nonempty if error else empty).append(index)
                status_field = 'completed' if domain == 'test_run' else 'accepted'
                records.append(dict(record=list(key), source=source, primary=message,
                    observed_primary=actual.get('primary'),
                    status=dict(field=status_field, value=actual[status_field],
                        authority='source_first_cause' if domain in ('api', 'parses') else 'qualified_prior_observation'),
                    native=pin(canonical(actual)), product=pin(canonical(actual.get('result'))),
                    raw=raw.get(key), semantic=semantics.get(key)))
            domains[domain] = dict(population=len(members), empty=empty, nonempty=nonempty, records=records)
        helpers = []
        for source, cause, actual in zip(context['source_helpers'], primary['helpers'], native['helpers'], strict=True):
            domain = 'api' if cause['failing_api_members'] else 'parses'
            member = (cause['failing_api_members'] or cause['failing_parse_members'])[0]
            helpers.append(dict(source=source, primary=cause['primary'], first_record=[mode, domain, member],
                failing_api_members=cause['failing_api_members'], failing_parse_members=cause['failing_parse_members'],
                native=pin(canonical(actual))))
        modes.append(dict(mode=mode, domains=domains, helpers=helpers))
    return dict(schema_version=1, owner=PLAN['owner'], revision=PLAN['revision'], inputs=identities,
                boundary=boundary(data), modes=modes)


if __name__ == '__main__':
    candidate = proposed()
    save_product('candidate.json.gz', candidate)
    print('Built complete proposed original primary/raw cause association; independent qualification remains required.')
