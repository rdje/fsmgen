#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::HDL::FlattenedDT;
use FSM::Pipeline::SourceFrontend;
use FSM::Scheduler::ISF;
use FSM::Scheduler::ISF::LoweringIR;

sub parse_actor {
    my ($source) = @_;
    return FSM::Adapter::ISF->new()->parse_source($source, 'rule-slot-resource-arbitration.isf');
}

sub lower_ir {
    my ($source) = @_;
    return FSM::Scheduler::ISF::LoweringIR->new()->build_module(parse_actor($source));
}

subtest 'rule_slot resource metadata survives parsing' => sub {
    my $actor = parse_actor(<<'ISF');
(actor resource_metadata
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (input a)
    (input b)
    (output done)
    (output valid))
  (transaction main
    (on start)
    (complete done))
  (resources
    (resource shared_bus
      (kind rule_slot)
      (arbiter priority)
      (users high low)))
  (priority high over low)
  (rule high a
    (valid 1))
  (rule low b
    (valid 0)))
ISF

    is_deeply(
        $actor->{resources},
        [
            {
                name    => 'shared_bus',
                kind    => 'rule_slot',
                arbiter => 'priority',
                users   => ['high', 'low'],
            },
        ],
        'resource kind/users metadata is preserved',
    );
};

subtest 'priority rule_slot grant gates the lower-priority rule DT' => sub {
    my $source = <<'ISF';
(actor resource_slot_priority
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (input a)
    (input b)
    (output done)
    (output valid)
    (output err))
  (transaction main
    (on start)
    (complete done))
  (priority high over low)
  (resources
    (resource shared_bus
      (kind rule_slot)
      (arbiter priority)
      (users high low)))
  (rule high a
    (valid 1))
  (rule low b
    (err 1)
    (trigger main)))
ISF

    my $ir = lower_ir($source);
    my $low_err = find_record($ir, owner => 'low', target => 'err');
    is_deeply($low_err->{resource_suppressed_by}, ['high'], 'low rule action records the higher resource requester');

    my $fsm = FSM::Scheduler::ISF->new()->lower(parse_actor($source))->{files}{'resource_slot_priority.fsm'};
    like(
        $fsm,
        qr/\(-low\s+<\(& b \(! a\)\)\s+\(<- \(err> 1\)\)\s+\(<1 \(low_main 1\)\)\s+\)/s,
        'scheduled .fsm gates the whole low rule DT with the priority grant',
    );
    assert_fsm_reaches_hdl($fsm, 'resource_slot_priority');
};

subtest 'priority output_bundle grant gates the lower-priority rule DT' => sub {
    my $source = <<'ISF';
(actor output_bundle_priority
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (input a)
    (input b)
    (output done)
    (output valid)
    (output err))
  (storage
    (var status (width 1)))
  (transaction main
    (on start)
    (complete done))
  (priority high over low)
  (resources
    (resource response_outputs
      (kind output_bundle)
      (arbiter priority)
      (members valid err status)
      (users high low)))
  (rule high a
    (valid 1))
  (rule low b
    (err 1)
    (status 1)))
ISF

    my $ir = lower_ir($source);
    my $low_err = find_record($ir, owner => 'low', target => 'err');
    my $low_status = find_record($ir, owner => 'low', target => 'status');
    is_deeply(
        $low_err->{resource_suppressed_by},
        ['high'],
        'low output-bundle rule action records the higher resource requester',
    );
    is_deeply(
        $low_status->{resource_suppressed_by},
        ['high'],
        'low output-bundle storage action records the higher resource requester',
    );
    is_deeply(
        $ir->{resource_arbitration}{grants},
        [
            {
                resource => 'response_outputs',
                kind     => 'output_bundle',
                arbiter  => 'priority',
                user     => 'high',
                higher   => [],
                members  => ['valid', 'err', 'status'],
            },
            {
                resource => 'response_outputs',
                kind     => 'output_bundle',
                arbiter  => 'priority',
                user     => 'low',
                higher   => ['high'],
                members  => ['valid', 'err', 'status'],
            },
        ],
        'output_bundle grants preserve member evidence in the resource arbitration IR shape',
    );

    my $fsm = FSM::Scheduler::ISF->new()->lower(parse_actor($source))->{files}{'output_bundle_priority.fsm'};
    like(
        $fsm,
        qr/\(-low\s+<\(& b \(! a\)\)\s+\(<- \(err> 1\)\)\s+\(<- \(status 1\)\)\s+\)/s,
        'scheduled .fsm gates the whole low output-bundle rule DT with the priority grant',
    );
    assert_fsm_reaches_hdl($fsm, 'output_bundle_priority');
};

