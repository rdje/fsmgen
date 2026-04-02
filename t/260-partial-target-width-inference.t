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

subtest 'slice bounds alone infer base widths for partial writes without +size' => sub {
    my $fsm_module = parse_fsm_module(
        'partial_slice_inferred_width_contract',
        <<'FSM'
(?fsm:partial_slice_inferred_width_contract
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+size
    (COND 1)
  )
  (idle
    (<COND
      (OUT[3:2] = 2'b10)
      (OUT[1] = 1'b1)
      (OUT[0] = 1'b0)
      (ROD[3:2] <-= 2'b10)
      (ROD[1] <-= 1'b1)
      (ROD[0] <-= 1'b0)
      (RID[3:2] <=+ 2'b10)
      (RID[1] <=+ 1'b1)
      (RID[0] <=+ 1'b0)
    )
  )
)
FSM
    );

    my $hdl_gen = FSM::HDL::FlattenedDT->new(debug => 0);
    my $hdl = $hdl_gen->generate_systemverilog($fsm_module);
    my $module_plan = $hdl_gen->{enable_graph_module_planning_support}->build_module_declaration_plan($fsm_module);
    my %module_output_by_name = map { $_->{name} => $_ } @{$module_plan->{outputs} || []};

    is($module_output_by_name{next_ROD}{width}, 4, 'slice-only partial <-= infers a 4-bit next_ROD output');
    is($module_output_by_name{RID_r}{width}, 4, 'slice-only partial <=+ infers a 4-bit RID_r output');

    like($hdl, qr/\breg\s+\[3:0\]\s+OUT;/s, 'slice-only partial = infers a 4-bit internal target');
    like($hdl, qr/\breg\s+\[3:0\]\s+ROD;/s, 'slice-only partial <-= infers a 4-bit internal target');
    like($hdl, qr/\breg\s+\[3:0\]\s+RID;/s, 'slice-only partial <=+ infers a 4-bit internal target');
    like($hdl, qr/\boutput\s+reg\s+\[3:0\]\s+next_ROD\b/s, 'slice-only partial <-= keeps full-width next_ROD output');
    like($hdl, qr/\boutput\s+reg\s+\[3:0\]\s+RID_r\b/s, 'slice-only partial <=+ keeps full-width RID_r output');
};

subtest 'indexed bounds alone infer base widths for partial writes without +size' => sub {
    my $fsm_module = parse_fsm_module(
        'partial_index_inferred_width_contract',
        <<'FSM'
(?fsm:partial_index_inferred_width_contract
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+size
    (COND 1)
  )
  (idle
    (<COND
      (IDXOUT[4] = 1'b1)
      (IDXOUT[0] = 1'b1)
      (IDXRO[4] <-= 1'b1)
      (IDXRO[0] <-= 1'b1)
      (IDXRI[4] <=+ 1'b1)
      (IDXRI[0] <=+ 1'b1)
    )
  )
)
FSM
    );

    my $hdl_gen = FSM::HDL::FlattenedDT->new(debug => 0);
    my $hdl = $hdl_gen->generate_systemverilog($fsm_module);
    my $module_plan = $hdl_gen->{enable_graph_module_planning_support}->build_module_declaration_plan($fsm_module);
    my %module_output_by_name = map { $_->{name} => $_ } @{$module_plan->{outputs} || []};

    is($module_output_by_name{next_IDXRO}{width}, 5, 'index-only partial <-= infers a 5-bit next_IDXRO output');
    is($module_output_by_name{IDXRI_r}{width}, 5, 'index-only partial <=+ infers a 5-bit IDXRI_r output');

    like($hdl, qr/\breg\s+\[4:0\]\s+IDXOUT;/s, 'index-only partial = infers a 5-bit internal target');
    like($hdl, qr/\breg\s+\[4:0\]\s+IDXRO;/s, 'index-only partial <-= infers a 5-bit internal target');
    like($hdl, qr/\breg\s+\[4:0\]\s+IDXRI;/s, 'index-only partial <=+ infers a 5-bit internal target');
    like($hdl, qr/\boutput\s+reg\s+\[4:0\]\s+next_IDXRO\b/s, 'index-only partial <-= keeps full-width next_IDXRO output');
    like($hdl, qr/\boutput\s+reg\s+\[4:0\]\s+IDXRI_r\b/s, 'index-only partial <=+ keeps full-width IDXRI_r output');
};

done_testing();

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
