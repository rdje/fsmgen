"""Instrument only observer-held prefixes; original payloads are never output."""
from pathlib import Path

BASE = Path('docs/audits/address-observer-holders-20261010')
ORIGINAL = Path('docs/audits/record-value-original-candidate-20261004/observe.pl')


def build():
    text = ORIGINAL.read_text()
    replacements = [
        ("my $base = 'docs/audits/record-value-original-candidate-20261004';",
         "my $base = 'docs/audits/address-observer-holders-20261010';"),
        ("&& $output =~ m{\\Adocs/audits/record-value-original-candidate-20261004/};",
         "&& $output =~ m{\\Adocs/audits/address-observer-holders-20261010/};"),
        ('my @trials;', '''my @trials;
my @retention;
sub retention_snapshot {
    my ($domain, $index) = @_;
    push @retention, {domain => $domain, index => $index,
        prefixes => {api => scalar @api, copies => scalar @copies,
            helpers => scalar @helpers, parses => scalar @parses,
            consumers => scalar @consumers}};
}'''),
        ('    my $primary = (split /\\n/, $error // \'\')[0] // \'\';',
         "    retention_snapshot('api', $active_api) unless $ok;\n"
         + '    my $primary = (split /\\n/, $error // \'\')[0] // \'\';'),
        ('    @{$parses[$active_parse]}{qw(after accepted error primary result api_end)} =',
         "    retention_snapshot('parses', $active_parse) unless $ok;\n"
         + '    @{$parses[$active_parse]}{qw(after accepted error primary result api_end)} ='),
    ]
    for before, after in replacements:
        if text.count(before) != 1:
            raise ValueError('unique original observer instrumentation site')
        text = text.replace(before, after)
    start = text.index('my $encoded = $json->encode({mode => $mode, trials =>')
    end = text.index("open my $out, '>:raw'", start)
    text = text[:start] + '''# Output only caller-bearing source headers and retained prefix counts.
# No error/stack/native-address bodies, input/result graphs or referent census.
my %headers;
for my $pair ([api => \\@api], [copies => \\@copies], [helpers => \\@helpers],
              [parses => \\@parses], [consumers => \\@consumers]) {
    my ($name, $rows) = @$pair;
    $headers{$name} = [map {
        my $row = $_;
        +{map {exists $row->{$_} ? ($_ => $row->{$_}) : ()}
            qw(kind caller helper parse api api_start api_end parse_start parse_end
               consumer_start consumer_end accepted)}
    } @$rows];
}
my $encoded = $json->encode({mode => $mode, headers => \\%headers,
    snapshots => \\@retention, completed => $test_loaded});
''' + text[end:]
    return text


def main():
    target = BASE / 'probe.pl'
    expected = build().encode()
    if target.exists() and target.read_bytes() != expected:
        raise ValueError('retained complete observer instrumentation')
    if not target.exists():
        target.write_bytes(expected)
    print('PASS exact finite observer instrumentation; outputs exclude native bodies and source payload graphs.')


if __name__ == '__main__':
    main()
