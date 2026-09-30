package FSM::Support::ISFRecordPortContexts;

use strict;
use warnings;
use Carp qw(confess);
use Exporter 'import';
use FSM::Support::ISFRecordPortScopes qw(record_actor_scope record_transaction_scope record_drive_scope);
use FSM::Support::ISFRecordPortValues qw(record_value_reference validate_record_port_copy);

our @EXPORT_OK = qw(validate_actor_record_contexts);

# Preparation only: this checks declaration references, not the complete source
# grammar. Existing validators still own unknown tokens, arity, operators and
# namespace/static-symbol resolution. Sampling and domain gates are separate.
sub validate_actor_record_contexts {
    my %args = @_;
    _require(keys(%args) == 1 && ref($args{actor}) eq 'HASH', 'requires one actor map');
    my $actor = $args{actor};
    my $outer = record_actor_scope(actor => $actor);
    my $scope = _context_scope($outer, $outer, $actor);
    for my $tx (@{$actor->{transactions} || []}) {
        my $local = _context_scope(record_transaction_scope(actor => $actor, transaction => $tx), $outer, $actor);
        _clauses($tx->{clauses}, $local, $actor, "transaction '$tx->{name}'");
    }
    for my $rule (@{$actor->{rules} || []}) {
        my $context = "rule '$rule->{name}'";
        _scalar($rule->{when}[1], $scope, "$context guard") if $rule->{when};
        for my $action (@{$rule->{actions} || []}) {
            my $head = $action->[0];
            if ($head eq 'set') {
                _assignment($action->[1], $action->[2], $scope, "$context assignment");
            } elsif ($head eq 'pulse') {
                _scalar_target($action->[1], $scope, "$context pulse target");
            } elsif ($head =~ /\A(?:trigger|atl_trigger|atl_trigger_batch|priority|store|load)\z/) {
                _unsupported($action, $scope, "$context $head");
            } else {
                _assignment($head, $action->[1], $scope, "$context assignment");
            }
        }
    }
    for my $name (sort keys %{$actor->{drives} || {}}) {
        my $drive = $actor->{drives}{$name};
        my $local = _context_scope(record_drive_scope(actor => $actor, drive => $drive), $outer, $actor);
        _drive_body($drive->{body}, $local, "drive '$name'");
    }
    return 1;
}

