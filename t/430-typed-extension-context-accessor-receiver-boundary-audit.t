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

my $audit_test = 't/430-typed-extension-context-accessor-receiver-boundary-audit.t';
my $receiver_shape = 'exact hash-backed FSM::Extension::Context object constructed by new(...)';

{
    package Test::ContextAccessorReceiverBoundarySubclass;

    use strict;
    use warnings;

    our @ISA = ('FSM::Extension::Context');
}

subtest 'typed-extension manifests publish the context accessor receiver boundary' => sub {
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
            $context_contract->{accessor_receiver_shape},
            $receiver_shape,
            "$label advertises the direct context accessor receiver shape",
        );
        is_deeply(
            sorted($context_contract->{accessor_method_names}),
            sorted(extension_contract_context_accessors()),
            "$label advertises the direct context accessor method names",
        );
        ok(
            contains_value($view->{contract}{tested_by}, $audit_test),
            "$label lists this context-accessor receiver audit in tested_by provenance",
        );
    }
};

subtest 'direct context accessors accept only constructed exact context instances' => sub {
    my $pipeline = bless({}, 'Test::ContextAccessorReceiverBoundaryPipeline');
    my $context = FSM::Extension::Context->new(
        stage => 'after_parse_source',
        pipeline => $pipeline,
        source_path => '/tmp/context_accessor_receiver_boundary.fsm',
        target_language => 'systemverilog',
        source_info => {
            kind => 'fsm',
        },
        raw_ast => [],
    );

    is($context->stage, 'after_parse_source', 'constructed context returns stage');
    is($context->pipeline, $pipeline, 'constructed context returns pipeline');
    is($context->source_path, '/tmp/context_accessor_receiver_boundary.fsm', 'constructed context returns source_path');
    is($context->target_language, 'systemverilog', 'constructed context returns target_language');
    is_deeply($context->source_info, {kind => 'fsm'}, 'constructed context returns source_info');
    is_deeply($context->raw_ast, [], 'constructed parse context returns raw_ast');
    is($context->result, undef, 'constructed parse context returns undef result');
};

subtest 'direct context accessors reject malformed receivers before raw hash fallout' => sub {
    my @receivers = (
        {
            label => 'class receiver',
            value => 'FSM::Extension::Context',
        },
        {
            label => 'subclass object',
            value => bless({}, 'Test::ContextAccessorReceiverBoundarySubclass'),
        },
        {
            label => 'fake exact-class hash object',
            value => bless({stage => 'after_parse_source'}, 'FSM::Extension::Context'),
        },
        {
            label => 'fake exact-class array object',
            value => bless([], 'FSM::Extension::Context'),
        },
    );

    for my $accessor (@{extension_contract_context_accessors()}) {
        for my $receiver (@receivers) {
            my $error = capture_exception(sub {
                $receiver->{value}->$accessor();
            });

            like(
                $error,
                qr/FSM::Extension::Context::\Q$accessor\E requires an exact FSM::Extension::Context object constructed by new\(\.\.\.\)/s,
                "$accessor rejects $receiver->{label} with the targeted receiver diagnostic",
            );
            unlike(
                primary_diagnostic($error),
                qr/HASH\(|ARRAY\(|Can't locate object method|Can't use/s,
                "$accessor $receiver->{label} does not leak raw accessor fallout",
            );
        }
    }
};

done_testing();

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
