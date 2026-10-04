sub snapshot_interface_port_metadata {
    my ($value) = @_;
    return undef unless defined $value;
    _require(ref($value) eq 'ARRAY', 'expected port metadata array');
    $value = dclone($value);
    my (@ports, %seen);
    my $outputs_started = 0;
    for my $port (@$value) {
        _require(ref($port) eq 'HASH', 'expected port metadata entry');
        _closed_keys($port, [qw(name direction width)], [qw(type type_kind domain fields)]);
        _require(_name($port->{name}) && !$seen{$port->{name}}++, 'invalid or duplicate port name');
        _require(defined($port->{direction}) && !ref($port->{direction})
            && scalar($port->{direction} =~ /\A(?:input|output)\z/), 'invalid direction');
        _require($port->{direction} ne 'input' || !$outputs_started, 'inputs must precede outputs');
        $outputs_started = 1 if $port->{direction} eq 'output';
        _require(_positive_integer($port->{width}), 'invalid port width');
        my %copy = (name => $port->{name}, direction => $port->{direction}, width => 0 + $port->{width});
        if (exists $port->{domain}) {
            _require(_identifier($port->{domain}), 'invalid domain');
            $copy{domain} = $port->{domain};
        }
        if (exists $port->{type}) {
            _require(defined($port->{type}) && !ref($port->{type})
                && scalar($port->{type} =~ /\A[A-Za-z_]\w*(?:\.[A-Za-z_]\w*)?\z/), 'invalid type alias');
            _require(defined($port->{type_kind}) && !ref($port->{type_kind})
                && scalar($port->{type_kind} =~ /\A(?:bit|bits|record)\z/), 'invalid resolved type kind');
            _require($port->{type_kind} ne 'bit' || $port->{width} == 1, 'bit port width must be one');
            @copy{qw(type type_kind)} = @{$port}{qw(type type_kind)};
        } else {
            _require(!exists($port->{type_kind}) && !exists($port->{fields}), 'type facts require an alias');
        }
        if (($port->{type_kind} // '') eq 'record') {
            $copy{fields} = _snapshot_fields($port->{fields}, $port->{width});
        } else {
            _require(!exists($port->{fields}), 'scalar port cannot have record fields');
        }
        push @ports, \%copy;
    }
    return \@ports;
}

sub _snapshot_fields {
    my ($fields, $width) = @_;
    _require(ref($fields) eq 'ARRAY' && scalar(@$fields), 'record requires scalar field metadata');
    my (@copy, %seen);
    my $next_high = $width - 1;
    for my $field (@$fields) {
        _require(ref($field) eq 'HASH', 'expected scalar field entry');
        _closed_keys($field, [qw(path width lsb msb signed)], ['state_model']);
        my $path = $field->{path};
        _require(defined($path) && !ref($path)
            && $path =~ /\A[A-Za-z_]\w*(?:(?:\.[A-Za-z_]\w*)|(?:\[[0-9]+\]))*\z/
            && !$seen{$path}++, 'invalid or duplicate field path');
        _require(_positive_integer($field->{width}) && _nonnegative_integer($field->{lsb})
            && _nonnegative_integer($field->{msb}) && $field->{msb} == $next_high
            && $field->{msb} - $field->{lsb} + 1 == $field->{width}, 'field ranges do not form ordered packed layout');
        _require(_binary($field->{signed}), 'invalid scalar field signed property');
        my %entry = (path => $path, map { $_ => 0 + $field->{$_} } qw(width lsb msb signed));
        if (exists $field->{state_model}) {
            _require(_state_model($field->{state_model}), 'invalid scalar field state model');
            $entry{state_model} = $field->{state_model};
        }
        push @copy, \%entry;
        $next_high = $field->{lsb} - 1;
    }
    _require($next_high == -1, 'record field layout does not cover the port');
    return \@copy;
}

