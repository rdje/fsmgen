use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use JSON::PP;
use Storable ();
use Scalar::Util qw(refaddr blessed);
use FSM::Scheduler::ISF;
use FSM::Scheduler::ISF::LoweringIR;
use FSM::Scheduler::ISF::FormalReservationCoverage;

my $base = 'docs/audits/reservation-coverage-copy-repair-20261003';
my ($version, $mode) = @ARGV;
die 'undeclared version/mode' unless defined($version) && $version =~ /\A(?:prior|current)\z/
    && defined($mode) && $mode =~ /\A(?:ordinary|pure|success|refusal|storable|alias)\z/
    && ($version eq 'prior' ? $mode !~ /\A(?:storable|alias)\z/ : $mode ne 'pure');
my $json = JSON::PP->new->canonical;
open my $file, '<:raw', "$base/observer-graphs.pl" or die $!;
eval do {local $/; <$file>}; die $@ if $@; close $file or die $!;
my $source_path = $version eq 'prior' ? "$base/prior-T1960.t" : 't/1960-isf-formal-reservation-coverage.t';
open $file, '<:raw', $source_path or die $!;
my @source = <$file>; close $file or die $!;
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
for my $i (0..$#source) {
    my $line = $source[$i]; chomp $line;
    $sites{$i + 1} = $patterns{$line} if exists $patterns{$line};
}
die 'prior exact copy sites missing' if $version eq 'prior' && keys(%sites) != 8;
my (@copies, @preparations, @lowerings, @coverage, @consumers, @proofs);
my $changed = 0;
my $clone = Storable->can('dclone');
my $prepare = FSM::Scheduler::ISF::LoweringIR->can('prepare_formal_source');
my $lower = FSM::Scheduler::ISF->can('lower');
my $verify = FSM::Scheduler::ISF::FormalReservationCoverage->can('verify');
my $subtest = Test::More->can('subtest');
my $compare = Test::More->can('is_deeply');
my $is = Test::More->can('is');
sub copy_row {
    my ($before, $value, $copy, $site, $label) = @_;
    my $original = reference_set($value); my $copied = reference_set($copy);
    push @copies, {before => $json->decode($before), after => graph($value), copy => graph($copy),
        site => $site, label => $label, original_reference_count => scalar(keys %$original),
        copy_reference_count => scalar(keys %$copied),
        shared_with_original => scalar(grep {exists $original->{$_}} keys %$copied)};
}
{
    no warnings 'redefine';
    local *Storable::dclone = sub ($) {
        my @caller = caller;
        return $clone->(@_) unless $caller[0] eq 'main' && exists $sites{$caller[2]};
        my $before = $json->encode(graph($_[0]));
        my $copy = $mode eq 'pure' ? pure_copy($_[0]) : $clone->(@_);
        copy_row($before, $_[0], $copy, $sites{$caller[2]}, undef);
        return $copy;
    };
    local *Test::More::subtest = sub {
        my ($name, $body, @args) = @_;
        return $subtest->(@_) if $version eq 'prior';
        my $copier = main->can('source_copy');
        my $value_copy = main->can('source_value_copy');
        return $subtest->($name, sub {
            no warnings 'redefine';
            local *main::source_value_copy = sub {
                if (!$changed && ($mode eq 'storable' || $mode eq 'alias')
                        && ref($_[0]) eq 'HASH' && ($_[0]{actor_name} // '') eq 'coverage'
                        && exists $_[0]{states} && exists $_[0]{counters}) {
                    $changed++;
                    return $mode eq 'storable' ? $clone->($_[0]) : $_[0];
                }
                return $value_copy->(@_);
            };
            local *main::source_copy = sub {
                my ($value, $label) = @_;
                my $before = $json->encode(graph($value));
                my $copy = $copier->(@_);
                my $site = $label =~ / authored actor\z/ ? 'authored_actor'
                    : $label =~ / physical actor\z/ ? 'physical_actor'
                    : $label =~ / captured module / ? 'captured_module'
                    : $label eq 'unexpected module seed' ? 'unexpected_module_seed'
                    : $label =~ / module mutation seed\z/ ? 'module_mutation_seed'
                    : $label eq 'allocation mutation seed' ? 'allocation_mutation_seed'
                    : die 'unknown current copy label';
                copy_row($before, $value, $copy, $site, $label);
                return $copy;
            };
            return $body->(@_);
        }, @args);
    };
    local *Test::More::is = sub ($$;$) {
        my ($actual, $expected, $label) = @_;
        my $passed = $is->(@_);
        if ((caller)[0] eq 'main' && $label =~ / copy (preserves|is isolated)/) {
            push @proofs, {label => $label, actual => $actual, expected => $expected, passed => $passed ? 1 : 0};
        } elsif ((caller)[0] eq 'main' && $label =~ / (?:verification is read-only|refusal preserves inputs)\z/) {
            push @consumers, {call_ordinal => $#coverage, label => $label,
                actual => $json->decode($actual), expected => $json->decode($expected), passed => $passed ? 1 : 0};
        }
        return $passed;
    };
    local *Test::More::is_deeply = sub ($$;$) {
        my ($actual, $expected, $label) = @_;
        my $passed = $compare->(@_);
        if ((caller)[0] eq 'main' && $label =~ / (?:verification is read-only|refusal preserves inputs)\z/) {
            push @consumers, {call_ordinal => $#coverage, label => $label,
                actual => graph($actual), expected => graph($expected), passed => $passed ? 1 : 0};
        }
        return $passed;
    };
    local *FSM::Scheduler::ISF::LoweringIR::prepare_formal_source = sub {
        return $prepare->(@_) unless (caller)[0] eq 'main';
        my $before = $json->encode(graph($_[1])); my $result = $prepare->(@_);
        push @preparations, {before => $json->decode($before), after => graph($_[1]), result => graph($result)};
        return $result;
    };
    local *FSM::Scheduler::ISF::lower = sub {
        my $before = $json->encode(graph($_[1])); my $result = $lower->(@_);
        push @lowerings, {before => $json->decode($before), after => graph($_[1]), result => graph($result)};
        return $result;
    };
    local *FSM::Scheduler::ISF::FormalReservationCoverage::verify = sub {
        my ($class, @inputs) = @_;
        my $before = $json->encode(graph(\@inputs));
        my ($result, $error, $mutation);
        my $ok = eval {$result = $verify->(@_); 1}; $error = $@;
        if (!$changed && (($mode eq 'success' && $ok) || ($mode eq 'refusal' && !$ok))) {
            my $slot = $inputs[0]{generated_child_products}{worker}{assignment_provenance}[0];
            die 'kind target missing' unless ref($slot) eq 'HASH' && $slot->{target} eq 'notice'
                && $slot->{source_kind} eq 'complete_pulse' && $json->encode($slot->{rhs}) eq '1';
            $slot->{rhs} = $json->decode('"1"');
            $changed++; $mutation = '/0/generated_child_products/worker/assignment_provenance/0/rhs';
        }
        push @coverage, {before => $json->decode($before), after => graph(\@inputs),
            accepted => $ok ? 1 : 0, error => $error, result => $ok ? graph($result) : undef, mutation => $mutation};
        die $error unless $ok;
        return $result;
    };
    my $ok = do "./$source_path";
    die $@ if $@; die $! unless defined $ok;
}
die 'declared mutation did not execute once' if $changed != ($mode =~ /\A(?:ordinary|pure)\z/ ? 0 : 1);
open $file, '>:raw', "$base/$version-$mode.json" or die $!;
print {$file} $json->encode({version => $version, mode => $mode, changed => $changed,
    copies => \@copies, preparations => \@preparations, lowerings => \@lowerings,
    coverage => \@coverage, consumers => \@consumers, proofs => \@proofs}), "\n" or die $!;
close $file or die $!;
