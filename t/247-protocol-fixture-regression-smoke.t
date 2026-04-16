#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use IPC::Cmd qw(run);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use lib File::Spec->catdir($FindBin::Bin, 'lib');

use FSM::Pipeline::HDLGenerator;
use FSM::Composition::Plan;
use FSM::Test::RegressionCorpus qw(protocol_fixture_entries);

my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $tempdir = tempdir(CLEANUP => 1);

subtest 'protocol requester/completer fixtures compile as direct roots' => sub {
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug_level => 0,
        quiet => 1,
    );

    for my $case (grep { $_->{coverage} eq 'direct_root_pipeline_cli' } protocol_fixture_entries()) {
        my $filename = $case->{relpath};
        $filename =~ s{\A.*/}{};
        my $path = File::Spec->catfile($repo_root, split m{/}, $case->{relpath});
        my $result = $pipeline->generate_hdl_from_file($path);

        is($result->{source_info}{kind}, $case->{source_kind}, "$filename keeps the expected source kind");
        like($result->{hdl_code}, qr/\bmodule\s+\Q$case->{expected_module_name}\E\b/s, "$filename generates module $case->{expected_module_name}");
        like($result->{hdl_code}, qr/\binput\s+(?:wire\s+)?rst_n\b/s, "$filename exposes canonical active-low async reset rst_n");

        my $out_path = File::Spec->catfile($tempdir, "$case->{expected_module_name}.sv");
        my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
            command => ['./bin/fsmgen', '--quiet', '-o', $out_path, $path],
        );

        ok($success, "CLI compiles $filename");
        ok(-e $out_path, "CLI emits HDL for $filename");
    }
};

subtest 'strict-supported protocol direct fixtures compile in strict mode' => sub {
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug_level => 0,
        quiet => 1,
        strict_mode => 1,
    );

    my @strict_cases = grep {
        $_->{coverage} eq 'direct_root_pipeline_cli'
            && $_->{strict_supported}
    } protocol_fixture_entries();

    ok(@strict_cases, 'protocol catalog records strict-supported direct fixtures');

    for my $case (@strict_cases) {
        my $filename = $case->{relpath};
        $filename =~ s{\A.*/}{};
        my $path = File::Spec->catfile($repo_root, split m{/}, $case->{relpath});
        my $result = $pipeline->generate_hdl_from_file($path);

        is($result->{source_info}{kind}, $case->{source_kind}, "$filename keeps the expected source kind in strict mode");
        like($result->{hdl_code}, qr/\bmodule\s+\Q$case->{expected_module_name}\E\b/s, "$filename generates module $case->{expected_module_name} in strict mode");
        like($result->{hdl_code}, qr/\binput\s+(?:wire\s+)?rst_n\b/s, "$filename exposes canonical active-low async reset rst_n in strict mode");

        my $out_path = File::Spec->catfile($tempdir, "$case->{expected_module_name}.strict.sv");
        my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
            command => ['./bin/fsmgen', '--strict', '--quiet', '-o', $out_path, $path],
        );

        ok($success, "CLI strict mode compiles $filename");
        ok(-e $out_path, "CLI strict mode emits HDL for $filename");
    }
};

subtest 'apb protocol top fixture compiles as a composed regression seed' => sub {
    my ($case) = grep { $_->{coverage} eq 'composition_top_pipeline_cli' } protocol_fixture_entries();
    my $composition_path = File::Spec->catfile($repo_root, split m{/}, $case->{relpath});

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug_level => 0,
        quiet => 1,
    );
    my $result = $pipeline->generate_hdl_from_file($composition_path);

    isa_ok($result->{composition_plan}, 'FSM::Composition::Plan');
    is($result->{source_info}{kind}, $case->{source_kind}, 'apb_tb is classified as a composition source');
    is($result->{composition_plan}->top_name, $case->{expected_top_name}, 'composition plan preserves the APB top name');
    is($result->{composition_plan}->lane, $case->{expected_lane}, 'apb_tb exercises the live generated-child composition lane');
    is(scalar(@{$result->{composition_plan}->instances || []}), $case->{expected_instance_count}, 'apb_tb realizes the expected generated children');

    my $hdl = $result->{hdl_code};
    for my $child_module (@{$case->{expected_child_modules}}) {
        like($hdl, qr/\bmodule\s+\Q$child_module\E\b/s, "generated HDL includes child module $child_module");
    }
    like($hdl, qr/\bmodule\s+\Q$case->{expected_top_name}\E\b/s, 'generated HDL includes the APB top module');
    like($hdl, qr/\binput\s+rst_n\b/s, 'generated APB top exposes canonical rst_n');
    like($hdl, qr/\.rst_n\(rst_n\)/s, 'generated APB top wires child resets by canonical rst_n');

    my $out_path = File::Spec->catfile($tempdir, "$case->{expected_top_name}.sv");
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '-o', $out_path, $composition_path],
    );

    ok($success, 'CLI compiles apb_tb');
    ok(-e $out_path, 'CLI emits HDL for apb_tb');
};

subtest 'strict-supported apb protocol top fixture compiles in strict mode' => sub {
    my ($case) = grep {
        $_->{coverage} eq 'composition_top_pipeline_cli'
            && $_->{strict_supported}
    } protocol_fixture_entries();
    ok($case, 'protocol catalog marks the APB composition top strict-supported');

    my $composition_path = File::Spec->catfile($repo_root, split m{/}, $case->{relpath});

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug_level => 0,
        quiet => 1,
        strict_mode => 1,
    );
    my $result = $pipeline->generate_hdl_from_file($composition_path);

    isa_ok($result->{composition_plan}, 'FSM::Composition::Plan');
    is($result->{source_info}{kind}, $case->{source_kind}, 'apb_tb is classified as a composition source in strict mode');
    is($result->{composition_plan}->top_name, $case->{expected_top_name}, 'strict composition plan preserves the APB top name');
    is($result->{composition_plan}->lane, $case->{expected_lane}, 'strict apb_tb keeps the generated-child composition lane');
    is(scalar(@{$result->{composition_plan}->instances || []}), $case->{expected_instance_count}, 'strict apb_tb realizes the expected generated children');

    my $hdl = $result->{hdl_code};
    for my $child_module (@{$case->{expected_child_modules}}) {
        like($hdl, qr/\bmodule\s+\Q$child_module\E\b/s, "strict generated HDL includes child module $child_module");
    }
    like($hdl, qr/\bmodule\s+\Q$case->{expected_top_name}\E\b/s, 'strict generated HDL includes the APB top module');
    like($hdl, qr/\binput\s+rst_n\b/s, 'strict generated APB top exposes canonical rst_n');
    like($hdl, qr/\.rst_n\(rst_n\)/s, 'strict generated APB top wires child resets by canonical rst_n');

    my $out_path = File::Spec->catfile($tempdir, "$case->{expected_top_name}.strict.sv");
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--quiet', '-o', $out_path, $composition_path],
    );

    ok($success, 'CLI strict mode compiles apb_tb');
    ok(-e $out_path, 'CLI strict mode emits HDL for apb_tb');
};

done_testing();
