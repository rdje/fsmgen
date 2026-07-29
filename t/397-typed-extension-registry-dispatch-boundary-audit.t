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
use FSM::Support::ExtensionContract qw(
    build_extension_contract
    extension_contract_hook_names
);

{
    package Test::RegistryDispatchBoundaryExtension;

    use strict;
    use warnings;

    sub new {
        return bless {
            expected_calls => [],
            unexpected_calls => [],
        }, shift;
    }

    sub after_parse_source {
        my ($self, $context) = @_;
        push @{$self->{expected_calls}}, {
            hook => 'after_parse_source',
            stage => $context->stage,
            source_kind => $context->source_info->{kind},
        };
    }

    sub after_generate_result {
        my ($self, $context) = @_;
        push @{$self->{expected_calls}}, {
            hook => 'after_generate_result',
            stage => $context->stage,
            source_kind => $context->source_info->{kind},
        };
        $context->result->{registry_dispatch_marker} = [@{$self->{expected_calls}}];
    }

    sub before_parse_source { return shift->_unexpected_hook('before_parse_source') }
    sub before_generate_result { return shift->_unexpected_hook('before_generate_result') }
    sub after_emit_hdl { return shift->_unexpected_hook('after_emit_hdl') }
    sub on_result { return shift->_unexpected_hook('on_result') }

    sub expected_calls { return shift->{expected_calls} }
    sub unexpected_calls { return shift->{unexpected_calls} }

    sub _unexpected_hook {
        my ($self, $hook_name) = @_;
        push @{$self->{unexpected_calls}}, $hook_name;
        die "Unexpected registry dispatch for $hook_name";
    }
}

subtest 'typed-extension manifests publish the registry-supported hook set' => sub {
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
            contract => run_capability_manifest('--capability-manifest')->{embedding}{typed_extensions},
        },
        {
            label => 'CLI alias capability manifest typed-extension contract',
            contract => run_capability_manifest('--emit-capability-manifest')->{embedding}{typed_extensions},
        },
    );

    for my $view (@views) {
        my $contract = $view->{contract};
        my $label = $view->{label};

        ok(
            $contract->{hook_set_closed_for_schema_version},
            "$label marks the hook set closed for schema version 1",
        );
        is_deeply(
            sorted($contract->{hook_names}),
            sorted(extension_contract_hook_names()),
            "$label hook_names match the builder-owned hook list",
        );
        is_deeply(
            sorted([keys %{$contract->{hooks} || {}}]),
            sorted($contract->{hook_names}),
            "$label detailed hook map matches the advertised hook list",
        );
    }
};

subtest 'direct registry dispatch accepts exactly the advertised hooks' => sub {
    my $extension = Test::RegistryDispatchBoundaryExtension->new();
    my $registry = FSM::Extension::Registry->new(extensions => [$extension]);
    my $parse_context = make_context(
        stage => 'after_parse_source',
        raw_ast => [],
    );
    my $result_context = make_context(
        stage => 'after_generate_result',
        result => {
            module_info => {
                module_name => 'registry_dispatch_boundary',
            },
        },
    );

    $registry->dispatch_hook('after_parse_source', $parse_context);
    $registry->dispatch_hook('after_generate_result', $result_context);

    is_deeply(
        $extension->expected_calls,
        [
            {
                hook => 'after_parse_source',
                stage => 'after_parse_source',
                source_kind => 'fsm',
            },
            {
                hook => 'after_generate_result',
                stage => 'after_generate_result',
                source_kind => 'fsm',
            },
        ],
        'direct registry dispatch runs only the advertised supported hooks',
    );
    is_deeply(
        $result_context->result->{registry_dispatch_marker},
        $extension->expected_calls,
        'result hook can still mutate the in-process result through direct registry dispatch',
    );
    is_deeply(
        $extension->unexpected_calls,
        [],
        'direct supported hook dispatch does not call unsupported hook-shaped methods',
    );
};

subtest 'public registry hook wrappers route through the supported hook names' => sub {
    my $extension = Test::RegistryDispatchBoundaryExtension->new();
    my $registry = FSM::Extension::Registry->new(extensions => [$extension]);
    my $parse_context = make_context(
        stage => 'after_parse_source',
        raw_ast => [],
    );
    my $result_context = make_context(
        stage => 'after_generate_result',
        result => {
            module_info => {
                module_name => 'registry_dispatch_boundary',
            },
        },
    );

    $registry->after_parse_source($parse_context);
    $registry->after_generate_result($result_context);

    is_deeply(
        [map { $_->{hook} } @{$extension->expected_calls}],
        [qw(after_parse_source after_generate_result)],
        'registry wrapper methods dispatch the supported hook names in order',
    );
    is_deeply(
        $extension->unexpected_calls,
        [],
        'registry wrapper methods do not call unsupported hook-shaped methods',
    );
};

subtest 'direct registry dispatch rejects unsupported hook names before extension invocation' => sub {
    for my $hook_name (qw(before_parse_source before_generate_result after_emit_hdl on_result)) {
        my $extension = Test::RegistryDispatchBoundaryExtension->new();
        my $registry = FSM::Extension::Registry->new(extensions => [$extension]);
        my $error = eval {
            $registry->dispatch_hook(
                $hook_name,
                make_context(
                    stage => 'after_parse_source',
                    raw_ast => [],
                ),
            );
            undef;
        };
        $error = $@ if !$error;

        like(
            $error,
            qr/FSM::Extension::Registry rejects unsupported extension hook '\Q$hook_name\E'/s,
            "registry rejects unsupported hook $hook_name",
        );
        is_deeply(
            $extension->expected_calls,
            [],
            "registry does not run expected hooks while rejecting $hook_name",
        );
        is_deeply(
            $extension->unexpected_calls,
            [],
            "registry rejects $hook_name before invoking the extension method",
        );
    }

    my $extension = Test::RegistryDispatchBoundaryExtension->new();
    my $registry = FSM::Extension::Registry->new(extensions => [$extension]);
    my $missing_error = eval {
        $registry->dispatch_hook(
            '',
            make_context(
                stage => 'after_parse_source',
                raw_ast => [],
            ),
        );
        undef;
    };
    $missing_error = $@ if !$missing_error;

    like(
        $missing_error,
        qr/FSM::Extension::Registry requires a non-empty hook name/s,
        'registry rejects empty direct hook dispatch names',
    );
    is_deeply(
        $extension->unexpected_calls,
        [],
        'registry rejects empty hook names before extension invocation',
    );
};

done_testing();

sub make_context {
    my (%args) = @_;
    return FSM::Extension::Context->new(
        stage => $args{stage},
        pipeline => bless({}, 'Test::RegistryDispatchBoundaryPipeline'),
        source_path => 'fixtures/registry_dispatch_boundary.fsm',
        target_language => 'systemverilog',
        source_info => {
            kind => 'fsm',
        },
        raw_ast => $args{raw_ast},
        result => $args{result},
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

sub sorted {
    my ($values) = @_;
    return [sort @{$values || []}];
}
