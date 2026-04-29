#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;
use FSM::Support::HDLGeneratorFacadeContract qw(
    build_hdl_generator_facade_contract
    hdl_generator_facade_public_constructor_option_names
);

my $repo_root = File::Spec->catdir($FindBin::Bin, '..');

subtest 'facade contract advertises target_language as a public constructor option' => sub {
    my $contract = build_hdl_generator_facade_contract();

    is(
        $contract->{default_target_language},
        'systemverilog',
        'facade contract records the default target language',
    );
    ok(
        contains_value(
            $contract->{public_constructor_option_names},
            'target_language',
        ),
        'emitted facade contract includes target_language in public constructor options',
    );
    ok(
        contains_value(
            hdl_generator_facade_public_constructor_option_names(),
            'target_language',
        ),
        'builder-owned public constructor list includes target_language',
    );
    ok(
        contains_value(
            $contract->{constructor_option_family_map}{core_constructor_option_names},
            'target_language',
        ),
        'grouped core constructor family includes target_language',
    );
};

subtest 'facade target_language option routes direct generated-module backend behavior' => sub {
    my $direct_path = repo_file('t/corpus/direct_sreset_active_high.fsm');

    my $default_pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        quiet => 1,
    );
    my $default_result = $default_pipeline->generate_hdl_from_file($direct_path);

    like(
        $default_result->{hdl_code},
        qr/\bmodule\s+direct_sreset_active_high\b/s,
        'default facade generation emits the expected direct module',
    );
    like(
        $default_result->{hdl_code},
        qr/\balways_ff\s*@\(posedge\s+clk\)/s,
        'default facade generation uses the SystemVerilog sequential block form',
    );
    like(
        $default_result->{hdl_code},
        qr/\balways_comb\s+begin/s,
        'default facade generation uses the SystemVerilog combinational block form',
    );

    my $verilog_pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'verilog',
        quiet => 1,
    );
    my $verilog_result = $verilog_pipeline->generate_hdl_from_file($direct_path);

    like(
        $verilog_result->{hdl_code},
        qr/\bmodule\s+direct_sreset_active_high\b/s,
        'explicit Verilog facade generation emits the same direct module',
    );
    like(
        $verilog_result->{hdl_code},
        qr/\balways\s*@\(posedge\s+clk\)\s+begin/s,
        'explicit Verilog facade generation uses the Verilog sequential block form',
    );
    like(
        $verilog_result->{hdl_code},
        qr/\balways\s*@\*\s+begin/s,
        'explicit Verilog facade generation uses the Verilog combinational block form',
    );
    unlike(
        $verilog_result->{hdl_code},
        qr/\balways_(?:ff|comb)\b/s,
        'explicit Verilog facade generation does not leak SystemVerilog always_* forms',
    );
};

subtest 'facade target_language option preserves the direct VHDL not-implemented boundary' => sub {
    my $direct_path = repo_file('t/corpus/direct_sreset_active_high.fsm');
    my $vhdl_pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'vhdl',
        quiet => 1,
    );

    my $error = capture_exception(sub {
        $vhdl_pipeline->generate_hdl_from_file($direct_path);
    });

    like(
        $error,
        qr/Source file:\s+'\Q$direct_path\E'/s,
        'direct VHDL facade failure keeps source-file context',
    );
    like(
        $error,
        qr/VHDL backend is not implemented yet/s,
        'direct VHDL facade failure preserves the backend not-implemented boundary',
    );
    like(
        $error,
        qr/Use --language systemverilog or --language verilog/s,
        'direct VHDL facade failure keeps the actionable target-language hint',
    );
};

done_testing();

sub repo_file {
    my ($relpath) = @_;
    return File::Spec->catfile($repo_root, split m{/}, $relpath);
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
