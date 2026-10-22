#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Spec;
use Cwd qw(abs_path);
use JSON::PP;
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::Test::SourceQueryRunner;
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Support::SemanticIntrospectionMCPAdapter;

my $work = tempdir(CLEANUP => 1);
my $json = JSON::PP->new->canonical;
if ($ENV{FSMGEN_TEST_LOAD_IDENTITY}) {
    require B;
    require Digest::SHA;
    my %observations;
    for my $item (
        ['FSM/Scheduler/ISF/LoweringIR.pm', \&FSM::Scheduler::ISF::LoweringIR::_build_child_ir],
        ['FSM/Scheduler/ISF/ChildActivation.pm', \&FSM::Scheduler::ISF::ChildActivation::guard_child_activation],
    ) {
        my ($module, $method) = @$item;
        my $path = $INC{$module};
        open my $in, '<:raw', $path or die $!;
        my $data = do {local $/; <$in>}; close $in or die $!;
        $observations{$module} = {path => $path, sha256 => Digest::SHA::sha256_hex($data),
            compiled_file => B::svref_2object($method)->GV->FILE};
    }
    note('loaded_identity=' . $json->encode(\%observations));
}
my @cases = (
    ['injected', '(wait count)', 0, 0],
    ['authored', '(on go) (wait count)', 0, 0],
    ['expression', q{(wait (& count 3'd7))}, 0, 0],
    ['consecutive', '(wait count) (wait tail)', 1, 0],
    ['sample', '(sample count as remembered) (wait count) (wait 1)', 0, 1],
    ['sample_chain', '(sample count as remembered) (wait count) (wait tail) (wait 1)', 1, 1],
);
my $public_file;
for my $case (@cases) {
    my ($name, $body, $chain, $sample) = @$case;
    subtest "$name entry samples exactly one active count or bypasses zero" => sub {
        my $source = source($body, $sample ? 'remembered' : 'count');
        my $file = write_file("$work/$name.isf", $source);
        $public_file = $file if $name eq 'injected';
        my $actor = FSM::Adapter::ISF->new->parse_source($source, "$name.isf");
        my $before = $json->encode($actor);
        my $scheduler = FSM::Scheduler::ISF->new;
        my $module = $scheduler->{ir}->build_module($actor);
        my $child = $module->{children}{child};
        my ($entry) = grep {$_->{kind} eq 'entry'} @{$child->{states}};
        my @waits = grep {$_->{dynamic_wait_entry}} @{$child->{states}};
        is(scalar @waits, $chain ? 2 : 1, 'actual runtime wait membership');
        my @history = grep {$child->{storage_roles}{$_} eq 'child_start_history'}
            keys %{$child->{storage_roles}};
        is(scalar @history, 1, 'one real activation-history identity');
        my $history = $history[0];
        my %states = map {$_->{name} => $_} @{$child->{states}};
        my @loads = grep {($_->{source_kind} // '') eq 'dynamic_wait_counter_load'}
            @{$entry->{assignments}};
        is(scalar @loads, $chain ? 2 : 1, 'entry loads each potentially first positive count once');
        is(scalar @{$entry->{transitions}}, $chain ? 3 : 2, 'entry has disjoint positive and all-zero paths');
        my %widths = map {$_->{name} => $_->{width}} @{$child->{ports}};
        is($widths{count}, 3, 'real count input retained');
        is($widths{tail}, 3, 'explicit sibling formal retained');

        # Evaluate emitted conditions independently for the complete declared
        # count ranges. This tests truth partitions, not serializer spelling.
        my @failures;
        for my $start (0, 1) {
            for my $seen (0, 1) {
                for my $count (0 .. 7) {
                    for my $tail ($chain ? (0 .. 7) : (0)) {
                        my %values = (start => $start, go => !$start, $history => $seen, count => $count, tail => $tail);
                        my @edges = grep {condition($_->{condition}, \%values)} @{$entry->{transitions}};
                        my @active_loads = grep {condition($_->{guard}, \%values)} @loads;
                        my $active = $start && !$seen;
                        if (@edges != ($active ? 1 : 0)) {
                            push @failures, "edge partition start=$start seen=$seen count=$count tail=$tail";
                            next;
                        }
                        if (!$active) {
                            push @failures, 'inactive entry loads a counter' if @active_loads;
                            next;
                        }
                        my $selected = $count ? $waits[0] : $chain && $tail ? $waits[1] : undef;
                        if ($selected) {
                            my $target = $states{$edges[0]{target}};
                            push @failures, 'wrong positive wait target'
                                unless $target && (($target->{carried_sample_entry_clone_of} // $target->{name}) eq $selected->{name});
                            if ($sample && $target) {
                                push @failures, 'positive path loses pending sample'
                                    unless grep {$_->{lhs} eq 'remembered' && ($_->{source_kind} // '') eq 'sample_capture'}
                                        @{$target->{assignments}};
                            }
                            push @failures, 'missing or duplicate sampled load'
                                unless @active_loads == 1 && $active_loads[0]{lhs} eq $selected->{wait_counter};
                            if (@active_loads == 1) {
                                my $wanted = $count ? $count : $tail;
                                push @failures, 'sampled value differs from the chosen source'
                                    unless expression($active_loads[0]{rhs}, \%values) == $wanted;
                            }
                        } else {
                            push @failures, 'zero count loads a counter' if @active_loads;
                            my $target = $states{$edges[0]{target}};
                            my $exit = $waits[-1]{dynamic_wait_exit_target};
                            push @failures, 'zero count does not reach the real post-wait state'
                                unless $target && (($target->{zero_sample_clone_of} // $target->{name}) eq $exit);
                            if ($sample && $target) {
                                push @failures, 'all-zero path loses pending sample'
                                    unless grep {$_->{lhs} eq 'remembered' && ($_->{source_kind} // '') eq 'sample_capture'}
                                        @{$target->{assignments}};
                            }
                        }
                    }
                }
            }
        }
        is_deeply(\@failures, [], 'independent count/activation/sample truth table');
        for my $state (@{$child->{states}}) {
            for my $edge (@{$state->{transitions}}) {
                ok(exists $states{$edge->{target}}, "real target for $state->{name}");
            }
        }
        my $files = $scheduler->lower($actor)->{files};
        like($files->{'child.fsm'}, qr/\Q(<- ($waits[0]{wait_counter}\E /,
            'actual carrier loads the sampled counter');
        is($json->encode($actor), $before, 'complete caller JSON kinds remain unchanged');
    };
}

subtest 'pending sample dependent zero target keeps the canonical refusal' => sub {
    my $text = source('(sample count as remembered) (wait count)', 'remembered');
    my $actor = FSM::Adapter::ISF->new->parse_source($text, 'dependent.isf');
    my $before = $json->encode($actor);
    my $ok = eval {FSM::Scheduler::ISF->new->{ir}->build_module($actor); 1};
    ok(!$ok, 'unsupported dependent zero target refuses before emission');
    like($@, qr/cannot materialize pending samples without changing timing/,
        'the existing canonical sample restriction supplies the cause');
    is($json->encode($actor), $before, 'refusal preserves complete caller JSON kinds');
};

subtest 'ordinary generated static wait retains its activation guard' => sub {
    my $actor = FSM::Adapter::ISF->new->parse_source(source('(wait 2)', 'count'), 'static.isf');
    my $child = FSM::Scheduler::ISF->new->{ir}->build_module($actor)->{children}{child};
    my ($entry) = grep {$_->{kind} eq 'entry'} @{$child->{states}};
    is(scalar @{$entry->{transitions}}, 1, 'ordinary entry has its original single edge');
    ok(!grep({($_->{source_kind} // '') eq 'dynamic_wait_counter_load'} @{$entry->{assignments}}),
        'ordinary entry gains no dynamic counter load');
};

subtest 'repaired source remains consistent through native API and newline MCP' => sub {
    my $root = abs_path('.');
    my $relative = File::Spec->abs2rel($public_file, $root);
    my $api = FSM::Support::SemanticIntrospectionMCPAdapter->new(repo_root => $root, workspace_root => $root);
    for my $query (['check', [qw(--quiet --strict --check --json)], 'fsmgen_check'],
                   ['semantic', [qw(--quiet --strict --emit-semantic-json)], 'fsmgen_semantic_introspect'],
                   ['schedule', [qw(--quiet --strict --emit-schedule-json)], 'fsmgen_schedule_preview']) {
        my ($kind, $flags, $tool) = @$query;
        my $native = FSM::Test::SourceQueryRunner::_capture([$^X, 'bin/fsmgen', @$flags, $relative], '');
        is($native->{exit_code}, 0, "native $kind accepted");
        my $request = {jsonrpc => '2.0', id => 1, method => 'tools/call', params => {
            name => $tool, arguments => {source_id => $relative}}};
        my $response = $api->handle_jsonrpc_request($request);
        my $report = FSM::Test::SourceQueryRunner::normalize_repository_paths($json->decode($native->{stdout}), $root);
        is_deeply($response->{result}{structuredContent}{report}, $report, "complete native/API $kind parity");
        my $wire = FSM::Test::SourceQueryRunner::_capture([$^X, 'bin/fsmgen-mcp', '--workspace-root', '.'],
            $json->encode($request) . "\n");
        is($wire->{exit_code}, 0, "newline $kind completed");
        is_deeply($json->decode($wire->{stdout}), $response, "complete newline/API $kind parity");
    }
};
done_testing;

sub source {
    my ($body, $result) = @_;
    return "(actor generated_wait (clock clk) (reset rst_n)\n"
        . " (interface (input start) (input go) (input count (width 3)) (input tail (width 3))"
        . " (output observed (width 3)) (output done))\n"
        . " (transaction child (ports (input count (width 3)) (input tail (width 3)) (output result (width 3)))"
        . " $body (update result $result) (complete done))\n"
        . " (transaction parent (on start)"
        . " (spawn child as first (bind (input count count) (input tail tail) (output result observed)))"
        . " (await_all first) (complete done)))\n";
}

sub write_file {
    my ($path, $text) = @_;
    open my $out, '>:raw', $path or die $!;
    print {$out} $text or die $!;
    close $out or die $!;
    return $path;
}

sub condition {
    my ($guard, $values) = @_;
    return 1 unless $guard;
    return expression($guard->{expr} // $guard->{port}, $values);
}

sub expression {
    my ($text, $values) = @_;
    my @tokens = $text =~ /(\(|\)|[^\s()]+)/g;
    my $parse;
    $parse = sub {
        my $token = shift @tokens;
        die 'missing expression token' unless defined $token;
        return atom($token, $values) unless $token eq '(';
        my $op = shift @tokens;
        my @args;
        push @args, $parse->() while @tokens && $tokens[0] ne ')';
        die 'unclosed expression' unless @tokens && shift(@tokens) eq ')';
        return !$args[0] if $op eq '!';
        return $args[0] != $args[1] if $op eq '!=';
        return $args[0] == $args[1] if $op eq '==';
        if ($op eq '&') {
            my $result = shift @args;
            $result &= $_ for @args;
            return $result;
        }
        die "unhandled independent oracle operator $op";
    };
    my $result = $parse->();
    die 'trailing expression tokens' if @tokens;
    return $result;
}

sub atom {
    my ($token, $values) = @_;
    return 0 + $token if $token =~ /\A\d+\z/;
    return 0 + $1 if $token =~ /\A\d+'d(\d+)\z/;
    die "unknown independent oracle signal $token" unless exists $values->{$token};
    return $values->{$token};
}
