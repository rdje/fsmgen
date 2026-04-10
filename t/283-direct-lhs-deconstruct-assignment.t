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

subtest 'direct LHS concat deconstruct lowers to ordinary partial assignments' => sub {
    my $fsm_module = parse_fsm_module(
        'direct_lhs_deconstruct_assignment_contract',
        <<'FSM'
(?fsm:direct_lhs_deconstruct_assignment_contract
  (+system
    (clock clk)
    (sreset rst)
  )
  (+size
    (COND 1)
    (DATA 8)
    (DATA2 8)
    (DATA3 8)
    (DATA4 8)
    (HI 4)
    (LO 4)
    (RO_HI 4)
    (RO_LO 4)
    (RI_HI 4)
    (RI_LO 4)
    (RD_HI 4)
    (RD_LO 4)
    (RQ_HI 4)
    (RQ_LO 4)
    (OUT 8)
  )
  (idle
    (<COND
      ((concat HI LO) = DATA)
      ((cat RO_HI RO_LO) <- DATA2)
      ((concat RI_HI RI_LO) <= DATA)
      ((concat RD_HI RD_LO) <-= DATA3)
      ((cat RQ_HI RQ_LO) <=+ DATA4)
      ((concat OUT[7:4] OUT[3:0]) = DATA)
    )
  )
)
FSM
    );

    my $hdl = FSM::HDL::FlattenedDT->new(debug => 0)->generate_systemverilog($fsm_module);

    like($hdl, qr/\bHI\s*=\s*DATA\[7:4\];/s, 'leftmost deconstruct operand receives the high RHS slice');
    like($hdl, qr/\bLO\s*=\s*DATA\[3:0\];/s, 'rightmost deconstruct operand receives the low RHS slice');
    like($hdl, qr/\bRO_HI_next\s*=\s*DATA2\[7:4\];/s, "cat alias supports '<-' register-out deconstruct");
    like($hdl, qr/\bRO_LO_next\s*=\s*DATA2\[3:0\];/s, "cat alias splits the low '<-' register-out fragment");
    like($hdl, qr/\bRI_HI\s*=\s*DATA\[7:4\];/s, "concat supports '<=' register-in deconstruct");
    like($hdl, qr/\bRI_LO\s*=\s*DATA\[3:0\];/s, "concat splits the low '<=' register-in fragment");
    like($hdl, qr/\bRD_HI_next\s*=\s*DATA3\[7:4\];/s, "concat supports '<-=' dual register-out deconstruct");
    like($hdl, qr/\bRD_LO_next\s*=\s*DATA3\[3:0\];/s, "concat splits the low '<-=' dual register-out fragment");
    like($hdl, qr/\bnext_RD_HI\s*=\s*RD_HI_next;/s, "dual register-out deconstruct exposes the high next output");
    like($hdl, qr/\bnext_RD_LO\s*=\s*RD_LO_next;/s, "dual register-out deconstruct exposes the low next output");
    like($hdl, qr/\bRQ_HI\s*=\s*DATA4\[7:4\];/s, "cat alias supports '<=+' dual register-in deconstruct");
    like($hdl, qr/\bRQ_LO\s*=\s*DATA4\[3:0\];/s, "cat alias splits the low '<=+' dual register-in fragment");
    like($hdl, qr/\bRQ_HI_r\s*=\s*RQ_HI_q;/s, "dual register-in deconstruct exposes the high q output");
    like($hdl, qr/\bRQ_LO_r\s*=\s*RQ_LO_q;/s, "dual register-in deconstruct exposes the low q output");
    like(
        $hdl,
        qr/\bOUT\s*=\s*\{DATA\[7:4\],\s*DATA\[3:0\]\};/s,
        'same-base sliced deconstruct fragments rejoin through existing partial-LHS normalization',
    );
};

