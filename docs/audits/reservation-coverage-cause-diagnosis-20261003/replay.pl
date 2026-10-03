use strict;
use warnings;
use lib 'perl';
use JSON::PP;
use Scalar::Util qw(refaddr blessed reftype);
use FSM::Scheduler::ISF::FormalReservationCoverage;
use Test::More;

my $base = 'docs/audits/reservation-coverage-cause-diagnosis-20261003';
my $json = JSON::PP->new->canonical;
open my $file, '<:raw', "$base/observations-unqualified.json" or die $!;
my $data = $json->decode(do {local $/; <$file>}); close $file or die $!;
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
    my ($tag, $body) = @$node;
    if ($tag eq 'reference') {
        die 'reference precedes identity' unless exists $memo->{$body};
        return $memo->{$body};
    }
    my $value;
    if ($tag eq 'blessed') {
        die 'unknown native marker' unless $body eq 'CoverageCauseSentinel';
        $value = bless {}, 'CoverageCauseSentinel';
    } elsif ($tag eq 'hash') {
        die 'unknown hash body' unless ref($body) eq 'HASH';
        $value = {};
    } elsif ($tag eq 'array') {
        die 'unknown array body' unless ref($body) eq 'ARRAY';
        $value = [];
    } else {die 'unknown descriptor tag'}
    $memo->{$path} = $value;
    if ($tag eq 'hash') {
        for my $key (sort keys %$body) {
            $value->{$key} = materialize($body->{$key}, $memo, "$path/" . pointer_key($key));
        }
    } elsif ($tag eq 'array') {
        for my $index (0..$#$body) {
            push @$value, materialize($body->[$index], $memo, "$path/$index");
        }
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
        my @items;
        push @items, snapshot($value->[$_], $memo, "$path/$_") for 0..$#$value;
        return ['array', \@items];
    }
    die 'unknown native reference' unless ref($value) eq 'HASH';
    my %members;
    for my $key (sort keys %$value) {
        $members{$key} = snapshot($value->{$key}, $memo, "$path/" . pointer_key($key));
    }
    return ['hash', \%members];
}
{
    package RealCoverageConsumer;
    use Test::More;
    use Storable qw(dclone);
}
# Source-declared exact QRs; helper is compiled but never called in this replay.
eval $data->{qr_program}; die $@ if $@;
my %patterns = map {@$_} RealCoverageConsumer::patterns();
my @rows;
for my $row (@{$data->{rows}}) {
    my $input = materialize($row->{before});
    my $before = snapshot($input);
    is($json->encode($before), $json->encode($row->{before}),
        "$row->{label} / $row->{band}: independent input materialization retains kinds/sharing");
    my ($result, $error);
    my $ok = eval { $result = FSM::Scheduler::ISF::FormalReservationCoverage->verify(@$input); 1 };
    $error = $@;
    is($ok ? 1 : 0, 0, "$row->{label} / $row->{band}: direct native API refuses");
    my $primary = (split /\n/, $error)[0];
    is($primary, (split /\n/, $row->{error})[0], "$row->{label} / $row->{band}: actual primary conserved");
    my $pattern = $patterns{$row->{label}} // die 'unknown original QR';
    die 'original QR flags drifted' unless "$pattern" eq $row->{pattern};
    my $saved_match = $row->{error} =~ $pattern ? 1 : 0;
    my $direct_match = $error =~ $pattern ? 1 : 0;
    is($saved_match, 1, "$row->{label} / $row->{band}: saved helper exception matches exact QR");
    is($direct_match, $row->{band} eq 'earlier_reference' ? 0 : 1,
        "$row->{label} / $row->{band}: native direct stack isolates path and helper echoes");
    my $after = snapshot($input);
    is($json->encode($after), $json->encode($before),
        "$row->{label} / $row->{band}: direct native input values/kinds/sharing conserved");
    push @rows, {label => $row->{label}, band => $row->{band}, before => $before, after => $after,
        accepted => $ok ? 1 : 0, result => $ok ? snapshot($result) : undef, error => $error,
        saved_match => $saved_match, direct_match => $direct_match};
}
open $file, '>:raw', "$base/direct-replay-unqualified.json" or die $!;
print {$file} $json->encode(\@rows), "\n" or die $!; close $file or die $!;
done_testing;
