package FSM::Adapter::ISF::Parser;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use feature qw(signatures postderef);
no warnings qw(experimental::signatures experimental::smartmatch);

use Lispish;
use File::Slurp qw(read_file);
use FSM::Adapter::ISF::LispishAdapter;
use FSM::Debug;

my %RESOURCE_ARBITERS = map { $_ => 1 } qw(priority round_robin);
my %RESOURCE_KINDS = map { $_ => 1 } qw(
    rule_slot output_bundle interface_bundle named_drive
    transaction_start child_instance storage_port
);
my %RULE_ASSIGNMENT_FORBIDDEN_EXPR_HEADS = map { $_ => 1 } qw(
    when switch repeat do spawn complete
);

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
#     resources     => [ { name => ..., arbiter => ..., kind => ..., users => [...] }, ... ],
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

    confess "Error: (actor ...) requires a scalar name\n"
        unless defined($actor_name) && !ref($actor_name) && length($actor_name);

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
    my %actor_phase_names;
    my %actor_stage_names;
    my %singleton_actor_clauses;
    my %transaction_names;
    my %rule_names;

    for my $clause (@body) {
        confess "Error: expected list, got " . (ref($clause) || 'scalar') . " in actor body\n"
            unless ref($clause) eq 'ARRAY';

        my $keyword = $clause->[0];
        given ($keyword) {
            when ('clock')     {
                $self->_claim_singleton_actor_clause($actor_name, 'clock', \%singleton_actor_clauses);
                $result->{clock} = $self->_parse_clock($clause);
            }
            when ('reset')     {
                $self->_claim_singleton_actor_clause($actor_name, 'reset', \%singleton_actor_clauses);
                $result->{reset} = $self->_parse_reset($clause);
            }
            when ('watchdog')  {
                $self->_claim_singleton_actor_clause($actor_name, 'watchdog', \%singleton_actor_clauses);
                $result->{watchdog} = $self->_parse_watchdog($clause);
            }
            when ('interface') {
                $self->_claim_singleton_actor_clause($actor_name, 'interface', \%singleton_actor_clauses);
                $result->{interface} = $self->_parse_interface($clause);
            }
            when ('handshake') { $self->_parse_handshake($clause); }  # deprecated, validated then ignored
            when ('transaction') {
                my $transaction = $self->_parse_transaction($clause);
                confess "Error: duplicate transaction '$transaction->{name}' in actor '$actor_name'\n"
                    if $transaction_names{$transaction->{name}}++;
                push @{$result->{transactions}}, $transaction;
            }
            when ('rule')      {
                my $rule = $self->_parse_rule($clause);
                confess "Error: duplicate rule '$rule->{name}' in actor '$actor_name'\n"
                    if $rule_names{$rule->{name}}++;
                push @{$result->{rules}}, $rule;
            }
            when ('resources') {
                $self->_claim_singleton_actor_clause($actor_name, 'resources', \%singleton_actor_clauses);
                $result->{resources} = $self->_parse_resources($clause);
            }
            when ('priority')  { push @{$result->{priorities}}, $self->_parse_priority($clause); }
            when ('drive')     { $self->_parse_drive_def($clause, $result->{drives}); }
            when ('phase')     {
                my $phase = $self->_parse_phase($clause);
                confess "Error: duplicate actor phase '$phase->{name}'\n"
                    if $actor_phase_names{$phase->{name}}++;
                push @{$result->{phases}}, $phase;
            }
            when ('stage')     {
                my $stage = $self->_parse_stage($clause);
                confess "Error: duplicate actor stage '$stage->{name}'\n"
                    if $actor_stage_names{$stage->{name}}++;
                push @{$result->{stages}}, $stage;
            }
            default {
                confess "Error: unknown actor clause '$keyword' in actor '$actor_name'\n";
            }
        }
    }

    $self->_validate_rule_trigger_targets($result);
    $self->_validate_rule_priority_targets($result);
    $self->_validate_actor_priority_targets($result);
    $self->_validate_resource_user_targets($result);

    fsm_trace_exit('Parser _build_actor completed', 3);
    return $result;
}

# --- Individual clause parsers ---

sub _claim_singleton_actor_clause($self, $actor_name, $keyword, $seen) {
    confess "Error: duplicate actor clause '$keyword' in actor '$actor_name'\n"
        if $seen->{$keyword}++;

    return 1;
}

