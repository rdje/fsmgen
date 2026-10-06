"""Compare finite observations to independently fixed public source roles."""
import json
from pathlib import Path


def check(record, expected, require):
    require(type(record['status']) is int and record['status'] == 0,
            'public fixture integer process success')
    for stream in ('stdout', 'stderr'):
        from hashlib import sha256
        raw = record[stream].encode()
        pin = record[stream + '_identity']
        require(type(pin['bytes']) is int and pin == dict(bytes=len(raw), sha256=sha256(raw).hexdigest()),
                'complete public fixture stream byte/kind identity')
    data = json.loads(record['stdout'])
    require(set(data) == {'observations'} and type(data['observations']) is list,
            'complete public observation domain')
    rows = data['observations']
    require([r['role'] for r in rows] == list(expected), 'complete ordered public fixture role population')
    output = {}
    for row in rows:
        role, want = row['role'], expected[row['role']]
        if role.startswith('trace-'):
            require(set(row) == {'role', 'text'} and type(row['text']) is str,
                    'complete public trace observation domain')
            require(want['body'] in row['text'] and all(f in row['text'] for f in want['frames']),
                    'public trace body and own call roles')
            require(all(arg in row['text'] for arg in want.get('visible', []))
                    and all(arg not in row['text'] for arg in want.get('absent', [])),
                    'source-selected public trace argument policy')
            output[role] = dict(own_calls=want['frames'], argument_policy=role,
                full_formatter='unmeasured; complete raw trace retained')
            continue
        loaded = role in ('do-load', 'require-load')
        eval_role = role.startswith('eval-')
        keys = {'role', 'value', 'error', 'loaded'} if loaded else (
            {'role', 'value', 'error', 'frames'} if eval_role else {'role', 'body', 'arguments', 'frames'})
        require(set(row) == keys, 'complete callback/eval/load observation domain')
        context = row['loaded'] if loaded else row
        if loaded:
            require(type(row['value']) is int and row['value'] == 1 and row['error'] == '',
                    'source-selected load success and error roles')
            require(type(context) is dict and set(context) == {'body', 'frames'}
                    and context['body'] == want['body'], 'source-selected public load body')
        elif eval_role:
            require(row['value'] == want['value'] and row['error'] == want['error'],
                    'source-selected public eval return/error roles')
        else:
            require(row['body'] == want['body'], 'source-selected public callback body')
            require(row['arguments'] == want['arguments'], 'source-selected public callback forwarded arguments')
        frames = context['frames']
        require(type(frames) is list and 0 < len(frames) < 128
                and all(type(f) is list and len(f) == 8 for f in frames),
                'complete bounded public caller field population')
        require(all(type(f[0]) is str and type(f[1]) is str and type(f[2]) is int
                    and f[2] > 0 and type(f[3]) is str for f in frames),
                'raw caller field kinds; coordinate recipes remain unmeasured')
        names = [f[3] for f in frames]
        require(names[:len(want['prefix'])] == want['prefix'], 'source-selected own public caller order')
        if eval_role:
            require(frames[2][6] is None and not frames[2][7], 'source-selected block-eval public fields')
        if loaded:
            require(names.count(want['enclosing']) == 1, 'source-selected own enclosing load call')
            end = names.index(want['enclosing'])
            # A visible marker does not change the authored do operator.
            # Only require's documented positive flag is required here.
            if role == 'require-load':
                require(any(f[3] == '(eval)' and f[7] for f in frames[2:end]),
                        'published require positive frame flag')
        output[role] = dict(source_roles=want, own_prefix=names[:len(want['prefix'])],
            external_frames='opaque complete observations retained; no private-name interpretation',
            coordinates='retained raw; source recipes and historical identity unmeasured')
    require(rows[-2]['text'] != rows[-1]['text'], 'genuine public trace policy separation')
    return output
