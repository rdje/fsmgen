"""Join the complete qualified children and public source-neutral constructions."""
from common import BASE, CENSUS, PREDICATE, SCALAR, REGEX, BOUNDARY, SCOPE, canonical, fixed_inputs, need, pin, read, save


def fixtures():
    return dict(
        predicate=dict(plan=read(PREDICATE/'fixture-plan-qualified.json'),
            intervention_plan=read(PREDICATE/'native-control-plan.json'),
            native=read(PREDICATE/'native-qualified.json'),
            driver=(PREDICATE/'native-qualified.pl').read_text(),
            public_contracts=read(PREDICATE/'public-contracts.json')),
        scalar=dict(plan=read(SCALAR/'plan.json'), native=read(SCALAR/'native.json'),
            driver=(SCALAR/'native.pl').read_text()),
        regex=dict(plan=read(REGEX/'plan.json'), native=read(REGEX/'native.json'),
            driver=(REGEX/'native.pl').read_text(), public_contracts=read(REGEX/'public-contracts.json')),
        meaning='Whole qualified source-neutral public constructions only; no current fixture supplies an original setting, native identity or private meaning.')


def product():
    source = read(BOUNDARY/'source-products.json')
    obligations = {}
    for name, paths in read(CENSUS/'census.json')['obligations'].items():
        resolutions = source['obligations'][name]
        need([r['path'] for r in resolutions] == paths, 'whole ordered original obligation membership')
        obligations[name] = [dict(resolution=r,
            value=source['operands' if r['resolution_kind']=='operand' else 'phases'][r['resolution_index']])
            for r in resolutions]
    return dict(scope=SCOPE, source_values=source, obligations=obligations,
        predicate=read(PREDICATE/'predicate-values-qualified.json'),
        scalar=read(SCALAR/'scalars.json'), regex=read(REGEX/'regexes.json'),
        public_constructions=fixtures(),
        dependencies={str(p):pin(p.read_bytes()) for p in fixed_inputs()},
        source_selection=read(BOUNDARY/'source-selection.json'),
        original_opaque=dict(source='separately retained whole original boundary evidence',
            identity=pin((BOUNDARY/'opaque-evidence.json').read_bytes()),
            semantic_oracle=False, native_identity='unmeasured', private_meanings='unmeasured'),
        next_scope='Full source-generated original headers remain separately owned; no original raw-header comparison occurs here.')


if __name__ == '__main__':
    result = product()
    need(not (BASE/'product-qualified.json').exists(), 'select complete parent product once')
    save('product-qualified.json', result)
    print('PASS complete original obligations, whole child values and source-neutral public constructions join without original-header promotion.')