sub _parse_clock($self, $clause) {
    confess "Error: (clock ...) requires exactly one name\n" unless @$clause == 2;
    confess "Error: (clock ...) requires a scalar name\n"
        unless defined($clause->[1]) && !ref($clause->[1]) && length($clause->[1]);
    return $clause->[1];
}

sub _parse_reset($self, $clause) {
    my $spec = $clause->[1];
    # Flat form: (reset rst_n)
    if (!ref($spec)) {
        confess "Error: (reset ...) requires a scalar name\n"
            unless defined($spec) && length($spec);
        my $polarity = $spec =~ /_[nb]$/ ? 'active_low' : 'active_high';
        return { name => $spec, kind => 'sync', polarity => $polarity };
    }
    # List form: (reset (rst_n async active_low))
    confess "Error: (reset ...) requires a name\n" unless ref($spec) eq 'ARRAY';
    my $name = $spec->[0];
    confess "Error: (reset ...) requires a scalar name\n"
        unless defined($name) && !ref($name) && length($name);
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
    confess "Error: (watchdog ...) requires a positive integer\n"
        unless defined($clause->[1]) && !ref($clause->[1]) && $clause->[1] =~ /\A[1-9][0-9]*\z/;
    return $clause->[1];
}

sub _parse_interface($self, $clause) {
    my @inputs;
    my @outputs;
    my %seen_names;

    for my $i (1 .. $#$clause) {
        my $port = $clause->[$i];
        confess "Error: interface port must be a list\n" unless ref($port) eq 'ARRAY';
        my $dir = $port->[0];
        my $name = $port->[1];
        my $width = 1;

        confess "Error: interface port direction must be input or output\n"
            unless defined($dir) && !ref($dir) && ($dir eq 'input' || $dir eq 'output');
        confess "Error: interface port requires a scalar name\n"
            unless defined($name) && !ref($name) && length($name);
        confess "Error: duplicate interface port '$name'\n" if $seen_names{$name}++;

        # Check for (width N) in remaining elements
        for my $j (2 .. $#$port) {
            my $prop = $port->[$j];
            if (ref($prop) eq 'ARRAY' && $prop->[0] eq 'width') {
                confess "Error: interface port '$name' width must be a positive integer\n"
                    unless @$prop == 2
                        && defined($prop->[1])
                        && !ref($prop->[1])
                        && $prop->[1] =~ /\A[1-9][0-9]*\z/;
                $width = $prop->[1];
            }
        }

        my $entry = { name => $name, width => $width };
        if ($dir eq 'input')  { push @inputs,  $entry; }
        if ($dir eq 'output') { push @outputs, $entry; }
    }

    return { inputs => \@inputs, outputs => \@outputs };
}

sub _parse_handshake($self, $clause) {
    confess "Error: (handshake ...) requires '(handshake name (valid signal) (ready signal))'\n"
        unless @$clause >= 3;
    my $name = $clause->[1];
    confess "Error: (handshake ...) requires a scalar name\n"
        unless defined($name) && !ref($name) && length($name);

    my %seen;
    for my $i (2 .. $#$clause) {
        my $pair = $clause->[$i];
        confess "Error: handshake '$name' properties must be '(valid signal)' or '(ready signal)'\n"
            unless ref($pair) eq 'ARRAY'
                && @$pair == 2
                && defined($pair->[0])
                && !ref($pair->[0])
                && ($pair->[0] eq 'valid' || $pair->[0] eq 'ready')
                && defined($pair->[1])
                && !ref($pair->[1])
                && length($pair->[1]);

        my $key = $pair->[0];
        confess "Error: duplicate handshake '$name' property '$key'\n" if $seen{$key}++;
    }

    return 1;
}

sub _parse_transaction($self, $clause) {
    confess "Error: (transaction ...) requires a name\n" unless @$clause >= 2;
    my $name = $clause->[1];
    confess "Error: (transaction ...) requires a scalar name\n"
        unless defined($name) && !ref($name) && length($name);
    my @clauses;

    for my $i (2 .. $#$clause) {
        push @clauses, $clause->[$i];
    }
    $self->_validate_transaction_phase_stage_clauses(\@clauses);

    return { name => $name, clauses => \@clauses };
}

