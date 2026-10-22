package FSM::Support::ISFReductions;

use strict;
use warnings;
use Carp qw(confess);
use Exporter 'import';
use Scalar::Util qw(refaddr);
use Storable qw(dclone);
use FSM::Package::ExpressionOperatorSupport qw(is_reduction_operator);
use FSM::Support::ISFRecordPortValues qw(record_value_scope record_value_reference);
use FSM::Support::ISFRecordPortScopes qw(record_actor_scope record_transaction_scope record_drive_scope);
use FSM::Support::ISFRecordPortSamples qw(record_transaction_samples);

our @EXPORT_OK = qw(capture_actor_reductions capture_expression_reductions snapshot_reductions reduction_metadata_contract);

# Source selectors operate on parsed, macro-expanded clauses. Only expression
# positions are visited; an assignment target named "xor" is not an operator.
sub capture_actor_reductions {
    my %args = @_;
    _keys(\%args, ['actor'], 'actor capture');
    my $actor = $args{actor};
    _require(ref($actor) eq 'HASH', 'actor capture requires a parsed actor');
    my (@records, %used_drives);
    for my $tx (@{$actor->{transactions} || []}) {
        my $scope;
        my $emit = sub {
            my ($expression, $context) = @_;
            return unless _has_reduction($expression, {});
            unless ($scope) {
                $scope = _without_static_values($actor,
                    _timing_scope($actor, record_transaction_scope(actor => $actor, transaction => $tx)), $tx);
                my $samples = record_transaction_samples(actor => $actor, transaction => $tx, port_only => 1);
                for my $sample (@{$samples->{samples}}) {
                    # An unresolved/delegated sample masks the alias, but the
                    # record-port consumer must not reinterpret its source.
                    my $value = $sample->{reference} && record_value_reference(scope => $scope, token => $sample->{source},
                        access => 'read', allow_whole => 1, context => "transaction '$tx->{name}' sample '$sample->{source}'");
                    $scope = record_value_scope(outer => $scope, local => {
                        $sample->{alias} => {role => 'local', type_spec => $value && $value->{type_spec}{kind} =~ /\A(?:bit|bits)\z/ ? $value->{type_spec} : undef}});
                }
                $scope = _without_static_values($actor, $scope, $tx);
            }
            push @records, @{capture_expression_reductions(expression => $expression, scope => $scope,
                owner_kind => 'transaction', owner => $tx->{name}, context => $context)};
        };
        _clauses($tx->{clauses}, $actor, $emit, \%used_drives, "transaction '$tx->{name}'");
    }
    my $actor_scope;
    for my $rule (@{$actor->{rules} || []}) {
        my $emit = sub {
            my ($expression, $context) = @_;
            return unless _has_reduction($expression, {});
            $actor_scope ||= _without_static_values($actor, _timing_scope($actor, record_actor_scope(actor => $actor)));
            push @records, @{capture_expression_reductions(expression => $expression, scope => $actor_scope,
                owner_kind => 'rule', owner => $rule->{name}, context => $context)};
        };
        $emit->($rule->{when}[1], "rule '$rule->{name}' guard") if ref($rule->{when}) eq 'ARRAY';
        for my $i (0 .. $#{$rule->{actions} || []}) {
            my $action = $rule->{actions}[$i];
            my $head = $action->[0];
            my $context = "rule '$rule->{name}' action[$i]";
            next if $head eq 'priority' || $head eq 'pulse';
            if ($head eq 'trigger') { _bindings($action, $emit, $context); }
            elsif ($head eq 'store') { $emit->($action->[2], "$context index"); $emit->($action->[3], "$context value"); }
            elsif ($head eq 'load') { $emit->($action->[2], "$context index"); }
            else { $emit->($action->[$head eq 'set' ? 2 : 1], "$context RHS"); }
        }
    }
    # Unused definitions do not have instantiated formal widths and are not
    # scheduled expressions. Preserve that existing source boundary.
    for my $name (sort keys %used_drives) {
        my $drive = $actor->{drives}{$name};
        my $scope;
        for my $i (0 .. $#{$drive->{body} || []}) {
            my $expression = $drive->{body}[$i][1];
            next unless _has_reduction($expression, {});
            $scope ||= _without_static_values($actor, _timing_scope($actor, record_drive_scope(actor => $actor, drive => $drive)));
            push @records, @{capture_expression_reductions(expression => $expression, scope => $scope,
                owner_kind => 'drive', owner => $name, context => "drive '$name' assignment[$i] RHS")};
        }
    }
    return snapshot_reductions(\@records);
}

