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
use FSM::Support::ExtensionContract qw(
    build_extension_contract
    extension_contract_context_accessors
);

my $audit_test = 't/433-typed-extension-context-accessor-argument-list-boundary-audit.t';
my $argument_list_shape = 'no payload arguments after the context invocant';

subtest 'typed-extension manifests publish the context accessor argument-list boundary' => sub {
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
        my $context_contract = $view->{contract}{context_contract} || {};
        my $label = $view->{label};

        is(
            $context_contract->{accessor_argument_list_shape},
            $argument_list_shape,
            "$label advertises the direct context accessor argument-list shape",
        );
        ok(
            contains_value($view->{contract}{tested_by}, $audit_test),
            "$label lists this context-accessor argument-list audit in tested_by provenance",
        );
    }
};

subtest 'direct context accessors accept no payload arguments' => sub {
    my $pipeline = bless({}, 'Test::ContextAccessorArgumentListBoundaryPipeline');
    my $context = make_context(
        stage => 'after_parse_source',
        pipeline => $pipeline,
        raw_ast => [],
    );

    is($context->stage, 'after_parse_source', 'stage accepts no payload arguments');
    is($context->pipeline, $pipeline, 'pipeline accepts no payload arguments');
    is($context->source_path, 'fixtures/context_accessor_argument_list_boundary.fsm', 'source_path accepts no payload arguments');
    is($context->target_language, 'systemverilog', 'target_language accepts no payload arguments');
    is_deeply($context->source_info, {kind => 'fsm'}, 'source_info accepts no payload arguments');
    is_deeply($context->raw_ast, [], 'raw_ast accepts no payload arguments');
    is($context->result, undef, 'result accepts no payload arguments');
};

subtest 'direct context accessors reject payload arguments before raw signature fallout' => sub {
    my $context = make_context(
        stage => 'after_generate_result',
        result => {
            module_info => {
                module_name => 'context_accessor_argument_list_boundary',
            },
        },
    );

    for my $accessor (@{extension_contract_context_accessors()}) {
        my $error = capture_exception(sub {
            $context->$accessor('unexpected_payload');
        });

        like(
            $error,
            qr/FSM::Extension::Context::\Q$accessor\E expects no payload arguments after the context invocant/s,
            "$accessor rejects payload arguments with the targeted diagnostic",
        );
        unlike(
            primary_diagnostic($error),
            qr/Too many arguments|HASH\(|ARRAY\(|Can't locate object method|Can't use/s,
            "$accessor payload arguments do not leak raw signature or receiver fallout",
        );
    }
};

subtest 'malformed receivers still fail at the receiver boundary before argument counts' => sub {
    my $error = capture_exception(sub {
        'FSM::Extension::Context'->stage('unexpected_payload');
    });

    like(
        $error,
        qr/FSM::Extension::Context::stage requires an exact FSM::Extension::Context object constructed by new\(\.\.\.\)/s,
        'class receiver with a payload still receives the receiver diagnostic first',
    );
    unlike(
        primary_diagnostic($error),
        qr/expects no payload arguments|Too many arguments/s,
        'class receiver with a payload is not misclassified as an argument-count failure',
    );
};

done_testing();

sub make_context {
    my (%args) = @_;

    return FSM::Extension::Context->new(
        stage => $args{stage},
        pipeline => $args{pipeline} || bless({}, 'Test::ContextAccessorArgumentListBoundaryPipeline'),
        source_path => 'fixtures/context_accessor_argument_list_boundary.fsm',
        target_language => 'systemverilog',
        source_info => {
            kind => 'fsm',
        },
        exists($args{raw_ast}) ? (raw_ast => $args{raw_ast}) : (),
        exists($args{result}) ? (result => $args{result}) : (),
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
