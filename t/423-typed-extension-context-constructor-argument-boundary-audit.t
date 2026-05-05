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

my $audit_test = 't/423-typed-extension-context-constructor-argument-boundary-audit.t';
my $receiver_shape = 'scalar FSM::Extension::Context class name';
my $argument_shape = 'even-length list of unique scalar non-empty supported option-name/value pairs after class invocant';
my $receiver_error = qr/FSM::Extension::Context constructor receiver must be scalar FSM::Extension::Context class name/s;
my $odd_argument_error = qr/FSM::Extension::Context constructor arguments must be an even-length option\/value list/s;
my $option_name_error = qr/FSM::Extension::Context constructor option names must be scalar non-empty strings/s;

subtest 'typed-extension manifests publish the context constructor argument boundary' => sub {
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
            $contract->{context_contract}{constructor_receiver_shape},
            $receiver_shape,
            "$label advertises the context constructor receiver shape",
        );
        is(
            $contract->{context_contract}{constructor_argument_list_shape},
            $argument_shape,
            "$label advertises the context constructor argument-list shape",
        );
        is_deeply(
            sorted($contract->{context_contract}{constructor_supported_option_names}),
            sorted(extension_contract_context_accessors()),
            "$label context constructor options match the advertised context accessors",
        );
        ok(
            contains_value($contract->{tested_by}, $audit_test),
            "$label lists this context-constructor audit in tested_by provenance",
        );
    }
};

subtest 'context construction still accepts the supported option set' => sub {
    my $context = make_context();

    isa_ok($context, 'FSM::Extension::Context');
    is($context->stage, 'after_parse_source', 'constructed context preserves stage');
    is(ref($context->pipeline), 'Test::ContextConstructorBoundaryPipeline', 'constructed context preserves pipeline object');
    is($context->source_path, '/tmp/context_constructor_boundary.fsm', 'constructed context preserves source path');
    is($context->target_language, 'systemverilog', 'constructed context preserves target language');
    is($context->source_info->{kind}, 'fsm', 'constructed context preserves source info');
    is(ref($context->raw_ast), 'ARRAY', 'constructed context preserves raw AST');
    is($context->result, undef, 'constructed parse context leaves result absent');
};

subtest 'context constructor rejects malformed receivers before bless fallout' => sub {
    for my $case (
        {
            label => 'undef receiver',
            code => sub { FSM::Extension::Context::new(undef, valid_context_args()) },
        },
        {
            label => 'wrong class receiver',
            code => sub { FSM::Extension::Context::new('Test::NotExtensionContext', valid_context_args()) },
        },
        {
            label => 'hashref receiver',
            code => sub { FSM::Extension::Context::new({}, valid_context_args()) },
        },
        {
            label => 'object-method misuse',
            code => sub {
                my $context = make_context();
                return $context->new(valid_context_args());
            },
        },
    ) {
        my $error = capture_exception($case->{code});

        like(
            $error,
            $receiver_error,
            "$case->{label} receives the targeted receiver diagnostic",
        );
        unlike(
            primary_diagnostic($error),
            qr/bless|HASH\(|ARRAY\(|Can't use|Can't locate object method/s,
            "$case->{label} does not leak raw constructor fallout",
        );
    }
};

subtest 'context constructor rejects malformed argument lists and option names' => sub {
    my $odd_error = capture_exception(sub {
        FSM::Extension::Context->new(stage => 'after_parse_source', 'pipeline');
    });
    like(
        $odd_error,
        $odd_argument_error,
        'odd constructor argument list receives the targeted diagnostic',
    );
    unlike(
        primary_diagnostic($odd_error),
        qr/Odd number|HASH\(|ARRAY\(/s,
        'odd constructor argument list does not leak Perl hash coercion fallout',
    );

    for my $case (
        {
            label => 'undef option name',
            option_name => undef,
        },
        {
            label => 'empty option name',
            option_name => '',
        },
        {
            label => 'arrayref option name',
            option_name => [],
        },
        {
            label => 'hashref option name',
            option_name => {},
        },
    ) {
        my $error = capture_exception(sub {
            FSM::Extension::Context->new(
                $case->{option_name}, 'value',
                valid_context_args(),
            );
        });

        like(
            $error,
            $option_name_error,
            "$case->{label} receives the targeted option-name diagnostic",
        );
        unlike(
            primary_diagnostic($error),
            qr/HASH\(|ARRAY\(|Can't use|Use of uninitialized/s,
            "$case->{label} does not leak raw option-name fallout",
        );
    }
};

subtest 'context constructor rejects unsupported and duplicate option names' => sub {
    my $unsupported_error = capture_exception(sub {
        FSM::Extension::Context->new(
            valid_context_args(),
            config => {},
            diagnostics => {},
        );
    });
    like(
        $unsupported_error,
        qr/FSM::Extension::Context constructor rejects unsupported option name\(s\): config, diagnostics/s,
        'unsupported context constructor options receive the targeted diagnostic',
    );
    unlike(
        primary_diagnostic($unsupported_error),
        qr/HASH\(|ARRAY\(|Can't locate object method|bless/s,
        'unsupported context constructor options do not leak raw fallout',
    );

    my $duplicate_error = capture_exception(sub {
        FSM::Extension::Context->new(
            valid_context_args(),
            source_path => '/tmp/duplicate_path.fsm',
            stage => 'after_generate_result',
        );
    });
    like(
        $duplicate_error,
        qr/FSM::Extension::Context constructor rejects duplicate option name\(s\): source_path, stage/s,
        'duplicate context constructor options receive the targeted diagnostic',
    );
    unlike(
        primary_diagnostic($duplicate_error),
        qr/HASH\(|ARRAY\(|Can't locate object method|bless/s,
        'duplicate context constructor options do not leak raw fallout',
    );
};

done_testing();

sub make_context {
    return FSM::Extension::Context->new(valid_context_args());
}

sub valid_context_args {
    return (
        stage => 'after_parse_source',
        pipeline => bless({}, 'Test::ContextConstructorBoundaryPipeline'),
        source_path => '/tmp/context_constructor_boundary.fsm',
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

sub sorted {
    my ($values) = @_;
    return [sort @{$values || []}];
}
