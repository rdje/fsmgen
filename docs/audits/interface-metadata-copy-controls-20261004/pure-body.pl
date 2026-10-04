sub pure_copy {
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
        $copy->{$_} = pure_copy($value->{$_}, $copies) for keys %$value;
    } else {
        push @$copy, pure_copy($_, $copies) for @$value;
    }
    return $copy;
}

