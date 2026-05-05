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
use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::ExtensionContract qw(build_extension_contract);

my $audit_test = 't/424-typed-extension-context-constructor-payload-boundary-audit.t';
my $stage_shape = 'supported hook stage name';
my $common_payload_shape = 'blessed pipeline object, scalar non-empty source_path, scalar non-empty target_language, and source_info hash with scalar non-empty kind';
my $stage_payload_shape = 'after_parse_source requires raw_ast ARRAY and no result; after_generate_result requires result HASH and no raw_ast';

subtest 'typed-extension manifests publish the context constructor payload boundary' => sub {
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
            $contract->{context_contract}{constructor_stage_shape},
            $stage_shape,
            "$label advertises the context constructor stage shape",
        );
        is(
            $contract->{context_contract}{constructor_common_payload_shape},
            $common_payload_shape,
            "$label advertises the context constructor common payload shape",
        );
        is(
            $contract->{context_contract}{constructor_stage_payload_shape},
            $stage_payload_shape,
            "$label advertises the context constructor stage payload shape",
        );
        ok(
            contains_value($contract->{tested_by}, $audit_test),
            "$label lists this context-payload audit in tested_by provenance",
        );
    }
};

subtest 'context construction accepts valid parse and result payloads' => sub {
    my $parse_context = FSM::Extension::Context->new(context_args(base => 'parse'));
    isa_ok($parse_context, 'FSM::Extension::Context');
    is($parse_context->stage, 'after_parse_source', 'parse context preserves stage');
    is(ref($parse_context->pipeline), 'Test::ContextConstructorPayloadBoundaryPipeline', 'parse context preserves pipeline object');
    is($parse_context->source_path, '/tmp/context_constructor_payload_boundary.fsm', 'parse context preserves source path');
    is($parse_context->target_language, 'systemverilog', 'parse context preserves target language');
    is($parse_context->source_info->{kind}, 'fsm', 'parse context preserves source kind');
    is(ref($parse_context->raw_ast), 'ARRAY', 'parse context carries raw_ast array');
    is($parse_context->result, undef, 'parse context leaves result absent');

    my $dt_context = FSM::Extension::Context->new(
        context_args(
            base => 'parse',
            set => {
                source_info => {
                    kind => 'dt',
                },
            },
        ),
    );
    is($dt_context->source_info->{kind}, 'dt', 'parse context accepts the live dt source kind');

    my $result_context = FSM::Extension::Context->new(context_args(base => 'result'));
    isa_ok($result_context, 'FSM::Extension::Context');
    is($result_context->stage, 'after_generate_result', 'result context preserves stage');
    is($result_context->source_info->{kind}, 'composition', 'result context preserves composition source kind');
    is($result_context->raw_ast, undef, 'result context leaves raw_ast absent');
    is(ref($result_context->result), 'HASH', 'result context carries result hash');
    is(
        $result_context->result->{module_info}{module_name},
        'context_constructor_payload_boundary',
        'result context preserves generated module result',
    );
};

subtest 'context constructor rejects malformed common payload values' => sub {
    for my $case (
        {
            label => 'undef stage',
            args => [context_args(base => 'parse', set => { stage => undef })],
            pattern => qr/FSM::Extension::Context constructor requires stage to be a supported hook name: after_parse_source, after_generate_result/s,
        },
        {
            label => 'unsupported stage',
            args => [context_args(base => 'parse', set => { stage => 'before_parse_source' })],
            pattern => qr/FSM::Extension::Context constructor requires stage to be a supported hook name: after_parse_source, after_generate_result/s,
        },
        {
            label => 'arrayref stage',
            args => [context_args(base => 'parse', set => { stage => [] })],
            pattern => qr/FSM::Extension::Context constructor requires stage to be a supported hook name/s,
        },
        {
            label => 'unblessed pipeline',
            args => [context_args(base => 'parse', set => { pipeline => {} })],
            pattern => qr/FSM::Extension::Context constructor requires pipeline to be a blessed object/s,
        },
        {
            label => 'blank source path',
            args => [context_args(base => 'parse', set => { source_path => '   ' })],
            pattern => qr/FSM::Extension::Context constructor requires source_path to be a scalar non-empty string/s,
        },
        {
            label => 'reference target language',
            args => [context_args(base => 'parse', set => { target_language => [] })],
            pattern => qr/FSM::Extension::Context constructor requires target_language to be a scalar non-empty string/s,
        },
        {
            label => 'non-hash source_info',
            args => [context_args(base => 'parse', set => { source_info => [] })],
            pattern => qr/FSM::Extension::Context constructor requires source_info to be a hash reference/s,
        },
        {
            label => 'missing source kind',
            args => [context_args(base => 'parse', set => { source_info => {} })],
            pattern => qr/FSM::Extension::Context constructor requires source_info->\{kind\} to be a scalar non-empty source kind/s,
        },
        {
            label => 'blank source kind',
            args => [context_args(base => 'parse', set => { source_info => { kind => '   ' } })],
            pattern => qr/FSM::Extension::Context constructor requires source_info->\{kind\} to be a scalar non-empty source kind/s,
        },
        {
            label => 'reference source kind',
            args => [context_args(base => 'parse', set => { source_info => { kind => [] } })],
            pattern => qr/FSM::Extension::Context constructor requires source_info->\{kind\} to be a scalar non-empty source kind/s,
        },
    ) {
        assert_rejected($case);
    }
};

