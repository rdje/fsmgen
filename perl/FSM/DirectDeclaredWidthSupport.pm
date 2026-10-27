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
use FSM::Backend::VHDL::ParameterBindingEmitter;
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

sub prepare_declarations ($class, %args) {
    my $source = $class->prepare_module(%args);
    my $json = JSON::PP->new->canonical->allow_nonref;
    my $target = eval {$json->decode($json->encode({namespace => $args{target_namespace},
        declarations => $args{target_declarations}}))};
    confess "Direct width target preparation requires JSON-safe namespace/declaration records: $@" if $@;
    my ($namespace, $declarations) = @{$target}{qw(namespace declarations)};
    confess "Direct width target preparation requires explicit namespace and declaration maps\n"
        unless ref($namespace) eq 'HASH' && ref($namespace->{identifier_map}) eq 'HASH'
            && ref($declarations) eq 'HASH';
    my $language = $source->{target_language};
    my $mapping = $namespace->{identifier_map};
    my $module_name = _target_identifier($language, $namespace->{module_name});
    my $physical_module = $args{fsm_module}->name;
    confess "Direct width target module mapping does not match the physical module\n"
        unless defined($physical_module) && !ref($physical_module)
            && ($mapping->{$physical_module} // $physical_module) eq $module_name;
    my $key = sub ($name) {return $language eq 'vhdl' ? lc($name) : $name};
    my %reserved = $language eq 'vhdl'
        ? map {$_ => 'generated type'} qw(natural std_logic std_logic_vector signed) : ();
    $reserved{$key->($module_name)} = 'module';
    my %roles;
    for my $bucket (qw(ports signals constants types parameter_names)) {
        confess "Direct width target namespace requires '$bucket' as an array\n"
            unless ref($namespace->{$bucket}) eq 'ARRAY';
        for my $raw (@{$namespace->{$bucket}}) {
            my $name = _target_identifier($language, $raw);
            my $identity = $key->($name);
            confess "Direct width target '$name' collides with $reserved{$identity}\n"
                if exists($reserved{$identity});
            $reserved{$identity} = $bucket;
            $roles{$name} = $bucket if $bucket eq 'ports' || $bucket eq 'signals';
        }
    }
    my %emitted = map {$_ => 1} @{$namespace->{parameter_names}};
    my %parameters;
    for my $name (sort keys %{$args{fsm_module}->parameters}) {
        my $target_name = _target_identifier($language, $mapping->{$name} // $name);
        confess "Direct width target parameter mapping has duplicate membership\n" if $parameters{$target_name}++;
    }
    confess "Direct width target emitted parameter membership does not match source mapping\n"
        unless keys(%parameters) == keys(%emitted) && !grep {!exists($emitted{$_})} keys %parameters;
    for my $name (@{$source->{parameter_references}}) {
        confess "Direct width target parameter '$name' renaming is unsupported\n"
            unless ($mapping->{$name} // $name) eq $name;
    }
    confess "Direct width target declaration membership does not match its namespace\n"
        unless keys(%roles) == keys(%$declarations) && !grep {!exists($declarations->{$_})} keys %roles;
    for my $name (sort keys %roles) {
        my $record = $declarations->{$name};
        confess "Direct width target declaration '$name' requires its actual name, positive width and signed flag\n"
            unless ref($record) eq 'HASH' && defined($record->{name}) && !ref($record->{name})
                && $record->{name} eq $name && defined($record->{width}) && !ref($record->{width})
                && $record->{width} =~ /\A[0-9]+\z/ && $record->{width} > 0
                && defined($record->{signed}) && !ref($record->{signed}) && $record->{signed} =~ /\A[01]\z/;
    }
    my (%signal_targets, %ranges, @fixed, %claimed);
    for my $name (@{$source->{signal_order}}) {
        my $target_name = _target_identifier($language, $mapping->{$name} // $name);
        confess "Direct width source Signal '$name' has no actual target declaration\n"
            unless exists($roles{$target_name});
        confess "Direct width target declaration '$target_name' has multiple source Signal owners\n"
            if $claimed{$target_name}++;
        my $signal = $source->{signals}{$name};
        my $record = $declarations->{$target_name};
        confess "Direct width target declaration '$target_name' disagrees with observed source width or signedness\n"
            unless $record->{width} == $signal->{width} && $record->{signed} == $signal->{signed};
        for my $field (qw(declared_type_name declared_type_spec)) {
            confess "Direct width target declaration '$target_name' disagrees with source $field\n"
                unless $json->encode($record->{$field}) eq $json->encode($signal->{$field});
        }
        confess "Direct width target declaration '$target_name' disagrees with source state model\n"
            if exists($record->{state_model})
                && $json->encode($record->{state_model}) ne $json->encode($signal->{state_model});
        $signal_targets{$name} = $target_name;
        my $width_plan = $signal->{width_plan};
        if ($width_plan && $width_plan->{profile} eq 'symbolic') {
            $ranges{$target_name} = {source_name => $name,
                declaration_kind => $roles{$target_name} eq 'ports' ? 'port' : 'signal', width_plan => $width_plan};
        } else {
            push @fixed, $target_name;
        }
    }
    return $json->decode($json->encode({profile => $source->{profile}, target_language => $language,
        source_scope => $source->{source_scope}, module_name => $module_name,
        parameter_references => $source->{parameter_references}, signal_targets => \%signal_targets,
        fixed_signals => \@fixed, ranges => \%ranges}));
}

sub _target_identifier ($language, $name) {
    return FSM::Backend::VHDL::ParameterBindingEmitter->validate_identifier($name) if $language eq 'vhdl';
    confess "Direct width target requires a simple declaration identifier\n"
        unless FSM::Support::HDLInstanceIdentifierPolicy->is_simple_identifier($name);
    confess "Direct width target declaration '$name' is reserved in SystemVerilog\n"
        if grep {$_ eq 'SystemVerilog'} @{FSM::Support::HDLInstanceIdentifierPolicy->reserved_target_languages($name)};
    return $name;
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
declaration namespaces are checked by C<prepare_declarations>, described below.

C<prepare_declarations> takes the same source arguments plus a backend-owned
C<target_namespace> and C<target_declarations> map. The namespace contains the
actual C<module_name>, original-to-target C<identifier_map> and complete target
C<parameter_names>, C<ports>, C<signals>, C<constants> and C<types> name arrays.
The declaration map covers exactly the ports and signals. Each row has its
actual C<name>, positive C<width>, boolean C<signed> and optional declared-type
name/spec and state model. Captured declaration metadata must be supplied from
the backend plan; it cannot be reconstructed by equal numeric widths.

Shared identifier policies check reserved names, namespace collisions and
VHDL case folding. Complete emitted parameter membership must match the actual
source mapping. Selected width roots cannot be renamed. Physical module and
signal mappings remain separate from lexical scope. Every actual source Signal
must match one target declaration with the same observed width, signedness and
declared type; a supplied state model must agree too.

The detached target result contains C<profile>, C<target_language>,
C<source_scope>, actual C<module_name>, ordered unique C<parameter_references>,
C<signal_targets>, C<fixed_signals> and C<ranges>. Each symbolic range entry
contains physical C<source_name>, C<declaration_kind> (port or signal) and the
proved C<width_plan>. Independent static/type rows stay on their fixed path.
Caller-made target records remain a contract, not provenance attestation.

The direct Verilog-family post-flattening owner now consumes these checks for
captured declarations before returning HDL. Port ranges retain actual selected
names and vector rank; complete actual target qualification and comparison with
the emitted port plans reject late same-default ancestry changes. Storage,
computed helper shapes and source-aware VHDL ranges remain separately owned.
Full compiler, override and runtime qualification remains pending. Whole backend
release is not claimed: task C<ISF-REDUCTION-DELIVERY.25> owns the independent
context/helper back-reference cycle reproduced without these preparation calls.

=cut
