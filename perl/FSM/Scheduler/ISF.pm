package FSM::Scheduler::ISF;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use Scalar::Util qw(blessed);
use feature qw(signatures postderef);
no warnings 'experimental::signatures';

use FSM::Debug;
use FSM::Scheduler::ISF::LoweringIR;
use FSM::Scheduler::ISF::Emitter::FSM;
use FSM::Scheduler::ISF::Emitter::CompositionTop;
use FSM::Scheduler::ISF::Emitter::JSON;

sub new($class, @constructor_args) {
    _validate_constructor_receiver($class);
    my %args = _validate_constructor_args($class, @constructor_args);
    my $debug = $args{debug} // 0;
    fsm_trace_enter('Initialize ISF scheduler', 2);

    my $self = bless {
        debug       => $debug,
        ir          => FSM::Scheduler::ISF::LoweringIR->new(debug => $debug),
        fsm_emitter => FSM::Scheduler::ISF::Emitter::FSM->new,
        top_emitter => FSM::Scheduler::ISF::Emitter::CompositionTop->new,
        json_emitter=> FSM::Scheduler::ISF::Emitter::JSON->new,
    }, $class;

    fsm_trace_exit('ISF scheduler initialized', 2);
    return $self;
}

sub _validate_constructor_receiver($class) {
    confess "FSM::Scheduler::ISF->new must be called with the FSM::Scheduler::ISF class invocant\n"
        unless defined($class) && !ref($class) && $class eq 'FSM::Scheduler::ISF';
}

sub _validate_constructor_args($class, @args) {
    confess "$class->new expects an even-length option/value list\n"
        if @args % 2;

    my %options = @args;
    my %allowed = map { $_ => 1 } qw(debug);
    for my $name (sort keys %options) {
        confess "$class->new unsupported option '$name'; supported option: debug\n"
            unless $allowed{$name};
    }

    return %options;
}

sub lower($self, @args) {
    _validate_object_receiver($self, 'lower');
    my ($actor) = _validate_actor_arg('lower', @args);
    fsm_trace_enter("Scheduler lower: $actor->{actor_name}", 2);

    my $ir     = $self->{ir}->build_module($actor);
    if (_is_multi_domain_ir($ir)) {
        my $files = $self->_emit_multi_domain_scheduled_artifacts($actor, $ir);
        fsm_trace_exit("Scheduler lower completed", 2);
        return { files => $files };
    }
    my %files;

    # Emit parent
    $files{"$ir->{actor_name}.fsm"} = $self->{fsm_emitter}->emit($ir);

    # Emit children
    my $children = $ir->{children} || {};
    for my $cname (sort keys %$children) {
        my $cir = $children->{$cname};
        $files{"$cname.fsm"} = $self->{fsm_emitter}->emit($cir);
    }

    my $top = $self->{top_emitter}->emit($ir, \%files);
    $files{"$ir->{actor_name}_top.fsm"} = $top if defined $top;

    fsm_trace_exit("Scheduler lower completed", 2);
    return { files => \%files };
}

sub report($self, @args) {
    _validate_object_receiver($self, 'report');
    my ($actor) = _validate_actor_arg('report', @args);
    fsm_trace_enter("Scheduler report: $actor->{actor_name}", 2);

    my $ir   = $self->{ir}->build_module($actor);
    _confess_unprojected_multi_domain_report($ir);
    my $json = $self->{json_emitter}->emit($ir);

    fsm_trace_exit("Scheduler report completed", 2);
    return $json;
}

sub _validate_object_receiver($self, $method) {
    confess "FSM::Scheduler::ISF->$method must be called on an FSM::Scheduler::ISF object\n"
        unless blessed($self) && $self->isa('FSM::Scheduler::ISF');
}

sub _validate_actor_arg($method, @args) {
    confess "FSM::Scheduler::ISF->$method expects exactly one scheduler-consumable actor hash reference\n"
        unless @args == 1;

    my $actor = $args[0];
    confess "FSM::Scheduler::ISF->$method argument 1 must be a scheduler-consumable actor hash reference\n"
        unless ref($actor) eq 'HASH';
    confess "FSM::Scheduler::ISF->$method actor must include scalar actor_name\n"
        unless defined($actor->{actor_name}) && !ref($actor->{actor_name});
    confess "FSM::Scheduler::ISF->$method actor must include transactions array\n"
        unless ref($actor->{transactions}) eq 'ARRAY';
    confess "FSM::Scheduler::ISF->$method actor must include interface hash\n"
        unless ref($actor->{interface}) eq 'HASH';

    return ($actor);
}

