package FSM::Extension::Context;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use feature qw(signatures);
no warnings 'experimental::signatures';

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
