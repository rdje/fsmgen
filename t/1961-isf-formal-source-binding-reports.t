#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Storable qw(dclone);
use JSON::PP;
use Cwd qw(abs_path);
use File::Spec;
use File::Temp qw(tempdir);
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::Test::SourceQueryRunner;
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Scheduler::ISF::FormalIdentityPlan;
use FSM::Scheduler::ISF::FormalClauseResolver;
use FSM::Scheduler::ISF::PreparedFormalReservations;
use FSM::Scheduler::ISF::FormalLowering;
use FSM::Support::SemanticIntrospectionMCPAdapter;

my $scheduler = FSM::Scheduler::ISF->new;
my $root = abs_path('.');
my $work = tempdir(CLEANUP => 1);
my $json = JSON::PP->new->canonical;
my $capture = \&FSM::Test::SourceQueryRunner::_capture;
my $normalize = \&FSM::Test::SourceQueryRunner::normalize_repository_paths;
my $api = FSM::Support::SemanticIntrospectionMCPAdapter->new(repo_root => $root, workspace_root => $root);
sub parse {FSM::Adapter::ISF->new->parse_source($_[0], 'source_binding_reports.isf')}
sub prepare {
    no warnings 'redefine';
    local *FSM::Scheduler::ISF::LoweringIR::build_module = sub {die "unexpected raw parent merge\n"};
    return $scheduler->{ir}->prepare_formal_source($_[0]);
}
sub project {
    my ($p) = @_;
    my $a = dclone($p->{actor});
    my $plan = FSM::Scheduler::ISF::FormalIdentityPlan->build($a,
        generated_children => $p->{generated_children},
        reserved_names => FSM::Scheduler::ISF::PreparedFormalReservations->collect($p)->{reserved_names});
    for my $tx (@{$a->{transactions}}) {
        next if $p->{pruned_transactions}{$tx->{name}};
        $tx = FSM::Scheduler::ISF::FormalClauseResolver->transaction($tx,
            plan => $plan, %{$p->{transactions}{$tx->{name}}})->{transaction};
    }
    for my $rule (@{$a->{rules}}) {
        $rule = FSM::Scheduler::ISF::FormalClauseResolver->rule($rule,
            plan => $plan, %{$p->{actor_context}})->{rule};
    }
    return ($a, $plan);
}
my $source = <<'ISF';
(actor source_binding_reports (clock clk) (reset rst_n)
 (interface (input start) (input fire) (input req_data (width 4)) (output done) (output response (width 4)))
 (transaction worker (ports (input addr (width 4)) (output result (width 4)))
  (on worker_start) (set result addr) (complete worker_done))
 (transaction generated (ports (input datum (width 4))) (wait 1))
 (transaction target (ports (input quota (width 4))) (on target_start) (wait 1))
 (transaction parent (ports (input payload (width 4)) (output reply (width 4)))
  (on start) (set payload req_data)
  (do worker (bind (input addr payload (timing snapshot)) (output result reply)))
  (spawn generated as job (bind (input datum (+ payload 1) (timing live))))
  (await_all done) (set response reply) (complete done))
 (rule request fire (trigger target (bind (input quota req_data (timing snapshot))))))
ISF

subtest 'source products match canonical public reports while physical operands stay separate' => sub {
    my $actor = parse($source); my $before = dclone($actor);
    my $p = prepare($actor);
    my $report = $json->decode($scheduler->report($actor));
    is_deeply($p->{transaction_binding_report_products}, $report->{transaction_port_bindings},
        'complete prepared records match the ordinary public binding table');
    is_deeply([map {$_->{site_kind}} @{$p->{transaction_binding_report_products}}],
        [qw(do do spawn rule_trigger)], 'local, generated and rule records retained in canonical order');
    my ($input, $output, $generated, $rule) = @{$p->{transaction_binding_report_products}};
    is($input->{port}, 'addr', 'authored callee formal retained');
    is($input->{actor_signal}, 'payload', 'authored caller formal retained');
    is($output->{actor_signal}, 'reply', 'authored output target retained');
    is($generated->{actor_expression}, '(+ payload 1)', 'complete source expression retained');
    is($generated->{child_port}, 'datum', 'generated public formal retained');
    is($rule->{payload_source}, 'request_target_quota', 'source-owned rule helper retained');
    is_deeply([map {$_->{authored_timing_mode}} ($input, $generated, $rule)],
        [qw(snapshot live snapshot)], 'authored timing remains distinct from effective timing');
    my ($physical, $plan) = project($p);
    my $physical_report = $json->decode($scheduler->report($physical));
    is($physical_report->{transaction_port_bindings}[0]{actor_signal},
        $plan->{formals}{parent}{payload}{physical_name}, 'current physical report exposes rewritten caller endpoint');
    is($physical_report->{transaction_port_bindings}[0]{port},
        $plan->{formals}{worker}{addr}{physical_name}, 'current physical report exposes rewritten callee endpoint');
    is_deeply($p->{transaction_binding_report_products}, $report->{transaction_port_bindings},
        'source table remains available unchanged after physical lowering');
    $p->{transaction_binding_report_products}[0]{actor_signal} = 'mutated';
    is_deeply($actor, $before, 'source metadata snapshot is detached from actor');
    is(prepare($actor)->{transaction_binding_report_products}[0]{actor_signal}, 'payload',
        'later preparation does not inherit mutations');
};

