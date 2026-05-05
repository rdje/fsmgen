package FSM::Extension::Context;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use Scalar::Util qw(blessed reftype);
use feature qw(signatures);
no warnings 'experimental::signatures';

my $CONTEXT_INSTANCE_MARKER = __PACKAGE__ . '::constructed';
my @SUPPORTED_CONTEXT_STAGE_NAMES = qw(
    after_parse_source
    after_generate_result
);
my %SUPPORTED_CONTEXT_STAGE_NAME = map { $_ => 1 } @SUPPORTED_CONTEXT_STAGE_NAMES;
my @SUPPORTED_CONTEXT_OPTION_NAMES = qw(
    stage
    pipeline
    source_path
    target_language
    source_info
    raw_ast
    result
);
my %SUPPORTED_CONTEXT_OPTION_NAME = map { $_ => 1 } @SUPPORTED_CONTEXT_OPTION_NAMES;
my $_non_empty_scalar = sub {
    my ($value) = @_;
    return defined($value) && !ref($value) && $value =~ /\S/;
};
my $_validate_context_stage = sub {
    my ($stage) = @_;
    confess "FSM::Extension::Context constructor requires stage to be a supported hook name: "
        . join(', ', @SUPPORTED_CONTEXT_STAGE_NAMES)
        unless defined($stage) && !ref($stage) && $SUPPORTED_CONTEXT_STAGE_NAME{$stage};

    return;
};
my $_validate_context_common_payload = sub {
    my (%args) = @_;
    confess "FSM::Extension::Context constructor requires pipeline to be a blessed object"
        unless blessed($args{pipeline});
    confess "FSM::Extension::Context constructor requires source_path to be a scalar non-empty string"
        unless $_non_empty_scalar->($args{source_path});
    confess "FSM::Extension::Context constructor requires target_language to be a scalar non-empty string"
        unless $_non_empty_scalar->($args{target_language});
    confess "FSM::Extension::Context constructor requires source_info to be a hash reference"
        unless ref($args{source_info}) eq 'HASH';

    my $source_kind = $args{source_info}{kind};
    confess "FSM::Extension::Context constructor requires source_info->{kind} to be a scalar non-empty source kind"
        unless $_non_empty_scalar->($source_kind);

    return;
};
my $_validate_context_stage_payload = sub {
    my (%args) = @_;
    if ($args{stage} eq 'after_parse_source') {
        confess "FSM::Extension::Context constructor requires raw_ast to be an array reference for after_parse_source"
            unless ref($args{raw_ast}) eq 'ARRAY';
        confess "FSM::Extension::Context constructor does not accept result for after_parse_source contexts"
            if defined($args{result});
        return;
    }

    confess "FSM::Extension::Context constructor requires result to be a hash reference for after_generate_result"
        unless ref($args{result}) eq 'HASH';
    confess "FSM::Extension::Context constructor does not accept raw_ast for after_generate_result contexts"
        if defined($args{raw_ast});
    return;
};
my $_validate_context_payload = sub {
    my (%args) = @_;
    $_validate_context_stage->($args{stage});
    $_validate_context_common_payload->(%args);
    $_validate_context_stage_payload->(%args);
    return;
};
my $_validate_context_accessor_receiver = sub {
    my ($self, $method_name) = @_;
    confess "FSM::Extension::Context::$method_name requires an exact FSM::Extension::Context object constructed by new(...)"
        unless blessed($self)
            && blessed($self) eq __PACKAGE__
            && (reftype($self) || '') eq 'HASH'
            && $self->{$CONTEXT_INSTANCE_MARKER};

    return;
};
my $_validate_context_accessor_argument_count = sub {
    my ($method_name, @args) = @_;
    confess "FSM::Extension::Context::$method_name expects no payload arguments after the context invocant"
        if @args;

    return;
};
my $_clone_context_payload;
$_clone_context_payload = sub {
    my ($value) = @_;
    return undef unless defined $value;

    if (ref($value) eq 'HASH') {
        return {
            map { $_ => $_clone_context_payload->($value->{$_}) } sort keys %$value
        };
    }

    if (ref($value) eq 'ARRAY') {
        return [ map { $_clone_context_payload->($_) } @$value ];
    }

    return $value;
};

sub new ($class, @arg_pairs) {
    confess "FSM::Extension::Context constructor receiver must be scalar FSM::Extension::Context class name"
        unless defined($class) && !ref($class) && $class eq __PACKAGE__;
    confess "FSM::Extension::Context constructor arguments must be an even-length option/value list"
        if @arg_pairs % 2;

    my %seen_option;
    my %unsupported_options;
    my %duplicate_options;
    for (my $i = 0; $i < @arg_pairs; $i += 2) {
        my $option_name = $arg_pairs[$i];
        confess "FSM::Extension::Context constructor option names must be scalar non-empty strings"
            unless defined($option_name) && !ref($option_name) && $option_name ne '';

        $unsupported_options{$option_name} = 1
            unless $SUPPORTED_CONTEXT_OPTION_NAME{$option_name};
        $duplicate_options{$option_name} = 1
            if $seen_option{$option_name}++;
    }

    confess "FSM::Extension::Context constructor rejects unsupported option name(s): "
        . join(', ', sort keys %unsupported_options)
        if %unsupported_options;
    confess "FSM::Extension::Context constructor rejects duplicate option name(s): "
        . join(', ', sort keys %duplicate_options)
        if %duplicate_options;

    my %args = @arg_pairs;
    $_validate_context_payload->(%args);

    return bless {
        $CONTEXT_INSTANCE_MARKER => 1,
        stage => $args{stage},
        pipeline => $args{pipeline},
        source_path => $args{source_path},
        target_language => $args{target_language},
        source_info => $_clone_context_payload->($args{source_info}),
        raw_ast => $_clone_context_payload->($args{raw_ast}),
        result => $args{result},
    }, $class;
}

sub stage {
    my ($self, @args) = @_;
    $_validate_context_accessor_receiver->($self, 'stage');
    $_validate_context_accessor_argument_count->('stage', @args);
    return $self->{stage};
}

sub pipeline {
    my ($self, @args) = @_;
    $_validate_context_accessor_receiver->($self, 'pipeline');
    $_validate_context_accessor_argument_count->('pipeline', @args);
    return $self->{pipeline};
}

sub source_path {
    my ($self, @args) = @_;
    $_validate_context_accessor_receiver->($self, 'source_path');
    $_validate_context_accessor_argument_count->('source_path', @args);
    return $self->{source_path};
}

sub target_language {
    my ($self, @args) = @_;
    $_validate_context_accessor_receiver->($self, 'target_language');
    $_validate_context_accessor_argument_count->('target_language', @args);
    return $self->{target_language};
}

sub source_info {
    my ($self, @args) = @_;
    $_validate_context_accessor_receiver->($self, 'source_info');
    $_validate_context_accessor_argument_count->('source_info', @args);
    return $_clone_context_payload->($self->{source_info});
}

sub raw_ast {
    my ($self, @args) = @_;
    $_validate_context_accessor_receiver->($self, 'raw_ast');
    $_validate_context_accessor_argument_count->('raw_ast', @args);
    return $_clone_context_payload->($self->{raw_ast});
}

sub result {
    my ($self, @args) = @_;
    $_validate_context_accessor_receiver->($self, 'result');
    $_validate_context_accessor_argument_count->('result', @args);
    return $self->{result};
}

1;
