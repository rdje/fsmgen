#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Storable qw(dclone);
use Cwd qw(abs_path);
use File::Temp qw(tempdir);
use File::Spec;
use JSON::PP;
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::Test::SourceQueryRunner;
use FSM::Test::DiagnosticCause qw(diagnostic_cause_matches);
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Scheduler::ISF::LoweringIR;
use FSM::Support::SemanticIntrospectionMCPAdapter;

my $lowerer = FSM::Scheduler::ISF::LoweringIR->new;
my $json = JSON::PP->new->canonical;
my $root = abs_path('.');
my $work = tempdir(CLEANUP => 1);
my $capture = \&FSM::Test::SourceQueryRunner::_capture;

sub source {
    my (%args) = @_;
    my $actor_decl = $args{actor_kind} eq 'storage'
        ? '(storage (var value (width 8) (reset 19)))'
        : '';
    my $actor_port = $args{actor_kind} =~ /\A(?:input|output)\z/
        ? "($args{actor_kind} value (width 8))" : '';
    my $formal = $args{formal} // '(ports (input value (width 4)))';
    my $callee = $args{callee} // '(ports (input payload (width 4)))';
    my $body = $args{body} // '(do worker (bind (input payload value)))';
    return "(actor binding_scope (clock clk) (reset (rst_n async active_low))\n"
        . "(interface (input start) (input observed (width 4)) (output done) $actor_port)\n"
        . "$actor_decl (transaction caller $formal (on start) $body (complete done))\n"
        . "(transaction worker $callee (on worker_start) (complete worker_done)))\n";
}

sub parse {
    return FSM::Adapter::ISF->new->parse_source($_[0], 'binding_scope.isf');
}
sub admission {
    my ($actor) = @_;
    my $ok = eval {$lowerer->_validate_transaction_port_bindings($actor); 1};
    return ($ok, $@);
}
sub rejects {
    my ($actor, $expected_cause, $label) = @_;
    my ($ok, $error) = admission($actor);
    ok(!$ok, "$label rejected");
    ok(diagnostic_cause_matches($error, $expected_cause), "$label diagnostic")
        or diag($error);
}

for my $actor_kind (qw(input output storage)) {
    for my $formal_kind (qw(input output)) {
        subtest "$formal_kind caller formal shadows actor $actor_kind" => sub {
            for my $actual ('value', '(+ value observed)') {
                my $actor = parse(source(actor_kind => $actor_kind,
                    formal => "(ports ($formal_kind value (width 4)))",
                    body => "(do worker (bind (input payload $actual)))"));
                my $before = dclone($actor);
                my ($ok, $error) = admission($actor);
                ok($ok, "$actual reads caller width and role") or diag($error);
                is_deeply($actor, $before, 'validation preserves source declarations');
                my ($worker) = grep {$_->{name} eq 'worker'} @{$actor->{transactions}};
                $worker->{ports}{inputs}[0]{width} = 8;
                my $expected_cause = "Transaction 'caller': do target 'worker' "
                    . ($actual eq 'value'
                        ? "binding for port 'payload' width 8 does not match actor signal 'value' width 4"
                        : "input binding expression for port 'payload' width 4 does not match transaction port width 8");
                rejects($actor, $expected_cause,
                    "$actual does not borrow wider actor width");
            }
            my $actor = parse(source(actor_kind => $actor_kind,
                formal => "(ports ($formal_kind value (width 4)))",
                callee => '(ports (output result (width 4)))',
                body => '(do worker (bind (output result value)))'));
            my ($ok, $error) = admission($actor);
            ok($ok, 'output actual targets the caller variable') or diag($error);
            my ($worker) = grep {$_->{name} eq 'worker'} @{$actor->{transactions}};
            $worker->{ports}{outputs}[0]{width} = 8;
            rejects($actor, "Transaction 'caller': do target 'worker' binding for port 'result' width 8 does not match actor signal 'value' width 4",
                'output actual keeps caller width');
        };
    }
}

