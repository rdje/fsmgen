#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;
use FindBin;
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Debug qw(
    capture_fsm_debug_state
    restore_fsm_debug_state
    set_fsm_debug_level
);
use FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateSupport;

{
    package Local::UntouchableModule;

    sub new { bless {}, shift }
    sub signals { die "disabled inventory trace touched the FSM module\n" }
}

{
    package Local::TraceAST;

    sub new { bless { render_count => 0 }, shift }
    sub to_systemverilog {
        my ($self) = @_;
        $self->{render_count}++;
        return 'ready && valid';
    }
}

{
    package Local::TraceSignal;

    sub new {
        my ($class, $ast) = @_;
        return bless { ast => $ast }, $class;
    }
    sub driving_ast { return $_[0]->{ast} }
    sub get_attribute { return 0 }
}

{
    package Local::TraceModule;

    sub new {
        my ($class, $signals) = @_;
        return bless { signals => $signals }, $class;
    }
    sub signals { return $_[0]->{signals} }
}

my $saved_debug_state = capture_fsm_debug_state();
END { restore_fsm_debug_state($saved_debug_state) if $saved_debug_state }

my $support =
    FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateSupport
        ->new(flattened_dt => {});

for my $level (0, 2) {
    set_fsm_debug_level($level);
    my $ok = eval {
        $support->trace_fsm_signal_inventory(Local::UntouchableModule->new());
        1;
    };
    ok($ok, "debug level $level skips inventory traversal before touching the module");
    diag($@) unless $ok;
}

my $ast = Local::TraceAST->new();
my $module = Local::TraceModule->new({
    handshake_ready => Local::TraceSignal->new($ast),
});
my $trace = '';

set_fsm_debug_level(3);
{
    open my $capture, '>', \$trace or die "cannot open scalar trace capture: $!";
    local *STDOUT = $capture;
    $support->trace_fsm_signal_inventory($module);
    close $capture or die "cannot close scalar trace capture: $!";
}

is($ast->{render_count}, 1, 'level-3 inventory renders the driving AST exactly once');
like($trace, qr/SIGNAL_TRACE: FSM module has 1 total signals/, 'level-3 inventory retains its entry summary');
like($trace, qr/SystemVerilog expression: ready && valid/, 'level-3 inventory retains the rendered expression');
like($trace, qr/handshake_ready_AST.*Local::TraceAST/s, 'level-3 inventory retains the Data::Dumper AST detail');

restore_fsm_debug_state($saved_debug_state);
$saved_debug_state = undef;

done_testing();
