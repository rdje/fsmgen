use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use JSON::PP;
use Storable qw(dclone);
use Scalar::Util qw(refaddr blessed);
use FSM::Scheduler::ISF::FormalReservationCoverage;
use FSM::Test::DiagnosticCause;
my $json = JSON::PP->new->canonical;
my $base = 'docs/audits/reservation-coverage-cause-repair-20261003';
my $mode = $ENV{FSMGEN_COVERAGE_OBSERVER_MODE} || 'ordinary';
die 'unknown owned observer mode' unless $mode eq 'ordinary' || $mode eq 'bypass';
sub graph {
    my ($value, $seen, $path) = @_;
    return $value unless ref($value);
    $seen ||= {}; $path //= '';
    my $address = refaddr($value);
    return ['reference', $seen->{$address}] if exists $seen->{$address};
    $seen->{$address} = $path;
    die 'undeclared native graph reference' if blessed($value);
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
    die 'undeclared native graph reference';
}
my (@api, @consumers, @clones);
my $clone = Storable->can('dclone');
my $verify = FSM::Scheduler::ISF::FormalReservationCoverage->can('verify');
my $predicate = FSM::Test::DiagnosticCause->can('diagnostic_cause_matches');
my $ok_function = Test::More->can('ok');
my $pending;
if ($mode eq 'bypass') {
    open my $source, '<:raw', 'perl/FSM/Scheduler/ISF/FormalReservationCoverage.pm' or die $!;
    my $body = do {local $/; <$source>}; close $source or die $!;
    my $start = index($body, 'sub _verify_scope {');
    my $end = index($body, 'sub _declarations {', $start);
    die 'exact declaration guard missing' unless $start >= 0 && $end > $start;
    my $scope = substr($body, $start, $end - $start);
    my $changed = $scope =~ s/if \@missing;/if 0;/g;
    die 'ambiguous declaration guard' unless $changed == 1;
    open my $saved, '>:raw', "$base/bypass-body.pl" or die $!;
    print {$saved} $scope or die $!; close $saved or die $!;
    # Replace only the missing-declaration conditional before native calls;
    # private ownership, schema, module membership and all adjacent guards remain.
    {no warnings 'redefine'; eval 'package FSM::Scheduler::ISF::FormalReservationCoverage;' . $scope; die $@ if $@}
}
{
    no warnings 'redefine';
    local *Storable::dclone = sub ($) {
        return $clone->(@_) unless (caller)[0] eq 'main';
        my $before = $json->encode(graph($_[0]));
        my $copy = $clone->(@_);
        push @clones, {line => (caller)[2], before => $json->decode($before),
            after => graph($_[0]), clone => graph($copy)};
        return $copy;
    };
    local *FSM::Scheduler::ISF::FormalReservationCoverage::verify = sub {
        my ($class, @inputs) = @_;
        my $before = $json->encode(graph(\@inputs));
        my ($result, $error);
        my $ok = eval {$result = $verify->(@_); 1}; $error = $@;
        push @api, {before => $json->decode($before), after => graph(\@inputs),
            accepted => $ok ? 1 : 0, error => $error,
            result => $ok ? graph($result) : undef};
        die $error unless $ok;
        return $result;
    };
    local *FSM::Test::DiagnosticCause::diagnostic_cause_matches = sub {
        my ($error, $expected) = @_;
        die 'unassociated real coverage consumer' unless @api;
        my $matched = $predicate->(@_);
        $pending = {api_index => $#api, expected_cause => $expected, error => $error,
            matched => $matched ? 1 : 0};
        return $matched;
    };
    local *Test::More::ok = sub ($;$) {
        my ($decision, $label) = @_;
        if (defined($label) && $label =~ / diagnosed$/) {
            die 'unassociated complete-cause decision' unless $pending;
            push @consumers, {%$pending, label => $label}; $pending = undef;
        }
        return $ok_function->(@_);
    };
    my $ok = do './t/1960-isf-formal-reservation-coverage.t';
    die $@ if $@; die $! unless defined $ok;
}
open my $out, '>:raw', "$base/$mode.json" or die $!;
print {$out} $json->encode({api => \@api, consumers => \@consumers, clones => \@clones}), "\n" or die $!;
close $out or die $!;
