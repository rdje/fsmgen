package FSM::Scheduler::ISF::WriterActivation;

use strict;
use warnings;
use Carp qw(confess);

# Detached evidence for explicit assignments only. This does not establish
# ownership, arbitration or exclusion between independently active controllers.
sub resolve {
    my ($class, $kind, $container, $index) = @_;
    confess "Writer activation requires a state or DT assignment\n"
        unless defined($kind) && ($kind eq 'state' || $kind eq 'dt')
            && ref($container) eq 'HASH' && _text($container->{name})
            && _text($container->{kind}) && ref($container->{assignments}) eq 'ARRAY'
            && defined($index) && !ref($index) && $index =~ /\A(?:0|[1-9][0-9]*)\z/
            && $index < @{$container->{assignments}};
    my $assignment = $container->{assignments}[$index];
    confess "Writer activation requires a supported explicit assignment\n"
        unless ref($assignment) eq 'HASH' && _text($assignment->{lhs})
            && _text($assignment->{op})
            && $assignment->{op} =~ /\A(?:=|<-|<=|<[0-9]+|--)\z/;
    my $enable = _guard($assignment->{guard});
    if ($assignment->{op} eq '--') {
        confess "Writer activation does not qualify DT decrement emission\n" unless $kind eq 'state';
        # The actual state emitter does not append a guard to (-- counter).
        # No admitted guarded-decrement producer has been qualified.
        confess "Writer activation does not qualify a guarded state decrement\n"
            unless $enable->{predicate}{kind} eq 'always';
    }
    my $record = {
        container_kind => $kind, container_name => $container->{name},
        assignment_index => 0 + $index, target => $assignment->{lhs},
        operator => $assignment->{op}, assignment_enable => $enable,
    };
    if ($kind eq 'state') {
        confess "Writer activation requires explicit state transitions\n"
            unless ref($container->{transitions}) eq 'ARRAY';
        $record->{container_enable} = {kind => 'state_active', state => $container->{name}};
        $record->{state_transition_context} = {
            state_kind => $container->{kind}, guard => _guard($container->{guard}),
            transitions => _clone($container->{transitions}),
        };
        $record->{assignment_guard_placement} = $assignment->{op} eq '--' ? 'none' : 'suffix';
    } else {
        $record->{container_enable} = {kind => 'dt_header', guard => _guard($container->{dte_guard})};
        my $raw = $assignment->{guard};
        my $grouped = $container->{kind} eq 'rule' && ref($raw) eq 'HASH'
            && _text($raw->{port}) && $raw->{port} ne '1';
        $record->{assignment_guard_placement} = $grouped ? 'rule_group' : 'suffix';
    }
    return $record;
}

sub _guard {
    my ($guard) = @_;
    return {raw => undef, predicate => {kind => 'always'}} unless defined $guard;
    confess "Writer activation requires a guard record\n" unless ref($guard) eq 'HASH';
    return {raw => {}, predicate => {kind => 'always'}} unless keys %$guard;
    my %allowed = map {$_ => 1} qw(port expr expr_ast signal op value);
    confess "Writer activation has an unknown guard field\n" if grep {!$allowed{$_}} keys %$guard;
    my @forms = grep {exists $guard->{$_}} qw(port expr signal);
    confess "Writer activation requires one unambiguous guard form\n" unless @forms == 1;
    my $form = $forms[0];
    my $predicate;
    if ($form eq 'signal') {
        confess "Writer activation requires a complete comparison guard\n"
            unless keys(%$guard) == 3 && _text($guard->{signal}) && _text($guard->{op})
                && $guard->{op} =~ /\A(?:=|==|!=|<|<=|>|>=)\z/ && _text($guard->{value});
        $predicate = {kind => 'comparison', signal => $guard->{signal},
            operator => $guard->{op}, value => $guard->{value}};
    } else {
        confess "Writer activation requires a scalar predicate\n"
            unless _text($guard->{$form}) && !exists($guard->{op}) && !exists($guard->{value})
                && ($form eq 'expr' || !exists($guard->{expr_ast}));
        if (exists $guard->{expr_ast}) {
            confess "Writer activation has inconsistent expression text and AST\n"
                unless ref($guard->{expr_ast}) eq 'ARRAY'
                    && _expression_text($guard->{expr_ast}) eq $guard->{expr};
        }
        $predicate = $form eq 'port' && $guard->{port} eq '1'
            ? {kind => 'always'}
            : {kind => 'truthy', source_field => $form, expression => $guard->{$form}};
    }
    return {raw => _clone($guard), predicate => $predicate};
}

sub _expression_text {
    my ($node) = @_;
    return "$node" if _text($node);
    confess "Writer activation requires a structured expression AST\n"
        unless ref($node) eq 'ARRAY' && @$node && _text($node->[0]);
    return '(' . join(' ', map {_expression_text($_)} @$node) . ')';
}

sub _clone {
    my ($value) = @_;
    return $value unless ref $value;
    return [map {_clone($_)} @$value] if ref($value) eq 'ARRAY';
    return {map {$_ => _clone($value->{$_})} keys %$value} if ref($value) eq 'HASH';
    confess "Writer activation requires plain structured evidence\n";
}

sub _text {defined($_[0]) && !ref($_[0]) && length($_[0])}

1;
