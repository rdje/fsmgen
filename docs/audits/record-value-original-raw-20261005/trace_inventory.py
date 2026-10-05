"""Reversible serialized-error grammar; annotations confer no frame meaning."""
import re

ADDRESS = re.compile(r'0x[0-9a-fA-F]+')
FRAME = re.compile(r'\t(?P<call>.+) called at (?P<path>.+) line (?P<line>[0-9]+)\Z')
ORIGIN = re.compile(r' at (?P<path>.+) line (?P<line>[0-9]+)\.\Z')


def inventory(body):
    if type(body) is not str:
        raise ValueError('raw serialized error kind')
    segments = []
    offset = 0
    for raw in body.splitlines(keepends=True):
        text = raw[:-1] if raw.endswith('\n') else raw
        row = {'offset_bytes': offset, 'raw': raw, 'bytes': len(raw.encode()), 'kind': 'message'}
        frame, origin = FRAME.fullmatch(text), ORIGIN.fullmatch(text)
        if frame:
            row.update(kind='frame', call=frame['call'], path=frame['path'], line=int(frame['line']))
        elif origin:
            row.update(kind='origin', path=origin['path'], line=int(origin['line']))
        elif text == '':
            row['kind'] = 'blank'
        segments.append(row)
        offset += row['bytes']
    assert ''.join(row['raw'] for row in segments) == body, 'lossless physical segmentation'
    assert offset == len(body.encode()), 'complete serialized UTF-8 byte allocation'
    addresses = [{'start_bytes': len(body[:match.start()].encode()), 'end_bytes': len(body[:match.end()].encode()),
                  'lexeme': match.group()} for match in ADDRESS.finditer(body)]
    return {'segments': segments, 'opaque_lexemes': addresses}
