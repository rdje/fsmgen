use strict;
use warnings;
use lib 'perl';
use JSON::PP;
use Scalar::Util qw(refaddr);
use FSM::CoreAST;
use FSM::ExpressionNamer;
use FSM::HDL::FlattenedDT;

# Observe only the fixed, already retained native guard/RHS producer. No HDL
# compiler, generic override, simulator or external caller population is run.
my $json = JSON::PP->new->canonical;
my %calls = (typed_concat => 0, definition_reads => 0, string_names => 0);
my @collections;
sub operand {
    my ($node, $module) = @_;
    if (ref($node) eq 'FSM::CoreAST::Concatenation') {
        return ['concat', map {operand($_,$module)} @{$node->operands}];
    }
    if (ref($node) eq 'FSM::CoreAST::Literal') {
        return ['literal', {value=>$node->value, width=>$node->width, radix=>$node->radix}];
    }
    die 'unexpected source operand' unless ref($node) eq 'FSM::CoreAST::SignalRef' && !defined($node->slice);
    my $source = $node->signal;
    my $member = $module->signals->{$source->name};
    return ['signal', {name=>$source->name, width=>$source->width,
        signed=>$source->signed, type=>$source->type, constraints=>$source->constraints,
        source=>$source->declared_width_source, binding=>$source->declared_width_binding,
        requirements=>$source->declared_width_requirements,
        actual_module_member=>($member && refaddr($member)==refaddr($source)) ? JSON::PP::true : JSON::PP::false}];
}
{
    no warnings 'redefine';
    my $typed = \&FSM::ExpressionNamer::name_concatenation_ast;
    my $definitions = \&FSM::ExpressionNamer::get_signal_definitions;
    my $strings = \&FSM::ExpressionNamer::parse_and_name_expression;
    *FSM::ExpressionNamer::name_concatenation_ast = sub {++$calls{typed_concat}; goto &$typed};
    *FSM::ExpressionNamer::get_signal_definitions = sub {++$calls{definition_reads}; goto &$definitions};
    *FSM::ExpressionNamer::parse_and_name_expression = sub {++$calls{string_names}; goto &$strings};
    my $collect = \&FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateSupport::collect_consolidated_intermediate_signals;
    *FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateSupport::collect_consolidated_intermediate_signals = sub {
        my ($owner,$module) = @_;
        my $rows = $collect->(@_);
        my $ctx = $owner->{flattened_dt};
        my @concats;
        for my $name (sort keys %$rows) {
            my $row=$rows->{$name};
            next unless ref($row->{ast}) eq 'FSM::CoreAST::Concatenation';
            push @concats, {name=>$name, source=>$row->{source}, width=>$row->{width},
                width_source=>$row->{width_source}, operands=>operand($row->{ast},$module),
                birth=>$ctx->{ast_factorizer}->concatenation_width_birth($name)};
        }
        push @collections, {module=>$module->name, concats=>\@concats,
            named_owner_class=>ref($ctx->{expr_namer}),
            named_definition_count=>scalar keys %{$ctx->{expr_namer}{_signal_definitions}}};
        return $rows;
    };
}
my $native_output = '';
{
    open my $capture, '>', \$native_output or die $!;
    local *STDOUT = $capture;
    do './docs/audits/concat-guard-capture-20261030/probe.pl';
    die $@ if $@;
}
my $native_calls = {%calls};
# Independently exercise both otherwise-unused typed hooks. This demonstrates
# observation capability without converting a zero count into a universal claim.
my $control = FSM::ExpressionNamer->new;
my $ast = FSM::CoreAST::Concatenation->new(map {
    FSM::CoreAST::SignalRef->new(FSM::CoreAST::Signal->new(name=>$_,width=>8))
} qw(CONTROL_A CONTROL_B));
my $name = $control->name_ast_expression($ast);
my $definitions = $control->get_signal_definitions;
die 'positive observation control failed' unless $calls{typed_concat}==$native_calls->{typed_concat}+1
    && $calls{definition_reads}==$native_calls->{definition_reads}+1
    && $definitions->{$name}{width}==16;
print $json->pretty->encode({native=>decode_json($native_output), native_calls=>$native_calls,
    collections=>\@collections, control=>{calls=>\%calls, actual_name=>$name,
        definition_width=>$definitions->{$name}{width}}});
