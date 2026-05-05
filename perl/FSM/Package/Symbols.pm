package FSM::Package::Symbols;

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

sub new ($class, %args) {
    return bless {
        constants => _clone($args{constants} || {}),
        enums => _clone($args{enums} || {}),
        types => _clone($args{types} || {}),
        raw_blocks => _clone($args{raw_blocks} || []),
    }, $class;
}

sub constants ($self) { return _clone($self->{constants}) }
sub enums ($self) { return _clone($self->{enums}) }
sub types ($self) { return _clone($self->{types}) }
sub raw_blocks ($self) { return _clone($self->{raw_blocks}) }

sub store_constant ($self, $name, $payload) {
    $self->{constants}{$name} = _clone($payload);
    return _clone($self->{constants}{$name});
}

sub store_enum ($self, $enum_name, $members_hashref) {
    $self->{enums}{$enum_name} = {
        %{ _clone($self->{enums}{$enum_name} || {}) },
        %{ _clone($members_hashref || {}) },
    };
    return _clone($self->{enums}{$enum_name});
}

sub store_type ($self, $type_name, $type_hashref) {
    $self->{types}{$type_name} = _clone($type_hashref);
    return _clone($self->{types}{$type_name});
}

sub push_raw_block ($self, $block_ast) {
    push @{ $self->{raw_blocks} }, _clone($block_ast) if defined $block_ast;
    return $self->raw_blocks;
}

sub resolve_actual_payload ($self, $symbol_name) {
    my $resolved_payload = $self->resolve_payload($symbol_name);
    return _scalar_payload_value($resolved_payload);
}

sub resolve_payload ($self, $symbol_name) {
    return undef unless defined($symbol_name) && !ref($symbol_name);

    if (exists $self->{constants}{$symbol_name}) {
        return _clone($self->{constants}{$symbol_name});
    }

    if ($symbol_name =~ /\A([A-Za-z_]\w*)\.([A-Za-z_]\w*)\z/) {
        my ($enum_name, $member_name) = ($1, $2);
        if (exists $self->{enums}{$enum_name} && exists $self->{enums}{$enum_name}{$member_name}) {
            return _clone({
                kind => 'scalar',
                payload => $self->{enums}{$enum_name}{$member_name},
            });
        }
    }

    if ($symbol_name =~ /\A([A-Za-z_]\w*)(.*)\z/) {
        my ($constant_name, $suffix) = ($1, $2);
        if (exists $self->{constants}{$constant_name}) {
            return _clone(_resolve_payload_suffix($self->{constants}{$constant_name}, $suffix));
        }
    }

    return undef;
}

sub resolve_type ($self, $type_name) {
    return undef unless defined($type_name) && !ref($type_name);
    return _clone($self->{types}{$type_name}) if exists $self->{types}{$type_name};
    return undef;
}

sub constant_scalar_leaves ($self) {
    my %leaf_payloads;

    for my $constant_name (sort keys %{ $self->{constants} || {} }) {
        _collect_scalar_leaves($constant_name, $self->{constants}{$constant_name}, \%leaf_payloads);
    }

    return \%leaf_payloads;
}

sub constant_aggregate_paths ($self) {
    my %aggregate_paths;

    for my $constant_name (sort keys %{ $self->{constants} || {} }) {
        _collect_aggregate_paths($constant_name, $self->{constants}{$constant_name}, \%aggregate_paths);
    }

    return \%aggregate_paths;
}

sub summary ($self) {
    return {
        constants => scalar(keys %{ $self->{constants} || {} }),
        enums => scalar(keys %{ $self->{enums} || {} }),
        types => scalar(keys %{ $self->{types} || {} }),
    };
}

