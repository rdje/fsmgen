package FSM::DirectDeclaredWidthSupport;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use Scalar::Util qw(blessed refaddr);
use feature qw(signatures);
no warnings 'experimental::signatures';
use JSON::PP ();
use FSM::ParameterDefaultEnvironmentSupport;
use FSM::DeclaredWidthRangeSupport;
use FSM::Support::HDLInstanceIdentifierPolicy;

sub prepare_module ($class, %args) {
    my $module = $args{fsm_module};
    confess "Direct module width preparation requires a Core module\n"
        unless blessed($module) && $module->isa('FSM::CoreAST::FSMModule');
    my %languages = (systemverilog => 'systemverilog', sv => 'systemverilog',
        verilog => 'verilog', v => 'verilog', vhdl => 'vhdl');
    my $language = $args{target_language};
    confess "Direct module width preparation requires a supported target language\n"
        unless defined($language) && !ref($language) && exists($languages{lc($language)});
    $language = $languages{lc($language)};
    my $analysis = $args{assignment_analysis};
    confess "Direct module width preparation requires complete assignment analysis\n"
        unless ref($analysis) eq 'HASH' && ref($module->signals) eq 'HASH';
    my %signals;
    for my $name (sort keys %{$module->signals}) {
        my $signal = $module->signals->{$name};
        _add_signal(\%signals, $signal);
        confess "Direct module width Signal membership does not match '$name'\n"
            unless $name eq $signal->name;
    }
    for my $name (sort keys %$analysis) {
        my $entry = $analysis->{$name};
        my $lhs = ref($entry) eq 'HASH' ? $entry->{lhs_ast} : undef;
        confess "Direct module width assignment '$name' requires a normalized SignalRef\n"
            unless blessed($lhs) && $lhs->isa('FSM::CoreAST::SignalRef');
        _add_signal(\%signals, $lhs->signal);
    }
    my $json = JSON::PP->new->canonical;
    my $maps = eval {$json->decode($json->encode({parameters => $module->parameters,
        sources => $module->parameter_default_sources, bindings => $module->parameter_default_bindings}))};
    confess "Direct module width preparation requires JSON-safe captured parameter maps: $@" if $@;
    confess "Direct module width preparation requires parameter, source and binding maps\n"
        if grep {ref($maps->{$_}) ne 'HASH'} qw(parameters sources bindings);
    my $environment;
    if (keys(%{$maps->{sources}}) || keys(%{$maps->{bindings}})) {
        $environment = FSM::ParameterDefaultEnvironmentSupport->prove_binding_observations(%$maps)->{environment};
    }
    my $scope = $environment ? $environment->{scope} : undef;
    my (%plans, %seen_parameters, @parameters, $symbolic);
    for my $name (sort keys %signals) {
        my $signal = $signals{$name};
        my $width = $signal->width;
        confess "Direct module width Signal '$name' requires a positive numeric width\n"
            unless defined($width) && !ref($width) && $width =~ /\A[0-9]+\z/ && $width > 0;
        my $binding = $signal->declared_width_binding;
        my $requirements = $signal->declared_width_requirements;
        _join_scope(\$scope, $binding->{scope}, $json) if $binding;
        _join_scope(\$scope, $requirements->{scope}, $json) if $requirements;
        if ($requirements) {
            my $mutable = grep {
                my $capture = $_->{width_capture};
                $capture && grep {$_->{kind} eq 'parameter'} @{$capture->{observations}};
            } @{$requirements->{requirements}};
            confess "Direct module '$name' has a combined mutable width shape pending specialization\n"
                if $mutable && @{$requirements->{requirements}} > 1;
            confess "Direct module '$name' has a missing coherent width binding\n" if $mutable && !$binding;
            if ($binding) {
                my $entry = $requirements->{requirements}[0];
                my $expected = {%{$entry->{width_capture} // {}},
                    signal => $entry->{signal}, expression => $entry->{expression}};
                confess "Direct module '$name' has inconsistent width binding and requirement snapshots\n"
                    unless @{$requirements->{requirements}} == 1
                        && $json->encode($binding) eq $json->encode($expected);
            }
        }
        confess "Direct module '$name' has a missing coherent width binding\n"
            if !$binding && defined($signal->declared_width_source);
        my $width_plan;
        if ($binding) {
            confess "Direct module '$name' width requires captured parameter declarations\n"
                if !$environment && keys(%{$maps->{parameters}});
            my $direct_environment = $environment // {scope => $scope, parameters => {}, declaration_order => []};
            $width_plan = FSM::DeclaredWidthRangeSupport->prepare_signal(
                signal => $signal, environment => $direct_environment, target_language => $language);
            $symbolic ||= $width_plan->{profile} eq 'symbolic';
            for my $parameter (@{$width_plan->{parameter_references}}) {
                push @parameters, $parameter unless $seen_parameters{$parameter}++;
            }
        }
        $plans{$name} = {name => $name, width => 0 + $width,
            signed => $signal->signed ? 1 : 0, state_model => $signal->state_model,
            declared_type_name => $signal->declared_type_name,
            declared_type_spec => $signal->declared_type_spec, width_plan => $width_plan};
    }
    return $json->decode($json->encode({profile => $symbolic ? 'symbolic' : 'fixed',
        target_language => $language, source_scope => $scope,
        signal_order => [sort keys %plans], signals => \%plans, parameter_references => \@parameters}));
}

sub _add_signal ($signals, $signal) {
    confess "Direct module width membership requires an actual Core Signal\n"
        unless blessed($signal) && $signal->isa('FSM::CoreAST::Signal');
    my $name = $signal->name;
    confess "Direct module width Signal requires a simple physical name\n"
        unless FSM::Support::HDLInstanceIdentifierPolicy->is_simple_identifier($name);
    confess "Direct module width membership has distinct actual Signals named '$name'\n"
        if exists($signals->{$name}) && refaddr($signals->{$name}) != refaddr($signal);
    $signals->{$name} = $signal;
}

sub _join_scope ($current, $candidate, $json) {
    confess "Direct module width captures have conflicting original source scope\n"
        if defined($$current) && $json->encode($$current) ne $json->encode($candidate);
    $$current //= $candidate;
}

1;

=head1 NAME

FSM::DirectDeclaredWidthSupport - Prepare actual direct module source-width plans

=head1 DESCRIPTION

C<prepare_module> consumes an actual Core C<fsm_module>, complete normalized
backend C<assignment_analysis> and C<target_language> (SystemVerilog/sv,
Verilog/v or VHDL). It joins module Signal membership with the actual Signals
held by normalized assignment C<lhs_ast> SignalRefs. One actual object reached
twice deduplicates; distinct objects claiming one physical name refuse.

Copied canonical module parameter maps pass the existing observation proof.
Coherent width bindings pass C<DeclaredWidthRangeSupport> with original lexical
scope, independent of the physical module name. Requirements and bindings must
agree. Combined mutable shapes, missing/stale coherent captures, foreign scope,
malformed membership and unsupported target profiles refuse instead of freezing
selected defaults. Independent fixed and named-type declarations retain their
numeric/type attributes. Legacy numeric modules gain no invented source scope.

The detached result contains C<profile> (symbolic or fixed), canonical
C<target_language>, optional original C<source_scope>, sorted C<signal_order>,
C<signals> and first-use unique C<parameter_references>. Each signal record
contains physical C<name>, numeric C<width>, C<signed>, C<state_model>,
C<declared_type_name>, C<declared_type_spec> and optional captured C<width_plan>.
The result retains no Core module, Signal or backend analysis graph.

This is source-object preparation. Complete analysis membership is a caller
contract, not attestation of caller-made objects. Actual target names and full
declaration namespaces, computed helper shapes and declaration activation
remain separate work; ordinary runtime generation does not import this helper
yet. Full compiler, override and runtime qualification remains separately owned.

=cut
