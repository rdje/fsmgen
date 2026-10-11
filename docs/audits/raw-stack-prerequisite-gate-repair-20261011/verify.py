"""Retain the first aggregate refusal and exact unchanged-ceiling correction."""
import argparse
import base64
import gzip
import json
import re
import stat
import subprocess
import sys
from pathlib import Path

BASE = Path('docs/audits/raw-stack-prerequisite-gate-repair-20261011')
OLD = Path('docs/audits/raw-stack-prerequisites-20261011')
sys.path.insert(0, str(OLD))
from common import OWNER, RAW, canonical, need, pin
import predecessors

TASK = Path('docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md')
REGISTRY = Path('doctrine/live_document_size/surfaces.jsonl')
NATIVE = r'''
my $encoded=do { local $/; <STDIN> }; my $input=decode_json($encoded);
my (%members,$files,$bytes_total,$lines_total,$bytes_each,$lines_each,$width);
($files,$bytes_total,$lines_total,$bytes_each,$lines_each,$width)=(0,0,0,0,0,0);
for my $name (sort keys %$input) {
  my $raw=decode_base64($input->{$name}); my $bytes=length($raw);
  my $lines=()=$raw=~/\n/g; my $part_width=0;
  while ($raw =~ /([^\n]*\n|[^\n]+\z)/g) {
    my $line=$1; $line =~ s/\r?\n\z//;
    $part_width=length($line) if length($line)>$part_width;
  }
  $members{$name}={bytes=>$bytes,sha256=>sha256_hex($raw),lines=>$lines,line_bytes=>$part_width};
  $files++; $bytes_total+=$bytes; $lines_total+=$lines;
  $bytes_each=$bytes if $bytes>$bytes_each; $lines_each=$lines if $lines>$lines_each;
  $width=$part_width if $part_width>$width;
}
print JSON::PP->new->canonical->encode({members=>\%members,metrics=>{
files=>$files,bytes_total=>$bytes_total,lines_total=>$lines_total,
bytes_each=>$bytes_each,lines_each=>$lines_each,line_bytes_each=>$width}}),"\n";
'''
SUCCESS = 'PASS retained aggregate gate refusal, independent complete task-source census and exact measured allowance correction; every ceiling and Knowledge Map allowance remains unchanged.\n'


def git(*args):
    result = subprocess.run(['git', '--no-replace-objects', *args], capture_output=True)
    need(result.returncode == 0 and not result.stderr, 'complete own Git source retrieval')
    return result.stdout


def metrics(sources):
    members = {}
    for name, raw in sources.items():
        lines = raw.split(b'\n')
        widths = [len(line[:-1] if index < len(lines)-1 and line.endswith(b'\r') else line)
                  for index,line in enumerate(lines)]
        members[name] = dict(**pin(raw), lines=raw.count(b'\n'), line_bytes=max(widths, default=0))
    return dict(members=members, metrics=dict(files=len(members),
        bytes_total=sum(row['bytes'] for row in members.values()),
        lines_total=sum(row['lines'] for row in members.values()),
        bytes_each=max(row['bytes'] for row in members.values()),
        lines_each=max(row['lines'] for row in members.values()),
        line_bytes_each=max(row['line_bytes'] for row in members.values())))


def native(sources):
    payload = canonical({name:base64.b64encode(raw).decode() for name, raw in sources.items()})
    command = ['perl', '-MJSON::PP', '-MMIME::Base64=decode_base64', '-MDigest::SHA=sha256_hex', '-e', NATIVE]
    result = subprocess.run(command, input=payload, capture_output=True)
    need(type(result.returncode) is int and result.returncode == 0 and result.stderr == b'',
         'complete actual independent native census')
    need(json.loads(result.stdout) == metrics(sources), 'whole independent Python/native census parity')
    return dict(command=command, stdin=pin(payload), status=result.returncode,
                stdout=result.stdout.decode(), stderr=result.stderr.decode())


