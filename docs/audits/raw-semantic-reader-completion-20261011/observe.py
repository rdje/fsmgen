"""One unchanged D reader with passive own-subtree and host-resource observations."""
import datetime
import re
import subprocess
import time
import traceback
from common import *


def native(command):
    result = subprocess.run(command, capture_output=True, text=True)
    return dict(command=command, status=result.returncode, stdout=result.stdout, stderr=result.stderr)


def memory():
    vm = native(['vm_stat'])
    size = native(['sysctl', '-n', 'hw.memsize'])
    need(all(type(r['status']) is int and r['status'] == 0 and r['stderr'] == '' for r in (vm, size)),
         'complete native memory counters before resource judgment')
    page_size = int(re.search(r'page size of ([0-9]+)', vm['stdout'])[1])
    names = ['Pages active', 'Pages inactive', 'Pages speculative', 'Pages wired down',
             'Pages occupied by compressor', 'Pages purgeable', 'File-backed pages']
    counters = {name: int(re.search(r'^' + re.escape(name) + r':\s*([0-9]+)',
                                  vm['stdout'], re.M)[1]) for name in names}
    used = sum(counters[n] for n in names[:5]) - sum(counters[n] for n in names[5:])
    total = int(size['stdout'])
    need(0 <= used * page_size <= total, 'native occupied-capacity domain')
    return dict(commands=[vm, size], page_size=page_size, counters=counters, total_bytes=total,
                occupied_percent=used * page_size * 100 / total)


def subtree(pid):
    result = native(['ps', '-Ao', 'pid,ppid,rss,command'])
    need(type(result['status']) is int and result['status'] == 0 and result['stderr'] == '',
         'native read-only process census')
    rows = []
    for line in result['stdout'].splitlines()[1:]:
        values = line.strip().split(None, 3)
        need(len(values) == 4, 'complete native process census row')
        rows.append(dict(pid=int(values[0]), ppid=int(values[1]), rss_kib=int(values[2]), command=values[3]))
    selected = {pid}
    while True:
        expanded = selected | {r['pid'] for r in rows if r['ppid'] in selected}
        if expanded == selected:
            break
        selected = expanded
    return dict(command=result['command'], status=result['status'], stderr=result['stderr'],
        rows=[r for r in rows if r['pid'] in selected],
        condition='Transient observed PID/parent/RSS rows only; exact native births and continuous/peak RSS are unmeasured. Unrelated process rows are not retained.')


def main():
    body = local(BASE / 'observe.py').read_bytes()
    command = ['python3', '-B', str(BASE / 'capture.py'), '--attempt', 'D', '--name', 'address-coordinate']
    before = memory()
    started = dict(owner=LEAF, command=command, observer=dict(body=body.decode(), identity=pin(body)),
        programmes=programs(), source=identity(BASE / 'source-after-C-before-D.json'), admission=before,
        launch_ceiling_percent=60,
        condition='One exact unchanged original reader after lower observed host occupancy. The conservative 60% launch ceiling is admission only, not a memory-fit guarantee or a changed original guard. Standard 88% host /4096-MiB per-descendant /2s guard remains the enforcing owner. No retry loop, foreign-process termination or original oracle change.')
    save('observer-D-started.json', started)
    need(before['occupied_percent'] < started['launch_ceiling_percent'],
         'substantially lower native resource headroom before the single original D attempt')
    need(load('source-after-C-before-D.json') == load('intake-before.json')
         and programs() == load('execution-plan.json')['programmes'],
         'whole conserved admitted source and original capture programme epoch before D')
    out_path = local(BASE / 'observer-D.stdout.txt', exists=False)
    err_path = local(BASE / 'observer-D.stderr.txt', exists=False)
    samples_path = local(BASE / 'observer-D-samples.jsonl', exists=False)
    observation_failure = None
    with out_path.open('xb', buffering=0) as out, err_path.open('xb', buffering=0) as err, samples_path.open('xb', buffering=0) as samples:
        child = subprocess.Popen(command, stdout=out, stderr=err)
        try:
            while child.poll() is None:
                observation = dict(date=datetime.datetime.now(datetime.timezone.utc).isoformat(),
                                   root_pid=child.pid, memory=memory(), process=subtree(child.pid))
                samples.write(canonical(observation))
                time.sleep(2)
        except BaseException:
            observation_failure = traceback.format_exc()
        finally:
            # Sampling failure never abandons or substitutes for the original result.
            status = child.wait()
    actual = dict(**started, status=status, stdout_path=str(out_path), stderr_path=str(err_path),
        stdout=out_path.read_text(), stderr=err_path.read_text(), samples=identity(samples_path),
        programmes_after=programs(), observer_after=pin(local(BASE / 'observe.py').read_bytes()),
        observation_failure=observation_failure, after=memory())
    save('observer-D-actual.json', actual)
    print('single unchanged D capture actual status', status, flush=True)
    need(observation_failure is None and type(status) is int and status == 0
         and actual['programmes'] == actual['programmes_after']
         and actual['observer_after'] == pin(body), 'actual successful unchanged original D capture and passive observation epoch')


if __name__ == '__main__':
    main()
