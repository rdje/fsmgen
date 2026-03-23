#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::IR::StructuralRTLIR;
use FSM::Pipeline::HDLGenerator;
use FSM::IR::StructuralRTLIR::ConnectionExpr qw(
    open_expr
    signal_ref_expr
    member_access_expr
    index_access_expr
    bit_select_expr
    slice_expr
    concat_expr
    bit_vector_literal_expr
    signal_ref_binding
    update_binding_signal_ref
    ensure_signal_ref_binding
    set_signal_ref_binding
    normalized_binding
    binding_expr
    expr_signal_name
    expr_signal_names
    binding_signal_name
    binding_signal_names
    render_expr
    binding_expr_text
);

subtest 'backend-neutral open connection expressions render without inventing fake signal dependencies' => sub {
    is_deeply(
        open_expr(),
        {
            kind => 'open',
        },
        'open helper builds the explicit unconnected actual-binding node',
    );

    is(
        render_expr(open_expr()),
        '',
        'open expressions render as an empty actual connection for the current verilog-family backend',
    );

    is(
        render_expr(open_expr(), 'unused', 'vhdl'),
        'open',
        'open expressions already render to the portable VHDL open keyword',
    );

    is_deeply(
        expr_signal_names(open_expr()),
        [],
        'open expressions do not report fake signal dependencies',
    );

    is(
        binding_expr_text({
            port_name => 'unused',
            connection_expr => open_expr(),
        }),
        '',
        'binding text rendering preserves an explicit open connection as an empty current-language actual',
    );

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug_level => 0,
        quiet => 1,
    );

    my $structural_rtl_ir = FSM::IR::StructuralRTLIR->new(
        module_name => 'structural_open_top',
        source_root_kind => 'top',
        target_language => 'systemverilog',
        ports => [],
        nets => [],
        instances => [
            {
                kind => 'fsmc',
                instance_name => 'u_child',
                module_name => 'child_mod',
                source_name => 'child_src',
                interface_ports => [
                    { name => 'unused', direction => 'input', width => 1, type => undef },
                ],
                port_bindings => [
                    {
                        port_name => 'unused',
                        connection_expr => open_expr(),
                    },
                ],
            },
        ],
        declared_links => [],
        resolved_links => [],
        auxiliary_assignments => [],
    );

    my $rendered = $pipeline->emit_composition_top_module($structural_rtl_ir);
    like(
        $rendered,
        qr/\.unused\(\)/,
        'composition structural emitter walks explicit open connection expressions directly',
    );
};

subtest 'signal_ref helper builds the first bounded structural connection node' => sub {
    is_deeply(
        signal_ref_expr('top_data'),
        {
            kind => 'signal_ref',
            signal_name => 'top_data',
        },
        'signal_ref helper returns the backend-neutral signal_ref expression shape',
    );

    is(
        expr_signal_name(signal_ref_expr('top_data')),
        'top_data',
        'expr signal-name recovery understands the bounded signal_ref form',
    );

    is_deeply(
        signal_ref_binding('data_in', 'top_data'),
        {
            port_name => 'data_in',
            signal_name => 'top_data',
            connection_expr => {
                kind => 'signal_ref',
                signal_name => 'top_data',
            },
        },
        'signal_ref binding helper builds the bounded binding payload with both compatibility and typed fields',
    );
};

subtest 'bounded fixed-size index-access connection expressions render through the helper and the structural emitter' => sub {
    is_deeply(
        index_access_expr('lane_bus', 2),
        {
            kind => 'index_access',
            source_expr => {
                kind => 'signal_ref',
                signal_name => 'lane_bus',
            },
            index => 2,
        },
        'index-access helper builds a nested structural connection expression',
    );

    is(
        render_expr(index_access_expr('lane_bus', 2)),
        'lane_bus[2]',
        'index-access expressions render through the current verilog-family helper path',
    );

    is(
        render_expr(index_access_expr('lane_bus', 2), 'lane', 'vhdl'),
        'lane_bus(2)',
        'index-access expressions also render through the current VHDL helper path',
    );

    is_deeply(
        expr_signal_names(index_access_expr('lane_bus', 2)),
        ['lane_bus'],
        'index-access signal discovery preserves the referenced base signal',
    );

    is(
        binding_signal_name({
            port_name => 'lane',
            connection_expr => index_access_expr('lane_bus', 2),
        }),
        '',
        'index-access expressions do not pretend to be one flat bound signal name',
    );

    is(
        binding_expr_text({
            port_name => 'lane',
            connection_expr => index_access_expr('lane_bus', 2),
        }),
        'lane_bus[2]',
        'binding text rendering walks index-access expressions',
    );

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug_level => 0,
        quiet => 1,
    );

    my $structural_rtl_ir = FSM::IR::StructuralRTLIR->new(
        module_name => 'structural_index_top',
        source_root_kind => 'top',
        target_language => 'systemverilog',
        ports => [],
        nets => [],
        instances => [
            {
                kind => 'fsmc',
                instance_name => 'u_child',
                module_name => 'child_mod',
                source_name => 'child_src',
                interface_ports => [
                    { name => 'lane', direction => 'input', width => 1, type => undef },
                ],
                port_bindings => [
                    {
                        port_name => 'lane',
                        connection_expr => index_access_expr('lane_bus', 2),
                    },
                ],
            },
        ],
        declared_links => [],
        resolved_links => [],
        auxiliary_assignments => [],
    );

    my $rendered = $pipeline->emit_composition_top_module($structural_rtl_ir);
    like(
        $rendered,
        qr/\.lane\(lane_bus\[2\]\)/,
        'composition structural emitter walks fixed-size index-access expressions directly',
    );
};