subtest 'raw actor storage shadows do not require an executable parent to retain binding provenance' => sub {
    (my $shadow = $source) =~ s/\(transaction worker/(storage (var payload (width 8)) (var reply (width 8))) (transaction worker/;
    my $actor = parse($shadow); my $p = prepare($actor);
    my $ok = eval {$scheduler->{ir}->build_module($actor); 1};
    ok(!$ok, 'raw conflicting storage/formal merge remains refused');
    like($@, qr/(?:width|storage role).*conflicts/, 'existing executable collision diagnostic retained');
    my ($input, $output) = @{$p->{transaction_binding_report_products}};
    is($input->{width}, 4, 'source binding width belongs to callee formal');
    is($input->{actor_signal}, 'payload', 'caller shadow stays source-spelled');
    is($output->{actor_signal}, 'reply', 'output shadow stays source-spelled');
    my ($physical) = project($p);
    ok($scheduler->{ir}->build_module($physical), 'detached physical projection still admits separate storage');
};

subtest 'actual domain source products retain only their own binding sites' => sub {
    my $actor = parse(<<'ISF');
(actor domain_binding_reports
 (clock-domains (domain core (clock clk) (reset rst_n) :default) (domain aux (clock aux_clk) (reset aux_rst_n)))
 (interface (input start) (input data (width 4)) (output done)
  (input aux_start (domain aux)) (input aux_data (width 8) (domain aux)) (output aux_done (domain aux)))
 (transaction worker (ports (input addr (width 4))) (on worker_start) (wait 1))
 (transaction parent (on start) (do worker (bind (input addr data))) (complete done))
 (transaction aux_worker (domain aux) (ports (input aux_addr (width 8))) (on aux_worker_start) (wait 1))
 (transaction aux_parent (domain aux) (on aux_start) (do aux_worker (bind (input aux_addr aux_data))) (complete aux_done)))
ISF
    my $p = prepare($actor); my %actual;
    my $build = \&FSM::Scheduler::ISF::LoweringIR::build_module;
    {
        no warnings 'redefine';
        local *FSM::Scheduler::ISF::LoweringIR::build_module = sub {
            my ($self, $source) = @_; my $ir = $build->(@_);
            $actual{$source->{_scheduled_domain_name}} = dclone($ir)
                if defined $source->{_scheduled_domain_name};
            return $ir;
        };
        $scheduler->lower($actor);
    }
    my $context = FSM::Scheduler::ISF::FormalLowering->prepare($scheduler->{ir}, $actor);
    for my $name (qw(core aux)) {
        my $records = $p->{domain_source_products}{$name}{preparation}{transaction_binding_report_products};
        my $view = FSM::Scheduler::ISF::FormalLowering->report_ir($context, $actual{$name}, $name);
        is_deeply($records, $view->{transaction_port_bindings}, "$name source metadata survives actual physical domain reporting");
        my $record = $records->[0];
        is($actual{$name}{transaction_port_bindings}[0]{port},
            $context->{plan}{formals}{$record->{target_transaction}}{$record->{port}}{physical_name},
            "$name executable binding remains physical");
        is_deeply([map {$_->{owner}} @$records], [$name eq 'core' ? 'parent' : 'aux_parent'],
            "$name report ownership excludes sibling sites");
    }
};

subtest 'complete public native API and newline schedules remain identical' => sub {
    my $path = "$work/source.isf";
    open my $fh, '>', $path or die $!; print {$fh} $source; close $fh or die $!;
    my $relative = File::Spec->abs2rel($path, $root);
    my $native = $capture->([$^X, 'bin/fsmgen', '--emit-schedule-json', $relative], '');
    is($native->{exit_code}, 0, 'native schedule succeeds') or diag($native->{stdout}, $native->{stderr});
    return if $native->{exit_code};
    my $report = $normalize->($json->decode($native->{stdout}), $root);
    my $request = {jsonrpc => '2.0', id => 1, method => 'tools/call', params => {
        name => 'fsmgen_schedule_preview', arguments => {source_id => $relative}}};
    my $response = $api->handle_jsonrpc_request($request);
    ok(!$response->{result}{isError}, 'API schedule succeeds');
    is_deeply($response->{result}{structuredContent}{report}, $report, 'entire API/native schedule agrees');
    my $wire = $capture->([$^X, 'bin/fsmgen-mcp', '--workspace-root', '.'], $json->encode($request) . "\n");
    is($wire->{exit_code}, 0, 'newline MCP succeeds');
    is_deeply($json->decode($wire->{stdout}), $response, 'entire newline/API response agrees');
};

done_testing();
