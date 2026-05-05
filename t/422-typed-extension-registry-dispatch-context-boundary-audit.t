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

my $audit_test = 't/422-typed-extension-registry-dispatch-context-boundary-audit.t';
my $dispatch_context_shape = 'FSM::Extension::Context object whose stage matches the dispatched hook name';
my $dispatch_context_error = qr/FSM::Extension::Registry expects dispatch context for 'after_parse_source' to be a FSM::Extension::Context object with matching stage/s;

{
    package Test::RegistryDispatchContextBoundaryExtension;

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

{
    package Test::RegistryDispatchContextBoundaryFakeContext;

    use strict;
    use warnings;

    sub new {
        my ($class, %args) = @_;
        return bless \%args, $class;
    }

    sub stage { return shift->{stage} }
    sub source_info { return shift->{source_info} }
}

subtest 'typed-extension manifests publish the registry dispatch context shape' => sub {
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
            "$label advertises the direct registry dispatch context shape",
        );
        ok(
            contains_value($contract->{tested_by}, $audit_test),
            "$label lists this dispatch-context audit in tested_by provenance",
        );
    }
};

subtest 'direct registry dispatch still accepts a matching typed context' => sub {
    my $extension = Test::RegistryDispatchContextBoundaryExtension->new();
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
        'matching typed dispatch context reaches the supported extension hook',
    );
};

subtest 'direct registry dispatch rejects malformed contexts before extension invocation' => sub {
    for my $case (
        {
            label => 'undef context',
            context => undef,
        },
        {
            label => 'hashref context',
            context => {
                stage => 'after_parse_source',
            },
        },
        {
            label => 'fake context class',
            context => Test::RegistryDispatchContextBoundaryFakeContext->new(
                stage => 'after_parse_source',
                source_info => {
                    kind => 'fsm',
                },
            ),
        },
        {
            label => 'typed context with mismatched stage',
            context => make_context(
                stage => 'after_generate_result',
            ),
        },
    ) {
        my $extension = Test::RegistryDispatchContextBoundaryExtension->new();
        my $registry = FSM::Extension::Registry->new(extensions => [$extension]);
        my $error = capture_exception(sub {
            $registry->dispatch_hook('after_parse_source', $case->{context});
        });

        like(
            $error,
            $dispatch_context_error,
            "$case->{label} receives the targeted dispatch-context diagnostic",
        );
        is_deeply(
            $extension->calls,
            [],
            "$case->{label} is rejected before extension invocation",
        );
        unlike(
            primary_diagnostic($error),
            qr/Can't locate object method|Can't use .* as|HASH\(|ARRAY\(|source_info/s,
            "$case->{label} does not leak raw context or hook fallout",
        );
    }
};

done_testing();

sub make_context {
    my (%args) = @_;
    return FSM::Extension::Context->new(
        stage => $args{stage},
        pipeline => bless({}, 'Test::RegistryDispatchContextBoundaryPipeline'),
        source_path => '/tmp/registry_dispatch_context_boundary.fsm',
        target_language => 'systemverilog',
        source_info => {
            kind => 'fsm',
        },
        raw_ast => [],
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
