#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use IPC::Cmd qw(run);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;
use FSM::Composition::Plan;

my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $fsm_dir = File::Spec->catdir($repo_root, 'fsm');
my $tempdir = tempdir(CLEANUP => 1);

subtest 'protocol requester/completer fixtures compile as direct roots' => sub {
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug_level => 0,
        quiet => 1,
    );

    for my $case (
        ['apb_requester.fsm', 'fsm', 'apb_requester'],
        ['apb_completer.fsm', 'fsm', 'apb_completer'],
        ['amba_requester.fsm', 'fsm', 'amba_requester'],
    ) {
        my ($filename, $expected_kind, $module_name) = @$case;
        my $path = File::Spec->catfile($fsm_dir, $filename);
        my $result = $pipeline->generate_hdl_from_file($path);

        is($result->{source_info}{kind}, $expected_kind, "$filename keeps the expected source kind");
        like($result->{hdl_code}, qr/\bmodule\s+\Q$module_name\E\b/s, "$filename generates module $module_name");

        my $out_path = File::Spec->catfile($tempdir, "$module_name.sv");
        my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
            command => ['./bin/fsmgen', '--quiet', '-o', $out_path, $path],
        );

        ok($success, "CLI compiles $filename");
        ok(-e $out_path, "CLI emits HDL for $filename");
    }
};

subtest 'apb protocol top fixture compiles as a composed regression seed' => sub {
    my $composition_path = File::Spec->catfile($fsm_dir, 'apb_tb.fsm');

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug_level => 0,
        quiet => 1,
    );
    my $result = $pipeline->generate_hdl_from_file($composition_path);

    isa_ok($result->{composition_plan}, 'FSM::Composition::Plan');
    is($result->{source_info}{kind}, 'composition', 'apb_tb is classified as a composition source');
    is($result->{composition_plan}->top_name, 'apb_tb', 'composition plan preserves the APB top name');
    is($result->{composition_plan}->lane, 'C4', 'apb_tb exercises the live generated-child composition lane');
    is(scalar(@{$result->{composition_plan}->instances || []}), 2, 'apb_tb realizes two generated children');

    my $hdl = $result->{hdl_code};
    like($hdl, qr/\bmodule\s+apb_requester\b/s, 'generated HDL includes the APB requester module');
    like($hdl, qr/\bmodule\s+apb_completer\b/s, 'generated HDL includes the APB completer module');
    like($hdl, qr/\bmodule\s+apb_tb\b/s, 'generated HDL includes the APB top module');

    my $out_path = File::Spec->catfile($tempdir, 'apb_tb.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '-o', $out_path, $composition_path],
    );

    ok($success, 'CLI compiles apb_tb');
    ok(-e $out_path, 'CLI emits HDL for apb_tb');
};

done_testing();