sub _without_static_values {
    my ($actor, $scope, $transaction) = @_;
    my %values = map {$_->{name} => {role => 'local', type_spec => undef}}
        (@{$actor->{params} || []}, @{$actor->{constants} || []});
    for my $clause (@{($transaction || {})->{clauses} || []}) {
        next unless ref($clause) eq 'ARRAY' && ($clause->[0] // '') eq 'params';
        for my $parameter (@{$clause}[1 .. $#$clause]) {
            $values{$parameter->[0]} = {role => 'local', type_spec => undef};
        }
    }
    return record_value_scope(outer => $scope, local => \%values);
}

sub _timing_scope {
    my ($actor, $scope) = @_;
    my %timing;
    for my $entry ($actor, @{($actor->{clock_domains} || {})->{domains} || []}) {
        for my $name ($entry->{clock}, ($entry->{reset} || {})->{name}) {
            next unless _text($name);
            $timing{$name} = {role => 'input', type_spec => {kind => 'bits', width => 1, signed => 0}};
        }
    }
    return record_value_scope(outer => \%timing, local => $scope);
}

sub _clauses {
    my ($clauses, $actor, $emit, $used, $prefix) = @_;
    for my $i (0 .. $#{$clauses || []}) {
        my $clause = $clauses->[$i];
        next unless ref($clause) eq 'ARRAY' && @$clause;
        my $head = $clause->[0];
        next unless _text($head);
        my $context = "$prefix clause[$i] $head";
        if ($head eq 'set' || $head eq 'update') { $emit->($clause->[2], "$context RHS"); }
        elsif ($head eq 'wait' || $head eq 'await' || $head eq 'assert' || $head eq 'cover' || $head eq 'assume') {
            $emit->($clause->[1], "$context expression");
        } elsif ($head eq 'when' || $head eq 'while' || $head eq 'until' || $head eq 'on' || $head eq 'repeat') {
            $emit->($clause->[1], "$context condition");
            _clauses([@{$clause}[2 .. $#$clause]], $actor, $emit, $used, $context);
        } elsif ($head eq 'switch') {
            $emit->($clause->[1], "$context selector");
            for my $j (2 .. $#$clause) {
                my $branch = $clause->[$j];
                next unless ref($branch) eq 'ARRAY';
                $emit->($branch->[0], "$context branch[$j] value");
                _clauses([@{$branch}[1 .. $#$branch]], $actor, $emit, $used, "$context branch[$j]");
            }
        } elsif ($head eq 'drive') {
            my $name = $clause->[1];
            if (_text($name) && exists(($actor->{drives} || {})->{$name})) {
                $used->{$name} = 1;
                $emit->($_, "$context actual") for @{$clause}[2 .. $#$clause];
            } else {
                my $first = ref($name) eq 'ARRAY' ? 1 : 2;
                for my $pair (@{$clause}[$first .. $#$clause]) {
                    $emit->($pair->[1], "$context RHS") if ref($pair) eq 'ARRAY';
                }
            }
        } elsif ($head eq 'do' || $head eq 'spawn') { _bindings($clause, $emit, $context); }
        elsif ($head eq 'store') { $emit->($clause->[2], "$context index"); $emit->($clause->[3], "$context value"); }
        elsif ($head eq 'load') { $emit->($clause->[2], "$context index"); }
        elsif ($head eq 'assemble') {
            for my $part (@{$clause}[1 .. $#$clause]) {
                last if !ref($part) && defined($part) && $part eq 'as';
                $emit->($part, "$context part");
            }
        }
    }
}
sub _bindings {
    my ($clause, $emit, $context) = @_;
    for my $option (@{$clause}[2 .. $#$clause]) {
        next unless ref($option) eq 'ARRAY' && ($option->[0] // '') eq 'bind';
        for my $binding (@{$option}[1 .. $#$option]) {
            $emit->($binding->[2], "$context input '$binding->[1]'")
                if ref($binding) eq 'ARRAY' && ($binding->[0] // '') eq 'input';
        }
    }
}
sub _has_reduction {
    my ($expression, $active) = @_;
    return 0 unless ref($expression) eq 'ARRAY' && @$expression;
    my $address = refaddr($expression);
    _require(!$active->{$address}, 'source expression is cyclic');
    local $active->{$address} = 1;
    my $head = $expression->[0];
    return 1 if @$expression == 2 && _text($head) && ($head =~ /\A(?:[&|^]|and|or|xor)\z/);
    for my $operand (@{$expression}[1 .. $#$expression]) { return 1 if _has_reduction($operand, $active); }
    return 0;
}

sub reduction_metadata_contract {
    return {
        source_forms => ['(^ X)', '(& X)', '(| X)'],
        operand_contract => 'declared positive-width packed scalar signal, scalar field, static slice or bit selection; static values and untyped formals refused',
        result_contract => 'unsigned one-bit result; existing multi-operand and logical negation semantics unchanged',
        qualification => 'source and report contract; feature runtime qualification is separately owned',
        shape => 'array',
        presence => 'nonempty successful directly parsed ISF source or scheduled expressions',
        entry_keys => [qw(owner_kind owner context kind operator operand operand_width result_width)],
        owner_kind_values => [qw(transaction rule drive)],
        kind_values => ['unary'],
        operator_values => ['^', '&', '|'],
        ordering => 'transactions, rules, used named drives; authored clause/expression order within each owner; drive names lexical',
        provenance => 'derived from selected expressions and declared scope; snapshots validate structure only',
    };
}

# The caller selects an expression payload, not a source
# clause or assignment pair; their heads may also be legal signal names.
# Scope roots use the existing detached declaration/path contract.
sub capture_expression_reductions {
    my %args = @_;
    _keys(\%args, [qw(expression scope owner_kind owner context)], 'capture');
    my $identity = _identity(\%args);
    my $scope = record_value_scope(outer => $args{scope}, local => {});
    my @records;
    my $expression = ref($args{expression}) ? dclone($args{expression}) : $args{expression};
    _expression($expression, $scope, $identity, \@records, {});
    return snapshot_reductions(\@records);
}

sub _expression {
    my ($expression, $scope, $identity, $records, $active) = @_;
    return unless ref($expression);
    _require(ref($expression) eq 'ARRAY', "$identity->{context} expression must be scalar or a list");
    my $address = refaddr($expression);
    _require(!$active->{$address}, "$identity->{context} expression is cyclic");
    local $active->{$address} = 1;
    _require(@$expression && _text($expression->[0]), "$identity->{context} expression requires a scalar operator");
    my $head = $expression->[0];
    my %aliases = (xor => '^', and => '&', or => '|');
    my $operator = $aliases{$head} // $head;
    if (@$expression == 2 && is_reduction_operator($operator)) {
        my $operand = $expression->[1];
        _require(_text($operand), "$identity->{context} reduction '$head' operand must be a declared packed scalar signal, slice or bit selection");
        my $value = record_value_reference(scope => $scope, token => $operand,
            access => 'read', context => "$identity->{context} reduction '$head' operand '$operand'");
        _require(defined($value), "$identity->{context} reduction '$head' operand '$operand' is not a declared packed scalar signal");
        push @$records, {%$identity, kind => 'unary', operator => $operator,
            operand => $operand, operand_width => 0 + $value->{width}, result_width => 1};
        return;
    }
    _expression($_, $scope, $identity, $records, $active) for @{$expression}[1 .. $#$expression];
}

# A detached structural snapshot is not an attestation of source ownership.
# Only the source-context caller can bind the supplied owner/scope to an actor.
sub snapshot_reductions {
    my ($records) = @_;
    return undef unless defined $records;
    _require(ref($records) eq 'ARRAY', 'inventory must be a list');
    my @copy;
    for my $input (@$records) {
        _require(ref($input) eq 'HASH', 'inventory entries must be maps');
        my $record = dclone($input); # Numeric checks must not change caller JSON kinds.
        _keys($record, [qw(owner_kind owner context kind operator operand operand_width result_width)], 'entry');
        my $identity = _identity($record);
        _require(_text($record->{kind}) && $record->{kind} eq 'unary', 'entry kind must be unary');
        _require(is_reduction_operator($record->{operator}), 'entry requires a canonical reduction operator');
        _require(_text($record->{operand}), 'entry requires an authored operand');
        _require(_positive($record->{operand_width}), 'entry operand width must be positive');
        _require(_positive($record->{result_width}) && $record->{result_width} == 1,
            'unary result width must be one');
        push @copy, {%$identity, kind => 'unary', operator => $record->{operator},
            operand => $record->{operand}, operand_width => 0 + $record->{operand_width}, result_width => 1};
    }
    return \@copy;
}

sub _identity {
    my ($args) = @_;
    my $kind = $args->{owner_kind};
    _require(_text($kind) && scalar($kind =~ /\A(?:transaction|rule|drive)\z/), 'invalid source owner kind');
    _require(_text($args->{owner}) && scalar($args->{owner} =~ /\A[A-Za-z_]\w*\z/), 'invalid source owner');
    _require(_text($args->{context}), 'missing source context');
    return {map {$_ => $args->{$_}} qw(owner_kind owner context)};
}
sub _positive { defined($_[0]) && !ref($_[0]) && $_[0] =~ /\A[1-9][0-9]*\z/ ? 1 : 0 }
sub _text { defined($_[0]) && !ref($_[0]) && length($_[0]) ? 1 : 0 }
sub _keys {
    my ($value, $keys, $context) = @_;
    my %allowed = map {$_ => 1} @$keys;
    _require(!grep(!exists($value->{$_}), @$keys), "$context has missing fields");
    _require(!grep(!$allowed{$_}, keys %$value), "$context has unknown fields");
}
sub _require {
    confess "Invalid ISF reductions: validation requires a predicate and message\n" unless @_ == 2;
    confess "Invalid ISF reductions: $_[1]\n" unless $_[0];
}

1;
