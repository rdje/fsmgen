use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use JSON::PP;
use Scalar::Util qw(refaddr blessed reftype);
use FSM::Scheduler::ISF::FormalReservationCoverage;
use FSM::Test::DiagnosticCause;

my $json = JSON::PP->new->canonical;
open my $file, '<:raw', 'docs/audits/reservation-coverage-cause-diagnosis-20261003/observations-unqualified.json' or die $!;
my $fixtures = $json->decode(do {local $/; <$file>}); close $file or die $!;

sub pointer_key {
    my ($key) = @_;
    $key =~ s/~/~0/g; $key =~ s{/}{~1}g;
    return $key;
}
sub materialize {
    my ($node, $memo, $path) = @_;
    return $node unless ref($node);
    $memo ||= {}; $path //= '';
    die 'unknown descriptor' unless ref($node) eq 'ARRAY' && @$node == 2;
    my ($kind, $body) = @$node;
    if ($kind eq 'reference') {
        die 'reference precedes identity' unless exists $memo->{$body};
        return $memo->{$body};
    }
    my $value;
    if ($kind eq 'blessed') {
        die 'unknown native marker' unless $body eq 'CoverageCauseSentinel';
        $value = bless {}, 'CoverageCauseSentinel';
    } elsif ($kind eq 'hash') {
        die 'unknown hash body' unless ref($body) eq 'HASH';
        $value = {};
    } elsif ($kind eq 'array') {
        die 'unknown array body' unless ref($body) eq 'ARRAY';
        $value = [];
    } else {die 'unknown descriptor tag'}
    $memo->{$path} = $value;
    if ($kind eq 'hash') {
        for my $key (sort keys %$body) {
            $value->{$key} = materialize($body->{$key}, $memo, "$path/" . pointer_key($key));
        }
    } elsif ($kind eq 'array') {
        push @$value, materialize($body->[$_], $memo, "$path/$_") for 0..$#$body;
    }
    return $value;
}
sub snapshot {
    my ($value, $memo, $path) = @_;
    return $value unless ref($value);
    $memo ||= {}; $path //= '';
    my $identity = refaddr($value);
    return ['reference', $memo->{$identity}] if exists $memo->{$identity};
    $memo->{$identity} = $path;
    if (blessed($value)) {
        die 'native marker changed' unless blessed($value) eq 'CoverageCauseSentinel'
            && reftype($value) eq 'HASH' && !keys %$value;
        return ['blessed', 'CoverageCauseSentinel'];
    }
    if (ref($value) eq 'ARRAY') {
        return ['array', [map {snapshot($value->[$_], $memo, "$path/$_")} 0..$#$value]];
    }
    die 'unknown native reference' unless ref($value) eq 'HASH';
    return ['hash', {map {$_ => snapshot($value->{$_}, $memo,
        "$path/" . pointer_key($_))} sort keys %$value}];
}
sub marker_identity {
    my ($input, $row) = @_;
    return undef if $row->{band} eq 'current_fixture';
    my $marker = $input->[0]{_early_reference};
    if ($row->{band} eq 'primary_path_echo') {
        $marker = $marker->{$_} for split m{/}, $row->{expected_cause}, -1;
    }
    die 'native marker shape changed' unless blessed($marker) eq 'CoverageCauseSentinel'
        && reftype($marker) eq 'HASH' && !keys %$marker;
    return refaddr($marker);
}

open $file, '<:raw', 't/1960-isf-formal-reservation-coverage.t' or die $!;
my $source = do {local $/; <$file>}; close $file or die $!;
my $start = index($source, 'sub reject {');
my $end = index($source, "subtest 'missing declarations", $start);
die 'exact current coverage helper missing' unless $start >= 0 && $end > $start;
my $helper = substr($source, $start, $end - $start);
my $graph_start = index($source, 'sub source_value_copy {');
my $graph_end = index($source, 'my $scheduler =', $graph_start);
die 'exact current coverage snapshot helpers missing' unless $graph_start >= 0 && $graph_end > $graph_start;
my $graph_helpers = substr($source, $graph_start, $graph_end - $graph_start);
{
    package CurrentCoverageCauseSubject;
    use JSON::PP;
    use Scalar::Util qw(refaddr blessed reftype);
    our (@bits, @errors, $api_error, $api_accepted, $api_result);
    sub verify {
        my $ok = eval {
            $api_result = FSM::Scheduler::ISF::FormalReservationCoverage->verify(@_);
            1;
        };
        $api_error = $@; $api_accepted = $ok ? 1 : 0;
        die $api_error unless $ok;
        return $api_result;
    }
    sub ok {push @bits, $_[0] ? 1 : 0; return $_[0]}
    sub diag {}
    sub is {
        my $same = Test::More::is($_[0], $_[1], $_[2]);
        push @bits, $same ? 1 : 0;
        return $same;
    }
    sub diagnostic_cause_matches {
        push @errors, $_[0];
        return FSM::Test::DiagnosticCause::diagnostic_cause_matches(@_);
    }
}
# Compile before native calls; no active source eval can echo a reason.
eval 'package CurrentCoverageCauseSubject;' . $graph_helpers . $helper; die $@ if $@;
my @captures;
for my $row (@{$fixtures->{rows}}) {
    my $input = materialize($row->{before});
    my $before = snapshot($input);
    my $identity = marker_identity($input, $row);
    @CurrentCoverageCauseSubject::bits = (); @CurrentCoverageCauseSubject::errors = ();
    $CurrentCoverageCauseSubject::api_result = undef;
    CurrentCoverageCauseSubject::reject(@$input, $row->{expected_cause}, "$row->{label} / $row->{band}");
    is_deeply(\@CurrentCoverageCauseSubject::bits, [1, $row->{band} eq 'current_fixture' ? 1 : 0, 1],
        "$row->{label} / $row->{band}: exact helper accepts only the complete intended cause");
    is((split /\n/, $CurrentCoverageCauseSubject::api_error)[0], (split /\n/, $row->{error})[0],
        "$row->{label} / $row->{band}: actual primary conserved");
    is($CurrentCoverageCauseSubject::errors[0], $CurrentCoverageCauseSubject::api_error,
        "$row->{label} / $row->{band}: native error saved immediately");
    my $after = snapshot($input);
    is($json->encode($after), $json->encode($before),
        "$row->{label} / $row->{band}: complete caller primitive kinds/sharing retained");
    is(marker_identity($input, $row), $identity, "$row->{label} / $row->{band}: empty native marker identity retained");
    push @captures, {label => $row->{label}, band => $row->{band}, expected_cause => $row->{expected_cause},
        before => $before, after => $after, error => $CurrentCoverageCauseSubject::api_error,
        incoming_error => $CurrentCoverageCauseSubject::errors[0], assertions => [@CurrentCoverageCauseSubject::bits],
        accepted => $CurrentCoverageCauseSubject::api_accepted,
        result => $CurrentCoverageCauseSubject::api_accepted ? snapshot($CurrentCoverageCauseSubject::api_result) : undef};
}
if (defined $ENV{FSMGEN_COVERAGE_CAUSE_CAPTURE}) {
    open $file, '>:raw', $ENV{FSMGEN_COVERAGE_CAUSE_CAPTURE} or die $!;
    print {$file} $json->encode({rows => \@captures}), "\n" or die $!; close $file or die $!;
}
done_testing;
