use strict;
use warnings;
use lib 'perl';
use JSON::PP;
use Scalar::Util qw(blessed refaddr);
use FSM::Adapter::ISF;
use Lispish;

# A fresh public constructor/normalization replay, not an original heap capture.
# Only own constructor objects and the public plain-array boundary are walked.
my $json = JSON::PP->new->canonical;
my $input = do { local $/; $json->decode(<STDIN>) };
die 'complete two-source public input required' unless ref($input) eq 'ARRAY' && @$input == 2;
my $facade = FSM::Adapter::ISF->new;
my $parser = $facade->{parser};
my $adapter = $parser->{adapter};
my %allowed = map { $_ => 1 } qw(
    FSM::Adapter::ISF FSM::Adapter::ISF::Parser FSM::Adapter::ISF::LispishAdapter
);

sub graph {
    my ($value, $seen, $classes, $path) = @_;
    return $value unless ref($value);
    my $class = blessed($value);
    die 'external object outside own source constructor boundary' if $class && !$allowed{$class};
    my $kind = $class ? 'HASH' : ref($value);
    die 'non-plain public boundary node' unless $kind eq 'HASH' || $kind eq 'ARRAY';
    my $address = refaddr($value);
    return ['reference', $seen->{$address}] if exists $seen->{$address};
    $seen->{$address} = $path;
    $classes->{$path} = $class if $class;
    if ($kind eq 'HASH') {
        my %out;
        for my $key (sort keys %$value) {
            my $escaped = $key;
            $escaped =~ s/~/~0/g;
            $escaped =~ s{/}{~1}g;
            $out{$key} = graph($value->{$key}, $seen, $classes, "$path/$escaped");
        }
        return ['hash', \%out];
    }
    return ['array', [map { graph($value->[$_], $seen, $classes, "$path/$_") } 0 .. $#$value]];
}

my %classes;
my $factory = graph([$facade, $parser, $adapter], {}, \%classes, '');
my @cases;
for my $original (@$input) {
    die 'source scalar required' if !defined($original) || ref($original);
    my $text = $original;
    my $raw = Lispish::multi(\$text);
    die 'public Lispish ARRAY boundary required' unless ref($raw) eq 'ARRAY';
    my $forms = $adapter->normalize_multi($raw);
    my @roots = FSM::Adapter::ISF::Parser::_forms_by_head($forms, 'actor');
    die 'one complete normalized actor required' unless @roots == 1;
    my %plain;
    my $stages = graph([$raw, $forms, $roots[0]], {}, \%plain, '');
    die 'public normalized graph must be plain' if keys %plain;
    push @cases, {source => $original, stages => $stages};
}
print $json->encode({factory => $factory, classes => \%classes, cases => \@cases,
    scope => 'Fresh public source constructor and normalization boundary only; original heap identity and payload/flags unmeasured.'}), "\n";