sub _is_multi_domain_ir($ir) {
    my $partition = $ir->{domain_partition};
    return ref($partition) eq 'HASH' && ($partition->{kind} // '') eq 'multi_domain';
}

sub _confess_unprojected_multi_domain_report($ir) {
    return 1 unless _is_multi_domain_ir($ir);

    confess "FSM::Scheduler::ISF->report validated the multi-domain partition for actor '$ir->{actor_name}', but multi-domain schedule-report projection is not implemented yet\n";
}

sub _emit_multi_domain_scheduled_artifacts($self, $actor, $ir) {
    my $partition = $ir->{domain_partition};
    confess "FSM::Scheduler::ISF->lower expected a validated multi-domain partition for actor '$actor->{actor_name}'\n"
        unless ref($partition) eq 'HASH' && ref($partition->{domains}) eq 'ARRAY';

    my %files;
    for my $domain (@{$partition->{domains}}) {
        my $file_name = $domain->{scheduled_fsm};
        confess "FSM::Scheduler::ISF->lower domain '$domain->{name}' is missing its scheduled .fsm artifact name\n"
            unless defined($file_name) && !ref($file_name) && length($file_name);
        confess "FSM::Scheduler::ISF->lower duplicate scheduled .fsm artifact '$file_name'\n"
            if exists $files{$file_name};

        my $domain_actor = _domain_actor_for_scheduled_artifact($actor, $domain, $partition->{default_domain});
        my $domain_ir = $self->{ir}->build_module($domain_actor);
        $files{$file_name} = $self->{fsm_emitter}->emit($domain_ir);
    }

    return \%files;
}

sub _domain_actor_for_scheduled_artifact($actor, $domain, $default_domain) {
    my $domain_name = $domain->{name};
    confess "FSM::Scheduler::ISF->lower domain metadata is missing a scalar domain name\n"
        unless defined($domain_name) && !ref($domain_name) && length($domain_name);

    my $module_name = $domain->{scheduled_fsm};
    $module_name =~ s/\.fsm\z//;

    my %transaction_names = map {
        $_->{name} => 1
    } grep {
        _entry_domain($_, $default_domain) eq $domain_name
    } @{$actor->{transactions} || []};
    my %rule_names = map {
        $_->{name} => 1
    } grep {
        _entry_domain($_, $default_domain) eq $domain_name
    } @{$actor->{rules} || []};
    my %owner_names = (%transaction_names, %rule_names);

    my %domain_actor = %{_clone_isf_value($actor)};
    $domain_actor{actor_name} = $module_name;
    $domain_actor{clock} = $domain->{clock};
    $domain_actor{reset} = _clone_isf_value($domain->{reset});
    $domain_actor{clock_domains} = undef;
    $domain_actor{interface} = {
        inputs => [
            map { _clone_isf_value($_) }
            grep { _entry_domain($_, $default_domain) eq $domain_name }
            @{$actor->{interface}{inputs} || []}
        ],
        outputs => [
            map { _clone_isf_value($_) }
            grep { _entry_domain($_, $default_domain) eq $domain_name }
            @{$actor->{interface}{outputs} || []}
        ],
    };
    $domain_actor{storage} = [
        map { _clone_isf_value($_) }
        grep { _entry_domain($_, $default_domain) eq $domain_name }
        @{$actor->{storage} || []}
    ];
    $domain_actor{transactions} = [
        map { _clone_isf_value($_) }
        grep { _entry_domain($_, $default_domain) eq $domain_name }
        @{$actor->{transactions} || []}
    ];
    $domain_actor{rules} = [
        map { _clone_isf_value($_) }
        grep { _entry_domain($_, $default_domain) eq $domain_name }
        @{$actor->{rules} || []}
    ];
    $domain_actor{library_uses} = [
        map { _clone_isf_value($_) }
        grep { _entry_domain($_, $default_domain) eq $domain_name }
        @{$actor->{library_uses} || []}
    ];
    $domain_actor{resources} = _domain_resources($actor, \%rule_names);
    $domain_actor{priorities} = _domain_priorities($actor, \%owner_names);

    return \%domain_actor;
}

sub _entry_domain($entry, $default_domain) {
    return ref($entry) eq 'HASH' && defined($entry->{domain})
        ? $entry->{domain}
        : $default_domain;
}

sub _domain_resources($actor, $rule_names) {
    my @resources;
    for my $resource (@{$actor->{resources} || []}) {
        my $copy = _clone_isf_value($resource);
        if (ref($copy->{users}) eq 'ARRAY') {
            $copy->{users} = [ grep { $rule_names->{$_} } @{$copy->{users}} ];
            next unless @{$copy->{users}};
        }
        push @resources, $copy;
    }
    return \@resources;
}

sub _domain_priorities($actor, $owner_names) {
    my @priorities;
    for my $priority (@{$actor->{priorities} || []}) {
        next unless ref($priority) eq 'ARRAY' && @$priority >= 3;
        next unless $owner_names->{$priority->[0]} && $owner_names->{$priority->[2]};
        push @priorities, _clone_isf_value($priority);
    }
    return \@priorities;
}

sub _clone_isf_value($value) {
    return $value unless ref($value);
    return [ map { _clone_isf_value($_) } @$value ] if ref($value) eq 'ARRAY';
    return { map { $_ => _clone_isf_value($value->{$_}) } keys %$value } if ref($value) eq 'HASH';
    confess "FSM::Scheduler::ISF cannot clone unsupported reference value\n";
}

1;
