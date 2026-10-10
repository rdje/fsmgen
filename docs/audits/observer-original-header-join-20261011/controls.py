"""Actual complete raw/header interventions and declared predecessor distinctions."""
import copy
import gzip
from common import BASE, CLASS, HEADERS, SCOPE, canonical, load, need, pin, read, same, save
import join_headers
import oracle


def module(path):
    namespace = {'__name__':'original_header_control_dependency','__file__':str(path)}
    exec(compile(path.read_bytes(),str(path),'exec'),namespace)
    return namespace


def controls(write=False):
    original = read(CLASS/'raw-product.json')['inventories']
    product = read(HEADERS/'headers.json')
    selection = load('selected.json')
    joined = load('joined.json')
    old = module(CLASS/'verify.py')
    trace = old['public']['context']['module'](old['public']['context']['RAW']/'trace_inventory.py')['inventory']
    expected = read(CLASS/'source-models.json')
    nested = old['public']['context']['nested_records'](expected['frame_model']['own'])
    results=[]
    def record(native, allocation):
        mode,domain,index=allocation['record']
        return next(r for m in native if m['mode']==mode for r in m['domains'][domain]['nonempty'] if r['index']==index)
    def change(native,allocation,new_call=None,remove=False,swap=False):
        row=record(native,allocation)
        frames=[s for s in row['segments'] if s['kind']=='frame']
        selected=frames[allocation['frame_position']]
        parts=[s['raw'] for s in row['segments']]
        position=row['segments'].index(selected)
        if remove:
            parts.pop(position)
        elif swap:
            other=row['segments'].index(frames[allocation['frame_position']+1])
            parts[position],parts[other]=parts[other],parts[position]
        else:
            need(new_call is not None and selected['raw'].count(selected['call'])==1,'unique complete raw call mutation')
            parts[position]=selected['raw'].replace(selected['call'],new_call,1)
        body=''.join(parts)
        need(body!=row['body'],'genuine whole original body intervention')
        row.update(body=body,body_identity=pin(body.encode()),**trace(body))
    def trial(name,mutate,cause,prior=False):
        native,selected,source,actual=copy.deepcopy((original,selection,product,joined))
        mutate(native,selected,source,actual)
        need(not same([native,selected,source,actual],[original,selection,product,joined]),'genuine whole header control')
        previous=None
        if prior:
            previous=old['prior_predicates'](expected,native,nested)
            need(not same(previous,old['prior_predicates'](expected,original,nested)), 'actual predecessor receives the changed full header')
        # Rebuild the candidate product for raw interventions so this is a real
        # source/encoded-header test, rather than a stale checksum refusal.
        if not same(native,original):
            try:
                actual=join_headers.join(native,selected,source)
                oracle.validate(actual,native,selected,source)
            except ValueError as error:
                refusal=str(error)
            else:
                raise ValueError('accepted hostile complete raw header: '+name)
        else:
            try:
                oracle.validate(actual,native,selected,source)
            except ValueError as error:
                refusal=str(error)
            else:
                raise ValueError('accepted hostile complete header product: '+name)
        need(refusal==cause,'intended whole encoded-header control: '+name+': '+refusal)
        independent = None
        if not same(native,original):
            try:
                oracle.validate(actual,native,selected,source)
            except ValueError as error:
                independent = str(error)
            else:
                raise ValueError('independent reader accepted hostile raw header: '+name)
            need(independent==cause,'independent intended whole header control: '+name+': '+independent)
        candidate=canonical(dict(native=native,selection=selected,source=source,joined=actual))
        raw=gzip.compress(candidate,mtime=0)
        path=BASE/'controls'/('candidate-'+name+'.json.gz')
        if write:
            path.parent.mkdir(exist_ok=True)
            if path.exists():
                need(path.read_bytes()==raw,'preserve identical whole first-attempt candidate')
            else:
                path.write_bytes(raw)
        else:
            need(path.read_bytes()==raw,'whole hostile header candidate/replay')
        results.append(dict(name=name,cause=refusal,status='rejected',candidate=str(path.relative_to(BASE)),identity=pin(raw),
                            independent_raw_refusal=independent,
                            limited_predecessor_actual_result=previous,
                            predecessor_meaning='Declared visible-prefix compatibility only; unchanged historical whole-reader custody still rejects mutations.'))
    # The exact diagnosed gap: a different proper prefix is admitted by the
    # limited predecessor and refused by the new whole known-token contract.
    long_public=next(a for a in selection['public_headers']
        if len(product['operands'][a['complete_argument_ids'][0]]['source']['qualification']['value'])>64
        and len(record(original,a)['body'].split('Test::Builder::subtest('))==2)
    original_call=[f for f in record(original,long_public)['segments'] if f['kind']=='frame'][long_public['frame_position']]['call']
    name=join_headers.tokens(product['operands'][long_public['complete_argument_ids'][0]],product)[0]
    shortened='"'+product['operands'][long_public['complete_argument_ids'][0]]['source']['qualification']['value'][0]+'"...'
    trial('different-proper-public-name-prefix',lambda n,s,p,j:change(n,long_public,original_call.replace(name,shortened,1)),
          'whole source-qualified literal argument header',prior=True)
    trial('lost-truncation-marker',lambda n,s,p,j:change(n,long_public,original_call.replace(name,name[:-3],1)),
          'whole source-qualified literal argument header')
    trial('wrong-quote-delimiter',lambda n,s,p,j:change(n,long_public,original_call.replace(name,"'borrowed'",1)),
          'whole source-qualified literal argument header')
    count=next(a for a in selection['source_headers'] if len(next(h for h in product['headers'] if h['id']==a['header_id'])['source_argument_ids'])>8)
    count_call=[f for f in record(original,count)['segments'] if f['kind']=='frame'][count['frame_position']]['call']
    trial('lost-argument-count-marker',lambda n,s,p,j:change(n,count,count_call.replace(', ...)',')',1)),
          'whole source-qualified argument-count marker')
    first=selection['source_headers'][0]
    # Choose the first core _require call; its following operation has a
    # distinct full function, so omission/reordering cannot hide in aliases.
    core=next(a for a in selection['source_headers'] if a['source_path'][-3:]==['own','core',0])
    core_call=[f for f in record(original,core)['segments'] if f['kind']=='frame'][core['frame_position']]['call']
    trial('borrowed-whole-header',lambda n,s,p,j:change(n,core,'main::__ANON__()'),'whole source-qualified call framing')
    trial('omitted-whole-frame',lambda n,s,p,j:change(n,core,remove=True),'whole source-qualified call framing')
    trial('reordered-whole-frames',lambda n,s,p,j:change(n,core,swap=True),'whole source-qualified call framing')
    reference=next(row for row in joined['source_headers'] if any(a.get('qualified_current_alternatives',[]) is None for a in row['joined']['arguments']))
    reference_argument=next(a for a in reference['joined']['arguments'] if a.get('qualified_current_alternatives',[]) is None)
    token=reference_argument['token'];prefix,address=token.rsplit('(0x',1);replacement=prefix+'(0x'+('1' if address[0]!='1' else '2')+address[1:]
    trial('changed-whole-opaque-reference',lambda n,s,p,j:change(n,reference['allocation'],reference['joined']['complete_call'].replace(token,replacement,1)),
          'every complete original raw/address/coordinate/source domain conserves')
    generic='whole independently reconstructed original header result'
    trial('omitted-source-header-result',lambda n,s,p,j:j['source_headers'].pop(),generic)
    trial('reordered-source-header-results',lambda n,s,p,j:j['source_headers'].reverse(),generic)
    trial('wrong-full-source-role',lambda n,s,p,j:j['source_headers'][0]['source_header']['source_metadata'].update(role='borrowed'),generic)
    trial('lost-complete-private-interval',lambda n,s,p,j:j['complete_opaque_allocation'][0]['whole_opaque_frames'].pop(),generic)
    trial('original-settings-promotion',lambda n,s,p,j:j['original_unknowns'].update(settings_formatter='measured'),generic)
    trial('wrong-whole-scope',lambda n,s,p,j:j.update(scope='Original native/provider/private observer acceptance closed.'),generic)
    trial('wrong-qualified-source-profile',lambda n,s,p,j:p['current_profile'].update(MaxArgLen=16),
          'whole committed complete source-header expression')
    return results


if __name__=='__main__':
    save('controls.json',controls(write=True))
    print('PASS genuine complete original raw/header/order/role/quote/truncation/count/source/scope controls and actual limited-predecessor distinction.')
