package FSM::Extension::Context;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use Scalar::Util qw(blessed);
use feature qw(signatures);
no warnings 'experimental::signatures';

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
        stage => $args{stage},
        pipeline => $args{pipeline},
        source_path => $args{source_path},
        target_language => $args{target_language},
        source_info => $args{source_info},
        raw_ast => $args{raw_ast},
        result => $args{result},
    }, $class;
}

sub stage ($self) { return $self->{stage} }
sub pipeline ($self) { return $self->{pipeline} }
sub source_path ($self) { return $self->{source_path} }
sub target_language ($self) { return $self->{target_language} }
sub source_info ($self) { return $self->{source_info} }
sub raw_ast ($self) { return $self->{raw_ast} }
sub result ($self) { return $self->{result} }

1;
