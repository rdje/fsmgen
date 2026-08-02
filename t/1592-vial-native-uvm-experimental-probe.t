#!/usr/bin/env perl

use v5.20;
use strict;
use warnings;

use File::Spec;
use FindBin;
use JSON::PP qw(decode_json);
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::Backend::SVUVMExperimentalProbe;

my $repo_root = File::Spec->rel2abs(File::Spec->catdir($FindBin::Bin, '..'));
my $evidence_rel = join '/', qw(
    vial experimental_probes
    sv_uvm_experimental.verilator_5_046.uvm_verilator_2020_3_1_vlt_656f20d0
    probe-report.json
);
my $report_text = _slurp($evidence_rel);
my $report = decode_json($report_text);

subtest 'selected profile is immutable and explicitly experimental' => sub {
    my $profile = FSM::VIAL::Backend::SVUVMExperimentalProbe->profile;
    is($profile->{id},
        'sv_uvm_experimental.verilator_5_046.uvm_verilator_2020_3_1_vlt_656f20d0',
        'profile identity names the exact tool and source variant');
    is($profile->{tool}{version_output},
        'Verilator 5.046 2026-02-28 rev vUNKNOWN-built20260228',
        'profile locks the exact tool version output');
    is($profile->{methodology}{canonical_accellera_commit},
        '78c06547a2a0a29b3dc9dcafae62b75b2ff61544',
        'profile retains the canonical Accellera release identity');
    is($profile->{source_variant}{commit},
        '656f20d087370a7c742e00188d20bbf30fa95339',
        'profile locks the Verilator-oriented UVM commit');
    is($profile->{source_variant}{tree},
        '882930bb7debe79b22234e4a8a53854549046778',
        'profile locks the Verilator-oriented UVM tree');
    is($profile->{source_variant}{unmodified_commit},
        'a457e9c40d5b7af89e4326a9ddab267476318f54',
        'profile records the unmodified comparison commit');
};

subtest 'diagnostic ownership separates generator defects and tool limitations' => sub {
    is(FSM::VIAL::Backend::SVUVMExperimentalProbe->classify_output(
            '%Error: generated.sv:13: syntax error, unexpected context'),
        'generator_defect', 'SystemVerilog syntax errors belong to the generator');
    is(FSM::VIAL::Backend::SVUVMExperimentalProbe->classify_output(
            '%Error-UNSUPPORTED: Unsupported: ## range cycle delay range expression'),
        'tool_limitation', 'unsupported ranged SVA belongs to the selected tool');
    is(FSM::VIAL::Backend::SVUVMExperimentalProbe->classify_output(
            '%Error: Verilator internal fault, sorry.'),
        'tool_limitation', 'selected-tool internal faults remain tool limitations');
    is(FSM::VIAL::Backend::SVUVMExperimentalProbe->classify_output(
            'ordinary nonzero tool diagnostic'),
        'tool_or_library', 'unclassified output is not mislabeled as a generator defect');
};

subtest 'probe invocation fails closed before tool execution' => sub {
    my $wrong_class = FSM::VIAL::Backend::SVUVMExperimentalProbe::run(
        'Wrong::Class', {});
    is($wrong_class->{diagnostics}[0]{code},
        'VIAL_UVM_PROBE_INVOCATION_ERROR', 'wrong class invocant is rejected');

    my $open = FSM::VIAL::Backend::SVUVMExperimentalProbe->run({
        repo_root => $repo_root,
        emission => {ok => 1, backend_profile => 'sv_uvm_emit.accellera_2020_3_1'},
        uvm_source_root => '.artifacts/cache/uvm-verilator/source',
        surprise => 1,
    });
    is($open->{diagnostics}[0]{code},
        'VIAL_UVM_PROBE_INVOCATION_ERROR', 'open invocation record is rejected');

    my $absolute = FSM::VIAL::Backend::SVUVMExperimentalProbe->run({
        repo_root => $repo_root,
        emission => {ok => 1, backend_profile => 'sv_uvm_emit.accellera_2020_3_1'},
        uvm_source_root => '/outside-repository/uvm',
    });
    is($absolute->{diagnostics}[0]{code},
        'VIAL_UVM_PROBE_PATH_ERROR', 'absolute UVM source path is rejected');
};

