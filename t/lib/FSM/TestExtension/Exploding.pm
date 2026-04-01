package FSM::TestExtension::Exploding;

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

sub after_parse_source ($self, $context) {
    $self->_maybe_fail('after_parse_source', $context);
}

sub after_generate_result ($self, $context) {
    $self->_maybe_fail('after_generate_result', $context);
}

sub _maybe_fail ($self, $stage, $context) {
    my $fail_stage = $ENV{FSM_TEST_EXTENSION_FAIL_STAGE} // '';
    return unless $fail_stage eq $stage;

    my $source_kind = $context->source_info->{kind} // 'unknown';
    die "Exploding test extension forced failure at stage '$stage' for source kind '$source_kind'\n";
}

1;
