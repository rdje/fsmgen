package FSM::Scheduler::ISF::RuleLowering;

use v5.20;
use strict;
use warnings;
use feature qw(signatures postderef);
no warnings 'experimental::signatures';
use FSM::Debug;

# Lowers ISF rules into .fsm combinational DT blocks.
#
# (rule name (when condition) actions...)
#   -> (-name ...) standalone DT block with condition-guarded assignments

sub new($class, %args) {
    return bless { debug => ($args{debug} // 0) }, $class;
}

sub lower_rules($self, $actor) {
    my @rules = @{$actor->{rules} || []};
    return [] unless @rules;

    fsm_trace_enter('RuleLowering', 3);
    my @dt_blocks;

    for my $rule (@rules) {
        my $name   = $rule->{name};
        my $when   = $rule->{when};
        my $actions = $rule->{actions};

        my $cond = $self->_extract_condition($when);
        my @lines;
        push @lines, "  (-$name";

        for my $action (@$actions) {
            next unless ref($action) eq 'ARRAY';
            my $ak = $action->[0];

            if ($ak eq 'assign') {
                my ($kw, $port, $value) = @$action;
                if ($value == 1 && $cond ne '1') {
                    # (assign port 1) with signal condition -> (port = condition_signal)
                    push @lines, "    ($port = $cond)";
                } else {
                    push @lines, "    ($port = $value <$cond)";
                }
            }
            elsif ($ak eq 'assert') {
                my ($kw, $port) = @$action;
                push @lines, "    ($port = 1 <$cond)";
            }
            elsif ($ak eq 'trigger') {
                my ($kw, $tx_name) = @$action;
                push @lines, "    (= (${tx_name}_start 1) <$cond)";
            }
            elsif ($ak eq 'pulse') {
                my ($kw, $port) = @$action;
                # Level-sensitive: port stays high while condition holds.
                # True single-cycle pulse needs edge-triggered sequential logic (deferred).
                push @lines, "    (= ($port 1) <$cond)";
            }
            elsif ($ak eq 'priority') {
                push @lines, "    ;; priority — lowering deferred";
            }
            elsif ($ak eq 'trigger') {
                my ($kw, $tx_name) = @$action;
                push @lines, "    ;; trigger $tx_name — lowering deferred";
            }
            elsif ($ak eq 'priority') {
                push @lines, "    ;; priority — lowering deferred";
            }
        }
        push @lines, '  )';
        push @lines, '';

        push @dt_blocks, join("\n", @lines);
    }

    fsm_trace_exit('RuleLowering', 3);
    return \@dt_blocks;
}

sub _extract_condition($self, $when) {
    return '1' unless $when && ref($when) eq 'ARRAY';
    my @parts = @{$when}[1 .. $#$when];
    return join('_', map { ref($_) ? join('_', @$_) : $_ } @parts);
}

1;