subtest 'round_robin output_bundle grant gates rule DTs and preserves explicit members' => sub {
    my $source = <<'ISF';
(actor output_bundle_round_robin
  (clock clk)
  (reset rst_n)
  (interface
    (input high_req)
    (input low_req)
    (output valid)
    (output err))
  (storage
    (var status (width 1)))
  (resources
    (resource response_outputs
      (kind output_bundle)
      (arbiter round_robin)
      (members valid err status)
      (users high low)))
  (rule high high_req
    (valid 1)
    (status 1))
  (rule low low_req
    (err 1)
    (status 0)))
ISF

    my $ir = lower_ir($source);
    is($ir->{counters}{isf_rr_response_outputs_turn}, 1, 'output_bundle round_robin pointer width covers both rule users');
    is(
        $ir->{storage_roles}{isf_rr_response_outputs_turn},
        'resource_round_robin_pointer',
        'output_bundle round_robin pointer storage carries the public role',
    );
    is_deeply(
        $ir->{resource_arbitration}{grants},
        [
            {
                resource => 'response_outputs',
                kind     => 'output_bundle',
                arbiter  => 'round_robin',
                user     => 'high',
                higher   => ['low'],
                members  => ['valid', 'err', 'status'],
            },
            {
                resource => 'response_outputs',
                kind     => 'output_bundle',
                arbiter  => 'round_robin',
                user     => 'low',
                higher   => ['high'],
                members  => ['valid', 'err', 'status'],
            },
        ],
        'output_bundle round_robin grants preserve explicit member evidence',
    );

    my $high_valid = find_record($ir, owner => 'high', target => 'valid');
    my $low_err = find_record($ir, owner => 'low', target => 'err');
    is_deeply($high_valid->{resource_suppressed_by}, ['low'], 'high output-bundle action records the dynamic low peer');
    is_deeply($low_err->{resource_suppressed_by}, ['high'], 'low output-bundle action records the dynamic high peer');

    my $high_pointer = find_record($ir, owner => 'high', target => 'isf_rr_response_outputs_turn');
    my $low_pointer = find_record($ir, owner => 'low', target => 'isf_rr_response_outputs_turn');
    is($high_pointer->{rhs}, 1, 'high grant advances the output_bundle pointer to low');
    is($low_pointer->{rhs}, 0, 'low grant wraps the output_bundle pointer to high');

    my $fsm = FSM::Scheduler::ISF->new()->lower(parse_actor($source))->{files}{'output_bundle_round_robin.fsm'};
    like($fsm, qr/\(isf_rr_response_outputs_turn 1\)/, 'scheduled .fsm declares the output_bundle round_robin pointer width');
    like($fsm, qr/\(-high\s+<\(& high_req [\s\S]*\(== isf_rr_response_outputs_turn 0\)/, 'high output-bundle rule is gated by pointer-0 grant logic');
    like($fsm, qr/\(<- \(isf_rr_response_outputs_turn 1\)\)/, 'high grant updates the output_bundle pointer');
    like($fsm, qr/\(-low\s+<\(& low_req [\s\S]*\(== isf_rr_response_outputs_turn 1\)/, 'low output-bundle rule is gated by pointer-1 grant logic');
    like($fsm, qr/\(<- \(isf_rr_response_outputs_turn 0\)\)/, 'low grant wraps the output_bundle pointer');
    assert_fsm_reaches_hdl($fsm, 'output_bundle_round_robin');

    my $unmembered = <<'ISF';
(actor output_bundle_round_robin_unmembered
  (clock clk)
  (reset rst_n)
  (interface
    (input high_req)
    (input low_req)
    (output valid)
    (output err))
  (resources
    (resource response_outputs
      (kind output_bundle)
      (arbiter round_robin)
      (users high low)))
  (rule high high_req
    (valid 1))
  (rule low low_req
    (err 1)))
ISF

    my $unmembered_ir = lower_ir($unmembered);
    is_deeply(
        [map { $_->{members} } @{$unmembered_ir->{resource_arbitration}{grants}}],
        [[], []],
        'unmembered output_bundle round_robin grants keep empty member evidence',
    );
    my $unmembered_fsm = FSM::Scheduler::ISF->new()->lower(parse_actor($unmembered))->{files}{'output_bundle_round_robin_unmembered.fsm'};
    assert_fsm_reaches_hdl($unmembered_fsm, 'output_bundle_round_robin_unmembered');
};

subtest 'priority transaction_start grant gates lower-priority rule triggers' => sub {
    my $source = <<'ISF';
(actor transaction_start_priority
  (clock clk)
  (reset rst_n)
  (interface
    (input high_req)
    (input low_req)
    (output done))
  (transaction work
    (on work_start)
    (complete done))
  (priority high over low)
  (resources
    (resource work
      (kind transaction_start)
      (arbiter priority)
      (users high low)))
  (rule high high_req
    (trigger work))
  (rule low low_req
    (trigger work)))
ISF

    my $ir = lower_ir($source);
    my $low_start = find_record($ir, owner => 'low', target => 'low_work');
    is_deeply(
        $low_start->{resource_suppressed_by},
        ['high'],
        'low transaction_start trigger source records the higher resource requester',
    );
    is_deeply(
        $ir->{resource_arbitration}{grants},
        [
            {
                resource => 'work',
                kind     => 'transaction_start',
                arbiter  => 'priority',
                user     => 'high',
                higher   => [],
                members  => [],
            },
            {
                resource => 'work',
                kind     => 'transaction_start',
                arbiter  => 'priority',
                user     => 'low',
                higher   => ['high'],
                members  => [],
            },
        ],
        'transaction_start grants reuse the resource arbitration IR shape',
    );

    my $fsm = FSM::Scheduler::ISF->new()->lower(parse_actor($source))->{files}{'transaction_start_priority.fsm'};
    like(
        $fsm,
        qr/\(-low\s+<\(& low_req \(! high_req\)\)\s+\(<1 \(low_work 1\)\)\s+\)/s,
        'scheduled .fsm gates the lower-priority trigger source before fan-in',
    );
    like(
        $fsm,
        qr/\(-work_trigger_fanin\s+\(= \(work_start \(\| high_work low_work\)\)\)\s+\)/s,
        'transaction_start arbitration preserves the generated trigger fan-in DT owner',
    );
    assert_fsm_reaches_hdl($fsm, 'transaction_start_priority');
};

subtest 'round_robin transaction_start grant gates trigger sources with generated pointer state' => sub {
    my $source = <<'ISF';
(actor transaction_start_round_robin
  (clock clk)
  (reset rst_n)
  (interface
    (input high_req)
    (input low_req)
    (output done))
  (transaction work
    (on work_start)
    (complete done))
  (resources
    (resource work
      (kind transaction_start)
      (arbiter round_robin)
      (users high low)))
  (rule high high_req
    (trigger work))
  (rule low low_req
    (trigger work)))
ISF

    my $ir = lower_ir($source);
    is($ir->{counters}{isf_rr_work_turn}, 1, 'transaction_start round_robin pointer width covers both rule users');
    is(
        $ir->{storage_roles}{isf_rr_work_turn},
        'resource_round_robin_pointer',
        'transaction_start round_robin pointer storage carries the public role',
    );
    is_deeply(
        $ir->{resource_arbitration}{grants},
        [
            {
                resource => 'work',
                kind     => 'transaction_start',
                arbiter  => 'round_robin',
                user     => 'high',
                higher   => ['low'],
                members  => [],
            },
            {
                resource => 'work',
                kind     => 'transaction_start',
                arbiter  => 'round_robin',
                user     => 'low',
                higher   => ['high'],
                members  => [],
            },
        ],
        'transaction_start round_robin grants reuse the resource arbitration IR shape',
    );

    my $high_start = find_record($ir, owner => 'high', target => 'high_work');
    my $low_start = find_record($ir, owner => 'low', target => 'low_work');
    is_deeply($high_start->{resource_suppressed_by}, ['low'], 'high trigger source records the dynamic low peer');
    is_deeply($low_start->{resource_suppressed_by}, ['high'], 'low trigger source records the dynamic high peer');

    my $high_pointer = find_record($ir, owner => 'high', target => 'isf_rr_work_turn');
    my $low_pointer = find_record($ir, owner => 'low', target => 'isf_rr_work_turn');
    is($high_pointer->{rhs}, 1, 'high grant advances the transaction_start pointer to low');
    is($low_pointer->{rhs}, 0, 'low grant wraps the transaction_start pointer to high');

    my $fsm = FSM::Scheduler::ISF->new()->lower(parse_actor($source))->{files}{'transaction_start_round_robin.fsm'};
    like($fsm, qr/\(isf_rr_work_turn 1\)/, 'scheduled .fsm declares the transaction_start round_robin pointer width');
    like($fsm, qr/\(-high\s+<\(& high_req [\s\S]*\(== isf_rr_work_turn 0\)/, 'high trigger source is gated by pointer-0 grant logic');
    like($fsm, qr/\(<- \(isf_rr_work_turn 1\)\)/, 'high grant updates the transaction_start pointer');
    like($fsm, qr/\(-low\s+<\(& low_req [\s\S]*\(== isf_rr_work_turn 1\)/, 'low trigger source is gated by pointer-1 grant logic');
    like($fsm, qr/\(<- \(isf_rr_work_turn 0\)\)/, 'low grant wraps the transaction_start pointer');
    like(
        $fsm,
        qr/\(-work_trigger_fanin\s+\(= \(work_start \(\| high_work low_work\)\)\)\s+\)/s,
        'transaction_start round_robin preserves the generated trigger fan-in DT owner',
    );
    assert_fsm_reaches_hdl($fsm, 'transaction_start_round_robin');
};

subtest 'priority storage_port grant gates lower-priority storage writers' => sub {
    my $source = <<'ISF';
(actor storage_port_priority
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (input a)
    (input b)
    (output done)
    (output valid))
  (storage
    (var slot (width 1))
    (var shadow (width 1)))
  (transaction main
    (on start)
    (complete done))
  (priority high over low)
  (resources
    (resource store_bus
      (kind storage_port)
      (arbiter priority)
      (members slot shadow)
      (users high low)))
  (rule high a
    (slot 1))
  (rule low b
    (shadow 1)
    (valid 1)))
ISF

    my $ir = lower_ir($source);
    my $low_shadow = find_record($ir, owner => 'low', target => 'shadow');
    my $low_valid = find_record($ir, owner => 'low', target => 'valid');
    is_deeply(
        $low_shadow->{resource_suppressed_by},
        ['high'],
        'low storage-port rule action records the higher resource requester',
    );
    is_deeply(
        $low_valid->{resource_suppressed_by},
        ['high'],
        'storage-port grant still gates the whole bound rule DT',
    );
    is_deeply(
        $ir->{resource_arbitration}{grants},
        [
            {
                resource => 'store_bus',
                kind     => 'storage_port',
                arbiter  => 'priority',
                user     => 'high',
                higher   => [],
                members  => ['slot', 'shadow'],
            },
            {
                resource => 'store_bus',
                kind     => 'storage_port',
                arbiter  => 'priority',
                user     => 'low',
                higher   => ['high'],
                members  => ['slot', 'shadow'],
            },
        ],
        'storage_port grants preserve explicit storage member evidence',
    );

    my $fsm = FSM::Scheduler::ISF->new()->lower(parse_actor($source))->{files}{'storage_port_priority.fsm'};
    like(
        $fsm,
        qr/\(-low\s+<\(& b \(! a\)\)\s+\(<- \(shadow 1\)\)\s+\(<- \(valid> 1\)\)\s+\)/s,
        'scheduled .fsm gates the whole low storage-port rule DT with the priority grant',
    );
    assert_fsm_reaches_hdl($fsm, 'storage_port_priority');
};

subtest 'round_robin rule_slot grant gates rule DTs with generated pointer state' => sub {
    my $source = <<'ISF';
(actor round_robin_rule_slot
  (clock clk)
  (reset rst_n)
  (interface
    (input a)
    (input b)
    (input c)
    (output valid))
  (resources
    (resource shared_bus
      (kind rule_slot)
      (arbiter round_robin)
      (users high mid low)))
  (rule high a
    (valid 1))
  (rule mid b
    (valid 0))
  (rule low c
    (valid 1)))
ISF

    my $ir = lower_ir($source);
    is($ir->{counters}{isf_rr_shared_bus_turn}, 2, 'round_robin pointer width covers all listed users');
    is(
        $ir->{storage_roles}{isf_rr_shared_bus_turn},
        'resource_round_robin_pointer',
        'round_robin pointer storage carries a public role',
    );
    is_deeply(
        $ir->{resource_arbitration}{grants},
        [
            {
                resource => 'shared_bus',
                kind     => 'rule_slot',
                arbiter  => 'round_robin',
                user     => 'high',
                higher   => ['mid', 'low'],
                members  => [],
            },
            {
                resource => 'shared_bus',
                kind     => 'rule_slot',
                arbiter  => 'round_robin',
                user     => 'mid',
                higher   => ['high', 'low'],
                members  => [],
            },
            {
                resource => 'shared_bus',
                kind     => 'rule_slot',
                arbiter  => 'round_robin',
                user     => 'low',
                higher   => ['high', 'mid'],
                members  => [],
            },
        ],
        'round_robin grants preserve peer suppression evidence in the resource arbitration IR shape',
    );

    my $high_valid = find_record($ir, owner => 'high', target => 'valid');
    my $mid_valid = find_record($ir, owner => 'mid', target => 'valid');
    my $low_valid = find_record($ir, owner => 'low', target => 'valid');
    is_deeply($high_valid->{resource_suppressed_by}, ['mid', 'low'], 'high rule records dynamic round_robin peers');
    is_deeply($mid_valid->{resource_suppressed_by}, ['high', 'low'], 'mid rule records dynamic round_robin peers');
    is_deeply($low_valid->{resource_suppressed_by}, ['high', 'mid'], 'low rule records dynamic round_robin peers');

    my $high_pointer = find_record($ir, owner => 'high', target => 'isf_rr_shared_bus_turn');
    my $mid_pointer = find_record($ir, owner => 'mid', target => 'isf_rr_shared_bus_turn');
    my $low_pointer = find_record($ir, owner => 'low', target => 'isf_rr_shared_bus_turn');
    is($high_pointer->{rhs}, 1, 'high grant advances pointer to mid');
    is($mid_pointer->{rhs}, 2, 'mid grant advances pointer to low');
    is($low_pointer->{rhs}, 0, 'low grant wraps pointer to high');

    my $fsm = FSM::Scheduler::ISF->new()->lower(parse_actor($source))->{files}{'round_robin_rule_slot.fsm'};
    like($fsm, qr/\(isf_rr_shared_bus_turn 2\)/, 'scheduled .fsm declares the round_robin pointer width');
    like($fsm, qr/\(-high\s+<\(& a \(\| \(== isf_rr_shared_bus_turn 0\)/, 'high rule is gated by the pointer-0 grant case');
    like($fsm, qr/\(<- \(isf_rr_shared_bus_turn 1\)\)/, 'high rule updates the pointer after a grant');
    like($fsm, qr/\(-low\s+<\(& c [\s\S]*\(== isf_rr_shared_bus_turn 2\)/, 'low rule is gated by the pointer-2 grant case');
    like($fsm, qr/\(<- \(isf_rr_shared_bus_turn 0\)\)/, 'low rule wraps the pointer after a grant');
    assert_fsm_reaches_hdl($fsm, 'round_robin_rule_slot');
};

subtest 'explicit output_bundle members fail closed on rule output mismatch' => sub {
    assert_lower_rejected(<<'ISF', 'bound rule writes output outside members', qr/isf_output_bundle_member_mismatch/);
(actor output_bundle_member_mismatch
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (input a)
    (input b)
    (output done)
    (output valid)
    (output err))
  (transaction main
    (on start)
    (complete done))
  (priority high over low)
  (resources
    (resource response_outputs
      (kind output_bundle)
      (arbiter priority)
      (members valid)
      (users high low)))
  (rule high a
    (valid 1))
  (rule low b
    (err 1)))
ISF

    assert_lower_rejected(<<'ISF', 'explicit member is not written by any user', qr/isf_output_bundle_member_unwritten/);
(actor output_bundle_member_unwritten
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (input a)
    (input b)
    (output done)
    (output valid)
    (output err))
  (transaction main
    (on start)
    (complete done))
  (priority high over low)
  (resources
    (resource response_outputs
      (kind output_bundle)
      (arbiter priority)
      (members valid err)
      (users high low)))
  (rule high a
    (valid 1))
  (rule low b
    (valid 0)))
ISF

    assert_lower_rejected(<<'ISF', 'bound rule writes storage outside members', qr/isf_output_bundle_member_mismatch/);
(actor output_bundle_storage_member_mismatch
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (input a)
    (input b)
    (output done)
    (output valid))
  (storage
    (var status (width 1)))
  (transaction main
    (on start)
    (complete done))
  (priority high over low)
  (resources
    (resource response_outputs
      (kind output_bundle)
      (arbiter priority)
      (members valid)
      (users high low)))
  (rule high a
    (valid 1))
  (rule low b
    (status 1)))
ISF

    assert_lower_rejected(<<'ISF', 'round_robin output_bundle member mismatch still fails closed', qr/isf_output_bundle_member_mismatch/);
(actor output_bundle_round_robin_member_mismatch
  (clock clk)
  (reset rst_n)
  (interface
    (input a)
    (input b)
    (output valid)
    (output err))
  (resources
    (resource response_outputs
      (kind output_bundle)
      (arbiter round_robin)
      (members valid)
      (users high low)))
  (rule high a
    (valid 1))
  (rule low b
    (err 1)))
ISF

    assert_lower_rejected(<<'ISF', 'explicit storage member is not written by any user', qr/isf_output_bundle_member_unwritten/);
(actor output_bundle_storage_member_unwritten
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (input a)
    (input b)
    (output done)
    (output valid))
  (storage
    (var status (width 1)))
  (transaction main
    (on start)
    (complete done))
  (priority high over low)
  (resources
    (resource response_outputs
      (kind output_bundle)
      (arbiter priority)
      (members valid status)
      (users high low)))
  (rule high a
    (valid 1))
  (rule low b
    (valid 0)))
ISF
};

subtest 'explicit storage_port members fail closed on storage mismatch' => sub {
    assert_lower_rejected(<<'ISF', 'storage_port requires explicit members with users', qr/storage_port resource 'store_bus' with users requires explicit/);
(actor storage_port_missing_members
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (input a)
    (input b)
    (output done))
  (storage
    (var slot (width 1)))
  (transaction main
    (on start)
    (complete done))
  (priority high over low)
  (resources
    (resource store_bus
      (kind storage_port)
      (arbiter priority)
      (users high low)))
  (rule high a
    (slot 1))
  (rule low b
    (slot 0)))
ISF

    assert_lower_rejected(<<'ISF', 'bound rule writes storage outside storage_port members', qr/isf_storage_port_member_mismatch/);
(actor storage_port_member_mismatch
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (input a)
    (input b)
    (output done))
  (storage
    (var slot (width 1))
    (var shadow (width 1)))
  (transaction main
    (on start)
    (complete done))
  (priority high over low)
  (resources
    (resource store_bus
      (kind storage_port)
      (arbiter priority)
      (members slot)
      (users high low)))
  (rule high a
    (slot 1))
  (rule low b
    (shadow 1)))
ISF

    assert_lower_rejected(<<'ISF', 'explicit storage_port member is not written by any user', qr/isf_storage_port_member_unwritten/);
(actor storage_port_member_unwritten
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (input a)
    (input b)
    (output done))
  (storage
    (var slot (width 1))
    (var shadow (width 1)))
  (transaction main
    (on start)
    (complete done))
  (priority high over low)
  (resources
    (resource store_bus
      (kind storage_port)
      (arbiter priority)
      (members slot shadow)
      (users high low)))
  (rule high a
    (slot 1))
  (rule low b
    (slot 0)))
ISF
};

subtest 'transaction_start resources fail closed outside the bounded rule-trigger surface' => sub {
    assert_lower_rejected(<<'ISF', 'rule user does not trigger transaction_start resource', qr/isf_transaction_start_user_without_trigger/);
(actor transaction_start_user_without_trigger
  (clock clk)
  (reset rst_n)
  (interface
    (input high_req)
    (input low_req)
    (output done)
    (output flag))
  (transaction work
    (on work_start)
    (complete done))
  (priority high over low)
  (resources
    (resource work
      (kind transaction_start)
      (arbiter priority)
      (users high low)))
  (rule high high_req
    (trigger work))
  (rule low low_req
    (flag 1)))
ISF

    assert_lower_rejected(<<'ISF', 'generated-child transaction_start resource remains unsupported', qr/isf_transaction_start_generated_child_unsupported/);
(actor transaction_start_generated_child
  (clock clk)
  (reset rst_n)
  (interface
    (input high_req)
    (input low_req)
    (output done))
  (transaction work
    (params (LIMIT 4))
    (on work_start)
    (complete done))
  (priority high over low)
  (resources
    (resource work
      (kind transaction_start)
      (arbiter priority)
      (users high low)))
  (rule high high_req
    (trigger work (params (LIMIT 2))))
  (rule low low_req
    (trigger work)))
ISF

    assert_lower_rejected(<<'ISF', 'round_robin generated-child transaction_start resource remains unsupported', qr/isf_transaction_start_generated_child_unsupported/);
(actor transaction_start_round_robin_generated_child
  (clock clk)
  (reset rst_n)
  (interface
    (input high_req)
    (input low_req)
    (output done))
  (transaction work
    (params (LIMIT 4))
    (on work_start)
    (complete done))
  (resources
    (resource work
      (kind transaction_start)
      (arbiter round_robin)
      (users high low)))
  (rule high high_req
    (trigger work (params (LIMIT 2))))
  (rule low low_req
    (trigger work)))
ISF
};

subtest 'resource priority rejects incomplete and cyclic orderings' => sub {
    assert_lower_rejected(<<'ISF', 'incomplete priority order', qr/isf_resource_priority_incomplete/);
(actor incomplete_resource_priority
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (input a)
    (input b)
    (output done)
    (output valid))
  (transaction main
    (on start)
    (complete done))
  (resources
    (resource shared_bus
      (kind rule_slot)
      (arbiter priority)
      (users high low)))
  (rule high a
    (valid 1))
  (rule low b
    (valid 0)))
ISF

    assert_lower_rejected(<<'ISF', 'cyclic priority order', qr/isf_resource_priority_cycle/);
(actor cyclic_resource_priority
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (input a)
    (input b)
    (output done)
    (output valid))
  (transaction main
    (on start)
    (complete done))
  (priority high over low)
  (priority low over high)
  (resources
    (resource shared_bus
      (kind rule_slot)
      (arbiter priority)
      (users high low)))
  (rule high a
    (valid 1))
  (rule low b
    (valid 0)))
ISF
};

subtest 'unsupported resource arbitration surfaces fail closed' => sub {
    assert_lower_rejected(<<'ISF', 'round_robin resource name that cannot form generated pointer storage', qr/isf_resource_round_robin_name_shape/);
(actor unsupported_rr_resource_name_shape
  (clock clk)
  (reset rst_n)
  (interface
    (input a)
    (input b)
    (output valid))
  (resources
    (resource shared-bus
      (kind rule_slot)
      (arbiter round_robin)
      (users high low)))
  (rule high a
    (valid 1))
  (rule low b
    (valid 0)))
ISF

    assert_lower_rejected(<<'ISF', 'round_robin generated pointer collision', qr/isf_resource_round_robin_pointer_collision/);
(actor unsupported_rr_pointer_collision
  (clock clk)
  (reset rst_n)
  (interface
    (input a)
    (input b)
    (output valid))
  (storage
    (var isf_rr_shared_bus_turn (width 1)))
  (resources
    (resource shared_bus
      (kind rule_slot)
      (arbiter round_robin)
      (users high low)))
  (rule high a
    (valid 1))
  (rule low b
    (valid 0)))
ISF

    assert_lower_rejected(<<'ISF', 'round_robin generated pointer collides with actor constant', qr/isf_resource_round_robin_pointer_collision/);
(actor unsupported_rr_pointer_constant_collision
  (clock clk)
  (reset rst_n)
  (constants
    (isf_rr_shared_bus_turn 1))
  (interface
    (input a)
    (input b)
    (output valid))
  (resources
    (resource shared_bus
      (kind rule_slot)
      (arbiter round_robin)
      (users high low)))
  (rule high a
    (valid 1))
  (rule low b
    (valid 0)))
ISF

    assert_lower_rejected(<<'ISF', 'round_robin user bound to two resources', qr/isf_resource_round_robin_user_overlap/);
(actor unsupported_rr_user_overlap
  (clock clk)
  (reset rst_n)
  (interface
    (input a)
    (input b)
    (output valid))
  (resources
    (resource shared_bus_a
      (kind rule_slot)
      (arbiter round_robin)
      (users high low))
    (resource shared_bus_b
      (kind rule_slot)
      (arbiter round_robin)
      (users high low)))
  (rule high a
    (valid 1))
  (rule low b
    (valid 0)))
ISF

    assert_lower_rejected(<<'ISF', 'round_robin storage_port with bound users', qr/isf_resource_unsupported_arbiter/);
(actor unsupported_rr_storage_port_resource
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (input a)
    (input b)
    (output done))
  (storage
    (var slot (width 1)))
  (transaction main
    (on start)
    (complete done))
  (priority high over low)
  (resources
    (resource store_bus
      (kind storage_port)
      (arbiter round_robin)
      (members slot)
      (users high low)))
  (rule high a
    (slot 1))
  (rule low b
    (slot 0)))
ISF

    assert_lower_rejected(<<'ISF', 'unsupported resource kind with bound users', qr/isf_resource_unsupported_kind/);
(actor unsupported_kind_resource
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (input a)
    (input b)
    (output done)
    (output valid))
  (transaction main
    (on start)
    (complete done))
  (priority high over low)
  (resources
    (resource shared_bus
      (kind interface_bundle)
      (arbiter priority)
      (users high low)))
  (rule high a
    (valid 1))
  (rule low b
    (valid 0)))
ISF
};

subtest 'rule resource user references fail before scheduler handoff' => sub {
    my $ok = eval {
        parse_actor(<<'ISF');
(actor unknown_resource_user
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (input a)
    (output done)
    (output valid))
  (transaction main
    (on start)
    (complete done))
  (resources
    (resource shared_bus
      (kind rule_slot)
      (arbiter priority)
      (users high missing)))
  (rule high a
    (valid 1)))
ISF
        1;
    };

    ok(!$ok, 'unknown rule_slot user is rejected');
    like($@, qr/resource 'shared_bus' user 'missing' is not a declared rule/, 'unknown user diagnostic names the resource and user');

    $ok = eval {
        parse_actor(<<'ISF');
(actor unknown_output_bundle_resource_user
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (input a)
    (output done)
    (output valid))
  (transaction main
    (on start)
    (complete done))
  (resources
    (resource response_outputs
      (kind output_bundle)
      (arbiter priority)
      (users high missing)))
  (rule high a
    (valid 1)))
ISF
        1;
    };

    ok(!$ok, 'unknown output_bundle user is rejected');
    like($@, qr/resource 'response_outputs' user 'missing' is not a declared rule/, 'unknown output_bundle user diagnostic names the resource and user');
};

