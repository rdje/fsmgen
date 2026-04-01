#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::HDL::FlattenedDT;
use FSM::Pipeline::SourceFrontend;

subtest 'partial dual-output writes keep full-width auxiliary outputs when sizes are declared first' => sub {
    my $fsm_module = parse_fsm_module(
        'partial_dual_output_lhs_assignment_lowering_contract',
        fsm_text_for_dual_partial_contract(size_before_state => 1),
    );

    assert_partial_dual_output_contract($fsm_module);
};

subtest 'partial dual-output writes keep full-width auxiliary outputs when sizes are declared later' => sub {
    my $fsm_module = parse_fsm_module(
        'partial_dual_output_lhs_assignment_lowering_contract_post_size',
        fsm_text_for_dual_partial_contract(size_before_state => 0),
    );

    assert_partial_dual_output_contract($fsm_module);
};

done_testing();

sub assert_partial_dual_output_contract {
    my ($fsm_module) = @_;

    my $hdl_gen = FSM::HDL::FlattenedDT->new(debug => 0);
    my $hdl = $hdl_gen->generate_systemverilog($fsm_module);
    my $module_plan = $hdl_gen->{enable_graph_module_planning_support}->build_module_declaration_plan($fsm_module);
    my %module_output_by_name = map { $_->{name} => $_ } @{$module_plan->{outputs} || []};

    is($module_output_by_name{next_ROD}{width}, 4, "module declaration plan keeps next_ROD full width for partial '<-=' writes");
    is($module_output_by_name{RID_r}{width}, 4, "module declaration plan keeps RID_r full width for partial '<=+' writes");

    like(
        $hdl,
        qr/\boutput\s+reg\s+\[3:0\]\s+next_ROD\b/s,
        "generated HDL exposes next_ROD as a full-width auxiliary output",
    );

    like(
        $hdl,
        qr/\boutput\s+reg\s+\[3:0\]\s+RID_r\b/s,
        "generated HDL exposes RID_r as a full-width auxiliary output",
    );

    like(
        $hdl,
        qr/\bROD_next\s*=\s*\{HI,\s*MID,\s*LO\};/s,
        "partial '<-=' writes assemble one full-width next-value expression",
    );

    like(
        $hdl,
        qr/\bRID\s*=\s*\{HI,\s*MID,\s*LO\};/s,
        "partial '<=+' writes assemble one full-width D-input expression",
    );

    like(
        $hdl,
        qr/\bnext_ROD\s*=\s*ROD_next;/s,
        "generated HDL still exposes the full-width next_ROD auxiliary output",
    );

    like(
        $hdl,
        qr/\bRID_r\s*=\s*RID_q;/s,
        "generated HDL still exposes the full-width RID_r auxiliary output",
    );
}

sub fsm_text_for_dual_partial_contract {
    my (%args) = @_;
    my $size_block = <<'FSM';
  (+size
    (COND 1)
    (HI 2)
    (MID 1)
    (LO 1)
    (ROD 4)
    (RID 4)
  )
FSM

    my $state_block = <<'FSM';
  (idle
    (<COND
      (ROD[3:2] <-= HI)
      (ROD[1] <-= MID)
      (ROD[0] <-= LO)
      (RID[3:2] <=+ HI)
      (RID[1] <=+ MID)
      (RID[0] <=+ LO)
    )
  )
FSM

    if ($args{size_before_state}) {
        return <<"FSM";
(?fsm:partial_dual_output_lhs_assignment_lowering_contract
  (+system
    (clock clk)
    (sreset rstn)
  )
$size_block
$state_block
)
FSM
    }

    return <<"FSM";
(?fsm:partial_dual_output_lhs_assignment_lowering_contract_post_size
  (+system
    (clock clk)
    (sreset rstn)
  )
$state_block
$size_block
)
FSM
}

sub parse_fsm_module {
    my ($basename, $fsm_text) = @_;
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, "$basename.fsm");

    write_file($fsm_path, $fsm_text);
    my $raw_ast = FSM::Pipeline::SourceFrontend->parse_fsm_file(
        fsm_file => $fsm_path,
        debug_level => 0,
    );
    return FSM::Pipeline::SourceFrontend->create_fsm_module(
        raw_ast => $raw_ast,
        debug_level => 0,
    );
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
