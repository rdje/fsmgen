#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Cwd qw(abs_path);
use Digest::SHA qw(sha256_hex);
use File::Spec;
use File::Temp qw(tempdir);
use JSON::PP ();
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::Adapter::ISF;
use FSM::Adapter::IAL2::PPIF;
use FSM::Support::SemanticIntrospectionMCPAdapter;
use FSM::Test::SourceQueryRunner;

sub actor_source {
    my ($body, $extra) = @_;
    return '(actor rule_reads (interface (input start) (input DATA (width 8)) '
        .'(output A (width 8)) (output B) (output done)) '
        .($extra // '').' (transaction tx (on start) (complete done)) '.$body.')';
}
sub parse {
    FSM::Adapter::ISF->new->parse_source($_[0], 'rule-reads.isf');
}

subtest 'all reported rules are identified before inferred widths or ports exist' => sub {
    for my $width (1, 8) {
        my $source = actor_source('(rule r_a (A VALID)) (rule r_b (B VALID))');
        $source =~ s/\(output A \(width 8\)\)/(output A (width $width))/;
        my $ok = eval { parse($source); 1 };
        ok(!$ok, "undeclared read rejected with target width $width");
        like($@, qr/actor 'rule_reads'.*undeclared.*operand 'VALID'/s, 'actor and missing operand');
        like($@, qr/rule 'r_a'.*rule 'r_b'/s, 'both readers are identified in declaration order');
        unlike($@, qr/incompatible width|OperandContractValidationSupport/, 'refusal precedes HDL width inference');
    }
};

subtest 'ordinary reads cannot hide inside expressions, guards, slices or bank operands' => sub {
    for my $body (
        '(rule r (set A (+ DATA VALID)))',
        '(rule r (A (& DATA (| VALID 1))))',
        '(rule r VALID (B 1))',
        '(rule r (! VALID) (B 1))',
        '(rule r !VALID (B 1))',
        '(rule r VALID=1 (B 1))',
        '(rule r "VALID = 1" (B 1))',
        '(rule r (B VALID[0]))',
        '(rule r (A VALID[7:0]))',
        '(rule r (store mem VALID DATA))',
        '(rule r (store mem 0 VALID))',
        '(rule r (load mem VALID as A))',
    ) {
        my $ok = eval { parse(actor_source($body, '(storage (bank mem (width 8) (depth 4)))')); 1 };
        ok(!$ok, "$body rejects unknown read");
        like($@, qr/undeclared.*operand 'VALID'/s, 'missing base identity is named');
    }
    my $ok = eval { parse(actor_source('(rule second (A (+ ZETA ALPHA ZETA))) (rule first ALPHA (B 1))')); 1 };
    ok(!$ok, 'multiple missing symbols are collected');
    like($@, qr/operand 'ALPHA' read by rule 'second' assignment RHS, rule 'first' guard\n  - operand 'ZETA' read by rule 'second' assignment RHS\n/,
        'operand ordering and reader deduplication are deterministic');
};

subtest 'declared actor symbols and literal forms remain valid reads' => sub {
    my $extra = '(params (P 2)) (constants (C 1)) (enums (mode (IDLE 0) (BUSY 1))) '
        .'(storage (var slot (width 8)) (bank mem (width 8) (depth 4)))';
    for my $rhs ('DATA', 'A', 'slot', 'P', 'C', 'mode.BUSY', 'DATA[0]', 'DATA[7:0]',
                 '0', '1', '-1', '0xFF', "8'hA5", "8'bxxxxxxxx", 'const_8b00000101',
                 '(+ DATA P)', '(& DATA (| slot C))') {
        my $a = eval { parse(actor_source("(rule r start (A $rhs))", $extra)) };
        ok($a, "$rhs is a declared read or literal") or diag($@);
    }
    for my $guard ('start', '!start', 'DATA=1', '"DATA = 1"', '(== DATA P)') {
        ok(eval { parse(actor_source("(rule r $guard (B 1))", $extra)); 1 }, "$guard stays valid") or diag($@);
    }
};

subtest 'transaction-local inferred targets remain separate from rule reads' => sub {
    my $source = actor_source('(rule r start (B 1))');
    $source =~ s/\(complete done\)/(set temporary DATA) (set A temporary) (complete done)/;
    ok(eval { parse($source); 1 }, 'existing transaction-local inference is preserved') or diag($@);
    $source =~ s/\(B 1\)/(B temporary)/;
    ok(!eval { parse($source); 1 }, 'a transaction-local name does not become an actor-wide rule input');
};

subtest 'generated AXI rules share explicitly declared actor state' => sub {
    my %address = (addr_q => 32, id_q => 4, len_q => 8, size_q => 3, burst_q => 2, active_q => 1);
    my %expected = (
        axi_aw_driver => {%address, launch_aw_start => 1},
        axi_ar_driver => {%address, launch_ar_start => 1},
        axi_w_driver => {data_q => 32, strb_q => 4, active_q => 1, launch_w_start => 1},
        axi_w_burst4_driver => {active_q => 1, beat_index_q => 2,
            data1_q => 32, data2_q => 32, data3_q => 32, strb1_q => 4, strb2_q => 4, strb3_q => 4},
        axi_b_response_acceptor => {active_q => 1, arm_b_start => 1},
        axi_r_beat_acceptor => {active_q => 1, arm_r_start => 1},
    );
    my $protocol = FSM::Adapter::IAL2::PPIF->new;
    for my $name (sort keys %expected) {
        my $result = eval { $protocol->parse_file("ppif/$name.ppif") };
        ok($result, "$name retains public admission") or do {diag($@); next};
        my $actor = FSM::Adapter::ISF->new->parse_source($result->{generated_ial1}{text}, "$name.isf");
        my %widths = map {$_->{name} => $_->{width}} map {@{$_->{signals}}} @{$actor->{storage}};
        is_deeply(\%widths, $expected{$name}, "$name exposes the intended shared-state widths");
        is_deeply($result->{generated_ial1_schedule_report}{compile_issues}, [], "$name still schedules cleanly");
        if ($name eq 'axi_aw_driver') {
            my $missing = $result->{generated_ial1}{text};
            $missing =~ s/\(var launch_aw_start \(width 1\)\)//;
            ok(!eval {FSM::Adapter::ISF->new->parse_source($missing, 'missing-handoff.isf'); 1},
                'generated launch producers do not bypass an absent shared declaration');
            like($@, qr/operand 'launch_aw_start'/, 'missing shared launch is identified');
        }
    }
    for my $channel (qw(aw ar w)) {
        open my $in, '<', "ppif/axi_${channel}_driver.ppif" or die $!;
        my $source = do {local $/; <$in>}; close $in;
        $source =~ s/\b${channel}_cmd_valid\b/launch_${channel}_start/g;
        ok(!eval {$protocol->parse_source($source, 'collision.ppif'); 1}, "$channel launch handoff cannot alias an input binding");
        like($@, qr/duplicates (?:interface\/internal )?signal 'launch_${channel}_start'/, 'collision diagnosed before generated actor construction');
    }
};

subtest 'AXI composition artifacts retain executable ISF admission' => sub {
    for my $name (qw(axi_write_request_composition axi_write_transaction_composition
                    axi_write_burst4_request_composition axi_read_transaction_composition
                    axi_read_burst4_transaction_composition)) {
        my $result = eval {FSM::Adapter::IAL2::PPIF->new->parse_file("ppif/$name.ppif")};
        ok($result, "$name admits through the public adapter") or do {diag($@); next};
        my $items = $result->{generated_ial1}{items};
        cmp_ok(scalar(@$items), '>', 1, 'composition exposes endpoint and coordinator artifacts');
        for my $item (@$items) {
            ok(eval {FSM::Adapter::ISF->new->parse_source($item->{text}, $item->{name}); 1},
                "$name / $item->{name} independently parses") or diag($@);
        }
    }
};

subtest 'native and MCP failures retain the authored source and stable operand diagnostic' => sub {
    my $root = abs_path('.');
    my $work = tempdir(CLEANUP => 1);
    my $json = JSON::PP->new->canonical->utf8;
    my $capture = \&FSM::Test::SourceQueryRunner::_capture;
    my $normalize = \&FSM::Test::SourceQueryRunner::normalize_repository_paths;
    my $adapter = FSM::Support::SemanticIntrospectionMCPAdapter->new(repo_root => $root, workspace_root => $root);
    open my $fh, '<', 't/corpus/isf_undeclared_rule_operand.isf' or die $!;
    my $original = do {local $/; <$fh>}; close $fh;
    for my $width (1, 8) {
        my $source = $original;
        $source =~ s/\(output A \(width 1\)\)/(output A (width $width))/;
        my $path = File::Spec->catfile($work, "missing-$width.isf");
        open my $out, '>', $path or die $!; print {$out} $source; close $out or die $!;
        my $relative = File::Spec->abs2rel($path, $root);
        for my $kind (qw(check semantic)) {
            my @flags = $kind eq 'check' ? ('--check', '--json') : ('--emit-semantic-json');
            my $native = $capture->([$^X, 'bin/fsmgen', '--strict', @flags, $relative], '');
            is($native->{exit_code}, 1, "$kind rejects width-$width source");
            is($native->{signal}, 0, 'ordinary refusal, not a crash');
            my $report = $normalize->($json->decode($native->{stdout}), $root);
            ok(!$report->{success}, 'report declares failure');
            is(scalar @{$report->{diagnostics}}, 1, 'one collected diagnostic');
            my $diagnostic = $report->{diagnostics}[0];
            is($diagnostic->{code}, 'FSMGEN_LANGUAGE_ISF_UNDECLARED_RULE_OPERAND', 'stable public code');
            is($diagnostic->{source_file}, $relative, 'authored source identity');
            like($diagnostic->{message}, qr/operand 'VALID'.*rule 'r_a'.*rule 'r_b'/s, 'all rule readers retained');
            unlike($diagnostic->{message}, qr/\.pm|ial1-lowering|\bat .* line \d+/, 'no implementation or lowered-source leakage');
            my $request = {jsonrpc => '2.0', id => 1, method => 'tools/call', params => {
                name => $kind eq 'check' ? 'fsmgen_check' : 'fsmgen_semantic_introspect',
                arguments => {source_id => $relative}}};
            my $api = $adapter->handle_jsonrpc_request($request);
            ok($api->{result}{isError}, 'public adapter marks source refusal');
            is_deeply($api->{result}{structuredContent}{report}, $report, 'complete native/API failure parity');
            my $wire = $capture->([$^X, 'bin/fsmgen-mcp', '--workspace-root', '.'], $json->encode($request)."\n");
            is($wire->{exit_code}, 0, 'MCP process handles source failure normally');
            is(sha256_hex($json->encode($json->decode($wire->{stdout}))), sha256_hex($json->encode($api)),
                'complete actual newline MCP response equals public adapter response');
        }
        my $schedule = $capture->([$^X, 'bin/fsmgen', '--emit-schedule-json', $relative], '');
        isnt($schedule->{exit_code}, 0, 'schedule preview cannot bypass admission');
        is($schedule->{signal}, 0, 'schedule refusal is not a signal termination');
        like($schedule->{stderr}, qr/undeclared rule read operands/, 'schedule retains source-level refusal');
        my $hdl = File::Spec->abs2rel(File::Spec->catfile($work, "missing-$width.sv"), $root);
        my $generated = $capture->([$^X, 'bin/fsmgen', '--strict', '--quiet', '--output', $hdl, $relative], '');
        isnt($generated->{exit_code}, 0, 'generation refuses the undeclared input');
        is($generated->{signal}, 0, 'generation refusal is not a signal termination');
        ok(!-e $hdl, 'no invalid module is emitted');
    }
    my $declared = $original;
    $declared =~ s/\(input start\)/(input start) (input VALID)/;
    my $path = File::Spec->catfile($work, 'declared.isf');
    open my $out, '>', $path or die $!; print {$out} $declared; close $out or die $!;
    my $relative = File::Spec->abs2rel($path, $root);
    my $native = $capture->([$^X, 'bin/fsmgen', '--strict', '--emit-semantic-json', $relative], '');
    is($native->{exit_code}, 0, 'declaring the operand restores strict admission');
    my $report = $normalize->($json->decode($native->{stdout}), $root);
    ok($report->{success}, 'declared control succeeds');
    is_deeply([sort map {$_->{name}} @{$report->{semantic}{signal_analysis}{inputs}}],
        [qw(VALID start)], 'only the authored data inputs exist');
    my $request = {jsonrpc => '2.0', id => 2, method => 'tools/call', params => {
        name => 'fsmgen_semantic_introspect', arguments => {source_id => $relative}}};
    my $api = $adapter->handle_jsonrpc_request($request);
    ok(!$api->{result}{isError}, 'public adapter accepts declared control');
    is_deeply($api->{result}{structuredContent}{report}, $report, 'declared native/API semantic parity');
    my $wire = $capture->([$^X, 'bin/fsmgen-mcp', '--workspace-root', '.'], $json->encode($request)."\n");
    is($wire->{exit_code}, 0, 'declared control completes through newline MCP');
    is(sha256_hex($json->encode($json->decode($wire->{stdout}))), sha256_hex($json->encode($api)),
        'complete declared-control newline MCP response equals public adapter response');
};

done_testing();
