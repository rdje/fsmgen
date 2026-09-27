#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Storable qw(dclone);
use File::Temp qw(tempdir);
use Cwd qw(abs_path);
use JSON::PP;
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::Test::SourceQueryRunner;
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Scheduler::ISF::WriterResourceGrants;
use FSM::Support::SemanticIntrospectionMCPAdapter;

my $collector = 'FSM::Scheduler::ISF::WriterResourceGrants';
my $scheduler = FSM::Scheduler::ISF->new;
my $work = tempdir(CLEANUP => 1);
my $root = abs_path('.');
my $json = JSON::PP->new;
my $capture = \&FSM::Test::SourceQueryRunner::_capture;
my @users = qw(low middle high);
my %higher = (low => [qw(high middle)], middle => ['high'], high => []);

sub write_file {
    my ($name, $text) = @_;
    open my $fh, '>', "$work/$name" or die $!;
    print {$fh} $text or die $!;
    close $fh or die $!;
    return "$work/$name";
}

sub fixture {
    my ($kind, $arbiter, $reverse, $extra) = @_;
    my $module = "grants_${kind}_${arbiter}";
    my $name = $kind eq 'transaction_start' ? 'main' : 'shared';
    my @members = $kind eq 'storage_port' ? qw(s_high s_middle s_low)
        : $kind eq 'output_bundle' ? qw(v_high v_middle v_low) : ();
    my $member_clause = @members ? '(members ' . join(' ', @members) . ')' : '';
    my $resource = $kind eq 'unbound' ? '(resource parking (kind named_drive) (arbiter priority))'
        : "(resource $name (kind $kind) (arbiter $arbiter) $member_clause (users low middle high))";
    $resource .= ' (resource second (kind rule_slot) (arbiter priority) (users high low))' if $extra;
    my @rules;
    my %request = (high => 'a', middle => 'b', low => 'c');
    for my $user (qw(high middle low)) {
        my $target = ($kind eq 'storage_port' ? 's_' : 'v_') . $user;
        my $trigger = $kind eq 'transaction_start' ? '(trigger main)' : '';
        push @rules, "(rule $user (when $request{$user}) (set $target 7) $trigger)";
    }
    @rules = reverse @rules if $reverse;
    my $source = "(actor $module (clock clk) (reset rst_n)\n"
        . '(interface (input start) (input a) (input b) (input c) (input free_req) (output done)'
        . ' (output v_high (width 8)) (output v_middle (width 8)) (output v_low (width 8)) (output spare (width 8)))'
        . ' (storage (var s_high (width 8)) (var s_middle (width 8)) (var s_low (width 8)))'
        . ' (transaction main (on start) (complete done))'
        . ' (priority high over middle) (priority middle over low)'
        . " (resources $resource)\n" . join("\n", @rules)
        . ' (rule free (when free_req) (set spare 9)))' . "\n";
    my $actor = FSM::Adapter::ISF->new->parse_source($source, "$module.isf");
    my $ir = $scheduler->{ir}->build_module($actor);
    return {actor => $actor, ir => $ir, source => $source, name => $name,
        module => $module, kind => $kind, arbiter => $arbiter, members => \@members};
}

my @cases = map {my $kind = $_; map {fixture($kind, $_)} qw(priority round_robin)}
    qw(rule_slot output_bundle transaction_start storage_port);

