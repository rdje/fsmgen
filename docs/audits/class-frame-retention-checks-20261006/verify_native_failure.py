"""Independently reproduce the full first native failure and sole literal repair."""
import difflib
from pathlib import Path


def check(ns):
    base,checks = ns['BASE'],ns['CHECKS']
    require,same,identity,load,module = (ns[k] for k in ('require','same','identity','load','module'))
    first = module(checks / 'first-book.py.txt'); raw = (checks / 'first-book-input.html').read_text()
    try:
        first['check'](raw)
    except ValueError as error:
        require(str(error) == 'native complete semantic-retention scope and retained gaps','whole independently reproduced first native failure')
    else:
        raise ValueError('false-green retained first native guide')
    parsed = first['Visible'](); parsed.feed(raw)
    visible = ' '.join(' '.join(parsed.parts).split()); start = visible.index('The semantic-retention checkpoint')
    end = visible.index('The own subtest source model',start)
    expected = ' '.join(first['GUIDE'].replace('```bash\n','').replace('```\n','').split())
    observed = visible[start:end].strip()
    changes = [[expected[a:b],observed[c:d]] for op,a,b,c,d in difflib.SequenceMatcher(a=expected,b=observed).get_opcodes() if op != 'equal']
    require(changes == [['--','–']],'independent exact sole native smart-punctuation cause')
    retained = load(checks / 'native-failure.json')
    require(retained['changes'] == changes and retained['expected'] == expected and retained['observed'] == observed
        and all(same(pin,identity(Path(p).read_bytes())) for p,pin in retained['retained'].items()),'whole independently retained first native render and programme')
    old = (checks / 'first-book.py.txt').read_text()
    repaired = old.replace('The additional --live-unchanged check','The additional `--live-unchanged` check')
    repaired = repaired.replace("expected = GUIDE.replace('```bash\\n','').replace('```\\n','')",
                                "expected = GUIDE.replace('```bash\\n','').replace('```\\n','').replace('`','')")
    require(repaired != old and (base / 'book.py').read_text() == repaired,'whole exact native guide literal-only programme repair')
    record = load(checks / 'first-book-change.json')
    require(record['after'] == first['transform'](record['before']),'whole independent first source guide publication')
    current = load(base / 'book-change.json')
    require(current['before'] == record['before'] and current['after'] == record['after'].replace('The additional --live-unchanged check','The additional `--live-unchanged` check'),
            'whole sole source option literal repair')
    actual,phases = load(checks / 'first-native-result.json'),load(checks / 'first-native-phases.json')
    require(type(actual['status']) is int and actual['status'] == 1 and len(phases['phases']) == 5
        and all(type(p['status']) is int for p in phases['phases']) and [p['status'] for p in phases['phases']] == [0,0,0,0,1],
            'actual whole retained first native failure versus successful prerequisite phases')
    require(actual['stdout'] == ''.join(p['stdout'] + p['stderr'] for p in phases['phases']) and actual['stderr'].endswith('AssertionError\n'),
            'complete actual retained first native streams and aggregation failure')
    return dict(cause=changes,first_render=identity((checks / 'first-book-input.html').read_bytes()),
        first_actual=identity((checks / 'first-native-result.json').read_bytes()),scope='Complete original native failure independently reproduced; only exact option literal authoring and visible-code matching repaired.')
