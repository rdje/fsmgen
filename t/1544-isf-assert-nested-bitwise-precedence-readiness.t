#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use IPC::Cmd qw(run);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::FSMGenFull;
use FSM::CoreAST;
use FSM::IR::IntentHIRBuilder;
use FSM::Pipeline::GeneratedModuleInfoBuilder;
use FSM::ProjectDataLocality qw(configure_project_temp_environment create_project_tempdir repository_root);
use Lispish;

my $repo_root = repository_root();
configure_project_temp_environment(purpose => 'tests');
my $workspace = create_project_tempdir(purpose => 'tests');

subtest 'direct CoreAST rendering preserves nested mixed bitwise precedence' => sub {
    my $high = FSM::CoreAST::SignalRef->new(FSM::CoreAST::Signal->new(name => 'high'));
    my $bit3 = FSM::CoreAST::SignalRef->new(FSM::CoreAST::Signal->new(name => 'bit3'));
    my $bit2 = FSM::CoreAST::SignalRef->new(FSM::CoreAST::Signal->new(name => 'bit2'));
    my $nested = FSM::CoreAST::BinaryOp->new(
        '&',
        $high,
        FSM::CoreAST::BinaryOp->new('|', $bit3, $bit2),
    );

    is(
        $nested->to_systemverilog(),
        'high & (bit3 | bit2)',
        'the canonical CoreAST renderer carries child precedence into the nested OR',
    );
};

subtest 'AXI assertion inlining preserves the nested OR grouping' => sub {
    my $outdir = File::Spec->catdir($workspace, 'out');
    my $hdl = File::Spec->catfile($workspace, 'axi_read_burst4_transaction_composition.sv');
    my $source = File::Spec->catfile(
        $repo_root,
        'ppif',
        'axi_read_burst4_transaction_composition.ppif',
    );
    my ($ok, undef, undef, undef, $stderr) = run(
        command => [
            File::Spec->catfile($repo_root, 'bin', 'fsmgen'),
            '--quiet',
            '--strict',
            '--outdir',
            $outdir,
            '--output',
            $hdl,
            $source,
        ],
    );
    ok($ok, 'public AXI fixed-four read source generates')
        or diag(join('', @{$stderr || []}));
    return unless $ok;

    my $coordinator = File::Spec->catfile(
        $outdir,
        'axi_read_burst4_transaction_coordinator.fsm',
    );
    ok(-f $coordinator, 'generated coordinator carrier exists');
    my $module = FSM::Adapter::FSMGenFull->new(debug => 0)->parse_fsm(
        Lispish::multi($coordinator),
    );
    my $assertions = $module->{attributes}{immediate_assertions};
    my ($boundary) = grep {
        ($_->{name} // '') eq 'aligned_boundary_command_check_assert_0'
    } @{$assertions || []};
    ok($boundary, 'the generated coordinator carries the aligned-boundary assertion');
    return unless $boundary;

    is(ref($boundary->{condition}), 'HASH', 'the assertion condition is a property tree');
    is($boundary->{condition}{op}, 'implies_overlap', 'the property root is overlapping implication');
    isa_ok(
        $boundary->{condition}{consequent},
        'FSM::CoreAST::SignalRef',
        'the consequent reaches the renderer through an inlineable intermediate',
    );

    my $intent = FSM::IR::IntentHIRBuilder->build_from_fsm_module(
        fsm_module => $module,
    );
    my $module_info = FSM::Pipeline::GeneratedModuleInfoBuilder->build_from_fsm_module(
        fsm_module => $module,
        intent_hir => $intent,
    );
    my ($rendered) = grep {
        ($_->{name} // '') eq 'aligned_boundary_command_check_assert_0'
    } @{$module_info->{immediate_assertions} || []};
    ok($rendered, 'GeneratedModuleInfoBuilder surfaces the assertion');
    return unless $rendered;

    like(
        $rendered->{condition_sv},
        qr/cmd_read_addr\[4\] & \(cmd_read_addr\[3\] \| cmd_read_addr\[2\]\)/,
        'the inlined condition preserves the nested OR as one AND child',
    );
    unlike(
        $rendered->{condition_sv},
        qr/cmd_read_addr\[4\] & cmd_read_addr\[3\] \| cmd_read_addr\[2\]/,
        'the malformed ungrouped substitution is absent',
    );

    my $hdl_text = slurp($hdl);
    like(
        $hdl_text,
        qr/assign intermediate_complex_expr_\d+ = cmd_read_addr\[3\] \| cmd_read_addr\[2\];/,
        'behavioral lowering keeps the nested OR in an intermediate',
    );
    like(
        $hdl_text,
        qr/cmd_read_addr\[4\] & intermediate_complex_expr_\d+;/,
        'behavioral lowering consumes that OR as one AND operand',
    );
    like(
        $hdl_text,
        qr/assert property .*cmd_read_addr\[4\] & \(cmd_read_addr\[3\] \| cmd_read_addr\[2\]\)/,
        'the emitted concurrent property preserves the same grouping boundary',
    );
};

done_testing();

sub slurp {
    my ($path) = @_;
    open my $fh, '<', $path or die "cannot read $path: $!";
    local $/;
    my $text = <$fh>;
    close $fh or die "cannot close $path: $!";
    return $text;
}
