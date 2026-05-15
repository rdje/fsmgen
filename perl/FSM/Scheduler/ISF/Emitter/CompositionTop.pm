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
    return undef unless @spawn_instances || @library_uses;

    fsm_trace_enter('Emitter::CompositionTop emit', 2);

    my $actor_name = $ir->{actor_name};
    my $top_name = "${actor_name}_top";
    my $parent_file = "$actor_name.fsm";

    confess "CompositionTop emitter cannot find emitted parent '$parent_file'\n"
        unless exists $files->{$parent_file};

    my @lines;
    push @lines, "(?top:$top_name";
    push @lines, _emit_ports_block($ir);
    push @lines, _emit_parent_instance($actor_name);
    push @lines, map { _emit_spawn_instance($_) } @spawn_instances;
    push @lines, map { _emit_library_instance($_) } @library_uses;
    push @lines, _emit_toplink_block($ir, \@spawn_instances, \@library_uses);
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

sub _emit_ports_block {
    my ($ir) = @_;
    my @tokens;
    my %seen;

    _push_port_token(\@tokens, \%seen, $ir->{clock}, 'input', 1)
        if defined($ir->{clock}) && length($ir->{clock});

    my $reset = $ir->{reset};
    _push_port_token(\@tokens, \%seen, $reset->{name}, 'input', 1)
        if ref($reset) eq 'HASH' && defined($reset->{name}) && length($reset->{name});

    for my $port (@{$ir->{ports} || []}) {
        next if $port->{isf_handoff};
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
    my ($actor_name) = @_;
    return "  (?fsmc:$actor_name $actor_name)";
}

sub _emit_spawn_instance {
    my ($spawn) = @_;
    my $instance = $spawn->{instance};
    my $child = $spawn->{child};
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
    my ($use) = @_;
    my $instance = $use->{instance};
    my $module = $use->{module};
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

sub _emit_toplink_block {
    my ($ir, $spawn_instances, $library_uses) = @_;
    my $actor_name = $ir->{actor_name};
    my %parent_port = map { $_->{name} => $_ } @{$ir->{ports} || []};
    my %child_ports_by_name = map {
        $_ => {
            map { $_->{name} => $_ } @{($ir->{children} || {})->{$_}{ports} || []}
        }
    } keys %{$ir->{children} || {}};
    my @links;
    my %library_output_parent = _library_output_parent_port_map($library_uses || []);
    my %library_input_parent = _library_input_parent_port_map($library_uses || []);

    for my $port (@{$ir->{ports} || []}) {
        next if $port->{isf_handoff};
        my $name = $port->{name};
        if ($port->{direction} eq 'output') {
            next if $library_output_parent{$name};
            push @links, "/$actor_name.$name/$name/";
        } else {
            next if $library_input_parent{$name};
            push @links, "/$name/$actor_name.$name/";
        }
    }

    for my $spawn (@$spawn_instances) {
        my $instance = $spawn->{instance};
        my $child = $spawn->{child};
        my $child_ports = $child_ports_by_name{$child} || {};

        for my $port (@{$ir->{ports} || []}) {
            next if $port->{isf_handoff};
            next unless $port->{direction} eq 'input';
            my $name = $port->{name};
            next unless exists $child_ports->{$name};
            next unless ($child_ports->{$name}{direction} || '') eq 'input';
            push @links, "/$name/$instance.$name/";
        }

        for my $binding (@{$spawn->{port_bindings} || []}) {
            next unless ($binding->{role} || '') eq 'input';
            push @links, "/$actor_name.$binding->{parent_port}/$instance.$binding->{child_port}/";
        }

        push @links, "/$actor_name.${instance}_start/$instance.start/";
        push @links, "/$instance.done/$actor_name.${instance}_done/";

        for my $port_name (sort keys %$child_ports) {
            next if $port_name eq 'done';
            my $port = $child_ports->{$port_name};
            next unless ($port->{direction} || '') eq 'output';
            my $parent_handoff = "${instance}_${port_name}";
            next unless exists $parent_port{$parent_handoff};
            push @links, "/$instance.$port_name/$actor_name.$parent_handoff/";
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
                confess "CompositionTop emitter library use '$instance' binds parent clock '$parent_name' to child clock '$child_clock', but generated composition currently requires same-name system clocks\n"
                    unless $child_clock eq $parent_name;
                next;
            }

            if ($role eq 'reset') {
                my $child_reset = $use->{child_reset};
                confess "CompositionTop emitter library use '$instance' has a reset binding but no child reset name\n"
                    unless defined($child_reset) && length($child_reset);
                confess "CompositionTop emitter library use '$instance' binds parent reset '$parent_name' to child reset '$child_reset', but generated composition currently requires same-name system resets\n"
                    unless $child_reset eq $parent_name;
                next;
            }

            my $library_name = $binding->{library_name};
            confess "CompositionTop emitter library use '$instance' binding is missing a library port name\n"
                unless defined($library_name) && length($library_name);
            confess "CompositionTop emitter library use '$instance' references child port '$library_name' not present on module '$module'\n"
                unless exists $child_ports->{$library_name};

            if ($role eq 'input') {
                push @links, "/$parent_name/$instance.$library_name/";
                next;
            }
            if ($role eq 'output') {
                push @links, "/$instance.$library_name/$parent_name/";
                next;
            }

            confess "CompositionTop emitter library use '$instance' has unsupported binding role '$role'\n";
        }
    }

    my @lines = ('  (?toplink:isf_wiring');
    push @lines, map { "    $_" } @links;
    push @lines, '  )';
    return join("\n", @lines);
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

sub _library_input_parent_port_map {
    my ($library_uses) = @_;
    my %consumers;

    for my $use (@$library_uses) {
        for my $binding (@{$use->{bindings} || []}) {
            next unless ($binding->{role} || '') eq 'input';
            my $parent_name = $binding->{parent_name};
            next unless defined($parent_name) && length($parent_name);
            $consumers{$parent_name} = 1;
        }
    }

    return %consumers;
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