subtest 'checked report preserves independent honest stage outcomes' => sub {
    is($report->{schema}, 'fsmgen.vial_uvm_experimental_probe.v1',
        'report schema is exact');
    ok($report->{probe_completed}, 'probe workflow completed despite partial evidence');
    ok($report->{experimental}, 'report is explicitly experimental');
    ok(!$report->{product_support}, 'report explicitly denies product support');
    is($report->{qualification_status}, 'unqualified_experimental_evidence_only',
        'qualification state cannot be mistaken for supported runtime');
    is($report->{conclusion}, 'partial_tool_limited',
        'overall conclusion reports partial tool-limited evidence');

    my %stage = map { $_->{id} => $_ } @{$report->{stages}};
    my %expected = (
        tool_identity => ['passed', 'none'],
        uvm_library_preprocess => ['passed', 'none'],
        uvm_library_parse => ['passed', 'none'],
        uvm_library_compile_elaboration => ['passed', 'none'],
        uvm_library_runtime_smoke => ['passed', 'none'],
        generated_fixture_preprocess => ['passed', 'none'],
        generated_fixture_parse => ['unsupported', 'tool_limitation'],
        generated_fixture_compile_elaboration => ['failed', 'tool_limitation'],
        generated_fixture_runtime_smoke => ['not_run', 'prerequisite'],
    );
    is_deeply([sort keys %stage], [sort keys %expected],
        'report carries exactly the selected stage set');
    for my $id (sort keys %expected) {
        is_deeply([@{$stage{$id}}{qw(status owner)}], $expected{$id},
            "$id publishes its exact status and owner");
        is_deeply([sort keys %{$stage{$id}}], [sort qw(
            argv conclusion diagnostic_summary exit_code id output_limited
            output_sha256 owner status timed_out
        )], "$id is a closed stage record");
    }
    is($stage{generated_fixture_compile_elaboration}{exit_code}, 139,
        'fixture compile/elaboration records the selected-tool internal fault exit');
    is($report->{capabilities}{generated_fixture_runtime}, 'not_run',
        'fixture runtime remains unexercised');
    is($report->{capabilities}{normalized_result}, 'not_exercised',
        'normalized native-UVM result remains unexercised');
    is($report->{capabilities}{cross_backend_parity}, 'not_exercised',
        'native-UVM parity remains unexercised');
};

subtest 'report records bounded local commands and exact deviations' => sub {
    like($report->{source_identity}{repository_relative_root},
        qr{\A\.artifacts/cache/}, 'source cache is repository-relative');
    unlike($report_text,
        qr{(?:\A|["\s:])/[A-Za-z0-9]},
        'persisted report contains no host-absolute project path');
    is_deeply([map { $_->{id} } @{$report->{deviations}}],
        [qw(uvm_no_dpi bbox_unsupported)], 'only two explicit deviations are recorded');
    is($report->{resource_controls}{build_jobs}, 1,
        'single-job compilation is recorded');
    is($report->{resource_controls}{cxx_optimization}, 'O0',
        'memory-bounded C++ optimization setting is recorded');
    for my $stage (@{$report->{stages}}) {
        unlike(join("\0", @{$stage->{argv}}), qr{(?:\A|\0)(?:/|~)},
            "$stage->{id} argv contains no absolute or home-relative argument");
        like($stage->{output_sha256}, qr{\A[0-9a-f]{64}\z},
            "$stage->{id} has one normalized transcript digest");
    }
    is($report->{cleanup}{removed}, 1,
        'report attests exact staging cleanup');
};

subtest 'corrected generated gallery does not use reserved context identifier' => sub {
    my $gallery = join '/', qw(
        vial review_gallery sv_uvm_emit.accellera_2020_3_1
        ahb_base_output_foundation
    );
    my $components = _slurp("$gallery/fsmgen_vial_uvm_components_pkg.sv");
    my $fixture = _slurp("$gallery/base_output_arbitration_pkg.sv");
    unlike($components, qr/fsmgen_vial_execution_context\s+context\s*;/,
        'component foundations no longer declare the reserved identifier');
    unlike($fixture, qr/fsmgen_vial_execution_context\s+context\s*;/,
        'fixture package no longer declares the reserved identifier');
    unlike($fixture, qr/\bcontext\.(?:logical_time|plan_id|set_logical_time|transition_lifecycle)\b/,
        'fixture package no longer dereferences the reserved identifier');
    like($fixture, qr/fsmgen_vial_execution_context\s+vial_context\s*;/,
        'fixture package uses the explicit legal identifier');
};

done_testing;

sub _slurp {
    my ($relative) = @_;
    my $path = File::Spec->catfile($repo_root, split m{/}, $relative);
    open my $fh, '<:raw', $path or die "cannot read $relative: $!\n";
    local $/;
    my $text = <$fh>;
    close $fh or die "cannot close $relative: $!\n";
    return $text;
}
