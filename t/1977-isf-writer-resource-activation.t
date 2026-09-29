#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Storable qw(dclone);
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::Test::ResourceActivationFixture qw(resource_activation_source resource_activation_cases);
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Scheduler::ISF::WriterResourceActivation;

my $collector = 'FSM::Scheduler::ISF::WriterResourceActivation';
my $scheduler = FSM::Scheduler::ISF->new;
my @users = qw(low middle high);
my %priority_rank = (low => 0, middle => 1, high => 2);
sub build {
    my ($case, $edit) = @_;
    my $source = resource_activation_source($case);
    $edit->(\$source) if $edit;
    my $actor = FSM::Adapter::ISF->new->parse_source($source, "$case.isf");
    return ($scheduler->{ir}->build_module($actor), $actor);
}
sub rule_dt { my ($ir, $user) = @_; return (grep {($_->{kind} // '') eq 'rule' && $_->{source_owner}{name} eq $user} @{$ir->{dt_blocks}})[0] }

# A small test-only expression interpreter; the grant oracle below chooses
# winners directly from requests and circular order, not from these equations.
sub expression_value {
    my ($text, $values) = @_;
    my @tokens = $text =~ /\(|\)|[^\s()]+/g;
    my $parse;
    $parse = sub {
        my $token = shift @tokens;
        die 'truncated expression' unless defined $token;
        return 0 + $token if $token =~ /\A[0-9]+\z/;
        if ($token ne '(') { die "unknown atom $token" unless exists $values->{$token}; return $values->{$token} }
        my $op = shift @tokens;
        my @args;
        push @args, $parse->() while @tokens && $tokens[0] ne ')';
        die 'missing close' unless @tokens && shift(@tokens) eq ')';
        return !(grep {!$_} @args) if $op eq '&';
        return !!(grep {$_} @args) if $op eq '|';
        return !$args[0] if $op eq '!' && @args == 1;
        return $args[0] == $args[1] if $op eq '==' && @args == 2;
        die "unsupported test expression $op";
    };
    my $result = $parse->();
    die 'trailing expression' if @tokens;
    return $result;
}

subtest 'complete detached collection matches an independent selection oracle' => sub {
    for my $case (resource_activation_cases()) {
        my ($ir, $actor) = build($case);
        my ($ir_before, $actor_before) = (dclone($ir), dclone($actor));
        my $carrier = $scheduler->{fsm_emitter}->emit($ir);
        my $report = $scheduler->{json_emitter}->report_hash($ir);
        my $records = $collector->collect($ir, $actor);
        is_deeply([map {[$_->{resource}, $_->{user}]} @{$records->{grants}}],
            [map {my $r = $_; map {[$r->{name}, $_]} @{$r->{users} || []}} @{$actor->{resources}}],
            "$case complete declared grant coverage");
        my @mismatches;
        for my $bits (0 .. 7) {
            my %values = (a => $bits & 1, b => ($bits >> 1) & 1, c => ($bits >> 2) & 1);
            my %requests = $case =~ /^literals/
                ? (low => 0, middle => 1, high => $values{a} && $values{b})
                : (low => $values{a}, middle => $values{b}, high => $values{a} && $values{c});
            for my $pointer (0 .. 3) {
                $values{isf_rr_shared_turn} = $pointer;
                my %expected = %requests;
                for my $resource (@{$actor->{resources}}) {
                    my @order = @{$resource->{users} || []};
                    next unless @order;
                    my $winner;
                    if ($resource->{arbiter} eq 'priority') {
                        ($winner) = grep {$requests{$_}}
                            sort {$priority_rank{$b} <=> $priority_rank{$a}} @order;
                    } elsif ($pointer < @order) {
                        ($winner) = grep {$requests{$_}} map {$order[($pointer + $_) % @order]} 0 .. $#order;
                    }
                    $expected{$_} &&= defined($winner) && $winner eq $_ for @order;
                }
                for my $user (@users) {
                    my $guard = $records->{final_guards}{$user};
                    my $actual = expression_value($guard->{port} // $guard->{expr}, \%values);
                    push @mismatches, "$case bits=$bits pointer=$pointer user=$user"
                        if !!$actual != !!$expected{$user};
                }
            }
        }
        is_deeply(\@mismatches, [], "$case guards agree with independent winner selection for every fixture input/pointer value");
        is_deeply($ir, $ir_before, 'collection leaves complete executable and private IR unchanged');
        is_deeply($actor, $actor_before, 'collection leaves authored source unchanged');
        is($scheduler->{fsm_emitter}->emit($ir), $carrier, 'complete emitted carrier unchanged');
        is_deeply($scheduler->{json_emitter}->report_hash($ir), $report, 'complete public schedule unchanged');
        $records->{requests}{high}{guard}{expr} = 'changed';
        $records->{final_guards}{low}{port} = 'changed';
        $records->{source_owners}{middle}{source_name} = 'changed';
        $records->{grants}[0]{activation}{after_guard}{port} = 'changed' if @{$records->{grants}};
        is_deeply($ir, $ir_before, 'returned nested evidence is deeply detached');
    }
};

subtest 'missing or consistently falsified evidence fails closed' => sub {
    my ($incomplete_ir, $incomplete_actor) = build('priority');
    $incomplete_ir->{resource_arbitration}{grants}[0]{higher} = ['middle'];
    rule_dt($incomplete_ir, 'low')->{resource_grants}[0]{higher} = ['middle'];
    my $catalog = FSM::Scheduler::ISF::WriterResourceGrants->collect($incomplete_ir, $incomplete_actor);
    is_deeply($catalog->[0]{higher}, ['middle'], 'structural catalog alone accepts matching but incomplete priority copies');
    eval {$collector->collect($incomplete_ir, $incomplete_actor)};
    like($@, qr/incomplete priority suppressors/, 'authored priority graph independently exposes the omission');
    my @controls = (
        ['priority', 'missing evidence', sub {delete $_[0]{resource_activation}}],
        ['priority', 'extra evidence field', sub {$_[0]{resource_activation}{future} = 1}],
        ['priority', 'missing request', sub {delete $_[0]{resource_activation}{requests}{high}}],
        ['priority', 'extra request', sub {$_[0]{resource_activation}{requests}{invented} = {}}],
        ['priority', 'changed request', sub {$_[0]{resource_activation}{requests}{high}{condition} = '1'}],
        ['priority', 'changed source request', sub {$_[1]{rules}[2]{when} = ['when', '0']}],
        ['priority', 'changed request owner', sub {$_[0]{resource_activation}{requests}{high}{source_owner}{kind} = 'transaction'}],
        ['priority', 'missing step', sub {pop @{$_[0]{resource_activation}{steps}}}],
        ['priority', 'duplicate step', sub {push @{$_[0]{resource_activation}{steps}}, dclone($_[0]{resource_activation}{steps}[0])}],
        ['priority', 'step order', sub {$_[0]{resource_activation}{steps} = [reverse @{$_[0]{resource_activation}{steps}}]}],
        ['priority', 'grant order', sub {$_[0]{resource_arbitration}{grants} = [reverse @{$_[0]{resource_arbitration}{grants}}]}],
        ['priority', 'changed before guard', sub {$_[0]{resource_activation}{steps}[0]{before_guard} = {port => '1'}}],
        ['priority', 'changed after guard', sub {$_[0]{resource_activation}{steps}[0]{after_guard} = {port => '1'}}],
        ['priority', 'changed final header', sub {rule_dt($_[0], 'low')->{dte_guard} = {port => '1'}}],
        ['priority', 'missing transitive priority', sub {pop @{$_[1]{priorities}}}],
        ['priority', 'priority cycle', sub {push @{$_[1]{priorities}}, ['low', 'over', 'high']}],
        ['priority', 'wrong original suppressor', sub {$_[0]{resource_activation}{steps}[0]{suppressors}[0]{condition} = '1'}],
        ['priority', 'both grant copies lose higher user', sub {
            $_[0]{resource_arbitration}{grants}[0]{higher} = ['middle'];
            rule_dt($_[0], 'low')->{resource_grants}[0]{higher} = ['middle'];
        }],
        ['unbound', 'unbound rule and request omitted together', sub {
            $_[0]{dt_blocks} = [grep {($_->{source_owner}{name} // '') ne 'high'} @{$_[0]{dt_blocks}}];
            delete $_[0]{resource_activation}{requests}{high};
        }],
        ['mixed', 'second resource uses transformed request', sub {$_[0]{resource_activation}{steps}[4]{suppressors}[0]{condition} = '0'}],
        ['round_robin', 'wrong permission', sub {$_[0]{resource_activation}{steps}[0]{round_robin}{permission} = '1'}],
        ['round_robin', 'missing pointer declaration', sub {delete $_[0]{resource_activation}{steps}[0]{round_robin}{pointer_declaration}}],
        ['round_robin', 'wrong pointer width', sub {$_[0]{resource_activation}{steps}[0]{round_robin}{pointer_declaration}{width} = 3}],
        ['round_robin', 'missing actual counter', sub {delete $_[0]{counters}{isf_rr_shared_turn}}],
        ['round_robin', 'wrong actual counter role', sub {$_[0]{storage_roles}{isf_rr_shared_turn} = 'other'}],
        ['round_robin', 'wrong next pointer', sub {$_[0]{resource_activation}{steps}[0]{round_robin}{next_pointer} = 0}],
        ['round_robin', 'wrong user index', sub {$_[0]{resource_activation}{steps}[0]{round_robin}{user_index} = 2}],
        ['round_robin', 'wrong update index', sub {$_[0]{resource_activation}{steps}[0]{round_robin}{assignment_index} = 0}],
        ['round_robin', 'wrong actual update', sub {rule_dt($_[0], 'low')->{assignments}[1]{rhs} = 0}],
        ['round_robin', 'changed permission and headers together', sub {
            my $step = $_[0]{resource_activation}{steps}[0];
            $step->{round_robin}{permission} = '1';
            $step->{after_guard} = {port => 'a'};
            rule_dt($_[0], 'low')->{dte_guard} = {port => 'a'};
        }],
    );
    for my $control (@controls) {
        my ($ir, $actor) = build($control->[0]);
        $control->[2]->($ir, $actor);
        eval {$collector->collect($ir, $actor)};
        like($@, qr/(?:Writer resource (?:activation|grants)|Source writer ownership)/, "$control->[1] refused");
    }
};

subtest 'source ordering, consistent renaming and rule-local priorities retain identity' => sub {
    my ($ir, $actor) = build('priority');
    my $expected = $collector->collect($ir, $actor);
    $actor->{rules} = [reverse @{$actor->{rules}}];
    $ir->{dt_blocks} = [reverse @{$ir->{dt_blocks}}];
    is_deeply($collector->collect($ir, $actor), $expected, 'declaration/container reordering preserves records');
    rule_dt($ir, 'low')->{name} = 'renamed_container';
    $ir->{resource_activation}{requests}{low}{container_name} = 'renamed_container';
    $_->{container_name} = 'renamed_container' for grep {$_->{user} eq 'low'} @{$ir->{resource_activation}{steps}};
    is($collector->collect($ir, $actor)->{grants}[0]{source_owner}{container_name}, 'renamed_container',
        'typed source identity survives consistently renamed actual containers');
    my ($local_ir, $local_actor) = build('priority', sub {
        ${$_[0]} =~ s/\(priority high over middle\) \(priority middle over low\)//;
        ${$_[0]} =~ s/\(set high_value 7\)/\(set high_value 7\) (priority over middle)/;
        ${$_[0]} =~ s/\(set middle_value 5\)/\(set middle_value 5\) (priority over low)/;
    });
    is_deeply($collector->collect($local_ir, $local_actor), $expected, 'rule-local priorities retain transitive grant semantics');
};

subtest 'unbound requests, pointer cardinalities and actual selected names remain supported' => sub {
    my ($ir, $actor) = build('priority', sub {${$_[0]} =~ s/\(when b\)//});
    is($collector->collect($ir, $actor)->{requests}{middle}{condition}, '1', 'implicit unconditional request validated');
    for my $count (1, 2, 3) {
        my ($small_ir, $small_actor) = build('round_robin', sub {
            my $selected = join(' ', @users[0 .. $count - 1]);
            ${$_[0]} =~ s/\(users low middle high\)/(users $selected)/;
        });
        my $records = $collector->collect($small_ir, $small_actor);
        is(scalar(@{$records->{grants}}), $count, 'single/pair/non-power-of-two user sets validate');
        is($records->{grants}[-1]{activation}{round_robin}{next_pointer}, 0, 'last user wraps to zero');
    }
    my ($split_ir, $split_actor) = build('round_robin', sub {
        ${$_[0]} =~ s/\(users low middle high\)\)/(users low middle)) (resource extra (kind rule_slot) (arbiter round_robin) (users high))/;
    });
    my $split = $collector->collect($split_ir, $split_actor);
    is_deeply([map {$_->{activation}{round_robin}{pointer_declaration}{name}} @{$split->{grants}}],
        [qw(isf_rr_shared_turn isf_rr_shared_turn isf_rr_extra_turn)], 'disjoint resources retain their independent actual pointers');

    no warnings 'redefine';
    local *FSM::Scheduler::ISF::LoweringIR::_round_robin_pointer_declaration = sub {
        return {name => 'selected_turn_counter', width => 2, storage_role => 'resource_round_robin_pointer'};
    };
    my ($selected_ir, $selected_actor) = build('round_robin');
    is($collector->collect($selected_ir, $selected_actor)->{grants}[0]{activation}{round_robin}{pointer_declaration}{name},
        'selected_turn_counter', 'validation consumes selected identity without reconstructing a generated name');
};

done_testing();
