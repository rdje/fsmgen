package FSM::Support::ISFRecordPortSamples;

use strict;
use warnings;
use Carp qw(confess);
use Exporter 'import';
use Storable qw(dclone);
use FSM::Support::ISFRecordPortScopes qw(record_context_scope record_reference_root_kind);
use FSM::Support::ISFRecordPortValues qw(record_value_scope record_value_reference);
use FSM::Composition::InterfacePortBuilder;

our @EXPORT_OK = qw(record_transaction_samples record_sample_type_products actor_has_record_input actor_has_record_port);

sub actor_has_record_input {
    my %args = @_;
    _arguments(\%args, [qw(actor)]);
    _require(ref($args{actor}) eq 'HASH', 'record-input selection requires an actor');
    my $interface = $args{actor}{interface};
    _require(!defined($interface) || ref($interface) eq 'HASH', 'record-input selection requires an interface map');
    my $inputs = ($interface || {})->{inputs};
    _require(!defined($inputs) || ref($inputs) eq 'ARRAY', 'record-input selection requires an input list');
    my $found = 0;
    for my $entry (@{$inputs || []}) {
        # Reading a hash member of an undefined array entry autovivifies the
        # caller's entry. Reject shape before the first dereference.
        _require(ref($entry) eq 'HASH', 'record-input selection requires declared input maps');
        $found = 1 if ref($entry->{type_spec}) eq 'HASH' && ($entry->{type_spec}{kind} // '') eq 'record';
    }
    return $found;
}

sub actor_has_record_port {
    my %args = @_;
    # Keep the legacy input selector's contract and diagnostics intact, but
    # always inspect the complete output list even when an input is known.
    my $found = actor_has_record_input(%args);
    my $outputs = ($args{actor}{interface} || {})->{outputs};
    _require(!defined($outputs) || ref($outputs) eq 'ARRAY',
        'record-port selection requires an output list');
    for my $entry (@{$outputs || []}) {
        _require(ref($entry) eq 'HASH', 'record-port selection requires declared output maps');
        $found = 1 if ref($entry->{type_spec}) eq 'HASH'
            && ($entry->{type_spec}{kind} // '') eq 'record';
    }
    return $found;
}

# Detached preparation only. Neither capture states nor authored admission are
# changed here. Existing grammar/context validators still own clause placement.
sub record_transaction_samples {
    my %args = @_;
    _arguments(\%args, [qw(actor transaction)], [qw(port_only)]);
    my $port_only = $args{port_only} // 0;
    _require(defined($port_only) && !ref($port_only) && scalar($port_only =~ /\A[01]\z/), 'port-only selection must be binary');
    my $context = record_context_scope(actor => $args{actor}, transaction => $args{transaction});
    my %declared = map {$_ => 1} (keys %{$context->{roots}}, keys %{$context->{rule_declared_roots}});
    my @clauses;
    _collect($args{transaction}{clauses}, \@clauses);
    my (%bindings, %derived, @samples, @unresolved);
    for my $clause (@clauses) {
        my $label = "transaction '$args{transaction}{name}' sample";
        _require(@$clause == 4 && _text($clause->[1])
            && _text($clause->[2]) && $clause->[2] eq 'as' && _identifier($clause->[3]),
            "$label requires '(sample scalar as identifier)'");
        my ($source, $alias) = @$clause[1, 3];
        my $kind = record_reference_root_kind(context => $context, token => $source);
        my ($source_root) = $source =~ /\A([A-Za-z_]\w*)/;
        my $binding = defined($source_root) ? $context->{roots}{$source_root} : undef;
        # Existing packed storage samples retain their width/inference owner.
        # The input delivery consumer adds scalar facts only for port leaves or
        # aliases already derived from those leaves.
        my $delegated = $port_only && $binding && _aggregate($binding->{type_spec})
            && $binding->{role} ne 'input' && $binding->{role} ne 'output';
        my $value = !$delegated && defined($kind) && $kind eq 'declaration'
            ? record_value_reference(scope => $context->{roots}, token => $source,
                access => 'read', context => $label) : undef;
        push @unresolved, [$source, $source_root] if !$value && defined($source_root)
            && (!defined($kind) || $kind ne 'namespace');
        my $root = $value ? $value->{root} : undef;
        my $record = defined($root) && (_aggregate($context->{roots}{$root}{type_spec}) || $derived{$root}) ? 1 : 0;
        my $prior = $context->{roots}{$alias};
        _require(!$prior || $prior->{role} ne 'input', "$label cannot write declared input '$alias'");
        # Inferred record-leaf aliases are private carriers, not a way to
        # replace an existing formal/local/storage/output declaration or its
        # reset/type facts. Repeated samples may reuse their own same type.
        _require(!$record || !exists($declared{$alias}),
            "$label record-derived alias '$alias' collides with a declaration");
        my $spec = $value ? $value->{type_spec} : undef;
        if (exists $bindings{$alias} && ($record || $derived{$alias})) {
            _require(defined($spec) && defined($bindings{$alias}{type_spec})
                && !FSM::Composition::InterfacePortBuilder->declared_type_conflicts(
                    $spec, $bindings{$alias}{type_spec}),
                "$label repeated alias '$alias' requires the same resolved scalar type");
        }
        $bindings{$alias} = {role => 'local', type_spec => $spec ? dclone($spec) : undef};
        $derived{$alias} = 1 if $record;
        $context->{roots} = record_value_scope(outer => $context->{roots}, local => {$alias => $bindings{$alias}});
        push @samples, {source => $source, alias => $alias, record_derived => $record,
            reference => $value ? dclone($value) : undef};
    }
    for my $unresolved (@unresolved) {
        _require(!$derived{$unresolved->[1]},
            "transaction '$args{transaction}{name}' sample uses record-derived alias '$unresolved->[0]' before its declaration");
    }
    return {samples => \@samples, bindings => \%bindings, record_aliases => \%derived};
}

# Produce the same core scalar declaration AST used by actor types. Generated
# aliases reserve names deterministically; no reset/default or backend default
# state model is synthesized. Only record-derived aliases need new carriers.
sub record_sample_type_products {
    my %args = @_;
    _arguments(\%args, [qw(bindings record_aliases reserved_names)]);
    my $bindings = record_value_scope(outer => {}, local => $args{bindings});
    _require(ref($args{record_aliases}) eq 'HASH' && ref($args{reserved_names}) eq 'ARRAY',
        'type products require record-alias map and reserved-name list');
    my %used;
    for my $name (@{$args{reserved_names}}) {
        _require(_text($name), 'reserved type name must be scalar text');
        $used{$name} = 1;
    }
    my (@types, %refs, %widths);
    for my $alias (sort keys %{$args{record_aliases}}) {
        _require(_identifier($alias) && _text($args{record_aliases}{$alias})
            && $args{record_aliases}{$alias} eq '1'
            && exists($bindings->{$alias}) && $bindings->{$alias}{role} eq 'local',
            'record alias requires a local sample binding');
        my $spec = $bindings->{$alias}{type_spec};
        _require(ref($spec) eq 'HASH' && !_aggregate($spec), "sample alias '$alias' lacks a resolved scalar type");
        my $base = "_isf_sample_$alias";
        my $name = $base;
        my $suffix = 0;
        $name = $base . '_' . ++$suffix while $used{$name};
        $used{$name} = 1;
        my $expression = $spec->{kind} eq 'bit' ? 'bit' : ['bits', 0 + $spec->{width}];
        $expression = ['signed', $expression] if $spec->{signed};
        $expression = [$spec->{state_model}, $expression] if exists $spec->{state_model};
        push @types, ['type', $name, $expression];
        $refs{$alias} = $name;
        $widths{$alias} = 0 + $spec->{width};
    }
    return {type_declarations => \@types, signal_type_refs => \%refs, signal_widths => \%widths};
}

sub _collect {
    my ($clauses, $samples) = @_;
    _require(ref($clauses) eq 'ARRAY', 'sample collection requires transaction clauses');
    for my $clause (@$clauses) {
        next unless ref($clause) eq 'ARRAY' && @$clause && _text($clause->[0]);
        my $head = $clause->[0];
        if ($head eq 'sample') {
            push @$samples, $clause;
        } elsif ($head =~ /\A(?:on|when|while|until|repeat)\z/) {
            _collect([@$clause[2 .. $#$clause]], $samples);
        } elsif ($head eq 'switch') {
            for my $branch (@$clause[2 .. $#$clause]) {
                next unless ref($branch) eq 'ARRAY' && @$branch;
                _collect([@$branch[1 .. $#$branch]], $samples);
            }
        }
    }
}
sub _aggregate {
    my ($spec) = @_;
    return ref($spec) eq 'HASH' && ($spec->{kind} eq 'record' || $spec->{kind} eq 'list') ? 1 : 0;
}
sub _identifier { _text($_[0]) && $_[0] =~ /\A[A-Za-z_]\w*\z/ ? 1 : 0 }
sub _text { defined($_[0]) && !ref($_[0]) && length($_[0]) ? 1 : 0 }
sub _arguments {
    my ($args, $names, $optional) = @_;
    my %allowed = map {$_ => 1} (@$names, @{$optional || []});
    _require(!grep(!exists($args->{$_}), @$names), 'missing sample argument');
    _require(!grep(!$allowed{$_}, keys %$args), 'unknown sample argument');
}
sub _require {
    confess "Invalid ISF record sample: validation requires predicate and message\n" unless @_ == 2;
    confess "Invalid ISF record sample: $_[1]\n" unless $_[0];
}

1;
