use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use JSON::PP;
use Storable qw(dclone);
use Scalar::Util qw(refaddr blessed reftype);
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF::LoweringIR;
use FSM::Scheduler::ISF::PreparedFormalReservations;
use FSM::Scheduler::ISF::FormalReservationInventory;
use FSM::Scheduler::ISF::FormalIdentityPlan;

my $json = JSON::PP->new->canonical;
my $base = 'docs/audits/prepared-reservation-snapshot-diagnosis-20261003';
my $mode = $ENV{FSMGEN_PREPARED_SNAPSHOT_MODE} // 'ordinary';
die 'unknown observer mode' unless $mode eq 'ordinary' || $mode eq 'mutate';
# Deterministic node tags separate user keys from reference metadata; all repeated
# references, including cycles, point to their first traversal path. Scalars are
# returned untouched. This observer never invokes overload or native referents.
sub native_graph {
    my ($value, $seen, $path) = @_;
    $seen ||= {}; $path //= '';
    return $value unless ref($value);
    my $address = refaddr($value);
    return ['reference', $seen->{$address}] if exists $seen->{$address};
    $seen->{$address} = $path;
    die 'undeclared blessed input' if blessed($value);
    if (ref($value) eq 'HASH') {
        my %out;
        for my $key (sort keys %$value) {
            my $escaped = $key; $escaped =~ s/~/~0/g; $escaped =~ s{/}{~1}g;
            $out{$key} = native_graph($value->{$key}, $seen, "$path/$escaped");
        }
        return ['hash', \%out];
    }
    return ['array', [map {native_graph($value->[$_], $seen, "$path/$_")} 0..$#$value]]
        if ref($value) eq 'ARRAY';
    die 'undeclared native input';
}
my (@clones, @calls);
my $clone = Storable->can('dclone');
my $collect = FSM::Scheduler::ISF::PreparedFormalReservations->can('collect');
{
    no warnings 'redefine';
    local *Storable::dclone = sub ($) {
        return $clone->(@_) unless (caller)[0] eq 'main';
        my $before = $json->encode(native_graph($_[0]));
        my $copy = $clone->(@_);
        push @clones, {line => (caller)[2], before => $json->decode($before),
            after => native_graph($_[0]), clone => native_graph($copy)};
        return $copy;
    };
    local *FSM::Scheduler::ISF::PreparedFormalReservations::collect = sub {
        my ($class, $input) = @_;
        my $before = $json->encode(native_graph($input));
        my ($result, $error);
        my $ok = eval {$result = $collect->(@_); 1}; $error = $@;
        my $mutation;
        if ($mode eq 'mutate' && ref($input->{actor}) eq 'HASH'
                && ($input->{actor}{actor_name} // '') eq 'scoped_reservations') {
            my $slot = $input->{generated_child_products}{worker}{assignment_provenance}[0];
            die 'missing declared mutation target' unless ref($slot) eq 'HASH';
            my $value = $slot->{rhs};
            my $text = $json->encode($value);
            die 'unexpected mutation value' unless $text eq '1' || $text eq '"1"';
            $slot->{rhs} = $json->decode($text eq '1' ? '"1"' : '1');
            $mutation = '/generated_child_products/worker/assignment_provenance/0/rhs';
        }
        push @calls, {before => $json->decode($before), after => native_graph($input),
            accepted => $ok ? 1 : 0, error => $error,
            result => $ok ? native_graph($result) : undef, mutation => $mutation};
        die $error unless $ok;
        return $result;
    };
    my $ok = do './t/1959-isf-prepared-formal-reservations.t';
    die $@ if $@; die $! unless defined $ok;
}
open my $out, '>:raw', "$base/observations-$mode.json" or die $!;
print {$out} $json->encode({clones => \@clones, calls => \@calls}), "\n" or die $!;
close $out or die $!;
