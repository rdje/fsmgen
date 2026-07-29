#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP qw(decode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Extension::Context;
use FSM::Extension::Registry;
use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::ExtensionContract qw(build_extension_contract);

my $audit_test = 't/432-typed-extension-registry-method-argument-list-boundary-audit.t';
my $argument_list_shape = 'extensions takes no payload arguments; dispatch_hook takes hook name and context; hook wrapper methods take one context argument after the registry invocant';

{
    package Test::RegistryMethodArgumentListBoundaryExtension;

    use strict;
    use warnings;

    sub new {
        return bless {
            parse_calls => [],
            result_calls => [],
        }, shift;
    }

    sub after_parse_source {
        my ($self, $context) = @_;
        push @{$self->{parse_calls}}, $context->stage;
    }

    sub after_generate_result {
        my ($self, $context) = @_;
        push @{$self->{result_calls}}, $context->stage;
    }

    sub parse_calls { return shift->{parse_calls} }
    sub result_calls { return shift->{result_calls} }
}

subtest 'typed-extension manifests publish the registry method argument-list boundary' => sub {
    my @views = (
        {
            label => 'direct typed-extension contract',
            contract => build_extension_contract(),
        },
        {
            label => 'in-process capability manifest typed-extension contract',
            contract => build_capability_manifest()->{embedding}{typed_extensions},
        },
        {
            label => 'CLI capability manifest typed-extension contract',
            contract => run_capability_manifest('--capability-manifest')
                ->{embedding}{typed_extensions},
        },
        {
            label => 'CLI alias capability manifest typed-extension contract',
            contract => run_capability_manifest('--emit-capability-manifest')
                ->{embedding}{typed_extensions},
        },
    );

    for my $view (@views) {
        my $object_contract = $view->{contract}{extension_object_contract} || {};
        my $label = $view->{label};

        is(
            $object_contract->{registry_method_argument_list_shape},
            $argument_list_shape,
            "$label advertises the direct registry method argument-list shape",
        );
        ok(
            contains_value($view->{contract}{tested_by}, $audit_test),
            "$label lists this registry-method argument-list audit in tested_by provenance",
        );
    }
};

subtest 'direct registry methods accept the advertised payload argument counts' => sub {
    my $extension = Test::RegistryMethodArgumentListBoundaryExtension->new();
    my $registry = FSM::Extension::Registry->new(extensions => [$extension]);

    is_deeply($registry->extensions, [$extension], 'extensions accepts no payload arguments');
    $registry->dispatch_hook('after_parse_source', make_context(stage => 'after_parse_source'));
    $registry->after_generate_result(make_context(stage => 'after_generate_result'));

    is_deeply(
        $extension->parse_calls,
        ['after_parse_source'],
        'dispatch_hook accepts one hook-name and one context argument',
    );
    is_deeply(
        $extension->result_calls,
        ['after_generate_result'],
        'hook wrapper accepts one context argument',
    );
};

