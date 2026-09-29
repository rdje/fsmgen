package FSM::Scheduler::ISF::WriterResourceActivation;

use strict;
use warnings;
use Carp qw(confess);
use JSON::PP;
use Storable qw(dclone);
use FSM::Scheduler::ISF::SourceWriterOwners;
use FSM::Scheduler::ISF::WriterResourceGrants;

# Private validation of the actual rule-header grant transformations. This
# does not prove exclusion of arbitrary assignments or independent controllers.
sub collect {
    my ($class, $ir, $actor) = @_;
    my $grants = FSM::Scheduler::ISF::WriterResourceGrants->collect($ir, $actor);
    my $evidence = $ir->{resource_activation};
    _keys($evidence, [qw(requests steps)], 'activation evidence');
    _require(ref($evidence->{steps}) eq 'ARRAY', 'requires ordered activation steps');
    my (%rules, %dt, %owners, %current);
    _require(ref($actor->{rules}) eq 'ARRAY', 'requires authored rule records');
    for my $rule (@{$actor->{rules}}) {
        _require(ref($rule) eq 'HASH' && _text($rule->{name}) && !exists($rules{$rule->{name}}),
            'has invalid or duplicate authored rules');
        $rules{$rule->{name}} = $rule;
    }
    for my $container (@{$ir->{dt_blocks}}) {
        next unless ($container->{kind} // '') eq 'rule';
        my $owner = FSM::Scheduler::ISF::SourceWriterOwners->resolve($ir, $actor, 'dt', $container);
        my $user = $owner->{source_name};
        _require(!exists($dt{$user}), 'has duplicate rule containers');
        $dt{$user} = $container;
        $owners{$user} = $owner;
    }
    _same([sort keys %dt], [sort keys %rules], 'has incomplete authored-rule/DT coverage');
    _keys($evidence->{requests}, [keys %rules], 'original requests');
    for my $user (sort keys %rules) {
        my $request = $evidence->{requests}{$user};
        _keys($request, [qw(container_name source_owner guard condition)], 'original request');
        my $guard = _request_guard($rules{$user});
        _same($request, {container_name => $dt{$user}{name}, source_owner => {kind => 'rule', name => $user},
            guard => $guard, condition => _condition($guard)}, 'has inconsistent original request');
        $current{$user} = $guard;
    }

    my $dominates = _priority_relation(\%rules, $actor->{priorities} // []);
    my (@expected, %resources);
    for my $resource (@{$actor->{resources} || []}) {
        $resources{$resource->{name}} = $resource;
        push @expected, map {[$resource->{name}, $_]} @{$resource->{users} || []};
    }
    _same([map {[$_->{resource}, $_->{user}]} @$grants], \@expected, 'has inconsistent grant order');
    _require(@{$evidence->{steps}} == @expected, 'has missing or extra activation steps');
    my (@records, %pointer_resources, %resource_pointers, %round_robin_users);
    for my $index (0 .. $#expected) {
        my ($name, $user) = @{$expected[$index]};
        my $resource = $resources{$name};
        my $grant = $grants->[$index];
        my $step = $evidence->{steps}[$index];
        my $rr = $resource->{arbiter} eq 'round_robin';
        _keys($step, [qw(resource user container_name arbiter before_guard after_guard),
            $rr ? 'round_robin' : 'suppressors'], 'activation step');
        _same([@{$step}{qw(resource user container_name arbiter)}],
            [$name, $user, $dt{$user}{name}, $resource->{arbiter}], 'has inconsistent step identity');
        _same($step->{before_guard}, $current{$user}, 'has a broken activation chain');
        my $after;
        if ($rr) {
            _require(!$round_robin_users{$user}++, 'binds one user to multiple round-robin resources');
            $after = _round_robin_guard($ir, $dt{$user}, $resource, $user, $step->{round_robin},
                $evidence->{requests}, \%pointer_resources, \%resource_pointers, $current{$user});
        } else {
            my @users = @{$resource->{users}};
            for my $peer (@users) {
                next if $peer eq $user;
                _require(!!$dominates->{$user}{$peer} != !!$dominates->{$peer}{$user},
                    'requires an acyclic complete resource priority order');
            }
            my @higher = sort grep {$_ ne $user && $dominates->{$_}{$user}} @users;
            _same($grant->{higher}, \@higher, 'has incomplete priority suppressors');
            my @conditions = map {$evidence->{requests}{$_}{condition}} @higher;
            _same($step->{suppressors}, [map {{user => $higher[$_], condition => $conditions[$_]}} 0 .. $#higher],
                'has inconsistent priority request inputs');
            $after = $current{$user};
            if (@higher) {
                my $blocked = @conditions == 1 ? $conditions[0] : '(| ' . join(' ', @conditions) . ')';
                my @terms = _condition($after) eq '1' ? () : (_condition($after));
                push @terms, "(! $blocked)";
                $after = {expr => @terms == 1 ? $terms[0] : '(& ' . join(' ', @terms) . ')'};
            }
        }
        _same($step->{after_guard}, $after, 'has an incorrect resource transformation');
        $current{$user} = $after;
        push @records, {%$grant, activation => $step};
    }
    for my $user (sort keys %rules) {
        _same($dt{$user}{dte_guard}, $current{$user}, 'has an inconsistent final rule header');
    }
    return dclone({requests => $evidence->{requests}, grants => \@records,
        final_guards => \%current, source_owners => \%owners});
}

sub _round_robin_guard {
    my ($ir, $dt, $resource, $user, $rr, $requests, $pointer_resources, $resource_pointers, $before) = @_;
    _keys($rr, [qw(permission pointer_declaration user_index next_pointer assignment_index)], 'round-robin inputs');
    my $declaration = $rr->{pointer_declaration};
    _keys($declaration, [qw(name width storage_role)], 'pointer declaration');
    my $pointer = $declaration->{name};
    my $name = $resource->{name};
    my @users = @{$resource->{users}};
    my ($winner) = grep {$users[$_] eq $user} 0 .. $#users;
    my $width = 1;
    ++$width while 2 ** $width < @users;
    _require(_text($pointer) && $pointer =~ /\A[A-Za-z_][A-Za-z0-9_]*\z/, 'has an invalid pointer identity');
    _same($declaration, {name => $pointer, width => $width, storage_role => 'resource_round_robin_pointer'},
        'has an invalid pointer declaration');
    _require(ref($ir->{counters}) eq 'HASH' && ref($ir->{storage_roles}) eq 'HASH', 'requires actual pointer storage');
    _same([$ir->{counters}{$pointer}, $ir->{storage_roles}{$pointer}],
        [$width, 'resource_round_robin_pointer'], 'has no matching executable pointer storage');
    _require(!exists($pointer_resources->{$pointer}) || $pointer_resources->{$pointer} eq $name,
        'shares a pointer between resources');
    _require(!exists($resource_pointers->{$name}) || $resource_pointers->{$name} eq $pointer,
        'changes pointer within one resource');
    $pointer_resources->{$pointer} = $name;
    $resource_pointers->{$name} = $pointer;
    my $next = ($winner + 1) % @users;
    _same([$rr->{user_index}, $rr->{next_pointer}], [$winner, $next], 'has an incorrect pointer transition');
    _require(_uint($rr->{assignment_index}) && ref($dt->{assignments}) eq 'ARRAY'
        && $rr->{assignment_index} < @{$dt->{assignments}}, 'has an invalid pointer update index');
    my $update = $dt->{assignments}[$rr->{assignment_index}];
    _require(ref($update) eq 'HASH', 'requires a pointer update record');
    _same([@{$update}{qw(lhs rhs op source_kind)}], [$pointer, $next, '<-', 'resource_round_robin_pointer'],
        'has an inconsistent executable pointer update');

    # Derive each allowed pointer position from the declared circular user order.
    # A position admits this user only when every earlier request is false.
    my @positions;
    for my $start (0 .. $#users) {
        my @terms = ("(== $pointer $start)");
        for (my $i = $start; $i != $winner; $i = ($i + 1) % @users) {
            my $request = $requests->{$users[$i]}{condition};
            push @terms, $request eq '1' ? '0' : $request eq '0' ? '1' : "(! $request)";
        }
        push @positions, _boolean('&', @terms);
    }
    my $permission = _boolean('|', @positions);
    _same($rr->{permission}, $permission, 'has an incorrect round-robin permission');
    my @terms = grep {$_ ne '1'} (_condition($before), $permission);
    return {port => '1'} unless @terms;
    return {expr => @terms == 1 ? $terms[0] : _boolean('&', @terms)};
}

sub _priority_relation {
    my ($rules, $priorities) = @_;
    _require(ref($priorities) eq 'ARRAY', 'requires authored priorities');
    my @edges = @$priorities;
    for my $user (sort keys %$rules) {
        _require(ref($rules->{$user}{actions}) eq 'ARRAY', 'requires authored rule actions');
        push @edges, map {[$user, $_->[1], $_->[2]]}
            grep {ref($_) eq 'ARRAY' && ($_->[0] // '') eq 'priority'} @{$rules->{$user}{actions}};
    }
    my (%next, %reachable);
    for my $edge (@edges) {
        _require(ref($edge) eq 'ARRAY' && @$edge == 3 && _text($edge->[0])
            && _text($edge->[2]) && ($edge->[1] // '') eq 'over', 'has malformed authored priority');
        next unless exists($rules->{$edge->[0]}) && exists($rules->{$edge->[2]});
        $next{$edge->[0]}{$edge->[2]} = 1;
    }
    for my $user (keys %$rules) {
        my @queue = keys %{$next{$user} || {}};
        while (@queue) {
            my $next = shift @queue;
            next if $reachable{$user}{$next}++;
            push @queue, keys %{$next{$next} || {}};
        }
    }
    return \%reachable;
}

sub _request_guard {
    my ($rule) = @_;
    return {port => '1'} unless defined $rule->{when};
    my $when = $rule->{when};
    _require(ref($when) eq 'ARRAY' && @$when == 2 && ($when->[0] // '') eq 'when',
        'has malformed authored request');
    return ref($when->[1]) ? {expr => _expression($when->[1])} : {port => _expression($when->[1])};
}

sub _expression {
    my ($value) = @_;
    return "$value" if _text($value);
    _require(ref($value) eq 'ARRAY' && @$value, 'has malformed request expression');
    return '(' . join(' ', map {_expression($_)} @$value) . ')';
}

sub _condition { exists($_[0]{port}) ? $_[0]{port} : $_[0]{expr} }
sub _boolean {
    my ($op, @terms) = @_;
    my ($absorbing, $identity) = $op eq '&' ? ('0', '1') : ('1', '0');
    return $absorbing if grep {$_ eq $absorbing} @terms;
    @terms = grep {$_ ne $identity} @terms;
    return $identity unless @terms;
    return $terms[0] if @terms == 1;
    return "($op " . join(' ', @terms) . ')';
}
sub _keys {
    my ($record, $keys, $label) = @_;
    _require(ref($record) eq 'HASH', "requires structured $label");
    _same([sort keys %$record], [sort @$keys], "has malformed $label fields");
}
sub _same {
    my ($actual, $expected, $message) = @_;
    my $equal = eval {JSON::PP->new->canonical->encode($actual) eq JSON::PP->new->canonical->encode($expected)};
    _require(!$@ && $equal, $message);
}
sub _uint { defined($_[0]) && !ref($_[0]) && $_[0] =~ /\A(?:0|[1-9][0-9]*)\z/ }
sub _text { defined($_[0]) && !ref($_[0]) && length($_[0]) }
sub _require { confess "Writer resource activation $_[1]\n" unless $_[0] }

1;
