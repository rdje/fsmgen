#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Backend::GeneratedModuleEmitter;
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

    my $pipeline_for_builder = new_pipeline();
    my $raw_ast = $pipeline_for_builder->parse_fsm_file($fsm_path);
    my $fsm_module = $pipeline_for_builder->create_fsm_module($raw_ast);
    my $intent_hir = $pipeline_for_builder->build_intent_hir($fsm_module);
    my $module_info = $pipeline_for_builder->analyze_fsm_module($fsm_module, $intent_hir);

    my $backend_result = FSM::Backend::GeneratedModuleEmitter->emit_from_fsm_module(
        fsm_module => $fsm_module,
        target_language => 'systemverilog',
        debug_level => 0,
    );
    $pipeline_for_builder->{hdl_generator} = $backend_result->{hdl_generator};
    $pipeline_for_builder->enrich_module_info_from_generated_analysis($module_info, $fsm_module);
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
    return $hdl_code;
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
