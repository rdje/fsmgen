use strict;
use warnings;
use lib 'perl', 't/lib';
use JSON::PP;
use Scalar::Util qw(refaddr blessed reftype);
use Storable qw(dclone);

my $base = 'docs/audits/reservation-coverage-plain-native-boundary-20261003';
my $json = JSON::PP->new->canonical;
open my $helpers, '<:raw', "$base/helper-body.pl" or die $!;
my $body = do {local $/; <$helpers>}; close $helpers or die $!;
eval $body; die $@ if $@;
sub materialize {
    my ($node, $seen, $path) = @_;
    return $node unless ref($node);
    $seen ||= {}; $path //= '';
    die 'invalid native descriptor' unless ref($node) eq 'ARRAY' && @$node == 2;
    my ($kind, $fields) = @$node;
    if ($kind eq 'reference') {
        die 'unbound native reference' unless exists $seen->{$fields};
        return $seen->{$fields};
    }
    die 'unsupported native descriptor' unless $kind eq 'hash' || $kind eq 'array';
    my $value = $kind eq 'hash' ? {} : [];
    $seen->{$path} = $value;
    if ($kind eq 'hash') {
        for my $key (sort keys %$fields) {
            my $escaped = $key; $escaped =~ s/~/~0/g; $escaped =~ s{/}{~1}g;
            $value->{$key} = materialize($fields->{$key}, $seen, "$path/$escaped");
        }
    } else {
        push @$value, materialize($fields->[$_], $seen, "$path/$_") for 0..$#$fields;
    }
    return $value;
}
sub references {
    my ($value, $seen) = @_;
    $seen ||= {}; return $seen unless ref($value);
    die 'unsupported reference census' if blessed($value) || (ref($value) ne 'HASH' && ref($value) ne 'ARRAY');
    return $seen if $seen->{refaddr($value)}++;
    references($_, $seen) for ref($value) eq 'HASH' ? values(%$value) : @$value;
    return $seen;
}
open my $capture, '<:raw', 'docs/audits/reservation-coverage-snapshot-capture-20261003/ordinary.json' or die $!;
my $data = $json->decode(do {local $/; <$capture>}); close $capture or die $!;
my @copies;
for my $ordinal (0..$#{$data->{copies}}) {
    my $source = materialize($data->{copies}[$ordinal]{before});
    my $before = input_snapshot($source);
    my $copy = source_value_copy($source);
    my $src_refs = references($source); my $copy_refs = references($copy);
    my $overlap = grep {exists $src_refs->{$_}} keys %$copy_refs;
    push @copies, {ordinal => $ordinal, before => $json->decode($before),
        after => snapshot_graph($source), copy => snapshot_graph($copy),
        source_references => scalar(keys %$src_refs), copy_references => scalar(keys %$copy_refs),
        overlap => $overlap};
}
my $shared = {'kind/~' => [1, '1', 0, '0', undef]};
my $source = {left => $shared, right => $shared}; $source->{loop} = $source;
my $before = input_snapshot($source);
my $pure = source_value_copy($source);
my $stored = dclone($source);
my $src_refs = references($source);
my @plain;
for my $pair (['candidate', $pure], ['storable', $stored]) {
    my ($name, $copy) = @$pair;
    my $copy_refs = references($copy);
    my $overlap = grep {exists $src_refs->{$_}} keys %$copy_refs;
    push @plain, {name => $name, before => $json->decode($before), copy => snapshot_graph($copy),
        overlap => $overlap, source_references => scalar(keys %$src_refs), copy_references => scalar(keys %$copy_refs),
        alias_retained => refaddr($copy->{left}) == refaddr($copy->{right}) ? 1 : 0,
        cycle_retained => refaddr($copy->{loop}) == refaddr($copy) ? 1 : 0};
}
$pure->{left}{'kind/~'}[0] = 9;
my $isolation_after = snapshot_graph($source);
my $isolation_copy_after = snapshot_graph($pure);
my $alias_break = source_value_copy($source); $alias_break->{right} = source_value_copy($shared);
my $cycle_break = source_value_copy($source); $cycle_break->{loop} = {};
my $marker = bless {}, 'CoverageCauseSentinel';
my $native = {left => $marker, right => $marker};
my $native_before = input_snapshot($native);
my $native_stable = input_snapshot($native);
my $original_identity = refaddr($marker);
$native->{left} = bless {}, 'CoverageCauseSentinel';
my $replacement = input_snapshot($native);
my $replacement_identity = refaddr($native->{left});
my @refusals;
for my $case (
    ['nonempty marker', sub {snapshot_graph(bless {payload => 1}, 'CoverageCauseSentinel')}],
    ['wrong marker class', sub {snapshot_graph(bless {}, 'OtherSentinel')}],
    ['scalar native snapshot', sub {my $value = 1; snapshot_graph(\$value)}],
    ['blessed source copy', sub {source_value_copy($marker)}],
    ['scalar source copy', sub {my $value = 1; source_value_copy(\$value)}],
) {
    my $ok = eval {$case->[1]->(); 1}; my $error = $@;
    push @refusals, {name => $case->[0], accepted => $ok ? 1 : 0, error => $error};
}
open my $out, '>:raw', "$base/observations.json" or die $!;
print {$out} $json->encode({copies => \@copies, plain => \@plain,
    isolation_before => $json->decode($before), isolation_after => $isolation_after,
    isolation_copy_after => $isolation_copy_after,
    alias_break => snapshot_graph($alias_break), cycle_break => snapshot_graph($cycle_break),
    native_before => $json->decode($native_before), native_stable => $json->decode($native_stable),
    native_replacement => $json->decode($replacement), native_original_identity => $original_identity,
    native_replacement_identity => $replacement_identity, refusals => \@refusals}), "\n" or die $!;
close $out or die $!;
print "PASS native candidate copy/snapshot probes completed; independent reader must qualify results.\n";