subtest 'bounded member-access connection expressions render through the helper and the structural emitter' => sub {
    is_deeply(
        member_access_expr('cfg_bus', 'mode'),
        {
            kind => 'member_access',
            source_expr => {
                kind => 'signal_ref',
                signal_name => 'cfg_bus',
            },
            member_name => 'mode',
        },
        'member-access helper builds a nested structural connection expression',
    );

    is(
        render_expr(member_access_expr('cfg_bus', 'mode')),
        'cfg_bus.mode',
        'member-access expressions render through the current systemverilog helper path',
    );

    is(
        render_expr(member_access_expr('cfg_bus', 'mode'), 'cfg', 'vhdl'),
        'cfg_bus.mode',
        'member-access expressions also render through the current VHDL helper path',
    );

    is_deeply(
        expr_signal_names(member_access_expr('cfg_bus', 'mode')),
        ['cfg_bus'],
        'member-access signal discovery preserves the referenced base signal',
    );

    is(
        binding_signal_name({
            port_name => 'cfg',
            connection_expr => member_access_expr('cfg_bus', 'mode'),
        }),
        '',
        'member-access expressions do not pretend to be one flat bound signal name',
    );

    is(
        binding_expr_text({
            port_name => 'cfg',
            connection_expr => member_access_expr('cfg_bus', 'mode'),
        }),
        'cfg_bus.mode',
        'binding text rendering walks member-access expressions',
    );

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug_level => 0,
        quiet => 1,
    );

    my $structural_rtl_ir = FSM::IR::StructuralRTLIR->new(
        module_name => 'structural_member_top',
        source_root_kind => 'top',
        target_language => 'systemverilog',
        ports => [],
        nets => [],
        instances => [
            {
                kind => 'fsmc',
                instance_name => 'u_child',
                module_name => 'child_mod',
                source_name => 'child_src',
                interface_ports => [
                    { name => 'cfg', direction => 'input', width => 1, type => undef },
                ],
                port_bindings => [
                    {
                        port_name => 'cfg',
                        connection_expr => member_access_expr('cfg_bus', 'mode'),
                    },
                ],
            },
        ],
        declared_links => [],
        resolved_links => [],
        auxiliary_assignments => [],
    );

    my $rendered = $pipeline->emit_composition_top_module($structural_rtl_ir);
    like(
        $rendered,
        qr/\.cfg\(cfg_bus\.mode\)/,
        'composition structural emitter walks member-access connection expressions directly',
    );

    my $error = eval {
        render_expr(member_access_expr('cfg_bus', 'mode'), 'cfg', 'verilog');
        undef;
    };

    like(
        $@,
        qr/unsupported target_language 'verilog'/,
        'member-access rendering fails explicitly for backends that do not support the bounded helper form yet',
    );
};

subtest 'binding signal-name lookup prefers the typed connection expression when present' => sub {
    is(
        binding_signal_name({
            port_name => 'data_in',
            signal_name => 'stale_mirror',
            connection_expr => {
                kind => 'signal_ref',
                signal_name => 'typed_source',
            },
        }),
        'typed_source',
        'binding signal-name recovery follows the typed expression instead of the compatibility mirror',
    );

    is(
        binding_signal_name({
            port_name => 'data_in',
            signal_name => 'fallback_name',
        }),
        'fallback_name',
        'binding signal-name recovery still falls back to the mirrored signal_name field',
    );

    is_deeply(
        binding_expr({
            port_name => 'data_in',
            signal_name => 'fallback_name',
        }),
        {
            kind => 'signal_ref',
            signal_name => 'fallback_name',
        },
        'binding expression recovery synthesizes the bounded signal_ref node from the compatibility mirror when needed',
    );
};