subtest 'actor restrictions and sibling scope are preserved' => sub {
    my $input = parse(source(actor_kind => 'input', formal => '',
        callee => '(ports (output result (width 8)))',
        body => '(do worker (bind (output result value)))'));
    rejects($input, "Transaction 'caller': do target 'worker' output binding for port 'result' targets actor input 'value', but actor inputs are read-only", 'actor input write');
    my $output = parse(source(actor_kind => 'output', formal => '',
        callee => '(ports (input payload (width 8)))'));
    rejects($output, "Transaction 'caller': do target 'worker' input binding for port 'payload' reads actor output 'value', but actor output readback is not public", 'actor output read');
    my $unknown = parse(source(actor_kind => 'none', formal => '',
        callee => '(ports (input value (width 4)))',
        body => '(do worker (bind (input value value)))'));
    rejects($unknown, "Transaction 'caller': do target 'worker' binding for port 'value' references unknown actor signal 'value'", 'callee formal is not caller variable');
    my $rule = parse(source(actor_kind => 'output'));
    $rule->{transactions}[0]{clauses} = [];
    $rule->{rules} = [{name => 'dispatch', actions => [['trigger', 'worker', ['bind', ['input', 'payload', 'value']]]]}];
    rejects($rule, "Rule 'dispatch': trigger target 'worker' input binding for port 'payload' reads actor output 'value', but actor output readback is not public", 'rule never borrows transaction formal');
};

subtest 'callee contract and live-site pruning are unchanged' => sub {
    for my $case (
        ['(do worker (bind (output payload value)))', "Transaction 'caller': do target 'worker' binding for port 'payload' uses role 'output' but the transaction declares 'input'", 'wrong direction'],
        ['(do worker (bind (input missing value)))', "Transaction 'caller': do target 'worker' binds unknown transaction port 'missing' on 'worker'", 'unknown callee port'],
        ['(do worker)', "Transaction 'caller': do target 'worker' requires '(bind ...)' because transaction 'worker' declares ports", 'missing binding'],
        ['(do worker (bind (input payload value) (input payload value)))', "Transaction 'caller': activation has duplicate binding for transaction port 'payload'", 'duplicate binding'],
        ['(do worker (bind (input payload value (timing live))))', "Transaction 'caller': do target 'worker' input binding for port 'payload' requested timing 'live', but this activation currently uses 'activation_region'; behavior-changing timing conversion is not supported yet", 'wrong timing'],
    ) {
        rejects(parse(source(actor_kind => 'storage', body => $case->[0])), $case->[1], $case->[2]);
    }
    my ($ok, $error) = admission(parse(source(actor_kind => 'storage',
        body => '(repeat 0 (do worker (bind (input missing nonexistent))))')));
    ok($ok, 'static-zero binding endpoints stay pruned') or diag($error);
    rejects(parse(source(actor_kind => 'storage',
        body => '(repeat 1 (do worker (bind (input missing nonexistent))))')),
        "Transaction 'caller': repeat-body do target 'worker' binds unknown transaction port 'missing' on 'worker'", 'live repeat checks endpoints');
};

subtest 'physical storage and caller formal remain separate' => sub {
    my $actor = parse(source(actor_kind => 'storage'));
    my $ok = eval {FSM::Scheduler::ISF->new->lower($actor); 1};
    ok($ok, 'production accepts independent caller formal storage') or diag($@);
    is($@, '', 'actor storage no longer creates a physical merge conflict');
};

subtest 'direct actor-pin shadows emit separate private storage' => sub {
    for my $kind (qw(input output)) {
        for my $width (4, 8) {
            for my $role (qw(input output)) {
                my $text = source(actor_kind => $kind,
                    callee => "(ports ($role payload (width 4)))",
                    body => "(do worker (bind ($role payload value)))");
                $text =~ s/\($kind value \(width 8\)\)/($kind value (width $width))/;
                my $actor = parse($text);
                my $lowered = FSM::Scheduler::ISF->new->lower($actor);
                my $fsm = $lowered->{files}{'binding_scope.fsm'};
                like($fsm, qr/\(isf_port_caller_value\w* 4\)/,
                    "$kind width $width $role binding uses private caller storage");
                like($fsm, qr/\(value $width\)/, 'actor pin keeps its original width');
                my $file = write_file("$work/alias_${kind}_${width}_${role}.isf", $text);
                my $check = $capture->([$^X, 'bin/fsmgen', '--strict', '--check', '--json', $file], '');
                is($check->{exit_code}, 0, 'native strict check admits separated identities')
                    or diag($check->{stdout}, $check->{stderr});
            }
        }
    }
};

