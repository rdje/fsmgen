#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP qw(decode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $isf_file = File::Spec->catfile($repo_root, 'isf', 'atl_resolved_child_pipeline.isf');
my $pin_ingress_isf_file = File::Spec->catfile(
    $repo_root,
    'isf',
    'atl_resolved_child_pin_ingress_pipeline.isf',
);
my $pin_ingress_vector_isf_file = File::Spec->catfile(
    $repo_root,
    'isf',
    'atl_resolved_child_pin_ingress_vector_pipeline.isf',
);
my $pin_ingress_multi_isf_file = File::Spec->catfile(
    $repo_root,
    'isf',
    'atl_resolved_child_pin_ingress_multi_pipeline.isf',
);
my $pin_egress_isf_file = File::Spec->catfile(
    $repo_root,
    'isf',
    'atl_resolved_child_pin_egress_pipeline.isf',
);
my $pin_egress_multi_isf_file = File::Spec->catfile(
    $repo_root,
    'isf',
    'atl_resolved_child_pin_egress_multi_pipeline.isf',
);
my $two_child_isf_file = File::Spec->catfile(
    $repo_root,
    'isf',
    'atl_two_child_pipeline.isf',
);
my $two_child_data_isf_file = File::Spec->catfile(
    $repo_root,
    'isf',
    'atl_two_child_data_pipeline.isf',
);
my $two_child_vector_data_isf_file = File::Spec->catfile(
    $repo_root,
    'isf',
    'atl_two_child_vector_data_pipeline.isf',
);
my $two_child_multi_data_isf_file = File::Spec->catfile(
    $repo_root,
    'isf',
    'atl_two_child_multi_data_pipeline.isf',
);