subtest 'actual declarations, module grants and explicitly owned DT mirrors agree' => sub {
    for my $case (@cases) {
        my ($ir, $actor) = @{$case}{qw(ir actor)};
        my ($before_ir, $before_actor) = (dclone($ir), dclone($actor));
        my $carrier = $scheduler->{fsm_emitter}->emit($ir);
        my @expected = map {
            my $user = $_;
            {resource => $case->{name}, kind => $case->{kind}, arbiter => $case->{arbiter}, user => $user,
             higher => $case->{arbiter} eq 'priority' ? $higher{$user} : [grep {$_ ne $user} @users],
             members => $case->{members},
             source_owner => {module => $case->{module}, domain => undef, source_kind => 'rule',
                source_name => $user, container_kind => 'dt', container_name => $user}}
        } @users;
        my $records = $collector->collect($ir, $actor);
        is_deeply($records, \@expected, "$case->{kind} $case->{arbiter} retains independent expected grant records");
        is_deeply($ir, $before_ir, 'collection leaves the entire module unchanged');
        is_deeply($actor, $before_actor, 'collection leaves all authored declarations unchanged');
        is($scheduler->{fsm_emitter}->emit($ir), $carrier, 'complete emitted carrier is unchanged');
        $records->[0]{higher}[0] = 'changed';
        $records->[0]{members}[0] = 'changed';
        $records->[0]{source_owner}{source_name} = 'changed';
        is_deeply($ir, $before_ir, 'returned nested grants and owners are detached');
        is_deeply($actor, $before_actor, 'returned member lists do not alias declarations');
        my $reordered = fixture($case->{kind}, $case->{arbiter}, 1);
        is_deeply($collector->collect($reordered->{ir}, $reordered->{actor}), \@expected,
            'rule declaration order does not change resource/user correspondence');
    }
    my $unbound = fixture('unbound', 'priority');
    is_deeply($collector->collect($unbound->{ir}, $unbound->{actor}), [], 'unbound backlog declaration fabricates no executable grant');
    my $multiple = fixture('rule_slot', 'priority', 0, 1);
    my $grants = $collector->collect($multiple->{ir}, $multiple->{actor});
    is_deeply([map {[$_->{resource}, $_->{user}]} @$grants],
        [[shared => 'low'], [shared => 'middle'], [shared => 'high'], [second => 'high'], [second => 'low']],
        'multiple resources keep separate actual user associations');
    my $renamed = dclone($multiple->{ir});
    for my $dt (@{$renamed->{dt_blocks}}) {$dt->{name} = 'renamed_low' if $dt->{name} eq 'low'}
    my @low = grep {$_->{user} eq 'low'} @{$collector->collect($renamed, $multiple->{actor})};
    is_deeply([map {$_->{source_owner}{container_name}} @low], ['renamed_low', 'renamed_low'],
        'authored ownership, not the DT spelling, joins every resource mirror');
};

subtest 'missing or inconsistent producer evidence cannot become a grant' => sub {
    my $base = $cases[0];
    my @mutations = (
        ['root omission', sub {shift @{$_[0]{resource_arbitration}{grants}}}],
        ['both lowered copies omitted', sub {$_[0]{resource_arbitration}{grants} = []; delete $_->{resource_grants} for @{$_[0]{dt_blocks}}}],
        ['duplicate root', sub {push @{$_[0]{resource_arbitration}{grants}}, dclone($_[0]{resource_arbitration}{grants}[0])}],
        ['missing mirror', sub {delete $_->{resource_grants} for grep {$_->{name} eq 'low'} @{$_[0]{dt_blocks}}}],
        ['duplicate mirror', sub {my ($dt) = grep {$_->{name} eq 'low'} @{$_[0]{dt_blocks}}; push @{$dt->{resource_grants}}, dclone($dt->{resource_grants}[0])}],
        ['wrong mirror', sub {my ($dt) = grep {$_->{name} eq 'low'} @{$_[0]{dt_blocks}}; $dt->{resource_grants}[0]{higher} = ['high']}],
        ['unknown user', sub {$_[0]{resource_arbitration}{grants}[0]{user} = 'unknown'}],
        ['wrong kind', sub {$_[0]{resource_arbitration}{grants}[0]{kind} = 'output_bundle'}],
        ['wrong members', sub {$_[0]{resource_arbitration}{grants}[0]{members} = ['v_low']}],
        ['self suppressor', sub {$_[0]{resource_arbitration}{grants}[0]{higher} = ['low']}],
        ['duplicate suppressor', sub {$_[0]{resource_arbitration}{grants}[0]{higher} = ['high', 'high']}],
        ['unstructured names', sub {$_[0]{resource_arbitration}{grants}[0]{higher} = 'high'}],
        ['unknown grant field', sub {$_[0]{resource_arbitration}{grants}[0]{future} = 1}],
        ['arbitration issue', sub {push @{$_[0]{resource_arbitration}{issues}}, {code => 'unproved'}}],
        ['missing arbitration', sub {delete $_[0]{resource_arbitration}}],
        ['missing source owner', sub {delete $_->{source_owner} for grep {$_->{name} eq 'low'} @{$_[0]{dt_blocks}}}],
        ['duplicate rule owner', sub {my ($dt) = grep {$_->{name} eq 'low'} @{$_[0]{dt_blocks}}; push @{$_[0]{dt_blocks}}, dclone($dt)}],
        ['declaration removed', sub {$_[1]{resources} = []}],
        ['duplicate declaration', sub {push @{$_[1]{resources}}, dclone($_[1]{resources}[0])}],
        ['duplicate declared user', sub {push @{$_[1]{resources}[0]{users}}, 'low'}],
        ['mismatched module', sub {$_[1]{actor_name} = 'other'}],
    );
    for my $mutation (@mutations) {
        my ($ir, $actor) = (dclone($base->{ir}), dclone($base->{actor}));
        $mutation->[1]->($ir, $actor);
        eval {$collector->collect($ir, $actor)};
        like($@, qr/(?:Writer resource grants|Source writer ownership)/, "$mutation->[0] is refused");
    }
    my $rr = dclone($cases[1]{ir});
    $rr->{resource_arbitration}{grants}[0]{higher} = ['high'];
    my ($dt) = grep {$_->{name} eq 'low'} @{$rr->{dt_blocks}};
    $dt->{resource_grants}[0]{higher} = ['high'];
    eval {$collector->collect($rr, $cases[1]{actor})};
    like($@, qr/incomplete round-robin peers/, 'declarations catch peer loss even when both lowered copies agree');
};

