#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use JSON::PP qw(decode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

my $fixture = File::Spec->catfile($FindBin::Bin, '..', 'isf', 'fifo_library_use.isf');

subtest 'fixed-shape FIFO library fixture imports and specializes one actor' => sub {
    my $actor = FSM::Adapter::ISF->new()->parse_file($fixture);

    is(scalar(@{$actor->{library_uses}}), 1, 'fixture resolves one FIFO library use');
    my $use = $actor->{library_uses}[0];
    is($use->{library}, 'common.fifo', 'resolved use records FIFO library namespace');
    is($use->{export}, 'fifo', 'resolved use records FIFO actor export');
    is($use->{instance}, 'u_fifo', 'resolved use records FIFO instance name');
    is($use->{module}, 'fifo_library_use__u_fifo', 'resolved use records deterministic FIFO child module');

    my $scheduler = FSM::Scheduler::ISF->new();
    my $lowered = $scheduler->lower($actor);

    ok(exists($lowered->{files}{'fifo_library_use.fsm'}), 'lowering emits the importing actor .fsm');
    ok(exists($lowered->{files}{'fifo_library_use__u_fifo.fsm'}), 'lowering emits the specialized FIFO child .fsm');
    ok(exists($lowered->{files}{'fifo_library_use_top.fsm'}), 'lowering emits the generated composition top .fsm');

    my $child_fsm = $lowered->{files}{'fifo_library_use__u_fifo.fsm'};
    like($child_fsm, qr/\A\(\?fsm:fifo_library_use__u_fifo\b/, 'FIFO child artifact uses the specialized module name');
    like($child_fsm, qr/\(\+params[\s\S]*\(DATA_WIDTH 8\)[\s\S]*\(DEPTH 4\)[\s\S]*\(PTR_WIDTH 2\)[\s\S]*\(OCC_WIDTH 3\)/, 'FIFO child preserves fixed-shape parameter provenance');
    like($child_fsm, qr/\(\+size[\s\S]*\(data_0 8\)[\s\S]*\(data_3 8\)/, 'FIFO child declares all four scalarized data entries');
    like($child_fsm, qr/\(-push_pop_occ4\s+<\(& write_req read_req \(== occupancy 4\)\)/, 'FIFO child includes same-cycle full push/pop case');
    like($child_fsm, qr/\(-accepted_push\s+<\(& write_req \(\| \(! \(== occupancy 4\)\) read_req\)\)[\s\S]*\(<- \(data_0 data_in\) <\(== wr_ptr 0\)\)[\s\S]*\(<- \(data_3 data_in\) <\(== wr_ptr 3\)\)/, 'FIFO child stores accepted pushes through the actor-owned bank');
    like($child_fsm, qr/\(-accepted_pop\s+<\(& read_req \(! \(== occupancy 0\)\)\)[\s\S]*\(<- \(data_out> data_0\) <\(== rd_ptr 0\)\)[\s\S]*\(<- \(data_out> data_3\) <\(== rd_ptr 3\)\)/, 'FIFO child loads accepted pops from the actor-owned bank');

    my $top_fsm = $lowered->{files}{'fifo_library_use_top.fsm'};
    like($top_fsm, qr/\(\?fsmc:u_fifo fifo_library_use__u_fifo\b/, 'generated top instantiates the specialized FIFO child');
    like($top_fsm, qr/\(write_req u_fifo\.write_req\)/, 'generated top wires FIFO write request input');
    like($top_fsm, qr/\(data_in u_fifo\.data_in\)/, 'generated top wires FIFO data input');
    like($top_fsm, qr/\(read_req u_fifo\.read_req\)/, 'generated top wires FIFO read request input');
    like($top_fsm, qr/\(u_fifo\.full full\)/, 'generated top wires FIFO full output');
    like($top_fsm, qr/\(u_fifo\.empty empty\)/, 'generated top wires FIFO empty output');
    like($top_fsm, qr/\(u_fifo\.data_out data_out\)/, 'generated top wires FIFO data output');
};

subtest 'FIFO library use is visible in the public schedule report' => sub {
    my $actor = FSM::Adapter::ISF->new()->parse_file($fixture);
    my $report = decode_json(FSM::Scheduler::ISF->new()->report($actor));

    is(scalar(@{$report->{library_uses}}), 1, 'schedule report exposes one FIFO library use');
    my $use = $report->{library_uses}[0];
    is($use->{library}, 'common.fifo', 'report records FIFO library namespace');
    is($use->{export}, 'fifo', 'report records FIFO actor export');
    is($use->{instance}, 'u_fifo', 'report records FIFO instance');
    is($use->{module}, 'fifo_library_use__u_fifo', 'report records generated child module');
    is($use->{scheduled_fsm}, 'fifo_library_use__u_fifo.fsm', 'report records generated child artifact');

    my %params = map { $_->{name} => $_ } @{$use->{parameters}};
    for my $name (qw(DATA_WIDTH DEPTH PTR_WIDTH OCC_WIDTH)) {
        is($params{$name}{source}, 'override', "report marks $name as an explicit use-site override");
    }
    is($params{DATA_WIDTH}{value}, '8', 'report records DATA_WIDTH fixture value');
    is($params{DEPTH}{value}, '4', 'report records DEPTH fixture value');
    is($params{PTR_WIDTH}{value}, '2', 'report records PTR_WIDTH fixture value');
    is($params{OCC_WIDTH}{value}, '3', 'report records OCC_WIDTH fixture value');
};

done_testing();
