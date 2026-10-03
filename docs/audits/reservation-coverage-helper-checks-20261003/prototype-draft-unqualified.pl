use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use JSON::PP;
use Scalar::Util qw(refaddr blessed);
use FSM::Scheduler::ISF::FormalReservationCoverage;
my $json = JSON::PP->new->canonical;
my $base = 'docs/audits/reservation-coverage-helper-causes-20261003';
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
my (@api, @consumers);
my $verify = FSM::Scheduler::ISF::FormalReservationCoverage->can('verify');
my $like = Test::More->can('like');
{
    no warnings 'redefine';
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
    local *Test::More::like = sub {
        my ($error, $pattern, $label) = @_;
        die 'unassociated real refusal consumer' unless @api && !$api[-1]{accepted};
        push @consumers, {api_index => $#api, label => $label,
            pattern => "$pattern", error => $error};
        return $like->(@_);
    };
    my $ok = do './t/1960-isf-formal-reservation-coverage.t';
    die $@ if $@; die $! unless defined $ok;
}
open my $out, '>:raw', "$base/initial-observations-unqualified.json" or die $!;
print {$out} $json->encode({api => \@api, consumers => \@consumers}), "\n" or die $!;
close $out or die $!;
