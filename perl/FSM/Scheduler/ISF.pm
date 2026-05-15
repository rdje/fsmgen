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
    my $json = _is_multi_domain_ir($ir)
        ? $self->_emit_multi_domain_schedule_report($actor, $ir)
        : $self->{json_emitter}->emit($ir);

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

sub _emit_multi_domain_schedule_report($self, $actor, $ir) {
    my $partition = $ir->{domain_partition};
    confess "FSM::Scheduler::ISF->report expected a validated multi-domain partition for actor '$actor->{actor_name}'\n"
        unless ref($partition) eq 'HASH' && ref($partition->{domains}) eq 'ARRAY';

    my %domain_report_by_name;
    for my $domain (@{$partition->{domains}}) {
        my $domain_actor = _domain_actor_for_scheduled_artifact($actor, $domain, $partition->{default_domain});
        my $domain_ir = $self->{ir}->build_module($domain_actor);
        $domain_report_by_name{$domain->{name}} = $self->{json_emitter}->report_hash($domain_ir);
    }

    my $report = $self->{json_emitter}->multi_domain_report_hash($ir, \%domain_report_by_name);
    return $self->{json_emitter}->emit_report_hash($report);
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
    $files{"$actor->{actor_name}_top.fsm"} = _emit_multi_domain_top($actor, $partition);

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
    _add_crossing_endpoint_ports($actor, \%domain_actor, $domain_name);
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

sub _add_crossing_endpoint_ports($actor, $domain_actor, $domain_name) {
    for my $crossing (@{$actor->{crossings} || []}) {
        next unless ($crossing->{kind} // '') eq 'event';
        if (($crossing->{from}{domain} // '') eq $domain_name) {
            _ensure_domain_interface_port(
                $domain_actor->{interface},
                $crossing->{from}{signal},
                'output',
                "crossing event '$crossing->{name}' request",
            );
            _ensure_domain_interface_port(
                $domain_actor->{interface},
                $crossing->{ready}{signal},
                'input',
                "crossing event '$crossing->{name}' ready",
            );
        }
        if (($crossing->{to}{domain} // '') eq $domain_name) {
            _ensure_domain_interface_port(
                $domain_actor->{interface},
                $crossing->{to}{signal},
                'input',
                "crossing event '$crossing->{name}' destination pulse",
            );
        }
    }
    return 1;
}

sub _ensure_domain_interface_port($interface, $name, $direction, $context) {
    return 1 unless defined($name) && !ref($name) && length($name);
    for my $existing_direction (qw(inputs outputs)) {
        for my $port (@{$interface->{$existing_direction} || []}) {
            next unless $port->{name} eq $name;
            my $port_direction = $existing_direction eq 'inputs' ? 'input' : 'output';
            confess "FSM::Scheduler::ISF->lower $context endpoint '$name' conflicts with an existing $port_direction port\n"
                unless $port_direction eq $direction;
            confess "FSM::Scheduler::ISF->lower $context endpoint '$name' conflicts with an existing $direction port of different width\n"
                if ($port->{width} // 1) != 1;
            return 1;
        }
    }
    my $bucket = $direction eq 'input' ? 'inputs' : 'outputs';
    push @{$interface->{$bucket}}, {
        name   => $name,
        width  => 1,
        domain => undef,
    };
    return 1;
}

sub _emit_multi_domain_top($actor, $partition) {
    my $top_name = "$actor->{actor_name}_top";
    my @lines;

    push @lines, "(?top:$top_name";
    push @lines, _emit_multi_domain_top_ports($actor, $partition);
    for my $domain (@{$partition->{domains} || []}) {
        push @lines, _emit_domain_instance($domain);
    }
    for my $crossing (@{$actor->{crossings} || []}) {
        next unless ($crossing->{kind} // '') eq 'event';
        push @lines, _emit_crossing_instance($actor, $crossing);
    }
    push @lines, _emit_multi_domain_wiring($actor, $partition);
    push @lines, ')';

    for my $crossing (@{$actor->{crossings} || []}) {
        next unless ($crossing->{kind} // '') eq 'event';
        push @lines, '';
        push @lines, _emit_crossing_rtlif($actor, $crossing, $partition);
    }

    return join("\n", @lines) . "\n";
}

sub _emit_multi_domain_top_ports($actor, $partition) {
    my @tokens;
    my %seen;

    for my $domain (@{$partition->{domains} || []}) {
        _push_top_port_token(\@tokens, \%seen, $domain->{clock}, 'input', 1);
        _push_top_port_token(\@tokens, \%seen, $domain->{reset}{name}, 'input', 1)
            if ref($domain->{reset}) eq 'HASH';
    }
    for my $input (@{$actor->{interface}{inputs} || []}) {
        _push_top_port_token(\@tokens, \%seen, $input->{name}, 'input', $input->{width} // 1);
    }
    for my $output (@{$actor->{interface}{outputs} || []}) {
        _push_top_port_token(\@tokens, \%seen, $output->{name}, 'output', $output->{width} // 1);
    }

    my @lines = ('  (?ports:public_io');
    push @lines, map { "    $_" } @tokens;
    push @lines, '  )';
    return join("\n", @lines);
}

sub _emit_domain_instance($domain) {
    my $module = _scheduled_module_name($domain);
    return "  (?fsmc:$domain->{name} $module)";
}

sub _emit_crossing_instance($actor, $crossing) {
    return "  (?rtl:" . _crossing_instance_name($crossing) . ' ' . _crossing_module_name($actor, $crossing) . ')';
}

sub _emit_multi_domain_wiring($actor, $partition) {
    my @links;
    my %domain_by_name = map { $_->{name} => $_ } @{$partition->{domains} || []};

    for my $input (@{$actor->{interface}{inputs} || []}) {
        my $domain = _entry_domain($input, $partition->{default_domain});
        push @links, _link($input->{name}, "$domain.$input->{name}");
    }
    for my $output (@{$actor->{interface}{outputs} || []}) {
        my $domain = _entry_domain($output, $partition->{default_domain});
        push @links, _link("$domain.$output->{name}", $output->{name});
    }
    for my $crossing (@{$actor->{crossings} || []}) {
        next unless ($crossing->{kind} // '') eq 'event';
        my $source_domain = $domain_by_name{$crossing->{from}{domain}};
        my $dest_domain = $domain_by_name{$crossing->{to}{domain}};
        my $instance = _crossing_instance_name($crossing);
        push @links, _link($source_domain->{clock}, "$instance.source_clk");
        push @links, _link($dest_domain->{clock}, "$instance.dest_clk");
        push @links, _link($source_domain->{reset}{name}, "$instance.source_reset")
            if ref($source_domain->{reset}) eq 'HASH';
        push @links, _link($dest_domain->{reset}{name}, "$instance.dest_reset")
            if ref($dest_domain->{reset}) eq 'HASH';
        push @links, _link("$crossing->{from}{domain}.$crossing->{from}{signal}", "$instance.request");
        push @links, _link("$instance.ready", "$crossing->{from}{domain}.$crossing->{ready}{signal}");
        push @links, _link("$instance.pulse", "$crossing->{to}{domain}.$crossing->{to}{signal}");
    }

    my @lines = ('  (?wiring:domain_wiring');
    push @lines, map { "    $_" } @links;
    push @lines, '  )';
    return join("\n", @lines);
}

sub _emit_crossing_rtlif($actor, $crossing, $partition) {
    my %domain_by_name = map { $_->{name} => $_ } @{$partition->{domains} || []};
    my $source_domain = $domain_by_name{$crossing->{from}{domain}};
    my $dest_domain = $domain_by_name{$crossing->{to}{domain}};

    my @lines;
    push @lines, '(?rtlif:' . _crossing_module_name($actor, $crossing);
    push @lines, '  (params';
    push @lines, '    (FSMGEN_ISF_CDC_EVENT 0d1)';
    push @lines, _emit_crossing_reset_param_lines('SOURCE', $source_domain->{reset});
    push @lines, _emit_crossing_reset_param_lines('DEST', $dest_domain->{reset});
    push @lines, '  )';
    push @lines, '  source_clk:clock';
    push @lines, '  dest_clk:clock';
    push @lines, '  source_reset:reset';
    push @lines, '  dest_reset:reset';
    push @lines, '  request<:data';
    push @lines, '  ready>:data';
    push @lines, '  pulse>:data';
    push @lines, ')';
    return join("\n", @lines);
}

sub _emit_crossing_reset_param_lines($prefix, $reset) {
    my $present = ref($reset) eq 'HASH' ? 1 : 0;
    my $async = $present && (($reset->{kind} // 'sync') eq 'async') ? 1 : 0;
    my $active_high = $present && (($reset->{polarity} // 'active_high') ne 'active_low') ? 1 : 0;

    return (
        "    (${prefix}_RESET_PRESENT " . _bool_param_literal($present) . ")",
        "    (${prefix}_RESET_ASYNC " . _bool_param_literal($async) . ")",
        "    (${prefix}_RESET_ACTIVE_HIGH " . _bool_param_literal($active_high) . ")",
    );
}

sub _bool_param_literal($value) {
    return $value ? '0d1' : '0d0';
}

sub _push_top_port_token($tokens, $seen, $name, $direction, $width) {
    return if !defined($name) || ref($name) || !length($name);
    return if $seen->{$name}++;
    push @$tokens, _format_top_port_token($name, $direction, $width);
}

sub _format_top_port_token($name, $direction, $width) {
    $width = 1 unless defined($width) && $width > 0;
    return $name if $direction eq 'input' && $width == 1;
    return "$name<$width" if $direction eq 'input';
    return "$name>" if $width == 1;
    return "$name>$width";
}

sub _link($from, $to) {
    confess "FSM::Scheduler::ISF->lower generated top wiring has an undefined endpoint\n"
        unless defined($from) && defined($to);
    return "/$from/$to/";
}

sub _scheduled_module_name($domain) {
    my $module = $domain->{scheduled_fsm};
    $module =~ s/\.fsm\z//;
    return $module;
}

sub _crossing_instance_name($crossing) {
    return "$crossing->{name}_cdc";
}

sub _crossing_module_name($actor, $crossing) {
    return "$actor->{actor_name}__cdc_event_$crossing->{name}";
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
