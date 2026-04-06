package FSM::Package::Symbols;

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

sub new ($class, %args) {
    return bless {
        constants => $args{constants} || {},
        enums => $args{enums} || {},
        raw_blocks => $args{raw_blocks} || [],
    }, $class;
}

sub constants ($self) { return $self->{constants} }
sub enums ($self) { return $self->{enums} }
sub raw_blocks ($self) { return $self->{raw_blocks} }

sub store_constant ($self, $name, $payload) {
    $self->{constants}{$name} = $payload;
    return $payload;
}

sub store_enum ($self, $enum_name, $members_hashref) {
    $self->{enums}{$enum_name} = {
        %{ $self->{enums}{$enum_name} || {} },
        %{ $members_hashref || {} },
    };
    return $self->{enums}{$enum_name};
}

sub push_raw_block ($self, $block_ast) {
    push @{ $self->{raw_blocks} }, $block_ast if defined $block_ast;
    return $self->{raw_blocks};
}

sub resolve_actual_payload ($self, $symbol_name) {
    return undef unless defined($symbol_name) && !ref($symbol_name);

    if (exists $self->{constants}{$symbol_name}) {
        return $self->{constants}{$symbol_name};
    }

    if ($symbol_name =~ /\A([A-Za-z_]\w*)\.([A-Za-z_]\w*)\z/) {
        my ($enum_name, $member_name) = ($1, $2);
        return undef unless exists $self->{enums}{$enum_name};
        return $self->{enums}{$enum_name}{$member_name};
    }

    return undef;
}

sub summary ($self) {
    return {
        constants => scalar(keys %{ $self->{constants} || {} }),
        enums => scalar(keys %{ $self->{enums} || {} }),
    };
}

1;
