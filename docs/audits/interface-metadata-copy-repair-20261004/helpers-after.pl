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
    die 'unqualified native graph reference' if blessed($value);
    $seen ||= {}; $path //= '';
    my $address = refaddr($value);
    return ['reference', $seen->{$address}] if exists $seen->{$address};
    $seen->{$address} = $path;
    if (ref($value) eq 'HASH') {
        my %out;
        for my $key (sort keys %$value) {
            my $escaped = $key; $escaped =~ s/~/~0/g; $escaped =~ s{/}{~1}g;
            $out{$key} = snapshot_graph($value->{$key}, $seen, "$path/$escaped");
        }
        return ['hash', \%out];
    }
    return ['array', [map {snapshot_graph($value->[$_], $seen, "$path/$_")} 0..$#$value]]
        if ref($value) eq 'ARRAY';
    die 'unqualified native graph reference';
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

# Compare complete primitive kinds as well as values in finite public products.
sub is_metadata {
    my ($actual, $expected, $label) = @_;
    is(input_snapshot($actual), input_snapshot($expected), $label);
}

