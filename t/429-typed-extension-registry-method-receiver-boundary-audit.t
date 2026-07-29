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
    extension_contract_registry_method_names
);

my $audit_test = 't/429-typed-extension-registry-method-receiver-boundary-audit.t';
my $receiver_shape = 'exact hash-backed FSM::Extension::Registry object constructed by new(...)';

{
    package Test::RegistryMethodReceiverBoundaryExtension;

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

{
    package Test::RegistryMethodReceiverBoundarySubclass;

    use strict;
    use warnings;

    our @ISA = ('FSM::Extension::Registry');
}

subtest 'typed-extension manifests publish the registry method receiver boundary' => sub {
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
            $object_contract->{registry_method_receiver_shape},
            $receiver_shape,
            "$label advertises the direct registry method receiver shape",
        );
        is_deeply(
            sorted($object_contract->{registry_method_names}),
            sorted(extension_contract_registry_method_names()),
            "$label advertises the direct registry method names",
        );
        ok(
            contains_value($view->{contract}{tested_by}, $audit_test),
            "$label lists this registry-method receiver audit in tested_by provenance",
        );
    }
};

subtest 'direct registry methods accept only a constructed exact registry instance' => sub {
    my $extension = Test::RegistryMethodReceiverBoundaryExtension->new();
    my $registry = FSM::Extension::Registry->new(extensions => [$extension]);

    is_deeply(
        $registry->extensions,
        [$extension],
        'constructed registry exposes the accepted extension list',
    );

    $registry->dispatch_hook('after_parse_source', make_context(stage => 'after_parse_source'));
    $registry->after_generate_result(make_context(stage => 'after_generate_result'));

    is_deeply(
        $extension->parse_calls,
        ['after_parse_source'],
        'constructed registry dispatch_hook still invokes parse hooks',
    );
    is_deeply(
        $extension->result_calls,
        ['after_generate_result'],
        'constructed registry wrapper still invokes result hooks',
    );
};

subtest 'direct registry methods reject malformed receivers before payload diagnostics' => sub {
    my @receivers = (
        {
            label => 'class receiver',
            value => 'FSM::Extension::Registry',
        },
        {
            label => 'subclass object',
            value => bless({}, 'Test::RegistryMethodReceiverBoundarySubclass'),
        },
        {
            label => 'fake exact-class hash object',
            value => bless({extensions => []}, 'FSM::Extension::Registry'),
        },
        {
            label => 'fake exact-class array object',
            value => bless([], 'FSM::Extension::Registry'),
        },
    );
    my @methods = (
        {
            name => 'extensions',
            call => sub {
                my ($receiver) = @_;
                return $receiver->extensions();
            },
        },
        {
            name => 'dispatch_hook',
            call => sub {
                my ($receiver) = @_;
                return $receiver->dispatch_hook('', undef);
            },
        },
        {
            name => 'after_parse_source',
            call => sub {
                my ($receiver) = @_;
                return $receiver->after_parse_source(undef);
            },
        },
        {
            name => 'after_generate_result',
            call => sub {
                my ($receiver) = @_;
                return $receiver->after_generate_result(undef);
            },
        },
    );

    for my $method (@methods) {
        for my $receiver (@receivers) {
            my $error = capture_exception(sub {
                $method->{call}->($receiver->{value});
            });

            like(
                $error,
                qr/FSM::Extension::Registry::\Q$method->{name}\E requires an exact FSM::Extension::Registry object constructed by new\(\.\.\.\)/s,
                "$method->{name} rejects $receiver->{label} with the targeted receiver diagnostic",
            );
            unlike(
                primary_diagnostic($error),
                qr/requires a non-empty hook name|expects dispatch context|HASH\(|ARRAY\(|Can't locate object method|Can't use/s,
                "$method->{name} $receiver->{label} does not leak payload or raw receiver fallout",
            );
        }
    }
};

subtest 'constructed registry still preserves existing hook and context boundaries' => sub {
    my $registry = FSM::Extension::Registry->new(
        extensions => [Test::RegistryMethodReceiverBoundaryExtension->new()],
    );

    my $hook_error = capture_exception(sub {
        $registry->dispatch_hook('', make_context(stage => 'after_parse_source'));
    });
    like(
        $hook_error,
        qr/FSM::Extension::Registry requires a non-empty hook name/s,
        'constructed registry keeps the hook-name boundary after receiver validation',
    );

    my $context_error = capture_exception(sub {
        $registry->dispatch_hook('after_parse_source', undef);
    });
    like(
        $context_error,
        qr/FSM::Extension::Registry expects dispatch context for 'after_parse_source' to be a FSM::Extension::Context object with matching stage/s,
        'constructed registry keeps the dispatch-context boundary after receiver validation',
    );
};

done_testing();

sub make_context {
    my (%args) = @_;
    my @stage_payload = $args{stage} eq 'after_generate_result'
        ? (
            result => {
                module_info => {
                    module_name => 'registry_method_receiver_boundary',
                },
            },
        )
        : (
            raw_ast => [],
        );

    return FSM::Extension::Context->new(
        stage => $args{stage},
        pipeline => bless({}, 'Test::RegistryMethodReceiverBoundaryPipeline'),
        source_path => 'fixtures/registry_method_receiver_boundary.fsm',
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

sub sorted {
    my ($values) = @_;
    return [sort @{$values || []}];
}
