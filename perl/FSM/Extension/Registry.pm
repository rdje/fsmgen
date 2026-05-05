package FSM::Extension::Registry;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use Scalar::Util qw(blessed reftype);
use feature qw(signatures);
no warnings 'experimental::signatures';

my @SUPPORTED_HOOK_NAMES = qw(
    after_parse_source
    after_generate_result
);
my %SUPPORTED_HOOK_NAME = map { $_ => 1 } @SUPPORTED_HOOK_NAMES;
my @SUPPORTED_REGISTRY_OPTION_NAMES = qw(
    extensions
);
my %SUPPORTED_REGISTRY_OPTION_NAME = map { $_ => 1 } @SUPPORTED_REGISTRY_OPTION_NAMES;
my $REGISTRY_INSTANCE_MARKER = __PACKAGE__ . '::constructed';
my $CONTEXT_INSTANCE_MARKER = 'FSM::Extension::Context::constructed';
my $_validate_registry_method_argument_count = sub {
    my ($method_name, $expected_count, $expected_description, @args) = @_;
    confess "FSM::Extension::Registry::$method_name expects $expected_description after the registry invocant"
        unless @args == $expected_count;

    return;
};

sub new {
    my ($class, @arg_pairs) = @_;
    confess "FSM::Extension::Registry constructor receiver must be scalar FSM::Extension::Registry class name"
        unless defined($class) && !ref($class) && $class eq __PACKAGE__;
    confess "FSM::Extension::Registry constructor arguments must be an even-length option/value list"
        if @arg_pairs % 2;

    my %seen_option;
    my %unsupported_options;
    my %duplicate_options;
    for (my $i = 0; $i < @arg_pairs; $i += 2) {
        my $option_name = $arg_pairs[$i];
        confess "FSM::Extension::Registry constructor option names must be scalar non-empty strings"
            unless defined($option_name) && !ref($option_name) && $option_name ne '';

        $unsupported_options{$option_name} = 1
            unless $SUPPORTED_REGISTRY_OPTION_NAME{$option_name};
        $duplicate_options{$option_name} = 1
            if $seen_option{$option_name}++;
    }

    confess "FSM::Extension::Registry constructor rejects unsupported option name(s): "
        . join(', ', sort keys %unsupported_options)
        if %unsupported_options;
    confess "FSM::Extension::Registry constructor rejects duplicate option name(s): "
        . join(', ', sort keys %duplicate_options)
        if %duplicate_options;

    my %args = @arg_pairs;
    my $extensions = exists($args{extensions}) ? $args{extensions} : [];
    confess "FSM::Extension::Registry expects 'extensions' to be an array reference"
        unless ref($extensions) eq 'ARRAY';

    for my $extension (@$extensions) {
        confess "FSM::Extension::Registry accepts only blessed extension objects"
            unless blessed($extension);
        confess "FSM::Extension::Registry expects extension objects to provide at least one supported hook method: "
            . join(', ', @SUPPORTED_HOOK_NAMES)
            unless _extension_supports_supported_hook($extension);
    }

    return bless {
        extensions => $extensions,
        $REGISTRY_INSTANCE_MARKER => 1,
    }, $class;
}

sub _extension_supports_supported_hook ($extension) {
    for my $hook_name (@SUPPORTED_HOOK_NAMES) {
        return 1 if UNIVERSAL::can($extension, $hook_name);
    }

    return 0;
}

sub extensions {
    my ($self, @args) = @_;
    _validate_registry_method_receiver($self, 'extensions');
    $_validate_registry_method_argument_count->('extensions', 0, 'no payload arguments', @args);

    return $self->{extensions};
}

sub dispatch_hook {
    my ($self, @args) = @_;
    _validate_registry_method_receiver($self, 'dispatch_hook');
    $_validate_registry_method_argument_count->(
        'dispatch_hook',
        2,
        'exactly one hook name and one context argument',
        @args,
    );

    my ($hook_name, $context) = @args;
    confess "FSM::Extension::Registry requires a non-empty hook name"
        unless defined($hook_name) && $hook_name ne '';
    confess "FSM::Extension::Registry rejects unsupported extension hook '$hook_name'"
        unless $SUPPORTED_HOOK_NAME{$hook_name};
    _dispatch_context_arg($hook_name, $context);

    for my $extension (@{$self->extensions}) {
        my $hook_method = UNIVERSAL::can($extension, $hook_name);
        next unless $hook_method;

        my @result = eval { $hook_method->($extension, $context) };
        if (!$@) {
            next;
        }

        my $error = $@;
        die $error if ref($error);
        die $error if $error =~ /(?:^|\n)Extension module:\s+'/s;

        my $module_name = blessed($extension) || ref($extension) || 'unknown_extension';
        die "Extension module: '$module_name'\nExtension stage: '$hook_name'\n$error";
    }
}

sub _dispatch_context_arg ($hook_name, $context) {
    confess "FSM::Extension::Registry expects dispatch context for '$hook_name' to be a FSM::Extension::Context object with matching stage"
        unless blessed($context)
            && blessed($context) eq 'FSM::Extension::Context'
            && (reftype($context) || '') eq 'HASH'
            && $context->{$CONTEXT_INSTANCE_MARKER};

    my $stage = $context->stage;
    confess "FSM::Extension::Registry expects dispatch context for '$hook_name' to be a FSM::Extension::Context object with matching stage"
        unless defined($stage)
            && !ref($stage)
            && $stage eq $hook_name;

    return;
}

sub _validate_registry_method_receiver ($self, $method_name) {
    confess "FSM::Extension::Registry::$method_name requires an exact FSM::Extension::Registry object constructed by new(...)"
        unless blessed($self)
            && blessed($self) eq __PACKAGE__
            && (reftype($self) || '') eq 'HASH'
            && $self->{$REGISTRY_INSTANCE_MARKER};

    return;
}

sub after_parse_source {
    my ($self, @args) = @_;
    _validate_registry_method_receiver($self, 'after_parse_source');
    $_validate_registry_method_argument_count->(
        'after_parse_source',
        1,
        'exactly one context argument',
        @args,
    );

    my ($context) = @args;
    return $self->dispatch_hook('after_parse_source', $context);
}

sub after_generate_result {
    my ($self, @args) = @_;
    _validate_registry_method_receiver($self, 'after_generate_result');
    $_validate_registry_method_argument_count->(
        'after_generate_result',
        1,
        'exactly one context argument',
        @args,
    );

    my ($context) = @args;
    return $self->dispatch_hook('after_generate_result', $context);
}

1;
