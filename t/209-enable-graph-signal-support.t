#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::AST::Node;
use FSM::HDL::FlattenedDT;
use FSM::Pipeline::SourceFrontend;

{
    package Local::SignalRefWithDefaults;

    use parent -norequire, 'FSM::AST::SignalRef';

    sub new {
        my ($class, $signal_name, %args) = @_;
        return bless {
            type => 'signal_ref',
            signal_name => $signal_name,
            %args,
        }, $class;
    }

    sub reset_value {
        my ($self) = @_;
        return $self->{reset_value};
    }

    sub default_value {
        my ($self) = @_;
        return $self->{default_value};
    }
}

subtest 'enable-graph signal support rebuilds signal naming, AST metadata lookup, and intermediate classification from a prepared backend context' => sub {
    my $fsm_module = parse_fsm_module(
        'enable_graph_signal_support_contract',
        <<'FSM'
(?fsm:enable_graph_signal_support_contract
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+size
    (A 1)
    (B 1)
    (OUT1 1)
  )
  (idle
    (OUT1 <= A)
  )
)
FSM
    );

    my $hdl = FSM::HDL::FlattenedDT->new(debug => 0);
    my $support = $hdl->{enable_graph_signal_support};

    $support->set_fsm_module_reference($fsm_module);
    is(
        $hdl->{fsm_module},
        $fsm_module,
        'signal support attaches the live FSM module to the backend context',
    );

    my $named_ast = FSM::AST::BinaryOp->new(
        '&&',
        FSM::AST::SignalRef->new('A'),
        FSM::AST::SignalRef->new('B'),
    );
    is(
        $support->generate_ast_based_signal_name($named_ast),
        'A_and_B',
        'signal support keeps AST-based intermediate naming stable',
    );
    is(
        $support->map_operator_to_name('+'),
        'plus',
        'signal support keeps operator-to-name mapping stable',
    );
    is(
        $support->clean_intermediate_expression('mid & & aux'),
        'mid &&aux',
        'signal support normalizes compatibility intermediate expressions',
    );
    is(
        $support->clean_signal_name('OUT[1]'),
        'out_1',
        'signal support normalizes backend signal names',
    );
    is(
        $support->generate_rhs_based_enable_name('OUT1', "8'h00"),
        'out1__8_h00_en',
        'signal support keeps RHS-based enable naming stable',
    );

    my $metadata_ast = Local::SignalRefWithDefaults->new(
        'OUT1',
        reset_value => "1'b0",
        default_value => "1'b1",
    );
    is(
        $support->get_reset_value_from_ast($metadata_ast),
        "1'b0",
        'signal support prefers AST reset metadata when present',
    );
    is(
        $support->get_default_value_from_ast($metadata_ast),
        "1'b1",
        'signal support prefers AST default metadata when present',
    );

    $hdl->{intermediate_signals}{mid} = {
        name => 'mid',
        source => 'test_fixture',
    };
    ok(
        $support->is_intermediate_signal('mid'),
        'signal support recognizes registered intermediate signals',
    );

    my $dependency_ast = FSM::AST::BinaryOp->new(
        '&&',
        FSM::AST::SignalRef->new('mid'),
        FSM::AST::SignalRef->new('A'),
    );
    is_deeply(
        [$support->extract_intermediate_signals_from_ast($dependency_ast)],
        ['mid'],
        'signal support extracts direct intermediate dependencies from AST trees',
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

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
