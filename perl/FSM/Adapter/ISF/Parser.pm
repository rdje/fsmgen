package FSM::Adapter::ISF::Parser;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use feature qw(signatures postderef);
no warnings 'experimental::signatures';

use Lispish;
use File::Slurp qw(read_file);
use FSM::Adapter::ISF::LispishAdapter;
use FSM::Debug;

# Parses .isf source files into a structured, validated AST.
#
# Pipeline: Lispish raw parse -> LispishAdapter normalization -> validation
#
# Output shape:
#   {
#     actor_name    => "apb_requester",
#     clock         => "clk",
#     reset         => { name => "rst_n", kind => "async", polarity => "active_low" },
#     watchdog      => 65536,
#     interface     => { inputs => [...], outputs => [...] },
#     handshakes    => { name => { valid => ..., ready => ... }, ... },
#     transactions  => [ { name => ..., clauses => [...] }, ... ],
#     rules         => [ { name => ..., when => ..., actions => [...] }, ... ],
#     resources     => [ { name => ..., arbiter => ... }, ... ],
#     priorities    => [ ... ],
#   }

sub new($class, %args) {
    return bless {
        debug   => ($args{debug} // 0),
        adapter => FSM::Adapter::ISF::LispishAdapter->new(debug => ($args{debug} // 0)),
    }, $class;
}

sub parse_file($self, $isf_path) {
    fsm_trace_enter("Parser parse_file: $isf_path", 2);
    my $source_text = read_file($isf_path);
    my $result = $self->parse_source($source_text, $isf_path);
    fsm_trace_exit("Parser parse_file completed for $isf_path", 2);
    return $result;
}

sub parse_source($self, $source_text, $source_label) {
    fsm_trace_enter("Parser parse_source: $source_label", 2);

    # Stage 1: raw Lispish parse
    fsm_debug("Raw Lispish parse", 3);
    my $raw = Lispish::multi(\$source_text);
    confess "Error: failed to parse .isf source '$source_label' with Lispish\n"
        unless defined $raw && ref($raw) eq 'ARRAY';
    fsm_debug("Lispish produced " . scalar(@$raw) . " top-level form(s)", 3);

    # Stage 2: normalize through the Lispish adapter
    my $actor_ast = $self->{adapter}->find_form_by_head($raw, 'actor');
    confess "Error: no (actor ...) root found in '$source_label'\n"
        unless $actor_ast;

    # Stage 3: validate and build typed AST
    fsm_debug("Building typed actor AST", 3);
    my $result = $self->_build_actor($actor_ast, $source_label);
    fsm_debug("Actor '" . $result->{actor_name} . "' parsed: "
        . scalar(@{$result->{transactions}}) . " tx, "
        . scalar(@{$result->{rules}}) . " rules, "
        . scalar(@{$result->{interface}{inputs}}) . " inputs, "
        . scalar(@{$result->{interface}{outputs}}) . " outputs", 2);
    fsm_trace_exit("Parser parse_source completed for $source_label", 2);
    return $result;
}

# Build the typed actor hash from the normalized actor AST.
# The LispishAdapter has already produced canonical [actor, name, body...] form.
sub _build_actor($self, $actor_ast, $source_label) {
    fsm_trace_enter('Parser _build_actor', 3);
    my ($actor_head, $actor_name, @body) = @$actor_ast;

    fsm_debug("Building actor '$actor_name' with " . scalar(@body) . " body clause(s)", 3);

    confess "Error: (actor ...) requires a name\n"
        unless defined $actor_name && !ref($actor_name);

    my $result = {
        actor_name   => $actor_name,
        clock        => undef,
        reset        => undef,
        watchdog     => undef,
        interface    => { inputs => [], outputs => [] },
        handshakes   => {},
        transactions => [],
        rules        => [],
        resources    => [],
        priorities   => [],
        drives       => {},
        phases       => [],
        stages       => [],
    };

    for my $clause (@body) {
        confess "Error: expected list, got " . (ref($clause) || 'scalar') . " in actor body\n"
            unless ref($clause) eq 'ARRAY';

        my $keyword = $clause->[0];
        given ($keyword) {
            when ('clock')     { $result->{clock}    = $self->_parse_clock($clause); }
            when ('reset')     { $result->{reset}    = $self->_parse_reset($clause); }
            when ('watchdog')  { $result->{watchdog} = $self->_parse_watchdog($clause); }
            when ('interface') { $result->{interface} = $self->_parse_interface($clause); }
            when ('handshake') { }  # deprecated, kept for backward compat
            when ('transaction') { push @{$result->{transactions}}, $self->_parse_transaction($clause); }
            when ('rule')      { push @{$result->{rules}}, $self->_parse_rule($clause); }
            when ('resources') { $result->{resources} = $self->_parse_resources($clause); }
            when ('priority')  { push @{$result->{priorities}}, $self->_parse_priority($clause); }
            when ('drive')     { $self->_parse_drive_def($clause, $result->{drives}); }
            when ('phase')     { push @{$result->{phases}},     $self->_parse_phase($clause); }
            when ('stage')     { push @{$result->{stages}},     $self->_parse_stage($clause); }
            default {
                confess "Error: unknown actor clause '$keyword' in actor '$actor_name'\n";
            }
        }
    }

    fsm_trace_exit('Parser _build_actor completed', 3);
    return $result;
}

# --- Individual clause parsers ---

sub _parse_clock($self, $clause) {
    confess "Error: (clock ...) requires exactly one name\n" unless @$clause == 2;
    return $clause->[1];
}

sub _parse_reset($self, $clause) {
    my $spec = $clause->[1];
    # Flat form: (reset rst_n)
    if (!ref($spec)) {
        my $polarity = $spec =~ /_[nb]$/ ? 'active_low' : 'active_high';
        return { name => $spec, kind => 'sync', polarity => $polarity };
    }
    # List form: (reset (rst_n async active_low))
    confess "Error: (reset ...) requires a name\n" unless ref($spec) eq 'ARRAY';
    my $name = $spec->[0];
    my $kind = 'sync';
    my $polarity = $name =~ /_[nb]$/ ? 'active_low' : 'active_high';

    for my $i (1 .. $#$spec) {
        my $val = $spec->[$i];
        next unless defined $val;
        if ($val eq 'async')      { $kind = 'async'; }
        elsif ($val eq 'active_low')  { $polarity = 'active_low'; }
        elsif ($val eq 'active_high') { $polarity = 'active_high'; }
    }

    return { name => $name, kind => $kind, polarity => $polarity };
}

sub _parse_watchdog($self, $clause) {
    confess "Error: (watchdog ...) requires a positive integer\n" unless @$clause == 2;
    return $clause->[1];
}

sub _parse_interface($self, $clause) {
    my @inputs;
    my @outputs;

    for my $i (1 .. $#$clause) {
        my $port = $clause->[$i];
        confess "Error: interface port must be a list\n" unless ref($port) eq 'ARRAY';
        my $dir = $port->[0];
        my $name = $port->[1];
        my $width = 1;

        # Check for (width N) in remaining elements
        for my $j (2 .. $#$port) {
            my $prop = $port->[$j];
            if (ref($prop) eq 'ARRAY' && $prop->[0] eq 'width') {
                $width = $prop->[1];
            }
        }

        my $entry = { name => $name, width => $width };
        if ($dir eq 'input')  { push @inputs,  $entry; }
        if ($dir eq 'output') { push @outputs, $entry; }
    }

    return { inputs => \@inputs, outputs => \@outputs };
}

sub _parse_handshake($self, $clause, $handshakes) {
    confess "Error: (handshake ...) requires a name\n" unless @$clause >= 2;
    my $name = $clause->[1];
    my $valid;

    for my $i (2 .. $#$clause) {
        my $pair = $clause->[$i];
        confess "Error: handshake '$name' property must be a list\n"
            unless ref($pair) eq 'ARRAY';
        my $key = $pair->[0];
        if ($key eq 'valid') { $valid = $pair->[1]; }
    }

    $handshakes->{$name} = { valid => $valid };
}

sub _parse_transaction($self, $clause) {
    confess "Error: (transaction ...) requires a name\n" unless @$clause >= 2;
    my $name = $clause->[1];
    my @clauses;

    for my $i (2 .. $#$clause) {
        push @clauses, $clause->[$i];
    }

    return { name => $name, clauses => \@clauses };
}

sub _parse_rule($self, $clause) {
    confess "Error: (rule ...) requires a name\n" unless @$clause >= 2;
    my $name = $clause->[1];
    my @body;
    my $when;
    my @actions;

    for my $i (2 .. $#$clause) {
        my $elem = $clause->[$i];
        if (ref($elem) eq 'ARRAY' && $elem->[0] eq 'when') {
            $when = $elem;
        } else {
            push @actions, $elem;
        }
    }

    return { name => $name, when => $when, actions => \@actions };
}

sub _parse_resources($self, $clause) {
    my @resources;
    for my $i (1 .. $#$clause) {
        my $res = $clause->[$i];
        confess "Error: resource must be a list\n" unless ref($res) eq 'ARRAY';
        my ($kw, $name, $arbiter_form) = @$res;
        my $arbiter_type;
        if (ref($arbiter_form) eq 'ARRAY' && $arbiter_form->[0] eq 'arbiter') {
            $arbiter_type = $arbiter_form->[1];
        }
        push @resources, { name => $name, arbiter => $arbiter_type };
    }
    return \@resources;
}

sub _parse_priority($self, $clause) {
    return [ @{$clause}[1 .. $#$clause] ];
}

sub _parse_drive_def($self, $clause, $drives) {
    confess "Error: (drive ...) requires a name\n" unless @$clause >= 2;
    my $name = $clause->[1];
    my @body = @{$clause}[2 .. $#$clause];
    $drives->{$name} = \@body;
}

sub _parse_phase($self, $clause) {
    confess "Error: (phase ...) requires a name\n" unless @$clause >= 2;
    my $name = $clause->[1];
    my @body;
    for my $i (2 .. $#$clause) {
        push @body, $clause->[$i];
    }
    return { name => $name, body => \@body };
}

sub _parse_stage($self, $clause) {
    confess "Error: (stage ...) requires a name\n" unless @$clause >= 2;
    my $name = $clause->[1];
    my @body;
    for my $i (2 .. $#$clause) {
        push @body, $clause->[$i];
    }
    return { name => $name, body => \@body };
}

1;
