use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use JSON::PP;
use Storable qw(dclone);
use Scalar::Util qw(refaddr blessed);
use FSM::Scheduler::ISF;
use FSM::Scheduler::ISF::LoweringIR;
use FSM::Scheduler::ISF::FormalReservationCoverage;

my $base = 'docs/audits/reservation-coverage-snapshot-capture-20261003';
my $mode = $ENV{FSMGEN_COVERAGE_SNAPSHOT_MODE} // 'ordinary';
die 'undeclared snapshot-copy mode' unless $mode eq 'ordinary' || $mode eq 'pure';
my $json = JSON::PP->new->canonical;

# Scalars are returned without arithmetic/string inspection. Plain repeated
# references are retained by their first JSON-pointer coordinate.
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

sub pure_copy {
    my ($value, $copies) = @_;
    return $value unless ref($value);
    die 'undeclared copy reference' if blessed($value)
        || (ref($value) ne 'HASH' && ref($value) ne 'ARRAY');
    $copies ||= {};
    my $address = refaddr($value);
    return $copies->{$address} if exists $copies->{$address};
    my $copy = ref($value) eq 'HASH' ? {} : [];
    $copies->{$address} = $copy;
    if (ref($value) eq 'HASH') {
        $copy->{$_} = pure_copy($value->{$_}, $copies) for keys %$value;
    } else {
        push @$copy, pure_copy($_, $copies) for @$value;
    }
    return $copy;
}

sub reference_set {
    my ($value, $seen) = @_;
    $seen ||= {};
    return $seen unless ref($value);
    die 'undeclared isolation reference' if blessed($value)
        || (ref($value) ne 'HASH' && ref($value) ne 'ARRAY');
    return $seen if $seen->{refaddr($value)}++;
    reference_set($_, $seen) for ref($value) eq 'HASH' ? values(%$value) : @$value;
    return $seen;
}

open my $source, '<:raw', 't/1960-isf-formal-reservation-coverage.t' or die $!;
my @lines = <$source>; close $source or die $!;
my %patterns = (
    q!    my $actor = ref($source) eq 'HASH' ? dclone($source)! => 'authored_actor',
    q!    my $physical = dclone($p->{actor});! => 'physical_actor',
    q!            $modules{$ir->{actor_name}} = dclone($ir);! => 'captured_module',
    q!    my $before = dclone([$p, $plan, \%modules]);! => 'success_snapshot',
    q!    my $before = dclone([$p, $allocation, $actual]);! => 'refusal_snapshot',
    q!        [sub {$_[0]{extra} = dclone($_[0]{coverage})},! => 'unexpected_module_seed',
    q!        my $actual = dclone($modules); $case->[0]->($actual);! => 'module_mutation_seed',
    q!    my $bad_plan = dclone($plan); $bad_plan->{formals}{main}{payload}{physical_name} = 'isf_port_main_payload';! => 'allocation_mutation_seed',
);
my %sites;
for my $index (0..$#lines) {
    my $line = $lines[$index]; chomp $line;
    $sites{$index + 1} = $patterns{$line} if exists $patterns{$line};
}
die 'exact copy-site membership missing' unless keys(%sites) == keys(%patterns);
my %selected = map {$_ => 1} qw(success_snapshot refusal_snapshot unexpected_module_seed
    module_mutation_seed allocation_mutation_seed);
my (@copies, @preparations, @lowerings, @coverage);
my $clone = Storable->can('dclone');
my $prepare = FSM::Scheduler::ISF::LoweringIR->can('prepare_formal_source');
my $lower = FSM::Scheduler::ISF->can('lower');
my $verify = FSM::Scheduler::ISF::FormalReservationCoverage->can('verify');
{
    no warnings 'redefine';
    local *Storable::dclone = sub ($) {
        my @caller = caller;
        return $clone->(@_) unless $caller[0] eq 'main' && exists $sites{$caller[2]};
        my $before = $json->encode(graph($_[0]));
        my $copy = $mode eq 'pure' && $selected{$sites{$caller[2]}} ? pure_copy($_[0]) : $clone->(@_);
        my $original_refs = reference_set($_[0]);
        my $copy_refs = reference_set($copy);
        my $overlap = grep {exists $original_refs->{$_}} keys %$copy_refs;
        push @copies, {site => $sites{$caller[2]}, line => $caller[2],
            before => $json->decode($before), after => graph($_[0]), copy => graph($copy),
            original_reference_count => scalar(keys %$original_refs),
            copy_reference_count => scalar(keys %$copy_refs),
            shared_with_original => $overlap};
        return $copy;
    };
    local *FSM::Scheduler::ISF::LoweringIR::prepare_formal_source = sub {
        return $prepare->(@_) unless (caller)[0] eq 'main';
        my ($self, $actor) = @_;
        my $before = $json->encode(graph($actor));
        my $result = $prepare->(@_);
        push @preparations, {before => $json->decode($before), after => graph($actor), result => graph($result)};
        return $result;
    };
    local *FSM::Scheduler::ISF::lower = sub {
        my ($self, $actor) = @_;
        my $before = $json->encode(graph($actor));
        my $result = $lower->(@_);
        push @lowerings, {before => $json->decode($before), after => graph($actor), result => graph($result)};
        return $result;
    };
    local *FSM::Scheduler::ISF::FormalReservationCoverage::verify = sub {
        my ($class, @inputs) = @_;
        my $before = $json->encode(graph(\@inputs));
        my ($result, $error);
        my $ok = eval {$result = $verify->(@_); 1}; $error = $@;
        push @coverage, {before => $json->decode($before), after => graph(\@inputs),
            accepted => $ok ? 1 : 0, error => $error, result => $ok ? graph($result) : undef};
        die $error unless $ok;
        return $result;
    };
    my $ok = do './t/1960-isf-formal-reservation-coverage.t';
    die $@ if $@; die $! unless defined $ok;
}
open my $out, '>:raw', "$base/$mode.json" or die $!;
print {$out} $json->encode({mode => $mode, sites => \%sites, copies => \@copies,
    preparations => \@preparations, lowerings => \@lowerings, coverage => \@coverage}), "\n" or die $!;
close $out or die $!;
