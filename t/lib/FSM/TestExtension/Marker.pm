package FSM::TestExtension::Marker;

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

sub new ($class) {
    return bless {
        module_name => $class,
        parsed_kinds => [],
    }, $class;
}

sub after_parse_source ($self, $context) {
    push @{$self->{parsed_kinds}}, $context->source_info->{kind};
}

sub after_generate_result ($self, $context) {
    my $parsed_kind = @{$self->{parsed_kinds}}
        ? $self->{parsed_kinds}[-1]
        : undef;

    $context->result->{extension_marker} = {
        module_name => $self->{module_name},
        source_kind => $context->source_info->{kind},
        parsed_kind => $parsed_kind,
    };

    return unless exists $context->result->{hdl_code};
    return unless defined $context->result->{hdl_code};

    $context->result->{hdl_code} .= "\n// extension marker: $self->{module_name}\n";
    $context->result->{hdl_code} .= "// parsed source kind: $parsed_kind\n"
        if defined $parsed_kind;
}

1;