sub _parse_rule($self, $clause) {
    confess "Error: (rule ...) requires a name\n" unless @$clause >= 2;
    my $name = $clause->[1];
    confess "Error: (rule ...) requires a scalar name\n"
        unless defined($name) && !ref($name) && length($name);
    my $when;
    my @actions;
    my @body = @{$clause}[2 .. $#$clause];

    if (@body && defined($body[0]) && !ref($body[0])) {
        $when = $self->_parse_rule_when(['when', shift @body], $name);
    }

    for my $elem (@body) {
        if (ref($elem) eq 'ARRAY' && defined($elem->[0]) && !ref($elem->[0]) && $elem->[0] eq 'when') {
            confess "Error: rule '$name' accepts only one guard condition\n"
                if defined $when;
            $when = $self->_parse_rule_when($elem, $name);
        } else {
            $self->_parse_rule_action($elem, $name);
            push @actions, $elem;
        }
    }

    return { name => $name, when => $when, actions => \@actions };
}

sub _parse_rule_when($self, $clause, $rule_name) {
    confess "Error: rule '$rule_name' guard requires exactly one scalar condition\n"
        unless ref($clause) eq 'ARRAY'
            && @$clause == 2
            && defined($clause->[1])
            && !ref($clause->[1])
            && length($clause->[1]);

    return ['when', $clause->[1]];
}

sub _parse_rule_priority($self, $clause, $rule_name) {
    confess "Error: rule '$rule_name' priority requires '(priority over other_rule)'\n"
        unless ref($clause) eq 'ARRAY'
            && @$clause == 3
            && defined($clause->[1])
            && !ref($clause->[1])
            && $clause->[1] eq 'over'
            && defined($clause->[2])
            && !ref($clause->[2])
            && length($clause->[2]);

    return 1;
}

sub _parse_rule_action($self, $action, $rule_name) {
    confess "Error: rule '$rule_name' actions must be list forms\n"
        unless ref($action) eq 'ARRAY' && @$action;

    my $keyword = $action->[0];
    confess "Error: rule '$rule_name' action heads must be scalar\n"
        unless defined($keyword) && !ref($keyword) && length($keyword);

    if ($keyword eq 'trigger') {
        confess "Error: rule '$rule_name' trigger requires '(trigger transaction)'\n"
            unless @$action == 2
                && defined($action->[1])
                && !ref($action->[1])
                && length($action->[1]);
        return 1;
    }
    if ($keyword eq 'priority') {
        return $self->_parse_rule_priority($action, $rule_name);
    }

    confess "Error: rule '$rule_name' assignment actions require '(port expr)'\n"
        unless @$action == 2
            && defined($action->[1]);

    $self->_validate_rule_assignment_expr($action->[1], $rule_name);

    return 1;
}

sub _validate_rule_assignment_expr($self, $expr, $rule_name) {
    return 1 unless ref($expr);

    confess "Error: rule '$rule_name' assignment RHS expression must be a non-empty list\n"
        unless ref($expr) eq 'ARRAY' && @$expr;

    my $head = $expr->[0];
    confess "Error: rule '$rule_name' assignment expression heads must be scalar\n"
        unless defined($head) && !ref($head) && length($head);

    confess "Error: rule '$rule_name' assignment RHS cannot use control-flow form '$head'\n"
        if $RULE_ASSIGNMENT_FORBIDDEN_EXPR_HEADS{$head};

    for my $operand (@{$expr}[1 .. $#$expr]) {
        $self->_validate_rule_assignment_expr($operand, $rule_name)
            if ref($operand);
    }

    return 1;
}

sub _validate_rule_trigger_targets($self, $actor) {
    my $actor_name = $actor->{actor_name};
    my %transaction_names = map { $_->{name} => 1 } @{$actor->{transactions} || []};

    for my $rule (@{$actor->{rules} || []}) {
        my $rule_name = $rule->{name};
        for my $action (@{$rule->{actions} || []}) {
            next unless ref($action) eq 'ARRAY' && @$action;
            next unless defined($action->[0]) && !ref($action->[0]) && $action->[0] eq 'trigger';

            my $target = $action->[1];
            confess "Error: rule '$rule_name' triggers unknown transaction '$target' in actor '$actor_name'\n"
                unless defined($target)
                    && !ref($target)
                    && $transaction_names{$target};
        }
    }

    return 1;
}

sub _validate_rule_priority_targets($self, $actor) {
    my $actor_name = $actor->{actor_name};
    my %rule_names = map { $_->{name} => 1 } @{$actor->{rules} || []};

    for my $rule (@{$actor->{rules} || []}) {
        my $rule_name = $rule->{name};
        for my $action (@{$rule->{actions} || []}) {
            next unless ref($action) eq 'ARRAY' && @$action;
            next unless defined($action->[0]) && !ref($action->[0]) && $action->[0] eq 'priority';

            my $target = $action->[2];
            confess "Error: rule '$rule_name' priority targets unknown rule '$target' in actor '$actor_name'\n"
                unless defined($target)
                    && !ref($target)
                    && $rule_names{$target};
        }
    }

    return 1;
}

sub _validate_actor_priority_targets($self, $actor) {
    my $actor_name = $actor->{actor_name};
    my %names = (
        map({ $_->{name} => 1 } @{$actor->{transactions} || []}),
        map({ $_->{name} => 1 } @{$actor->{rules} || []}),
    );

    for my $priority (@{$actor->{priorities} || []}) {
        for my $target ($priority->[0], $priority->[2]) {
            confess "Error: priority target '$target' is not a declared transaction or rule in actor '$actor_name'\n"
                unless defined($target)
                    && !ref($target)
                    && $names{$target};
        }
    }

    return 1;
}

sub _parse_resources($self, $clause) {
    my @resources;
    my %seen;

    for my $i (1 .. $#$clause) {
        my $res = $clause->[$i];
        confess "Error: resource must be a list\n" unless ref($res) eq 'ARRAY';
        my ($kw, $name, @forms) = @$res;
        confess "Error: resource entries require '(resource name (arbiter priority|round_robin) [(kind kind)] [(users rule...)])'\n"
            unless @$res >= 3
                && defined($kw)
                && !ref($kw)
                && $kw eq 'resource'
                && defined($name)
                && !ref($name)
                && length($name);

        confess "Error: duplicate resource '$name'\n" if $seen{$name}++;

        my %seen_subclause;
        my ($arbiter, $kind);
        my @users;
        my %seen_users;

        for my $form (@forms) {
            confess "Error: resource '$name' subclauses must be list forms\n"
                unless ref($form) eq 'ARRAY' && @$form;
            my $head = $form->[0];
            confess "Error: resource '$name' subclause heads must be scalar\n"
                unless defined($head) && !ref($head) && length($head);
            confess "Error: duplicate resource '$name' subclause '$head'\n"
                if $seen_subclause{$head}++;

            if ($head eq 'arbiter') {
                confess "Error: resource '$name' arbiter requires '(arbiter priority|round_robin)'\n"
                    unless @$form == 2
                        && defined($form->[1])
                        && !ref($form->[1])
                        && $RESOURCE_ARBITERS{$form->[1]};
                $arbiter = $form->[1];
                next;
            }

            if ($head eq 'kind') {
                confess "Error: resource '$name' kind requires '(kind rule_slot|output_bundle|interface_bundle|named_drive|transaction_start|child_instance|storage_port)'\n"
                    unless @$form == 2
                        && defined($form->[1])
                        && !ref($form->[1])
                        && $RESOURCE_KINDS{$form->[1]};
                $kind = $form->[1];
                next;
            }

            if ($head eq 'users') {
                confess "Error: resource '$name' users requires '(users rule...)'\n"
                    unless @$form >= 2;
                for my $u (@{$form}[1 .. $#$form]) {
                    confess "Error: resource '$name' users must be scalar names\n"
                        unless defined($u) && !ref($u) && length($u);
                    confess "Error: duplicate resource '$name' user '$u'\n"
                        if $seen_users{$u}++;
                    push @users, $u;
                }
                next;
            }

            confess "Error: resource '$name' has unsupported subclause '$head'\n";
        }

        confess "Error: resource '$name' requires '(arbiter priority|round_robin)'\n"
            unless defined($arbiter);
        confess "Error: resource '$name' with users requires '(kind rule_slot)'\n"
            if @users && !defined($kind);

        my %resource = (name => $name, arbiter => $arbiter);
        $resource{kind} = $kind if defined($kind);
        $resource{users} = \@users if @users;
        push @resources, \%resource;
    }
    return \@resources;
}

sub _validate_resource_user_targets($self, $actor) {
    my $actor_name = $actor->{actor_name};
    my %rule_names = map { $_->{name} => 1 } @{$actor->{rules} || []};

    for my $resource (@{$actor->{resources} || []}) {
        next unless ($resource->{kind} // '') eq 'rule_slot';
        for my $user (@{$resource->{users} || []}) {
            confess "Error: resource '$resource->{name}' user '$user' is not a declared rule in actor '$actor_name'\n"
                unless defined($user)
                    && !ref($user)
                    && $rule_names{$user};
        }
    }

    return 1;
}

sub _parse_priority($self, $clause) {
    confess "Error: (priority ...) requires '(priority lhs over rhs)'\n"
        unless @$clause == 4
            && defined($clause->[1])
            && !ref($clause->[1])
            && length($clause->[1])
            && defined($clause->[2])
            && !ref($clause->[2])
            && $clause->[2] eq 'over'
            && defined($clause->[3])
            && !ref($clause->[3])
            && length($clause->[3]);

    return [ @{$clause}[1 .. $#$clause] ];
}

sub _parse_drive_def($self, $clause, $drives) {
    confess "Error: (drive ...) requires a name\n" unless @$clause >= 2;
    my $spec = $clause->[1];
    my ($name, @params);
    if (ref($spec) eq 'ARRAY') {
        # Parameterized: (drive (name p1 p2) body...)
        $name = $spec->[0];
        @params = @{$spec}[1 .. $#$spec];
    } else {
        # Simple: (drive name body...)
        $name = $spec;
        @params = ();
    }
    confess "Error: (drive ...) requires a scalar name\n"
        unless defined($name) && !ref($name) && length($name);
    my %seen_params;
    for my $param (@params) {
        confess "Error: drive '$name' parameter names must be scalar\n"
            unless defined($param) && !ref($param) && length($param);
        confess "Error: duplicate drive '$name' parameter '$param'\n"
            if $seen_params{$param}++;
    }
    confess "Error: duplicate drive '$name'\n" if exists $drives->{$name};
    my @body = @{$clause}[2 .. $#$clause];
    for my $entry (@body) {
        confess "Error: drive '$name' body entries must be list forms\n"
            unless ref($entry) eq 'ARRAY' && @$entry;
        confess "Error: drive '$name' body entry heads must be scalar\n"
            unless defined($entry->[0]) && !ref($entry->[0]) && length($entry->[0]);
        confess "Error: drive '$name' body assignments require '(port value)'\n"
            unless @$entry == 2
                && defined($entry->[1])
                && !ref($entry->[1]);
    }
    $drives->{$name} = { body => \@body, params => \@params };
}

sub _parse_phase($self, $clause) {
    return $self->_parse_named_body_clause($clause, 'phase');
}

sub _parse_stage($self, $clause) {
    return $self->_parse_named_body_clause($clause, 'stage');
}

sub _validate_transaction_phase_stage_clauses($self, $clauses) {
    return unless ref($clauses) eq 'ARRAY';

    for my $clause (@$clauses) {
        next unless ref($clause) eq 'ARRAY' && @$clause;
        my $keyword = $clause->[0];
        next unless defined($keyword) && !ref($keyword);

        if ($keyword eq 'phase' || $keyword eq 'stage') {
            $self->_parse_named_body_clause($clause, $keyword);
        }

        if ($keyword eq 'when' || $keyword eq 'repeat') {
            $self->_validate_transaction_phase_stage_clauses([@{$clause}[2 .. $#$clause]]);
        } elsif ($keyword eq 'switch') {
            for my $branch (@{$clause}[2 .. $#$clause]) {
                next unless ref($branch) eq 'ARRAY';
                $self->_validate_transaction_phase_stage_clauses([@{$branch}[1 .. $#$branch]]);
            }
        }
    }
}

sub _parse_named_body_clause($self, $clause, $kind) {
    confess "Error: ($kind ...) requires a name\n" unless @$clause >= 2;
    my $name = $clause->[1];
    confess "Error: ($kind ...) requires a scalar name\n"
        unless defined($name) && !ref($name) && length($name);

    my @body;
    for my $i (2 .. $#$clause) {
        my $entry = $clause->[$i];
        confess "Error: $kind '$name' body entries must be list forms\n"
            unless ref($entry) eq 'ARRAY' && @$entry;
        confess "Error: $kind '$name' body entry heads must be scalar\n"
            unless defined($entry->[0]) && !ref($entry->[0]) && length($entry->[0]);
        push @body, $entry;
    }

    return { name => $name, body => \@body };
}

1;
