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
    my $source_text = read_file($isf_path);
    return $self->parse_source($source_text, $isf_path);
}

sub parse_source($self, $source_text, $source_label) {
    # Stage 1: raw Lispish parse
    my $raw = Lispish::multi(\$source_text);
    confess "Error: failed to parse .isf source '$source_label' with Lispish\n"
        unless defined $raw && ref($raw) eq 'ARRAY';

    # Stage 2: normalize through the Lispish adapter
    my $actor_ast = $self->{adapter}->find_form_by_head($raw, 'actor');
    confess "Error: no (actor ...) root found in '$source_label'\n"
        unless $actor_ast;

    # Stage 3: validate and build typed AST
    return $self->_build_actor($actor_ast, $source_label);
}

# Build the typed actor hash from the normalized actor AST.
# The LispishAdapter has already produced canonical [actor, name, body...] form.
sub _build_actor($self, $actor_ast, $source_label) {
    my ($actor_head, $actor_name, @body) = @$actor_ast;

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
            when ('handshake') { $self->_parse_handshake($clause, $result->{handshakes}); }
            when ('transaction') { push @{$result->{transactions}}, $self->_parse_transaction($clause); }
            when ('rule')      { push @{$result->{rules}}, $self->_parse_rule($clause); }
            when ('resources') { $result->{resources} = $self->_parse_resources($clause); }
            when ('priority')  { push @{$result->{priorities}}, $self->_parse_priority($clause); }
            default {
                confess "Error: unknown actor clause '$keyword' in actor '$actor_name'\n";
            }
        }
    }

    return $result;
}

# --- Individual clause parsers ---

sub _parse_clock($self, $clause) {
    confess "Error: (clock ...) requires exactly one name\n" unless @$clause == 2;
    return $clause->[1];
}

sub _parse_reset($self, $clause) {
    my $name = $clause->[1];
    my $kind = 'sync';
    my $polarity = 'active_high';

    for my $i (2 .. $#$clause) {
        my $opt = $clause->[$i];
        if (ref($opt) eq 'ARRAY') {
            my $val = $opt->[0];
            if ($val eq 'async')      { $kind = 'async'; }
            elsif ($val eq 'active_low') { $polarity = 'active_low'; }
            elsif ($val eq 'active_high') { $polarity = 'active_high'; }
        }
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
    my $ready;

    for my $i (2 .. $#$clause) {
        my $pair = $clause->[$i];
        confess "Error: handshake '$name' property must be a list\n"
            unless ref($pair) eq 'ARRAY';
        my $key = $pair->[0];
        if ($key eq 'valid') { $valid = $pair->[1]; }
        if ($key eq 'ready') { $ready = $pair->[1]; }
    }

    $handshakes->{$name} = { valid => $valid, ready => $ready };
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

1;
