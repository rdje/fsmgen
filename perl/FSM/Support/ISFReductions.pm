package FSM::Support::ISFReductions;

use strict;
use warnings;
use Carp qw(confess);
use Exporter 'import';
use Scalar::Util qw(refaddr);
use Storable qw(dclone);
use FSM::Package::ExpressionOperatorSupport qw(is_reduction_operator);
use FSM::Support::ISFRecordPortValues qw(record_value_scope record_value_reference);

our @EXPORT_OK = qw(capture_expression_reductions snapshot_reductions reduction_metadata_contract);

sub reduction_metadata_contract {
    return {
        entry_keys => [qw(owner_kind owner context kind operator operand operand_width result_width)],
        owner_kind_values => [qw(transaction rule drive)],
        kind_values => ['unary'],
        operator_values => ['^', '&', '|'],
        ordering => 'expression preorder within the selected source context',
        provenance => 'derived from selected expressions and declared scope; snapshots validate structure only',
    };
}

# Preparation only. The caller selects an expression payload, not a source
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
