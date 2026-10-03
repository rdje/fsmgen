use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use JSON::PP;
use Scalar::Util qw(refaddr blessed);
use FSM::Scheduler::ISF;
use FSM::Scheduler::ISF::LoweringIR;
use FSM::Scheduler::ISF::FormalReservationCoverage;

my $base = 'docs/audits/reservation-coverage-value-only-controls-20261003';
my $mode = $ENV{FSMGEN_COVERAGE_VALUE_ONLY_MODE} // 'ordinary';
die 'unknown caller-kind mode' unless $mode =~ /\A(?:ordinary|success|refusal)\z/;
my $json = JSON::PP->new->canonical;
sub graph {
    my ($value, $seen, $path) = @_;
    return $value unless ref($value);
    $seen ||= {}; $path //= '';
    die 'undeclared native reference' if blessed($value);
    my $address = refaddr($value);
    return ['reference', $seen->{$address}] if exists $seen->{$address};
    $seen->{$address} = $path;
    if (ref($value) eq 'HASH') {
        my %out;
        for my $key (sort keys %$value) {
            my $escaped = $key; $escaped =~ s/~/~0/g; $escaped =~ s{/}{~1}g;
            $out{$key} = graph($value->{$key}, $seen, "$path/$escaped");
        }
        return ['hash', \%out];
    }
    return ['array', [map {graph($value->[$_], $seen, "$path/$_")} 0..$#$value]]
        if ref($value) eq 'ARRAY';
    die 'undeclared native reference';
}
my (@calls, @consumers, @lowerings);
my $changed = 0;
my $verify = FSM::Scheduler::ISF::FormalReservationCoverage->can('verify');
my $compare = Test::More->can('is_deeply');
my $lower = FSM::Scheduler::ISF->can('lower');
{
    no warnings 'redefine';
    local *FSM::Scheduler::ISF::FormalReservationCoverage::verify = sub {
        my ($class, @input) = @_;
        my $before = $json->encode(graph(\@input));
        my ($result, $error);
        my $ok = eval {$result = $verify->(@_); 1}; $error = $@;
        my $mutation;
        if (!$changed && (($mode eq 'success' && $ok) || ($mode eq 'refusal' && !$ok))) {
            my $slot = $input[0]{generated_child_products}{worker}{assignment_provenance}[0];
            die 'declared caller-kind target missing' unless ref($slot) eq 'HASH'
                && $slot->{target} eq 'notice' && $slot->{source_kind} eq 'complete_pulse';
            my $original = $slot->{rhs};
            die 'declared caller-kind target not numeric1' unless $json->encode($original) eq '1';
            $slot->{rhs} = $json->decode('"1"');
            $changed = 1;
            $mutation = '/1/0/1/generated_child_products/1/worker/1/assignment_provenance/1/0/1/rhs';
        }
        push @calls, {before => $json->decode($before), after => graph(\@input),
            accepted => $ok ? 1 : 0, error => $error,
            result => $ok ? graph($result) : undef, mutation => $mutation};
        die $error unless $ok;
        return $result;
    };
    local *Test::More::is_deeply = sub ($$;$) {
        my ($actual, $expected, $label) = @_;
        return $compare->(@_) unless (caller)[0] eq 'main'
            && $label =~ / (?:verification is read-only|refusal preserves inputs)\z/;
        die 'actual snapshot consumer has no native call' unless @calls;
        my $actual_graph = graph($actual);
        my $expected_graph = graph($expected);
        my $passed = $compare->(@_);
        push @consumers, {call_ordinal => $#calls, label => $label,
            actual => $actual_graph, expected => $expected_graph, passed => $passed ? 1 : 0};
        return $passed;
    };
    local *FSM::Scheduler::ISF::lower = sub {
        my ($self, $actor) = @_;
        my $before = $json->encode(graph($actor));
        my $result = $lower->(@_);
        push @lowerings, {before => $json->decode($before), after => graph($actor), result => graph($result)};
        return $result;
    };
    my $ok = do './t/1960-isf-formal-reservation-coverage.t';
    die $@ if $@; die $! unless defined $ok;
}
die 'declared caller-kind mutation did not execute' if ($mode ne 'ordinary') != $changed;
open my $out, '>:raw', "$base/$mode.json" or die $!;
print {$out} $json->encode({mode => $mode, calls => \@calls, consumers => \@consumers,
    lowerings => \@lowerings, changed => $changed}), "\n" or die $!;
close $out or die $!;
