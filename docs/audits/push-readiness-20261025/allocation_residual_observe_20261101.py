from pathlib import Path
import subprocess,os,time,json,hashlib,signal,datetime,collections
root=Path.cwd();base=root/'.artifacts/push-readiness-20261025/allocation-residual-sampling-20261101';receipt=base/'outcome.json';assert not receipt.exists()
fixture='ppif/axi_manager_capacity_status_read_single_beat_multi_depth3_same_id_queue_head_response_demux.ppif'
cmd=['/usr/bin/perl','-I',str(base),'-MCurrentStackSampler','bin/fsmgen','--quiet','--verify-hdl','--output',str(base.relative_to(root)/'observed.sv'),fixture]
env=os.environ.copy();assert 'PERL5OPT' not in env;env['FSMGEN_STACK_SAMPLE_OUTPUT']=str(base/'stacks.jsonl')
def identity(pid):
    r=subprocess.run(['ps','-p',str(pid),'-o','pid=,ppid=,pgid=,lstart=,command='],capture_output=True,text=True)
    if not r.stdout.strip():return None
    a=r.stdout.strip().split(None,8);return {'pid':int(a[0]),'ppid':int(a[1]),'pgid':int(a[2]),'birth':' '.join(a[3:8]),'command':a[8]}
start=time.monotonic();utc=datetime.datetime.now(datetime.timezone.utc).isoformat();settlement=[];reason=None
with (base/'stdout.log').open('xb') as out,(base/'stderr.log').open('xb') as err:
    p=subprocess.Popen(cmd,cwd=root,env=env,stdout=out,stderr=err,start_new_session=True);birth=identity(p.pid)
    while p.poll() is None:
        if time.monotonic()-start>=30:reason='declared_30_second_deadline'
        if any(q.exists() and q.stat().st_size>16777216 for q in [base/'stdout.log',base/'stderr.log',base/'stacks.jsonl']):reason='declared_16MiB_stream_cap'
        if reason:
            fresh=identity(p.pid)
            if fresh is not None:
                assert birth is not None and fresh==birth
                assert fresh['pid']==fresh['pgid']==p.pid and fresh['ppid']==os.getpid() and fresh['command']==' '.join(cmd)
                os.killpg(p.pid,signal.SIGTERM);settlement.append({'signal':'SIGTERM','authenticated_identity':fresh})
            try:p.wait(timeout=5)
            except subprocess.TimeoutExpired:
                fresh=identity(p.pid);assert fresh==birth
                os.killpg(p.pid,signal.SIGKILL);settlement.append({'signal':'SIGKILL','authenticated_identity':fresh});p.wait(timeout=5)
            break
        time.sleep(.1)
status=p.wait();samples=base/'stacks.jsonl';records=[json.loads(l) for l in samples.read_text().splitlines()] if samples.exists() else [];counts=collections.Counter();top=collections.Counter()
for row in records:
    frames=[f for f in row['frames'] if (f.get('subroutine') or '').startswith('FSM::')]
    counts.update({f['subroutine'] for f in frames})
    if frames:top[frames[0]['subroutine']]+=1
source_files={f['file'] for row in records for f in row['frames'] if (f.get('subroutine') or '').startswith('FSM::')};sources=[]
for name in sorted(source_files):
    q=Path(name);q=q if q.is_absolute() else root/q
    if q.is_file():sources.append({'path':str(q.relative_to(root)) if q.is_relative_to(root) else str(q),'bytes':q.stat().st_size,'sha256':hashlib.sha256(q.read_bytes()).hexdigest()})
def normalized(v):
    if isinstance(v,str):return v.replace(str(root),'<repository>')
    if isinstance(v,list):return [normalized(x) for x in v]
    if isinstance(v,dict):return {k:normalized(x) for k,x in v.items()}
    return v
x={'owner':'PUBLICATION-REGRESSION-REPAIRS.20.2.2.2','revision':subprocess.check_output(['git','rev-parse','HEAD'],text=True).strip(),'observed_utc':utc,'command':cmd,'cwd':'.','fixture':{'path':fixture,'sha256':hashlib.sha256((root/fixture).read_bytes()).hexdigest()},'instrument':{'path':str((base/'CurrentStackSampler.pm').relative_to(root)),'sha256':hashlib.sha256((base/'CurrentStackSampler.pm').read_bytes()).hexdigest()},'guard':'unchanged88/4096','declared_interval_microseconds':250000,'declared_wall_deadline_seconds':30,'exit_status':status,'elapsed_seconds':time.monotonic()-start,'stop_reason':reason,'identity':birth,'settlement':settlement,'known_pid_after':identity(p.pid),'sample_count':len(records),'samples_path':str(samples.relative_to(root)),'sampled_top_FSM_methods':top.most_common(20),'sampled_any_frame_FSM_methods':counts.most_common(20),'sampled_source_files':sources,'output_exists':(base/'observed.sv').exists(),'scope':'One separate current CLI clone with periodic deferred-signal Perl stack snapshots. Timing and sample counts are instrumentation-specific, not original full8 stack/latency/distribution or full loaded-footprint evidence. Caller stacks only guide causal investigation; no producer override. Original full8 and the settled180-second confirmation remain untouched.'}
receipt.write_text(json.dumps(normalized(x),indent=2)+'\n')
print(json.dumps({'receipt':str(receipt.relative_to(root)),'exit_status':status,'stop_reason':reason,'sample_count':len(records),'sampled_top_FSM_methods':top.most_common(12),'known_pid_after':identity(p.pid)}))
