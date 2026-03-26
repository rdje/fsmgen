#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::IR::IntentHIRBuilder;
use FSM::Pipeline::HDLGenerator;

subtest 'intent hir builder rebuilds the bounded direct-root semantic surface from a semantic module' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'intent_hir_builder_direct_root.fsm');

    write_file(
        $fsm_path,
        <<'FSM'
(?dt:intent_hir_builder_direct_root
  (-route
    (<trigger
      (serial_out> = 8'1)
    )
    (<!trigger
      (serial_out> = 8'0)
    )
  )
  (+size
    (trigger 1)
    (serial_out 8)
  )
)
FSM
    );

    my $pipeline_for_builder = new_pipeline();
    my $raw_ast = $pipeline_for_builder->parse_fsm_file($fsm_path);
    my $fsm_module = $pipeline_for_builder->create_fsm_module($raw_ast);
    my $rebuilt_intent_hir = FSM::IR::IntentHIRBuilder->build_from_fsm_module(
        fsm_module => $fsm_module,
    );

    my $pipeline_for_full = new_pipeline();
    my $result = $pipeline_for_full->generate_hdl_from_file($fsm_path);

    is_deeply(
        $rebuilt_intent_hir->as_hashref,
        $result->{intent_hir},
        'builder rebuilds the same bounded direct-root intent_hir surface as the pipeline',
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

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
