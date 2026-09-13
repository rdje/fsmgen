package NativeProxyPopulatedWire;
use strict;
use warnings;
use JSON::PP ();

my $JSON = JSON::PP->new->canonical->ascii->allow_nonref;

sub fields {
    my ($value, @fields) = @_;
    die "expected closed object fields\n" unless ref($value) eq 'HASH'
        && join(',', sort keys %$value) eq join(',', sort @fields);
    return $value;
}

sub integer {
    my ($value) = @_;
    die "expected unsigned bounded JSON integer\n" unless defined($value) && !ref($value)
        && $JSON->encode($value) =~ /\A(?:0|[1-9][0-9]*)\z/
        && length("$value") <= 19 && $value <= 9_223_372_036_854_775_807;
    return $value;
}

sub digest {
    my ($value) = @_;
    die "expected lowercase SHA-256\n" unless defined($value) && !ref($value)
        && $value =~ /\A[0-9a-f]{64}\z/;
    return $value;
}

sub hex_bytes {
    my ($value, $limit) = @_;
    die "expected bounded lowercase octet hex\n" unless defined($value) && !ref($value)
        && length($value) <= 2 * $limit && $value =~ /\A(?:[0-9a-f]{2})*\z/;
    return pack('H*', $value);
}

sub canonical {
    return $JSON->encode($_[0]);
}

sub decode {
    my ($bytes, $limit) = @_;
    die "expected bounded ASCII JSON bytes\n" unless defined($bytes) && !ref($bytes)
        && !utf8::is_utf8($bytes) && length($bytes) <= $limit && $bytes !~ /[^\x00-\x7f]/;
    my $value = $JSON->decode($bytes);
    die "JSON is not canonical\n" unless $JSON->encode($value) eq $bytes;
    return $value;
}

sub _walk {
    my ($value, $restore, $limits, $depth, $count) = @_;
    die "transport structure bound exceeded\n"
        if $depth > $limits->{transport_depth} || ++$$count > $limits->{transport_nodes};
    return $value if !ref($value) || ref($value) eq 'JSON::PP::Boolean';
    return [map { _walk($_, $restore, $limits, $depth + 1, $count) } @$value]
        if ref($value) eq 'ARRAY';
    die "transport contains an opaque reference\n" unless ref($value) eq 'HASH';
    die "transport bytes spelling is ambiguous\n"
        if ($restore && exists($value->{bytes})) || (!$restore && exists($value->{bytes_hex}));
    my %copy;
    for my $key (sort keys %$value) {
        if ($restore && $key eq 'bytes_hex') {
            $copy{bytes} = hex_bytes($value->{$key}, $limits->{handoff_bytes});
        } elsif (!$restore && $key eq 'bytes') {
            my $bytes = $value->{$key};
            die "snapshot does not contain octets\n" unless defined($bytes) && !ref($bytes)
                && utf8::downgrade($bytes, 1) && length($bytes) <= $limits->{handoff_bytes};
            $copy{bytes_hex} = unpack('H*', $bytes);
        } else {
            $copy{$key} = _walk($value->{$key}, $restore, $limits, $depth + 1, $count);
        }
    }
    return \%copy;
}

sub retain {
    my ($value, $limits) = @_;
    my $count = 0;
    return _walk($value, 0, $limits, 0, \$count);
}

sub restore {
    my ($value, $limits) = @_;
    my $count = 0;
    return _walk($value, 1, $limits, 0, \$count);
}

sub copy {
    my ($value, $limits) = @_;
    return restore($JSON->decode(canonical(retain($value, $limits))), $limits);
}

sub same {
    my ($left, $right, $limits) = @_;
    return canonical(retain($left, $limits)) eq canonical(retain($right, $limits));
}

sub command {
    my ($bytes, $limits, $expected, $step) = @_;
    die "unterminated command\n" unless defined($bytes) && $bytes =~ s/\n\z//;
    my $value = decode($bytes, $limits->{command_bytes} - 1);
    fields($value, qw(command payload));
    die "unexpected controller command\n" unless defined($value->{command}) && !ref($value->{command})
        && $value->{command} eq $expected;
    if ($expected eq 'finish') {
        die "finish command carries unexpected payload\n" if defined($value->{payload});
    } elsif ($expected eq 'admit') {
        fields($value->{payload}, 'activation_sha256');
        digest($value->{payload}{activation_sha256});
    } else {
        my @fields = ('id');
        push @fields, 'handoff_sha256' if $expected eq 'step'
            && $step->{operation} =~ /\Aadopt_(?:runtime|observation)\z/;
        fields($value->{payload}, @fields);
        die "command targets a different fixed step\n" unless defined($value->{payload}{id})
            && !ref($value->{payload}{id}) && $value->{payload}{id} eq $step->{id};
        digest($value->{payload}{handoff_sha256}) if @fields > 1;
    }
    return $value->{payload};
}

1;
