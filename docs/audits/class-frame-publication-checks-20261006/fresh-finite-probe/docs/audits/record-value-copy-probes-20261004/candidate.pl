use strict;
use warnings;
use JSON::PP;
use Scalar::Util qw(refaddr blessed reftype);
use Test::More;

sub source_value_copy {
    my ($value, $copies) = @_;
    return $value unless ref($value);
    die 'unexpected source reference' if blessed($value)
        || (ref($value) ne 'HASH' && ref($value) ne 'ARRAY');
    $copies ||= {};
    my $address = refaddr($value);
    return $copies->{$address} if exists $copies->{$address};
    my $copy = ref($value) eq 'HASH' ? {} : [];
    $copies->{$address} = $copy;
    if (ref($value) eq 'HASH') {
        $copy->{$_} = source_value_copy($value->{$_}, $copies) for keys %$value;
    } else {
        push @$copy, source_value_copy($_, $copies) for @$value;
    }
    return $copy;
}

sub snapshot_graph {
    my ($value, $seen, $path) = @_;
    return $value unless ref($value);
    $seen ||= {}; $path //= '';
    my $address = refaddr($value);
    return ['reference', $seen->{$address}] if exists $seen->{$address};
    $seen->{$address} = $path;
    die 'unexpected native snapshot reference' if blessed($value);
    if (ref($value) eq 'HASH') {
        my %copy;
        for my $key (sort keys %$value) {
            my $escaped = $key; $escaped =~ s/~/~0/g; $escaped =~ s{/}{~1}g;
            $copy{$key} = snapshot_graph($value->{$key}, $seen, "$path/$escaped");
        }
        return ['hash', \%copy];
    }
    return ['array', [map {snapshot_graph($value->[$_], $seen, "$path/$_")} 0..$#$value]]
        if ref($value) eq 'ARRAY';
    die 'unexpected snapshot reference';
}

sub input_snapshot {JSON::PP->new->canonical->encode(snapshot_graph($_[0]))}

sub source_references {
    my @pending = ($_[0]);
    my %seen;
    while (@pending) {
        my $value = pop @pending;
        next unless ref($value);
        die 'unexpected source reference' if blessed($value)
            || (ref($value) ne 'HASH' && ref($value) ne 'ARRAY');
        my $address = refaddr($value);
        next if exists $seen{$address};
        $seen{$address} = 1;
        push @pending, ref($value) eq 'HASH' ? values(%$value) : @$value;
    }
    return \%seen;
}

sub source_copy {
    my ($value, $label) = @_;
    my $before = input_snapshot($value);
    my $original = source_references($value);
    my $copy = source_value_copy($value);
    my $copied = source_references($copy);
    my $shared = grep {exists $original->{$_}} keys %$copied;
    is(input_snapshot($value), $before, "$label copy preserves original kinds and sharing");
    is(input_snapshot($copy), $before, "$label copy preserves kinds and sharing");
    is(scalar(keys %$copied), scalar(keys %$original), "$label copy preserves reference population");
    is($shared, 0, "$label copy is isolated from source");
    return $copy;
}

1;
