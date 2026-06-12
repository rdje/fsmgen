#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Backend::GeneratedModuleEmitter;
use FSM::IR::IntentHIRBuilder;
use FSM::Pipeline::GeneratedModuleInfoBuilder;
use FSM::Pipeline::SourceFrontend;
use FSM::Pipeline::HDLGenerator;

subtest 'generated module emitter rebuilds the bounded direct backend surface from a semantic module' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'generated_module_emitter_direct_root.fsm');

    write_file(
        $fsm_path,
        <<'FSM'
(?dt:generated_module_emitter_direct_root
  (+size
    (SEL 1)
    (A 8)
    (B 8)
    (OUT 8)
  )
  (-from_a
    (<SEL==1'b0
      (OUT = A)
    )
  )
  (-from_b
    (<SEL==1'b1
      (OUT = B)
    )
  )
)
FSM
    );

    my $raw_ast = FSM::Pipeline::SourceFrontend->parse_fsm_file(
        fsm_file => $fsm_path,
        debug_level => 0,
    );
    my $fsm_module = FSM::Pipeline::SourceFrontend->create_fsm_module(
        raw_ast => $raw_ast,
        debug_level => 0,
    );
    my $intent_hir = FSM::IR::IntentHIRBuilder->build_from_fsm_module(
        fsm_module => $fsm_module,
    );
    my $module_info = FSM::Pipeline::GeneratedModuleInfoBuilder->build_from_fsm_module(
        fsm_module => $fsm_module,
        intent_hir => $intent_hir,
    );

    my $backend_result = FSM::Backend::GeneratedModuleEmitter->emit_from_fsm_module(
        fsm_module => $fsm_module,
        target_language => 'systemverilog',
        debug_level => 0,
    );
    FSM::Pipeline::GeneratedModuleInfoBuilder->enrich_with_generated_analysis(
        module_info => $module_info,
        fsm_module => $fsm_module,
        target_language => 'systemverilog',
        hdl_generator => $backend_result->{hdl_generator},
    );
    my $rebuilt_hdl_code = FSM::Backend::GeneratedModuleEmitter->augment_with_standalone_dt_assertions(
        hdl_code => $backend_result->{hdl_code},
        module_info => $module_info,
        target_language => 'systemverilog',
    );

    my $pipeline_for_full = new_pipeline();
    my $result = $pipeline_for_full->generate_hdl_from_file($fsm_path);

    is(
        $backend_result->{generator_method},
        'generate_systemverilog',
        'emitter resolves the bounded direct backend method for the target language',
    );
    is_deeply(
        normalized_hdl_code($rebuilt_hdl_code),
        normalized_hdl_code($result->{hdl_code}),
        'emitter rebuilds the same bounded direct generated HDL surface as the pipeline',
    );
    is_deeply(
        $backend_result->{statistics},
        $result->{statistics},
        'emitter rebuilds the same bounded direct backend statistics surface as the pipeline',
    );
};

subtest 'generated module emitter reroutes a marked generated-enable block from StructuralRTLIR' => sub {
    my $hdl = join(
        '',
        "module sample;\n",
        "  // FSMGEN_STRUCTURAL_RTLIR_ENABLE_ASSIGNMENTS_BEGIN\n",
        "  assign stale_en = stale;\n",
        "  // FSMGEN_STRUCTURAL_RTLIR_ENABLE_ASSIGNMENTS_END\n",
        "endmodule\n",
    );

    my $rerouted = FSM::Backend::GeneratedModuleEmitter
        ->reroute_generated_enable_assignments_through_structural_rtl_ir(
            hdl_code => $hdl,
            target_language => 'systemverilog',
            structural_rtl_ir => {
                assignment_records => [
                    {
                        rendered => '  assign fresh_en = fresh;',
                        provenance => {
                            family => 'generated_enable',
                            role => 'top_state_enable',
                        },
                    },
                    {
                        rendered => '  assign final_en = fresh_en;',
                        provenance => {
                            family => 'generated_enable',
                            role => 'standalone_dt_enable',
                        },
                    },
                ],
            },
        );

    is(
        $rerouted,
        join(
            '',
            "module sample;\n",
            "  // State and DT Enable Conditions\n",
            "  assign fresh_en = fresh;\n",
            "  assign final_en = fresh_en;\n",
            "\n",
            "endmodule\n",
        ),
        'reroute helper replaces only the explicit marked block with StructuralRTLIR assignments',
    );

    my $error;
    eval {
        FSM::Backend::GeneratedModuleEmitter
            ->reroute_generated_enable_assignments_through_structural_rtl_ir(
                hdl_code => "module sample;\n  assign stale_en = stale;\nendmodule\n",
                target_language => 'systemverilog',
                structural_rtl_ir => {
                    assignment_records => [
                        {
                            rendered => '  assign fresh_en = fresh;',
                            provenance => {
                                family => 'generated_enable',
                                role => 'top_state_enable',
                            },
                        },
                    ],
                },
            );
        1;
    } or $error = $@;
    like(
        $error,
        qr/expected one marked block/,
        'reroute helper refuses to parse unmarked HDL text',
    );
};

done_testing();

sub new_pipeline {
    return FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        quiet => 1,
    );
}

sub normalized_hdl_code {
    my ($hdl_code) = @_;
    return '' unless defined $hdl_code && length $hdl_code;

    $hdl_code =~ s{// Date: .*}{// Date: <normalized>}g;
    $hdl_code =~ s{
        (//\s+Consolidated\ intermediate\ signals.*?\n)
        (.*?)
        (\n\s*//\s+Unified\ WEN/EN\ Signal\ Generation\ from\ Phase\ 1\ Analysis)
    }{
        my ($header, $body, $footer) = ($1, $2, $3);
        my @body_lines = grep { length($_) } split /\n/, $body;
        $header . join("\n", sort @body_lines) . $footer;
    }gsex;
    return $hdl_code;
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
