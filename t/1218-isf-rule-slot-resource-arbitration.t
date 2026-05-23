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
    assert_lower_rejected(<<'ISF', 'round_robin with bound users', qr/isf_resource_unsupported_arbiter/);
(actor unsupported_rr_resource
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
      (kind rule_slot)
      (arbiter round_robin)
      (users high low)))
  (rule high a
    (valid 1))
  (rule low b
    (valid 0)))
ISF

    assert_lower_rejected(<<'ISF', 'round_robin output_bundle with bound users', qr/isf_resource_unsupported_arbiter/);
(actor unsupported_rr_output_bundle_resource
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
    (resource response_outputs
      (kind output_bundle)
      (arbiter round_robin)
      (users high low)))
  (rule high a
    (valid 1))
  (rule low b
    (valid 0)))
ISF

    assert_lower_rejected(<<'ISF', 'round_robin transaction_start with bound users', qr/isf_resource_unsupported_arbiter/);
(actor unsupported_rr_transaction_start_resource
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
      (arbiter round_robin)
      (users high low)))
  (rule high high_req
    (trigger work))
  (rule low low_req
    (trigger work)))
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
