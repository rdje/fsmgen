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

