"""Independent finite Perl literal reader; no native operands or proposal imports."""
import re
from remaining_common import need


class Literal:
    def __init__(self, source):
        self.source, self.position = source, 0

    def space(self):
        while self.position < len(self.source) and self.source[self.position].isspace():
            self.position += 1

    def take(self, text):
        self.space()
        if self.source.startswith(text, self.position):
            self.position += len(text)
            return True
        return False

    def atom(self):
        self.space()
        need(self.position < len(self.source), 'complete authored literal atom')
        token = self.source[self.position]
        if token in "'\"":
            self.position += 1
            start = self.position
            while self.position < len(self.source) and self.source[self.position] != token:
                need(self.source[self.position] != '\\', 'finite unescaped authored literal')
                self.position += 1
            need(self.position < len(self.source), 'closed authored literal quote')
            value = self.source[start:self.position]
            self.position += 1
            return value
        if self.take('{'):
            result = {}
            while not self.take('}'):
                key = self.atom()
                need(type(key) is str and key not in result and self.take('=>'), 'unique authored hash key/value')
                result[key] = self.atom()
                if self.take('}'):
                    return result
                need(self.take(','), 'authored hash item separator')
            return result
        if self.take('['):
            result = []
            while not self.take(']'):
                result.append(self.atom())
                if self.take(']'):
                    return result
                need(self.take(','), 'authored array item separator')
            return result
        self.space()
        match = re.match(r'[A-Za-z_][A-Za-z_0-9]*|[0-9]+', self.source[self.position:])
        need(match is not None, 'finite authored literal token')
        self.position += len(match[0])
        if match[0] == 'undef':
            return None
        return int(match[0]) if match[0].isdigit() else match[0]

    def whole(self):
        result = self.atom()
        self.space()
        need(self.position == len(self.source), 'whole authored literal expression')
        return result


def graph(value):
    if isinstance(value, dict):
        return ['hash', dict((key, graph(value[key])) for key in sorted(value))]
    if isinstance(value, list):
        return ['array', list(map(graph, value))]
    need(value is None or type(value) in (str, int), 'authored graph primitive domain')
    return value


def json_frame(source):
    import json
    start = source.index('my $string_frame = $json->decode(') + len('my $string_frame = $json->decode(')
    reader = Literal(source[start:source.index(');', start)])
    parts = [reader.atom()]
    while reader.take('.'):
        parts.append(reader.atom())
    reader.space()
    need(reader.position == len(reader.source) and all(type(part) is str for part in parts),
         'complete authored JSON string concatenation')
    return json.loads(''.join(parts))