sub as_hashref ($self) {
    my $constants = _clone($self->{constants} || {});
    my $enums = _clone($self->{enums} || {});
    my $types = _clone($self->{types} || {});
    my $constant_names = [ sort keys %{ $self->{constants} || {} } ];
    my $enum_names = [ sort keys %{ $self->{enums} || {} } ];
    my $type_names = [ sort keys %{ $self->{types} || {} } ];
    my $constant_scalar_leaves = $self->constant_scalar_leaves || {};
    my $constant_aggregate_paths = [ sort keys %{ $self->constant_aggregate_paths || {} } ];

    return {
        constant_count => scalar(@$constant_names),
        constant_names => $constant_names,
        constants => $constants,
        enum_count => scalar(@$enum_names),
        enum_names => $enum_names,
        enums => $enums,
        type_count => scalar(@$type_names),
        type_names => $type_names,
        types => $types,
        constant_scalar_leaves => _clone($constant_scalar_leaves),
        constant_aggregate_paths => $constant_aggregate_paths,
    };
}

sub _scalar_payload_value ($payload) {
    return undef unless defined $payload;
    return $payload unless ref($payload) eq 'HASH';
    return undef unless ($payload->{kind} || '') eq 'scalar';
    return $payload->{payload};
}

sub _resolve_payload_suffix ($payload, $suffix) {
    return undef unless defined $payload;
    $suffix //= '';
    return $payload if $suffix eq '';

    my $current = $payload;
    my $remaining = $suffix;

    while (length $remaining) {
        if ($remaining =~ s/\A\.([A-Za-z_]\w*)//) {
            return undef unless ref($current) eq 'HASH' && ($current->{kind} || '') eq 'map';
            $current = ($current->{members} || {})->{$1};
            return undef unless defined $current;
            next;
        }

        if ($remaining =~ s/\A\[(\d+)\]//) {
            return undef unless ref($current) eq 'HASH' && ($current->{kind} || '') eq 'list';
            my $items = $current->{items} || [];
            return undef if $1 > $#$items;
            $current = $items->[$1];
            return undef unless defined $current;
            next;
        }

        return undef;
    }

    return $current;
}

sub _collect_scalar_leaves ($path, $payload, $leaf_payloads) {
    return unless defined $payload;

    my $scalar_value = _scalar_payload_value($payload);
    if (defined $scalar_value) {
        $leaf_payloads->{$path} = $scalar_value;
        return;
    }

    return unless ref($payload) eq 'HASH';
    my $kind = $payload->{kind} || '';

    if ($kind eq 'map') {
        for my $member_name (sort keys %{ $payload->{members} || {} }) {
            _collect_scalar_leaves("$path.$member_name", $payload->{members}{$member_name}, $leaf_payloads);
        }
        return;
    }

    if ($kind eq 'list') {
        my $items = $payload->{items} || [];
        for my $index (0 .. $#$items) {
            _collect_scalar_leaves("$path\[$index\]", $items->[$index], $leaf_payloads);
        }
    }
}

sub _collect_aggregate_paths ($path, $payload, $aggregate_paths) {
    return unless defined $payload && ref($payload) eq 'HASH';

    my $kind = $payload->{kind} || '';
    return unless $kind eq 'map' || $kind eq 'list';

    $aggregate_paths->{$path} = 1;

    if ($kind eq 'map') {
        for my $member_name (sort keys %{ $payload->{members} || {} }) {
            _collect_aggregate_paths("$path.$member_name", $payload->{members}{$member_name}, $aggregate_paths);
        }
        return;
    }

    my $items = $payload->{items} || [];
    for my $index (0 .. $#$items) {
        _collect_aggregate_paths("$path\[$index\]", $items->[$index], $aggregate_paths);
    }
}

sub _clone ($value) {
    return undef unless defined $value;

    if (ref($value) eq 'HASH') {
        return {
            map { $_ => _clone($value->{$_}) } sort keys %$value
        };
    }

    if (ref($value) eq 'ARRAY') {
        return [ map { _clone($_) } @$value ];
    }

    return $value;
}

1;