subtest 'collected actual carriers and public reports keep their existing contract' => sub {
    my $api = FSM::Support::SemanticIntrospectionMCPAdapter->new(repo_root => $root, workspace_root => $root);
    for my $case (@cases) {
        my $source = write_file("$case->{module}.isf", $case->{source});
        my $carrier = write_file("$case->{module}.fsm", $scheduler->{fsm_emitter}->emit($case->{ir}));
        my $check = $capture->([$^X, 'bin/fsmgen', '--strict', '--check', '--json', $carrier], '');
        is($check->{exit_code}, 0, "$case->{module} complete carrier strict-checks") or diag($check->{stdout}, $check->{stderr});
        my @semantic;
        for my $path ($source, $carrier) {
            my $result = $capture->([$^X, 'bin/fsmgen', '--strict', '--emit-semantic-json', $path], '');
            is($result->{exit_code}, 0, "$case->{module} semantic query succeeds") or diag($result->{stderr});
            push @semantic, $json->decode($result->{stdout})->{semantic};
        }
        is_deeply($semantic[0], $semantic[1], "$case->{module} complete native/carrier semantic parity");
        next unless $case->{kind} eq 'rule_slot';
        my $native = $capture->([$^X, 'bin/fsmgen', '--emit-schedule-json', $source], '');
        is($native->{exit_code}, 0, "$case->{arbiter} public schedule succeeds");
        my $expected = FSM::Test::SourceQueryRunner::normalize_repository_paths($json->decode($native->{stdout}), $root);
        my $id = $source; $id =~ s{\A\Q$root\E/}{};
        my $request = {jsonrpc => '2.0', id => 1, method => 'tools/call',
            params => {name => 'fsmgen_schedule_preview', arguments => {source_id => $id}}};
        my $response = $api->handle_jsonrpc_request($request);
        ok(!$response->{error} && !$response->{result}{isError}, "$case->{arbiter} schedule API succeeds");
        is_deeply($response->{result}{structuredContent}{report}, $expected, "$case->{arbiter} complete native/API schedule parity");
        my $wire = $capture->([$^X, 'bin/fsmgen-mcp', '--workspace-root', '.'], $json->encode($request) . "\n");
        is($wire->{exit_code}, 0, "$case->{arbiter} newline query succeeds");
        is_deeply($json->decode($wire->{stdout}), $response, "$case->{arbiter} complete API/newline schedule parity");
    }
};

done_testing();