subtest 'direct registry methods reject malformed payload argument counts before raw signature fallout' => sub {
    my $registry = FSM::Extension::Registry->new(
        extensions => [Test::RegistryMethodArgumentListBoundaryExtension->new()],
    );
    my $parse_context = make_context(stage => 'after_parse_source');
    my $result_context = make_context(stage => 'after_generate_result');
    my @cases = (
        {
            label => 'extensions extra payload',
            call => sub { $registry->extensions([]) },
            diagnostic => qr/FSM::Extension::Registry::extensions expects no payload arguments after the registry invocant/s,
        },
        {
            label => 'dispatch_hook missing payloads',
            call => sub { $registry->dispatch_hook() },
            diagnostic => qr/FSM::Extension::Registry::dispatch_hook expects exactly one hook name and one context argument after the registry invocant/s,
        },
        {
            label => 'dispatch_hook missing context',
            call => sub { $registry->dispatch_hook('after_parse_source') },
            diagnostic => qr/FSM::Extension::Registry::dispatch_hook expects exactly one hook name and one context argument after the registry invocant/s,
        },
        {
            label => 'dispatch_hook extra payload',
            call => sub { $registry->dispatch_hook('after_parse_source', $parse_context, $parse_context) },
            diagnostic => qr/FSM::Extension::Registry::dispatch_hook expects exactly one hook name and one context argument after the registry invocant/s,
        },
        {
            label => 'after_parse_source missing context',
            call => sub { $registry->after_parse_source() },
            diagnostic => qr/FSM::Extension::Registry::after_parse_source expects exactly one context argument after the registry invocant/s,
        },
        {
            label => 'after_parse_source extra payload',
            call => sub { $registry->after_parse_source($parse_context, $parse_context) },
            diagnostic => qr/FSM::Extension::Registry::after_parse_source expects exactly one context argument after the registry invocant/s,
        },
        {
            label => 'after_generate_result missing context',
            call => sub { $registry->after_generate_result() },
            diagnostic => qr/FSM::Extension::Registry::after_generate_result expects exactly one context argument after the registry invocant/s,
        },
        {
            label => 'after_generate_result extra payload',
            call => sub { $registry->after_generate_result($result_context, $result_context) },
            diagnostic => qr/FSM::Extension::Registry::after_generate_result expects exactly one context argument after the registry invocant/s,
        },
    );

    for my $case (@cases) {
        my $error = capture_exception($case->{call});

        like($error, $case->{diagnostic}, "$case->{label} receives the targeted diagnostic");
        unlike(
            primary_diagnostic($error),
            qr/Too few arguments|Too many arguments|requires a non-empty hook name|expects dispatch context|HASH\(|ARRAY\(|Can't locate object method|Can't use/s,
            "$case->{label} does not leak raw signature, hook, context, or receiver fallout",
        );
    }
};

subtest 'valid argument counts still preserve existing hook and context value boundaries' => sub {
    my $registry = FSM::Extension::Registry->new(
        extensions => [Test::RegistryMethodArgumentListBoundaryExtension->new()],
    );

    my $hook_error = capture_exception(sub {
        $registry->dispatch_hook('', make_context(stage => 'after_parse_source'));
    });
    like(
        $hook_error,
        qr/FSM::Extension::Registry requires a non-empty hook name/s,
        'dispatch_hook keeps the hook-name value boundary after argument-count validation',
    );

    my $context_error = capture_exception(sub {
        $registry->after_parse_source(undef);
    });
    like(
        $context_error,
        qr/FSM::Extension::Registry expects dispatch context for 'after_parse_source' to be a FSM::Extension::Context object with matching stage/s,
        'hook wrapper keeps the context value boundary after argument-count validation',
    );
};

done_testing();

sub make_context {
    my (%args) = @_;
    my @stage_payload = $args{stage} eq 'after_generate_result'
        ? (
            result => {
                module_info => {
                    module_name => 'registry_method_argument_list_boundary',
                },
            },
        )
        : (
            raw_ast => [],
        );

    return FSM::Extension::Context->new(
        stage => $args{stage},
        pipeline => bless({}, 'Test::RegistryMethodArgumentListBoundaryPipeline'),
        source_path => 'fixtures/registry_method_argument_list_boundary.fsm',
        target_language => 'systemverilog',
        source_info => {
            kind => 'fsm',
        },
        @stage_payload,
    );
}

sub run_capability_manifest {
    my ($mode) = @_;
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', $mode],
    );

    ok($success, "$mode succeeds");
    is(join('', @{$stderr_buf || []}), '', "$mode keeps stderr clean");

    return decode_json(join('', @{$stdout_buf || []}));
}

sub capture_exception {
    my ($code) = @_;
    my $ok = eval {
        $code->();
        1;
    };

    return '' if $ok;
    return $@ || 'unknown error';
}

sub primary_diagnostic {
    my ($error) = @_;
    my ($primary) = split /\n/, ($error || ''), 2;
    return $primary || '';
}

sub contains_value {
    my ($values, $wanted) = @_;
    return 0 unless ref($values) eq 'ARRAY';

    for my $value (@{$values}) {
        return 1 if defined($value) && $value eq $wanted;
    }

    return 0;
}
