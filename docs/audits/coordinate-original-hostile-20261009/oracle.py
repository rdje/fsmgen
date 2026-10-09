"""Separate source-link enumeration and byte-offset intervention oracle."""
import copy
import hashlib
import json
import re
import runpy
from pathlib import Path


def require(ok,why):
    if not ok:
        raise ValueError(why)


def stamp(value):
    raw=value if type(value) is bytes else json.dumps(value,sort_keys=True).encode()
    return {'bytes':len(raw),'sha256':hashlib.sha256(raw).hexdigest()}


def records(raw):
    return {(m['mode'],d,r['index']):r for m in raw['inventories']
            for d,values in m['domains'].items() for r in values['nonempty']}


def resolve(binding,positions,previous):
    targets=[]
    for link in binding['model_links']:
        targets.append(positions['operations'][link[1]][link[3]] if link[0]=='operations'
                       else positions[link[0]+'_positions'][link[1]])
    if not targets:
        require(binding['role']=='nested_capture_eval' and previous is not None,'independent nested eval source position')
        targets=[previous+1]
    require(len(set(targets))==1,'independent complete source-link position')
    return targets[0]


def points(raw,matched,proofs):
    source=matched['source_phases'];rows=records(raw)
    qualified={(m['mode'],c['domain'],c['index']):c for m in proofs['modes'] for c in m['cases']}
    recipes={s['id']:s for s in source['statements']}
    candidates={c['recipe_id']:c for c in matched['expression_alternatives']['candidates']}
    result=[];bindings={}
    def selection(recipe_id,segment):
        candidate=candidates[recipe_id]
        labels=sorted(k for k,v in candidate['line_alternatives'].items() if v==segment['line'])
        require(segment['path'] in candidate['filename_alternatives'] and labels,'independent actual source coordinate')
        return {'recipe_id':recipe_id,'statement_identity':stamp(recipes[recipe_id]),'candidate_identity':stamp(candidate),
            'reported_filename':segment['path'],'reported_line':segment['line'],'matching_line_labels':labels,
            'equivalent_line_labels':candidate['equivalent_line_labels'],'all_filename_alternatives':candidate['filename_alternatives'],
            'all_line_alternatives':candidate['line_alternatives']}
    for refusal in source['refusals']:
        key=refusal['mode'],refusal['domain'],refusal['index'];record=rows[key]
        frames=[i for i,s in enumerate(record['segments']) if s['kind']=='frame']
        origins=[i for i,s in enumerate(record['segments']) if s['kind']=='origin']
        for number,phase in enumerate(refusal['phases']):
            positions=qualified[key]['phases'][number]['complete_own_positions']
            def append(kind,role,index,recipe_id):
                result.append({'key':list(key),'phase':number,'kind':kind,'role':role,'segment_index':index,
                               'selection':selection(recipe_id,record['segments'][index])})
            append('origin','origin',origins[number],phase['origin']['caller']['recipe_id'])
            previous=None
            for index,binding in enumerate(phase['active_path_inner_to_outer']):
                position=resolve(binding,positions,previous);previous=position
                if binding['caller']['kind']=='own_statement':
                    segment_index=frames[position]
                    append('frame',binding['role'],segment_index,binding['caller']['recipe_id'])
                    bindings[(key,number,segment_index)]=index
            append('load','load',frames[positions['load_position']],phase['load']['caller']['recipe_id'])
    return result,bindings


def forwarding(raw,proofs):
    rows=records(raw);result=[]
    for mode in proofs['modes']:
        for case in mode['cases']:
            forwarded=case['forwarded']
            if forwarded is None:
                continue
            child=mode['mode'],'api',forwarded['capture_api']
            parent=mode['mode'],case['domain'],case['index']
            inner=rows[child]['body'].encode();outer=rows[parent]['body'].encode()
            start=forwarded['entire_outer_prefix']['bytes']-len(inner)-1
            require(outer[start:start+len(inner)]==inner,'independent entire forwarded child interval')
            result.append({'child':list(child),'parent':list(parent),'start_bytes':start,'bytes':len(inner)})
    return result


def construct(raw,point,field,value,pairs):
    original=records(raw);key=tuple(point['key']);segment=original[key]['segments'][point['segment_index']]
    for pair in pairs:
        if pair['parent']==list(key) and pair['start_bytes']<=segment['offset_bytes']<pair['start_bytes']+pair['bytes']:
            relative=segment['offset_bytes']-pair['start_bytes'];key=tuple(pair['child'])
            segment=next(s for s in original[key]['segments'] if s['offset_bytes']==relative)
            break
    piece=segment['raw'].encode()
    if field=='line':
        replacement,count=re.subn(rb'(?<= line )[0-9]+(?=\.?\n\Z)',str(value).encode(),piece)
        require(count==1,'independent unique terminal line replacement')
    else:
        suffix=(' line '+str(segment['line'])+('.\n' if segment['kind']=='origin' else '\n')).encode()
        first=len(piece)-len(suffix)-len(segment['path'].encode())
        require(piece[first:-len(suffix)]==segment['path'].encode(),'independent literal terminal filename interval')
        replacement=piece[:first]+value.encode()+suffix
    body=original[key]['body'].encode();start=segment['offset_bytes']
    changed={key:body[:start]+replacement+body[start+segment['bytes']:]}
    for pair in pairs:
        if pair['child']==list(key):
            parent=tuple(pair['parent']);body=original[parent]['body'].encode();start=pair['start_bytes']
            changed[parent]=body[:start]+changed[key]+body[start+pair['bytes']:]
    candidate=copy.deepcopy(raw);rows=records(candidate)
    grammar=runpy.run_path('docs/audits/record-value-original-raw-20261005/trace_inventory.py')['inventory']
    for target,body in changed.items():
        text=body.decode();rows[target].update(body=text,body_identity=stamp(body),**grammar(text))
    require(all(rows[key]==record for key,record in original.items() if key not in changed),'independent whole untargeted record conservation')
    for key in changed:
        require([s['call'] for s in rows[key]['segments'] if s['kind']=='frame']==
                [s['call'] for s in original[key]['segments'] if s['kind']=='frame']
                and rows[key]['context']==original[key]['context'],'independent complete function/argument/context conservation')
    return candidate,sorted(map(list,changed))


def observer_epoch(observer,raw):
    candidate=copy.deepcopy(observer);candidate['original']=raw;rows=records(raw)
    for association in candidate['associations']:
        record=rows[tuple(association['key'])]
        frames=[s for s in record['segments'] if s['kind']=='frame']
        association.update(whole_original=stamp(record),whole_frame=stamp(frames[association['frame_index']]),recorded_context=record['context'])
    return candidate


def borrow_source(source,point,recipe_id,bindings):
    candidate=copy.deepcopy(source);key=tuple(point['key'])
    phase=next(r for r in candidate['refusals'] if (r['mode'],r['domain'],r['index'])==key)['phases'][point['phase']]
    if point['kind']=='frame':
        phase['active_path_inner_to_outer'][bindings[(key,point['phase'],point['segment_index'])]]['caller']['recipe_id']=recipe_id
    else:
        phase[point['kind']]['caller']['recipe_id']=recipe_id
    return candidate