subtest 'recursive signal discovery follows richer typed connection expressions without flattening them into fake plain-wire names' => sub {
    is_deeply(
        expr_signal_names(slice_expr('shared_bus', 7, 4)),
        ['shared_bus'],
        'slice expressions still report their referenced source signal',
    );

    is_deeply(
        expr_signal_names(
            concat_expr(
                bit_select_expr('ctrl', 0),
                slice_expr('payload', 6, 0),
                'payload',
            )
        ),
        ['ctrl', 'payload'],
        'concat signal discovery preserves referenced signal order while deduplicating repeats',
    );

    is_deeply(
        binding_signal_names({
            port_name => 'combined',
            connection_expr => concat_expr(
                bit_select_expr('ctrl', 0),
                slice_expr('payload', 6, 0),
            ),
        }),
        ['ctrl', 'payload'],
        'binding signal discovery follows the typed connection expression recursively',
    );

    is(
        binding_signal_name({
            port_name => 'combined',
            connection_expr => concat_expr(
                bit_select_expr('ctrl', 0),
                slice_expr('payload', 6, 0),
            ),
        }),
        '',
        'plain binding signal-name lookup still refuses to mislabel a non-leaf connection as one flat wire',
    );
};

subtest 'binding expression text rendering stays backend-neutral for the bounded signal_ref case' => sub {
    is(
        binding_expr_text({
            port_name => 'data_in',
            connection_expr => {
                kind => 'signal_ref',
                signal_name => 'typed_source',
            },
        }),
        'typed_source',
        'binding text rendering emits the signal name for the current bounded signal_ref form',
    );

    is(
        binding_expr_text({
            port_name => 'data_in',
            signal_name => 'fallback_name',
        }),
        'fallback_name',
        'binding text rendering still supports the mirrored signal_name fallback path',
    );
};

subtest 'bounded indexed and sliced connection expressions render through the current verilog-family backend' => sub {
    is_deeply(
        bit_select_expr('shared_bus', 3),
        {
            kind => 'bit_select',
            source_expr => {
                kind => 'signal_ref',
                signal_name => 'shared_bus',
            },
            index => 3,
        },
        'bit-select helper builds a nested structural connection expression',
    );

    is_deeply(
        slice_expr('shared_bus', 7, 4),
        {
            kind => 'slice',
            source_expr => {
                kind => 'signal_ref',
                signal_name => 'shared_bus',
            },
            msb => 7,
            lsb => 4,
        },
        'slice helper builds a nested structural connection expression',
    );

    is(
        render_expr(bit_select_expr('shared_bus', 3)),
        'shared_bus[3]',
        'bit-select expressions render through the current verilog-family backend',
    );

    is(
        render_expr(slice_expr('shared_bus', 7, 4)),
        'shared_bus[7:4]',
        'slice expressions render through the current verilog-family backend',
    );

    is(
        binding_expr_text({
            port_name => 'data_window',
            connection_expr => slice_expr('shared_bus', 7, 4),
        }),
        'shared_bus[7:4]',
        'binding text rendering walks a sliced connection expression',
    );

    is(
        binding_signal_name({
            port_name => 'data_window',
            connection_expr => slice_expr('shared_bus', 7, 4),
        }),
        '',
        'non-signal-ref connection expressions do not pretend to be a plain bound signal name',
    );

    my $error = eval {
        render_expr(slice_expr('shared_bus', 7, 4), 'data_window', 'vhdl');
        undef;
    };

    like(
        $@,
        qr/unsupported target_language 'vhdl'/,
        'slice rendering fails explicitly for backends the current bounded renderer does not support yet',
    );
};

