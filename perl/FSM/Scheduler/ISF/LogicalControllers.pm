package FSM::Scheduler::ISF::LogicalControllers;

use strict;
use warnings;
use Carp qw(confess);

# Private shadow data only. Neither emitter consumes this model. Identity is a
# tuple, not a generated HDL spelling; no selector allocation happens here.
sub inventory {
    my ($class, $ir, $actor) = @_;
    my %transactions = map { $_->{name} => $_ } @{$actor->{transactions} || []};
    my $domains = $actor->{clock_domains} || {};
    my %domains = map { $_->{name} => $_ } @{$domains->{domains} || []};
    my $default_domain = $actor->{_scheduled_domain_name} // $domains->{default};
    my (@controllers, %by_owner, %state_owner, @references, @issues);
    for my $state (@{$ir->{states} || []}) {
        my $name = $state->{name};
        my $owner = $state->{transaction};
        if (!_name($name)) {
            push @issues, 'state has no scalar identity';
            next;
        }
        if (!_name($owner) || !exists $transactions{$owner}) {
            push @issues, "state '$name' has no declared transaction owner";
            next;
        }
        if (exists $state_owner{$name}) {
            push @issues, "state '$name' has duplicate membership";
            next;
        }
        my $controller = $by_owner{$owner};
        if (!$controller) {
            my $domain = $transactions{$owner}{domain} // $default_domain;
            my $timing = defined($domain) && exists($domains{$domain})
                ? $domains{$domain} : $actor;
            $controller = {
                identity => [$ir->{actor_name}, $domain, $owner],
                transaction => $owner, domain => $domain,
                clock => $timing->{clock}, reset => _copy($timing->{reset}),
                initial_state => $name, states => [], entries => [],
            };
            $by_owner{$owner} = $controller;
            push @controllers, $controller;
        }
        $state_owner{$name} = $owner;
        push @{$controller->{states}}, {name => $name, kind => $state->{kind}};
        push @{$controller->{entries}}, $name if ($state->{kind} // '') eq 'entry';

        # Typed references, including metadata still used by linking/reporting.
        # Inactive branch metadata is retained as metadata, not executable edges.
        for my $i (0 .. $#{$state->{transitions} || []}) {
            _reference(\@references, $name, "transitions[$i].target",
                $state->{transitions}[$i]{target}, 'transition');
        }
        for my $field (qw(true_target loop_body_start dynamic_wait_loop_state dynamic_wait_loop_for)) {
            _reference(\@references, $name, $field, $state->{$field}, 'metadata')
                if defined $state->{$field};
        }
        for my $field (qw(branch_state_names branch_end_names loop_body_state_names
                          loop_decision_state_names wait_state_names repeat_state_names)) {
            for my $i (0 .. $#{$state->{$field} || []}) {
                _reference(\@references, $name, "$field\[$i\]", $state->{$field}[$i], 'metadata');
            }
        }
        for my $i (0 .. $#{$state->{branches} || []}) {
            _reference(\@references, $name, "branches[$i].body_start",
                $state->{branches}[$i]{body_start}, 'metadata');
        }
    }
    for my $ref (@references) {
        my ($from, $to) = @{$ref}{qw(state target)};
        if (!_name($to) || !exists $state_owner{$to}) {
            push @issues, "state '$from' $ref->{field} has no owned target";
        } elsif ($state_owner{$from} ne $state_owner{$to}) {
            push @issues, "state '$from' $ref->{field} crosses transaction ownership to '$to'";
        }
    }
    return {
        model => 'isf_logical_controllers_shadow_v1',
        module => $ir->{actor_name}, controllers => \@controllers,
        state_owner => \%state_owner, references => \@references, issues => \@issues,
    };
}

# Explicit qualification gate. Attaching the shadow never changes source
# admission; executable promotion must call this gate and resolve every issue.
sub assert_valid {
    my ($class, $ir, $actor) = @_;
    my $model = $class->inventory($ir, $actor);
    confess "Logical controller ownership: " . join('; ', @{$model->{issues}}) . "\n"
        if @{$model->{issues}};
    return $model;
}

sub _reference {
    my ($refs, $state, $field, $target, $role) = @_;
    push @$refs, {state => $state, field => $field, target => $target, role => $role};
}

sub _name { defined($_[0]) && !ref($_[0]) && length($_[0]) }
sub _copy {
    my ($value) = @_;
    return {map {$_ => _copy($value->{$_})} keys %$value} if ref($value) eq 'HASH';
    return [map {_copy($_)} @$value] if ref($value) eq 'ARRAY';
    return $value;
}

1;