subtest 'context constructor rejects malformed stage-specific payload values' => sub {
    for my $case (
        {
            label => 'parse context missing raw_ast',
            args => [context_args(base => 'parse', omit => ['raw_ast'])],
            pattern => qr/FSM::Extension::Context constructor requires raw_ast to be an array reference for after_parse_source/s,
        },
        {
            label => 'parse context hash raw_ast',
            args => [context_args(base => 'parse', set => { raw_ast => {} })],
            pattern => qr/FSM::Extension::Context constructor requires raw_ast to be an array reference for after_parse_source/s,
        },
        {
            label => 'parse context with result',
            args => [context_args(base => 'parse', set => { result => {} })],
            pattern => qr/FSM::Extension::Context constructor does not accept result for after_parse_source contexts/s,
        },
        {
            label => 'result context missing result',
            args => [context_args(base => 'result', omit => ['result'])],
            pattern => qr/FSM::Extension::Context constructor requires result to be a hash reference for after_generate_result/s,
        },
        {
            label => 'result context array result',
            args => [context_args(base => 'result', set => { result => [] })],
            pattern => qr/FSM::Extension::Context constructor requires result to be a hash reference for after_generate_result/s,
        },
        {
            label => 'result context with raw_ast',
            args => [context_args(base => 'result', set => { raw_ast => [] })],
            pattern => qr/FSM::Extension::Context constructor does not accept raw_ast for after_generate_result contexts/s,
        },
    ) {
        assert_rejected($case);
    }
};

done_testing();

sub assert_rejected {
    my ($case) = @_;
    my $error = capture_exception(sub {
        FSM::Extension::Context->new(@{$case->{args}});
    });

    like(
        $error,
        $case->{pattern},
        "$case->{label} receives the targeted context-payload diagnostic",
    );
    unlike(
        primary_diagnostic($error),
        qr/Can't use|Can't locate object method|Not a HASH|HASH\(|ARRAY\(|\bbless\b/s,
        "$case->{label} does not leak raw context payload fallout",
    );
}

sub context_args {
    my (%spec) = @_;
    my %args = $spec{base} && $spec{base} eq 'result'
        ? result_context_args()
        : parse_context_args();

    for my $option_name (@{$spec{omit} || []}) {
        delete $args{$option_name};
    }

    my $set = $spec{set} || {};
    for my $option_name (keys %{$set}) {
        $args{$option_name} = $set->{$option_name};
    }

    return %args;
}

sub parse_context_args {
    return (
        stage => 'after_parse_source',
        common_context_args(),
        source_info => {
            kind => 'fsm',
        },
        raw_ast => [],
    );
}

sub result_context_args {
    return (
        stage => 'after_generate_result',
        common_context_args(),
        source_info => {
            kind => 'composition',
        },
        result => {
            module_info => {
                module_name => 'context_constructor_payload_boundary',
            },
        },
    );
}

sub common_context_args {
    return (
        pipeline => bless({}, 'Test::ContextConstructorPayloadBoundaryPipeline'),
        source_path => '/tmp/context_constructor_payload_boundary.fsm',
        target_language => 'systemverilog',
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