subtest 'direct LHS concat deconstruct rejects ambiguous or unsafe contracts before generation' => sub {
    like(
        parse_failure(
            'direct_lhs_deconstruct_width_mismatch',
            <<'FSM'
(?fsm:direct_lhs_deconstruct_width_mismatch
  (+system
    (clock clk)
    (sreset rst)
  )
  (+size
    (DATA 7)
    (HI 4)
    (LO 4)
  )
  (idle
    ((concat HI LO) = DATA)
  )
)
FSM
        ),
        qr/LHS deconstruct total width 8 does not match RHS width 7/s,
        'deconstruct width mismatch is rejected before HDL generation',
    );

    like(
        parse_failure(
            'direct_lhs_deconstruct_overlap',
            <<'FSM'
(?fsm:direct_lhs_deconstruct_overlap
  (+system
    (clock clk)
    (sreset rst)
  )
  (+size
    (DATA 10)
    (OUT 8)
  )
  (idle
    ((concat OUT[7:4] OUT[5:0]) = DATA)
  )
)
FSM
        ),
        qr/overlaps an earlier write range on 'OUT'/s,
        'overlapping deconstruct target ranges are rejected before HDL generation',
    );

    like(
        parse_failure(
            'direct_lhs_deconstruct_non_lvalue',
            <<'FSM'
(?fsm:direct_lhs_deconstruct_non_lvalue
  (+system
    (clock clk)
    (sreset rst)
  )
  (+size
    (DATA 8)
    (HI 4)
  )
  (idle
    ((concat HI 4'b0000) = DATA)
  )
)
FSM
        ),
        qr/not a legal static writable LHS operand/s,
        'literal deconstruct operands are rejected as non-lvalues',
    );
};

subtest 'direct LHS concat deconstruct preserves aggregate RHS fragment contracts' => sub {
    my $compatible_fsm_module = parse_fsm_module(
        'direct_lhs_deconstruct_aggregate_fragment_contract',
        <<'FSM'
(?fsm:direct_lhs_deconstruct_aggregate_fragment_contract
  (+system
    (clock clk)
    (sreset rst)
  )
  (+constants
    (FRAME ((tag 4'b1010) (payload (1 2'b10))))
  )
  (+types
    (type payload_t (list bit (bits 2)))
    (type frame_t (record (tag (bits 4)) (payload payload_t)))
  )
  (+size
    (TAG 4)
    (PAYLOAD payload_t)
    (OUT frame_t)
  )
  (idle
    ((concat TAG PAYLOAD) = FRAME)
    ((concat OUT.tag OUT.payload) = FRAME)
  )
)
FSM
    );

    my $hdl = FSM::HDL::FlattenedDT->new(debug => 0)->generate_systemverilog($compatible_fsm_module);

    like($hdl, qr/\bTAG\s*=\s*\(7'b1010110\)\[6:3\];/s, 'aggregate deconstruct high fragment drives the scalar tag target');
    like($hdl, qr/\bPAYLOAD\s*=\s*\(7'b1010110\)\[2:0\];/s, 'aggregate deconstruct low fragment drives the compatible aggregate payload target');
    like(
        $hdl,
        qr/\bOUT\s*=\s*\{\(7'b1010110\)\[6:3\],\s*\(7'b1010110\)\[2:0\]\};/s,
        'same-base aggregate deconstruct fragments rejoin through partial aggregate LHS normalization',
    );

    like(
        generation_failure(
            'direct_lhs_deconstruct_bad_aggregate_fragment_contract',
            <<'FSM'
(?fsm:direct_lhs_deconstruct_bad_aggregate_fragment_contract
  (+system
    (clock clk)
    (sreset rst)
  )
  (+constants
    (BAD ((tag 4'b1010) (payload ((mode 2'b10) (flag 1)))))
  )
  (+types
    (type payload_t (list bit (bits 2)))
    (type frame_t (record (tag (bits 4)) (payload payload_t)))
  )
  (+size
    (TAG 4)
    (PAYLOAD payload_t)
  )
  (idle
    ((concat TAG PAYLOAD) = BAD)
  )
)
FSM
        ),
        qr/assignment to 'PAYLOAD' uses whole aggregate RHS 'BAD\[2:0\]' with contract 'record\{mode:bits\[2\], flag:bit\}' that does not match declared type 'list<bit, bits\[2\]>'/s,
        'aggregate deconstruct rejects incompatible typed source fragments against the target fragment contract',
    );

    my $typed_signal_fsm_module = parse_fsm_module(
        'direct_lhs_deconstruct_typed_signal_fragment_contract',
        <<'FSM'
(?fsm:direct_lhs_deconstruct_typed_signal_fragment_contract
  (+system
    (clock clk)
    (sreset rst)
  )
  (+types
    (type payload_t (list bit (bits 2)))
    (type frame_t (record (tag (bits 4)) (payload payload_t)))
  )
  (+size
    (IN_FRAME frame_t)
    (TAG 4)
    (PAYLOAD payload_t)
    (OUT frame_t)
  )
  (idle
    ((concat TAG PAYLOAD) = IN_FRAME)
    ((concat OUT.tag OUT.payload) = IN_FRAME)
  )
)
FSM
    );

    my $typed_signal_hdl = FSM::HDL::FlattenedDT->new(debug => 0)->generate_systemverilog($typed_signal_fsm_module);

    like($typed_signal_hdl, qr/\bTAG\s*=\s*IN_FRAME\[6:3\];/s, 'typed aggregate RHS signal high fragment drives the scalar tag target');
    like($typed_signal_hdl, qr/\bPAYLOAD\s*=\s*IN_FRAME\[2:0\];/s, 'typed aggregate RHS signal low fragment drives the compatible aggregate payload target');
    like(
        $typed_signal_hdl,
        qr/\bOUT\s*=\s*\{IN_FRAME\[6:3\],\s*IN_FRAME\[2:0\]\};/s,
        'typed aggregate RHS signal fragments rejoin through partial aggregate LHS normalization',
    );

    like(
        generation_failure(
            'direct_lhs_deconstruct_bad_typed_signal_fragment_contract',
            <<'FSM'
(?fsm:direct_lhs_deconstruct_bad_typed_signal_fragment_contract
  (+system
    (clock clk)
    (sreset rst)
  )
  (+types
    (type payload_t (list bit (bits 2)))
    (type bad_payload_t (record (mode (bits 2)) (flag bit)))
    (type bad_frame_t (record (tag (bits 4)) (payload bad_payload_t)))
  )
  (+size
    (BAD_FRAME bad_frame_t)
    (TAG 4)
    (PAYLOAD payload_t)
  )
  (idle
    ((concat TAG PAYLOAD) = BAD_FRAME)
  )
)
FSM
        ),
        qr/assignment to 'PAYLOAD' uses whole aggregate RHS 'BAD_FRAME\[2:0\]' with contract 'record\{mode:bits\[2\], flag:bit\}' that does not match declared type 'list<bit, bits\[2\]>'/s,
        'aggregate deconstruct rejects incompatible typed RHS signal fragments against the target fragment contract',
    );
};

subtest 'direct LHS concat deconstruct preserves aligned RHS concat operand contracts' => sub {
    my $compatible_fsm_module = parse_fsm_module(
        'direct_lhs_deconstruct_rhs_concat_operand_contract',
        <<'FSM'
(?fsm:direct_lhs_deconstruct_rhs_concat_operand_contract
  (+system
    (clock clk)
    (sreset rst)
  )
  (+types
    (type payload_t (list bit (bits 2)))
    (type frame_t (record (tag (bits 4)) (payload payload_t)))
  )
  (+size
    (TAG_IN 4)
    (GOOD_PAYLOAD payload_t)
    (TAG 4)
    (PAYLOAD payload_t)
    (OUT frame_t)
  )
  (idle
    ((concat TAG PAYLOAD) = (concat TAG_IN GOOD_PAYLOAD))
    ((concat OUT.tag OUT.payload) = (concat TAG_IN GOOD_PAYLOAD))
  )
)
FSM
    );

    my $hdl = FSM::HDL::FlattenedDT->new(debug => 0)->generate_systemverilog($compatible_fsm_module);

    like($hdl, qr/\bTAG\s*=\s*TAG_IN;/s, 'aligned RHS concat high operand drives the scalar target without selecting the whole concat');
    like($hdl, qr/\bPAYLOAD\s*=\s*GOOD_PAYLOAD;/s, 'aligned typed RHS concat aggregate operand drives the matching aggregate target directly');
    like(
        $hdl,
        qr/\bOUT\s*=\s*\{TAG_IN,\s*GOOD_PAYLOAD\};/s,
        'aligned RHS concat operands rejoin through partial aggregate LHS normalization without packed-blob part-selects',
    );
    unlike($hdl, qr/\(\{TAG_IN,\s*GOOD_PAYLOAD\}\)\[\d+(?::\d+)?\]/s, 'aligned RHS concat fragments avoid selecting from the whole concat blob');

    like(
        generation_failure(
            'direct_lhs_deconstruct_bad_rhs_concat_operand_contract',
            <<'FSM'
(?fsm:direct_lhs_deconstruct_bad_rhs_concat_operand_contract
  (+system
    (clock clk)
    (sreset rst)
  )
  (+types
    (type payload_t (list bit (bits 2)))
    (type bad_payload_t (record (mode (bits 2)) (flag bit)))
  )
  (+size
    (TAG_IN 4)
    (BAD_PAYLOAD bad_payload_t)
    (TAG 4)
    (PAYLOAD payload_t)
  )
  (idle
    ((concat TAG PAYLOAD) = (concat TAG_IN BAD_PAYLOAD))
  )
)
FSM
        ),
        qr/assignment to 'PAYLOAD' uses whole aggregate RHS 'BAD_PAYLOAD' with contract 'record\{mode:bits\[2\], flag:bit\}' that does not match declared type 'list<bit, bits\[2\]>'/s,
        'aligned RHS concat aggregate operands keep their own type contract during deconstruct validation',
    );
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

sub parse_failure {
    my ($basename, $fsm_text) = @_;
    my $error = '';
    eval {
        parse_fsm_module($basename, $fsm_text);
        1;
    } or do {
        $error = $@ || 'unknown error';
    };
    return $error;
}

sub generation_failure {
    my ($basename, $fsm_text) = @_;
    my $error = '';
    eval {
        my $fsm_module = parse_fsm_module($basename, $fsm_text);
        FSM::HDL::FlattenedDT->new(debug => 0)->generate_systemverilog($fsm_module);
        1;
    } or do {
        $error = $@ || 'unknown error';
    };
    return $error;
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
