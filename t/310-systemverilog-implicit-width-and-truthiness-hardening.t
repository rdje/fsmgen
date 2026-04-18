#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;

sub generate_sv {
    my ($relative_path) = @_;
    my $fsm_file = File::Spec->catfile($FindBin::Bin, '..', $relative_path);

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        quiet => 1,
    );

    my $result;
    {
        local $SIG{__WARN__} = sub { };
        $result = $pipeline->generate_hdl_from_file($fsm_file);
    }

    return $result->{hdl_code};
}

subtest 'static RHS slices and selectors infer missing direct signal widths' => sub {
    my $hdl = generate_sv('fsm/mipicsi2_byteserial.fsm');

    like($hdl, qr/\binput\s+wire\s+\[31:0\]\s+fifout\b/, 'RHS slice use infers fifout as 32 bits');
    like($hdl, qr/\breg\s+\[1:0\]\s+bytept\b/, 'test selectors infer bytept as 2 bits');
    like($hdl, qr/\breg\s+\[7:0\]\s+byteso\b/, 'slice RHS assignment infers byteso as 8 bits');
    like($hdl, qr/\bbout_byteso_fifout_7_0_en\s*=\s*bout_en\s*&\s*\(~\|bytept\)\s*;/, 'zero selector emits width-safe multibit false truthiness');
};

subtest 'explicit-width relational guards infer missing counter widths' => sub {
    my $hdl = generate_sv('fsm/mipicsi2_txtimer.fsm');

    like($hdl, qr/\breg\s+\[19:0\]\s+txtimer\b/, '20-bit guard literal infers txtimer width');
    like($hdl, qr/\breg\s+\[19:0\]\s+txtimer_next\b/, 'txtimer helper register keeps inferred width');
    like($hdl, qr/\btxtimer\s*==\s*20'h1\b/, 'generated comparison preserves the explicit guard width');
};

subtest 'enable-graph rendering preserves sliced CoreAST relational guards' => sub {
    my $hdl = generate_sv('fsm/mipicsi2_pkt_nx4B_fifo.fsm');

    like(
        $hdl,
        qr/\bcnt\[2:1\]\s*!=\s*2'd2\s*&\s*!cnt\[0\]\s*;/,
        'packet FIFO guard keeps the authored 2-bit counter slice before bitwise conjunction',
    );
    unlike(
        $hdl,
        qr/\bcnt\s*!=\s*2'd2\s*&\s*!cnt\[0\]\s*;/,
        'packet FIFO guard does not widen the sliced compare back to the full counter',
    );
};

subtest 'whole-signal assignment widths reconcile after later selector inference' => sub {
    my $hdl = generate_sv('fsm/mipicsi2_tester_ctrl.fsm');

    like(
        $hdl,
        qr/\binput\s+wire\s+\[7:0\]\s+cnt_wait\b/,
        'later selector inference widens cnt_wait to match the 8-bit counter assignment edge',
    );
    like(
        $hdl,
        qr/\bcnt_next\s*=\s*cnt_wait\s*;/,
        'counter mux still uses the simple authored whole-signal assignment once widths reconcile',
    );
};

subtest 'intermediate arithmetic width follows assignment-analysis signal widths' => sub {
    my $hdl = generate_sv('fsm/amba_requester.fsm');

    like($hdl, qr/\bwire\s+\[31:0\]\s+addr_q_plus_addr_step_q\b/, 'arithmetic intermediate keeps 32-bit result width');
    unlike($hdl, qr/\bwire\s+addr_q_plus_addr_step_q\s*;/, 'arithmetic intermediate is not silently collapsed to 1 bit');
    like($hdl, qr/\bwrap_base_q_next\s*=\s*addr_q\s*-\s*addr_q\s*%\s*\(beats_total_q\s*\*\s*addr_step_q\)\s*;/, 'runtime modulo RHS product keeps authored grouping');
    like($hdl, qr/\bwrap_high_q_next\s*=\s*addr_q\s*-\s*addr_q\s*%\s*\(beats_total_q\s*\*\s*addr_step_q\)\s*\+\s*beats_total_q\s*\*\s*addr_step_q\s*;/, 'runtime modulo grouping is preserved inside wider arithmetic expressions');
    unlike($hdl, qr/addr_q\s*%\s*beats_total_q\s*\*\s*addr_step_q/, 'runtime modulo is not flattened into left-associative MOD/MUL text');
};

done_testing();
