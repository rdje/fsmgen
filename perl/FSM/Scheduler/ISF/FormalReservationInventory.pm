package FSM::Scheduler::ISF::FormalReservationInventory;

use strict;
use warnings;
use Carp qw(confess);
use Scalar::Util qw(refaddr);

# Conservative tokens from actual lowering products, including formatted
# expressions. This is neither an operand parser nor a completeness proof:
# callers must inventory every producer in the eventual physical namespace.
sub collect {
    my ($class, $products) = @_;
    confess "Formal reservation inventory requires a product hash\n"
        unless ref($products) eq 'HASH';
    my (%origins, %active);
    _walk($products, '', \%origins, \%active);
    return {
        reserved_names => {map {$_ => 1} keys %origins},
        origins => \%origins,
    };
}

sub _tokens {
    my ($value, $path, $position, $origins) = @_;
    return unless defined $value;
    my %seen;
    while ($value =~ /([A-Za-z_][A-Za-z0-9_]*)/g) {
        my $name = $1;
        next if $seen{$name}++;
        push @{$origins->{$name}}, {path => $path, position => $position};
    }
}

sub _walk {
    my ($value, $path, $origins, $active) = @_;
    if (!ref($value)) {
        _tokens($value, $path, 'value', $origins);
        return;
    }
    my $kind = ref($value);
    confess "Formal reservation inventory has unsupported reference at '$path'\n"
        unless $kind eq 'HASH' || $kind eq 'ARRAY';
    my $address = refaddr($value);
    confess "Formal reservation inventory has a cycle at '$path'\n" if $active->{$address};
    local $active->{$address} = 1;
    if ($kind eq 'HASH') {
        for my $key (sort keys %$value) {
            my $escaped = $key;
            $escaped =~ s/~/~0/g;
            $escaped =~ s{/}{~1}g;
            my $child = "$path/$escaped";
            _tokens($key, $child, 'key', $origins);
            _walk($value->{$key}, $child, $origins, $active);
        }
    } else {
        _walk($value->[$_], "$path/$_", $origins, $active) for 0 .. $#$value;
    }
}

1;
