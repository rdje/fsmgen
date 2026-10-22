#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::AST::Node;
use FSM::CoreAST;
use FSM::HDL::ASTFactorization;
use FSM::HDL::FlattenedDT;
use FSM::Debug;

my $work = tempdir(CLEANUP => 1);
my $context = FSM::HDL::FlattenedDT->new(debug => 0);
my $owner = $context->{enable_graph_ast_support};
my $left = FSM::CoreAST::SignalRef->new(FSM::CoreAST::Signal->new(name => 'A', width => 8));
my $right = FSM::CoreAST::SignalRef->new(FSM::CoreAST::Signal->new(name => 'B', width => 8));
my @models = (
    [runtime => FSM::AST::BinaryOp->new('+', FSM::AST::SignalRef->new('A'), FSM::AST::SignalRef->new('B'))],
    [core => FSM::CoreAST::BinaryOp->new('+', $left, $right)],
    [substituted => FSM::HDL::SubstitutedBinaryOp->new(operator => '+', left => $left, right => $right)],
);

# Keep the direct calls at file scope: an eval/subtest/capture callback would
# supply the very caller frame missing from the original failure.
for my $model (@models) {
    my ($name, $ast) = @$model;
    for my $level (0, 2, 3) {
        for my $file_route (0, 1) {
            my (@warnings, $rendered, $call_line);
            my $stdout = '';
            my $path = "$work/$name-$level-$file_route.trace";
            set_fsm_debug_level($level);
            set_fsm_trace_emojis(0);
            set_fsm_trace_output_file($path) if $file_route;
            {
                local $SIG{__WARN__} = sub { push @warnings, @_ };
                local *STDOUT;
                open STDOUT, '>', \$stdout or die $!;
                $call_line = __LINE__ + 1;
                $rendered = $owner->ast_to_systemverilog($ast);
            }
            clear_fsm_trace_output_file() if $file_route;
            my $trace = $file_route ? read_file($path) : '';
            my $label = "$name level=$level file=$file_route";
            is($rendered, 'A + B', "$label preserves independently expected expression bytes");
            is_deeply(\@warnings, [], "$label direct top-level render has no warnings");
            if ($level < 3) {
                is($stdout . $trace, '', "$label renderer diagnostics remain gated");
            } else {
                my $emitted = $file_route ? $trace : $stdout;
                is($file_route ? $stdout : $trace, '', "$label keeps the unselected channel empty");
                like($emitted, qr/Called from: \(top level\) at line \Q$call_line\E\n/,
                    "$label identifies the actual top-level call line");
                like($emitted, qr/AST_TO_SV_DEBUG: A \+ B/, "$label retains rendered-value diagnostics");
                like($emitted, qr/AST type: \Q@{[ref($ast)]}\E/, "$label retains AST-type diagnostics");
            }
        }
    }
}

# A named outer frame already supplies metadata. Preserve its existing name
# and invocation line, and exercise the real debug implementation above.
set_fsm_debug_level(3);
my $nested_line = __LINE__ + 1;
my $nested = nested_render($owner, $models[0][1]);
is($nested->{rendered}, 'A + B', 'nested render preserves expression bytes');
is_deeply($nested->{warnings}, [], 'nested render has no warnings');
like($nested->{stdout}, qr/Called from: main::nested_render at line \Q$nested_line\E\n/,
    'existing nested caller metadata stays unchanged');
clear_fsm_trace_output_file();
set_fsm_debug_level(0);
done_testing();

sub nested_render {
    my ($support, $ast) = @_;
    my (@warnings, $rendered);
    my $stdout = '';
    {
        local $SIG{__WARN__} = sub { push @warnings, @_ };
        local *STDOUT;
        open STDOUT, '>', \$stdout or die $!;
        $rendered = $support->ast_to_systemverilog($ast);
    }
    return {rendered => $rendered, warnings => \@warnings, stdout => $stdout};
}

sub read_file {
    my ($path) = @_;
    open my $fh, '<', $path or die $!;
    local $/;
    return <$fh>;
}