def fixed_sources(revision, names):
    result = {}
    process = subprocess.Popen(['git', '--no-replace-objects', 'cat-file', '--batch'],
        stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    try:
        for name in names:
            process.stdin.write((revision+':'+name+'\n').encode()); process.stdin.flush()
            header = process.stdout.readline().split()
            need(len(header) == 3 and header[1] == b'blob', 'complete fixed task source blob')
            result[name] = process.stdout.read(int(header[2]))
            need(len(result[name]) == int(header[2]) and process.stdout.read(1) == b'\n',
                 'whole fixed task source body')
        process.stdin.close()
        need(process.stderr.read() == b'' and process.wait() == 0 and process.stdout.read(1) == b'',
             'complete fixed task source protocol')
    finally:
        if process.poll() is None: process.kill(); process.wait()
    return result


def corrected(before, actual):
    rows = [json.loads(line) for line in before.splitlines()]
    selected = next(row for row in rows if row.get('surface_id') == 'task_evidence')
    need(selected['state'] == 'warning_debt' and actual['lines_each'] < 7200,
         'finish warning-debt slice before mandatory task containment')
    for dimension, value in actual.items():
        need(value <= selected['enforcement_ceilings'][dimension], 'unchanged task ceiling')
        wanted = max(0, min(value + selected['transition']['ratchet_step'][dimension],
                            selected['enforcement_ceilings'][dimension]) - selected['baseline'][dimension])
        selected['transition']['max_growth'][dimension] = max(
            selected['transition']['max_growth'][dimension], wanted)
    return b''.join(canonical(row) for row in rows)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--apply', action='store_true'); args = parser.parse_args()
    root = Path.cwd().resolve(); full = root/BASE
    need(full.resolve() == full and full.is_dir() and full.stat().st_dev == root.stat().st_dev,
         'plain same-volume correction namespace before writes')
    for parent in (full,*full.parents):
        if parent == root: break
        need(not (parent/'.git').exists(), 'own correction namespace before writes')
    record_path = BASE/'record.json'
    if args.apply:
        need(not record_path.exists(), 'retain first correction epoch')
        before = REGISTRY.read_bytes(); active = TASK.read_bytes()
        block = predecessors.blocks(active.decode())[OWNER]
        need('  Status: `active`\n' in block, 'own uncommitted signoff repair before writes')
        text = active.decode().replace(block, block.replace('  Status: `active`\n','  Status: `done`\n',1),1)
        TASK.write_text(text)
        memory = Path('MEMORY.md'); state = memory.read_text().replace(OWNER+'` (active)',RAW+'.5.2` (pending)',1)
        start, end = state.index('- next_action:'), state.index('- in_flight_uncommitted:')
        state = state[:start]+'- next_action: Own exact task-tree containment from this clean prerequisite commit before ordinary growth reaches 7200 lines, then activate the complete raw semantic join .5.2. Preserve original contracts and native/private uncertainty.\n'+state[end:]
        memory.write_text(state)
        names = sorted(str(path) for pattern in ('docs/tasks/*.md','docs/tasks/segments/*/*.md')
                       for path in Path('.').glob(pattern))
        other = subprocess.check_output(['rg','--files','--hidden','-uuu','docs/tasks'], text=True).splitlines()
        independent = sorted(name for name in other if re.fullmatch(r'docs/tasks/(?:[^/]+|segments/[^/]+/[^/]+)\.md',name))
        need(names == independent and len(names) == len(set(names)), 'complete independent task-file population')
        root = Path.cwd().resolve(); sources = {}
        for name in names:
            path = Path(name)
            need(path.resolve() == root/path and stat.S_ISREG(path.lstat().st_mode)
                 and path.stat().st_dev == root.stat().st_dev, 'plain own task input')
            for parent in path.parents:
                if parent == Path('.'): break
                need(not (parent/'.git').exists(), 'own task repository boundary')
            sources[name] = path.read_bytes()
        revision = git('rev-parse','HEAD').decode().strip()
        original = fixed_sources(revision, names)
        need(all(raw == original[name] for name,raw in sources.items() if name != str(TASK)),
             'all unchanged task sources bind complete Git bytes')
        first_task = gzip.decompress((OLD/'qualified-task.md.gz').read_bytes())
        first_sources = dict(original); first_sources[str(TASK)] = first_task
        first = json.loads((OLD/'checks.json').read_bytes())['staged-doctrines']
        need(type(first['status']) is int and first['status'] == 1 and first['epoch_conserved'] is True,
             'whole actual first staged refusal remains non-success')
        first_metrics = metrics(first_sources)['metrics']
        baseline = next(json.loads(line) for line in before.splitlines()
                        if json.loads(line).get('surface_id') == 'task_evidence')
        for dimension, label in (('lines_total','lines'),('bytes_total','bytes')):
            value = first_metrics[dimension]
            wanted = f'total {label} is {value} (> baseline {baseline["baseline"][dimension]} + growth {baseline["transition"]["max_growth"][dimension]})'
            need(wanted in first['stderr'], 'exact independently reconstructed first aggregate refusal')
        measured = metrics(sources); actual_native = native(sources)
        after = corrected(before, measured['metrics']); REGISTRY.write_bytes(after)
        (BASE/'registry-before.txt').write_bytes(before); (BASE/'registry-after.txt').write_bytes(after)
        (BASE/'task-active.md.gz').write_bytes(gzip.compress(active,mtime=0))
        (BASE/'task-after.md.gz').write_bytes(gzip.compress(sources[str(TASK)],mtime=0))
        record = dict(owner=OWNER, source_revision=revision, names=names, measured=measured,
            native=actual_native, first_refusal=first, first_metrics=first_metrics,
            programme=pin(Path(__file__).read_bytes()),
            scope='Exact dated task aggregate correction only. The first sealed proof and failed gate retain; no ceiling, Knowledge Map allowance, original acceptance or native/private scope changes. Mandatory task containment precedes ordinary growth.',
            legs=dict(rederive='Complete glob and rg populations, whole fixed Git task bodies with retained changed task, and Python byte/member metrics.',
                      falsify='Separately implemented Perl byte/member census; actual first production gate refuses both aggregate dimensions, final production gate must pass the exact corrected declaration.',
                      durability='Whole programme, complete Git source boundary, changed task snapshots, registry before/after, native command/input identity/status/streams and first actual refusal.'))
        record_path.write_bytes(canonical(record))
        seal = {path.name:pin(path.read_bytes()) for path in BASE.iterdir() if path.is_file()}
        (BASE/'manifest.json').write_bytes(canonical(seal))
    record = json.loads(record_path.read_bytes())
    seal = json.loads((BASE/'manifest.json').read_bytes())
    need({path.name:pin(path.read_bytes()) for path in BASE.iterdir() if path.is_file() and path.name != 'manifest.json'} == seal
         and all(path.is_file() and not path.is_symlink() for path in BASE.iterdir()), 'whole strict correction namespace')
    need(pin(Path(__file__).read_bytes()) == record['programme'], 'exact corrected programme source')
    sources = fixed_sources(record['source_revision'],record['names'])
    sources[str(TASK)] = gzip.decompress((BASE/'task-after.md.gz').read_bytes())
    need(metrics(sources) == record['measured'] and native(sources) == record['native'], 'whole dated independent correction census')
    need(corrected((BASE/'registry-before.txt').read_bytes(),record['measured']['metrics']) == (BASE/'registry-after.txt').read_bytes(),
         'only exact measured task allowance dimensions change')
    need(json.loads((OLD/'checks.json').read_bytes())['staged-doctrines'] == record['first_refusal'], 'first staged failure remains whole')
    print(SUCCESS,end='')


if __name__ == '__main__': main()
