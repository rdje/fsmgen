use strict;
use warnings;
use lib 'perl';
use JSON::PP;
use Scalar::Util qw(blessed refaddr);
use FSM::Adapter::ISF;
use FSM::Adapter::IAL2::PPIF;
use FSM::Scheduler::ISF;
use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::HDL::FlattenedDT;
use FSM::CoreExpressionWidthSupport;

my $literal = 'FSM::HDL::FlattenedDT::Backend::SystemVerilog::SourceLiteralWidthSupport';
my $fence = $literal->can('capture_generation_fence');
my $lowered = FSM::Adapter::IAL2::PPIF->new->parse_file('ppif/ahb_lite_subordinate.ppif');
my $text = $lowered->{generated_ial0}{files}{'ahb_lite_subordinate.fsm'};
my $module = FSM::Adapter::FSMGenFull->new->parse_fsm(scalar Lispish::multi(\$text));
my $ctx = FSM::HDL::FlattenedDT->new;
my @selected;

sub tree {
    my ($node, $active, $budget, $depth) = @_;
    return {boundary => 'unblessed'} unless blessed($node);
    return {boundary => 'bounded'} if $depth > FSM::CoreExpressionWidthSupport::MAX_DEPTH() || --$$budget < 0;
    my $id = refaddr($node);
    return {boundary => 'cycle'} if $active->{$id};
    local $active->{$id} = 1;
    my $out = {class => ref($node)};
    if ($node->isa('FSM::CoreAST::Literal')) {
        $out->{$_} = $node->{$_} for qw(value width radix);
    } elsif ($node->isa('FSM::CoreAST::SignalRef')) {
        my $signal = $node->{signal};
        $out->{signal} = {name => $signal->{name}, width => $signal->{_width},
            intermediate => $signal->{attributes}{is_intermediate} ? 1 : 0};
        $out->{driving} = tree($signal->{driving_ast}, $active, $budget, $depth + 1)
            if $signal->{attributes}{is_intermediate} && blessed($signal->{driving_ast});
    } elsif (ref($node->{operands}) eq 'ARRAY') {
        $out->{operator} = $node->{operator};
        $out->{operands} = [map {tree($_, $active, $budget, $depth + 1)} @{$node->{operands}}];
    }
    return $out;
}

my $error;
{
    no strict 'refs'; no warnings 'redefine';
    local *{"${literal}::capture_generation_fence"} = sub {
        my ($class, %args) = @_;
        for my $name (sort keys %{$args{signal_registry}}) {
            my $signal = $args{flattened_dt}{fsm_module}{signals}{$name};
            next unless $class->requires_emission($signal, $args{signal_registry});
            my $budget = FSM::CoreExpressionWidthSupport::MAX_NODES();
            push @selected, {name => $name, source_holder_present => exists($signal->{_source_literal_width_allocation}) ? 1 : 0,
                ast => tree($signal->{driving_ast}, {}, \$budget, 0)};
        }
        return $fence->(@_);
    };
    eval {$ctx->generate_systemverilog($module); 1} or $error = $@;
}
print JSON::PP->new->canonical->pretty->encode({carrier => $text, selected => \@selected,
    generation_error => $error, observation_scope => 'Raw bounded AST projection before the original generation-fence call; no source getters or authority writes in the observer. The independent uninstrumented CLI and T1309 failure establish the actual regression.'});