subtest 'ATL resolved-child fixture lowers to parent, child, and generated top artifacts' => sub {
    my ($files, $report) = lower_atl_fixture();

    is_deeply(
        sorted([keys %$files]),
        [
            'atl_resolved_child_pipeline.fsm',
            'atl_resolved_child_pipeline__worker.fsm',
            'atl_resolved_child_pipeline_top.fsm',
        ],
        'lowering emits exactly the parent, resolved child, and generated ATL top FSM artifacts',
    );

    my $parent = $files->{'atl_resolved_child_pipeline.fsm'};
    like($parent, qr/\A\(\?fsm:atl_resolved_child_pipeline\b/, 'parent scheduled FSM uses the fixture module name');
    like($parent, qr/\(worker_done 1\)/, 'parent exposes the worker event handoff input');
    like($parent, qr/\(worker_process_start 1\)/, 'parent exposes the worker trigger handoff output');
    like($parent, qr/\brun_atl_trigger_1\b/, 'parent contains the trigger handoff state');
    like($parent, qr/\brun_await_2\b/, 'parent contains the event wait state');
    like($parent, qr/\(<1 \(worker_process_start> 1\)\)/, 'trigger state pulses the worker process handoff');
    like($parent, qr/\(<worker_done\s+\(-> run_done_3\)\s+\)/, 'await state waits for the worker done handoff');

    my $child = $files->{'atl_resolved_child_pipeline__worker.fsm'};
    like($child, qr/\A\(\?fsm:atl_resolved_child_pipeline__worker\b/, 'child scheduled FSM uses the resolved child module name');
    like($child, qr/\(process_start 1\)/, 'child keeps its authored process_start input');
    like($child, qr/\(done 1\)/, 'child keeps its authored done output');
    like($child, qr/\bprocess_idle_0\b/, 'child keeps its process transaction entry state');

    my $top = $files->{'atl_resolved_child_pipeline_top.fsm'};
    like($top, qr/\A\(\?top:atl_resolved_child_pipeline_top\b/, 'generated top uses the fixture top module name');
    like($top, qr/\(\?ports:public_io\s+clk\s+rst_n\s+start\s+done>\s+\)/s, 'generated top exposes only parent public pins plus clock/reset');
    like($top, qr/\(\?fsmc:atl_resolved_child_pipeline atl_resolved_child_pipeline\)/, 'generated top instantiates the scheduled parent');
    like($top, qr/\(\?fsmc:worker atl_resolved_child_pipeline__worker\)/, 'generated top instantiates the resolved child');
    like($top, qr/\(start atl_resolved_child_pipeline\.start\)/, 'generated top wires top start into the parent');
    like($top, qr/\(atl_resolved_child_pipeline\.done done\)/, 'generated top wires parent done to the top output');
    like($top, qr/\(atl_resolved_child_pipeline\.worker_process_start worker\.process_start\)/, 'generated top wires parent trigger handoff to the child transaction start input');
    like($top, qr/\(worker\.done atl_resolved_child_pipeline\.worker_done\)/, 'generated top wires child event pulse to the parent event handoff input');

    assert_report_shape($report);
};

subtest 'ATL pin-ingress fixture lowers scalar top input through parent into resolved child' => sub {
    my ($files, $report) = lower_atl_fixture($pin_ingress_isf_file);

    is_deeply(
        sorted([keys %$files]),
        [
            'atl_resolved_child_pin_ingress_pipeline.fsm',
            'atl_resolved_child_pin_ingress_pipeline__worker.fsm',
            'atl_resolved_child_pin_ingress_pipeline_top.fsm',
        ],
        'pin-ingress lowering emits exactly the parent, resolved child, and generated ATL top FSM artifacts',
    );

    my $parent = $files->{'atl_resolved_child_pin_ingress_pipeline.fsm'};
    like($parent, qr/\A\(\?fsm:atl_resolved_child_pin_ingress_pipeline\b/, 'pin-ingress parent uses the fixture module name');
    like($parent, qr/\(payload 1\)/, 'pin-ingress parent exposes the top payload input');
    like($parent, qr/\(worker_payload 1\)/, 'pin-ingress parent exposes the generated worker payload handoff');
    like($parent, qr/\brun_drive_1\b/, 'pin-ingress parent contains the drive-call state');
    like($parent, qr/\(= \(feed_worker_start 1\)\)/, 'pin-ingress drive-call state pulses the named drive enable');
    like($parent, qr/\(-feed_worker\s+\(<- \(worker_payload> payload\) <feed_worker_start\)\s+\)/s,
        'pin-ingress named drive transfers the top payload into the worker handoff');

    my $child = $files->{'atl_resolved_child_pin_ingress_pipeline__worker.fsm'};
    like($child, qr/\A\(\?fsm:atl_resolved_child_pin_ingress_pipeline__worker\b/,
        'pin-ingress child uses the resolved child module name');
    like($child, qr/\(\+interface\s+\(input payload\)\s+\)/s,
        'pin-ingress child preserves the declared payload input as an explicit generated interface role');
    like($child, qr/\(payload 1\)/, 'pin-ingress child keeps the payload size declaration');
    like($child, qr/\(process_start 1\)/, 'pin-ingress child keeps its authored process_start input');
    like($child, qr/\(done 1\)/, 'pin-ingress child keeps its authored done output');

    my $top = $files->{'atl_resolved_child_pin_ingress_pipeline_top.fsm'};
    like($top, qr/\A\(\?top:atl_resolved_child_pin_ingress_pipeline_top\b/,
        'pin-ingress generated top uses the fixture top module name');
    like($top, qr/\(\?ports:public_io\s+clk\s+rst_n\s+start\s+payload\s+done>\s+\)/s,
        'pin-ingress generated top exposes only parent public pins plus clock/reset');
    like($top, qr/\(payload atl_resolved_child_pin_ingress_pipeline\.payload\)/,
        'pin-ingress generated top wires top payload into the parent');
    like($top, qr/\(atl_resolved_child_pin_ingress_pipeline\.worker_payload worker\.payload\)/,
        'pin-ingress generated top wires the parent data handoff into the child payload input');
    like($top, qr/\(atl_resolved_child_pin_ingress_pipeline\.worker_process_start worker\.process_start\)/,
        'pin-ingress generated top wires parent trigger handoff to the child transaction start input');
    like($top, qr/\(worker\.done atl_resolved_child_pin_ingress_pipeline\.worker_done\)/,
        'pin-ingress generated top wires child event pulse to the parent event handoff input');

    assert_pin_ingress_report_shape($report);
};

subtest 'ATL pin-ingress vector fixture lowers exact-width top input through parent into resolved child' => sub {
    my ($files, $report) = lower_atl_fixture($pin_ingress_vector_isf_file);

    is_deeply(
        sorted([keys %$files]),
        [
            'atl_resolved_child_pin_ingress_vector_pipeline.fsm',
            'atl_resolved_child_pin_ingress_vector_pipeline__worker.fsm',
            'atl_resolved_child_pin_ingress_vector_pipeline_top.fsm',
        ],
        'pin-ingress vector lowering emits exactly the parent, resolved child, and generated ATL top FSM artifacts',
    );

    my $parent = $files->{'atl_resolved_child_pin_ingress_vector_pipeline.fsm'};
    like($parent, qr/\A\(\?fsm:atl_resolved_child_pin_ingress_vector_pipeline\b/,
        'pin-ingress vector parent uses the fixture module name');
    like($parent, qr/\(payload 8\)/, 'pin-ingress vector parent exposes the top payload input width');
    like($parent, qr/\(worker_payload 8\)/, 'pin-ingress vector parent exposes the generated worker payload handoff width');
    like($parent, qr/\brun_drive_1\b/, 'pin-ingress vector parent contains the drive-call state');
    like($parent, qr/\(= \(feed_worker_start 1\)\)/,
        'pin-ingress vector drive-call state pulses the named drive enable');
    like($parent, qr/\(-feed_worker\s+\(<- \(worker_payload> payload\) <feed_worker_start\)\s+\)/s,
        'pin-ingress vector named drive transfers the top payload into the worker handoff');

    my $child = $files->{'atl_resolved_child_pin_ingress_vector_pipeline__worker.fsm'};
    like($child, qr/\A\(\?fsm:atl_resolved_child_pin_ingress_vector_pipeline__worker\b/,
        'pin-ingress vector child uses the resolved child module name');
    like($child, qr/\(\+interface\s+\(input payload\)\s+\)/s,
        'pin-ingress vector child preserves the declared payload input as an explicit generated interface role');
    like($child, qr/\(payload 8\)/, 'pin-ingress vector child keeps the payload size declaration');
    like($child, qr/\(process_start 1\)/, 'pin-ingress vector child keeps its authored process_start input');
    like($child, qr/\(done 1\)/, 'pin-ingress vector child keeps its authored done output');

    my $top = $files->{'atl_resolved_child_pin_ingress_vector_pipeline_top.fsm'};
    like($top, qr/\A\(\?top:atl_resolved_child_pin_ingress_vector_pipeline_top\b/,
        'pin-ingress vector generated top uses the fixture top module name');
    like($top, qr/\(\?ports:public_io\s+clk\s+rst_n\s+start\s+payload<8\s+done>\s+\)/s,
        'pin-ingress vector generated top exposes only parent public pins plus clock/reset');
    like($top, qr/\(payload atl_resolved_child_pin_ingress_vector_pipeline\.payload\)/,
        'pin-ingress vector generated top wires top payload into the parent');
    like($top, qr/\(atl_resolved_child_pin_ingress_vector_pipeline\.worker_payload worker\.payload\)/,
        'pin-ingress vector generated top wires the parent data handoff into the child payload input');
    like($top, qr/\(atl_resolved_child_pin_ingress_vector_pipeline\.worker_process_start worker\.process_start\)/,
        'pin-ingress vector generated top wires parent trigger handoff to the child transaction start input');
    like($top, qr/\(worker\.done atl_resolved_child_pin_ingress_vector_pipeline\.worker_done\)/,
        'pin-ingress vector generated top wires child event pulse to the parent event handoff input');

    assert_pin_ingress_vector_report_shape($report);
};

subtest 'ATL pin-ingress multi-route fixture lowers multiple top inputs through parent into one resolved child' => sub {
    my ($files, $report) = lower_atl_fixture($pin_ingress_multi_isf_file);

    is_deeply(
        sorted([keys %$files]),
        [
            'atl_resolved_child_pin_ingress_multi_pipeline.fsm',
            'atl_resolved_child_pin_ingress_multi_pipeline__worker.fsm',
            'atl_resolved_child_pin_ingress_multi_pipeline_top.fsm',
        ],
        'pin-ingress multi-route lowering emits exactly the parent, resolved child, and generated ATL top FSM artifacts',
    );

    my $parent = $files->{'atl_resolved_child_pin_ingress_multi_pipeline.fsm'};
    like($parent, qr/\A\(\?fsm:atl_resolved_child_pin_ingress_multi_pipeline\b/,
        'pin-ingress multi-route parent uses the fixture module name');
    like($parent, qr/\(payload 1\)/,
        'pin-ingress multi-route parent exposes the top payload input');
    like($parent, qr/\(sideband 1\)/,
        'pin-ingress multi-route parent exposes the top sideband input');
    like($parent, qr/\(worker_payload 1\)/,
        'pin-ingress multi-route parent exposes the generated worker payload handoff');
    like($parent, qr/\(worker_sideband 1\)/,
        'pin-ingress multi-route parent exposes the generated worker sideband handoff');
    like($parent, qr/\brun_drive_1\b/,
        'pin-ingress multi-route parent contains the first drive-call state');
    like($parent, qr/\brun_drive_2\b/,
        'pin-ingress multi-route parent contains the second drive-call state');
    like($parent, qr/\brun_atl_trigger_3\b/,
        'pin-ingress multi-route parent triggers the child after both drive calls');
    like($parent, qr/\brun_await_4\b/,
        'pin-ingress multi-route parent waits for the child after the trigger');
    like($parent, qr/\(= \(feed_payload_start 1\)\)/,
        'pin-ingress multi-route first drive-call state pulses the payload route enable');
    like($parent, qr/\(= \(feed_sideband_start 1\)\)/,
        'pin-ingress multi-route second drive-call state pulses the sideband route enable');
    like($parent, qr/\(-feed_payload\s+\(<- \(worker_payload> payload\) <feed_payload_start\)\s+\)/s,
        'pin-ingress multi-route payload drive transfers the top payload into the worker handoff');
    like($parent, qr/\(-feed_sideband\s+\(<- \(worker_sideband> sideband\) <feed_sideband_start\)\s+\)/s,
        'pin-ingress multi-route sideband drive transfers the top sideband into the worker handoff');

    my $child = $files->{'atl_resolved_child_pin_ingress_multi_pipeline__worker.fsm'};
    like($child, qr/\A\(\?fsm:atl_resolved_child_pin_ingress_multi_pipeline__worker\b/,
        'pin-ingress multi-route child uses the resolved child module name');
    like($child, qr/\(\+interface\s+\(input payload\)\s+\(input sideband\)\s+\)/s,
        'pin-ingress multi-route child preserves both routed inputs as explicit generated interface roles');
    like($child, qr/\(payload 1\)/, 'pin-ingress multi-route child keeps the payload size declaration');
    like($child, qr/\(sideband 1\)/, 'pin-ingress multi-route child keeps the sideband size declaration');
    like($child, qr/\(process_start 1\)/, 'pin-ingress multi-route child keeps its authored process_start input');
    like($child, qr/\(done 1\)/, 'pin-ingress multi-route child keeps its authored done output');

    my $top = $files->{'atl_resolved_child_pin_ingress_multi_pipeline_top.fsm'};
    like($top, qr/\A\(\?top:atl_resolved_child_pin_ingress_multi_pipeline_top\b/,
        'pin-ingress multi-route generated top uses the fixture top module name');
    like($top, qr/\(\?ports:public_io\s+clk\s+rst_n\s+start\s+payload\s+sideband\s+done>\s+\)/s,
        'pin-ingress multi-route generated top exposes only parent public pins plus clock/reset');
    like($top, qr/\(payload atl_resolved_child_pin_ingress_multi_pipeline\.payload\)/,
        'pin-ingress multi-route generated top wires top payload into the parent');
    like($top, qr/\(sideband atl_resolved_child_pin_ingress_multi_pipeline\.sideband\)/,
        'pin-ingress multi-route generated top wires top sideband into the parent');
    like($top, qr/\(atl_resolved_child_pin_ingress_multi_pipeline\.worker_payload worker\.payload\)/,
        'pin-ingress multi-route generated top wires the parent payload handoff into the child');
    like($top, qr/\(atl_resolved_child_pin_ingress_multi_pipeline\.worker_sideband worker\.sideband\)/,
        'pin-ingress multi-route generated top wires the parent sideband handoff into the child');
    like($top, qr/\(atl_resolved_child_pin_ingress_multi_pipeline\.worker_process_start worker\.process_start\)/,
        'pin-ingress multi-route generated top wires parent trigger handoff to the child transaction start input');
    like($top, qr/\(worker\.done atl_resolved_child_pin_ingress_multi_pipeline\.worker_done\)/,
        'pin-ingress multi-route generated top wires child event pulse to the parent event handoff input');

    assert_pin_ingress_multi_report_shape($report);
};

subtest 'ATL pin-egress fixture lowers scalar resolved child output through parent to top output' => sub {
    my ($files, $report) = lower_atl_fixture($pin_egress_isf_file);

    is_deeply(
        sorted([keys %$files]),
        [
            'atl_resolved_child_pin_egress_pipeline.fsm',
            'atl_resolved_child_pin_egress_pipeline__worker.fsm',
            'atl_resolved_child_pin_egress_pipeline_top.fsm',
        ],
        'pin-egress lowering emits exactly the parent, resolved child, and generated ATL top FSM artifacts',
    );

    my $parent = $files->{'atl_resolved_child_pin_egress_pipeline.fsm'};
    like($parent, qr/\A\(\?fsm:atl_resolved_child_pin_egress_pipeline\b/,
        'pin-egress parent uses the fixture module name');
    like($parent, qr/\(result 1\)/, 'pin-egress parent preserves the top result output');
    like($parent, qr/\(worker_payload 1\)/, 'pin-egress parent exposes the generated worker payload source handoff');
    like($parent, qr/\brun_atl_trigger_1\b/, 'pin-egress parent triggers the child before waiting');
    like($parent, qr/\brun_await_2\b/, 'pin-egress parent waits for the child event before publishing');
    like($parent, qr/\brun_drive_3\b/, 'pin-egress parent contains the post-event drive-call state');
    like($parent, qr/\(= \(publish_result_start 1\)\)/, 'pin-egress drive-call state pulses the named drive enable');
    like($parent, qr/\(-publish_result\s+\(<- \(result> worker_payload\) <publish_result_start\)\s+\)/s,
        'pin-egress named drive transfers the worker handoff into the top result');

    my $child = $files->{'atl_resolved_child_pin_egress_pipeline__worker.fsm'};
    like($child, qr/\A\(\?fsm:atl_resolved_child_pin_egress_pipeline__worker\b/,
        'pin-egress child uses the resolved child module name');
    like($child, qr/\(\+interface\s+\(output payload\)\s+\)/s,
        'pin-egress child preserves the declared payload output as an explicit generated interface role');
    like($child, qr/\(payload 1\)/, 'pin-egress child keeps the payload size declaration');
    like($child, qr/\(process_start 1\)/, 'pin-egress child keeps its authored process_start input');
    like($child, qr/\(done 1\)/, 'pin-egress child keeps its authored done output');

    my $top = $files->{'atl_resolved_child_pin_egress_pipeline_top.fsm'};
    like($top, qr/\A\(\?top:atl_resolved_child_pin_egress_pipeline_top\b/,
        'pin-egress generated top uses the fixture top module name');
    like($top, qr/\(\?ports:public_io\s+clk\s+rst_n\s+start\s+result>\s+done>\s+\)/s,
        'pin-egress generated top exposes only parent public pins plus clock/reset');
    like($top, qr/\(atl_resolved_child_pin_egress_pipeline\.result result\)/,
        'pin-egress generated top wires parent result to the top result output');
    like($top, qr/\(worker\.payload atl_resolved_child_pin_egress_pipeline\.worker_payload\)/,
        'pin-egress generated top wires the child payload output into the parent handoff');
    like($top, qr/\(atl_resolved_child_pin_egress_pipeline\.worker_process_start worker\.process_start\)/,
        'pin-egress generated top wires parent trigger handoff to the child transaction start input');
    like($top, qr/\(worker\.done atl_resolved_child_pin_egress_pipeline\.worker_done\)/,
        'pin-egress generated top wires child event pulse to the parent event handoff input');

    assert_pin_egress_report_shape($report);
};

subtest 'ATL pin-egress multi-route fixture lowers multiple child outputs through parent to top outputs' => sub {
    my ($files, $report) = lower_atl_fixture($pin_egress_multi_isf_file);

    is_deeply(
        sorted([keys %$files]),
        [
            'atl_resolved_child_pin_egress_multi_pipeline.fsm',
            'atl_resolved_child_pin_egress_multi_pipeline__worker.fsm',
            'atl_resolved_child_pin_egress_multi_pipeline_top.fsm',
        ],
        'pin-egress multi-route lowering emits exactly the parent, resolved child, and generated ATL top FSM artifacts',
    );

    my $parent = $files->{'atl_resolved_child_pin_egress_multi_pipeline.fsm'};
    like($parent, qr/\A\(\?fsm:atl_resolved_child_pin_egress_multi_pipeline\b/,
        'pin-egress multi-route parent uses the fixture module name');
    like($parent, qr/\(result 1\)/,
        'pin-egress multi-route parent preserves the top result output');
    like($parent, qr/\(status 1\)/,
        'pin-egress multi-route parent preserves the top status output');
    like($parent, qr/\(worker_payload 1\)/,
        'pin-egress multi-route parent exposes the generated worker payload source handoff');
    like($parent, qr/\(worker_status 1\)/,
        'pin-egress multi-route parent exposes the generated worker status source handoff');
    like($parent, qr/\brun_atl_trigger_1\b/,
        'pin-egress multi-route parent triggers the child before waiting');
    like($parent, qr/\brun_await_2\b/,
        'pin-egress multi-route parent waits for the child event before publishing');
    like($parent, qr/\brun_drive_3\b/,
        'pin-egress multi-route parent contains the first post-event drive-call state');
    like($parent, qr/\brun_drive_4\b/,
        'pin-egress multi-route parent contains the second post-event drive-call state');
    like($parent, qr/\(= \(publish_result_start 1\)\)/,
        'pin-egress multi-route first drive-call state pulses the result route enable');
    like($parent, qr/\(= \(publish_status_start 1\)\)/,
        'pin-egress multi-route second drive-call state pulses the status route enable');
    like($parent, qr/\(-publish_result\s+\(<- \(result> worker_payload\) <publish_result_start\)\s+\)/s,
        'pin-egress multi-route result drive transfers the worker payload handoff into the top result');
    like($parent, qr/\(-publish_status\s+\(<- \(status> worker_status\) <publish_status_start\)\s+\)/s,
        'pin-egress multi-route status drive transfers the worker status handoff into the top status');

    my $child = $files->{'atl_resolved_child_pin_egress_multi_pipeline__worker.fsm'};
    like($child, qr/\A\(\?fsm:atl_resolved_child_pin_egress_multi_pipeline__worker\b/,
        'pin-egress multi-route child uses the resolved child module name');
    like($child, qr/\(\+interface\s+\(output payload\)\s+\(output status\)\s+\)/s,
        'pin-egress multi-route child preserves both routed outputs as explicit generated interface roles');
    like($child, qr/\(payload 1\)/, 'pin-egress multi-route child keeps the payload size declaration');
    like($child, qr/\(status 1\)/, 'pin-egress multi-route child keeps the status size declaration');
    like($child, qr/\(process_start 1\)/, 'pin-egress multi-route child keeps its authored process_start input');
    like($child, qr/\(done 1\)/, 'pin-egress multi-route child keeps its authored done output');

    my $top = $files->{'atl_resolved_child_pin_egress_multi_pipeline_top.fsm'};
    like($top, qr/\A\(\?top:atl_resolved_child_pin_egress_multi_pipeline_top\b/,
        'pin-egress multi-route generated top uses the fixture top module name');
    like($top, qr/\(\?ports:public_io\s+clk\s+rst_n\s+start\s+result>\s+status>\s+done>\s+\)/s,
        'pin-egress multi-route generated top exposes only parent public pins plus clock/reset');
    like($top, qr/\(atl_resolved_child_pin_egress_multi_pipeline\.result result\)/,
        'pin-egress multi-route generated top wires parent result to the top result output');
    like($top, qr/\(atl_resolved_child_pin_egress_multi_pipeline\.status status\)/,
        'pin-egress multi-route generated top wires parent status to the top status output');
    like($top, qr/\(worker\.payload atl_resolved_child_pin_egress_multi_pipeline\.worker_payload\)/,
        'pin-egress multi-route generated top wires the child payload output into the parent handoff');
    like($top, qr/\(worker\.status atl_resolved_child_pin_egress_multi_pipeline\.worker_status\)/,
        'pin-egress multi-route generated top wires the child status output into the parent handoff');
    like($top, qr/\(atl_resolved_child_pin_egress_multi_pipeline\.worker_process_start worker\.process_start\)/,
        'pin-egress multi-route generated top wires parent trigger handoff to the child transaction start input');
    like($top, qr/\(worker\.done atl_resolved_child_pin_egress_multi_pipeline\.worker_done\)/,
        'pin-egress multi-route generated top wires child event pulse to the parent event handoff input');

    assert_pin_egress_multi_report_shape($report);
};

subtest 'ATL two-child fixture lowers sequential trigger/event handoffs through one generated top' => sub {
    my ($files, $report) = lower_atl_fixture($two_child_isf_file);

    is_deeply(
        sorted([keys %$files]),
        [
            'atl_two_child_pipeline.fsm',
            'atl_two_child_pipeline__reader.fsm',
            'atl_two_child_pipeline__writer.fsm',
            'atl_two_child_pipeline_top.fsm',
        ],
        'two-child lowering emits exactly the parent, two resolved children, and generated ATL top FSM artifacts',
    );

    my $parent = $files->{'atl_two_child_pipeline.fsm'};
    like($parent, qr/\A\(\?fsm:atl_two_child_pipeline\b/, 'two-child parent uses the fixture module name');
    like($parent, qr/\(reader_capture_start 1\)/, 'two-child parent exposes the reader trigger handoff output');
    like($parent, qr/\(reader_done 1\)/, 'two-child parent exposes the reader event handoff input');
    like($parent, qr/\(writer_emit_start 1\)/, 'two-child parent exposes the writer trigger handoff output');
    like($parent, qr/\(writer_done 1\)/, 'two-child parent exposes the writer event handoff input');
    like($parent, qr/\brun_atl_trigger_1\b/, 'two-child parent contains the reader trigger state');
    like($parent, qr/\brun_await_2\b/, 'two-child parent contains the reader await state');
    like($parent, qr/\brun_atl_trigger_3\b/, 'two-child parent contains the writer trigger state');
    like($parent, qr/\brun_await_4\b/, 'two-child parent contains the writer await state');
    like($parent, qr/\(<1 \(reader_capture_start> 1\)\)/, 'reader trigger state pulses the reader capture handoff');
    like($parent, qr/\(<reader_done\s+\(-> run_atl_trigger_3\)\s+\)/,
        'reader await state advances to the writer trigger');
    like($parent, qr/\(<1 \(writer_emit_start> 1\)\)/, 'writer trigger state pulses the writer emit handoff');
    like($parent, qr/\(<writer_done\s+\(-> run_done_5\)\s+\)/,
        'writer await state advances to completion');

    my $reader = $files->{'atl_two_child_pipeline__reader.fsm'};
    like($reader, qr/\A\(\?fsm:atl_two_child_pipeline__reader\b/,
        'reader child uses the resolved reader module name');
    like($reader, qr/\(capture_start 1\)/, 'reader child keeps its authored capture_start input');
    like($reader, qr/\(done 1\)/, 'reader child keeps its authored done output');
    like($reader, qr/\bcapture_idle_0\b/, 'reader child keeps its capture transaction entry state');

    my $writer = $files->{'atl_two_child_pipeline__writer.fsm'};
    like($writer, qr/\A\(\?fsm:atl_two_child_pipeline__writer\b/,
        'writer child uses the resolved writer module name');
    like($writer, qr/\(emit_start 1\)/, 'writer child keeps its authored emit_start input');
    like($writer, qr/\(done 1\)/, 'writer child keeps its authored done output');
    like($writer, qr/\bemit_idle_0\b/, 'writer child keeps its emit transaction entry state');

    my $top = $files->{'atl_two_child_pipeline_top.fsm'};
    like($top, qr/\A\(\?top:atl_two_child_pipeline_top\b/, 'two-child generated top uses the fixture top module name');
    like($top, qr/\(\?ports:public_io\s+clk\s+rst_n\s+start\s+done>\s+\)/s,
        'two-child generated top exposes only parent public pins plus clock/reset');
    like($top, qr/\(\?fsmc:atl_two_child_pipeline atl_two_child_pipeline\)/,
        'two-child generated top instantiates the scheduled parent');
    like($top, qr/\(\?fsmc:reader atl_two_child_pipeline__reader\)/,
        'two-child generated top instantiates the resolved reader child');
    like($top, qr/\(\?fsmc:writer atl_two_child_pipeline__writer\)/,
        'two-child generated top instantiates the resolved writer child');
    like($top, qr/\(start atl_two_child_pipeline\.start\)/, 'two-child generated top wires top start into the parent');
    like($top, qr/\(atl_two_child_pipeline\.done done\)/, 'two-child generated top wires parent done to the top output');
    like($top, qr/\(atl_two_child_pipeline\.reader_capture_start reader\.capture_start\)/,
        'two-child generated top wires parent reader trigger handoff to the reader transaction start input');
    like($top, qr/\(reader\.done atl_two_child_pipeline\.reader_done\)/,
        'two-child generated top wires reader event pulse to the parent event handoff input');
    like($top, qr/\(atl_two_child_pipeline\.writer_emit_start writer\.emit_start\)/,
        'two-child generated top wires parent writer trigger handoff to the writer transaction start input');
    like($top, qr/\(writer\.done atl_two_child_pipeline\.writer_done\)/,
        'two-child generated top wires writer event pulse to the parent event handoff input');

    assert_two_child_report_shape($report);
};

subtest 'ATL two-child data fixture lowers a scalar generated-child actor-to-actor route' => sub {
    my ($files, $report) = lower_atl_fixture($two_child_data_isf_file);

    is_deeply(
        sorted([keys %$files]),
        [
            'atl_two_child_data_pipeline.fsm',
            'atl_two_child_data_pipeline__reader.fsm',
            'atl_two_child_data_pipeline__writer.fsm',
            'atl_two_child_data_pipeline_top.fsm',
        ],
        'two-child data lowering emits exactly the parent, reader, writer, and generated ATL top FSM artifacts',
    );

    my $parent = $files->{'atl_two_child_data_pipeline.fsm'};
    like($parent, qr/\A\(\?fsm:atl_two_child_data_pipeline\b/,
        'two-child data parent uses the fixture module name');
    like($parent, qr/\(reader_payload 1\)/,
        'two-child data parent exposes the generated reader payload source handoff');
    like($parent, qr/\(writer_payload 1\)/,
        'two-child data parent exposes the generated writer payload sink handoff');
    like($parent, qr/\brun_atl_trigger_1\b/,
        'two-child data parent contains the reader trigger state');
    like($parent, qr/\brun_await_2\b/,
        'two-child data parent contains the reader await state');
    like($parent, qr/\brun_drive_3\b/,
        'two-child data parent contains the drive-call state between reader and writer');
    like($parent, qr/\brun_atl_trigger_4\b/,
        'two-child data parent contains the writer trigger state after the drive');
    like($parent, qr/\brun_await_5\b/,
        'two-child data parent contains the writer await state');
    like($parent, qr/\(= \(forward_payload_start 1\)\)/,
        'two-child data drive-call state pulses the named drive enable');
    like($parent, qr/\(-forward_payload\s+\(<- \(writer_payload> reader_payload\) <forward_payload_start\)\s+\)/s,
        'two-child data named drive transfers the reader handoff into the writer handoff for the drive-call cycle');

    my $reader = $files->{'atl_two_child_data_pipeline__reader.fsm'};
    like($reader, qr/\A\(\?fsm:atl_two_child_data_pipeline__reader\b/,
        'two-child data reader child uses the resolved reader module name');
    like($reader, qr/\(\+interface\s+\(output payload\)\s+\)/s,
        'two-child data reader child preserves payload as an explicit generated output interface role');
    like($reader, qr/\(payload 1\)/, 'two-child data reader keeps the payload size declaration');
    like($reader, qr/\(capture_start 1\)/, 'two-child data reader keeps its authored capture_start input');
    like($reader, qr/\(done 1\)/, 'two-child data reader keeps its authored done output');

    my $writer = $files->{'atl_two_child_data_pipeline__writer.fsm'};
    like($writer, qr/\A\(\?fsm:atl_two_child_data_pipeline__writer\b/,
        'two-child data writer child uses the resolved writer module name');
    like($writer, qr/\(\+interface\s+\(input payload\)\s+\)/s,
        'two-child data writer child preserves payload as an explicit generated input interface role');
    like($writer, qr/\(payload 1\)/, 'two-child data writer keeps the payload size declaration');
    like($writer, qr/\(emit_start 1\)/, 'two-child data writer keeps its authored emit_start input');
    like($writer, qr/\(done 1\)/, 'two-child data writer keeps its authored done output');

    my $top = $files->{'atl_two_child_data_pipeline_top.fsm'};
    like($top, qr/\A\(\?top:atl_two_child_data_pipeline_top\b/,
        'two-child data generated top uses the fixture top module name');
    like($top, qr/\(\?ports:public_io\s+clk\s+rst_n\s+start\s+done>\s+\)/s,
        'two-child data generated top exposes only parent public pins plus clock/reset');
    like($top, qr/\(\?fsmc:atl_two_child_data_pipeline atl_two_child_data_pipeline\)/,
        'two-child data generated top instantiates the scheduled parent');
    like($top, qr/\(\?fsmc:reader atl_two_child_data_pipeline__reader\)/,
        'two-child data generated top instantiates the resolved reader child');
    like($top, qr/\(\?fsmc:writer atl_two_child_data_pipeline__writer\)/,
        'two-child data generated top instantiates the resolved writer child');
    like($top, qr/\(reader\.payload atl_two_child_data_pipeline\.reader_payload\)/,
        'two-child data generated top wires reader payload to the parent source handoff');
    like($top, qr/\(atl_two_child_data_pipeline\.writer_payload writer\.payload\)/,
        'two-child data generated top wires the parent sink handoff to writer payload');
    like($top, qr/\(atl_two_child_data_pipeline\.reader_capture_start reader\.capture_start\)/,
        'two-child data generated top wires parent reader trigger handoff to the reader');
    like($top, qr/\(reader\.done atl_two_child_data_pipeline\.reader_done\)/,
        'two-child data generated top wires reader done to the parent');
    like($top, qr/\(atl_two_child_data_pipeline\.writer_emit_start writer\.emit_start\)/,
        'two-child data generated top wires parent writer trigger handoff to the writer');
    like($top, qr/\(writer\.done atl_two_child_data_pipeline\.writer_done\)/,
        'two-child data generated top wires writer done to the parent');

    assert_two_child_data_report_shape($report);
};

subtest 'ATL two-child vector data fixture lowers an exact-width generated-child actor-to-actor route' => sub {
    my ($files, $report) = lower_atl_fixture($two_child_vector_data_isf_file);

    is_deeply(
        sorted([keys %$files]),
        [
            'atl_two_child_vector_data_pipeline.fsm',
            'atl_two_child_vector_data_pipeline__reader.fsm',
            'atl_two_child_vector_data_pipeline__writer.fsm',
            'atl_two_child_vector_data_pipeline_top.fsm',
        ],
        'two-child vector data lowering emits exactly the parent, reader, writer, and generated ATL top FSM artifacts',
    );

    my $parent = $files->{'atl_two_child_vector_data_pipeline.fsm'};
    like($parent, qr/\A\(\?fsm:atl_two_child_vector_data_pipeline\b/,
        'two-child vector data parent uses the fixture module name');
    like($parent, qr/\(reader_payload 8\)/,
        'two-child vector data parent exposes the generated reader payload source handoff at exact width');
    like($parent, qr/\(writer_payload 8\)/,
        'two-child vector data parent exposes the generated writer payload sink handoff at exact width');
    like($parent, qr/\brun_drive_3\b/,
        'two-child vector data parent contains the drive-call state between reader and writer');
    like($parent, qr/\(-forward_payload\s+\(<- \(writer_payload> reader_payload\) <forward_payload_start\)\s+\)/s,
        'two-child vector data named drive transfers the reader handoff into the writer handoff for the drive-call cycle');

    my $reader = $files->{'atl_two_child_vector_data_pipeline__reader.fsm'};
    like($reader, qr/\A\(\?fsm:atl_two_child_vector_data_pipeline__reader\b/,
        'two-child vector data reader child uses the resolved reader module name');
    like($reader, qr/\(\+interface\s+\(output payload\)\s+\)/s,
        'two-child vector data reader child preserves payload as an explicit generated output interface role');
    like($reader, qr/\(payload 8\)/, 'two-child vector data reader keeps the payload size declaration');

    my $writer = $files->{'atl_two_child_vector_data_pipeline__writer.fsm'};
    like($writer, qr/\A\(\?fsm:atl_two_child_vector_data_pipeline__writer\b/,
        'two-child vector data writer child uses the resolved writer module name');
    like($writer, qr/\(\+interface\s+\(input payload\)\s+\)/s,
        'two-child vector data writer child preserves payload as an explicit generated input interface role');
    like($writer, qr/\(payload 8\)/, 'two-child vector data writer keeps the payload size declaration');

    my $top = $files->{'atl_two_child_vector_data_pipeline_top.fsm'};
    like($top, qr/\A\(\?top:atl_two_child_vector_data_pipeline_top\b/,
        'two-child vector data generated top uses the fixture top module name');
    like($top, qr/\(reader\.payload atl_two_child_vector_data_pipeline\.reader_payload\)/,
        'two-child vector data generated top wires reader payload to the parent source handoff');
    like($top, qr/\(atl_two_child_vector_data_pipeline\.writer_payload writer\.payload\)/,
        'two-child vector data generated top wires the parent sink handoff to writer payload');
    like($top, qr/\(atl_two_child_vector_data_pipeline\.reader_capture_start reader\.capture_start\)/,
        'two-child vector data generated top wires parent reader trigger handoff to the reader');
    like($top, qr/\(reader\.done atl_two_child_vector_data_pipeline\.reader_done\)/,
        'two-child vector data generated top wires reader done to the parent');
    like($top, qr/\(atl_two_child_vector_data_pipeline\.writer_emit_start writer\.emit_start\)/,
        'two-child vector data generated top wires parent writer trigger handoff to the writer');
    like($top, qr/\(writer\.done atl_two_child_vector_data_pipeline\.writer_done\)/,
        'two-child vector data generated top wires writer done to the parent');

    assert_two_child_vector_data_report_shape($report);
};

subtest 'ATL two-child multi-data fixture lowers multiple same-source same-sink scalar routes' => sub {
    my ($files, $report) = lower_atl_fixture($two_child_multi_data_isf_file);

    is_deeply(
        sorted([keys %$files]),
        [
            'atl_two_child_multi_data_pipeline.fsm',
            'atl_two_child_multi_data_pipeline__reader.fsm',
            'atl_two_child_multi_data_pipeline__writer.fsm',
            'atl_two_child_multi_data_pipeline_top.fsm',
        ],
        'two-child multi-data lowering emits exactly the parent, reader, writer, and generated ATL top FSM artifacts',
    );

    my $parent = $files->{'atl_two_child_multi_data_pipeline.fsm'};
    like($parent, qr/\A\(\?fsm:atl_two_child_multi_data_pipeline\b/,
        'two-child multi-data parent uses the fixture module name');
    like($parent, qr/\(reader_payload 1\)/,
        'two-child multi-data parent exposes the generated reader payload source handoff');
    like($parent, qr/\(writer_payload 1\)/,
        'two-child multi-data parent exposes the generated writer payload sink handoff');
    like($parent, qr/\(reader_sideband 1\)/,
        'two-child multi-data parent exposes the generated reader sideband source handoff');
    like($parent, qr/\(writer_sideband 1\)/,
        'two-child multi-data parent exposes the generated writer sideband sink handoff');
    like($parent, qr/\brun_drive_3\b/,
        'two-child multi-data parent contains the first route drive-call state');
    like($parent, qr/\brun_drive_4\b/,
        'two-child multi-data parent contains the second route drive-call state');
    like($parent, qr/\brun_atl_trigger_5\b/,
        'two-child multi-data parent triggers the sink child after both route drive calls');
    like($parent, qr/\brun_await_6\b/,
        'two-child multi-data parent waits for the sink child after both route drive calls');
    like($parent, qr/\(= \(forward_payload_start 1\)\)/,
        'two-child multi-data first drive-call state pulses the payload route enable');
    like($parent, qr/\(= \(forward_sideband_start 1\)\)/,
        'two-child multi-data second drive-call state pulses the sideband route enable');
    like($parent, qr/\(-forward_payload\s+\(<- \(writer_payload> reader_payload\) <forward_payload_start\)\s+\)/s,
        'two-child multi-data payload route transfers reader payload into the writer payload handoff');
    like($parent, qr/\(-forward_sideband\s+\(<- \(writer_sideband> reader_sideband\) <forward_sideband_start\)\s+\)/s,
        'two-child multi-data sideband route transfers reader sideband into the writer sideband handoff');

    my $reader = $files->{'atl_two_child_multi_data_pipeline__reader.fsm'};
    like($reader, qr/\A\(\?fsm:atl_two_child_multi_data_pipeline__reader\b/,
        'two-child multi-data reader child uses the resolved reader module name');
    like($reader, qr/\(\+interface\s+\(output payload\)\s+\(output sideband\)\s+\)/s,
        'two-child multi-data reader child preserves both routed outputs as explicit generated interface roles');
    like($reader, qr/\(payload 1\)/, 'two-child multi-data reader keeps the payload size declaration');
    like($reader, qr/\(sideband 1\)/, 'two-child multi-data reader keeps the sideband size declaration');

    my $writer = $files->{'atl_two_child_multi_data_pipeline__writer.fsm'};
    like($writer, qr/\A\(\?fsm:atl_two_child_multi_data_pipeline__writer\b/,
        'two-child multi-data writer child uses the resolved writer module name');
    like($writer, qr/\(\+interface\s+\(input payload\)\s+\(input sideband\)\s+\)/s,
        'two-child multi-data writer child preserves both routed inputs as explicit generated interface roles');
    like($writer, qr/\(payload 1\)/, 'two-child multi-data writer keeps the payload size declaration');
    like($writer, qr/\(sideband 1\)/, 'two-child multi-data writer keeps the sideband size declaration');

    my $top = $files->{'atl_two_child_multi_data_pipeline_top.fsm'};
    like($top, qr/\A\(\?top:atl_two_child_multi_data_pipeline_top\b/,
        'two-child multi-data generated top uses the fixture top module name');
    like($top, qr/\(\?fsmc:reader atl_two_child_multi_data_pipeline__reader\)/,
        'two-child multi-data generated top instantiates the resolved reader child');
    like($top, qr/\(\?fsmc:writer atl_two_child_multi_data_pipeline__writer\)/,
        'two-child multi-data generated top instantiates the resolved writer child');
    like($top, qr/\(reader\.payload atl_two_child_multi_data_pipeline\.reader_payload\)/,
        'two-child multi-data generated top wires reader payload to the parent source handoff');
    like($top, qr/\(reader\.sideband atl_two_child_multi_data_pipeline\.reader_sideband\)/,
        'two-child multi-data generated top wires reader sideband to the parent source handoff');
    like($top, qr/\(atl_two_child_multi_data_pipeline\.writer_payload writer\.payload\)/,
        'two-child multi-data generated top wires the parent payload sink handoff to writer payload');
    like($top, qr/\(atl_two_child_multi_data_pipeline\.writer_sideband writer\.sideband\)/,
        'two-child multi-data generated top wires the parent sideband sink handoff to writer sideband');

    assert_two_child_multi_data_report_shape($report);
};

subtest 'ATL two-child data route stays valid when the route drive precedes actor instances' => sub {
    my ($files, $report) = lower_source(
        generated_child_actor_route_fixture({ drive_before_instances => 1 }),
        'atl_two_child_data_pipeline.isf',
    );

    is_deeply(
        sorted([keys %$files]),
        [
            'atl_two_child_data_pipeline.fsm',
            'atl_two_child_data_pipeline__reader.fsm',
            'atl_two_child_data_pipeline__writer.fsm',
            'atl_two_child_data_pipeline_top.fsm',
        ],
        'drive-before-instance route lowering emits the same parent, child, and top FSM artifacts',
    );

    my $parent = $files->{'atl_two_child_data_pipeline.fsm'};
    like($parent, qr/\(-forward_payload\s+\(<- \(writer_payload> reader_payload\) <forward_payload_start\)\s+\)/s,
        'drive-before-instance route keeps the same scalar parent data handoff');

    my $top = $files->{'atl_two_child_data_pipeline_top.fsm'};
    like($top, qr/\(reader\.payload atl_two_child_data_pipeline\.reader_payload\)/,
        'drive-before-instance route wires reader payload to the parent source handoff');
    like($top, qr/\(atl_two_child_data_pipeline\.writer_payload writer\.payload\)/,
        'drive-before-instance route wires the parent sink handoff to writer payload');

    assert_two_child_data_report_shape($report);
};

subtest 'ATL resolved-child fixture strict schedule JSON matches the in-process report' => sub {
    my (undef, $in_process_report) = lower_atl_fixture();
    my ($success, $stdout, $stderr) = run_cli(
        [
            './bin/fsmgen',
            '--strict',
            '--quiet',
            '--emit-schedule-json',
            $isf_file,
        ],
        'strict schedule JSON generation',
    );

    ok($success, 'strict schedule JSON generation succeeds for the ATL resolved-child fixture');
    is($stderr, '', 'strict schedule JSON generation keeps stderr clean');
    is_deeply(
        decode_json($stdout),
        $in_process_report,
        'strict schedule JSON generation matches the in-process report',
    );
};

subtest 'ATL pin-ingress fixture strict schedule JSON matches the in-process report' => sub {
    my (undef, $in_process_report) = lower_atl_fixture($pin_ingress_isf_file);
    my ($success, $stdout, $stderr) = run_cli(
        [
            './bin/fsmgen',
            '--strict',
            '--quiet',
            '--emit-schedule-json',
            $pin_ingress_isf_file,
        ],
        'pin-ingress strict schedule JSON generation',
    );

    ok($success, 'strict schedule JSON generation succeeds for the ATL pin-ingress fixture');
    is($stderr, '', 'pin-ingress strict schedule JSON generation keeps stderr clean');
    is_deeply(
        decode_json($stdout),
        $in_process_report,
        'pin-ingress strict schedule JSON generation matches the in-process report',
    );
};

subtest 'ATL pin-ingress vector fixture strict schedule JSON matches the in-process report' => sub {
    my (undef, $in_process_report) = lower_atl_fixture($pin_ingress_vector_isf_file);
    my ($success, $stdout, $stderr) = run_cli(
        [
            './bin/fsmgen',
            '--strict',
            '--quiet',
            '--emit-schedule-json',
            $pin_ingress_vector_isf_file,
        ],
        'pin-ingress vector strict schedule JSON generation',
    );

    ok($success, 'strict schedule JSON generation succeeds for the ATL pin-ingress vector fixture');
    is($stderr, '', 'pin-ingress vector strict schedule JSON generation keeps stderr clean');
    is_deeply(
        decode_json($stdout),
        $in_process_report,
        'pin-ingress vector strict schedule JSON generation matches the in-process report',
    );
};

subtest 'ATL pin-ingress multi-route fixture strict schedule JSON matches the in-process report' => sub {
    my (undef, $in_process_report) = lower_atl_fixture($pin_ingress_multi_isf_file);
    my ($success, $stdout, $stderr) = run_cli(
        [
            './bin/fsmgen',
            '--strict',
            '--quiet',
            '--emit-schedule-json',
            $pin_ingress_multi_isf_file,
        ],
        'pin-ingress multi-route strict schedule JSON generation',
    );

    ok($success, 'strict schedule JSON generation succeeds for the ATL pin-ingress multi-route fixture');
    is($stderr, '', 'pin-ingress multi-route strict schedule JSON generation keeps stderr clean');
    is_deeply(
        decode_json($stdout),
        $in_process_report,
        'pin-ingress multi-route strict schedule JSON generation matches the in-process report',
    );
};

subtest 'ATL pin-egress fixture strict schedule JSON matches the in-process report' => sub {
    my (undef, $in_process_report) = lower_atl_fixture($pin_egress_isf_file);
    my ($success, $stdout, $stderr) = run_cli(
        [
            './bin/fsmgen',
            '--strict',
            '--quiet',
            '--emit-schedule-json',
            $pin_egress_isf_file,
        ],
        'pin-egress strict schedule JSON generation',
    );

    ok($success, 'strict schedule JSON generation succeeds for the ATL pin-egress fixture');
    is($stderr, '', 'pin-egress strict schedule JSON generation keeps stderr clean');
    is_deeply(
        decode_json($stdout),
        $in_process_report,
        'pin-egress strict schedule JSON generation matches the in-process report',
    );
};

subtest 'ATL pin-egress multi-route fixture strict schedule JSON matches the in-process report' => sub {
    my (undef, $in_process_report) = lower_atl_fixture($pin_egress_multi_isf_file);
    my ($success, $stdout, $stderr) = run_cli(
        [
            './bin/fsmgen',
            '--strict',
            '--quiet',
            '--emit-schedule-json',
            $pin_egress_multi_isf_file,
        ],
        'pin-egress multi-route strict schedule JSON generation',
    );

    ok($success, 'strict schedule JSON generation succeeds for the ATL pin-egress multi-route fixture');
    is($stderr, '', 'pin-egress multi-route strict schedule JSON generation keeps stderr clean');
    is_deeply(
        decode_json($stdout),
        $in_process_report,
        'pin-egress multi-route strict schedule JSON generation matches the in-process report',
    );
};

subtest 'ATL two-child fixture strict schedule JSON matches the in-process report' => sub {
    my (undef, $in_process_report) = lower_atl_fixture($two_child_isf_file);
    my ($success, $stdout, $stderr) = run_cli(
        [
            './bin/fsmgen',
            '--strict',
            '--quiet',
            '--emit-schedule-json',
            $two_child_isf_file,
        ],
        'two-child strict schedule JSON generation',
    );

    ok($success, 'strict schedule JSON generation succeeds for the ATL two-child fixture');
    is($stderr, '', 'two-child strict schedule JSON generation keeps stderr clean');
    is_deeply(
        decode_json($stdout),
        $in_process_report,
        'two-child strict schedule JSON generation matches the in-process report',
    );
};

subtest 'ATL two-child data fixture strict schedule JSON matches the in-process report' => sub {
    my (undef, $in_process_report) = lower_atl_fixture($two_child_data_isf_file);
    my ($success, $stdout, $stderr) = run_cli(
        [
            './bin/fsmgen',
            '--strict',
            '--quiet',
            '--emit-schedule-json',
            $two_child_data_isf_file,
        ],
        'two-child data strict schedule JSON generation',
    );

    ok($success, 'strict schedule JSON generation succeeds for the ATL two-child data fixture');
    is($stderr, '', 'two-child data strict schedule JSON generation keeps stderr clean');
    is_deeply(
        decode_json($stdout),
        $in_process_report,
        'two-child data strict schedule JSON generation matches the in-process report',
    );
};

subtest 'ATL two-child vector data fixture strict schedule JSON matches the in-process report' => sub {
    my (undef, $in_process_report) = lower_atl_fixture($two_child_vector_data_isf_file);
    my ($success, $stdout, $stderr) = run_cli(
        [
            './bin/fsmgen',
            '--strict',
            '--quiet',
            '--emit-schedule-json',
            $two_child_vector_data_isf_file,
        ],
        'two-child vector data strict schedule JSON generation',
    );

    ok($success, 'strict schedule JSON generation succeeds for the ATL two-child vector data fixture');
    is($stderr, '', 'two-child vector data strict schedule JSON generation keeps stderr clean');
    is_deeply(
        decode_json($stdout),
        $in_process_report,
        'two-child vector data strict schedule JSON generation matches the in-process report',
    );
};

subtest 'ATL two-child multi-data fixture strict schedule JSON matches the in-process report' => sub {
    my (undef, $in_process_report) = lower_atl_fixture($two_child_multi_data_isf_file);
    my ($success, $stdout, $stderr) = run_cli(
        [
            './bin/fsmgen',
            '--strict',
            '--quiet',
            '--emit-schedule-json',
            $two_child_multi_data_isf_file,
        ],
        'two-child multi-data strict schedule JSON generation',
    );

    ok($success, 'strict schedule JSON generation succeeds for the ATL two-child multi-data fixture');
    is($stderr, '', 'two-child multi-data strict schedule JSON generation keeps stderr clean');
    is_deeply(
        decode_json($stdout),
        $in_process_report,
        'two-child multi-data strict schedule JSON generation matches the in-process report',
    );
};

subtest 'ATL resolved-child fixture strict outdir lowering writes the generated top' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my ($success, $stdout, $stderr) = run_cli(
        [
            './bin/fsmgen',
            '--strict',
            '--quiet',
            '--outdir',
            $dir,
            $isf_file,
        ],
        'strict outdir lowering',
    );

    ok($success, 'strict outdir lowering succeeds for the ATL resolved-child fixture');
    like($stdout, qr/Wrote: .*atl_resolved_child_pipeline_top\.fsm/, 'strict outdir lowering reports the written generated top');
    is($stderr, '', 'strict outdir lowering keeps stderr clean');
    is_deeply(
        sorted([fsm_basenames_in($dir)]),
        [
            'atl_resolved_child_pipeline.fsm',
            'atl_resolved_child_pipeline__worker.fsm',
            'atl_resolved_child_pipeline_top.fsm',
        ],
        'strict outdir lowering writes the parent, resolved child, and generated top files',
    );
};

subtest 'ATL pin-ingress fixture strict outdir lowering writes the generated top' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my ($success, $stdout, $stderr) = run_cli(
        [
            './bin/fsmgen',
            '--strict',
            '--quiet',
            '--outdir',
            $dir,
            $pin_ingress_isf_file,
        ],
        'pin-ingress strict outdir lowering',
    );

    ok($success, 'strict outdir lowering succeeds for the ATL pin-ingress fixture');
    like($stdout, qr/Wrote: .*atl_resolved_child_pin_ingress_pipeline_top\.fsm/,
        'pin-ingress strict outdir lowering reports the written generated top');
    is($stderr, '', 'pin-ingress strict outdir lowering keeps stderr clean');
    is_deeply(
        sorted([fsm_basenames_in($dir)]),
        expected_fsm_basenames_for_source($pin_ingress_isf_file),
        'pin-ingress strict outdir lowering writes the parent, resolved child, and generated top files',
    );
};

subtest 'ATL pin-ingress vector fixture strict outdir lowering writes the generated top' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my ($success, $stdout, $stderr) = run_cli(
        [
            './bin/fsmgen',
            '--strict',
            '--quiet',
            '--outdir',
            $dir,
            $pin_ingress_vector_isf_file,
        ],
        'pin-ingress vector strict outdir lowering',
    );

    ok($success, 'strict outdir lowering succeeds for the ATL pin-ingress vector fixture');
    like($stdout, qr/Wrote: .*atl_resolved_child_pin_ingress_vector_pipeline_top\.fsm/,
        'pin-ingress vector strict outdir lowering reports the written generated top');
    is($stderr, '', 'pin-ingress vector strict outdir lowering keeps stderr clean');
    is_deeply(
        sorted([fsm_basenames_in($dir)]),
        expected_fsm_basenames_for_source($pin_ingress_vector_isf_file),
        'pin-ingress vector strict outdir lowering writes the parent, resolved child, and generated top files',
    );
};

subtest 'ATL pin-ingress multi-route fixture strict outdir lowering writes the generated top' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my ($success, $stdout, $stderr) = run_cli(
        [
            './bin/fsmgen',
            '--strict',
            '--quiet',
            '--outdir',
            $dir,
            $pin_ingress_multi_isf_file,
        ],
        'pin-ingress multi-route strict outdir lowering',
    );

    ok($success, 'strict outdir lowering succeeds for the ATL pin-ingress multi-route fixture');
    like($stdout, qr/Wrote: .*atl_resolved_child_pin_ingress_multi_pipeline_top\.fsm/,
        'pin-ingress multi-route strict outdir lowering reports the written generated top');
    is($stderr, '', 'pin-ingress multi-route strict outdir lowering keeps stderr clean');
    is_deeply(
        sorted([fsm_basenames_in($dir)]),
        expected_fsm_basenames_for_source($pin_ingress_multi_isf_file),
        'pin-ingress multi-route strict outdir lowering writes the parent, resolved child, and generated top files',
    );
};

subtest 'ATL pin-egress fixture strict outdir lowering writes the generated top' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my ($success, $stdout, $stderr) = run_cli(
        [
            './bin/fsmgen',
            '--strict',
            '--quiet',
            '--outdir',
            $dir,
            $pin_egress_isf_file,
        ],
        'pin-egress strict outdir lowering',
    );

    ok($success, 'strict outdir lowering succeeds for the ATL pin-egress fixture');
    like($stdout, qr/Wrote: .*atl_resolved_child_pin_egress_pipeline_top\.fsm/,
        'pin-egress strict outdir lowering reports the written generated top');
    is($stderr, '', 'pin-egress strict outdir lowering keeps stderr clean');
    is_deeply(
        sorted([fsm_basenames_in($dir)]),
        expected_fsm_basenames_for_source($pin_egress_isf_file),
        'pin-egress strict outdir lowering writes the parent, resolved child, and generated top files',
    );
};

subtest 'ATL pin-egress multi-route fixture strict outdir lowering writes the generated top' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my ($success, $stdout, $stderr) = run_cli(
        [
            './bin/fsmgen',
            '--strict',
            '--quiet',
            '--outdir',
            $dir,
            $pin_egress_multi_isf_file,
        ],
        'pin-egress multi-route strict outdir lowering',
    );

    ok($success, 'strict outdir lowering succeeds for the ATL pin-egress multi-route fixture');
    like($stdout, qr/Wrote: .*atl_resolved_child_pin_egress_multi_pipeline_top\.fsm/,
        'pin-egress multi-route strict outdir lowering reports the written generated top');
    is($stderr, '', 'pin-egress multi-route strict outdir lowering keeps stderr clean');
    is_deeply(
        sorted([fsm_basenames_in($dir)]),
        expected_fsm_basenames_for_source($pin_egress_multi_isf_file),
        'pin-egress multi-route strict outdir lowering writes the parent, resolved child, and generated top files',
    );
};

subtest 'ATL two-child fixture strict outdir lowering writes the generated top' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my ($success, $stdout, $stderr) = run_cli(
        [
            './bin/fsmgen',
            '--strict',
            '--quiet',
            '--outdir',
            $dir,
            $two_child_isf_file,
        ],
        'two-child strict outdir lowering',
    );

    ok($success, 'strict outdir lowering succeeds for the ATL two-child fixture');
    like($stdout, qr/Wrote: .*atl_two_child_pipeline_top\.fsm/,
        'two-child strict outdir lowering reports the written generated top');
    is($stderr, '', 'two-child strict outdir lowering keeps stderr clean');
    is_deeply(
        sorted([fsm_basenames_in($dir)]),
        expected_fsm_basenames_for_source($two_child_isf_file),
        'two-child strict outdir lowering writes the parent, resolved children, and generated top files',
    );
};

subtest 'ATL two-child data fixture strict outdir lowering writes the generated top' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my ($success, $stdout, $stderr) = run_cli(
        [
            './bin/fsmgen',
            '--strict',
            '--quiet',
            '--outdir',
            $dir,
            $two_child_data_isf_file,
        ],
        'two-child data strict outdir lowering',
    );

    ok($success, 'strict outdir lowering succeeds for the ATL two-child data fixture');
    like($stdout, qr/Wrote: .*atl_two_child_data_pipeline_top\.fsm/,
        'two-child data strict outdir lowering reports the written generated top');
    is($stderr, '', 'two-child data strict outdir lowering keeps stderr clean');
    is_deeply(
        sorted([fsm_basenames_in($dir)]),
        expected_fsm_basenames_for_source($two_child_data_isf_file),
        'two-child data strict outdir lowering writes the parent, resolved children, and generated top files',
    );
};

subtest 'ATL two-child vector data fixture strict outdir lowering writes the generated top' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my ($success, $stdout, $stderr) = run_cli(
        [
            './bin/fsmgen',
            '--strict',
            '--quiet',
            '--outdir',
            $dir,
            $two_child_vector_data_isf_file,
        ],
        'two-child vector data strict outdir lowering',
    );

    ok($success, 'strict outdir lowering succeeds for the ATL two-child vector data fixture');
    like($stdout, qr/Wrote: .*atl_two_child_vector_data_pipeline_top\.fsm/,
        'two-child vector data strict outdir lowering reports the written generated top');
    is($stderr, '', 'two-child vector data strict outdir lowering keeps stderr clean');
    is_deeply(
        sorted([fsm_basenames_in($dir)]),
        expected_fsm_basenames_for_source($two_child_vector_data_isf_file),
        'two-child vector data strict outdir lowering writes the parent, resolved children, and generated top files',
    );
};

subtest 'ATL two-child multi-data fixture strict outdir lowering writes the generated top' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my ($success, $stdout, $stderr) = run_cli(
        [
            './bin/fsmgen',
            '--strict',
            '--quiet',
            '--outdir',
            $dir,
            $two_child_multi_data_isf_file,
        ],
        'two-child multi-data strict outdir lowering',
    );

    ok($success, 'strict outdir lowering succeeds for the ATL two-child multi-data fixture');
    like($stdout, qr/Wrote: .*atl_two_child_multi_data_pipeline_top\.fsm/,
        'two-child multi-data strict outdir lowering reports the written generated top');
    is($stderr, '', 'two-child multi-data strict outdir lowering keeps stderr clean');
    is_deeply(
        sorted([fsm_basenames_in($dir)]),
        expected_fsm_basenames_for_source($two_child_multi_data_isf_file),
        'two-child multi-data strict outdir lowering writes the parent, resolved children, and generated top files',
    );
};

subtest 'ATL resolved-child fixture reaches generated-top HDL generation' => sub {
    my $plain_dir = tempdir(CLEANUP => 1);
    my $plain_hdl = File::Spec->catfile($plain_dir, 'atl_resolved_child_pipeline_plain.sv');
    my $plain = generate_hdl($plain_hdl, [], 'plain HDL generation');

    assert_generated_top_hdl($plain, 'plain HDL');

    my $strict_dir = tempdir(CLEANUP => 1);
    my $strict_hdl = File::Spec->catfile($strict_dir, 'atl_resolved_child_pipeline_strict.sv');
    my $strict = generate_hdl($strict_hdl, ['--strict'], 'strict HDL generation');

    assert_generated_top_hdl($strict, 'strict HDL');
};

subtest 'ATL pin-ingress fixture reaches generated-top HDL generation' => sub {
    my $plain_dir = tempdir(CLEANUP => 1);
    my $plain_hdl = File::Spec->catfile($plain_dir, 'atl_resolved_child_pin_ingress_pipeline_plain.sv');
    my $plain = generate_hdl(
        $plain_hdl,
        [],
        'pin-ingress plain HDL generation',
        $pin_ingress_isf_file,
    );

    assert_pin_ingress_generated_top_hdl($plain, 'pin-ingress plain HDL');

    my $strict_dir = tempdir(CLEANUP => 1);
    my $strict_hdl = File::Spec->catfile($strict_dir, 'atl_resolved_child_pin_ingress_pipeline_strict.sv');
    my $strict = generate_hdl(
        $strict_hdl,
        ['--strict'],
        'pin-ingress strict HDL generation',
        $pin_ingress_isf_file,
    );

    assert_pin_ingress_generated_top_hdl($strict, 'pin-ingress strict HDL');
};

subtest 'ATL pin-ingress vector fixture reaches generated-top HDL generation' => sub {
    my $plain_dir = tempdir(CLEANUP => 1);
    my $plain_hdl = File::Spec->catfile($plain_dir, 'atl_resolved_child_pin_ingress_vector_pipeline_plain.sv');
    my $plain = generate_hdl(
        $plain_hdl,
        [],
        'pin-ingress vector plain HDL generation',
        $pin_ingress_vector_isf_file,
    );

    assert_pin_ingress_vector_generated_top_hdl($plain, 'pin-ingress vector plain HDL');

    my $strict_dir = tempdir(CLEANUP => 1);
    my $strict_hdl = File::Spec->catfile($strict_dir, 'atl_resolved_child_pin_ingress_vector_pipeline_strict.sv');
    my $strict = generate_hdl(
        $strict_hdl,
        ['--strict'],
        'pin-ingress vector strict HDL generation',
        $pin_ingress_vector_isf_file,
    );

    assert_pin_ingress_vector_generated_top_hdl($strict, 'pin-ingress vector strict HDL');
};

subtest 'ATL pin-ingress multi-route fixture reaches generated-top HDL generation' => sub {
    my $plain_dir = tempdir(CLEANUP => 1);
    my $plain_hdl = File::Spec->catfile($plain_dir, 'atl_resolved_child_pin_ingress_multi_pipeline_plain.sv');
    my $plain = generate_hdl(
        $plain_hdl,
        [],
        'pin-ingress multi-route plain HDL generation',
        $pin_ingress_multi_isf_file,
    );

    assert_pin_ingress_multi_generated_top_hdl($plain, 'pin-ingress multi-route plain HDL');

    my $strict_dir = tempdir(CLEANUP => 1);
    my $strict_hdl = File::Spec->catfile($strict_dir, 'atl_resolved_child_pin_ingress_multi_pipeline_strict.sv');
    my $strict = generate_hdl(
        $strict_hdl,
        ['--strict'],
        'pin-ingress multi-route strict HDL generation',
        $pin_ingress_multi_isf_file,
    );

    assert_pin_ingress_multi_generated_top_hdl($strict, 'pin-ingress multi-route strict HDL');
};

subtest 'ATL pin-egress fixture reaches generated-top HDL generation' => sub {
    my $plain_dir = tempdir(CLEANUP => 1);
    my $plain_hdl = File::Spec->catfile($plain_dir, 'atl_resolved_child_pin_egress_pipeline_plain.sv');
    my $plain = generate_hdl(
        $plain_hdl,
        [],
        'pin-egress plain HDL generation',
        $pin_egress_isf_file,
    );

    assert_pin_egress_generated_top_hdl($plain, 'pin-egress plain HDL');

    my $strict_dir = tempdir(CLEANUP => 1);
    my $strict_hdl = File::Spec->catfile($strict_dir, 'atl_resolved_child_pin_egress_pipeline_strict.sv');
    my $strict = generate_hdl(
        $strict_hdl,
        ['--strict'],
        'pin-egress strict HDL generation',
        $pin_egress_isf_file,
    );

    assert_pin_egress_generated_top_hdl($strict, 'pin-egress strict HDL');
};

subtest 'ATL pin-egress multi-route fixture reaches generated-top HDL generation' => sub {
    my $plain_dir = tempdir(CLEANUP => 1);
    my $plain_hdl = File::Spec->catfile($plain_dir, 'atl_resolved_child_pin_egress_multi_pipeline_plain.sv');
    my $plain = generate_hdl(
        $plain_hdl,
        [],
        'pin-egress multi-route plain HDL generation',
        $pin_egress_multi_isf_file,
    );

    assert_pin_egress_multi_generated_top_hdl($plain, 'pin-egress multi-route plain HDL');

    my $strict_dir = tempdir(CLEANUP => 1);
    my $strict_hdl = File::Spec->catfile($strict_dir, 'atl_resolved_child_pin_egress_multi_pipeline_strict.sv');
    my $strict = generate_hdl(
        $strict_hdl,
        ['--strict'],
        'pin-egress multi-route strict HDL generation',
        $pin_egress_multi_isf_file,
    );

    assert_pin_egress_multi_generated_top_hdl($strict, 'pin-egress multi-route strict HDL');
};

subtest 'ATL two-child fixture reaches generated-top HDL generation' => sub {
    my $plain_dir = tempdir(CLEANUP => 1);
    my $plain_hdl = File::Spec->catfile($plain_dir, 'atl_two_child_pipeline_plain.sv');
    my $plain = generate_hdl(
        $plain_hdl,
        [],
        'two-child plain HDL generation',
        $two_child_isf_file,
    );

    assert_two_child_generated_top_hdl($plain, 'two-child plain HDL');

    my $strict_dir = tempdir(CLEANUP => 1);
    my $strict_hdl = File::Spec->catfile($strict_dir, 'atl_two_child_pipeline_strict.sv');
    my $strict = generate_hdl(
        $strict_hdl,
        ['--strict'],
        'two-child strict HDL generation',
        $two_child_isf_file,
    );

    assert_two_child_generated_top_hdl($strict, 'two-child strict HDL');
};

subtest 'ATL two-child data fixture reaches generated-top HDL generation' => sub {
    my $plain_dir = tempdir(CLEANUP => 1);
    my $plain_hdl = File::Spec->catfile($plain_dir, 'atl_two_child_data_pipeline_plain.sv');
    my $plain = generate_hdl(
        $plain_hdl,
        [],
        'two-child data plain HDL generation',
        $two_child_data_isf_file,
    );

    assert_two_child_data_generated_top_hdl($plain, 'two-child data plain HDL');

    my $strict_dir = tempdir(CLEANUP => 1);
    my $strict_hdl = File::Spec->catfile($strict_dir, 'atl_two_child_data_pipeline_strict.sv');
    my $strict = generate_hdl(
        $strict_hdl,
        ['--strict'],
        'two-child data strict HDL generation',
        $two_child_data_isf_file,
    );

    assert_two_child_data_generated_top_hdl($strict, 'two-child data strict HDL');
};

subtest 'ATL two-child vector data fixture reaches generated-top HDL generation' => sub {
    my $plain_dir = tempdir(CLEANUP => 1);
    my $plain_hdl = File::Spec->catfile($plain_dir, 'atl_two_child_vector_data_pipeline_plain.sv');
    my $plain = generate_hdl(
        $plain_hdl,
        [],
        'two-child vector data plain HDL generation',
        $two_child_vector_data_isf_file,
    );
    assert_two_child_vector_data_generated_top_hdl($plain, 'two-child vector data plain HDL');

    my $strict_dir = tempdir(CLEANUP => 1);
    my $strict_hdl = File::Spec->catfile($strict_dir, 'atl_two_child_vector_data_pipeline_strict.sv');
    my $strict = generate_hdl(
        $strict_hdl,
        ['--strict'],
        'two-child vector data strict HDL generation',
        $two_child_vector_data_isf_file,
    );
    assert_two_child_vector_data_generated_top_hdl($strict, 'two-child vector data strict HDL');
};

subtest 'ATL two-child multi-data fixture reaches generated-top HDL generation' => sub {
    my $plain_dir = tempdir(CLEANUP => 1);
    my $plain_hdl = File::Spec->catfile($plain_dir, 'atl_two_child_multi_data_pipeline_plain.sv');
    my $plain = generate_hdl(
        $plain_hdl,
        [],
        'two-child multi-data plain HDL generation',
        $two_child_multi_data_isf_file,
    );

    assert_two_child_multi_data_generated_top_hdl($plain, 'two-child multi-data plain HDL');

    my $strict_dir = tempdir(CLEANUP => 1);
    my $strict_hdl = File::Spec->catfile($strict_dir, 'atl_two_child_multi_data_pipeline_strict.sv');
    my $strict = generate_hdl(
        $strict_hdl,
        ['--strict'],
        'two-child multi-data strict HDL generation',
        $two_child_multi_data_isf_file,
    );

    assert_two_child_multi_data_generated_top_hdl($strict, 'two-child multi-data strict HDL');
};

subtest 'ATL generated top fail-closed boundary rejects unsupported child wiring shapes' => sub {
    lower_source_fails_like(
        atl_fixture_variant(<<'LIBRARY'),
(library common.packet
  (exports
    (actor packet_worker))
  (actor packet_worker
    (clock clk)
    (reset (rst_n async active_low))
    (interface
      (input process_start)
      (output done))
    (transaction other
      (on process_start)
      (complete done))))
LIBRARY
        qr/trigger targets missing child transaction 'process'/,
        'missing child target transaction fails closed',
    );

    lower_source_fails_like(
        atl_fixture_variant(<<'LIBRARY'),
(library common.packet
  (exports
    (actor packet_worker))
  (actor packet_worker
    (clock clk)
    (reset (rst_n async active_low))
    (interface
      (input process_start)
      (output done))
    (transaction process
      (on (== process_start 1))
      (complete done))))
LIBRARY
        qr/on requires '\(on port \[sample\.\.\.\]\)'/,
        'non-scalar child transaction on condition fails closed',
    );

    lower_source_fails_like(
        atl_fixture_variant(<<'LIBRARY'),
(library common.packet
  (exports
    (actor packet_worker))
  (actor packet_worker
    (clock clk)
    (reset (rst_n async active_low))
    (interface
      (input process_start)
      (output finished))
    (transaction process
      (on process_start)
      (complete finished))))
LIBRARY
        qr/event 'done' is not a scalar child output port/,
        'missing child event output fails closed',
    );

    lower_source_fails_like(
        atl_fixture_variant(<<'LIBRARY'),
(library common.packet
  (exports
    (actor packet_worker))
  (actor packet_worker
    (clock child_clk)
    (reset (rst_n async active_low))
    (interface
      (input process_start)
      (output done))
    (transaction process
      (on process_start)
      (complete done))))
LIBRARY
        qr/requires parent and child clocks to match/,
        'cross-clock child wiring fails closed',
    );

    lower_source_fails_like(
        pin_ingress_atl_fixture_variant(<<'LIBRARY'),
(library common.packet
  (exports
    (actor packet_worker))
  (actor packet_worker
    (clock clk)
    (reset (rst_n async active_low))
    (interface
      (input process_start)
      (output done))
    (transaction process
      (on process_start)
      (complete done))))
LIBRARY
        qr/data movement 'feed_worker' requires a scalar child input port 'payload'/,
        'pin-ingress data route fails closed when the child omits the target input',
    );

    lower_source_fails_like(
        pin_ingress_vector_atl_fixture_variant(4),
        qr/ATL generated-child pin-ingress data movement 'feed_worker' top-level input pin 'pins\.payload' width 8 does not match sink endpoint 'worker\.payload' width 4; width adaptation remains deferred/,
        'pin-ingress vector data route fails closed when top input and child input widths differ',
    );

    lower_source_fails_like(
        pin_ingress_multi_atl_fixture_variant(<<'LIBRARY'),
(library common.packet
  (exports
    (actor packet_worker))
  (actor packet_worker
    (clock clk)
    (reset (rst_n async active_low))
    (interface
      (input process_start)
      (input payload)
      (output done))
    (transaction process
      (on process_start)
      (complete done))))
LIBRARY
        qr/data movement 'feed_sideband' requires a scalar child input port 'sideband'/,
        'pin-ingress multi-route data route fails closed when the child omits a routed input',
    );

    lower_source_fails_like(
        pin_ingress_multi_atl_fixture_variant(
            default_pin_ingress_multi_library(),
            { interleaved_sample_between_drives => 1 },
        ),
        qr/resolved-child pin-ingress data movement requires one-to-one top-level input pins and child inputs, contiguous data drive calls before trigger, and trigger before event wait/,
        'pin-ingress multi-route data route fails closed when parent work splits the route drive calls',
    );

    lower_source_fails_like(
        pin_ingress_multi_atl_fixture_variant(
            default_pin_ingress_multi_library(),
            { duplicate_source_pin => 1 },
        ),
        qr/ATL generated handoff signal 'payload' is used by both actor data movement 'feed_payload' source endpoint and actor data movement 'feed_sideband'/,
        'pin-ingress multi-route data route fails closed when two routes reuse one top-level input pin',
    );

    lower_source_fails_like(
        pin_ingress_atl_fixture_variant(
            default_pin_ingress_multi_library(),
            { route_drive_parameters => 1 },
        ),
        qr/drive 'feed_worker' body ATL scalar data movement does not accept drive parameters in the current subset/,
        'pin-ingress data route fails closed when the route drive declares formal parameters',
    );

    lower_source_fails_like(
        pin_ingress_atl_fixture_variant(
            default_pin_ingress_multi_library(),
            { drive_call_actual => 1 },
        ),
        qr/transaction 'run' ATL scalar data movement drive '\(drive feed_worker\)' does not accept actual arguments in the current subset/,
        'pin-ingress data route fails closed when the route drive call carries an actual argument',
    );

    lower_source_fails_like(
        pin_egress_atl_fixture_variant(<<'LIBRARY'),
(library common.packet
  (exports
    (actor packet_worker))
  (actor packet_worker
    (clock clk)
    (reset (rst_n async active_low))
    (interface
      (input process_start)
      (output done))
    (transaction process
      (on process_start)
      (complete done))))
LIBRARY
        qr/data movement 'publish_result' requires a scalar child output port 'payload'/,
        'pin-egress data route fails closed when the child omits the source output',
    );

    lower_source_fails_like(
        pin_egress_atl_fixture_variant(
            <<'LIBRARY',
(library common.packet
  (exports
    (actor packet_worker))
  (actor packet_worker
    (clock clk)
    (reset (rst_n async active_low))
    (interface
      (input process_start)
      (output payload)
      (output done))
    (transaction process
      (on process_start)
      (set payload process_start)
      (complete done))))
LIBRARY
            { drive_before_event_wait => 1 },
        ),
        qr/requires one-to-one child outputs and top-level output pins, trigger before event wait, and contiguous data drive calls after event wait/,
        'pin-egress data route fails closed when the drive call precedes the child event wait',
    );

    lower_source_fails_like(
        pin_egress_multi_atl_fixture_variant(<<'LIBRARY'),
(library common.packet
  (exports
    (actor packet_worker))
  (actor packet_worker
    (clock clk)
    (reset (rst_n async active_low))
    (interface
      (input process_start)
      (output payload)
      (output done))
    (transaction process
      (on process_start)
      (set payload process_start)
      (complete done))))
LIBRARY
        qr/data movement 'publish_status' requires a scalar child output port 'status'/,
        'pin-egress multi-route data route fails closed when the child omits a routed output',
    );

    lower_source_fails_like(
        pin_egress_multi_atl_fixture_variant(
            default_pin_egress_multi_library(),
            { interleaved_sample_between_drives => 1 },
        ),
        qr/resolved-child pin-egress data movement requires one-to-one child outputs and top-level output pins, trigger before event wait, and contiguous data drive calls after event wait/,
        'pin-egress multi-route data route fails closed when parent work splits the route drive calls',
    );

    lower_source_fails_like(
        pin_egress_multi_atl_fixture_variant(
            default_pin_egress_multi_library(),
            { duplicate_sink_pin => 1 },
        ),
        qr/ATL generated handoff signal 'result' is used by both actor data movement 'publish_result' sink endpoint and actor data movement 'publish_status'/,
        'pin-egress multi-route data route fails closed when two routes reuse one top-level output pin',
    );

    lower_source_fails_like(
        pin_egress_atl_fixture_variant(
            default_pin_egress_multi_library(),
            { route_drive_parameters => 1 },
        ),
        qr/drive 'publish_result' body ATL scalar data movement does not accept drive parameters in the current subset/,
        'pin-egress data route fails closed when the route drive declares formal parameters',
    );

    lower_source_fails_like(
        pin_egress_atl_fixture_variant(
            default_pin_egress_multi_library(),
            { drive_call_actual => 1 },
        ),
        qr/transaction 'run' ATL scalar data movement drive '\(drive publish_result\)' does not accept actual arguments in the current subset/,
        'pin-egress data route fails closed when the route drive call carries an actual argument',
    );

    lower_source_fails_like(
        generated_child_actor_route_fixture({ omit_writer_payload => 1 }),
        qr/data movement 'forward_payload' requires a scalar child input port 'payload' on sink instance 'writer'/,
        'generated-child actor-to-actor data route fails closed when the sink child omits the target input',
    );

    lower_source_fails_like(
        generated_child_actor_route_fixture({ omit_reader_payload => 1 }),
        qr/data movement 'forward_payload' requires a scalar child output port 'payload' on source instance 'reader'/,
        'generated-child actor-to-actor data route fails closed when the source child omits the source output',
    );

    lower_source_fails_like(
        generated_child_actor_route_fixture({ reader_payload_width => 8 }),
        qr/ATL generated-child actor-to-actor data movement 'forward_payload' source endpoint 'reader\.payload' width 8 does not match sink endpoint 'writer\.payload' width 1; width adaptation remains deferred/,
        'generated-child actor-to-actor data route fails closed when the source and sink widths differ',
    );

    lower_source_fails_like(
        generated_child_actor_route_fixture({ writer_payload_width => 8 }),
        qr/ATL generated-child actor-to-actor data movement 'forward_payload' source endpoint 'reader\.payload' width 1 does not match sink endpoint 'writer\.payload' width 8; width adaptation remains deferred/,
        'generated-child actor-to-actor data route fails closed when the sink and source widths differ',
    );

    lower_source_fails_like(
        generated_child_actor_route_fixture({ reader_clock => 'reader_clk' }),
        qr/requires parent and child clocks to match before ATL child wiring; parent 'clk' child 'reader_clk'/,
        'generated-child actor-to-actor data route fails closed when the source child clock differs from the parent',
    );

    lower_source_fails_like(
        generated_child_actor_route_fixture({ writer_clock => 'writer_clk' }),
        qr/requires parent and child clocks to match before ATL child wiring; parent 'clk' child 'writer_clk'/,
        'generated-child actor-to-actor data route fails closed when the sink child clock differs from the parent',
    );

    lower_source_fails_like(
        generated_child_actor_route_fixture({ reader_reset => '(reader_rst_n async active_low)' }),
        qr/requires parent and child reset policy to match before ATL child wiring/,
        'generated-child actor-to-actor data route fails closed when the source child reset differs from the parent',
    );

    lower_source_fails_like(
        generated_child_actor_route_fixture({ writer_reset => '(writer_rst_n async active_low)' }),
        qr/requires parent and child reset policy to match before ATL child wiring/,
        'generated-child actor-to-actor data route fails closed when the sink child reset differs from the parent',
    );

    lower_source_fails_like(
        generated_child_actor_route_fixture({ same_child_route => 1 }),
        qr/drive 'forward_payload' body ATL scalar actor-to-actor data movement requires distinct source and sink actor instances/,
        'generated-child actor-to-actor data route fails closed when source and sink name the same child',
    );

    lower_source_fails_like(
        generated_child_actor_route_fixture({ extra_reader_trigger => 1 }),
        qr/generated-child actor-to-actor data route requires exactly one transaction trigger per source and sink child in the current subset; repeated activation remains deferred/,
        'generated-child actor-to-actor data route fails closed when the source child is triggered twice',
    );

    lower_source_fails_like(
        generated_child_actor_route_fixture({ extra_writer_trigger => 1 }),
        qr/generated-child actor-to-actor data route requires exactly one transaction trigger per source and sink child in the current subset; repeated activation remains deferred/,
        'generated-child actor-to-actor data route fails closed when the sink child is triggered twice',
    );

    lower_source_fails_like(
        generated_child_actor_route_fixture({ extra_reader_wait => 1 }),
        qr/generated-child actor-to-actor data route requires exactly one event wait per source and sink child in the current subset; repeated waits remain deferred/,
        'generated-child actor-to-actor data route fails closed when the source child event is awaited twice',
    );

    lower_source_fails_like(
        generated_child_actor_route_fixture({ extra_writer_wait => 1 }),
        qr/generated-child actor-to-actor data route requires exactly one event wait per source and sink child in the current subset; repeated waits remain deferred/,
        'generated-child actor-to-actor data route fails closed when the sink child event is awaited twice',
    );

    lower_source_fails_like(
        generated_child_actor_route_fixture({ split_sink_transaction => 1 }),
        qr/generated-child actor-to-actor data route requires source trigger, source event wait, data drive call, sink trigger, and sink event wait to belong to one parent transaction in the current subset; cross-transaction route continuation remains deferred/,
        'generated-child actor-to-actor data route fails closed when the sink side is split into another parent transaction',
    );

    lower_source_fails_like(
        generated_child_actor_route_fixture({ drive_before_reader_done => 1 }),
        qr/generated-child actor-to-actor data movement requires source trigger, source event wait, data drive call, sink trigger, and sink event wait in that order/,
        'generated-child actor-to-actor data route fails closed when the drive call precedes the source event wait',
    );

    lower_source_fails_like(
        generated_child_actor_route_fixture({ source_wait_before_trigger => 1 }),
        qr/generated-child actor-to-actor data movement requires source trigger, source event wait, data drive call, sink trigger, and sink event wait in that order/,
        'generated-child actor-to-actor data route fails closed when the source child event is awaited before the source trigger',
    );

    lower_source_fails_like(
        generated_child_actor_route_fixture({ interleaved_sample_before_drive => 1 }),
        qr/generated-child actor-to-actor data movement requires source trigger, source event wait, data drive call, sink trigger, and sink event wait to be contiguous in the current subset; interleaved parent work remains deferred/,
        'generated-child actor-to-actor data route fails closed when parent work is interleaved before the drive call',
    );

    lower_source_fails_like(
        generated_child_actor_route_fixture({ pre_route_sample => 1 }),
        qr/generated-child actor-to-actor data movement requires the route segment to be the only executable parent transaction-body work in the current subset; pre\/post route parent work remains deferred/,
        'generated-child actor-to-actor data route fails closed when parent work appears before the route segment',
    );

    lower_source_fails_like(
        generated_child_actor_route_fixture({ post_route_sample => 1 }),
        qr/generated-child actor-to-actor data movement requires the route segment to be the only executable parent transaction-body work in the current subset; pre\/post route parent work remains deferred/,
        'generated-child actor-to-actor data route fails closed when parent work appears after the route segment',
    );

    lower_source_fails_like(
        generated_child_actor_route_fixture({ extra_start_boundary => 1 }),
        qr/generated-child actor-to-actor data movement requires exactly one start boundary and exactly one completion boundary around the route in the current subset; activation fan-in and completion fan-out remain deferred/,
        'generated-child actor-to-actor data route fails closed when an extra start boundary appears before the route segment',
    );

    lower_source_fails_like(
        generated_child_actor_route_fixture({ extra_completion_boundary => 1 }),
        qr/generated-child actor-to-actor data movement requires exactly one start boundary and exactly one completion boundary around the route in the current subset; activation fan-in and completion fan-out remain deferred/,
        'generated-child actor-to-actor data route fails closed when an extra completion boundary appears after the route segment',
    );

    lower_source_fails_like(
        generated_child_actor_route_fixture({ start_boundary_sample => 1 }),
        qr/generated-child actor-to-actor data movement requires simple '\(on PORT\)' and '\(complete PORT\)' boundaries around the route in the current subset; activation-body samples and completion payloads remain deferred/,
        'generated-child actor-to-actor data route fails closed when the start boundary carries an activation-body sample',
    );

    lower_source_fails_like(
        generated_child_actor_route_fixture({ completion_payload_operand => 1 }),
        qr/generated-child actor-to-actor data movement requires simple '\(on PORT\)' and '\(complete PORT\)' boundaries around the route in the current subset; activation-body samples and completion payloads remain deferred/,
        'generated-child actor-to-actor data route fails closed when the completion boundary carries an extra payload operand',
    );

    lower_source_fails_like(
        generated_child_actor_route_fixture({ start_boundary_output => 1 }),
        qr/generated-child actor-to-actor data movement requires scalar parent interface boundaries '\(on INPUT_PIN\)' and '\(complete OUTPUT_PIN\)' in the current subset; interface remapping and boundary expressions remain deferred/,
        'generated-child actor-to-actor data route fails closed when the start boundary names a top-level output',
    );

    lower_source_fails_like(
        generated_child_actor_route_fixture({ completion_boundary_input => 1 }),
        qr/generated-child actor-to-actor data movement requires scalar parent interface boundaries '\(on INPUT_PIN\)' and '\(complete OUTPUT_PIN\)' in the current subset; interface remapping and boundary expressions remain deferred/,
        'generated-child actor-to-actor data route fails closed when the completion boundary names a top-level input',
    );

    lower_source_fails_like(
        generated_child_actor_route_fixture({ start_boundary_undeclared => 1 }),
        qr/generated-child actor-to-actor data movement requires scalar parent interface boundaries '\(on INPUT_PIN\)' and '\(complete OUTPUT_PIN\)' in the current subset; interface remapping and boundary expressions remain deferred/,
        'generated-child actor-to-actor data route fails closed when the start boundary names an undeclared pin',
    );

    lower_source_fails_like(
        generated_child_actor_route_fixture({ completion_boundary_undeclared => 1 }),
        qr/generated-child actor-to-actor data movement requires scalar parent interface boundaries '\(on INPUT_PIN\)' and '\(complete OUTPUT_PIN\)' in the current subset; interface remapping and boundary expressions remain deferred/,
        'generated-child actor-to-actor data route fails closed when the completion boundary names an undeclared pin',
    );

    lower_source_fails_like(
        generated_child_actor_route_fixture({ start_width => 2 }),
        qr/generated-child actor-to-actor data movement requires scalar parent interface boundaries '\(on INPUT_PIN\)' and '\(complete OUTPUT_PIN\)' in the current subset; interface remapping and boundary expressions remain deferred/,
        'generated-child actor-to-actor data route fails closed when the start boundary is wider than one bit',
    );

    lower_source_fails_like(
        generated_child_actor_route_fixture({ completion_width => 2 }),
        qr/generated-child actor-to-actor data movement requires scalar parent interface boundaries '\(on INPUT_PIN\)' and '\(complete OUTPUT_PIN\)' in the current subset; interface remapping and boundary expressions remain deferred/,
        'generated-child actor-to-actor data route fails closed when the completion boundary is wider than one bit',
    );

    my @generated_handoff_collision_cases = (
        [
            'source data handoff',
            'reader_payload',
            qr/drive 'forward_payload' body ATL scalar actor-to-actor data movement generated handoff signal 'reader_payload' conflicts with a declared actor signal/,
        ],
        [
            'sink data handoff',
            'writer_payload',
            qr/drive 'forward_payload' body ATL scalar actor-to-actor data movement generated handoff signal 'writer_payload' conflicts with a declared actor signal/,
        ],
        [
            'source trigger handoff',
            'reader_capture_start',
            qr/ATL actor transaction trigger '\(trigger reader\.capture\)' generated handoff signal 'reader_capture_start' conflicts with a declared actor signal/,
        ],
        [
            'source event handoff',
            'reader_done',
            qr/ATL actor event wait '\(await reader\.done\)' generated handoff signal 'reader_done' conflicts with a declared actor signal/,
        ],
        [
            'sink trigger handoff',
            'writer_emit_start',
            qr/ATL actor transaction trigger '\(trigger writer\.emit\)' generated handoff signal 'writer_emit_start' conflicts with a declared actor signal/,
        ],
        [
            'sink event handoff',
            'writer_done',
            qr/ATL actor event wait '\(await writer\.done\)' generated handoff signal 'writer_done' conflicts with a declared actor signal/,
        ],
        [
            'named-drive request handoff',
            'forward_payload_start',
            qr/drive 'forward_payload' body ATL scalar actor-to-actor data movement generated drive request signal 'forward_payload_start' conflicts with a declared actor signal/,
        ],
    );

    for my $case (@generated_handoff_collision_cases) {
        my ($label, $signal, $expected) = @$case;
        lower_source_fails_like(
            generated_child_actor_route_fixture({ parent_interface_collision => $signal }),
            $expected,
            "generated-child actor-to-actor data route fails closed when a parent interface declares the $label name",
        );
        lower_source_fails_like(
            generated_child_actor_route_fixture({ parent_storage_collision => $signal }),
            $expected,
            "generated-child actor-to-actor data route fails closed when parent storage declares the $label name",
        );
    }

    my @lowerer_handoff_collision_cases = (
        [ 'source data handoff',        'reader_payload' ],
        [ 'sink data handoff',          'writer_payload' ],
        [ 'source trigger handoff',     'reader_capture_start' ],
        [ 'source event handoff',       'reader_done' ],
        [ 'sink trigger handoff',       'writer_emit_start' ],
        [ 'sink event handoff',         'writer_done' ],
        [ 'named-drive request handoff', 'forward_payload_start' ],
    );

    for my $case (@lowerer_handoff_collision_cases) {
        my ($role, $signal) = @$case;

        my $interface_actor = parsed_generated_child_actor_route_actor();
        add_mutated_parent_interface_signal($interface_actor, $signal);
        lower_actor_fails_like(
            $interface_actor,
            lowerer_generated_handoff_collision_pattern($role, $signal, 'parent interface port'),
            "generated-child actor-to-actor data route lowerer backstop rejects mutated parent interface collision for $role",
        );

        my $storage_actor = parsed_generated_child_actor_route_actor();
        add_mutated_parent_storage_signal($storage_actor, $signal);
        lower_actor_fails_like(
            $storage_actor,
            lowerer_generated_handoff_collision_pattern($role, $signal, 'declared actor-owned storage signal'),
            "generated-child actor-to-actor data route lowerer backstop rejects mutated parent storage collision for $role",
        );
    }

    my $duplicate_handoff_actor = parsed_generated_child_actor_route_actor();
    $duplicate_handoff_actor->{actor_network}{data_movements}[0]{sink_signal} =
        $duplicate_handoff_actor->{actor_network}{data_movements}[0]{source_signal};
    lower_actor_fails_like(
        $duplicate_handoff_actor,
        qr/lowerer generated-handoff collision: sink data handoff signal 'reader_payload' conflicts with already registered generated handoff 'reader_payload' from source data handoff/,
        'generated-child actor-to-actor data route lowerer backstop rejects duplicated generated handoff metadata',
    );

    lower_source_fails_like(
        generated_child_actor_route_fixture({ sink_trigger_before_drive => 1 }),
        qr/generated-child actor-to-actor data movement requires source trigger, source event wait, data drive call, sink trigger, and sink event wait in that order/,
        'generated-child actor-to-actor data route fails closed when the sink child is triggered before the drive call',
    );

    lower_source_fails_like(
        generated_child_actor_route_fixture({ sink_wait_before_trigger => 1 }),
        qr/generated-child actor-to-actor data movement requires source trigger, source event wait, data drive call, sink trigger, and sink event wait in that order/,
        'generated-child actor-to-actor data route fails closed when the sink child event is awaited before the sink trigger',
    );

    lower_source_fails_like(
        generated_child_actor_route_fixture({ route_drive_parameters => 1 }),
        qr/drive 'forward_payload' body ATL scalar data movement does not accept drive parameters in the current subset/,
        'generated-child actor-to-actor data route fails closed when the route drive declares formal parameters',
    );

    lower_source_fails_like(
        generated_child_actor_route_fixture({ drive_call_actual => 1 }),
        qr/transaction 'run' ATL scalar data movement drive '\(drive forward_payload\)' does not accept actual arguments in the current subset/,
        'generated-child actor-to-actor data route fails closed when the route drive call carries an actual argument',
    );

    lower_source_fails_like(
        generated_child_actor_route_fixture({ source_expression => 1 }),
        qr/drive 'forward_payload' body ATL scalar actor-to-actor data movement source expressions remain deferred/,
        'generated-child actor-to-actor data route fails closed when the route source is an expression',
    );

    lower_source_fails_like(
        generated_child_actor_route_fixture({ source_expression => 1, drive_before_instances => 1 }),
        qr/drive 'forward_payload' body ATL scalar actor-to-actor data movement source expressions remain deferred/,
        'generated-child actor-to-actor data route fails closed when a route source expression appears before actor instances',
    );

    lower_source_fails_like(
        generated_child_actor_route_fixture({ sink_expression => 1 }),
        qr/drive 'forward_payload' body ATL scalar actor-to-actor data movement sink expressions remain deferred/,
        'generated-child actor-to-actor data route fails closed when the route sink is an expression',
    );

    lower_source_fails_like(
        generated_child_actor_route_fixture({ sink_expression => 1, drive_before_instances => 1 }),
        qr/drive 'forward_payload' body ATL scalar actor-to-actor data movement sink expressions remain deferred/,
        'generated-child actor-to-actor data route fails closed when a route sink expression appears before actor instances',
    );

    lower_source_fails_like(
        generated_child_actor_route_fixture({ extra_drive_pair => 1 }),
        qr/drive 'forward_payload' body ATL scalar actor-to-actor data movement requires exactly one drive-body pair in the current subset/,
        'generated-child actor-to-actor data route fails closed when one route drive contains multiple endpoint pairs',
    );

    lower_source_fails_like(
        generated_child_actor_route_fixture({ second_route_drive => 1 }),
        qr/drive 'forward_sideband' ATL scalar data movement requires exactly one top-level transaction drive call in the current subset/,
        'generated-child actor-to-actor data route fails closed when a second route drive is declared but not called',
    );

    lower_source_fails_like(
        generated_child_actor_route_fixture({ repeated_drive_call => 1 }),
        qr/transaction 'run' ATL scalar data movement drive '\(drive forward_payload\)' exceeds the current one-call-per-route subset; repeated movement remains deferred/,
        'generated-child actor-to-actor data route fails closed when the route drive is called twice',
    );
};

done_testing();

sub lower_atl_fixture {
    my ($source_file) = @_;
    $source_file //= $isf_file;

    my $actor = FSM::Adapter::ISF->new()->parse_file($source_file);
    my $scheduler = FSM::Scheduler::ISF->new();
    my $result = $scheduler->lower($actor);
    my $report = decode_json($scheduler->report($actor));

    return ($result->{files}, $report);
}

sub lower_source {
    my ($source, $source_label) = @_;
    $source_label //= 'inline.isf';

    my $actor = FSM::Adapter::ISF->new()->parse_source($source, $source_label);
    my $scheduler = FSM::Scheduler::ISF->new();
    my $result = $scheduler->lower($actor);
    my $report = decode_json($scheduler->report($actor));

    return ($result->{files}, $report);
}

sub assert_report_shape {
    my ($report) = @_;

    is($report->{source}, 'atl_resolved_child_pipeline.isf', 'schedule report names the ATL resolved-child fixture');
    is($report->{scheduled_fsm}, 'atl_resolved_child_pipeline.fsm', 'schedule report names the scheduled parent FSM');
    is($report->{clock}, 'clk', 'schedule report records the clock');
    is_deeply(
        $report->{reset},
        { name => 'rst_n', kind => 'async', polarity => 'active_low' },
        'schedule report records async active-low reset metadata',
    );
    is($report->{inputs}, 2, 'schedule report input count includes the worker event handoff');
    is($report->{outputs}, 2, 'schedule report output count includes the worker trigger handoff');
    is($report->{port_count}, 4, 'schedule report port count includes generated orchestration handoffs');
    is($report->{state_count}, 5, 'schedule report state count includes the default await timeout state');
    is_deeply($report->{compile_issues}, [], 'schedule report has no compile issues');
    is_deeply($report->{dt_blocks}, [], 'schedule report has no drive bodies');
    is_deeply($report->{library_uses}, [], 'ATL resolved child does not appear as a reusable-library use');

    is_deeply(
        $report->{transactions},
        [
            {
                name => 'run',
                count => 5,
                states => [qw(
                  run_idle_0
                  run_atl_trigger_1
                  run_await_2
                  run_done_3
                  run_timeout
                )],
            },
        ],
        'schedule report records the resolved-child transaction state order',
    );

    my $actor_network = $report->{actor_network};
    is($actor_network->{kind}, 'static_declaration', 'actor network kind');
    is_deeply(
        $actor_network->{instances},
        [
            {
                name            => 'worker',
                actor_type      => 'pkt_lib.packet_worker',
                declaration     => 'actor',
                type_resolution => 'library_actor_export',
                library         => 'common.packet',
                alias           => 'pkt_lib',
                export          => 'packet_worker',
                module          => 'atl_resolved_child_pipeline__worker',
                scheduled_fsm   => 'atl_resolved_child_pipeline__worker.fsm',
            },
        ],
        'report records the resolved child actor metadata',
    );
    is_deeply($actor_network->{groups}, [], 'fixture has no permanent static group');
    is_deeply(
        $actor_network->{generated_tops},
        [
            {
                kind                 => 'resolved_child_trigger_event_handoff',
                top_module           => 'atl_resolved_child_pipeline_top',
                top_fsm              => 'atl_resolved_child_pipeline_top.fsm',
                parent_module        => 'atl_resolved_child_pipeline',
                parent_scheduled_fsm => 'atl_resolved_child_pipeline.fsm',
                instance             => 'worker',
                child_module         => 'atl_resolved_child_pipeline__worker',
                child_scheduled_fsm  => 'atl_resolved_child_pipeline__worker.fsm',
                target_transaction   => 'process',
                trigger_parent_port  => 'worker_process_start',
                trigger_child_port   => 'process_start',
                event                => 'done',
                event_parent_port    => 'worker_done',
                event_child_port     => 'done',
                clock                => 'clk',
                reset                => 'rst_n',
            },
        ],
        'report records the generated ATL top handoff wiring',
    );
    is_deeply($actor_network->{data_movements}, [], 'fixture does not use ATL data movement');
    is_deeply($actor_network->{association_schedules}, [], 'fixture does not use trigger-batch association schedules');
    is_deeply($actor_network->{group_schedules}, [], 'fixture does not use compatibility group schedule evidence');
    is_deeply(
        $actor_network->{transaction_triggers},
        [
            {
                owner_transaction  => 'run',
                context            => 'transaction_body',
                instance           => 'worker',
                target_transaction => 'process',
                signal             => 'worker_process_start',
                sink               => 'external_handoff',
            },
        ],
        'report records the worker process trigger handoff',
    );
    is_deeply(
        $actor_network->{event_waits},
        [
            {
                transaction => 'run',
                context     => 'transaction_body',
                instance    => 'worker',
                event       => 'done',
                signal      => 'worker_done',
                source      => 'external_handoff',
            },
        ],
        'report records the worker done event handoff',
    );
}

sub assert_pin_ingress_report_shape {
    my ($report) = @_;

    is($report->{source}, 'atl_resolved_child_pin_ingress_pipeline.isf',
        'pin-ingress schedule report names the fixture');
    is($report->{scheduled_fsm}, 'atl_resolved_child_pin_ingress_pipeline.fsm',
        'pin-ingress schedule report names the scheduled parent FSM');
    is($report->{inputs}, 3, 'pin-ingress report input count includes payload and worker event handoff');
    is($report->{outputs}, 3, 'pin-ingress report output count includes done, trigger, and data handoffs');
    is($report->{port_count}, 6, 'pin-ingress report port count includes public and generated handoff ports');
    is($report->{state_count}, 6, 'pin-ingress report state count includes drive, trigger, await, done, and timeout states');
    is_deeply($report->{compile_issues}, [], 'pin-ingress schedule report has no compile issues');
    is_deeply(
        $report->{dt_blocks},
        [
            {
                assignments => 1,
                kind        => 'drive',
                name        => 'feed_worker',
            },
        ],
        'pin-ingress schedule report records the scalar transfer drive body',
    );
    is_deeply(
        $report->{transactions},
        [
            {
                name => 'run',
                count => 6,
                states => [qw(
                  run_idle_0
                  run_drive_1
                  run_atl_trigger_2
                  run_await_3
                  run_done_4
                  run_timeout
                )],
            },
        ],
        'pin-ingress schedule report records the drive before trigger and await',
    );

    my $actor_network = $report->{actor_network};
    is($actor_network->{kind}, 'static_declaration', 'pin-ingress actor network kind');
    is_deeply(
        $actor_network->{generated_tops},
        [
            {
                kind                 => 'resolved_child_trigger_event_handoff',
                top_module           => 'atl_resolved_child_pin_ingress_pipeline_top',
                top_fsm              => 'atl_resolved_child_pin_ingress_pipeline_top.fsm',
                parent_module        => 'atl_resolved_child_pin_ingress_pipeline',
                parent_scheduled_fsm => 'atl_resolved_child_pin_ingress_pipeline.fsm',
                instance             => 'worker',
                child_module         => 'atl_resolved_child_pin_ingress_pipeline__worker',
                child_scheduled_fsm  => 'atl_resolved_child_pin_ingress_pipeline__worker.fsm',
                target_transaction   => 'process',
                trigger_parent_port  => 'worker_process_start',
                trigger_child_port   => 'process_start',
                event                => 'done',
                event_parent_port    => 'worker_done',
                event_child_port     => 'done',
                clock                => 'clk',
                reset                => 'rst_n',
            },
        ],
        'pin-ingress report records the generated ATL top without private data-link internals',
    );
    is_deeply(
        $actor_network->{data_movements},
        [
            {
                kind            => 'scalar_pin_to_actor_handoff',
                drive           => 'feed_worker',
                transaction     => 'run',
                context         => 'transaction_body',
                source          => 'top_level_pin',
                source_instance => 'pins',
                source_endpoint => 'payload',
                source_signal   => 'payload',
                sink            => 'external_handoff',
                sink_instance   => 'worker',
                sink_endpoint   => 'payload',
                sink_signal     => 'worker_payload',
                width           => 1,
                width_source    => 'top_level_pin_scalar_one_bit',
                route_lifetime  => 'drive_call_cycle',
                storage         => 'none',
            },
        ],
        'pin-ingress report records the public scalar pin-to-child data movement',
    );
    is_deeply(
        $actor_network->{transaction_triggers},
        [
            {
                owner_transaction  => 'run',
                context            => 'transaction_body',
                instance           => 'worker',
                target_transaction => 'process',
                signal             => 'worker_process_start',
                sink               => 'external_handoff',
            },
        ],
        'pin-ingress report records the worker process trigger handoff',
    );
    is_deeply(
        $actor_network->{event_waits},
        [
            {
                transaction => 'run',
                context     => 'transaction_body',
                instance    => 'worker',
                event       => 'done',
                signal      => 'worker_done',
                source      => 'external_handoff',
            },
        ],
        'pin-ingress report records the worker done event handoff',
    );
}

sub assert_pin_ingress_vector_report_shape {
    my ($report) = @_;

    is($report->{source}, 'atl_resolved_child_pin_ingress_vector_pipeline.isf',
        'pin-ingress vector schedule report names the fixture');
    is($report->{scheduled_fsm}, 'atl_resolved_child_pin_ingress_vector_pipeline.fsm',
        'pin-ingress vector schedule report names the scheduled parent FSM');
    is($report->{inputs}, 3, 'pin-ingress vector report input count includes payload and worker event handoff');
    is($report->{outputs}, 3, 'pin-ingress vector report output count includes done, trigger, and data handoffs');
    is($report->{port_count}, 6, 'pin-ingress vector report port count includes public and generated handoff ports');
    is($report->{state_count}, 6, 'pin-ingress vector report state count includes drive, trigger, await, done, and timeout states');
    is_deeply($report->{compile_issues}, [], 'pin-ingress vector schedule report has no compile issues');
    is_deeply(
        $report->{dt_blocks},
        [
            {
                assignments => 1,
                kind        => 'drive',
                name        => 'feed_worker',
            },
        ],
        'pin-ingress vector schedule report records the vector transfer drive body',
    );
    is_deeply(
        $report->{transactions},
        [
            {
                name => 'run',
                count => 6,
                states => [qw(
                  run_idle_0
                  run_drive_1
                  run_atl_trigger_2
                  run_await_3
                  run_done_4
                  run_timeout
                )],
            },
        ],
        'pin-ingress vector schedule report records the drive before trigger and await',
    );

    my $actor_network = $report->{actor_network};
    is($actor_network->{kind}, 'static_declaration', 'pin-ingress vector actor network kind');
    is_deeply(
        $actor_network->{generated_tops},
        [
            {
                kind                 => 'resolved_child_trigger_event_handoff',
                top_module           => 'atl_resolved_child_pin_ingress_vector_pipeline_top',
                top_fsm              => 'atl_resolved_child_pin_ingress_vector_pipeline_top.fsm',
                parent_module        => 'atl_resolved_child_pin_ingress_vector_pipeline',
                parent_scheduled_fsm => 'atl_resolved_child_pin_ingress_vector_pipeline.fsm',
                instance             => 'worker',
                child_module         => 'atl_resolved_child_pin_ingress_vector_pipeline__worker',
                child_scheduled_fsm  => 'atl_resolved_child_pin_ingress_vector_pipeline__worker.fsm',
                target_transaction   => 'process',
                trigger_parent_port  => 'worker_process_start',
                trigger_child_port   => 'process_start',
                event                => 'done',
                event_parent_port    => 'worker_done',
                event_child_port     => 'done',
                clock                => 'clk',
                reset                => 'rst_n',
            },
        ],
        'pin-ingress vector report records the generated ATL top without private data-link internals',
    );
    is_deeply(
        $actor_network->{data_movements},
        [
            {
                kind            => 'vector_pin_to_actor_handoff',
                drive           => 'feed_worker',
                transaction     => 'run',
                context         => 'transaction_body',
                source          => 'top_level_pin',
                source_instance => 'pins',
                source_endpoint => 'payload',
                source_signal   => 'payload',
                sink            => 'external_handoff',
                sink_instance   => 'worker',
                sink_endpoint   => 'payload',
                sink_signal     => 'worker_payload',
                width           => 8,
                width_source    => 'top_level_input_pin_resolved_child_endpoint_exact_width',
                route_lifetime  => 'drive_call_cycle',
                storage         => 'none',
            },
        ],
        'pin-ingress vector report records the public exact-width pin-to-child data movement',
    );
    is_deeply(
        $actor_network->{transaction_triggers},
        [
            {
                owner_transaction  => 'run',
                context            => 'transaction_body',
                instance           => 'worker',
                target_transaction => 'process',
                signal             => 'worker_process_start',
                sink               => 'external_handoff',
            },
        ],
        'pin-ingress vector report records the worker process trigger handoff',
    );
    is_deeply(
        $actor_network->{event_waits},
        [
            {
                transaction => 'run',
                context     => 'transaction_body',
                instance    => 'worker',
                event       => 'done',
                signal      => 'worker_done',
                source      => 'external_handoff',
            },
        ],
        'pin-ingress vector report records the worker done event handoff',
    );
}

sub assert_pin_ingress_multi_report_shape {
    my ($report) = @_;

    is($report->{source}, 'atl_resolved_child_pin_ingress_multi_pipeline.isf',
        'pin-ingress multi-route schedule report names the fixture');
    is($report->{scheduled_fsm}, 'atl_resolved_child_pin_ingress_multi_pipeline.fsm',
        'pin-ingress multi-route schedule report names the scheduled parent FSM');
    is($report->{inputs}, 4, 'pin-ingress multi-route report input count includes payload, sideband, and worker event handoff');
    is($report->{outputs}, 4, 'pin-ingress multi-route report output count includes done, trigger, and data handoffs');
    is($report->{port_count}, 8, 'pin-ingress multi-route report port count includes public and generated handoff ports');
    is($report->{state_count}, 7, 'pin-ingress multi-route report state count includes two drives, trigger, await, done, and timeout states');
    is_deeply($report->{compile_issues}, [], 'pin-ingress multi-route schedule report has no compile issues');
    is_deeply(
        $report->{dt_blocks},
        [
            {
                assignments => 1,
                kind        => 'drive',
                name        => 'feed_payload',
            },
            {
                assignments => 1,
                kind        => 'drive',
                name        => 'feed_sideband',
            },
        ],
        'pin-ingress multi-route schedule report records both scalar transfer drive bodies',
    );
    is_deeply(
        $report->{transactions},
        [
            {
                name => 'run',
                count => 7,
                states => [qw(
                  run_idle_0
                  run_drive_1
                  run_drive_2
                  run_atl_trigger_3
                  run_await_4
                  run_done_5
                  run_timeout
                )],
            },
        ],
        'pin-ingress multi-route schedule report records both drives before trigger and await',
    );

    my $actor_network = $report->{actor_network};
    is($actor_network->{kind}, 'static_declaration', 'pin-ingress multi-route actor network kind');
    is_deeply(
        $actor_network->{generated_tops},
        [
            {
                kind                 => 'resolved_child_trigger_event_handoff',
                top_module           => 'atl_resolved_child_pin_ingress_multi_pipeline_top',
                top_fsm              => 'atl_resolved_child_pin_ingress_multi_pipeline_top.fsm',
                parent_module        => 'atl_resolved_child_pin_ingress_multi_pipeline',
                parent_scheduled_fsm => 'atl_resolved_child_pin_ingress_multi_pipeline.fsm',
                instance             => 'worker',
                child_module         => 'atl_resolved_child_pin_ingress_multi_pipeline__worker',
                child_scheduled_fsm  => 'atl_resolved_child_pin_ingress_multi_pipeline__worker.fsm',
                target_transaction   => 'process',
                trigger_parent_port  => 'worker_process_start',
                trigger_child_port   => 'process_start',
                event                => 'done',
                event_parent_port    => 'worker_done',
                event_child_port     => 'done',
                clock                => 'clk',
                reset                => 'rst_n',
            },
        ],
        'pin-ingress multi-route report records the generated ATL top without private data-link internals',
    );
    is_deeply(
        $actor_network->{data_movements},
        [
            {
                kind            => 'scalar_pin_to_actor_handoff',
                drive           => 'feed_payload',
                transaction     => 'run',
                context         => 'transaction_body',
                source          => 'top_level_pin',
                source_instance => 'pins',
                source_endpoint => 'payload',
                source_signal   => 'payload',
                sink            => 'external_handoff',
                sink_instance   => 'worker',
                sink_endpoint   => 'payload',
                sink_signal     => 'worker_payload',
                width           => 1,
                width_source    => 'top_level_pin_scalar_one_bit',
                route_lifetime  => 'drive_call_cycle',
                storage         => 'none',
            },
            {
                kind            => 'scalar_pin_to_actor_handoff',
                drive           => 'feed_sideband',
                transaction     => 'run',
                context         => 'transaction_body',
                source          => 'top_level_pin',
                source_instance => 'pins',
                source_endpoint => 'sideband',
                source_signal   => 'sideband',
                sink            => 'external_handoff',
                sink_instance   => 'worker',
                sink_endpoint   => 'sideband',
                sink_signal     => 'worker_sideband',
                width           => 1,
                width_source    => 'top_level_pin_scalar_one_bit',
                route_lifetime  => 'drive_call_cycle',
                storage         => 'none',
            },
        ],
        'pin-ingress multi-route report records both public scalar pin-to-child data movements',
    );
    is_deeply(
        $actor_network->{transaction_triggers},
        [
            {
                owner_transaction  => 'run',
                context            => 'transaction_body',
                instance           => 'worker',
                target_transaction => 'process',
                signal             => 'worker_process_start',
                sink               => 'external_handoff',
            },
        ],
        'pin-ingress multi-route report records the worker process trigger handoff',
    );
    is_deeply(
        $actor_network->{event_waits},
        [
            {
                transaction => 'run',
                context     => 'transaction_body',
                instance    => 'worker',
                event       => 'done',
                signal      => 'worker_done',
                source      => 'external_handoff',
            },
        ],
        'pin-ingress multi-route report records the worker done event handoff',
    );
}

sub assert_pin_egress_report_shape {
    my ($report) = @_;

    is($report->{source}, 'atl_resolved_child_pin_egress_pipeline.isf',
        'pin-egress schedule report names the fixture');
    is($report->{scheduled_fsm}, 'atl_resolved_child_pin_egress_pipeline.fsm',
        'pin-egress schedule report names the scheduled parent FSM');
    is($report->{inputs}, 3, 'pin-egress report input count includes start, worker event, and worker payload handoff');
    is($report->{outputs}, 3, 'pin-egress report output count includes result, done, and trigger handoff');
    is($report->{port_count}, 6, 'pin-egress report port count includes public and generated handoff ports');
    is($report->{state_count}, 6, 'pin-egress report state count includes trigger, await, drive, done, and timeout states');
    is_deeply($report->{compile_issues}, [], 'pin-egress schedule report has no compile issues');
    is_deeply(
        $report->{dt_blocks},
        [
            {
                assignments => 1,
                kind        => 'drive',
                name        => 'publish_result',
            },
        ],
        'pin-egress schedule report records the scalar transfer drive body',
    );
    is_deeply(
        $report->{transactions},
        [
            {
                name => 'run',
                count => 6,
                states => [qw(
                  run_idle_0
                  run_atl_trigger_1
                  run_await_2
                  run_drive_3
                  run_done_4
                  run_timeout
                )],
            },
        ],
        'pin-egress schedule report records the trigger, await, then drive state order',
    );

    my $actor_network = $report->{actor_network};
    is($actor_network->{kind}, 'static_declaration', 'pin-egress actor network kind');
    is_deeply(
        $actor_network->{generated_tops},
        [
            {
                kind                 => 'resolved_child_trigger_event_handoff',
                top_module           => 'atl_resolved_child_pin_egress_pipeline_top',
                top_fsm              => 'atl_resolved_child_pin_egress_pipeline_top.fsm',
                parent_module        => 'atl_resolved_child_pin_egress_pipeline',
                parent_scheduled_fsm => 'atl_resolved_child_pin_egress_pipeline.fsm',
                instance             => 'worker',
                child_module         => 'atl_resolved_child_pin_egress_pipeline__worker',
                child_scheduled_fsm  => 'atl_resolved_child_pin_egress_pipeline__worker.fsm',
                target_transaction   => 'process',
                trigger_parent_port  => 'worker_process_start',
                trigger_child_port   => 'process_start',
                event                => 'done',
                event_parent_port    => 'worker_done',
                event_child_port     => 'done',
                clock                => 'clk',
                reset                => 'rst_n',
            },
        ],
        'pin-egress report records the generated ATL top without private data-link internals',
    );
    is_deeply(
        $actor_network->{data_movements},
        [
            {
                kind            => 'scalar_actor_to_pin_handoff',
                drive           => 'publish_result',
                transaction     => 'run',
                context         => 'transaction_body',
                source          => 'external_handoff',
                source_instance => 'worker',
                source_endpoint => 'payload',
                source_signal   => 'worker_payload',
                sink            => 'top_level_pin',
                sink_instance   => 'pins',
                sink_endpoint   => 'result',
                sink_signal     => 'result',
                width           => 1,
                width_source    => 'top_level_output_pin_scalar_one_bit',
                route_lifetime  => 'drive_call_cycle',
                storage         => 'none',
            },
        ],
        'pin-egress report records the public scalar child-to-pin data movement',
    );
    is_deeply(
        $actor_network->{transaction_triggers},
        [
            {
                owner_transaction  => 'run',
                context            => 'transaction_body',
                instance           => 'worker',
                target_transaction => 'process',
                signal             => 'worker_process_start',
                sink               => 'external_handoff',
            },
        ],
        'pin-egress report records the worker process trigger handoff',
    );
    is_deeply(
        $actor_network->{event_waits},
        [
            {
                transaction => 'run',
                context     => 'transaction_body',
                instance    => 'worker',
                event       => 'done',
                signal      => 'worker_done',
                source      => 'external_handoff',
            },
        ],
        'pin-egress report records the worker done event handoff',
    );
}

sub assert_pin_egress_multi_report_shape {
    my ($report) = @_;

    is($report->{source}, 'atl_resolved_child_pin_egress_multi_pipeline.isf',
        'pin-egress multi-route schedule report names the fixture');
    is($report->{scheduled_fsm}, 'atl_resolved_child_pin_egress_multi_pipeline.fsm',
        'pin-egress multi-route schedule report names the scheduled parent FSM');
    is($report->{inputs}, 4, 'pin-egress multi-route report input count includes start, worker event, and two worker data handoffs');
    is($report->{outputs}, 4, 'pin-egress multi-route report output count includes result, status, done, and trigger handoff');
    is($report->{port_count}, 8, 'pin-egress multi-route report port count includes public and generated handoff ports');
    is($report->{state_count}, 7, 'pin-egress multi-route report state count includes trigger, await, two drives, done, and timeout states');
    is_deeply($report->{compile_issues}, [], 'pin-egress multi-route schedule report has no compile issues');
    is_deeply(
        $report->{dt_blocks},
        [
            {
                assignments => 1,
                kind        => 'drive',
                name        => 'publish_result',
            },
            {
                assignments => 1,
                kind        => 'drive',
                name        => 'publish_status',
            },
        ],
        'pin-egress multi-route schedule report records both scalar transfer drive bodies',
    );
    is_deeply(
        $report->{transactions},
        [
            {
                name => 'run',
                count => 7,
                states => [qw(
                  run_idle_0
                  run_atl_trigger_1
                  run_await_2
                  run_drive_3
                  run_drive_4
                  run_done_5
                  run_timeout
                )],
            },
        ],
        'pin-egress multi-route schedule report records trigger, await, then both drives',
    );

    my $actor_network = $report->{actor_network};
    is($actor_network->{kind}, 'static_declaration', 'pin-egress multi-route actor network kind');
    is_deeply(
        $actor_network->{generated_tops},
        [
            {
                kind                 => 'resolved_child_trigger_event_handoff',
                top_module           => 'atl_resolved_child_pin_egress_multi_pipeline_top',
                top_fsm              => 'atl_resolved_child_pin_egress_multi_pipeline_top.fsm',
                parent_module        => 'atl_resolved_child_pin_egress_multi_pipeline',
                parent_scheduled_fsm => 'atl_resolved_child_pin_egress_multi_pipeline.fsm',
                instance             => 'worker',
                child_module         => 'atl_resolved_child_pin_egress_multi_pipeline__worker',
                child_scheduled_fsm  => 'atl_resolved_child_pin_egress_multi_pipeline__worker.fsm',
                target_transaction   => 'process',
                trigger_parent_port  => 'worker_process_start',
                trigger_child_port   => 'process_start',
                event                => 'done',
                event_parent_port    => 'worker_done',
                event_child_port     => 'done',
                clock                => 'clk',
                reset                => 'rst_n',
            },
        ],
        'pin-egress multi-route report records the generated ATL top without private data-link internals',
    );
    is_deeply(
        $actor_network->{data_movements},
        [
            {
                kind            => 'scalar_actor_to_pin_handoff',
                drive           => 'publish_result',
                transaction     => 'run',
                context         => 'transaction_body',
                source          => 'external_handoff',
                source_instance => 'worker',
                source_endpoint => 'payload',
                source_signal   => 'worker_payload',
                sink            => 'top_level_pin',
                sink_instance   => 'pins',
                sink_endpoint   => 'result',
                sink_signal     => 'result',
                width           => 1,
                width_source    => 'top_level_output_pin_scalar_one_bit',
                route_lifetime  => 'drive_call_cycle',
                storage         => 'none',
            },
            {
                kind            => 'scalar_actor_to_pin_handoff',
                drive           => 'publish_status',
                transaction     => 'run',
                context         => 'transaction_body',
                source          => 'external_handoff',
                source_instance => 'worker',
                source_endpoint => 'status',
                source_signal   => 'worker_status',
                sink            => 'top_level_pin',
                sink_instance   => 'pins',
                sink_endpoint   => 'status',
                sink_signal     => 'status',
                width           => 1,
                width_source    => 'top_level_output_pin_scalar_one_bit',
                route_lifetime  => 'drive_call_cycle',
                storage         => 'none',
            },
        ],
        'pin-egress multi-route report records both public scalar child-to-pin data movements',
    );
    is_deeply(
        $actor_network->{transaction_triggers},
        [
            {
                owner_transaction  => 'run',
                context            => 'transaction_body',
                instance           => 'worker',
                target_transaction => 'process',
                signal             => 'worker_process_start',
                sink               => 'external_handoff',
            },
        ],
        'pin-egress multi-route report records the worker process trigger handoff',
    );
    is_deeply(
        $actor_network->{event_waits},
        [
            {
                transaction => 'run',
                context     => 'transaction_body',
                instance    => 'worker',
                event       => 'done',
                signal      => 'worker_done',
                source      => 'external_handoff',
            },
        ],
        'pin-egress multi-route report records the worker done event handoff',
    );
}

sub assert_two_child_report_shape {
    my ($report) = @_;

    is($report->{source}, 'atl_two_child_pipeline.isf',
        'two-child schedule report names the fixture');
    is($report->{scheduled_fsm}, 'atl_two_child_pipeline.fsm',
        'two-child schedule report names the scheduled parent FSM');
    is($report->{inputs}, 3, 'two-child report input count includes start and both event handoffs');
    is($report->{outputs}, 3, 'two-child report output count includes done and both trigger handoffs');
    is($report->{port_count}, 6, 'two-child report port count includes public and generated handoff ports');
    is($report->{state_count}, 7, 'two-child report state count includes two trigger/await pairs and timeout');
    is_deeply($report->{compile_issues}, [], 'two-child schedule report has no compile issues');
    is_deeply($report->{dt_blocks}, [], 'two-child schedule report has no drive bodies');
    is_deeply(
        $report->{transactions},
        [
            {
                name => 'run',
                count => 7,
                states => [qw(
                  run_idle_0
                  run_atl_trigger_1
                  run_await_2
                  run_atl_trigger_3
                  run_await_4
                  run_done_5
                  run_timeout
                )],
            },
        ],
        'two-child schedule report records the sequential trigger/await state order',
    );

    my $actor_network = $report->{actor_network};
    is($actor_network->{kind}, 'static_declaration', 'two-child actor network kind');
    is_deeply(
        $actor_network->{instances},
        [
            {
                name            => 'reader',
                actor_type      => 'pkt_lib.packet_reader',
                declaration     => 'actor',
                type_resolution => 'library_actor_export',
                library         => 'common.packet',
                alias           => 'pkt_lib',
                export          => 'packet_reader',
                module          => 'atl_two_child_pipeline__reader',
                scheduled_fsm   => 'atl_two_child_pipeline__reader.fsm',
            },
            {
                name            => 'writer',
                actor_type      => 'pkt_lib.packet_writer',
                declaration     => 'actor',
                type_resolution => 'library_actor_export',
                library         => 'common.packet',
                alias           => 'pkt_lib',
                export          => 'packet_writer',
                module          => 'atl_two_child_pipeline__writer',
                scheduled_fsm   => 'atl_two_child_pipeline__writer.fsm',
            },
        ],
        'two-child report records both resolved child actor metadata entries',
    );
    is_deeply($actor_network->{groups}, [], 'two-child fixture has no permanent static group');
    is_deeply(
        $actor_network->{generated_tops},
        [
            {
                kind                 => 'resolved_children_trigger_event_sequence',
                top_module           => 'atl_two_child_pipeline_top',
                top_fsm              => 'atl_two_child_pipeline_top.fsm',
                parent_module        => 'atl_two_child_pipeline',
                parent_scheduled_fsm => 'atl_two_child_pipeline.fsm',
                clock                => 'clk',
                reset                => 'rst_n',
                children             => [
                    {
                        instance             => 'reader',
                        child_module         => 'atl_two_child_pipeline__reader',
                        child_scheduled_fsm  => 'atl_two_child_pipeline__reader.fsm',
                        target_transaction   => 'capture',
                        trigger_parent_port  => 'reader_capture_start',
                        trigger_child_port   => 'capture_start',
                        event                => 'done',
                        event_parent_port    => 'reader_done',
                        event_child_port     => 'done',
                    },
                    {
                        instance             => 'writer',
                        child_module         => 'atl_two_child_pipeline__writer',
                        child_scheduled_fsm  => 'atl_two_child_pipeline__writer.fsm',
                        target_transaction   => 'emit',
                        trigger_parent_port  => 'writer_emit_start',
                        trigger_child_port   => 'emit_start',
                        event                => 'done',
                        event_parent_port    => 'writer_done',
                        event_child_port     => 'done',
                    },
                ],
            },
        ],
        'two-child report records one generated ATL top with per-child wiring metadata',
    );
    is_deeply($actor_network->{data_movements}, [], 'two-child fixture does not use ATL data movement');
    is_deeply($actor_network->{association_schedules}, [], 'two-child fixture does not use trigger-batch association schedules');
    is_deeply($actor_network->{group_schedules}, [], 'two-child fixture does not use compatibility group schedule evidence');
    is_deeply(
        $actor_network->{transaction_triggers},
        [
            {
                owner_transaction  => 'run',
                context            => 'transaction_body',
                instance           => 'reader',
                target_transaction => 'capture',
                signal             => 'reader_capture_start',
                sink               => 'external_handoff',
            },
            {
                owner_transaction  => 'run',
                context            => 'transaction_body',
                instance           => 'writer',
                target_transaction => 'emit',
                signal             => 'writer_emit_start',
                sink               => 'external_handoff',
            },
        ],
        'two-child report records both transaction trigger handoffs',
    );
    is_deeply(
        $actor_network->{event_waits},
        [
            {
                transaction => 'run',
                context     => 'transaction_body',
                instance    => 'reader',
                event       => 'done',
                signal      => 'reader_done',
                source      => 'external_handoff',
            },
            {
                transaction => 'run',
                context     => 'transaction_body',
                instance    => 'writer',
                event       => 'done',
                signal      => 'writer_done',
                source      => 'external_handoff',
            },
        ],
        'two-child report records both event wait handoffs',
    );
}

sub assert_two_child_data_report_shape {
    my ($report) = @_;

    is($report->{source}, 'atl_two_child_data_pipeline.isf',
        'two-child data schedule report names the fixture');
    is($report->{scheduled_fsm}, 'atl_two_child_data_pipeline.fsm',
        'two-child data schedule report names the scheduled parent FSM');
    is($report->{inputs}, 4, 'two-child data report input count includes start, both events, and reader payload');
    is($report->{outputs}, 4, 'two-child data report output count includes done, both triggers, and writer payload');
    is($report->{port_count}, 8, 'two-child data report port count includes public and generated handoff ports');
    is($report->{state_count}, 8, 'two-child data report state count includes trigger, await, drive, trigger, await, done, and timeout');
    is_deeply($report->{compile_issues}, [], 'two-child data schedule report has no compile issues');
    is_deeply(
        $report->{dt_blocks},
        [
            {
                assignments => 1,
                kind        => 'drive',
                name        => 'forward_payload',
            },
        ],
        'two-child data schedule report records the scalar transfer drive body',
    );
    is_deeply(
        $report->{transactions},
        [
            {
                name => 'run',
                count => 8,
                states => [qw(
                  run_idle_0
                  run_atl_trigger_1
                  run_await_2
                  run_drive_3
                  run_atl_trigger_4
                  run_await_5
                  run_done_6
                  run_timeout
                )],
            },
        ],
        'two-child data schedule report records the selected trigger-await-drive-trigger-await state order',
    );

    my $actor_network = $report->{actor_network};
    is($actor_network->{kind}, 'static_declaration', 'two-child data actor network kind');
    is_deeply(
        $actor_network->{instances},
        [
            {
                name            => 'reader',
                actor_type      => 'pkt_lib.packet_reader',
                declaration     => 'actor',
                type_resolution => 'library_actor_export',
                library         => 'common.packet',
                alias           => 'pkt_lib',
                export          => 'packet_reader',
                module          => 'atl_two_child_data_pipeline__reader',
                scheduled_fsm   => 'atl_two_child_data_pipeline__reader.fsm',
            },
            {
                name            => 'writer',
                actor_type      => 'pkt_lib.packet_writer',
                declaration     => 'actor',
                type_resolution => 'library_actor_export',
                library         => 'common.packet',
                alias           => 'pkt_lib',
                export          => 'packet_writer',
                module          => 'atl_two_child_data_pipeline__writer',
                scheduled_fsm   => 'atl_two_child_data_pipeline__writer.fsm',
            },
        ],
        'two-child data report records both resolved child actor metadata entries',
    );
    is_deeply($actor_network->{groups}, [], 'two-child data fixture has no permanent static group');
    is_deeply(
        $actor_network->{generated_tops},
        [
            {
                kind                 => 'resolved_children_trigger_event_sequence',
                top_module           => 'atl_two_child_data_pipeline_top',
                top_fsm              => 'atl_two_child_data_pipeline_top.fsm',
                parent_module        => 'atl_two_child_data_pipeline',
                parent_scheduled_fsm => 'atl_two_child_data_pipeline.fsm',
                clock                => 'clk',
                reset                => 'rst_n',
                children             => [
                    {
                        instance             => 'reader',
                        child_module         => 'atl_two_child_data_pipeline__reader',
                        child_scheduled_fsm  => 'atl_two_child_data_pipeline__reader.fsm',
                        target_transaction   => 'capture',
                        trigger_parent_port  => 'reader_capture_start',
                        trigger_child_port   => 'capture_start',
                        event                => 'done',
                        event_parent_port    => 'reader_done',
                        event_child_port     => 'done',
                    },
                    {
                        instance             => 'writer',
                        child_module         => 'atl_two_child_data_pipeline__writer',
                        child_scheduled_fsm  => 'atl_two_child_data_pipeline__writer.fsm',
                        target_transaction   => 'emit',
                        trigger_parent_port  => 'writer_emit_start',
                        trigger_child_port   => 'emit_start',
                        event                => 'done',
                        event_parent_port    => 'writer_done',
                        event_child_port     => 'done',
                    },
                ],
            },
        ],
        'two-child data report records one generated ATL top with per-child wiring metadata',
    );
    is_deeply(
        $actor_network->{data_movements},
        [
            {
                kind            => 'scalar_actor_handoff',
                drive           => 'forward_payload',
                transaction     => 'run',
                context         => 'transaction_body',
                source          => 'external_handoff',
                source_instance => 'reader',
                source_endpoint => 'payload',
                source_signal   => 'reader_payload',
                sink            => 'external_handoff',
                sink_instance   => 'writer',
                sink_endpoint   => 'payload',
                sink_signal     => 'writer_payload',
                width           => 1,
                width_source    => 'scalar_one_bit',
                route_lifetime  => 'drive_call_cycle',
                storage         => 'none',
            },
        ],
        'two-child data report records the public scalar generated-child data movement',
    );
    is_deeply($actor_network->{association_schedules}, [], 'two-child data fixture has no trigger-batch association schedules');
    is_deeply($actor_network->{group_schedules}, [], 'two-child data fixture has no compatibility group schedule evidence');
    is_deeply(
        $actor_network->{transaction_triggers},
        [
            {
                owner_transaction  => 'run',
                context            => 'transaction_body',
                instance           => 'reader',
                target_transaction => 'capture',
                signal             => 'reader_capture_start',
                sink               => 'external_handoff',
            },
            {
                owner_transaction  => 'run',
                context            => 'transaction_body',
                instance           => 'writer',
                target_transaction => 'emit',
                signal             => 'writer_emit_start',
                sink               => 'external_handoff',
            },
        ],
        'two-child data report records both transaction trigger handoffs',
    );
    is_deeply(
        $actor_network->{event_waits},
        [
            {
                transaction => 'run',
                context     => 'transaction_body',
                instance    => 'reader',
                event       => 'done',
                signal      => 'reader_done',
                source      => 'external_handoff',
            },
            {
                transaction => 'run',
                context     => 'transaction_body',
                instance    => 'writer',
                event       => 'done',
                signal      => 'writer_done',
                source      => 'external_handoff',
            },
        ],
        'two-child data report records both event wait handoffs',
    );
}

sub assert_two_child_vector_data_report_shape {
    my ($report) = @_;

    is($report->{source}, 'atl_two_child_vector_data_pipeline.isf',
        'two-child vector data schedule report names the fixture');
    is($report->{scheduled_fsm}, 'atl_two_child_vector_data_pipeline.fsm',
        'two-child vector data schedule report names the scheduled parent FSM');
    is($report->{inputs}, 4, 'two-child vector data report input count includes start, both events, and reader payload');
    is($report->{outputs}, 4, 'two-child vector data report output count includes done, both triggers, and writer payload');
    is($report->{port_count}, 8, 'two-child vector data report port count includes public and generated handoff ports');
    is($report->{state_count}, 8, 'two-child vector data report state count includes trigger, await, drive, trigger, await, done, and timeout');
    is_deeply($report->{compile_issues}, [], 'two-child vector data schedule report has no compile issues');
    is_deeply(
        $report->{dt_blocks},
        [
            {
                assignments => 1,
                kind        => 'drive',
                name        => 'forward_payload',
            },
        ],
        'two-child vector data schedule report records the exact-width transfer drive body',
    );
    is_deeply(
        $report->{transactions},
        [
            {
                name => 'run',
                count => 8,
                states => [qw(
                  run_idle_0
                  run_atl_trigger_1
                  run_await_2
                  run_drive_3
                  run_atl_trigger_4
                  run_await_5
                  run_done_6
                  run_timeout
                )],
            },
        ],
        'two-child vector data schedule report records the selected trigger-await-drive-trigger-await state order',
    );

    my $actor_network = $report->{actor_network};
    is($actor_network->{kind}, 'static_declaration', 'two-child vector data actor network kind');
    is_deeply(
        $actor_network->{instances},
        [
            {
                name            => 'reader',
                actor_type      => 'pkt_lib.packet_reader',
                declaration     => 'actor',
                type_resolution => 'library_actor_export',
                library         => 'common.packet',
                alias           => 'pkt_lib',
                export          => 'packet_reader',
                module          => 'atl_two_child_vector_data_pipeline__reader',
                scheduled_fsm   => 'atl_two_child_vector_data_pipeline__reader.fsm',
            },
            {
                name            => 'writer',
                actor_type      => 'pkt_lib.packet_writer',
                declaration     => 'actor',
                type_resolution => 'library_actor_export',
                library         => 'common.packet',
                alias           => 'pkt_lib',
                export          => 'packet_writer',
                module          => 'atl_two_child_vector_data_pipeline__writer',
                scheduled_fsm   => 'atl_two_child_vector_data_pipeline__writer.fsm',
            },
        ],
        'two-child vector data report records both resolved child actor metadata entries',
    );
    is_deeply($actor_network->{groups}, [], 'two-child vector data fixture has no permanent static group');
    is_deeply(
        $actor_network->{generated_tops},
        [
            {
                kind                 => 'resolved_children_trigger_event_sequence',
                top_module           => 'atl_two_child_vector_data_pipeline_top',
                top_fsm              => 'atl_two_child_vector_data_pipeline_top.fsm',
                parent_module        => 'atl_two_child_vector_data_pipeline',
                parent_scheduled_fsm => 'atl_two_child_vector_data_pipeline.fsm',
                clock                => 'clk',
                reset                => 'rst_n',
                children             => [
                    {
                        instance             => 'reader',
                        child_module         => 'atl_two_child_vector_data_pipeline__reader',
                        child_scheduled_fsm  => 'atl_two_child_vector_data_pipeline__reader.fsm',
                        target_transaction   => 'capture',
                        trigger_parent_port  => 'reader_capture_start',
                        trigger_child_port   => 'capture_start',
                        event                => 'done',
                        event_parent_port    => 'reader_done',
                        event_child_port     => 'done',
                    },
                    {
                        instance             => 'writer',
                        child_module         => 'atl_two_child_vector_data_pipeline__writer',
                        child_scheduled_fsm  => 'atl_two_child_vector_data_pipeline__writer.fsm',
                        target_transaction   => 'emit',
                        trigger_parent_port  => 'writer_emit_start',
                        trigger_child_port   => 'emit_start',
                        event                => 'done',
                        event_parent_port    => 'writer_done',
                        event_child_port     => 'done',
                    },
                ],
            },
        ],
        'two-child vector data report records one generated ATL top with per-child wiring metadata',
    );
    is_deeply(
        $actor_network->{data_movements},
        [
            {
                kind            => 'vector_actor_handoff',
                drive           => 'forward_payload',
                transaction     => 'run',
                context         => 'transaction_body',
                source          => 'external_handoff',
                source_instance => 'reader',
                source_endpoint => 'payload',
                source_signal   => 'reader_payload',
                sink            => 'external_handoff',
                sink_instance   => 'writer',
                sink_endpoint   => 'payload',
                sink_signal     => 'writer_payload',
                width           => 8,
                width_source    => 'resolved_child_endpoint_exact_width',
                route_lifetime  => 'drive_call_cycle',
                storage         => 'none',
            },
        ],
        'two-child vector data report records the public exact-width generated-child data movement',
    );
    is_deeply($actor_network->{association_schedules}, [], 'two-child vector data fixture has no trigger-batch association schedules');
    is_deeply($actor_network->{group_schedules}, [], 'two-child vector data fixture has no compatibility group schedule evidence');
    is_deeply(
        $actor_network->{transaction_triggers},
        [
            {
                owner_transaction  => 'run',
                context            => 'transaction_body',
                instance           => 'reader',
                target_transaction => 'capture',
                signal             => 'reader_capture_start',
                sink               => 'external_handoff',
            },
            {
                owner_transaction  => 'run',
                context            => 'transaction_body',
                instance           => 'writer',
                target_transaction => 'emit',
                signal             => 'writer_emit_start',
                sink               => 'external_handoff',
            },
        ],
        'two-child vector data report records both transaction trigger handoffs',
    );
    is_deeply(
        $actor_network->{event_waits},
        [
            {
                transaction => 'run',
                context     => 'transaction_body',
                instance    => 'reader',
                event       => 'done',
                signal      => 'reader_done',
                source      => 'external_handoff',
            },
            {
                transaction => 'run',
                context     => 'transaction_body',
                instance    => 'writer',
                event       => 'done',
                signal      => 'writer_done',
                source      => 'external_handoff',
            },
        ],
        'two-child vector data report records both event wait handoffs',
    );
}

sub assert_two_child_multi_data_report_shape {
    my ($report) = @_;

    is($report->{source}, 'atl_two_child_multi_data_pipeline.isf',
        'two-child multi-data schedule report names the ATL fixture');
    is($report->{scheduled_fsm}, 'atl_two_child_multi_data_pipeline.fsm',
        'two-child multi-data schedule report names the scheduled parent FSM');
    is($report->{inputs}, 5,
        'two-child multi-data report input count includes start, both events, and two reader data handoffs');
    is($report->{outputs}, 5,
        'two-child multi-data report output count includes done, both triggers, and two writer data handoffs');
    is($report->{port_count}, 10,
        'two-child multi-data report port count includes public and generated handoff ports');
    is($report->{state_count}, 9,
        'two-child multi-data report state count includes two drive states, trigger, awaits, done, and timeout');
    is_deeply($report->{compile_issues}, [],
        'two-child multi-data schedule report has no compile issues');
    is_deeply(
        $report->{dt_blocks},
        [
            {
                assignments => 1,
                kind        => 'drive',
                name        => 'forward_payload',
            },
            {
                assignments => 1,
                kind        => 'drive',
                name        => 'forward_sideband',
            },
        ],
        'two-child multi-data schedule report records both scalar transfer drive bodies',
    );
    is_deeply(
        $report->{transactions},
        [
            {
                name => 'run',
                count => 9,
                states => [qw(
                  run_idle_0
                  run_atl_trigger_1
                  run_await_2
                  run_drive_3
                  run_drive_4
                  run_atl_trigger_5
                  run_await_6
                  run_done_7
                  run_timeout
                )],
            },
        ],
        'two-child multi-data schedule report records the selected trigger-await-drive-drive-trigger-await state order',
    );

    my $actor_network = $report->{actor_network};
    is($actor_network->{kind}, 'static_declaration', 'two-child multi-data actor network kind');
    is_deeply(
        $actor_network->{instances},
        [
            {
                name            => 'reader',
                actor_type      => 'pkt_lib.packet_reader',
                declaration     => 'actor',
                type_resolution => 'library_actor_export',
                library         => 'common.packet',
                alias           => 'pkt_lib',
                export          => 'packet_reader',
                module          => 'atl_two_child_multi_data_pipeline__reader',
                scheduled_fsm   => 'atl_two_child_multi_data_pipeline__reader.fsm',
            },
            {
                name            => 'writer',
                actor_type      => 'pkt_lib.packet_writer',
                declaration     => 'actor',
                type_resolution => 'library_actor_export',
                library         => 'common.packet',
                alias           => 'pkt_lib',
                export          => 'packet_writer',
                module          => 'atl_two_child_multi_data_pipeline__writer',
                scheduled_fsm   => 'atl_two_child_multi_data_pipeline__writer.fsm',
            },
        ],
        'two-child multi-data report records both resolved child actor metadata entries',
    );
    is_deeply($actor_network->{groups}, [], 'two-child multi-data fixture has no permanent static group');
    is_deeply(
        $actor_network->{generated_tops},
        [
            {
                kind                 => 'resolved_children_trigger_event_sequence',
                top_module           => 'atl_two_child_multi_data_pipeline_top',
                top_fsm              => 'atl_two_child_multi_data_pipeline_top.fsm',
                parent_module        => 'atl_two_child_multi_data_pipeline',
                parent_scheduled_fsm => 'atl_two_child_multi_data_pipeline.fsm',
                clock                => 'clk',
                reset                => 'rst_n',
                children             => [
                    {
                        instance             => 'reader',
                        child_module         => 'atl_two_child_multi_data_pipeline__reader',
                        child_scheduled_fsm  => 'atl_two_child_multi_data_pipeline__reader.fsm',
                        target_transaction   => 'capture',
                        trigger_parent_port  => 'reader_capture_start',
                        trigger_child_port   => 'capture_start',
                        event                => 'done',
                        event_parent_port    => 'reader_done',
                        event_child_port     => 'done',
                    },
                    {
                        instance             => 'writer',
                        child_module         => 'atl_two_child_multi_data_pipeline__writer',
                        child_scheduled_fsm  => 'atl_two_child_multi_data_pipeline__writer.fsm',
                        target_transaction   => 'emit',
                        trigger_parent_port  => 'writer_emit_start',
                        trigger_child_port   => 'emit_start',
                        event                => 'done',
                        event_parent_port    => 'writer_done',
                        event_child_port     => 'done',
                    },
                ],
            },
        ],
        'two-child multi-data report records one generated ATL top with per-child wiring metadata',
    );
    is_deeply(
        $actor_network->{data_movements},
        [
            {
                kind            => 'scalar_actor_handoff',
                drive           => 'forward_payload',
                transaction     => 'run',
                context         => 'transaction_body',
                source          => 'external_handoff',
                source_instance => 'reader',
                source_endpoint => 'payload',
                source_signal   => 'reader_payload',
                sink            => 'external_handoff',
                sink_instance   => 'writer',
                sink_endpoint   => 'payload',
                sink_signal     => 'writer_payload',
                width           => 1,
                width_source    => 'scalar_one_bit',
                route_lifetime  => 'drive_call_cycle',
                storage         => 'none',
            },
            {
                kind            => 'scalar_actor_handoff',
                drive           => 'forward_sideband',
                transaction     => 'run',
                context         => 'transaction_body',
                source          => 'external_handoff',
                source_instance => 'reader',
                source_endpoint => 'sideband',
                source_signal   => 'reader_sideband',
                sink            => 'external_handoff',
                sink_instance   => 'writer',
                sink_endpoint   => 'sideband',
                sink_signal     => 'writer_sideband',
                width           => 1,
                width_source    => 'scalar_one_bit',
                route_lifetime  => 'drive_call_cycle',
                storage         => 'none',
            },
        ],
        'two-child multi-data report records both public scalar generated-child data movements',
    );
    is_deeply($actor_network->{association_schedules}, [],
        'two-child multi-data fixture has no trigger-batch association schedules');
    is_deeply($actor_network->{group_schedules}, [],
        'two-child multi-data fixture has no compatibility group schedule evidence');
}

sub run_cli {
    my ($command, $label) = @_;
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) =
      run(command => $command);

    diag("$label failed: $error_message") if !$success && defined $error_message;
    return (
        $success,
        join('', @{$stdout_buf || []}),
        join('', @{$stderr_buf || []}),
    );
}

sub lower_source_fails_like {
    my ($source, $pattern, $label) = @_;
    my $ok = eval {
        my $actor = FSM::Adapter::ISF->new()->parse_source($source, "$label.isf");
        FSM::Scheduler::ISF->new()->lower($actor);
        1;
    };

    ok(!$ok, "$label is rejected during lowering");
    like($@, $pattern, "$label diagnostic is targeted");
}

sub lower_actor_fails_like {
    my ($actor, $pattern, $label) = @_;
    my $ok = eval {
        FSM::Scheduler::ISF->new()->lower($actor);
        1;
    };

    ok(!$ok, "$label is rejected during lowering");
    like($@, $pattern, "$label diagnostic is targeted");
}

sub parsed_generated_child_actor_route_actor {
    return FSM::Adapter::ISF->new()->parse_source(
        generated_child_actor_route_fixture(),
        'atl-two-child-lowerer-backstop.isf',
    );
}

sub add_mutated_parent_interface_signal {
    my ($actor, $signal) = @_;
    push @{$actor->{interface}{inputs}}, {
        name  => $signal,
        width => 1,
    };
}

sub add_mutated_parent_storage_signal {
    my ($actor, $signal) = @_;
    push @{$actor->{storage}}, {
        kind    => 'var',
        name    => $signal,
        width   => 1,
        signals => [
            {
                name  => $signal,
                width => 1,
            },
        ],
    };
}

sub lowerer_generated_handoff_collision_pattern {
    my ($role, $signal, $origin) = @_;
    my $role_pattern = quotemeta($role);
    my $signal_pattern = quotemeta($signal);
    my $origin_pattern = quotemeta($origin);

    return qr/lowerer generated-handoff collision: $role_pattern signal '$signal_pattern' conflicts with $origin_pattern '$signal_pattern'/;
}

sub generate_hdl {
    my ($output_file, $extra_args, $label, $source_file) = @_;
    $source_file //= $isf_file;

    my $lower_dir = tempdir(CLEANUP => 1);
    my @command = (
        './bin/fsmgen',
        @{$extra_args || []},
        '--quiet',
        '--outdir',
        $lower_dir,
        '--output',
        $output_file,
        $source_file,
    );
    my ($success, undef, $stderr) = run_cli(\@command, $label);

    ok($success, "$label succeeds");
    is($stderr, '', "$label keeps stderr clean");
    ok(-f $output_file, "$label writes the requested output");
    is_deeply(
        sorted([fsm_basenames_in($lower_dir)]),
        expected_fsm_basenames_for_source($source_file),
        "$label materializes the parent, child, and generated top FSM artifacts",
    );

    return slurp($output_file);
}

sub assert_generated_top_hdl {
    my ($hdl, $label) = @_;

    like($hdl, qr/\bmodule\s+atl_resolved_child_pipeline_top\b/, "$label contains the generated ATL top module");
    like($hdl, qr/\bmodule\s+atl_resolved_child_pipeline\b/, "$label contains the scheduled parent module");
    like($hdl, qr/\bmodule\s+atl_resolved_child_pipeline__worker\b/, "$label contains the resolved child module");
    like($hdl, qr/\bwire\s+comp_link_atl_resolved_child_pipeline_worker_process_start\b/,
        "$label declares the parent-to-child trigger link");
    like($hdl, qr/\bwire\s+comp_link_worker_done\b/,
        "$label declares the child-to-parent event link");
    like($hdl, qr/\.worker_process_start\(comp_link_atl_resolved_child_pipeline_worker_process_start\)/,
        "$label connects the parent trigger handoff to the internal trigger link");
    like($hdl, qr/\.process_start\(comp_link_atl_resolved_child_pipeline_worker_process_start\)/,
        "$label connects the child process start input to the internal trigger link");
    like($hdl, qr/\.done\(comp_link_worker_done\)/,
        "$label connects the child done output to the internal event link");
    like($hdl, qr/\.worker_done\(comp_link_worker_done\)/,
        "$label connects the parent event handoff input to the internal event link");
}

sub assert_pin_ingress_generated_top_hdl {
    my ($hdl, $label) = @_;

    like($hdl, qr/\bmodule\s+atl_resolved_child_pin_ingress_pipeline_top\b/,
        "$label contains the generated ATL top module");
    like($hdl, qr/\bmodule\s+atl_resolved_child_pin_ingress_pipeline\b/,
        "$label contains the scheduled parent module");
    like($hdl, qr/\bmodule\s+atl_resolved_child_pin_ingress_pipeline__worker\b/,
        "$label contains the resolved child module");
    like($hdl, qr/\bmodule\s+atl_resolved_child_pin_ingress_pipeline__worker\s*\([^;]*\binput\s+wire\s+payload\b/s,
        "$label preserves the child payload input as a module port");
    like($hdl, qr/\bwire\s+comp_link_atl_resolved_child_pin_ingress_pipeline_worker_payload\b/,
        "$label declares the parent-to-child payload link");
    like($hdl, qr/\bwire\s+comp_link_atl_resolved_child_pin_ingress_pipeline_worker_process_start\b/,
        "$label declares the parent-to-child trigger link");
    like($hdl, qr/\bwire\s+comp_link_worker_done\b/,
        "$label declares the child-to-parent event link");
    like($hdl, qr/\.payload\(payload\)/,
        "$label connects the public top payload input to the parent payload input");
    like($hdl, qr/\.worker_payload\(comp_link_atl_resolved_child_pin_ingress_pipeline_worker_payload\)/,
        "$label connects the parent payload handoff to the internal payload link");
    like($hdl, qr/\.payload\(comp_link_atl_resolved_child_pin_ingress_pipeline_worker_payload\)/,
        "$label connects the internal payload link to the child payload input");
    like($hdl, qr/\.process_start\(comp_link_atl_resolved_child_pin_ingress_pipeline_worker_process_start\)/,
        "$label connects the child process start input to the internal trigger link");
    like($hdl, qr/\.done\(comp_link_worker_done\)/,
        "$label connects the child done output to the internal event link");
    like($hdl, qr/\.worker_done\(comp_link_worker_done\)/,
        "$label connects the parent event handoff input to the internal event link");
}

sub assert_pin_ingress_vector_generated_top_hdl {
    my ($hdl, $label) = @_;

    like($hdl, qr/\bmodule\s+atl_resolved_child_pin_ingress_vector_pipeline_top\b/,
        "$label contains the generated ATL top module");
    like($hdl, qr/\bmodule\s+atl_resolved_child_pin_ingress_vector_pipeline\b/,
        "$label contains the scheduled parent module");
    like($hdl, qr/\bmodule\s+atl_resolved_child_pin_ingress_vector_pipeline__worker\b/,
        "$label contains the resolved child module");
    like($hdl, qr/\bmodule\s+atl_resolved_child_pin_ingress_vector_pipeline__worker\s*\([^;]*\binput\s+wire\s+\[7:0\]\s+payload\b/s,
        "$label preserves the child payload input as an 8-bit module port");
    like($hdl, qr/\bwire\s+\[7:0\]\s+comp_link_atl_resolved_child_pin_ingress_vector_pipeline_worker_payload\b/,
        "$label declares the 8-bit parent-to-child payload link");
    like($hdl, qr/\bwire\s+comp_link_atl_resolved_child_pin_ingress_vector_pipeline_worker_process_start\b/,
        "$label declares the parent-to-child trigger link");
    like($hdl, qr/\bwire\s+comp_link_worker_done\b/,
        "$label declares the child-to-parent event link");
    like($hdl, qr/\.payload\(payload\)/,
        "$label connects the public top payload input to the parent payload input");
    like($hdl, qr/\.worker_payload\(comp_link_atl_resolved_child_pin_ingress_vector_pipeline_worker_payload\)/,
        "$label connects the parent payload handoff to the internal payload link");
    like($hdl, qr/\.payload\(comp_link_atl_resolved_child_pin_ingress_vector_pipeline_worker_payload\)/,
        "$label connects the internal payload link to the child payload input");
    like($hdl, qr/\.process_start\(comp_link_atl_resolved_child_pin_ingress_vector_pipeline_worker_process_start\)/,
        "$label connects the child process start input to the internal trigger link");
    like($hdl, qr/\.done\(comp_link_worker_done\)/,
        "$label connects the child done output to the internal event link");
    like($hdl, qr/\.worker_done\(comp_link_worker_done\)/,
        "$label connects the parent event handoff input to the internal event link");
}

sub assert_pin_ingress_multi_generated_top_hdl {
    my ($hdl, $label) = @_;

    like($hdl, qr/\bmodule\s+atl_resolved_child_pin_ingress_multi_pipeline_top\b/,
        "$label contains the generated ATL top module");
    like($hdl, qr/\bmodule\s+atl_resolved_child_pin_ingress_multi_pipeline\b/,
        "$label contains the scheduled parent module");
    like($hdl, qr/\bmodule\s+atl_resolved_child_pin_ingress_multi_pipeline__worker\b/,
        "$label contains the resolved child module");
    like($hdl, qr/\bmodule\s+atl_resolved_child_pin_ingress_multi_pipeline__worker\s*\([^;]*\binput\s+wire\s+payload\b/s,
        "$label preserves the child payload input as a module port");
    like($hdl, qr/\bmodule\s+atl_resolved_child_pin_ingress_multi_pipeline__worker\s*\([^;]*\binput\s+wire\s+sideband\b/s,
        "$label preserves the child sideband input as a module port");
    like($hdl, qr/\bwire\s+comp_link_atl_resolved_child_pin_ingress_multi_pipeline_worker_payload\b/,
        "$label declares the parent-to-child payload link");
    like($hdl, qr/\bwire\s+comp_link_atl_resolved_child_pin_ingress_multi_pipeline_worker_sideband\b/,
        "$label declares the parent-to-child sideband link");
    like($hdl, qr/\bwire\s+comp_link_atl_resolved_child_pin_ingress_multi_pipeline_worker_process_start\b/,
        "$label declares the parent-to-child trigger link");
    like($hdl, qr/\bwire\s+comp_link_worker_done\b/,
        "$label declares the child-to-parent event link");
    like($hdl, qr/\.payload\(payload\)/,
        "$label connects the public top payload input to the parent payload input");
    like($hdl, qr/\.sideband\(sideband\)/,
        "$label connects the public top sideband input to the parent sideband input");
    like($hdl, qr/\.worker_payload\(comp_link_atl_resolved_child_pin_ingress_multi_pipeline_worker_payload\)/,
        "$label connects the parent payload handoff to the internal payload link");
    like($hdl, qr/\.worker_sideband\(comp_link_atl_resolved_child_pin_ingress_multi_pipeline_worker_sideband\)/,
        "$label connects the parent sideband handoff to the internal sideband link");
    like($hdl, qr/\.payload\(comp_link_atl_resolved_child_pin_ingress_multi_pipeline_worker_payload\)/,
        "$label connects the internal payload link to the child payload input");
    like($hdl, qr/\.sideband\(comp_link_atl_resolved_child_pin_ingress_multi_pipeline_worker_sideband\)/,
        "$label connects the internal sideband link to the child sideband input");
    like($hdl, qr/\.process_start\(comp_link_atl_resolved_child_pin_ingress_multi_pipeline_worker_process_start\)/,
        "$label connects the child process start input to the internal trigger link");
    like($hdl, qr/\.done\(comp_link_worker_done\)/,
        "$label connects the child done output to the internal event link");
    like($hdl, qr/\.worker_done\(comp_link_worker_done\)/,
        "$label connects the parent event handoff input to the internal event link");
}

sub assert_pin_egress_generated_top_hdl {
    my ($hdl, $label) = @_;

    like($hdl, qr/\bmodule\s+atl_resolved_child_pin_egress_pipeline_top\b/,
        "$label contains the generated ATL top module");
    like($hdl, qr/\bmodule\s+atl_resolved_child_pin_egress_pipeline\b/,
        "$label contains the scheduled parent module");
    like($hdl, qr/\bmodule\s+atl_resolved_child_pin_egress_pipeline__worker\b/,
        "$label contains the resolved child module");
    like($hdl, qr/\bmodule\s+atl_resolved_child_pin_egress_pipeline__worker\s*\([^;]*\boutput\s+reg\s+payload\b/s,
        "$label preserves the child payload output as a module port");
    like($hdl, qr/\bwire\s+comp_link_worker_payload\b/,
        "$label declares the child-to-parent payload link");
    like($hdl, qr/\bwire\s+comp_link_atl_resolved_child_pin_egress_pipeline_worker_process_start\b/,
        "$label declares the parent-to-child trigger link");
    like($hdl, qr/\bwire\s+comp_link_worker_done\b/,
        "$label declares the child-to-parent event link");
    like($hdl, qr/\.result\(result\)/,
        "$label connects the parent result output to the public top result output");
    like($hdl, qr/\.payload\(comp_link_worker_payload\)/,
        "$label connects the child payload output to the internal payload link");
    like($hdl, qr/\.worker_payload\(comp_link_worker_payload\)/,
        "$label connects the internal payload link to the parent payload handoff");
    like($hdl, qr/\.process_start\(comp_link_atl_resolved_child_pin_egress_pipeline_worker_process_start\)/,
        "$label connects the child process start input to the internal trigger link");
    like($hdl, qr/\.done\(comp_link_worker_done\)/,
        "$label connects the child done output to the internal event link");
    like($hdl, qr/\.worker_done\(comp_link_worker_done\)/,
        "$label connects the parent event handoff input to the internal event link");
}

sub assert_pin_egress_multi_generated_top_hdl {
    my ($hdl, $label) = @_;

    like($hdl, qr/\bmodule\s+atl_resolved_child_pin_egress_multi_pipeline_top\b/,
        "$label contains the generated ATL top module");
    like($hdl, qr/\bmodule\s+atl_resolved_child_pin_egress_multi_pipeline\b/,
        "$label contains the scheduled parent module");
    like($hdl, qr/\bmodule\s+atl_resolved_child_pin_egress_multi_pipeline__worker\b/,
        "$label contains the resolved child module");
    like($hdl, qr/\bmodule\s+atl_resolved_child_pin_egress_multi_pipeline__worker\s*\([^;]*\boutput\s+reg\s+payload\b/s,
        "$label preserves the child payload output as a module port");
    like($hdl, qr/\bmodule\s+atl_resolved_child_pin_egress_multi_pipeline__worker\s*\([^;]*\boutput\s+reg\s+status\b/s,
        "$label preserves the child status output as a module port");
    like($hdl, qr/\bwire\s+comp_link_worker_payload\b/,
        "$label declares the child-to-parent payload link");
    like($hdl, qr/\bwire\s+comp_link_worker_status\b/,
        "$label declares the child-to-parent status link");
    like($hdl, qr/\bwire\s+comp_link_atl_resolved_child_pin_egress_multi_pipeline_worker_process_start\b/,
        "$label declares the parent-to-child trigger link");
    like($hdl, qr/\bwire\s+comp_link_worker_done\b/,
        "$label declares the child-to-parent event link");
    like($hdl, qr/\.result\(result\)/,
        "$label connects the parent result output to the public top result output");
    like($hdl, qr/\.status\(status\)/,
        "$label connects the parent status output to the public top status output");
    like($hdl, qr/\.payload\(comp_link_worker_payload\)/,
        "$label connects the child payload output to the internal payload link");
    like($hdl, qr/\.status\(comp_link_worker_status\)/,
        "$label connects the child status output to the internal status link");
    like($hdl, qr/\.worker_payload\(comp_link_worker_payload\)/,
        "$label connects the internal payload link to the parent payload handoff");
    like($hdl, qr/\.worker_status\(comp_link_worker_status\)/,
        "$label connects the internal status link to the parent status handoff");
    like($hdl, qr/\.process_start\(comp_link_atl_resolved_child_pin_egress_multi_pipeline_worker_process_start\)/,
        "$label connects the child process start input to the internal trigger link");
    like($hdl, qr/\.done\(comp_link_worker_done\)/,
        "$label connects the child done output to the internal event link");
    like($hdl, qr/\.worker_done\(comp_link_worker_done\)/,
        "$label connects the parent event handoff input to the internal event link");
}

sub assert_two_child_generated_top_hdl {
    my ($hdl, $label) = @_;

    like($hdl, qr/\bmodule\s+atl_two_child_pipeline_top\b/,
        "$label contains the generated ATL top module");
    like($hdl, qr/\bmodule\s+atl_two_child_pipeline\b/,
        "$label contains the scheduled parent module");
    like($hdl, qr/\bmodule\s+atl_two_child_pipeline__reader\b/,
        "$label contains the resolved reader child module");
    like($hdl, qr/\bmodule\s+atl_two_child_pipeline__writer\b/,
        "$label contains the resolved writer child module");
    like($hdl, qr/\bwire\s+comp_link_atl_two_child_pipeline_reader_capture_start\b/,
        "$label declares the parent-to-reader trigger link");
    like($hdl, qr/\bwire\s+comp_link_reader_done\b/,
        "$label declares the reader-to-parent event link");
    like($hdl, qr/\bwire\s+comp_link_atl_two_child_pipeline_writer_emit_start\b/,
        "$label declares the parent-to-writer trigger link");
    like($hdl, qr/\bwire\s+comp_link_writer_done\b/,
        "$label declares the writer-to-parent event link");
    like($hdl, qr/\.reader_capture_start\(comp_link_atl_two_child_pipeline_reader_capture_start\)/,
        "$label connects the parent reader trigger handoff to the internal reader trigger link");
    like($hdl, qr/\.capture_start\(comp_link_atl_two_child_pipeline_reader_capture_start\)/,
        "$label connects the reader capture start input to the internal reader trigger link");
    like($hdl, qr/\.done\(comp_link_reader_done\)/,
        "$label connects the reader done output to the internal reader event link");
    like($hdl, qr/\.reader_done\(comp_link_reader_done\)/,
        "$label connects the parent reader event handoff input to the internal reader event link");
    like($hdl, qr/\.writer_emit_start\(comp_link_atl_two_child_pipeline_writer_emit_start\)/,
        "$label connects the parent writer trigger handoff to the internal writer trigger link");
    like($hdl, qr/\.emit_start\(comp_link_atl_two_child_pipeline_writer_emit_start\)/,
        "$label connects the writer emit start input to the internal writer trigger link");
    like($hdl, qr/\.done\(comp_link_writer_done\)/,
        "$label connects the writer done output to the internal writer event link");
    like($hdl, qr/\.writer_done\(comp_link_writer_done\)/,
        "$label connects the parent writer event handoff input to the internal writer event link");
}

sub assert_two_child_data_generated_top_hdl {
    my ($hdl, $label) = @_;

    like($hdl, qr/\bmodule\s+atl_two_child_data_pipeline_top\b/,
        "$label contains the generated ATL top module");
    like($hdl, qr/\bmodule\s+atl_two_child_data_pipeline\b/,
        "$label contains the scheduled parent module");
    like($hdl, qr/\bmodule\s+atl_two_child_data_pipeline__reader\b/,
        "$label contains the resolved reader child module");
    like($hdl, qr/\bmodule\s+atl_two_child_data_pipeline__writer\b/,
        "$label contains the resolved writer child module");
    like($hdl, qr/\bmodule\s+atl_two_child_data_pipeline__reader\s*\([^;]*\boutput\s+reg\s+payload\b/s,
        "$label preserves the reader payload output as a module port");
    like($hdl, qr/\bmodule\s+atl_two_child_data_pipeline__writer\s*\([^;]*\binput\s+wire\s+payload\b/s,
        "$label preserves the writer payload input as a module port");
    like($hdl, qr/\bwire\s+comp_link_reader_payload\b/,
        "$label declares the reader-to-parent payload link");
    like($hdl, qr/\bwire\s+comp_link_atl_two_child_data_pipeline_writer_payload\b/,
        "$label declares the parent-to-writer payload link");
    like($hdl, qr/\bwire\s+comp_link_atl_two_child_data_pipeline_reader_capture_start\b/,
        "$label declares the parent-to-reader trigger link");
    like($hdl, qr/\bwire\s+comp_link_reader_done\b/,
        "$label declares the reader-to-parent event link");
    like($hdl, qr/\bwire\s+comp_link_atl_two_child_data_pipeline_writer_emit_start\b/,
        "$label declares the parent-to-writer trigger link");
    like($hdl, qr/\bwire\s+comp_link_writer_done\b/,
        "$label declares the writer-to-parent event link");
    like($hdl, qr/\.reader_payload\(comp_link_reader_payload\)/,
        "$label connects the reader payload link to the parent source handoff input");
    like($hdl, qr/\.payload\(comp_link_reader_payload\)/,
        "$label connects the reader payload output to the internal payload link");
    like($hdl, qr/\.writer_payload\(comp_link_atl_two_child_data_pipeline_writer_payload\)/,
        "$label connects the parent sink handoff output to the writer payload link");
    like($hdl, qr/\.payload\(comp_link_atl_two_child_data_pipeline_writer_payload\)/,
        "$label connects the internal writer payload link to the writer payload input");
    like($hdl, qr/\.capture_start\(comp_link_atl_two_child_data_pipeline_reader_capture_start\)/,
        "$label connects the reader capture start input to the internal trigger link");
    like($hdl, qr/\.done\(comp_link_reader_done\)/,
        "$label connects the reader done output to the internal event link");
    like($hdl, qr/\.emit_start\(comp_link_atl_two_child_data_pipeline_writer_emit_start\)/,
        "$label connects the writer emit start input to the internal trigger link");
    like($hdl, qr/\.writer_done\(comp_link_writer_done\)/,
        "$label connects the parent writer event handoff input to the internal event link");
}

sub assert_two_child_vector_data_generated_top_hdl {
    my ($hdl, $label) = @_;

    like($hdl, qr/\bmodule\s+atl_two_child_vector_data_pipeline_top\b/,
        "$label contains the generated ATL top module");
    like($hdl, qr/\bmodule\s+atl_two_child_vector_data_pipeline\b/,
        "$label contains the scheduled parent module");
    like($hdl, qr/\bmodule\s+atl_two_child_vector_data_pipeline__reader\b/,
        "$label contains the resolved reader child module");
    like($hdl, qr/\bmodule\s+atl_two_child_vector_data_pipeline__writer\b/,
        "$label contains the resolved writer child module");
    like($hdl, qr/\bmodule\s+atl_two_child_vector_data_pipeline__reader\s*\([^;]*\boutput\s+reg\s+\[[^]]+\]\s+payload\b/s,
        "$label preserves the reader vector payload output as a module port");
    like($hdl, qr/\bmodule\s+atl_two_child_vector_data_pipeline__writer\s*\([^;]*\binput\s+wire\s+\[[^]]+\]\s+payload\b/s,
        "$label preserves the writer vector payload input as a module port");
    like($hdl, qr/\bwire\s+\[[^]]+\]\s+comp_link_reader_payload\b/,
        "$label declares the vector reader-to-parent payload link");
    like($hdl, qr/\bwire\s+\[[^]]+\]\s+comp_link_atl_two_child_vector_data_pipeline_writer_payload\b/,
        "$label declares the vector parent-to-writer payload link");
    like($hdl, qr/\.reader_payload\(comp_link_reader_payload\)/,
        "$label connects the vector reader payload link to the parent source handoff input");
    like($hdl, qr/\.payload\(comp_link_reader_payload\)/,
        "$label connects the reader vector payload output to the internal payload link");
    like($hdl, qr/\.writer_payload\(comp_link_atl_two_child_vector_data_pipeline_writer_payload\)/,
        "$label connects the parent vector sink handoff output to the writer payload link");
    like($hdl, qr/\.payload\(comp_link_atl_two_child_vector_data_pipeline_writer_payload\)/,
        "$label connects the internal vector writer payload link to the writer payload input");
    like($hdl, qr/\.capture_start\(comp_link_atl_two_child_vector_data_pipeline_reader_capture_start\)/,
        "$label connects the reader capture start input to the internal trigger link");
    like($hdl, qr/\.done\(comp_link_reader_done\)/,
        "$label connects the reader done output to the internal event link");
    like($hdl, qr/\.emit_start\(comp_link_atl_two_child_vector_data_pipeline_writer_emit_start\)/,
        "$label connects the writer emit start input to the internal trigger link");
    like($hdl, qr/\.writer_done\(comp_link_writer_done\)/,
        "$label connects the parent writer event handoff input to the internal event link");
}

sub assert_two_child_multi_data_generated_top_hdl {
    my ($hdl, $label) = @_;

    like($hdl, qr/\bmodule\s+atl_two_child_multi_data_pipeline_top\b/,
        "$label contains the generated ATL top module");
    like($hdl, qr/\bmodule\s+atl_two_child_multi_data_pipeline\b/,
        "$label contains the scheduled parent module");
    like($hdl, qr/\bmodule\s+atl_two_child_multi_data_pipeline__reader\b/,
        "$label contains the resolved reader child module");
    like($hdl, qr/\bmodule\s+atl_two_child_multi_data_pipeline__writer\b/,
        "$label contains the resolved writer child module");
    like($hdl, qr/\bmodule\s+atl_two_child_multi_data_pipeline__reader\s*\([^;]*\boutput\s+reg\s+payload\b/s,
        "$label preserves the reader payload output as a module port");
    like($hdl, qr/\bmodule\s+atl_two_child_multi_data_pipeline__reader\s*\([^;]*\boutput\s+reg\s+sideband\b/s,
        "$label preserves the reader sideband output as a module port");
    like($hdl, qr/\bmodule\s+atl_two_child_multi_data_pipeline__writer\s*\([^;]*\binput\s+wire\s+payload\b/s,
        "$label preserves the writer payload input as a module port");
    like($hdl, qr/\bmodule\s+atl_two_child_multi_data_pipeline__writer\s*\([^;]*\binput\s+wire\s+sideband\b/s,
        "$label preserves the writer sideband input as a module port");
    like($hdl, qr/\bwire\s+comp_link_reader_payload\b/,
        "$label declares the reader-to-parent payload link");
    like($hdl, qr/\bwire\s+comp_link_reader_sideband\b/,
        "$label declares the reader-to-parent sideband link");
    like($hdl, qr/\bwire\s+comp_link_atl_two_child_multi_data_pipeline_writer_payload\b/,
        "$label declares the parent-to-writer payload link");
    like($hdl, qr/\bwire\s+comp_link_atl_two_child_multi_data_pipeline_writer_sideband\b/,
        "$label declares the parent-to-writer sideband link");
    like($hdl, qr/\bwire\s+comp_link_atl_two_child_multi_data_pipeline_reader_capture_start\b/,
        "$label declares the parent-to-reader trigger link");
    like($hdl, qr/\bwire\s+comp_link_atl_two_child_multi_data_pipeline_writer_emit_start\b/,
        "$label declares the parent-to-writer trigger link");
    like($hdl, qr/\.reader_payload\(comp_link_reader_payload\)/,
        "$label connects the reader payload link to the parent source handoff input");
    like($hdl, qr/\.reader_sideband\(comp_link_reader_sideband\)/,
        "$label connects the reader sideband link to the parent source handoff input");
    like($hdl, qr/\.payload\(comp_link_reader_payload\)/,
        "$label connects the reader payload output to the internal payload link");
    like($hdl, qr/\.sideband\(comp_link_reader_sideband\)/,
        "$label connects the reader sideband output to the internal sideband link");
    like($hdl, qr/\.writer_payload\(comp_link_atl_two_child_multi_data_pipeline_writer_payload\)/,
        "$label connects the parent payload sink handoff output to the writer payload link");
    like($hdl, qr/\.writer_sideband\(comp_link_atl_two_child_multi_data_pipeline_writer_sideband\)/,
        "$label connects the parent sideband sink handoff output to the writer sideband link");
    like($hdl, qr/\.payload\(comp_link_atl_two_child_multi_data_pipeline_writer_payload\)/,
        "$label connects the internal writer payload link to the writer payload input");
    like($hdl, qr/\.sideband\(comp_link_atl_two_child_multi_data_pipeline_writer_sideband\)/,
        "$label connects the internal writer sideband link to the writer sideband input");
    like($hdl, qr/\.capture_start\(comp_link_atl_two_child_multi_data_pipeline_reader_capture_start\)/,
        "$label connects the reader capture start input to the internal trigger link");
    like($hdl, qr/\.emit_start\(comp_link_atl_two_child_multi_data_pipeline_writer_emit_start\)/,
        "$label connects the writer emit start input to the internal trigger link");
}

sub atl_fixture_variant {
    my ($library) = @_;
    my $actor = <<'ISF';
(actor atl_resolved_child_pipeline
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input start)
    (output done))
  (imports
    (library common.packet as pkt_lib))
  (instance worker of pkt_lib.packet_worker)
  (transaction run
    (on start)
    (trigger worker.process)
    (await worker.done)
    (complete done)))

ISF
    return $actor . $library;
}

sub pin_ingress_atl_fixture_variant {
    my ($library, $options) = @_;
    $options ||= {};
    my $route_drive = $options->{route_drive_parameters}
        ? "  (drive (feed_worker value)\n"
        : "  (drive feed_worker\n";
    my $route_drive_call = $options->{drive_call_actual}
        ? "    (drive feed_worker start)\n"
        : "    (drive feed_worker)\n";
    my $actor = <<'ISF';
(actor atl_resolved_child_pin_ingress_pipeline
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input start)
    (input payload)
    (output done))
  (imports
    (library common.packet as pkt_lib))
  (instance worker of pkt_lib.packet_worker)
ISF
    $actor .= $route_drive;
    $actor .= <<'ISF';
    (worker.payload pins.payload))
  (transaction run
    (on start)
ISF
    $actor .= $route_drive_call;
    $actor .= <<'ISF';
    (trigger worker.process)
    (await worker.done)
    (complete done)))

ISF
    return $actor . $library;
}

sub pin_ingress_vector_atl_fixture_variant {
    my ($child_payload_width) = @_;
    $child_payload_width //= 8;
    return <<"ISF";
(actor atl_resolved_child_pin_ingress_vector_pipeline
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input start)
    (input payload (width 8))
    (output done))
  (imports
    (library common.packet as pkt_lib))
  (instance worker of pkt_lib.packet_worker)
  (drive feed_worker
    (worker.payload pins.payload))
  (transaction run
    (on start)
    (drive feed_worker)
    (trigger worker.process)
    (await worker.done)
    (complete done)))

(library common.packet
  (exports
    (actor packet_worker))
  (actor packet_worker
    (clock clk)
    (reset (rst_n async active_low))
    (interface
      (input process_start)
      (input payload (width $child_payload_width))
      (output done))
    (transaction process
      (on process_start)
      (complete done))))
ISF
}

sub pin_ingress_multi_atl_fixture_variant {
    my ($library, $options) = @_;
    $options ||= {};
    my $second_source = $options->{duplicate_source_pin} ? 'payload' : 'sideband';
    my $between_drives = $options->{interleaved_sample_between_drives}
        ? "    (sample start as observed)\n"
        : '';
    my $actor = <<"ISF";
(actor atl_resolved_child_pin_ingress_multi_pipeline
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input start)
    (input payload)
    (input sideband)
    (output done))
  (imports
    (library common.packet as pkt_lib))
  (instance worker of pkt_lib.packet_worker)
  (drive feed_payload
    (worker.payload pins.payload))
  (drive feed_sideband
    (worker.sideband pins.$second_source))
  (transaction run
    (on start)
    (drive feed_payload)
$between_drives    (drive feed_sideband)
    (trigger worker.process)
    (await worker.done)
    (complete done)))

ISF
    return $actor . $library;
}

sub default_pin_ingress_multi_library {
    return <<'LIBRARY';
(library common.packet
  (exports
    (actor packet_worker))
  (actor packet_worker
    (clock clk)
    (reset (rst_n async active_low))
    (interface
      (input process_start)
      (input payload)
      (input sideband)
      (output done))
    (transaction process
      (on process_start)
      (complete done))))
LIBRARY
}

sub pin_egress_atl_fixture_variant {
    my ($library, $options) = @_;
    $options ||= {};
    my $route_drive = $options->{route_drive_parameters}
        ? "  (drive (publish_result value)\n"
        : "  (drive publish_result\n";
    my $route_drive_call = $options->{drive_call_actual}
        ? "    (drive publish_result start)\n"
        : "    (drive publish_result)\n";
    my $clauses = $options->{drive_before_event_wait}
        ? $route_drive_call
            . "    (trigger worker.process)\n"
            . "    (await worker.done)\n"
        : "    (trigger worker.process)\n"
            . "    (await worker.done)\n"
            . $route_drive_call;

    my $actor = <<'ISF';
(actor atl_resolved_child_pin_egress_pipeline
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input start)
    (output result)
    (output done))
  (imports
    (library common.packet as pkt_lib))
  (instance worker of pkt_lib.packet_worker)
ISF
    $actor .= $route_drive;
    $actor .= <<'ISF';
    (pins.result worker.payload))
  (transaction run
    (on start)
ISF
    $actor .= $clauses;
    $actor .= <<'ISF';
    (complete done)))

ISF
    return $actor . $library;
}

sub pin_egress_multi_atl_fixture_variant {
    my ($library, $options) = @_;
    $options ||= {};
    my $second_sink = $options->{duplicate_sink_pin} ? 'result' : 'status';
    my $second_source = $options->{duplicate_source_endpoint} ? 'payload' : 'status';
    my $between_drives = $options->{interleaved_sample_between_drives}
        ? "    (sample start as observed)\n"
        : '';
    my $actor = <<"ISF";
(actor atl_resolved_child_pin_egress_multi_pipeline
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input start)
    (output result)
    (output status)
    (output done))
  (imports
    (library common.packet as pkt_lib))
  (instance worker of pkt_lib.packet_worker)
  (drive publish_result
    (pins.result worker.payload))
  (drive publish_status
    (pins.$second_sink worker.$second_source))
  (transaction run
    (on start)
    (trigger worker.process)
    (await worker.done)
    (drive publish_result)
$between_drives    (drive publish_status)
    (complete done)))

ISF
    return $actor . $library;
}

sub default_pin_egress_multi_library {
    return <<'LIBRARY';
(library common.packet
  (exports
    (actor packet_worker))
  (actor packet_worker
    (clock clk)
    (reset (rst_n async active_low))
    (interface
      (input process_start)
      (output payload)
      (output status)
      (output done))
    (transaction process
      (on process_start)
      (set payload process_start)
      (set status process_start)
      (complete done))))
LIBRARY
}

sub generated_child_actor_route_fixture {
    my ($options) = @_;
    $options ||= {};
    my $route_drive_call = $options->{drive_call_actual}
        ? "    (drive forward_payload start)\n"
        : "    (drive forward_payload)\n";
    my $clauses = $options->{split_sink_transaction}
        ? <<'CLAUSES'
    (trigger reader.capture)
    (await reader.done)
    (drive forward_payload)
CLAUSES
        : $options->{drive_before_reader_done}
        ? <<'CLAUSES'
    (trigger reader.capture)
    (drive forward_payload)
    (await reader.done)
    (trigger writer.emit)
    (await writer.done)
CLAUSES
        : $options->{source_wait_before_trigger}
        ? <<'CLAUSES'
    (await reader.done)
    (trigger reader.capture)
    (drive forward_payload)
    (trigger writer.emit)
    (await writer.done)
CLAUSES
        : $options->{interleaved_sample_before_drive}
        ? <<'CLAUSES'
    (trigger reader.capture)
    (await reader.done)
    (sample start as observed)
    (drive forward_payload)
    (trigger writer.emit)
    (await writer.done)
CLAUSES
        : $options->{sink_trigger_before_drive}
        ? <<'CLAUSES'
    (trigger reader.capture)
    (await reader.done)
    (trigger writer.emit)
    (drive forward_payload)
    (await writer.done)
CLAUSES
        : $options->{sink_wait_before_trigger}
        ? <<'CLAUSES'
    (trigger reader.capture)
    (await reader.done)
    (drive forward_payload)
    (await writer.done)
    (trigger writer.emit)
CLAUSES
        : undef;
    if (!defined $clauses) {
        my $pre_route_sample = $options->{pre_route_sample}
            ? "    (sample start as observed)\n"
            : '';
        my $post_route_sample = $options->{post_route_sample}
            ? "    (sample start as observed)\n"
            : '';
        my $extra_reader_trigger = $options->{extra_reader_trigger}
            ? "    (trigger reader.flush)\n"
            : '';
        my $extra_writer_trigger = $options->{extra_writer_trigger}
            ? "    (trigger writer.prime)\n"
            : '';
        my $extra_reader_wait = $options->{extra_reader_wait}
            ? "    (await reader.done)\n"
            : '';
        my $extra_writer_wait = $options->{extra_writer_wait}
            ? "    (await writer.done)\n"
            : '';
        $clauses = $pre_route_sample
            . "    (trigger reader.capture)\n"
            . "    (await reader.done)\n"
            . $extra_reader_wait
            . $extra_reader_trigger
            . $route_drive_call
            . "    (trigger writer.emit)\n"
            . $extra_writer_trigger
            . "    (await writer.done)\n"
            . $extra_writer_wait
            . $post_route_sample;
    }
    my $writer_payload_width = $options->{writer_payload_width} || 1;
    my $reader_payload_width = $options->{reader_payload_width} || 1;
    my $reader_clock = $options->{reader_clock} || 'clk';
    my $writer_clock = $options->{writer_clock} || 'clk';
    my $reader_reset = $options->{reader_reset} || '(rst_n async active_low)';
    my $writer_reset = $options->{writer_reset} || '(rst_n async active_low)';
    my $writer_payload_port = $options->{omit_writer_payload}
        ? ''
        : _interface_port_decl('input', 'payload', $writer_payload_width);
    my $reader_payload_port = $options->{omit_reader_payload}
        ? ''
        : _interface_port_decl('output', 'payload', $reader_payload_width);
    my $drive_body = "    (writer.payload reader.payload)";
    if ($options->{same_child_route}) {
        $drive_body = "    (reader.payload_in reader.payload_out)";
    }
    elsif ($options->{extra_drive_pair}) {
        $drive_body = "    (writer.payload reader.payload)\n    (writer.sideband reader.sideband)";
    }
    elsif ($options->{source_expression}) {
        $drive_body = "    (writer.payload (+ reader.payload 1))";
    }
    elsif ($options->{sink_expression}) {
        $drive_body = "    ((+ writer.payload 1) reader.payload)";
    }
    my $reader_self_route_ports = $options->{same_child_route}
        ? "      (input payload_in)\n      (output payload_out)\n"
        : '';
    my $reader_extra_trigger_ports = $options->{extra_reader_trigger}
        ? "      (input flush_start)\n      (output flush_done)\n"
        : '';
    my $reader_extra_transaction = $options->{extra_reader_trigger}
        ? <<'ISF'
    (transaction flush
      (on flush_start)
      (complete flush_done))
ISF
        : '';
    my $writer_extra_trigger_ports = $options->{extra_writer_trigger}
        ? "      (input prime_start)\n      (output prime_done)\n"
        : '';
    my $writer_extra_transaction = $options->{extra_writer_trigger}
        ? <<'ISF'
    (transaction prime
      (on prime_start)
      (complete prime_done))
ISF
        : '';
    my $second_route_drive = $options->{second_route_drive}
        ? <<'ISF'
  (drive forward_sideband
    (writer.sideband reader.sideband))
ISF
        : '';
    my $repeated_drive_call = $options->{repeated_drive_call}
        ? "    (drive forward_payload)\n"
        : '';
    my $interface_extra = $options->{split_sink_transaction}
        ? "    (input continue)\n    (output staged)\n"
        : '';
    $interface_extra .= "    (input alt_start)\n"
        if $options->{extra_start_boundary};
    $interface_extra .= "    (output extra_done)\n"
        if $options->{extra_completion_boundary};
    $interface_extra .= "    (output launch)\n"
        if $options->{start_boundary_output};
    $interface_extra .= "    (input ack)\n"
        if $options->{completion_boundary_input};
    $interface_extra .= _interface_port_decl('input', $options->{parent_interface_collision}, 1)
        if $options->{parent_interface_collision};
    my $parent_storage = $options->{parent_storage_collision}
        ? "  (storage\n    (var $options->{parent_storage_collision} (width 1)))\n"
        : '';
    my $extra_start_boundary = $options->{extra_start_boundary}
        ? "    (on alt_start)\n"
        : '';
    my $extra_completion_boundary = $options->{extra_completion_boundary}
        ? "    (complete extra_done)\n"
        : '';
    my $run_complete = $options->{split_sink_transaction} ? 'staged' : 'done';
    my $start_pin = $options->{start_boundary_output}
        ? 'launch'
        : $options->{start_boundary_undeclared}
            ? 'missing_start'
            : 'start';
    my $completion_pin = $options->{completion_boundary_input}
        ? 'ack'
        : $options->{completion_boundary_undeclared}
            ? 'missing_done'
            : $run_complete;
    my $start_boundary = $options->{start_boundary_sample}
        ? "    (on $start_pin (sample start as observed))\n"
        : "    (on $start_pin)\n";
    my $completion_boundary = $options->{completion_payload_operand}
        ? "    (complete $completion_pin payload)\n"
        : "    (complete $completion_pin)\n";
    my $split_sink_transaction = $options->{split_sink_transaction}
        ? <<'ISF'
  (transaction finish
    (on continue)
    (trigger writer.emit)
    (await writer.done)
    (complete done))
ISF
        : '';

    my $actor = <<'ISF';
(actor atl_two_child_data_pipeline
  (clock clk)
  (reset (rst_n async active_low))
  (interface
ISF
    $actor .= _interface_port_decl('input', 'start', $options->{start_width} || 1);
    $actor .= $interface_extra;
    $actor .= _interface_port_decl('output', 'done', $options->{completion_width} || 1);
    $actor .= <<'ISF';
  )
ISF
    $actor .= $parent_storage;
    $actor .= <<'ISF';
  (imports
    (library common.packet as pkt_lib))
ISF
    my $route_drive = $options->{route_drive_parameters}
        ? "  (drive (forward_payload value)\n"
        : "  (drive forward_payload\n";
    $route_drive .= $drive_body;
    $route_drive .= <<'ISF';
)
ISF
    $actor .= $route_drive if $options->{drive_before_instances};
    $actor .= <<'ISF';
  (instance reader of pkt_lib.packet_reader)
  (instance writer of pkt_lib.packet_writer)
ISF
    $actor .= $route_drive unless $options->{drive_before_instances};
    $actor .= $second_route_drive;
    $actor .= <<'ISF';
  (transaction run
ISF
    $actor .= $start_boundary;
    $actor .= $extra_start_boundary;
    $actor .= $clauses;
    $actor .= $repeated_drive_call;
    $actor .= $extra_completion_boundary;
    $actor .= $completion_boundary;
    $actor .= "  )\n";
    $actor .= $split_sink_transaction;
    $actor .= ")\n\n";
    my $library = <<'ISF';
(library common.packet
  (exports
    (actor packet_reader)
    (actor packet_writer))
  (actor packet_reader
ISF
    $library .= "    (clock $reader_clock)\n";
    $library .= "    (reset $reader_reset)\n";
    $library .= <<'ISF';
    (interface
      (input capture_start)
ISF
    $library .= $reader_payload_port;
    $library .= $reader_self_route_ports;
    $library .= $reader_extra_trigger_ports;
    $library .= <<'ISF';
      (output done))
    (transaction capture
      (on capture_start)
      (set payload capture_start)
      (complete done))
ISF
    $library .= $reader_extra_transaction;
    $library .= <<'ISF';
  )
  (actor packet_writer
ISF
    $library .= "    (clock $writer_clock)\n";
    $library .= "    (reset $writer_reset)\n";
    $library .= <<'ISF';
    (interface
      (input emit_start)
ISF
    $library .= $writer_payload_port;
    $library .= $writer_extra_trigger_ports;
    $library .= <<'ISF';
      (output done))
    (transaction emit
      (on emit_start)
      (complete done))
ISF
    $library .= $writer_extra_transaction;
    $library .= <<'ISF';
  ))
ISF
    return $actor . $library;
}

sub _interface_port_decl {
    my ($direction, $name, $width) = @_;
    $width ||= 1;
    return "      ($direction $name)\n" if $width == 1;
    return "      ($direction $name (width $width))\n";
}

sub fsm_basenames_in {
    my ($dir) = @_;
    opendir my $dh, $dir or die "cannot read directory $dir: $!";
    my @files = grep { /\.fsm\z/ } readdir $dh;
    closedir $dh or die "cannot close directory $dir: $!";
    return @files;
}

sub expected_fsm_basenames_for_source {
    my ($source_file) = @_;
    my (undef, undef, $filename) = File::Spec->splitpath($source_file);
    $filename =~ s/\.isf\z//;

    if ($filename eq 'atl_two_child_pipeline'
        || $filename eq 'atl_two_child_data_pipeline'
        || $filename eq 'atl_two_child_vector_data_pipeline'
        || $filename eq 'atl_two_child_multi_data_pipeline')
    {
        return [
            "$filename.fsm",
            "${filename}__reader.fsm",
            "${filename}__writer.fsm",
            "${filename}_top.fsm",
        ];
    }

    return [
        "$filename.fsm",
        "${filename}__worker.fsm",
        "${filename}_top.fsm",
    ];
}

sub slurp {
    my ($path) = @_;
    open my $fh, '<', $path or die "cannot read $path: $!";
    my $text = do { local $/; <$fh> };
    close $fh or die "cannot close $path: $!";
    return $text;
}

sub sorted {
    my ($values) = @_;
    return [sort @{$values || []}];
}
