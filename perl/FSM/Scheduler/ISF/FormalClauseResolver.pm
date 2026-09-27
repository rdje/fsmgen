package FSM::Scheduler::ISF::FormalClauseResolver;

use strict;
use warnings;
use Carp qw(confess);
use FSM::Scheduler::ISF::FormalIdentityPlan;
use FSM::Scheduler::ISF::FormalOperandResolver;
use FSM::Support::HDLInstanceIdentifierPolicy;

# Detached transforms of normalized, source-validated ISF records. The caller
# still owns source admission, pruning, generated placement and complete scope
# contexts. No actor definition or source report is changed in place.
sub transaction {
    my ($class, $tx, %context) = @_;
    confess "Formal clause resolver requires a named transaction with clauses\n"
        unless ref($tx) eq 'HASH' && _identifier($tx->{name}) && ref($tx->{clauses}) eq 'ARRAY';
    my $self = $class->_context($tx->{name}, %context);
    my $copy = _copy($tx);
    for my $direction (qw(input output)) {
        for my $port (@{($copy->{ports} || {})->{"${direction}s"} || []}) {
            my $formal = FSM::Scheduler::ISF::FormalIdentityPlan->lookup($context{plan}, $tx->{name}, $port->{name});
            confess "Formal clause declaration does not match the identity plan\n"
                unless $formal && $formal->{direction} eq $direction;
            confess "Formal clause local '$port->{name}' duplicates a transaction formal\n"
                if exists $context{locals}{$port->{name}};
            $port->{name} = $formal->{physical_name};
        }
    }
    $copy->{clauses} = $self->_sequence($tx->{clauses}, ['clauses']);
    return {transaction => $copy, bindings => $self->{bindings}};
}

sub rule {
    my ($class, $rule, %context) = @_;
    confess "Formal clause resolver requires a named rule with actions\n"
        unless ref($rule) eq 'HASH' && _identifier($rule->{name}) && ref($rule->{actions}) eq 'ARRAY';
    my $self = $class->_context(undef, %context);
    confess "Formal clause rule scope cannot contain transaction locals\n" if keys %{$context{locals}};
    my $copy = _copy($rule);
    if (defined $rule->{when}) {
        _head($rule->{when});
        _require($rule->{when}[0] eq 'when' && @{$rule->{when}} == 2, 'rule guard');
        $copy->{when} = ['when', $self->{operands}->expression($rule->{when}[1])];
    }
    my @actions;
    for my $i (0 .. $#{$rule->{actions}}) {
        my $cl = $rule->{actions}[$i];
        my $op = _head($cl);
        my $path = ['actions', $i];
        if ($op eq 'trigger') {
            push @actions, $self->_activation($cl, $path);
        } elsif ($op eq 'priority') {
            _require(@$cl == 3 && _scalar($cl->[1]) && $cl->[1] eq 'over' && _identifier($cl->[2]), 'rule priority');
            push @actions, _copy($cl);
        } elsif ($op =~ /\A(?:pulse|set|store|load|atl_trigger|atl_trigger_batch)\z/) {
            push @actions, $self->_clause($cl, $path);
        } else {
            # The parser's rule shorthand is (target expression), not an opcode.
            _require(@$cl == 2 && _identifier($op), 'rule assignment');
            push @actions, [$self->{operands}->target($op), $self->{operands}->expression($cl->[1])];
        }
    }
    $copy->{actions} = \@actions;
    return {rule => $copy, bindings => $self->{bindings}};
}

sub _context {
    my ($class, $owner, %context) = @_;
    confess "Formal clause owner is selected by the source record\n" if exists $context{transaction};
    my $drives = delete $context{named_drives};
    confess "Formal clause resolver requires an explicit named_drives hash\n"
        unless ref($drives) eq 'HASH' && !grep {!_identifier($_)} keys %$drives;
    my $operands = FSM::Scheduler::ISF::FormalOperandResolver->new(%context, transaction => $owner);
    return bless {operands => $operands, named_drives => _copy($drives),
        locals => _copy($context{locals}), bindings => []}, $class;
}

