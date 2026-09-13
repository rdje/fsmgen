"""Pure cross-phase applicability checks; modeled and actual coverage stay distinct."""
from copy import deepcopy
import hashlib
import json


def digest(value):
    return hashlib.sha256(json.dumps(value,sort_keys=True,ensure_ascii=True,separators=(',',':'),allow_nan=False).encode()).hexdigest()


def roots(case):
    return [case['roots'][key] for key in ('store','target','other','evidence')]


def verify(value):
    contract=value['contract'];model=value['model'];schedules=value['model_schedules']
    assert digest(contract['schedules'])==contract['schedule_domain_sha256']
    assert digest(schedules)==model['domain_sha256']==contract['schedule_domain_sha256']
    domain={(row['profile'],tuple(row['order'])) for row in contract['schedules']}
    assert len(domain)==len(schedules)==model['serial_orders']==390
    assert {profile:sum(p==profile for p,order in domain) for profile in ('same_image','different_image')}==model['profiles']
    complete=value['complete_selection']['cases'];controls=value['control_selection']['cases']
    good=value['complete_report'];bad=value['control_report']
    assert len(complete)==len(good['cases'])==8 and len(controls)==len(bad['independent_reader']['cases'])==14
    assert {case['profile'] for case in complete}=={'same_image','different_image'}
    complete_roots=[];control_roots=[];coverage=[]
    for case,observed in zip(complete,good['cases'],strict=True):
        assert (case['profile'],tuple(case['order'])) in domain
        assert observed['case']==case['name'] and observed['prefixes']==len(case['order'])
        assert observed['roots']==roots(case);complete_roots.extend(roots(case))
        coverage.append(dict(case=case['name'],profile=case['profile'],order=case['order']))
    witnesses=bad['after_effect_witnesses']
    assert {(row['case'],row['role']) for row in witnesses}=={(case['name'],case['fault']) for case in controls if case['fault'] is not None}
    assert len(witnesses)==3
    for case,observed in zip(controls,bad['independent_reader']['cases'],strict=True):
        prefix=tuple(case['prefix'])
        assert any(profile==case['profile'] and order[:len(prefix)]==prefix for profile,order in domain)
        assert observed['case']==case['name'] and observed['prefixes']==len(prefix)
        assert observed['roots']==roots(case);control_roots.extend(roots(case))
    assert len(complete_roots)==len(set(complete_roots))==32
    assert len(control_roots)==len(set(control_roots))==56 and set(complete_roots).isdisjoint(control_roots)
    assert set(good['roots_absent'])==set(complete_roots) and len(good['roots_absent'])==32
    assert set(bad['roots_absent'])==set(control_roots) and len(bad['roots_absent'])==56
    for report in (good,bad):
        assert report['runtime_qualification'] is report['native_process_authentication'] is False
        assert report['separate_recoveries']==0
        assert report['primary_handles']==report['file_handles']+report['directory_handles']
        assert report['metadata_observers']==report['directory_handles']
    assert good['original_harness_replayed'] is bad['original_execution_replayed'] is False
    return dict(modeled_serial_orders=len(domain),modeled_prefix_states=model['prefix_states'],
        modeled_controls=model['controls'],modeled_omitted_guard_witnesses=model['omitted_guard_witnesses'],
        actual_complete_cases=len(complete),actual_control_cases=len(controls),actual_complete_orders=coverage,
        actual_control_prefixes=sum(len(case['prefix']) for case in controls),
        actual_stages=good['stages']+bad['independent_reader']['stages'],
        retained_journal_records=good['journal_records']+bad['first_journal_records'],
        retained_journal_bytes=good['record_bytes']+bad['first_journal_bytes'],
        observed_primary_handles=good['primary_handles']+bad['primary_handles'],
        observed_metadata_handles=good['metadata_observers']+bad['metadata_observers'],
        recorded_source_calls=good['actual_calls']+bad['recorded_source_calls'],
        fixture_roots=sorted(complete_roots+control_roots),after_effect_witnesses=witnesses,
        modeled_domain_exhausted=True,all_modeled_orders_executed_on_files=False,
        native_process_authentication=False,live_store_authorized=False)


def falsify(value):
    changes=[
        ('missing_model_order',lambda v:v['model_schedules'].pop()),
        ('missing_actual_case',lambda v:v['complete_report']['cases'].pop()),
        ('unsafe_control_prefix',lambda v:v['control_selection']['cases'][0].update(prefix=['maintain_target'])),
        ('missing_after_effect_witness',lambda v:v['control_report']['after_effect_witnesses'].pop()),
        ('promoted_native_authority',lambda v:v['control_report'].update(native_process_authentication=True)),
        ('lost_cleanup_root',lambda v:v['complete_report']['roots_absent'].pop()),
        ('separate_recovery_promoted',lambda v:v['control_report'].update(separate_recoveries=1)),
    ]
    def invalid_order(v):
        case=v['complete_selection']['cases'][0]
        first=case['order'].index('archive_a');last=case['order'].index('release_a')
        case['order'][first],case['order'][last]=case['order'][last],case['order'][first]
    changes.append(('actual_order_outside_domain',invalid_order))
    def overlap(v):
        old=v['control_selection']['cases'][0]['roots']['store'];new=v['complete_selection']['cases'][0]['roots']['store']
        v['control_selection']['cases'][0]['roots']['store']=new
        v['control_report']['independent_reader']['cases'][0]['roots'][0]=new
        v['control_report']['roots_absent']=[new if path==old else path for path in v['control_report']['roots_absent']]
    changes.append(('coherent_cross_run_root_overlap',overlap))
    rejected=[]
    for label,change in changes:
        altered=deepcopy(value);change(altered)
        try:verify(altered)
        except (AssertionError,KeyError,ValueError,IndexError,TypeError):rejected.append(label)
        else:raise AssertionError('accepted inconsistent lifetime join: '+label)
    return rejected
