package FSM::Scheduler::ISF;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use Scalar::Util qw(blessed);
use feature qw(signatures postderef);
no warnings 'experimental::signatures';

use FSM::Debug;
use FSM::Support::HDLInstanceIdentifierPolicy;
use FSM::Scheduler::ISF::LoweringIR;
use FSM::Scheduler::ISF::FormalLowering;
use FSM::Scheduler::ISF::RecordOutputWriters;
use FSM::Scheduler::ISF::DomainSource qw(_domain_actor_for_scheduled_artifact _entry_domain);
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

    my $formal = FSM::Scheduler::ISF::FormalLowering->prepare($self->{ir}, $actor);
    $actor = $formal->{actor} if $formal;
    my $ir     = $self->{ir}->build_module($actor);
    if (_is_multi_domain_ir($ir)) {
        my $files = $self->_emit_multi_domain_scheduled_artifacts($actor, $ir, $formal);
        fsm_trace_exit("Scheduler lower completed", 2);
        return { files => $files };
    }
    FSM::Scheduler::ISF::FormalLowering->verify($formal, {$ir->{actor_name} => $ir});
    _assert_record_output_writers($actor, $ir);
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

    my $formal = FSM::Scheduler::ISF::FormalLowering->prepare($self->{ir}, $actor);
    $actor = $formal->{actor} if $formal;
    my $ir   = $self->{ir}->build_module($actor);
    FSM::Scheduler::ISF::FormalLowering->verify($formal, {$ir->{actor_name} => $ir})
        unless _is_multi_domain_ir($ir);
    _assert_record_output_writers($actor, $ir) unless _is_multi_domain_ir($ir);
    my $json = _is_multi_domain_ir($ir)
        ? $self->_emit_multi_domain_schedule_report($actor, $ir, $formal)
        : $self->{json_emitter}->emit(FSM::Scheduler::ISF::FormalLowering->report_ir($formal, $ir));

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