sub _sequence {
    my ($self, $clauses, $path) = @_;
    _require(ref($clauses) eq 'ARRAY', 'clause sequence');
    return [map {$self->_clause($clauses->[$_], [@$path, $_])} 0 .. $#$clauses];
}

sub _clause {
    my ($self, $cl, $path) = @_;
    return [] if ref($cl) eq 'ARRAY' && !@$cl; # admitted empty no-op
    my $op = _head($cl);
    my $r = $self->{operands};
    if ($op eq 'set' || $op eq 'update') {
        _require(@$cl == 3, $op);
        return [$op, $r->target($cl->[1]), $r->expression($cl->[2])];
    }
    if ($op eq 'sample') {
        _require(@$cl == 4 && _scalar($cl->[2]) && $cl->[2] eq 'as', $op);
        return [$op, $r->expression($cl->[1]), 'as', $r->target($cl->[3])];
    }
    if ($op =~ /\A(?:complete|pulse|wait|exit-when|continue-when)\z/) {
        _require(@$cl == 2, $op);
        return [$op, $op eq 'complete' || $op eq 'pulse'
            ? $r->target($cl->[1]) : $r->expression($cl->[1])];
    }
    if ($op eq 'on') {
        _require(@$cl >= 2, $op);
        my @out = ($op, $r->expression($cl->[1]));
        my $label_seen;
        for (my $i = 2; $i < @$cl; $i++) {
            if (_scalar($cl->[$i]) && $cl->[$i] eq 'as') {
                _require(!$label_seen++ && _identifier($cl->[$i+1]), 'on label');
                push @out, 'as', $cl->[++$i];
            } else {
                _require(_head($cl->[$i]) eq 'sample', 'on sample');
                push @out, $self->_clause($cl->[$i], [@$path, $i]);
            }
        }
        return \@out;
    }
    if ($op eq 'await') {
        _require(@$cl == 2 || @$cl == 3, $op);
        return [$op, $r->expression($cl->[1]), @$cl == 3 ? _static_option($cl->[2], 'watchdog', 2) : ()];
    }
    if ($op =~ /\A(?:when|while|until|repeat)\z/) {
        _require(@$cl >= 3, $op);
        return [$op, $r->expression($cl->[1]), map {$self->_clause($cl->[$_], [@$path, $_])} 2 .. $#$cl];
    }
    if ($op eq 'switch') {
        _require(@$cl >= 3, $op);
        my @branches;
        for my $i (2 .. $#$cl) {
            my $branch = $cl->[$i];
            _require(ref($branch) eq 'ARRAY' && @$branch >= 2 && _scalar($branch->[0]), 'switch branch');
            push @branches, [$branch->[0], map {$self->_clause($branch->[$_], [@$path, $i, $_])} 1 .. $#$branch];
        }
        return [$op, $r->expression($cl->[1]), @branches];
    }
    if ($op eq 'drive') {
        _require(@$cl >= 2, $op);
        if (_scalar($cl->[1]) && exists $self->{named_drives}{$cl->[1]}) {
            return [$op, $cl->[1], map {$r->expression($_)} @$cl[2 .. $#$cl]];
        }
        my $start = ref($cl->[1]) eq 'ARRAY' ? 1 : 2;
        _require($start < @$cl && ($start == 1 || _identifier($cl->[1])), 'inline drive');
        my @out = @$cl[0 .. $start-1];
        for my $i ($start .. $#$cl) {
            my $pair = $cl->[$i];
            _require(ref($pair) eq 'ARRAY' && @$pair == 2, 'inline drive pair');
            push @out, [$r->target($pair->[0]), $r->expression($pair->[1])];
        }
        return \@out;
    }
    if ($op eq 'shift_left' || $op eq 'shift_right') {
        _require(@$cl == 3 || @$cl == 4, $op);
        return [$op, $r->target($cl->[1]), $r->expression($cl->[2]),
            @$cl == 4 ? _static_option($cl->[3], 'width', 2) : ()];
    }
    if ($op eq 'assemble' || $op eq 'extract') {
        return $self->_packing($cl);
    }
    if ($op eq 'store' || $op eq 'load') {
        _require(_identifier($cl->[1]) && ($op eq 'store' ? @$cl == 4
            : @$cl == 5 && _scalar($cl->[3]) && $cl->[3] eq 'as'), $op);
        # Bank identity is explicitly actor-owned, even under a formal shadow.
        return $op eq 'store'
            ? [$op, $cl->[1], $r->expression($cl->[2]), $r->expression($cl->[3])]
            : [$op, $cl->[1], $r->expression($cl->[2]), 'as', $r->target($cl->[4])];
    }
    if ($op eq 'do' || $op eq 'spawn') { return $self->_activation($cl, $path); }
    if ($op eq 'await_all' || $op eq 'await_any') {
        _require(@$cl == 1 || @$cl == 2, $op);
        return [$op, @$cl == 2 ? $r->target($cl->[1]) : ()];
    }
    if ($op eq 'assert' || $op eq 'cover' || $op eq 'assume') {
        _require((@$cl == 2 || @$cl == 3) && (@$cl == 2 || _scalar($cl->[2])), $op);
        return [$op, $self->_property($cl->[1]), @$cl == 3 ? $cl->[2] : ()];
    }
    if ($op eq 'point') {
        _require(@$cl == 2 && _identifier($cl->[1]), $op);
        return _copy($cl);
    }
    if ($op eq 'stage') {
        _require(@$cl == 4 && _scalar($cl->[1]), $op);
        my %seen;
        for my $option (@$cl[2 .. $#$cl]) {
            my $head = _head($option);
            _require($head =~ /\A(?:ready|valid|input|output)\z/ && @$option == 2 && _identifier($option->[1]), 'stage endpoint');
            my $role = $head eq 'ready' || $head eq 'input' ? 'input' : 'output';
            _require(!$seen{$role}++, 'duplicate stage endpoint');
        }
        return _copy($cl); # Lowering explicitly requires actor interface ports.
    }
    if ($op eq 'atl_trigger' || $op eq 'atl_trigger_batch') {
        _require(@$cl >= 2 && ($op ne 'atl_trigger' || @$cl == 2)
            && !(grep {!_identifier($_)} @$cl[1 .. $#$cl]), $op);
        return _copy($cl); # Parser-generated actor wiring, not lexical formals.
    }
    if ($op eq 'local') {
        _require(@$cl >= 3 && _identifier($cl->[1]) && exists $self->{locals}{$cl->[1]}, 'local context');
        for my $option (@$cl[2 .. $#$cl]) {
            my $head = _head($option);
            _require(scalar($head =~ /\A(?:width|default|init|reset)\z/), 'local option');
            _static_option($option, $head, 2);
        }
        return _copy($cl);
    }
    if ($op eq 'latency') {
        _require(@$cl >= 2, $op);
        for my $option (@$cl[1 .. $#$cl]) {
            my $head = _head($option);
            _require($head eq 'min' || $head eq 'max', 'latency option');
            _static_option($option, $head, 2);
        }
        return _copy($cl);
    }
    if ($op eq 'params' || $op eq 'phase') {
        # Params hold static structured values; phase bodies are opaque source
        # annotations, ignored by executable lowering. Neither is runtime code.
        _require(@$cl >= 2, $op);
        _require(_scalar($cl->[1]), 'phase name') if $op eq 'phase';
        my $start = $op eq 'phase' ? 2 : 1;
        for my $entry (@$cl[$start .. $#$cl]) {
            _head($entry);
        }
        return _copy($cl);
    }
    confess "Formal clause resolver has unsupported transaction clause '$op'\n";
}

sub _activation {
    my ($self, $cl, $path) = @_;
    my $op = $cl->[0];
    my $start = $op eq 'spawn' ? 4 : 2;
    _require(@$cl >= $start && _identifier($cl->[1]), $op);
    _require(_scalar($cl->[2]) && $cl->[2] eq 'as' && _identifier($cl->[3]), 'spawn instance') if $op eq 'spawn';
    my @out = @$cl[0 .. $start-1];
    my %seen;
    for my $i ($start .. $#$cl) {
        my $option = $cl->[$i];
        my $head = _head($option);
        _require(!$seen{$head}++, 'duplicate activation option');
        if ($head eq 'bind') {
            _require(@$option >= 2, 'empty binding');
            my @entries;
            my %ports;
            for my $j (1 .. $#$option) {
                my $record = $self->{operands}->binding($cl->[1], $option->[$j]);
                _require(!$ports{$record->{formal}{source_name}}++, 'duplicate binding');
                push @entries, $record->{physical};
                push @{$self->{bindings}}, {%$record, site_kind => $op, callee => $cl->[1], path => [@$path, $i, $j]};
            }
            push @out, ['bind', @entries];
        } elsif ($head eq 'params') {
            _require(@$option >= 2, 'activation parameters');
            for my $pair (@$option[1 .. $#$option]) {
                _require(ref($pair) eq 'ARRAY' && @$pair == 2 && _identifier($pair->[0]) && defined($pair->[1]), 'activation parameter');
            }
            push @out, _copy($option);
        } elsif ($head eq 'domain' && $op ne 'trigger') {
            push @out, _static_option($option, 'domain', 2);
        } else { confess "Formal clause resolver has unsupported $op option '$head'\n"; }
    }
    return \@out;
}

sub _packing {
    my ($self, $cl) = @_;
    my $op = $cl->[0];
    my $r = $self->{operands};
    my @items = @$cl;
    my $widths = ref($items[-1]) eq 'ARRAY' ? pop @items : undef;
    _static_option($widths, 'widths') if defined $widths;
    my @out;
    if ($op eq 'assemble') {
        _require(@items >= 4 && _scalar($items[-2]) && $items[-2] eq 'as', $op);
        @out = ($op, (map {$r->expression($_)} @items[1 .. $#items-2]), 'as', $r->target($items[-1]));
    } else {
        _require(@items >= 4 && _scalar($items[2]) && $items[2] eq 'as', $op);
        @out = ($op, $r->expression($items[1]), 'as', map {$r->target($_)} @items[3 .. $#items]);
    }
    push @out, _copy($widths) if defined $widths;
    return \@out;
}

sub _property {
    my ($self, $expr) = @_;
    return $self->{operands}->expression($expr, property => 1) unless ref($expr) eq 'ARRAY';
    my $head = _head($expr);
    if ($head eq 'monitor') {
        _require(@$expr == 2 && _head($expr->[1]) eq 'within' && @{$expr->[1]} == 3
            && _identifier($expr->[1][1]) && _scalar($expr->[1][2]), 'monitor property');
        return _copy($expr); # actor interface signal and static window
    }
    if ($head eq '=>' || $head eq 'after') {
        _require(@$expr == 3, 'binary property');
        return [$head, map {$self->_property($_)} @$expr[1, 2]];
    }
    if ($head =~ /\A(?:next|stable|changed|rose|fell)\z/) {
        _require(@$expr == 2, 'unary property');
        return [$head, $self->_property($expr->[1])];
    }
    if ($head eq 'within') {
        _require((@$expr == 3 || @$expr == 4) && !(grep {!_scalar($_)} @$expr[2 .. $#$expr]), 'property window');
        return [$head, $self->_property($expr->[1]), @$expr[2 .. $#$expr]];
    }
    return $self->{operands}->expression($expr, property => 1);
}

sub _static_option {
    my ($option, $head, $size) = @_;
    _require(_head($option) eq $head && (defined($size) ? @$option == $size : @$option >= 2)
        && !(grep {!_scalar($_)} @$option[1 .. $#$option]), "$head option");
    return _copy($option);
}

sub _head {
    my ($cl) = @_;
    _require(ref($cl) eq 'ARRAY' && @$cl && _scalar($cl->[0]), 'normalized clause head');
    return $cl->[0];
}
sub _scalar { return defined($_[0]) && !ref($_[0]); }
sub _identifier { return FSM::Support::HDLInstanceIdentifierPolicy->is_simple_identifier($_[0]); }
sub _require { confess "Formal clause resolver has malformed $_[1]\n" unless $_[0]; }
sub _copy {
    my ($value) = @_;
    return {map {$_ => _copy($value->{$_})} keys %$value} if ref($value) eq 'HASH';
    return [map {_copy($_)} @$value] if ref($value) eq 'ARRAY';
    confess "Formal clause resolver cannot copy an unsupported reference\n" if ref($value);
    return $value;
}

1;