done_testing();

sub assert_lower_rejected {
    my ($source, $label, $diagnostic_re) = @_;
    my $ok = eval {
        lower_ir($source);
        1;
    };

    ok(!$ok, "$label is rejected");
    like($@, $diagnostic_re, "$label diagnostic is targeted");
}

sub find_record {
    my ($ir, %want) = @_;

    RECORD:
    for my $record (@{$ir->{assignment_provenance} || []}) {
        for my $key (sort keys %want) {
            next RECORD unless defined($record->{$key}) && $record->{$key} eq $want{$key};
        }
        return $record;
    }

    fail('found provenance record for ' . join(', ', map { "$_=$want{$_}" } sort keys %want));
    return {};
}

sub assert_fsm_reaches_hdl {
    my ($fsm, $module_name) = @_;
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, "$module_name.fsm");
    write_file($fsm_path, $fsm);

    my $raw_ast = FSM::Pipeline::SourceFrontend->parse_fsm_file(
        fsm_file    => $fsm_path,
        debug_level => 0,
    );
    my $fsm_module = FSM::Pipeline::SourceFrontend->create_fsm_module(
        raw_ast     => $raw_ast,
        debug_level => 0,
    );
    ok($fsm_module, 'resource-gated scheduled .fsm parses through the normal .fsm frontend');

    my $hdl = FSM::HDL::FlattenedDT->new(debug => 0)->generate_systemverilog($fsm_module);
    like($hdl, qr/\bmodule\s+\Q$module_name\E\b/, 'resource-gated scheduled .fsm reaches HDL generation');
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
