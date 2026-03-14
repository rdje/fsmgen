package FSM::TestExtension::Marker;

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

sub new ($class) {
    return bless {
        module_name => $class,
    }, $class;
}

sub after_generate_result ($self, $context) {
    $context->result->{extension_marker} = {
        module_name => $self->{module_name},
        source_kind => $context->source_info->{kind},
    };

    return unless exists $context->result->{hdl_code};
    return unless defined $context->result->{hdl_code};

    $context->result->{hdl_code} .= "\n// extension marker: $self->{module_name}\n";
}

1;
