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

my $audit_test = 't/434-typed-extension-registry-dispatch-constructed-context-boundary-audit.t';
my $dispatch_context_shape = 'exact hash-backed FSM::Extension::Context object constructed by new(...) whose stage matches the dispatched hook name';
my $dispatch_context_error = qr/FSM::Extension::Registry expects dispatch context for 'after_parse_source' to be a FSM::Extension::Context object with matching stage/s;

{
    package Test::RegistryDispatchConstructedContextBoundaryExtension;

    use strict;
    use warnings;

    sub new {
        return bless {
            calls => [],
        }, shift;
    }

    sub after_parse_source {
        my ($self, $context) = @_;
        push @{$self->{calls}}, {
            stage => $context->stage,
            source_kind => $context->source_info->{kind},
        };
    }

    sub calls { return shift->{calls} }
}

subtest 'typed-extension manifests publish the constructed dispatch-context boundary' => sub {
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
        my $contract = $view->{contract};
        my $label = $view->{label};

        is(
            $contract->{extension_object_contract}{registry_dispatch_context_shape},
            $dispatch_context_shape,
            "$label advertises the constructed direct registry dispatch-context shape",
        );
        ok(
            contains_value($contract->{tested_by}, $audit_test),
            "$label lists this constructed dispatch-context audit in tested_by provenance",
        );
    }
};

subtest 'direct registry dispatch accepts constructed matching contexts' => sub {
    my $extension = Test::RegistryDispatchConstructedContextBoundaryExtension->new();
    my $registry = FSM::Extension::Registry->new(extensions => [$extension]);

    $registry->dispatch_hook('after_parse_source', make_context(
        stage => 'after_parse_source',
    ));

    is_deeply(
        $extension->calls,
        [
            {
                stage => 'after_parse_source',
                source_kind => 'fsm',
            },
        ],
        'constructed matching dispatch context reaches the supported extension hook',
    );
};

subtest 'direct registry dispatch rejects fake exact-class contexts before context accessor fallout' => sub {
    my @contexts = (
        {
            label => 'fake exact-class hash object',
            value => bless(
                {
                    stage => 'after_parse_source',
                    source_info => {
                        kind => 'fsm',
                    },
                },
                'FSM::Extension::Context',
            ),
        },
        {
            label => 'fake exact-class array object',
            value => bless([], 'FSM::Extension::Context'),
        },
    );

    for my $case (@contexts) {
        my $extension = Test::RegistryDispatchConstructedContextBoundaryExtension->new();
        my $registry = FSM::Extension::Registry->new(extensions => [$extension]);
        my $error = capture_exception(sub {
            $registry->dispatch_hook('after_parse_source', $case->{value});
        });

        like(
            $error,
            $dispatch_context_error,
            "$case->{label} receives the targeted registry dispatch-context diagnostic",
        );
        is_deeply(
            $extension->calls,
            [],
            "$case->{label} is rejected before extension invocation",
        );
        unlike(
            primary_diagnostic($error),
            qr/FSM::Extension::Context::stage requires|HASH\(|ARRAY\(|Can't locate object method|Can't use/s,
            "$case->{label} does not leak context accessor or raw receiver fallout",
        );
    }
};

subtest 'constructed mismatched contexts still fail at the stage-match boundary' => sub {
    my $registry = FSM::Extension::Registry->new(
        extensions => [Test::RegistryDispatchConstructedContextBoundaryExtension->new()],
    );
    my $error = capture_exception(sub {
        $registry->dispatch_hook('after_parse_source', make_context(
            stage => 'after_generate_result',
        ));
    });

    like(
        $error,
        $dispatch_context_error,
        'constructed context with mismatched stage receives the registry dispatch-context diagnostic',
    );
    unlike(
        primary_diagnostic($error),
        qr/FSM::Extension::Context::stage requires|HASH\(|ARRAY\(|Can't locate object method|Can't use/s,
        'constructed mismatched context does not leak context accessor or raw receiver fallout',
    );
};

done_testing();

sub make_context {
    my (%args) = @_;
    my @stage_payload = $args{stage} eq 'after_generate_result'
        ? (
            result => {
                module_info => {
                    module_name => 'registry_dispatch_constructed_context_boundary',
                },
            },
        )
        : (
            raw_ast => [],
        );

    return FSM::Extension::Context->new(
        stage => $args{stage},
        pipeline => bless({}, 'Test::RegistryDispatchConstructedContextBoundaryPipeline'),
        source_path => 'fixtures/registry_dispatch_constructed_context_boundary.fsm',
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
