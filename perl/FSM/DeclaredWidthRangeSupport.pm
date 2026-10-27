package FSM::DeclaredWidthRangeSupport;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use feature qw(signatures);
no warnings 'experimental::signatures';
use JSON::PP ();
use FSM::DeclaredWidthBindingSupport;
use FSM::WidthExpressionSupport;
use FSM::Backend::VerilogFamily::WidthExpressionEmitter;
use FSM::Backend::VHDL::WidthExpressionEmitter;
use FSM::Backend::VHDL::ParameterBindingEmitter;

sub prepare_signal ($class, %args) {
    my $language = $args{target_language};
    confess "Direct declared-width range requires a supported target language\n"
        unless defined($language) && !ref($language)
            && lc($language) =~ /\A(?:systemverilog|sv|verilog|v|vhdl)\z/;
    $language = lc($language);
    $language = 'systemverilog' if $language eq 'sv';
    $language = 'verilog' if $language eq 'v';
    my $json = JSON::PP->new->canonical;
    my $environment = eval {$json->decode($json->encode($args{environment}))};
    confess "Direct declared-width range requires JSON-safe acyclic environment: $@" if $@;
    my $proof = FSM::DeclaredWidthBindingSupport->prove_signal(
        signal => $args{signal}, environment => $environment);
    my $capture = $proof->{capture};
    my $plan = {profile => 'fixed', target_language => $language,
        source_scope => $capture->{scope}, source_signal => $capture->{signal},
        width => $capture->{width}, is_vector => $capture->{width} > 1 ? 1 : 0,
        parameter_references => [], width_contract => undef, range_text => undef};
    # A static capture must retain the existing numeric declaration/rank path.
    # Only actual selected mutable observations request a new symbolic range.
    if ($proof->{has_parameter_references}) {
        my $state = {capture => $capture, environment => $environment,
            language => $language, references => [], parameters => [],
            evaluator => FSM::WidthExpressionSupport->new};
        my $expression = _expression($state, $capture->{binding});
        my $contract = {scope => $capture->{scope}, expression => $expression,
            references => $state->{references}};
        my $emitter = $language eq 'vhdl'
            ? 'FSM::Backend::VHDL::WidthExpressionEmitter'
            : 'FSM::Backend::VerilogFamily::WidthExpressionEmitter';
        $plan->{range_text} = $emitter->lower_range(
            port => {name => $capture->{signal}, width => $capture->{width}, width_contract => $contract},
            environment => $environment, target_language => $language,
            required_scope_kind => 'direct_module');
        @{$plan}{qw(profile is_vector width_contract parameter_references)} =
            ('symbolic', 1, $contract, $state->{parameters});
    }
    return $json->decode($json->encode($plan));
}

sub _contains_reference ($state, $node, $parameters_only) {
    my $kind = $node->{kind};
    if ($kind eq 'reference') {
        return 1 unless $parameters_only;
        return 1 if $state->{capture}{observations}[$node->{observation_index}]{kind} eq 'parameter';
        return _contains_reference($state, $node->{value_expression}, $parameters_only);
    }
    return 0 unless $kind eq 'operator';
    for my $operand (@{$node->{operands}}) {
        return 1 if _contains_reference($state, $operand, $parameters_only);
    }
    return 0;
}

sub _expression ($state, $node) {
    # The proof already checked this closed graph against the canonical walk.
    my $kind = $node->{kind};
    return sprintf('%s', $node->{token}) if $kind eq 'literal';
    if ($kind eq 'operator') {
        my $operator = $state->{evaluator}->normalize_constant_width_operator($node->{operator});
        confess "Direct declared-width range uses an unsupported VHDL operator\n"
            if $state->{language} eq 'vhdl' && $operator !~ /\A[+*\/%-]\z/;
        # Preserve the tree: target kernels own all arithmetic and intermediate
        # bounds, including static subtrees. Never pre-fold to bypass a check.
        return [$operator, map {_expression($state, $_)} @{$node->{operands}}];
    }
    my $observation = $state->{capture}{observations}[$node->{observation_index}];
    if ($observation->{kind} eq 'static_symbol') {
        confess "Direct declared-width range has a hidden mutable payload dependency\n"
            if _contains_reference($state, $node->{value_expression}, 1);
        return _expression($state, $node->{value_expression});
    }
    my $name = $observation->{parameter};
    confess "Direct declared-width range does not support mutable parameter paths\n"
        if length($observation->{suffix});
    my $info = $state->{environment}{parameters}{$name};
    confess "Direct declared-width range requires a scalar parameter profile\n"
        unless ($info->{value_kind} // '') eq 'scalar';
    my $type = $info->{value_type_spec};
    confess "Direct declared-width range has an unsupported typed parameter profile\n"
        if defined($type) && (ref($type) ne 'HASH' || ($type->{kind} // '') !~ /\A(?:bit|bits)\z/);
    confess "Direct declared-width range has a nested symbol-bearing parameter payload\n"
        if _contains_reference($state, $node->{value_expression}, 0);
    FSM::Backend::VHDL::ParameterBindingEmitter->validate_integer_payload($info->{value_payload})
        if $state->{language} eq 'vhdl';
    push @{$state->{references}}, {kind => 'parameter', token => $name};
    push @{$state->{parameters}}, $name;
    return ['param', $name];
}

1;

=head1 NAME

FSM::DeclaredWidthRangeSupport - Bounded target adaptation of proved direct width captures

=head1 DESCRIPTION

C<prepare_signal> takes an actual Core C<signal>, prepared direct C<environment>
and C<target_language> (SystemVerilog/sv, Verilog/v or VHDL). It copies the
environment, invokes C<DeclaredWidthBindingSupport::prove_signal> and converts
only the proved binding graph to the shared target width contract.

Selected scalar roots retain their observed names and repeated order. Pinned
static trees inline structurally; target kernels retain responsibility for
arithmetic, target bounds and range spelling. Selected one-bit widths remain
vectors. Fully static captures return a fixed plan with the existing numeric
rank and no new contract or range text.

The detached plan contains C<profile>, canonical C<target_language>, original
C<source_scope> and C<source_signal>, observed C<width>, numeric C<is_vector>,
ordered emitted C<parameter_references>, C<width_contract> and C<range_text>.
Fixed plans have undefined contract/text. Original source/default records are
read-only; returned plans retain neither Signal nor environment objects.

Mutable paths, non-scalar or unsupported typed roots, nested symbol-bearing
parameter payloads and static payloads hiding mutable dependencies refuse.
VHDL also requires portable natural payloads and arithmetic-only operators;
the existing kernel checks each intermediate value. No new evaluator, numeric
ancestry inference or raw HDL substitution is introduced. Consistency proof
does not attest arbitrary caller authorship. Actual module membership, full
target namespaces, declaration activation and complete compiler/runtime
qualification remain separate work.

=cut