sub _clauses {
    my ($clauses, $scope, $actor, $context) = @_;
    for my $clause (@{$clauses || []}) {
        next unless ref($clause) eq 'ARRAY' && @$clause;
        my $head = $clause->[0];
        next unless defined($head) && !ref($head);
        if ($head eq 'set' || $head eq 'update') {
            _assignment($clause->[1], $clause->[2], $scope, "$context $head");
            _unsupported($_, $scope, "$context $head extra operand") for @{$clause}[3 .. $#$clause];
        } elsif ($head eq 'when' || $head eq 'while' || $head eq 'until') {
            _scalar($clause->[1], $scope, "$context $head condition");
            _clauses([@{$clause}[2 .. $#$clause]], $scope, $actor, "$context $head body");
        } elsif ($head eq 'repeat') {
            _unsupported($clause->[1], $scope, "$context repeat count");
            _clauses([@{$clause}[2 .. $#$clause]], $scope, $actor, "$context repeat body");
        } elsif ($head eq 'switch') {
            _scalar($clause->[1], $scope, "$context switch selector");
            for my $branch (@{$clause}[2 .. $#$clause]) {
                next unless ref($branch) eq 'ARRAY' && @$branch;
                _scalar($branch->[0], $scope, "$context switch branch value")
                    unless defined($branch->[0]) && !ref($branch->[0]) && $branch->[0] eq 'default';
                _clauses([@{$branch}[1 .. $#$branch]], $scope, $actor, "$context switch branch");
            }
        } elsif ($head eq 'drive') {
            my $name = $clause->[1];
            if (defined($name) && !ref($name) && exists(($actor->{drives} || {})->{$name})) {
                _scalar($_, $scope, "$context drive '$name' actual") for @{$clause}[2 .. $#$clause];
            } else {
                my $first = ref($name) eq 'ARRAY' ? 1 : 2;
                _drive_body([@{$clause}[$first .. $#$clause]], $scope, "$context inline drive");
            }
        } elsif ($head eq 'on') {
            _unsupported($clause->[1], $scope, "$context on trigger");
            _clauses([@{$clause}[2 .. $#$clause]], $scope, $actor, "$context on body");
        } elsif ($head eq 'local' || $head eq 'params') {
            # Names/options are declarations, not expression operands. Existing
            # declaration/static-value validation remains authoritative.
            my $first = $head eq 'local' ? 2 : 1;
            for my $option (@{$clause}[$first .. $#$clause]) {
                next unless ref($option) eq 'ARRAY' && @$option >= 2;
                _unsupported($option->[1], $scope, "$context $head value");
            }
        } else {
            # Explicit leaf samples acquire their facts in the sampling slice.
            # No other source context inherits scalar-read permission here.
            _unsupported($clause, $scope, "$context $head clause");
        }
    }
}

sub _drive_body {
    my ($body, $scope, $context) = @_;
    for my $entry (@{$body || []}) {
        next unless ref($entry) eq 'ARRAY' && @$entry >= 2;
        _assignment($entry->[0], $entry->[1], $scope, "$context assignment");
        _unsupported($_, $scope, "$context extra operand") for @{$entry}[2 .. $#$entry];
    }
}

sub _assignment {
    my ($target, $source, $scope, $context) = @_;
    my $to = _reference($target, $scope, 'write', "$context target");
    my $from = _reference($source, $scope, 'read', "$context RHS");
    return 1 if validate_record_port_copy(source => $from, target => $to, context => $context);
    _scalar($source, $scope, "$context RHS");
    return 1;
}

sub _scalar_target {
    my ($token, $scope, $context) = @_;
    my $value = _reference($token, $scope, 'write', $context);
    _require(!_whole_port($value), "$context requires a scalar target; '$token' is a whole record port");
}

sub _scalar {
    my ($expr, $scope, $context) = @_;
    return unless defined $expr;
    if (ref($expr) eq 'ARRAY') {
        return unless @$expr;
        # A state_active argument is a state identity, never a signal operand.
        return if defined($expr->[0]) && !ref($expr->[0]) && $expr->[0] eq 'state_active';
        my $operator = _reference($expr->[0], $scope, 'read', "$context operator");
        _require(!$operator || (!length($operator->{path_text}) && !_aggregate($operator->{type_spec})),
            "$context operator cannot use declared aggregate reference '$expr->[0]'");
        _scalar($_, $scope, $context) for @{$expr}[1 .. $#$expr];
        return;
    }
    return if ref($expr);
    # Preserve existing compact scalar conditions while preventing negation or
    # comparison spelling from hiding a whole record port in a scalar context.
    if ($expr =~ /\A(.+?)(?:==|!=|<=|>=|=|<|>)(.+)\z/) {
        my ($left, $right) = ($1, $2);
        _scalar($_, $scope, $context) for ($left, $right);
        return;
    }
    return _scalar($1, $scope, $context) if $expr =~ /\A!(.+)\z/;
    my $value = _reference($expr, $scope, 'read', $context);
    _require(!_whole_port($value), "$context requires a scalar value; '$expr' is a whole record port");
}

sub _unsupported {
    my ($value, $scope, $context) = @_;
    if (ref($value) eq 'ARRAY') {
        _unsupported($_, $scope, $context) for @$value;
        return;
    }
    return if !defined($value) || ref($value);
    if ($value =~ /\A(.+?)(?:==|!=|<=|>=|=|<|>)(.+)\z/) {
        my ($left, $right) = ($1, $2);
        _unsupported($_, $scope, $context) for ($left, $right);
        return;
    }
    return _unsupported($1, $scope, $context) if $value =~ /\A!(.+)\z/;
    my ($root) = $value =~ /\A([A-Za-z_]\w*)/;
    return unless defined($root) && exists($scope->{roots}{$root}) && _port_root($scope->{roots}{$root});
    _reference($value, $scope, 'read', $context); # validate paths before contextual refusal
    _require(0, "$context does not admit record port reference '$value'");
}

sub _reference {
    my ($token, $scope, $access, $context) = @_;
    return undef unless defined($token) && !ref($token) && $token =~ /\A([A-Za-z_]\w*)(.*)\z/s;
    my ($name, $suffix) = ($1, $2);
    my $roots = $scope->{roots};
    return undef unless exists $roots->{$name};
    # A scalar pin can share an enum/package name. Those namespaces retain
    # their current validator unless a nearest aggregate, or an explicitly
    # shadowed outer aggregate, establishes this as a declaration path.
    return undef if $suffix =~ /\A\./ && $scope->{namespaces}{$name}
        && !_aggregate($roots->{$name}{type_spec}) && !$scope->{aggregate_outers}{$name};
    # Scalar width/output annotations belong to the existing expression owner;
    # they cannot conceal a record port or an aggregate path here.
    return undef if length($suffix) && $suffix !~ /\A[.\[]/
        && !_aggregate($roots->{$name}{type_spec});
    return record_value_reference(scope => $roots, token => $token, access => $access,
        allow_whole => 1, context => $context);
}
sub _context_scope {
    my ($roots, $outer, $actor) = @_;
    my $enums = $actor->{enum_symbols} || {};
    my $constants = $actor->{constant_symbols} || {};
    my %namespaces = map {$_ => 1} (keys %{$enums->{local} || {}},
        keys %{$enums->{packages} || {}}, keys %{$constants->{packages} || {}});
    my %aggregate_outers = map {$_ => 1} grep {_aggregate($outer->{$_}{type_spec})} keys %$outer;
    return {roots => $roots, namespaces => \%namespaces, aggregate_outers => \%aggregate_outers};
}
sub _aggregate {
    my ($spec) = @_;
    return (ref($spec) eq 'HASH' && ($spec->{kind} eq 'record' || $spec->{kind} eq 'list')) ? 1 : 0;
}
sub _port_root {
    my ($root) = @_;
    return (ref($root) eq 'HASH' && ($root->{role} eq 'input' || $root->{role} eq 'output')
        && ref($root->{type_spec}) eq 'HASH' && $root->{type_spec}{kind} eq 'record') ? 1 : 0;
}
sub _whole_port {
    my ($value) = @_;
    return (ref($value) eq 'HASH' && !length($value->{path_text}) && _port_root($value)) ? 1 : 0;
}
sub _require {
    confess "Invalid ISF record context: validation requires a predicate and message\n" unless @_ == 2;
    confess "Invalid ISF record context: $_[1]\n" unless $_[0];
}

1;