subtest 'generated interfaces and zero-pruned targets keep their separate paths' => sub {
    for my $case (
        ['generated', '(spawn worker as w0 (bind (input value observed))) (await_all done)'],
        ['pruned', '(repeat 0 (do worker (bind (input value observed))))'],
    ) {
        my ($name, $body) = @$case;
        my $text = source(actor_kind => 'input', formal => '',
            callee => '(ports (input value (width 4)))', body => $body);
        $text =~ s/\(input value \(width 8\)\)/(input value (width 4))/;
        my $actor = parse($text);
        my $lowered = FSM::Scheduler::ISF->new->lower($actor);
        ok($lowered, "$name target avoids direct merge gate");
        if ($name eq 'generated') {
            like($lowered->{files}{'worker.fsm'}, qr/\(value 4\)/, 'generated public formal keeps its name and width');
        } else {
            unlike($lowered->{files}{'binding_scope.fsm'}, qr/worker_idle/, 'zero-pruned target has no physical states');
        }
        my $file = write_file("$work/$name.isf", $text);
        my $check = $capture->([$^X, 'bin/fsmgen', '--strict', '--check', '--json', $file], '');
        is($check->{exit_code}, 0, "$name source strict-checks") or diag($check->{stdout}, $check->{stderr});
    }
};

subtest 'unshadowed source, carriers and complete public reports' => sub {
    my $text = source(actor_kind => 'none',
        body => '(sample observed as value) (do worker (bind (input payload value (timing snapshot))))');
    my $actor = parse($text);
    my $lowered = FSM::Scheduler::ISF->new->lower($actor);
    for my $name (sort keys %{$lowered->{files}}) {
        next unless $name =~ /\.fsm\z/;
        my $file = write_file("$work/$name", $lowered->{files}{$name});
        my $result = $capture->([$^X, 'bin/fsmgen', '--strict', '--check', '--json', $file], '');
        is($result->{exit_code}, 0, "$name strict carrier replay") or diag($result->{stdout}, $result->{stderr});
    }
    my $file = write_file("$work/binding_scope.isf", $text);
    my $relative = File::Spec->abs2rel($file, $root);
    my $api = FSM::Support::SemanticIntrospectionMCPAdapter->new(repo_root => $root, workspace_root => $root);
    for my $query (
        [[qw(--strict --check --json)], 'fsmgen_check'],
        [[qw(--strict --emit-semantic-json)], 'fsmgen_semantic_introspect'],
        [['--emit-schedule-json'], 'fsmgen_schedule_preview'],
    ) {
        my ($flags, $tool) = @$query;
        my $native = $capture->([$^X, 'bin/fsmgen', @$flags, $relative], '');
        is($native->{exit_code}, 0, "$tool native success") or diag($native->{stdout}, $native->{stderr});
        my $expected = FSM::Test::SourceQueryRunner::normalize_repository_paths($json->decode($native->{stdout}), $root);
        my $request = {jsonrpc => '2.0', id => 1, method => 'tools/call', params => {
            name => $tool, arguments => {source_id => $relative}}};
        my $response = $api->handle_jsonrpc_request($request);
        is_deeply($response->{result}{structuredContent}{report}, $expected, "$tool complete native/API parity");
        my $wire = $capture->([$^X, 'bin/fsmgen-mcp', '--workspace-root', '.'], $json->encode($request)."\n");
        is($wire->{exit_code}, 0, "$tool protocol success");
        is_deeply($json->decode($wire->{stdout}), $response, "$tool complete newline/API parity");
    }
};
done_testing;

sub write_file {
    my ($path, $text) = @_;
    open my $fh, '>', $path or die "open $path: $!";
    print {$fh} $text or die "write $path: $!";
    close $fh or die "close $path: $!";
    return $path;
}
