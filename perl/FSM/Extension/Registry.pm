package FSM::Extension::Registry;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use Scalar::Util qw(blessed);
use feature qw(signatures);
no warnings 'experimental::signatures';

my @SUPPORTED_HOOK_NAMES = qw(
    after_parse_source
    after_generate_result
);
my %SUPPORTED_HOOK_NAME = map { $_ => 1 } @SUPPORTED_HOOK_NAMES;

sub new ($class, %args) {
    my $extensions = $args{extensions} || [];
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
    }, $class;
}

sub _extension_supports_supported_hook ($extension) {
    for my $hook_name (@SUPPORTED_HOOK_NAMES) {
        return 1 if UNIVERSAL::can($extension, $hook_name);
    }

    return 0;
}

sub extensions ($self) { return $self->{extensions} }

sub dispatch_hook ($self, $hook_name, $context) {
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
            && defined($context->stage)
            && !ref($context->stage)
            && $context->stage eq $hook_name;

    return;
}

sub after_parse_source ($self, $context) {
    return $self->dispatch_hook('after_parse_source', $context);
}

sub after_generate_result ($self, $context) {
    return $self->dispatch_hook('after_generate_result', $context);
}

1;
