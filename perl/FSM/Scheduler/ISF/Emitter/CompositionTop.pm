package FSM::Scheduler::ISF::Emitter::CompositionTop;

use v5.20;
use strict;
use warnings;
use feature qw(signatures postderef);
no warnings 'experimental::signatures';

use Carp qw(confess);
use FSM::Debug;

sub new($class, %args) { bless {}, $class }

sub emit($self, $ir, $files) {
    confess "CompositionTop emitter requires parent lowering IR\n"
        unless ref($ir) eq 'HASH';
    confess "CompositionTop emitter requires emitted file map\n"
        unless ref($files) eq 'HASH';

    my @spawn_instances = @{$ir->{spawn_instances} || []};
    my @library_uses = @{$ir->{library_uses} || []};
    my @atl_top_instances = @{$ir->{atl_top_instances} || []};
    return undef unless @spawn_instances || @library_uses || @atl_top_instances;

    fsm_trace_enter('Emitter::CompositionTop emit', 2);

    my $actor_name = $ir->{actor_name};
    my $top_name = "${actor_name}_top";
    my $parent_file = "$actor_name.fsm";

    confess "CompositionTop emitter cannot find emitted parent '$parent_file'\n"
        unless exists $files->{$parent_file};

    my @lines;
    push @lines, "(?top:$top_name";
    push @lines, _emit_ports_block($ir);
    push @lines, $self->emit_components($ir);
    push @lines, ')';
    push @lines, '';
    push @lines, _trim_trailing_newlines($files->{$parent_file});

    for my $child_name (sort keys %{$ir->{children} || {}}) {
        my $child_file = "$child_name.fsm";
        confess "CompositionTop emitter cannot find emitted child '$child_file'\n"
            unless exists $files->{$child_file};
        push @lines, '';
        push @lines, _trim_trailing_newlines($files->{$child_file});
    }

    fsm_trace_exit('Emitter::CompositionTop emit', 2);
    return join("\n", @lines) . "\n";
}

# A domain contributes ordinary children and wiring to one flat outer top.
# Keep logical handoff names in the IR; map only instance/module identities and
# boundary endpoints at emission, so helper names and parameter values survive.
sub emit_components($self, $ir, $names = {}) {
    my @spawns = @{$ir->{spawn_instances} || []};
    my @uses = @{$ir->{library_uses} || []};
    my @atl = @{$ir->{atl_top_instances} || []};
    return (
        _emit_parent_instance($ir->{actor_name}, $names),
        (map { _emit_spawn_instance($_, $names) } @spawns),
        (map { _emit_library_instance($_, $names) } @uses),
        (map { _emit_atl_instance($_, $names) } @atl),
        _emit_wiring_block($ir, \@spawns, \@uses, \@atl, $names),
    );
}

sub _mapped_name {
    my ($names, $kind, $name) = @_;
    return $name unless defined $name;
    return ($names->{$kind} || {})->{$name} // $name;
}

