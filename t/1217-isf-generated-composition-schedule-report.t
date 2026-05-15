#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use JSON::PP ();
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Support::ISFPublicInterfaceContract qw(
    isf_public_interface_schedule_report_generated_composition_binding_keys
    isf_public_interface_schedule_report_generated_composition_child_keys
    isf_public_interface_schedule_report_generated_composition_child_parameter_keys
    isf_public_interface_schedule_report_generated_composition_drive_handoff_keys
    isf_public_interface_schedule_report_generated_composition_instance_keys
    isf_public_interface_schedule_report_generated_composition_link_keys
    isf_public_interface_schedule_report_generated_composition_parent_keys
    isf_public_interface_schedule_report_generated_composition_payload_keys
    isf_public_interface_schedule_report_generated_composition_required_keys
);

subtest 'generated composition schedule report exposes bounded spawn metadata' => sub {
    my $source = <<'ISF';
(actor generated_composition_report
  (clock clk)
  (interface
    (input trigger)
    (output done)
    (output rdata (width 32)))
  (drive (rdata val) (rdata val))
  (transaction parent
    (on trigger)
    (spawn worker as w0
      (params
        (WIDTH 16)))
    (spawn worker as w1)
    (await_all done)
    (complete done))
  (transaction worker
    (params
      (WIDTH 8))
    (sample trigger as val)
    (drive rdata val)
    (complete done)))
ISF

    my $actor = FSM::Adapter::ISF->new()->parse_source(
        $source,
        'generated-composition-report.isf',
    );
    my $report = JSON::PP->new->decode(FSM::Scheduler::ISF->new()->report($actor));
    my $composition = $report->{generated_composition};

    is($composition->{kind}, 'spawn_generated_top', 'generated composition kind is bounded');
    is_deeply(
        sorted([keys %$composition]),
        sorted(isf_public_interface_schedule_report_generated_composition_required_keys()),
        'generated composition object exposes advertised keys',
    );
    is($composition->{top_module}, 'generated_composition_report_top', 'top module is reported');
    is($composition->{top_fsm}, 'generated_composition_report_top.fsm', 'top file is reported');
    is_deeply(
        sorted([keys %{$composition->{parent}}]),
        sorted(isf_public_interface_schedule_report_generated_composition_parent_keys()),
        'parent summary exposes advertised keys',
    );
    is_deeply(
        $composition->{parent},
        {
            module        => 'generated_composition_report',
            scheduled_fsm => 'generated_composition_report.fsm',
        },
        'parent scheduled module is reported',
    );
    is_deeply(
        $composition->{children},
        [
            {
                transaction   => 'worker',
                module        => 'worker',
                scheduled_fsm => 'worker.fsm',
                parameters    => [
                    { name => 'WIDTH', default => '8' },
                ],
            },
        ],
        'child module and parameter defaults are reported',
    );
    is_deeply(
        sorted([keys %{$composition->{children}[0]}]),
        sorted(isf_public_interface_schedule_report_generated_composition_child_keys()),
        'child summary exposes advertised keys',
    );
    is_deeply(
        sorted([keys %{$composition->{children}[0]{parameters}[0]}]),
        sorted(isf_public_interface_schedule_report_generated_composition_child_parameter_keys()),
        'child parameter summary exposes advertised keys',
    );

    is(scalar(@{$composition->{instances}}), 2, 'two spawned instances are reported');
    my ($w0, $w1) = @{$composition->{instances}};
    is_deeply(
        sorted([keys %$w0]),
        sorted(isf_public_interface_schedule_report_generated_composition_instance_keys()),
        'instance summary exposes advertised keys',
    );
    is($w0->{instance}, 'w0', 'first instance keeps authored name');
    is($w0->{child}, 'worker', 'first instance names child module');
    is($w0->{activation_kind}, 'spawn', 'first instance reports spawn activation kind');
    is_deeply(
        sorted([keys %{$w0->{start}}]),
        sorted(isf_public_interface_schedule_report_generated_composition_link_keys()),
        'start handoff exposes advertised link keys',
    );
    is_deeply(
        $w0->{start},
        { parent_port => 'w0_start', child_port => 'start' },
        'start handoff is reported',
    );
    is_deeply(
        $w0->{done},
        { child_port => 'done', parent_port => 'w0_done' },
        'done handoff is reported',
    );
    is_deeply(
        sorted([keys %{$w0->{parameter_bindings}[0]}]),
        sorted(isf_public_interface_schedule_report_generated_composition_binding_keys()),
        'parameter binding exposes advertised keys',
    );
    is_deeply(
        $w0->{parameter_bindings},
        [
            { name => 'WIDTH', source => 'override', value => '16' },
        ],
        'override binding is reported',
    );
    is_deeply(
        $w1->{parameter_bindings},
        [
            { name => 'WIDTH', source => 'default', value => '8' },
        ],
        'default binding is reported',
    );
    is_deeply(
        sorted([keys %{$w0->{drive_handoffs}[0]}]),
        sorted(isf_public_interface_schedule_report_generated_composition_drive_handoff_keys()),
        'drive handoff exposes advertised keys',
    );
    is_deeply(
        sorted([keys %{$w0->{drive_handoffs}[0]{payloads}[0]}]),
        sorted(isf_public_interface_schedule_report_generated_composition_payload_keys()),
        'drive payload exposes advertised keys',
    );
    is_deeply(
        $w0->{drive_handoffs},
        [
            {
                drive   => 'rdata',
                request => {
                    child_port  => 'rdata_start',
                    parent_port => 'w0_rdata_start',
                },
                payloads => [
                    {
                        parameter   => 'val',
                        child_port  => 'rdata_val',
                        parent_port => 'w0_rdata_val',
                        width       => 32,
                    },
                ],
            },
        ],
        'named-drive request and payload handoff are reported',
    );
    is_deeply(
        $w1->{drive_handoffs},
        [
            {
                drive   => 'rdata',
                request => {
                    child_port  => 'rdata_start',
                    parent_port => 'w1_rdata_start',
                },
                payloads => [
                    {
                        parameter   => 'val',
                        child_port  => 'rdata_val',
                        parent_port => 'w1_rdata_val',
                        width       => 32,
                    },
                ],
            },
        ],
        'default-parameter instance still reports named-drive handoff',
    );
};

subtest 'non-composed schedule report uses null generated composition field' => sub {
    my $source = <<'ISF';
(actor single_report
  (clock clk)
  (interface
    (input start)
    (output done))
  (transaction main
    (on start)
    (complete done)))
ISF

    my $actor = FSM::Adapter::ISF->new()->parse_source($source, 'single-report.isf');
    my $report = JSON::PP->new->decode(FSM::Scheduler::ISF->new()->report($actor));
    is($report->{generated_composition}, undef, 'single-module report has null generated_composition');
};

done_testing();

sub sorted {
    my ($values) = @_;
    return [sort @{$values || []}];
}
