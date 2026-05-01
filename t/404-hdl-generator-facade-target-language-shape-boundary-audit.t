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
use FSM::Support::HDLGeneratorFacadeContract qw(
    build_hdl_generator_facade_contract
    hdl_generator_facade_target_language_names
);

my @target_language_names = qw(systemverilog sv verilog v vhdl);

subtest 'manifests advertise the facade target_language token family' => sub {
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

        is_deeply(
            $facade->{target_language_names},
            \@target_language_names,
            "$label advertises the accepted lower-case target-language tokens",
        );
        is_deeply(
            hdl_generator_facade_target_language_names(),
            \@target_language_names,
            "$label target language list stays builder-owned",
        );
        is(
            $facade->{constructor_option_shape_map}{target_language},
            'one of target_language_names',
            "$label advertises target_language as a bounded token choice",
        );
    }
};

subtest 'HDLGenerator accepts only advertised target_language tokens at construction' => sub {
    for my $target_language (@target_language_names) {
        my $pipeline = eval {
            FSM::Pipeline::HDLGenerator->new(
                debug_level => 0,
                target_language => $target_language,
                quiet => 1,
            );
        };
        my $error = $@;

        ok($pipeline, "constructor accepts target_language => $target_language")
            or diag($error);
        is(
            $pipeline->{target_language},
            $target_language,
            "constructor stores target_language => $target_language without rewriting it",
        ) if $pipeline;
    }
};

subtest 'HDLGenerator rejects unsupported target_language strings before backend selection' => sub {
    for my $target_language (qw(system-verilog SystemVerilog vhd unknown)) {
        my $error = capture_exception(sub {
            FSM::Pipeline::HDLGenerator->new(
                debug_level => 0,
                target_language => $target_language,
                quiet => 1,
            );
        });

        like(
            $error,
            qr/FSM::Pipeline::HDLGenerator expects 'target_language' to be one of: systemverilog, sv, verilog, v, vhdl/s,
            "unsupported target_language '$target_language' receives the targeted facade diagnostic",
        );
        unlike(
            $error,
            qr/generate_systemverilog|generate_verilog|generate_vhdl|StructuralRTLIR verilog-family emitter/s,
            "unsupported target_language '$target_language' does not reach backend selection",
        );
    }
};

subtest 'HDLGenerator rejects reference target_language values before backend selection' => sub {
    for my $case (
        {
            label => 'arrayref',
            value => ['systemverilog'],
        },
        {
            label => 'hashref',
            value => { language => 'systemverilog' },
        },
    ) {
        my $error = capture_exception(sub {
            FSM::Pipeline::HDLGenerator->new(
                debug_level => 0,
                target_language => $case->{value},
                quiet => 1,
            );
        });

        like(
            $error,
            qr/FSM::Pipeline::HDLGenerator expects 'target_language' to be a scalar string/s,
            "$case->{label} target_language receives a targeted scalar-string diagnostic",
        );
        unlike(
            $error,
            qr/generate_systemverilog|generate_verilog|generate_vhdl|StructuralRTLIR verilog-family emitter/s,
            "$case->{label} target_language does not reach backend selection",
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

sub capture_exception {
    my ($code) = @_;
    my $ok = eval {
        $code->();
        1;
    };

    return '' if $ok;
    return $@ || 'unknown error';
}
