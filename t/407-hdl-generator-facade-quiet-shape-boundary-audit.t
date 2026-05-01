#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP qw(decode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;
use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::HDLGeneratorFacadeContract qw(build_hdl_generator_facade_contract);

subtest 'manifests advertise quiet as a scalar boolean compatibility facade option' => sub {
    my @views = (
        {
            label => 'direct facade contract',
            facade => build_hdl_generator_facade_contract(),
        },
        {
            label => 'in-process capability manifest',
            facade => build_capability_manifest()->{embedding}{hdl_generator_facade},
        },
        {
            label => 'CLI capability manifest',
            facade => run_capability_manifest('--capability-manifest')
                ->{embedding}{hdl_generator_facade},
        },
        {
            label => 'CLI alias capability manifest',
            facade => run_capability_manifest('--emit-capability-manifest')
                ->{embedding}{hdl_generator_facade},
        },
    );

    for my $view (@views) {
        my $facade = $view->{facade};
        my $label = $view->{label};

        ok(
            contains_value($facade->{public_constructor_option_names}, 'quiet'),
            "$label advertises quiet as public",
        );
        ok(
            contains_value(
                $facade->{constructor_option_family_map}{compatibility_constructor_option_names},
                'quiet',
            ),
            "$label groups quiet with compatibility constructor options",
        );
        ok(
            !contains_value(
                $facade->{constructor_option_family_map}{core_constructor_option_names},
                'quiet',
            ),
            "$label keeps quiet out of core runtime constructor options",
        );
        is(
            $facade->{constructor_option_shape_map}{quiet},
            'boolean scalar 0 or 1',
            "$label advertises the quiet scalar boolean shape",
        );
    }
};

subtest 'HDLGenerator accepts and canonicalizes only scalar boolean quiet values' => sub {
    my $default_pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
    );
    is($default_pipeline->{quiet}, 0, 'omitted quiet defaults to canonical false');

    for my $case (
        {
            label => 'integer false',
            value => 0,
            expected => 0,
        },
        {
            label => 'integer true',
            value => 1,
            expected => 1,
        },
        {
            label => 'string false',
            value => '0',
            expected => 0,
        },
        {
            label => 'string true',
            value => '1',
            expected => 1,
        },
        {
            label => 'whitespace-padded string false',
            value => ' 0 ',
            expected => 0,
        },
        {
            label => 'whitespace-padded string true',
            value => ' 1 ',
            expected => 1,
        },
    ) {
        my $pipeline = eval {
            FSM::Pipeline::HDLGenerator->new(
                debug_level => 0,
                target_language => 'systemverilog',
                strict_mode => 0,
                quiet => $case->{value},
            );
        };
        my $error = $@;

        ok($pipeline, "$case->{label} quiet constructs a facade object")
            or diag($error);
        is(
            $pipeline->{quiet},
            $case->{expected},
            "$case->{label} quiet is stored canonically",
        ) if $pipeline;
    }
};

subtest 'HDLGenerator rejects non-boolean quiet values before generation setup continues' => sub {
    for my $case (
        {
            label => 'negative integer',
            value => -1,
        },
        {
            label => 'above-range integer',
            value => 2,
        },
        {
            label => 'multi-digit false-looking string',
            value => '00',
        },
        {
            label => 'multi-digit true-looking string',
            value => '01',
        },
        {
            label => 'true string',
            value => 'true',
        },
        {
            label => 'false string',
            value => 'false',
        },
        {
            label => 'empty string',
            value => '',
        },
        {
            label => 'arrayref',
            value => [1],
        },
        {
            label => 'hashref',
            value => { quiet => 1 },
        },
    ) {
        my $error = capture_exception(sub {
            FSM::Pipeline::HDLGenerator->new(
                debug_level => 0,
                target_language => 'systemverilog',
                strict_mode => 0,
                quiet => $case->{value},
            );
        });

        like(
            $error,
            qr/FSM::Pipeline::HDLGenerator expects 'quiet' to be a scalar boolean 0 or 1/s,
            "$case->{label} quiet receives the targeted facade diagnostic",
        );
        unlike(
            $error,
            qr/Source file:|Strict mode rejects|Unsupported target language/s,
            "$case->{label} quiet does not leak generation or backend diagnostics",
        );
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

sub contains_value {
    my ($values, $wanted) = @_;
    return 0 unless ref($values) eq 'ARRAY';

    for my $value (@{$values}) {
        return 1 if defined($value) && $value eq $wanted;
    }

    return 0;
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
