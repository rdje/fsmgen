package FSM::Scheduler::ISF::FormalOperandResolver;

use strict;
use warnings;
use Carp qw(confess);
use FSM::Adapter::FSMGenFull::ExpressionBuilder;
use FSM::Package::AggregatePathSupport;
use FSM::Package::IntegerLiteralSupport;
use FSM::Scheduler::ISF::FormalIdentityPlan;
use FSM::Support::HDLInstanceIdentifierPolicy;

# Detached, role-directed rewriting of normalized ISF expression arrays (not
# Lispish packed operand arrays or formatted prefix text). The caller supplies
# the complete local-name and resolved static-symbol sets for this scope.
# An undefined transaction selects actor scope, as used by rules/named drives.
# This is not expression type checking, binding admission, or production wiring.
sub new {
    my ($class, %args) = @_;
    confess "Formal operand resolver received an unknown option\n"
        if grep {$_ ne 'plan' && $_ ne 'transaction' && $_ ne 'locals' && $_ ne 'static_symbols'} keys %args;
    confess "Formal operand resolver requires an explicit transaction context\n"
        unless exists $args{transaction};
    my $plan = $args{plan};
    confess "Formal operand resolver requires a formal identity plan\n"
        unless ref($plan) eq 'HASH' && ($plan->{model} // '') eq 'isf_formal_identity_plan_v1'
            && ref($plan->{formals}) eq 'HASH';
    if (defined $args{transaction}) {
        confess "Formal operand resolver has unknown transaction context\n"
            unless _identifier($args{transaction})
                && ref($plan->{formals}{$args{transaction}}) eq 'HASH';
    }
    for my $set (qw(locals static_symbols)) {
        confess "Formal operand resolver requires an explicit $set hash\n"
            unless ref($args{$set}) eq 'HASH';
    }
    confess "Formal operand resolver has an invalid local name\n"
        if grep {!_identifier($_)} keys %{$args{locals}};
    confess "Formal operand resolver has an invalid static symbol\n"
        if grep {!/\A[A-Za-z_]\w*(?:(?:\.[A-Za-z_]\w*)|(?:\[\d+(?::\d+)?\]))*\z/}
            keys %{$args{static_symbols}};
    return bless _copy(\%args), $class;
}

sub expression {
    my ($self, $expr, %options) = @_;
    confess "Formal operand expression received an unknown option\n"
        if grep {$_ ne 'property'} keys %options;
    return $self->_scalar($expr) unless ref($expr);
    confess "Formal operand expression requires a non-empty normalized list\n"
        unless ref($expr) eq 'ARRAY' && @$expr && defined($expr->[0]) && !ref($expr->[0]);
    my ($op, @args) = @$expr;
    if ($op eq 'state_active' || $op eq 'at') {
        confess "Formal operand '$op' requires one source identity\n"
            unless @args == 1 && _identifier($args[0]);
        return [$op, $args[0]];
    }
    if ($op eq 'past') {
        confess "Formal operand 'past' requires property context, a reference and optional literal depth\n"
            unless $options{property} && (@args == 1 || @args == 2)
                && (@args == 1 || (defined($args[1]) && !ref($args[1])
                    && $args[1] =~ /\A\d+\z/ && $args[1] > 0));
        return [$op, $self->target($args[0]), @args == 2 ? $args[1] : ()];
    }

    # Consume the carrier's operator policy rather than a second alias table.
    # These methods are pure metadata queries and need no signal manager.
    my $policy = 'FSM::Adapter::FSMGenFull::ExpressionBuilder';
    my $normalized = $policy->normalize_expression_operator($op);
    my $family = $policy->operator_family_for($normalized);
    confess "Formal operand expression has unsupported operator '$op'\n" unless $family;
    my $valid_arity = $family eq 'unary' ? @args == 1
        : $family eq 'binary' ? @args == 2 : @args >= 2;
    confess "Formal operand expression has invalid arity for '$op'\n" unless $valid_arity;
    return [$op, map {$self->expression($_, %options)} @args];
}

# Target positions are signal references, never constants or arbitrary RHS
# expressions. Only formal roots are renamed; member/index/width syntax stays.
sub target {
    my ($self, $token) = @_;
    confess "Formal operand target cannot be a static symbol\n"
        if defined($token) && !ref($token) && exists $self->{static_symbols}{$token};
    return $self->_reference($token);
}

# A binding record retains the source projection separately. Direction chooses
# the caller role; the callee endpoint always resolves against declared ports,
# even when a caller local or static symbol has the same spelling.
sub binding {
    my ($self, $callee, $entry) = @_;
    confess "Formal operand binding requires an input/output entry\n"
        unless ref($entry) eq 'ARRAY' && (@$entry == 3 || @$entry == 4)
            && defined($entry->[0]) && !ref($entry->[0])
            && ($entry->[0] eq 'input' || $entry->[0] eq 'output')
            && _identifier($entry->[1]);
    my ($direction, $formal, $actual, $timing) = @$entry;
    my $endpoint = FSM::Scheduler::ISF::FormalIdentityPlan->lookup($self->{plan}, $callee, $formal);
    confess "Formal operand binding has no $direction formal '$callee.$formal'\n"
        unless $endpoint && $endpoint->{direction} eq $direction;
    if (@$entry == 4) {
        confess "Formal operand binding timing requires an input and snapshot/live\n"
            unless $direction eq 'input' && ref($timing) eq 'ARRAY' && @$timing == 2
                && defined($timing->[0]) && !ref($timing->[0]) && $timing->[0] eq 'timing'
                && defined($timing->[1]) && !ref($timing->[1])
                && ($timing->[1] eq 'snapshot' || $timing->[1] eq 'live');
    }
    confess "Formal operand output binding requires a scalar caller target\n"
        if $direction eq 'output' && !_identifier($actual);
    my $physical_actual = $direction eq 'input' ? $self->expression($actual) : $self->target($actual);
    return {
        source => _copy($entry),
        physical => [$direction, $endpoint->{physical_name}, $physical_actual,
            @$entry == 4 ? _copy($timing) : ()],
        formal => $endpoint,
    };
}

sub _scalar {
    my ($self, $value) = @_;
    confess "Formal operand expression requires a defined scalar\n" unless defined $value;
    return $value if exists $self->{static_symbols}{$value};
    return $value if FSM::Package::IntegerLiteralSupport->literal_parts_from_scalar($value)
        || $value =~ /\A\d+'[0-9a-fA-F_]+\z/
        || $value =~ /\Aconst_\d+b[01xXzZ_]+\z/;
    if ($value =~ /\A(.+?)(==|!=|<=|>=|=|<|>)(.+)\z/) {
        my ($left, $op, $right) = ($1, $2, $3);
        s/^\s+|\s+$//g for $left, $right;
        return $self->_scalar($left) . $op . $self->_scalar($right);
    }
    if ($value =~ /\A!([A-Za-z_]\w*(?:\[\d+(?::\d+)?\])?)\z/) {
        return '!' . $self->target($1);
    }
    return $self->_reference($value);
}

sub _reference {
    my ($self, $token) = @_;
    confess "Formal operand has unsupported signal reference\n"
        unless defined($token) && !ref($token)
            && $token =~ /\A([A-Za-z_]\w*)((?:(?:\.[A-Za-z_]\w*)|(?:\[\d+(?::\d+)?\]))*)('\d+)?(>)?\z/;
    my ($root, $path, $width, $output) = ($1, $2, $3 // '', $4 // '');
    return $token if !defined($self->{transaction}) || exists $self->{locals}{$root};
    my $formal = FSM::Scheduler::ISF::FormalIdentityPlan->lookup($self->{plan}, $self->{transaction}, $root);
    return $token unless $formal;
    if (length $path) {
        my $declaration = $formal->{declaration};
        my $type = $declaration->{type_spec};
        if (ref($type) eq 'HASH' && ($type->{kind} // '') =~ /\A(?:record|list)\z/) {
            my $resolved = FSM::Package::AggregatePathSupport->resolve(root_type_spec => $type, path_text => $path);
            confess "Formal operand '$token' has invalid aggregate path: $resolved->{code}\n" unless $resolved->{ok};
        } else {
            confess "Formal operand '$token' requires a declared aggregate member path or scalar bit/slice\n"
                unless $path =~ /\A\[(\d+)(?::(\d+))?\]\z/;
            my ($a, $b) = ($1, $2 // $1);
            my $bits = $declaration->{width};
            confess "Formal operand '$token' has unresolved or out-of-range scalar access\n"
                unless defined($bits) && !ref($bits) && $bits =~ /\A\d+\z/ && $a < $bits && $b < $bits;
        }
    }
    return $formal->{physical_name} . $path . $width . $output;
}

sub _identifier {
    return FSM::Support::HDLInstanceIdentifierPolicy->is_simple_identifier($_[0]);
}

sub _copy {
    my ($value) = @_;
    return {map {$_ => _copy($value->{$_})} keys %$value} if ref($value) eq 'HASH';
    return [map {_copy($_)} @$value] if ref($value) eq 'ARRAY';
    confess "Formal operand context contains an unsupported reference\n" if ref($value);
    return $value;
}

1;
