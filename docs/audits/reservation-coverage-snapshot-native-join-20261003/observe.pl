use strict;
use warnings;
use lib 'perl', 't/lib';
use JSON::PP;
use Scalar::Util qw(refaddr blessed reftype);
use FSM::Scheduler::ISF::FormalReservationCoverage;

my $base = 'docs/audits/reservation-coverage-snapshot-native-join-20261003';
my $mode = $ENV{FSMGEN_NATIVE_JOIN_MODE} || 'ordinary';
die 'unknown owned native mode' unless $mode eq 'ordinary' || $mode eq 'replacement';
my $json = JSON::PP->new->canonical;
open my $file, '<:raw', 'docs/audits/reservation-coverage-plain-native-boundary-20261003/helper-body.pl' or die $!;
my $helpers = do {local $/; <$file>}; close $file or die $!;
eval $helpers; die $@ if $@;
my $verify = FSM::Scheduler::ISF::FormalReservationCoverage->can('verify');
my (@calls, $changed);
{
    no warnings 'redefine';
    local *FSM::Scheduler::ISF::FormalReservationCoverage::verify = sub {
        my ($class, @inputs) = @_;
        my $before = input_snapshot(\@inputs);
        my ($result, $error, $mutation);
        my $ok = eval {$result = $verify->(@_); 1}; $error = $@;
        # Keep a strong reference to the actual old marker until after the new
        # marker is observed. Its identity cannot be recycled during the control.
        my $marker = $inputs[0]{_early_reference};
        if ($mode eq 'replacement' && !$changed && !$ok && blessed($marker)
                && blessed($marker) eq 'CoverageCauseSentinel') {
            die 'unexpected owned marker shape' unless reftype($marker) eq 'HASH' && !keys %$marker;
            my $old_identity = refaddr($marker);
            $inputs[0]{_early_reference} = bless {}, 'CoverageCauseSentinel';
            $mutation = {path => '/0/_early_reference', before_identity => $old_identity,
                after_identity => refaddr($inputs[0]{_early_reference})};
            $changed++;
        }
        push @calls, {ordinal => scalar(@calls), before => $json->decode($before),
            after => snapshot_graph(\@inputs), accepted => $ok ? 1 : 0,
            result => $ok ? snapshot_graph($result) : undef, error => $error, mutation => $mutation};
        die $error unless $ok;
        return $result;
    };
    local $ENV{FSMGEN_COVERAGE_CAUSE_CAPTURE} = "$base/$mode-test.json";
    my $ok = do './t/2063-isf-coverage-diagnostic-causes.t';
    die $@ if $@; die $! unless defined $ok;
}
open $file, '>:raw', "$base/$mode-observer.json" or die $!;
print {$file} $json->encode({mode => $mode, changed => $changed || 0, calls => \@calls}), "\n" or die $!;
close $file or die $!;
