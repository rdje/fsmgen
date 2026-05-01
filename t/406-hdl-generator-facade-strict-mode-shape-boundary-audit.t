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

my $repo_root = File::Spec->catdir($FindBin::Bin, '..');

subtest 'manifests advertise strict_mode as a scalar boolean public facade option' => sub {
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
            contains_value($facade->{public_constructor_option_names}, 'strict_mode'),
            "$label advertises strict_mode as public",
        );
        ok(
            contains_value(
                $facade->{constructor_option_family_map}{core_constructor_option_names},
                'strict_mode',
            ),
            "$label groups strict_mode with core constructor options",
        );
        is(
            $facade->{constructor_option_shape_map}{strict_mode},
            'boolean scalar 0 or 1',
            "$label advertises the strict_mode scalar boolean shape",
        );
    }
};

subtest 'HDLGenerator accepts and canonicalizes only scalar boolean strict_mode values' => sub {
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
                quiet => 1,
                strict_mode => $case->{value},
            );
        };
        my $error = $@;

        ok($pipeline, "$case->{label} strict_mode constructs a facade object")
            or diag($error);
        is(
            $pipeline->{strict_mode},
            $case->{expected},
            "$case->{label} strict_mode is stored canonically",
        ) if $pipeline;
    }
};

subtest 'canonical false strict_mode values keep compatibility mode disabled' => sub {
    my $legacy_path = repo_file('t/corpus/legacy_infix_assignment.fsm');
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        quiet => 1,
        strict_mode => ' 0 ',
    );
    my $result = $pipeline->generate_hdl_from_file($legacy_path);

    like(
        $result->{hdl_code},
        qr/\bmodule\s+legacy_infix_assignment\b/s,
        'whitespace-padded false strict_mode does not trigger strict rejection through Perl truthiness',
    );
};

subtest 'HDLGenerator rejects non-boolean strict_mode values before strict-mode generation logic' => sub {
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
            value => { strict_mode => 1 },
        },
    ) {
        my $error = capture_exception(sub {
            FSM::Pipeline::HDLGenerator->new(
                debug_level => 0,
                target_language => 'systemverilog',
                quiet => 1,
                strict_mode => $case->{value},
            );
        });

        like(
            $error,
            qr/FSM::Pipeline::HDLGenerator expects 'strict_mode' to be a scalar boolean 0 or 1/s,
            "$case->{label} strict_mode receives the targeted facade diagnostic",
        );
        unlike(
            $error,
            qr/Strict mode rejects|Source file:|legacy_infix_assignment/s,
            "$case->{label} strict_mode does not reach strict-mode generation diagnostics",
        );
    }
};

done_testing();

sub repo_file {
    my ($relpath) = @_;
    return File::Spec->catfile($repo_root, split m{/}, $relpath);
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
