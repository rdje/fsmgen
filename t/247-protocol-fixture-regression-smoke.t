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

        my $out_path = File::Spec->catfile($tempdir, "$case->{expected_module_name}.sv");
        my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
            command => ['./bin/fsmgen', '--quiet', '-o', $out_path, $path],
        );

        ok($success, "CLI compiles $filename");
        ok(-e $out_path, "CLI emits HDL for $filename");
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

    my $out_path = File::Spec->catfile($tempdir, "$case->{expected_top_name}.sv");
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '-o', $out_path, $composition_path],
    );

    ok($success, 'CLI compiles apb_tb');
    ok(-e $out_path, 'CLI emits HDL for apb_tb');
};

done_testing();