subtest 'bounded concat connection expressions render through the helper and the structural emitter' => sub {
    is_deeply(
        concat_expr(
            bit_select_expr('ctrl', 0),
            slice_expr('payload', 6, 0),
        ),
        {
            kind => 'concat',
            operands => [
                {
                    kind => 'bit_select',
                    source_expr => {
                        kind => 'signal_ref',
                        signal_name => 'ctrl',
                    },
                    index => 0,
                },
                {
                    kind => 'slice',
                    source_expr => {
                        kind => 'signal_ref',
                        signal_name => 'payload',
                    },
                    msb => 6,
                    lsb => 0,
                },
            ],
        },
        'concat helper preserves nested structural operand expressions',
    );

    is(
        render_expr(concat_expr('upper_nibble', slice_expr('payload', 3, 0))),
        '{upper_nibble, payload[3:0]}',
        'concat expressions render through the current verilog-family backend',
    );

    is(
        binding_expr_text({
            port_name => 'combined',
            connection_expr => concat_expr(
                bit_select_expr('ctrl', 0),
                slice_expr('payload', 6, 0),
            ),
        }),
        '{ctrl[0], payload[6:0]}',
        'binding text rendering walks nested concat expressions',
    );

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug_level => 0,
        quiet => 1,
    );

    my $structural_rtl_ir = FSM::IR::StructuralRTLIR->new(
        module_name => 'structural_concat_top',
        source_root_kind => 'top',
        target_language => 'systemverilog',
        ports => [
            { name => 'ctrl', direction => 'input', width => 1, type => 'wire' },
            { name => 'payload', direction => 'input', width => 7, type => 'wire' },
        ],
        nets => [],
        instances => [
            {
                kind => 'fsmc',
                instance_name => 'u_child',
                module_name => 'child_mod',
                source_name => 'child_src',
                interface_ports => [
                    { name => 'combined', direction => 'input', width => 8, type => undef },
                ],
                port_bindings => [
                    {
                        port_name => 'combined',
                        connection_expr => concat_expr(
                            bit_select_expr('ctrl', 0),
                            slice_expr('payload', 6, 0),
                        ),
                    },
                ],
            },
        ],
        declared_links => [],
        resolved_links => [],
        auxiliary_assignments => [],
    );

    my $rendered = $pipeline->emit_composition_top_module($structural_rtl_ir);
    like(
        $rendered,
        qr/\.combined\(\{ctrl\[0\], payload\[6:0\]\}\)/,
        'composition structural emitter walks concat connection expressions directly',
    );

    my $error = eval {
        render_expr(concat_expr('upper_nibble', 'lower_nibble'), 'combined', 'vhdl');
        undef;
    };

    like(
        $@,
        qr/unsupported target_language 'vhdl'/,
        'concat rendering also fails explicitly for backends the current bounded renderer does not support yet',
    );
};

subtest 'bounded bit-vector literal connection expressions render through the helper and the structural emitter' => sub {
    is_deeply(
        bit_vector_literal_expr('10100101'),
        {
            kind => 'bit_vector_literal',
            bits => '10100101',
            width => 8,
        },
        'bit-vector literal helper builds a backend-neutral literal node',
    );

    is(
        render_expr(bit_vector_literal_expr('10100101')),
        "8'b10100101",
        'bit-vector literal expressions render through the current verilog-family backend',
    );

    is_deeply(
        expr_signal_names(bit_vector_literal_expr('10100101')),
        [],
        'literal expressions do not report fake signal dependencies',
    );

    is(
        binding_expr_text({
            port_name => 'mask',
            connection_expr => bit_vector_literal_expr('10100101'),
        }),
        "8'b10100101",
        'binding text rendering walks bit-vector literal expressions',
    );

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug_level => 0,
        quiet => 1,
    );

    my $structural_rtl_ir = FSM::IR::StructuralRTLIR->new(
        module_name => 'structural_literal_top',
        source_root_kind => 'top',
        target_language => 'systemverilog',
        ports => [],
        nets => [],
        instances => [
            {
                kind => 'fsmc',
                instance_name => 'u_child',
                module_name => 'child_mod',
                source_name => 'child_src',
                interface_ports => [
                    { name => 'mask', direction => 'input', width => 8, type => undef },
                ],
                port_bindings => [
                    {
                        port_name => 'mask',
                        connection_expr => bit_vector_literal_expr('10100101'),
                    },
                ],
            },
        ],
        declared_links => [],
        resolved_links => [],
        auxiliary_assignments => [],
    );

    my $rendered = $pipeline->emit_composition_top_module($structural_rtl_ir);
    like(
        $rendered,
        qr/\.mask\(8'b10100101\)/,
        'composition structural emitter walks literal connection expressions directly',
    );

    my $error = eval {
        render_expr(bit_vector_literal_expr('10100101'), 'mask', 'vhdl');
        undef;
    };

    like(
        $@,
        qr/unsupported target_language 'vhdl'/,
        'literal rendering fails explicitly for backends the current bounded renderer does not support yet',
    );
};