# Public scheduling and emission consume actual bound modules. The private IR
# builder remains available to inventory/refusal probes; a mixed-domain view
# must be replaced by each matching domain source before physical admission.
sub _assert_record_output_writers($actor, $ir) {
    return unless grep {
        ref($_->{type_spec}) eq 'HASH' && ($_->{type_spec}{kind} // '') eq 'record'
    } @{$actor->{interface}{outputs} || []};
    FSM::Scheduler::ISF::RecordOutputWriters->assert_admitted(actor => $actor, ir => $ir);
    return;
}

sub _emit_multi_domain_schedule_report($self, $actor, $ir, $formal = undef) {
    my $partition = $ir->{domain_partition};
    confess "FSM::Scheduler::ISF->report expected a validated multi-domain partition for actor '$actor->{actor_name}'\n"
        unless ref($partition) eq 'HASH' && ref($partition->{domains}) eq 'ARRAY';

    my %domain_report_by_name;
    my $realizations = $self->_multi_domain_realizations($actor, $partition);
    FSM::Scheduler::ISF::FormalLowering->verify($formal,
        {map {$_->{ir}{actor_name} => $_->{ir}} @$realizations});
    for my $realization (@$realizations) {
        $domain_report_by_name{$realization->{domain}{name}} =
            $self->{json_emitter}->report_hash(FSM::Scheduler::ISF::FormalLowering->report_ir(
                $formal, $realization->{ir}, $realization->{domain}{name}));
    }

    my $report = $self->{json_emitter}->multi_domain_report_hash($ir, \%domain_report_by_name);
    if ($formal) {
        my $reductions = FSM::Scheduler::ISF::FormalLowering->source_reductions($formal);
        if (@$reductions) { $report->{reductions} = $reductions; }
        else { delete $report->{reductions}; }
    }
    return $self->{json_emitter}->emit_report_hash($report);
}

sub _emit_multi_domain_scheduled_artifacts($self, $actor, $ir, $formal = undef) {
    my $partition = $ir->{domain_partition};
    confess "FSM::Scheduler::ISF->lower expected a validated multi-domain partition for actor '$actor->{actor_name}'\n"
        unless ref($partition) eq 'HASH' && ref($partition->{domains}) eq 'ARRAY';

    my %files;
    my $realizations = $self->_multi_domain_realizations($actor, $partition);
    FSM::Scheduler::ISF::FormalLowering->verify($formal,
        {map {$_->{ir}{actor_name} => $_->{ir}} @$realizations});
    for my $realization (@$realizations) {
        my $domain = $realization->{domain};
        my $domain_ir = $realization->{ir};
        $files{$domain->{scheduled_fsm}} = $self->{fsm_emitter}->emit($domain_ir);
        for my $child (sort keys %{$domain_ir->{children} || {}}) {
            my $module = $realization->{names}{modules}{$child};
            my $child_ir = { %{$domain_ir->{children}{$child}}, actor_name => $module };
            $files{"$module.fsm"} = $self->{fsm_emitter}->emit($child_ir);
        }
    }
    $files{"$actor->{actor_name}_top.fsm"} = $self->_emit_multi_domain_top($actor, $partition, $realizations);
    return \%files;
}

# Allocate against every existing outer identity before adding domain children.
# Reporting and emission use the same deterministic plan; authored transaction,
# domain and local handoff names remain unchanged in the domain IR.
sub _multi_domain_realizations($self, $actor, $partition) {
    my %instances = map { $_->{name} => 1 }
        @{$actor->{interface}{inputs} || []}, @{$actor->{interface}{outputs} || []};
    my %modules = ("$actor->{actor_name}_top" => 1);
    for my $domain (@{$partition->{domains}}) {
        my $file = $domain->{scheduled_fsm};
        confess "FSM::Scheduler::ISF domain '$domain->{name}' is missing its scheduled .fsm artifact name\n"
            unless defined($file) && !ref($file) && length($file);
        my $module = _scheduled_module_name($domain);
        confess "FSM::Scheduler::ISF duplicate scheduled .fsm artifact '$file'\n"
            if grep { lc($_) eq lc($module) } keys %modules;
        $modules{$module} = 1;
        $instances{$domain->{instance}} = $instances{$domain->{clock}} = 1;
        $instances{$domain->{reset}{name}} = 1 if ref($domain->{reset}) eq 'HASH';
    }
    for my $crossing (@{$partition->{crossings} || []}) {
        for my $prefix ($crossing->{kind} eq 'event' ? ('') : ('start_', 'done_')) {
            $instances{$crossing->{"${prefix}instance"}} = 1;
            $modules{$crossing->{"${prefix}module"}} = 1;
        }
    }
    my $allocate = sub ($desired, $reserved) {
        return FSM::Support::HDLInstanceIdentifierPolicy->allocate_generated_instance_identifier(
            desired => $desired, role => 'child', reserved => $reserved);
    };
    my @realizations;
    for my $domain (@{$partition->{domains}}) {
        my $domain_actor = _domain_actor_for_scheduled_artifact($actor, $domain, $partition->{default_domain});
        my $domain_ir = $self->{ir}->build_module($domain_actor);
        _assert_record_output_writers($domain_actor, $domain_ir);
        my $names = { instances => { $domain_ir->{actor_name} => $domain->{instance} }, modules => {},
            wiring_name => "$domain->{instance}_child_wiring" };
        for my $child (sort keys %{$domain_ir->{children} || {}}) {
            $names->{modules}{$child} = $allocate->("$domain_ir->{actor_name}__child_$child", \%modules);
        }
        my @children = (
            (map { { kind => $_->{activation_kind} // 'spawn', instance => $_->{instance}, child => $_->{child} } }
                @{$domain_ir->{spawn_instances} || []}),
            (map { { kind => 'library', instance => $_->{instance}, child => $_->{module} } }
                @{$domain_ir->{library_uses} || []}),
        );
        for my $top (@{$domain_ir->{atl_top_instances} || []}) {
            my @atl = ref($top->{children}) eq 'ARRAY' ? @{$top->{children}} : ($top);
            push @children, map { { kind => 'actor', instance => $_->{instance}, child => $_->{child_module} } } @atl;
        }
        for my $child (@children) {
            my $instance = $child->{instance};
            confess "Domain '$domain->{name}' has duplicate composition instance '$instance'\n"
                if exists $names->{instances}{$instance};
            $names->{instances}{$instance} = $allocate->("$domain->{instance}__$instance", \%instances);
        }
        push @realizations, { domain => $domain, ir => $domain_ir, names => $names, composed => @children ? 1 : 0 };
    }
    return \@realizations;
}

sub _emit_multi_domain_top($self, $actor, $partition, $realizations) {
    my $top_name = "$actor->{actor_name}_top";
    my @lines;

    push @lines, "(?top:$top_name";
    push @lines, _emit_multi_domain_top_ports($actor, $partition);
    my $links = _multi_domain_links($actor, $partition);
    my %composed = map { $_->{domain}{instance} => 1 } grep { $_->{composed} } @$realizations;
    for my $realization (@$realizations) {
        my $domain = $realization->{domain};
        if (!$realization->{composed}) {
            push @lines, _emit_domain_instance($domain);
            next;
        }
        my $names = $realization->{names};
        my $prefix = "$domain->{instance}.";
        for my $link (@$links) {
            if (index($link->[1], $prefix) == 0) {
                push @{$names->{sources}{substr($link->[1], length($prefix))}}, $link->[0];
            }
            if (index($link->[0], $prefix) == 0) {
                push @{$names->{targets}{substr($link->[0], length($prefix))}}, $link->[1];
            }
        }
        push @lines, $self->{top_emitter}->emit_components($realization->{ir}, $names);
    }
    my @outer_links = grep {
        my ($source, $target) = @$_;
        my ($source_instance) = split /\./, $source, 2;
        my ($target_instance) = split /\./, $target, 2;
        !$composed{$source_instance} && !$composed{$target_instance};
    } @$links;
    for my $crossing (@{$partition->{crossings} || []}) {
        next unless ($crossing->{kind} // '') eq 'event';
        push @lines, "  (?rtl:$crossing->{instance} $crossing->{module})";
    }
    for my $crossing (@{$partition->{crossings} || []}) {
        next unless ($crossing->{kind} // '') eq 'activation';
        push @lines, "  (?rtl:$crossing->{start_instance} $crossing->{start_module})";
        push @lines, "  (?rtl:$crossing->{done_instance} $crossing->{done_module})";
    }
    push @lines, "  (?wiring:domain_wiring",
        (map { "    ($_->[0] $_->[1])" } @outer_links), "  )";
    push @lines, ')';

    for my $crossing (@{$partition->{crossings} || []}) {
        next unless ($crossing->{kind} // '') eq 'event';
        push @lines, '';
        push @lines, _emit_crossing_rtlif($crossing, $partition);
    }
    for my $crossing (@{$partition->{crossings} || []}) {
        next unless ($crossing->{kind} // '') eq 'activation';
        push @lines, '';
        push @lines, _emit_activation_crossing_rtlif($crossing, $partition, 'start');
        push @lines, '';
        push @lines, _emit_activation_crossing_rtlif($crossing, $partition, 'done');
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
    return "  (?fsmc:$domain->{instance} $module)";
}

sub _multi_domain_links($actor, $partition) {
    my @links;
    my %domain_by_name = map { $_->{name} => $_ } @{$partition->{domains} || []};

    for my $input (@{$actor->{interface}{inputs} || []}) {
        my $domain = $domain_by_name{_entry_domain($input, $partition->{default_domain})};
        push @links, _link($input->{name}, "$domain->{instance}.$input->{name}");
    }
    for my $output (@{$actor->{interface}{outputs} || []}) {
        my $domain = $domain_by_name{_entry_domain($output, $partition->{default_domain})};
        push @links, _link("$domain->{instance}.$output->{name}", $output->{name});
    }
    for my $crossing (@{$partition->{crossings} || []}) {
        next unless ($crossing->{kind} // '') eq 'event';
        my $source_domain = $domain_by_name{$crossing->{source_domain}};
        my $dest_domain = $domain_by_name{$crossing->{destination_domain}};
        my $instance = $crossing->{instance};
        push @links, _link($source_domain->{clock}, "$instance.source_clk");
        push @links, _link($dest_domain->{clock}, "$instance.dest_clk");
        push @links, _link($source_domain->{reset}{name}, "$instance.source_reset")
            if ref($source_domain->{reset}) eq 'HASH';
        push @links, _link($dest_domain->{reset}{name}, "$instance.dest_reset")
            if ref($dest_domain->{reset}) eq 'HASH';
        push @links, _link("$source_domain->{instance}.$crossing->{source_signal}", "$instance.request");
        push @links, _link("$instance.ready", "$source_domain->{instance}.$crossing->{ready_signal}");
        push @links, _link("$instance.pulse", "$dest_domain->{instance}.$crossing->{destination_signal}");
    }
    for my $crossing (@{$partition->{crossings} || []}) {
        next unless ($crossing->{kind} // '') eq 'activation';
        my $src = $domain_by_name{$crossing->{source_domain}};
        my $dst = $domain_by_name{$crossing->{destination_domain}};
        my $start_signal = $crossing->{start_signal};
        my $done_signal = $crossing->{done_signal};
        my $start = $crossing->{start_instance};
        my $done = $crossing->{done_instance};

        # start synchronizer: SRC drives the one-cycle request -> DEST start pulse.
        push @links, _link($src->{clock}, "$start.source_clk");
        push @links, _link($dst->{clock}, "$start.dest_clk");
        push @links, _link($src->{reset}{name}, "$start.source_reset")
            if ref($src->{reset}) eq 'HASH';
        push @links, _link($dst->{reset}{name}, "$start.dest_reset")
            if ref($dst->{reset}) eq 'HASH';
        push @links, _link("$src->{instance}.$start_signal", "$start.request");
        push @links, _link("$start.pulse", "$dst->{instance}.$start_signal");
        # The caller awaits `<start>_ready` before issuing the one-cycle request,
        # so route the start CDC `ready` back to the SRC module (the event-crossing
        # idiom). This also consumes the CDC `ready` output for the composition.
        push @links, _link("$start.ready", "$src->{instance}.${start_signal}_ready");

        # done synchronizer: DEST drives the one-cycle done -> SRC release pulse.
        push @links, _link($dst->{clock}, "$done.source_clk");
        push @links, _link($src->{clock}, "$done.dest_clk");
        push @links, _link($dst->{reset}{name}, "$done.source_reset")
            if ref($dst->{reset}) eq 'HASH';
        push @links, _link($src->{reset}{name}, "$done.dest_reset")
            if ref($src->{reset}) eq 'HASH';
        push @links, _link("$dst->{instance}.$done_signal", "$done.request");
        push @links, _link("$done.pulse", "$src->{instance}.$done_signal");
        # The callee awaits `<done>_ready` before pulsing `<done>`; route the done
        # CDC `ready` back to the DEST module (consuming the output).
        push @links, _link("$done.ready", "$dst->{instance}.${done_signal}_ready");
    }

    return \@links;
}

sub _emit_crossing_rtlif($crossing, $partition) {
    my %domain_by_name = map { $_->{name} => $_ } @{$partition->{domains} || []};
    return _emit_cdc_event_rtlif(
        $crossing->{module},
        $domain_by_name{$crossing->{source_domain}},
        $domain_by_name{$crossing->{destination_domain}},
    );
}

# Shared acknowledged-event CDC child interface artifact, used by both the
# `(event ...)` crossing and the two `(activation ...)` start/done synchronizers.
sub _emit_cdc_event_rtlif($module_name, $source_domain, $dest_domain) {
    my @lines;
    push @lines, "(?rtlif:$module_name";
    push @lines, '  (params';
    push @lines, '    (FSMGEN_ISF_CDC_EVENT 0d1)';
    push @lines, _emit_crossing_reset_param_lines('SOURCE', $source_domain->{reset});
    push @lines, _emit_crossing_reset_param_lines('DEST', $dest_domain->{reset});
    push @lines, '  )';
    push @lines, '  source_clk:clock';
    push @lines, '  dest_clk:clock';
    push @lines, '  source_reset:reset'
        if ref($source_domain->{reset}) eq 'HASH';
    push @lines, '  dest_reset:reset'
        if ref($dest_domain->{reset}) eq 'HASH';
    push @lines, '  request<:data';
    push @lines, '  ready>:data';
    push @lines, '  pulse>:data';
    push @lines, ')';
    return join("\n", @lines);
}

# The two CDC children of one activation crossing: `start` synchronizes SRC->DEST,
# `done` synchronizes DEST->SRC (source/dest reversed).
sub _emit_activation_crossing_rtlif($crossing, $partition, $direction) {
    my %domain_by_name = map { $_->{name} => $_ } @{$partition->{domains} || []};
    my $src = $domain_by_name{$crossing->{source_domain}};
    my $dst = $domain_by_name{$crossing->{destination_domain}};
    my ($source_domain, $dest_domain, $module_name) = $direction eq 'start'
        ? ($src, $dst, $crossing->{start_module})
        : ($dst, $src, $crossing->{done_module});
    return _emit_cdc_event_rtlif($module_name, $source_domain, $dest_domain);
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
    return [$from, $to];
}

sub _scheduled_module_name($domain) {
    my $module = $domain->{scheduled_fsm};
    $module =~ s/\.fsm\z//;
    return $module;
}


1;
