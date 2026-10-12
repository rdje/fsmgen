"""Retain native host/process trajectories outside the unchanged RAM guard."""
import argparse
import time
from preparation_common import *

COMMANDS = [['sysctl', '-n', 'hw.memsize'], ['vm_stat'], ['ps', '-axo', 'pid=,ppid=,rss=,comm=']]
CONDITION = ('Observed native host counters and process RSS samples only. RSS is not occupied host capacity; '
             'sparse samples cannot identify an unobserved peak or retrospectively attribute the first failed replay. '
             'Original programme and guard thresholds remain unchanged.')


def sample(origin):
    result = []
    for command in COMMANDS:
        actual = subprocess.run(command, capture_output=True, text=True)
        result.append(dict(command=command, status=actual.returncode, stdout=actual.stdout, stderr=actual.stderr))
    return dict(elapsed_seconds=time.monotonic() - origin, native=result)


def qualify(label):
    row = load_product(label + '-resources.json.gz')
    need(set(row) == {'owner', 'label', 'command', 'status', 'stdout', 'stderr', 'programme_before',
                     'programme_after', 'samples', 'condition', 'complete'}
         and row['owner'] == PLAN['owner'] and row['label'] == label and row['condition'] == CONDITION
         and row['complete'] is True and type(row['status']) is int and row['status'] == 0,
         'complete successful external resource observation')
    actual = json.loads((BASE / (label + '-actual.json')).read_bytes())
    source = (BASE / 'resource_observer.py').read_bytes()
    need(same(row['programme_before'], dict(body=source.decode(), identity=pin(source)))
         and same(row['programme_before'], row['programme_after'])
         and row['command'] == ['python3', '-B', str(BASE / 'capture.py'), label, *actual['command'][2:]]
         and actual['status'] == actual['expected_status'] == 0
         and row['stdout'] == label + ' actual native status 0\n' and row['stderr'] == '',
         'whole resource instrument command terminal and unchanged successful native replay')
    samples = row['samples']
    need(type(samples) is list and 2 <= len(samples) < 43200, 'bounded complete native resource sample population')
    previous = -1
    for entry in samples:
        need(set(entry) == {'elapsed_seconds', 'native'} and type(entry['elapsed_seconds']) is float
             and previous < entry['elapsed_seconds'] and len(entry['native']) == len(COMMANDS),
             'whole ordered native resource sampling epoch')
        previous = entry['elapsed_seconds']
        for native, command in zip(entry['native'], COMMANDS, strict=True):
            need(set(native) == {'command', 'status', 'stdout', 'stderr'} and native['command'] == command
                 and type(native['status']) is int and native['status'] == 0
                 and type(native['stdout']) is str and native['stdout'] != '' and native['stderr'] == '',
                 'complete actual native OS counter and process census terminal')
    return dict(receipt=pin(canonical(row)), programme=pin(source), samples=len(samples), condition=CONDITION)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('label')
    parser.add_argument('command', nargs=argparse.REMAINDER)
    args = parser.parse_args()
    need(args.command and re.fullmatch('[a-z0-9-]+', args.label), 'explicit ordinary resource-observed gate')
    path = BASE / (args.label + '-resources.json.gz')
    need(not path.exists(), 'retain first complete native resource trajectory')
    folder = Path('.artifacts') / BASE.name / 'observer' / args.label
    folder.mkdir(parents=True, exist_ok=False)
    source = (BASE / 'resource_observer.py').read_bytes()
    origin = time.monotonic()
    samples = [sample(origin)]
    command = ['python3', '-B', str(BASE / 'capture.py'), args.label, *args.command]
    with (folder / 'stdout.txt').open('xb', buffering=0) as out, (folder / 'stderr.txt').open('xb', buffering=0) as err:
        process = subprocess.Popen(command, stdout=out, stderr=err)
        while process.poll() is None:
            try:
                process.wait(timeout=2)
            except subprocess.TimeoutExpired:
                if len(samples) < 43200:
                    samples.append(sample(origin))
        samples.append(sample(origin))
    save_product(args.label + '-resources.json.gz', dict(owner=PLAN['owner'], label=args.label,
        command=command, status=process.returncode, stdout=(folder / 'stdout.txt').read_text(),
        stderr=(folder / 'stderr.txt').read_text(), programme_before=dict(body=source.decode(), identity=pin(source)),
        programme_after=dict(body=(BASE / 'resource_observer.py').read_text(), identity=pin((BASE / 'resource_observer.py').read_bytes())),
        samples=samples, complete=len(samples) < 43200, condition=CONDITION))
    if process.returncode:
        print('Resource-observed gate failed: ' + args.label, flush=True)
        raise SystemExit(process.returncode)
    qualify(args.label)
    print('PASS complete external resource observation: ' + args.label, flush=True)