subtest 'signal_ref binding updates keep compatibility and typed fields aligned' => sub {
    my $binding = signal_ref_binding('data_in', 'old_data');

    is(
        update_binding_signal_ref($binding, 'new_data'),
        $binding,
        'signal_ref binding update returns the same binding reference for in-place callers',
    );

    is_deeply(
        $binding,
        {
            port_name => 'data_in',
            signal_name => 'new_data',
            connection_expr => {
                kind => 'signal_ref',
                signal_name => 'new_data',
            },
        },
        'signal_ref binding update keeps the compatibility and typed fields aligned',
    );
};

subtest 'binding-list ensure and set helpers now own bounded signal-ref port-binding updates' => sub {
    my $bindings = [
        signal_ref_binding('data_in', 'top_data'),
    ];

    my $ensured = ensure_signal_ref_binding($bindings, 'data_in', 'top_data');
    is($ensured, $bindings->[0], 'ensure helper reuses an existing matching binding');
    is(scalar(@$bindings), 1, 'ensure helper does not duplicate an existing matching binding');

    my $added = ensure_signal_ref_binding($bindings, 'clk', 'clk');
    is($added, $bindings->[1], 'ensure helper returns the appended binding for a new port');
    is_deeply(
        $bindings,
        [
            {
                port_name => 'data_in',
                signal_name => 'top_data',
                connection_expr => {
                    kind => 'signal_ref',
                    signal_name => 'top_data',
                },
            },
            {
                port_name => 'clk',
                signal_name => 'clk',
                connection_expr => {
                    kind => 'signal_ref',
                    signal_name => 'clk',
                },
            },
        ],
        'ensure helper appends a bounded signal-ref binding when the port is new',
    );

    my $rebound = set_signal_ref_binding($bindings, 'data_in', 'shared_bus');
    is($rebound, $bindings->[0], 'set helper updates the existing binding in place');
    is_deeply(
        $bindings->[0],
        {
            port_name => 'data_in',
            signal_name => 'shared_bus',
            connection_expr => {
                kind => 'signal_ref',
                signal_name => 'shared_bus',
            },
        },
        'set helper keeps the compatibility and typed fields aligned on existing bindings',
    );

    my $set_added = set_signal_ref_binding($bindings, 'rstn', 'rstn');
    is($set_added, $bindings->[2], 'set helper appends a new binding when the port is missing');
};

subtest 'normalized binding cloning and backfilling now live in the structural helper module' => sub {
    my $expr = {
        kind => 'signal_ref',
        signal_name => 'shared_bus',
    };

    is_deeply(
        normalized_binding({
            port_name => 'rx',
            connection_expr => $expr,
        }),
        {
            port_name => 'rx',
            signal_name => 'shared_bus',
            connection_expr => {
                kind => 'signal_ref',
                signal_name => 'shared_bus',
            },
        },
        'normalized binding backfills the compatibility mirror from the typed signal_ref expression',
    );

    my $normalized = normalized_binding({
        port_name => 'data_in',
        signal_name => 'top_data',
    });
    $expr->{signal_name} = 'mutated_after_normalization';

    is_deeply(
        $normalized,
        {
            port_name => 'data_in',
            signal_name => 'top_data',
            connection_expr => {
                kind => 'signal_ref',
                signal_name => 'top_data',
            },
        },
        'normalized binding synthesizes the bounded signal_ref node from the compatibility mirror',
    );

    my $cloned = normalized_binding({
        port_name => 'shared',
        connection_expr => {
            kind => 'signal_ref',
            signal_name => 'orig_bus',
        },
    });
    $cloned->{connection_expr}{signal_name} = 'mutated_clone';

    is_deeply(
        normalized_binding({
            port_name => 'shared',
            connection_expr => {
                kind => 'signal_ref',
                signal_name => 'orig_bus',
            },
        }),
        {
            port_name => 'shared',
            signal_name => 'orig_bus',
            connection_expr => {
                kind => 'signal_ref',
                signal_name => 'orig_bus',
            },
        },
        'normalized binding returns its own cloned payload instead of aliasing caller-owned hashes',
    );
};

subtest 'unsupported structural connection kinds fail explicitly' => sub {
    my $error = eval {
        binding_expr_text({
            port_name => 'data_in',
            connection_expr => {
                kind => 'mystery_expr',
            },
        });
        undef;
    };

    like(
        $@,
        qr/unsupported connection_expr kind 'mystery_expr'/,
        'unsupported structural connection kinds fail with clear bounded wording',
    );
};

done_testing();
