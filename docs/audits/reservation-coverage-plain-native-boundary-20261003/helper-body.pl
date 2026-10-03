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
    if (blessed($value)) {
        # The cause controls use this empty native HASH. Other unsupported
        # referents have no declared snapshot contract and fail closed.
        die 'unexpected native snapshot reference' unless ref($value) eq 'CoverageCauseSentinel'
            && reftype($value) eq 'HASH' && !keys %$value;
        return ['empty_native_hash', ref($value), $address];
    }
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
