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
    return undef unless @spawn_instances;

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
    push @lines, _emit_toplink_block($ir, \@spawn_instances);
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

sub _emit_toplink_block {
    my ($ir, $spawn_instances) = @_;
    my $actor_name = $ir->{actor_name};
    my %parent_port = map { $_->{name} => $_ } @{$ir->{ports} || []};
    my %child_ports_by_name = map {
        $_ => {
            map { $_->{name} => $_ } @{($ir->{children} || {})->{$_}{ports} || []}
        }
    } keys %{$ir->{children} || {}};
    my @links;

    for my $port (@{$ir->{ports} || []}) {
        next if $port->{isf_handoff};
        my $name = $port->{name};
        if ($port->{direction} eq 'output') {
            push @links, "/$actor_name.$name/$name/";
        } else {
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

    my @lines = ('  (?toplink:isf_wiring');
    push @lines, map { "    $_" } @links;
    push @lines, '  )';
    return join("\n", @lines);
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
