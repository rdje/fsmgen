"""Attach complete dated original evidence without borrowing semantic values."""
from common import BASE,PUBLIC,RAW,SCOPE,canonical,load,need,pin,read,save


def derive(product,public,raw):
    public_cases={(mode['mode'],case['domain'],case['index']):case
        for mode in public['observations']['modes'] for case in mode['cases']}
    records={(mode['mode'],domain,row['index']):row for mode in raw['inventories']
        for domain,rows in mode['domains'].items() for row in rows['nonempty']}
    bodies={};phases=[]
    for source in product['phases']:
        key=(source['mode'],source['domain'],source['index'])
        case,record=public_cases[key],records[key]
        need(case['original_body']==record['body_identity']==pin(record['body'].encode()),
             'whole inherited original body custody at source boundary')
        identifier=pin(canonical(list(key)))['sha256']
        bodies[identifier]=dict(key=list(key),record=record,
            meaning='Whole inherited original body/record custody only; no new semantic header, identity or private-meaning oracle.')
        phase=case['phases'][source['phase']]
        need(phase['phase']==source['phase'] and phase['source_operator']=='do',
             'whole original public phase and source loading role')
        phases.append(dict(path=source['path'],body=identifier,original_public_boundary=phase,
            original_public_case={k:v for k,v in case.items() if k!='phases'},
            meaning='Every original receiver token, private framework/eval interval and full raw body retains as dated opaque evidence; native identity/settings/private semantics remain unmeasured.'))
    return dict(scope=SCOPE,phases=phases,original_records=bodies,
        inputs={str(path):pin(path.read_bytes()) for path in (PUBLIC,RAW)},
        public_scope=public['observations']['scope'],raw_scope=raw['scope'])


def main():
    need((BASE/'source-products.json').exists() and (BASE/'source-selection.json').exists(),
         'whole source hypotheses precede own opaque attachment')
    save('opaque-evidence.json',derive(load('source-products.json'),read(PUBLIC),read(RAW)))
    print('PASS whole dated original records, public receiver/private boundaries and source allocation retained only as opaque evidence.')


if __name__=='__main__':
    main()