sub _emit_ports_block {
    my ($ir) = @_;
    my @tokens;
    my %seen;
    my %atl_internal_parent_port = _atl_internal_parent_port_map($ir->{atl_top_instances} || []);

    _push_port_token(\@tokens, \%seen, $ir->{clock}, 'input', 1)
        if defined($ir->{clock}) && length($ir->{clock});

    my $reset = $ir->{reset};
    _push_port_token(\@tokens, \%seen, $reset->{name}, 'input', 1)
        if ref($reset) eq 'HASH' && defined($reset->{name}) && length($reset->{name});

    for my $port (@{$ir->{ports} || []}) {
        next if $port->{isf_handoff};
        next if $atl_internal_parent_port{$port->{name}};
        _push_port_token(\@tokens, \%seen, $port->{name}, $port->{direction}, $port->{width} // 1);
    }

    my @lines = ('  (?ports:public_io');
    push @lines, map { "    $_" } @tokens;
    push @lines, '  )';
    return join("\n", @lines);
}

sub _push_port_token {
    my ($tokens, $seen, $name, $direction, $width) = @_;
    return if !defined($name) || ref($name) || !length($name);
    return if $seen->{$name}++;

    push @$tokens, _format_port_token($name, $direction, $width);
}

sub _format_port_token {
    my ($name, $direction, $width) = @_;
    $width = 1 unless defined($width) && $width > 0;

    return $name if $direction eq 'input' && $width == 1;
    return "$name<$width" if $direction eq 'input';
    return "$name>" if $width == 1;
    return "$name>$width";
}

sub _emit_parent_instance {
    my ($actor_name, $names) = @_;
    my $instance = _mapped_name($names, 'instances', $actor_name);
    return "  (?fsmc:$instance $actor_name)";
}

sub _emit_spawn_instance {
    my ($spawn, $names) = @_;
    my $instance = _mapped_name($names, 'instances', $spawn->{instance});
    my $child = _mapped_name($names, 'modules', $spawn->{child});
    my @overrides = @{$spawn->{parameter_overrides} || []};

    return "  (?fsmc:$instance $child)" unless @overrides;

    my @lines;
    push @lines, "  (?fsmc:$instance $child";
    push @lines, '    (params';
    for my $override (@overrides) {
        push @lines, "      ($override->{name} " . _format_param_value($override->{value}) . ")";
    }
    push @lines, '    )';
    push @lines, '  )';
    return join("\n", @lines);
}

sub _emit_library_instance {
    my ($use, $names) = @_;
    my $instance = _mapped_name($names, 'instances', $use->{instance});
    my $module = _mapped_name($names, 'modules', $use->{module});
    my @overrides = @{$use->{parameter_overrides} || []};

    confess "CompositionTop emitter library use is missing an instance name\n"
        unless defined($instance) && length($instance);
    confess "CompositionTop emitter library use '$instance' is missing a module name\n"
        unless defined($module) && length($module);

    return "  (?fsmc:$instance $module)" unless @overrides;

    my @lines;
    push @lines, "  (?fsmc:$instance $module";
    push @lines, '    (params';
    for my $override (@overrides) {
        push @lines, "      ($override->{name} " . _format_param_value($override->{value}) . ")";
    }
    push @lines, '    )';
    push @lines, '  )';
    return join("\n", @lines);
}

sub _emit_atl_instance {
    my ($top, $names) = @_;
    my @lines;

    for my $child (_atl_top_children($top)) {
        my $instance = _mapped_name($names, 'instances', $child->{instance});
        my $module = _mapped_name($names, 'modules', $child->{child_module});

        confess "CompositionTop emitter ATL top binding is missing an instance name\n"
            unless defined($instance) && length($instance);
        confess "CompositionTop emitter ATL top binding '$instance' is missing a child module name\n"
            unless defined($module) && length($module);

        push @lines, "  (?fsmc:$instance $module)";
    }

    confess "CompositionTop emitter ATL top binding has no children\n"
        unless @lines;

    return join("\n", @lines);
}

sub _emit_wiring_block {
    my ($ir, $spawn_instances, $library_uses, $atl_top_instances, $names) = @_;
    my $actor_name = $ir->{actor_name};
    my %parent_port = map { $_->{name} => $_ } @{$ir->{ports} || []};
    my %child_ports_by_name = map {
        $_ => {
            map { $_->{name} => $_ } @{($ir->{children} || {})->{$_}{ports} || []}
        }
    } keys %{$ir->{children} || {}};
    my @links;
    my %library_output_parent = _library_output_parent_port_map($library_uses || []);
    my %atl_internal_parent_port = _atl_internal_parent_port_map($atl_top_instances || []);

    for my $port (@{$ir->{ports} || []}) {
        next if $port->{isf_handoff};
        my $name = $port->{name};
        next if $atl_internal_parent_port{$name};
        next if $library_output_parent{$name};
        if ($port->{direction} eq 'output') {
            push @links, _link($actor_name . ".$name", $name);
        } else {
            push @links, _link($name, $actor_name . ".$name");
        }
    }

    for my $spawn (@$spawn_instances) {
        my $instance = $spawn->{instance};
        my $child = $spawn->{child};
        my $child_ports = $child_ports_by_name{$child} || {};
        my $activation_kind = $spawn->{activation_kind} // 'spawn';
        my %bound_inputs = map { $_->{child_port} => 1 }
            grep { ($_->{role} || '') eq 'input' } @{$spawn->{port_bindings} || []};

        if ($activation_kind eq 'spawn') {
            my %explicit_binding_sources = _spawn_input_binding_source_signals($spawn);
            for my $port (@{$ir->{ports} || []}) {
                next if $port->{isf_handoff};
                next unless $port->{direction} eq 'input';
                my $name = $port->{name};
                next if $name eq 'start';
                next if $bound_inputs{$name};
                next if $explicit_binding_sources{$name};
                next unless exists $child_ports->{$name};
                next unless ($child_ports->{$name}{direction} || '') eq 'input';
                push @links, _link($name, $instance . ".$name");
            }
        }

        if ($activation_kind eq 'do') {
            # A generated do can read inherited actor inputs as well as its
            # explicitly bound payload. Explicit child bindings win by name.
            for my $port (@{$ir->{ports} || []}) {
                next if $port->{isf_handoff} || $port->{direction} ne 'input';
                my $name = $port->{name};
                next if $name eq 'start' || $bound_inputs{$name};
                next unless exists($child_ports->{$name})
                    && ($child_ports->{$name}{direction} || '') eq 'input';
                push @links, _link($name, $instance . ".$name");
            }
        }

        for my $binding (@{$spawn->{port_bindings} || []}) {
            next unless ($binding->{role} || '') eq 'input';
            push @links, _link(
                $actor_name . ".$binding->{parent_port}",
                $instance . ".$binding->{child_port}",
            );
        }

        for my $read (@{$spawn->{actor_storage_reads} || []}) {
            push @links, _link(
                $actor_name . ".$read->{parent_port}",
                $instance . ".$read->{child_port}",
            );
        }

        for my $write (@{$spawn->{actor_storage_writes} || []}) {
            push @links, _link($instance . ".$write->{child_port}", $actor_name . ".$write->{parent_port}");
        }

        for my $output (@{$spawn->{actor_completion_outputs} || []}) {
            push @links, _link($instance . ".$output->{child_port}", $actor_name . ".$output->{parent_port}");
        }

        push @links, _link($actor_name . ".${instance}_start", $instance . '.start');
        push @links, _link($instance . '.done', $actor_name . ".${instance}_done");

        my %completion_outputs = map { $_->{child_port} => 1 }
            @{$spawn->{actor_completion_outputs} || []};
        my %write_outputs = map { $_->{child_port} => 1 }
            @{$spawn->{actor_storage_writes} || []};
        for my $port_name (sort keys %$child_ports) {
            next if $port_name eq 'done';
            next if $write_outputs{$port_name};
            # Actor completion routing has its own allocated input. An authored
            # public port with the old suffix is not an implicit second binding.
            next if $completion_outputs{$port_name};
            my $port = $child_ports->{$port_name};
            next unless ($port->{direction} || '') eq 'output';
            my $parent_handoff = "${instance}_${port_name}";
            next unless exists $parent_port{$parent_handoff};
            push @links, _link($instance . ".$port_name", $actor_name . ".$parent_handoff");
        }
    }

    for my $use (@$library_uses) {
        my $instance = $use->{instance};
        my $module = $use->{module};
        my $child_ports = $child_ports_by_name{$module} || {};

        for my $binding (@{$use->{bindings} || []}) {
            my $role = $binding->{role};
            my $parent_name = $binding->{parent_name};

            if ($role eq 'clock') {
                my $child_clock = $use->{child_clock};
                confess "CompositionTop emitter library use '$instance' has a clock binding but no child clock name\n"
                    unless defined($child_clock) && length($child_clock);
                push @links, _link($parent_name, $instance . ".$child_clock")
                    unless $child_clock eq $parent_name;
                next;
            }

            if ($role eq 'reset') {
                my $child_reset = $use->{child_reset};
                confess "CompositionTop emitter library use '$instance' has a reset binding but no child reset name\n"
                    unless defined($child_reset) && length($child_reset);
                push @links, _link($parent_name, $instance . ".$child_reset")
                    unless $child_reset eq $parent_name;
                next;
            }

            my $library_name = $binding->{library_name};
            confess "CompositionTop emitter library use '$instance' binding is missing a library port name\n"
                unless defined($library_name) && length($library_name);
            confess "CompositionTop emitter library use '$instance' references child port '$library_name' not present on module '$module'\n"
                unless exists $child_ports->{$library_name};

            if ($role eq 'input') {
                push @links, _link($parent_name, $instance . ".$library_name");
                next;
            }
            if ($role eq 'output') {
                push @links, _link($instance . ".$library_name", $parent_name);
                push @links, _link($instance . ".$library_name", $actor_name . ".$parent_name");
                next;
            }

            confess "CompositionTop emitter library use '$instance' has unsupported binding role '$role'\n";
        }
    }

    for my $top (@$atl_top_instances) {
        for my $child (_atl_top_children($top)) {
            my $instance = $child->{instance};
            my $module = $child->{child_module};
            my $child_ports = $child_ports_by_name{$module} || {};
            my $trigger_parent = $child->{trigger_parent_port};
            my $trigger_child = $child->{trigger_child_port};
            my $event_parent = $child->{event_parent_port};
            my $event_child = $child->{event_child_port};
            my @data_links = @{$child->{data_links} || []};

            confess "CompositionTop emitter ATL instance '$instance' references child module '$module' not present in emitted children\n"
                unless keys %$child_ports;
            confess "CompositionTop emitter ATL instance '$instance' trigger child port '$trigger_child' is not present on module '$module'\n"
                unless exists $child_ports->{$trigger_child};
            confess "CompositionTop emitter ATL instance '$instance' event child port '$event_child' is not present on module '$module'\n"
                unless exists $child_ports->{$event_child};
            confess "CompositionTop emitter ATL parent trigger port '$trigger_parent' is not present on parent '$actor_name'\n"
                unless exists $parent_port{$trigger_parent};
            confess "CompositionTop emitter ATL parent event port '$event_parent' is not present on parent '$actor_name'\n"
                unless exists $parent_port{$event_parent};

            push @links, _link($actor_name . ".$trigger_parent", $instance . ".$trigger_child");
            push @links, _link($instance . ".$event_child", $actor_name . ".$event_parent");

            for my $data_link (@data_links) {
                if (($data_link->{kind} // '') eq 'scalar_pin_to_resolved_child_handoff') {
                    my $parent_sink = $data_link->{parent_sink_port};
                    my $child_sink = $data_link->{child_sink_port};

                    confess "CompositionTop emitter ATL parent data handoff port '$parent_sink' is not present on parent '$actor_name'\n"
                        unless exists $parent_port{$parent_sink};
                    confess "CompositionTop emitter ATL child data input '$child_sink' is not present on module '$module'\n"
                        unless exists $child_ports->{$child_sink};
                    confess "CompositionTop emitter ATL child data endpoint '$child_sink' must be an input on module '$module'\n"
                        unless ($child_ports->{$child_sink}{direction} || '') eq 'input';

                    push @links, _link($actor_name . ".$parent_sink", $instance . ".$child_sink");
                    next;
                }

                if (($data_link->{kind} // '') eq 'scalar_resolved_child_to_pin_handoff') {
                    my $parent_source = $data_link->{parent_source_port};
                    my $child_source = $data_link->{child_source_port};

                    confess "CompositionTop emitter ATL parent data handoff port '$parent_source' is not present on parent '$actor_name'\n"
                        unless exists $parent_port{$parent_source};
                    confess "CompositionTop emitter ATL child data output '$child_source' is not present on module '$module'\n"
                        unless exists $child_ports->{$child_source};
                    confess "CompositionTop emitter ATL child data endpoint '$child_source' must be an output on module '$module'\n"
                        unless ($child_ports->{$child_source}{direction} || '') eq 'output';

                    push @links, _link($instance . ".$child_source", $actor_name . ".$parent_source");
                    next;
                }

                if (($data_link->{kind} // '') eq 'scalar_resolved_child_to_parent_handoff') {
                    my $parent_source = $data_link->{parent_source_port};
                    my $child_source = $data_link->{child_source_port};

                    confess "CompositionTop emitter ATL parent data handoff port '$parent_source' is not present on parent '$actor_name'\n"
                        unless exists $parent_port{$parent_source};
                    confess "CompositionTop emitter ATL child data output '$child_source' is not present on module '$module'\n"
                        unless exists $child_ports->{$child_source};
                    confess "CompositionTop emitter ATL child data endpoint '$child_source' must be an output on module '$module'\n"
                        unless ($child_ports->{$child_source}{direction} || '') eq 'output';

                    push @links, _link($instance . ".$child_source", $actor_name . ".$parent_source");
                    next;
                }

                if (($data_link->{kind} // '') eq 'scalar_parent_to_resolved_child_handoff') {
                    my $parent_sink = $data_link->{parent_sink_port};
                    my $child_sink = $data_link->{child_sink_port};

                    confess "CompositionTop emitter ATL parent data handoff port '$parent_sink' is not present on parent '$actor_name'\n"
                        unless exists $parent_port{$parent_sink};
                    confess "CompositionTop emitter ATL child data input '$child_sink' is not present on module '$module'\n"
                        unless exists $child_ports->{$child_sink};
                    confess "CompositionTop emitter ATL child data endpoint '$child_sink' must be an input on module '$module'\n"
                        unless ($child_ports->{$child_sink}{direction} || '') eq 'input';

                    push @links, _link($actor_name . ".$parent_sink", $instance . ".$child_sink");
                    next;
                }

                confess "CompositionTop emitter ATL data link has unsupported kind '$data_link->{kind}'\n";
            }
        }
    }

    my $wiring_name = $names->{wiring_name} // 'isf_wiring';
    my @lines = ("  (?wiring:$wiring_name");
    for my $link (@links) {
        my @sources = _mapped_endpoints($link->[0], $names, 'sources');
        my @targets = _mapped_endpoints($link->[1], $names, 'targets');
        confess "Composition boundary '$link->[0]' has multiple drivers\n" if @sources != 1;
        push @lines, map { "    ($sources[0] $_)" } @targets;
    }
    push @lines, '  )';
    return join("\n", @lines);
}

sub _mapped_endpoints {
    my ($endpoint, $names, $direction) = @_;
    if ($endpoint =~ /\A([^.]+)\.(.+)\z/) {
        my ($instance, $port) = ($1, $2);
        return _mapped_name($names, 'instances', $instance) . ".$port";
    }
    return @{$names->{$direction}{$endpoint}}
        if exists($names->{$direction}) && exists($names->{$direction}{$endpoint});
    return $endpoint;
}

sub _link {
    my ($source, $target) = @_;
    return [$source, $target];
}

sub _spawn_input_binding_source_signals {
    my ($spawn) = @_;
    my %signals;

    for my $binding (@{$spawn->{port_bindings} || []}) {
        next unless ($binding->{role} || '') eq 'input';
        my $expr = exists($binding->{actor_expr}) ? $binding->{actor_expr} : $binding->{actor_signal};
        $signals{$_} = 1 for _expr_signal_names($expr);
    }

    return %signals;
}

sub _expr_signal_names {
    my ($expr) = @_;
    return () unless defined $expr;
    if (!ref($expr)) {
        return _is_hdl_identifier($expr) ? ($expr) : ();
    }
    return () unless ref($expr) eq 'ARRAY';

    my @signals;
    for my $index (0 .. $#$expr) {
        next if $index == 0 && !ref($expr->[$index]);
        push @signals, _expr_signal_names($expr->[$index]);
    }
    return @signals;
}

sub _is_hdl_identifier {
    my ($value) = @_;
    return defined($value) && !ref($value) && $value =~ /\A[A-Za-z_]\w*\z/;
}

sub _library_output_parent_port_map {
    my ($library_uses) = @_;
    my %drivers;

    for my $use (@$library_uses) {
        my $instance = $use->{instance} // 'unknown';
        for my $binding (@{$use->{bindings} || []}) {
            next unless ($binding->{role} || '') eq 'output';
            my $parent_name = $binding->{parent_name};
            next unless defined($parent_name) && length($parent_name);
            confess "CompositionTop emitter library output '$parent_name' is driven by both '$drivers{$parent_name}' and '$instance'\n"
                if exists $drivers{$parent_name};
            $drivers{$parent_name} = $instance;
        }
    }

    return %drivers;
}

sub _atl_internal_parent_port_map {
    my ($atl_top_instances) = @_;
    my %ports;

    for my $top (@$atl_top_instances) {
        for my $child (_atl_top_children($top)) {
            $ports{$child->{trigger_parent_port}} = 1
                if defined($child->{trigger_parent_port}) && length($child->{trigger_parent_port});
            $ports{$child->{event_parent_port}} = 1
                if defined($child->{event_parent_port}) && length($child->{event_parent_port});
            for my $data_link (@{$child->{data_links} || []}) {
                $ports{$data_link->{parent_sink_port}} = 1
                    if defined($data_link->{parent_sink_port}) && length($data_link->{parent_sink_port});
                $ports{$data_link->{parent_source_port}} = 1
                    if defined($data_link->{parent_source_port}) && length($data_link->{parent_source_port});
            }
        }
    }

    return %ports;
}

sub _atl_top_children {
    my ($top) = @_;
    return () unless ref($top) eq 'HASH';
    return @{$top->{children}}
        if ref($top->{children}) eq 'ARRAY' && @{$top->{children}};
    return ($top);
}

sub _format_param_value {
    my ($value) = @_;
    return $value unless ref($value) eq 'ARRAY';
    return '(' . join(' ', map { _format_param_value($_) } @$value) . ')';
}

sub _trim_trailing_newlines {
    my ($text) = @_;
    $text = '' unless defined $text;
    $text =~ s/\n+\z//;
    return $text;
}

1;
