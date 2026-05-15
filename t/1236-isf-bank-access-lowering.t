#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use JSON::PP qw(decode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::HDL::FlattenedDT;
use FSM::Pipeline::SourceFrontend;
use FSM::Scheduler::ISF;
use FSM::Support::ISFPublicInterfaceContract qw(
    isf_public_interface_schedule_report_bank_access_keys
);

subtest 'actor-owned bank store/load lower to scalarized guarded assignments' => sub {
    my $fixture = File::Spec->catfile($FindBin::Bin, '..', 'isf', 'fifo_data_path.isf');
    my $actor = FSM::Adapter::ISF->new()->parse_file($fixture);
    my $scheduler = FSM::Scheduler::ISF->new();
    my $lowered = $scheduler->lower($actor);
    my $fsm = $lowered->{files}{'fifo_data_path.fsm'};

    ok(defined($fsm), 'scheduler emits the FIFO data-path .fsm');
    like($fsm, qr/\(\+size[\s\S]*\(data_0 8\)[\s\S]*\(data_3 8\)/, 'scheduled .fsm declares scalarized data bank entries');
    like(
        $fsm,
        qr/\(-accepted_push\s+<\(& write_req \(\| \(! \(== occupancy 4\)\) read_req\)\)[\s\S]*\(<- \(data_0 data_in\) <\(== wr_ptr 0\)\)[\s\S]*\(<- \(data_3 data_in\) <\(== wr_ptr 3\)\)/,
        'store lowers to per-entry guarded updates of the selected bank entry',
    );
    like(
        $fsm,
        qr/\(-accepted_pop\s+<\(& read_req \(! \(== occupancy 0\)\)\)[\s\S]*\(<- \(data_out> data_0\) <\(== rd_ptr 0\)\)[\s\S]*\(<- \(data_out> data_3\) <\(== rd_ptr 3\)\)/,
        'load lowers to mux-equivalent guarded assignments from scalarized entries',
    );

    my $report = decode_json($scheduler->report($actor));
    is_deeply($report->{compile_issues}, [], 'bank access lowering has no compile issues');
    is(scalar(@{$report->{bank_accesses}}), 2, 'schedule report exposes store and load bank accesses');

    my %access_by_kind = map { $_->{kind} => $_ } @{$report->{bank_accesses}};
    assert_bank_access($access_by_kind{store}, store => value => 'data_in', target => undef);
    assert_bank_access($access_by_kind{load},  load  => target => 'data_out', value => undef);

    assert_fsm_reaches_hdl($fsm, 'fifo_data_path');
};

subtest 'bank access diagnostics fail closed for malformed and unsupported access' => sub {
    assert_parse_rejected(
        bad_rule_store_shape_source(),
        qr/rule 'bad_store' store action requires '\(store <bank-name> <index> <value>\)'/,
        'malformed rule store is rejected by the parser',
    );
    assert_schedule_rejected(
        unknown_bank_source(),
        qr/rule 'bad_store': store references unknown actor-owned bank 'missing'/,
        'unknown bank is rejected during lowering',
    );
    assert_schedule_rejected(
        non_bank_storage_source(),
        qr/rule 'bad_store': store references unknown actor-owned bank 'wr_ptr'/,
        'var storage cannot be used as a bank',
    );
    assert_schedule_rejected(
        out_of_range_index_source(),
        qr/rule 'bad_store': store index '4' is outside bank 'data' depth 4/,
        'literal bank index must be inside the fixed bank depth',
    );
    assert_schedule_rejected(
        width_mismatch_source(),
        qr/rule 'bad_store': store store value 'too_wide' width 16 does not match bank 'data' entry width 8/,
        'store value width mismatch is rejected when width evidence is known',
    );
    assert_two_bank_selection(two_bank_source());
};

done_testing();

sub assert_bank_access {
    my ($entry, $kind, %want) = @_;
    ok($entry, "report includes $kind access");
    return unless $entry;

    is_deeply(
        [sort keys %$entry],
        [sort @{isf_public_interface_schedule_report_bank_access_keys()}],
        "$kind access exposes advertised keys",
    );
    is($entry->{owner_kind}, 'rule', "$kind access records rule ownership");
    is($entry->{bank}, 'data', "$kind access records bank name");
    is($entry->{width}, 8, "$kind access records bank entry width");
    is($entry->{depth}, 4, "$kind access records bank depth");
    is($entry->{same_cycle_policy}, 'read_before_write', "$kind access records read-before-write policy");
    is_deeply(
        $entry->{scalar_entries},
        [qw(data_0 data_1 data_2 data_3)],
        "$kind access records scalarized entries",
    );
    for my $key (sort keys %want) {
        is($entry->{$key}, $want{$key}, "$kind access records $key");
    }
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
    ok($fsm_module, 'scheduled .fsm with bank access parses through the normal .fsm frontend');

    my $hdl = FSM::HDL::FlattenedDT->new(debug => 0)->generate_systemverilog($fsm_module);
    like($hdl, qr/\bmodule\s+\Q$module_name\E\b/, 'bank access scheduled .fsm reaches HDL generation');
    like($hdl, qr/\bdata_0\b/, 'generated HDL contains scalarized bank entry data_0');
    like($hdl, qr/\bdata_3\b/, 'generated HDL contains scalarized bank entry data_3');
}

sub assert_parse_rejected {
    my ($source, $diagnostic_re, $label) = @_;
    my $ok = eval {
        FSM::Adapter::ISF->new()->parse_source($source, "$label.isf");
        1;
    };

    ok(!$ok, $label);
    like($@, $diagnostic_re, "$label diagnostic");
}

sub assert_schedule_rejected {
    my ($source, $diagnostic_re, $label) = @_;
    my $actor = FSM::Adapter::ISF->new()->parse_source($source, "$label.isf");
    my $ok = eval {
        FSM::Scheduler::ISF->new()->lower($actor);
        1;
    };

    ok(!$ok, $label);
    like($@, $diagnostic_re, "$label diagnostic");
}

sub common_prefix {
    return <<'ISF';
(actor bad_bank_access
  (clock clk)
  (interface
    (input write_req)
    (input data_in (width 8))
    (input too_wide (width 16))
    (output data_out (width 8)))
  (storage
    (var wr_ptr (width 2))
    (bank data (width 8) (depth 4)))
ISF
}

sub bad_rule_store_shape_source {
    return common_prefix() . <<'ISF';
  (rule bad_store write_req
    (store data wr_ptr)))
ISF
}

sub unknown_bank_source {
    return common_prefix() . <<'ISF';
  (rule bad_store write_req
    (store missing wr_ptr data_in)))
ISF
}

sub non_bank_storage_source {
    return common_prefix() . <<'ISF';
  (rule bad_store write_req
    (store wr_ptr 0 data_in)))
ISF
}

sub out_of_range_index_source {
    return common_prefix() . <<'ISF';
  (rule bad_store write_req
    (store data 4 data_in)))
ISF
}

sub width_mismatch_source {
    return common_prefix() . <<'ISF';
  (rule bad_store write_req
    (store data wr_ptr too_wide)))
ISF
}

sub two_bank_source {
    return <<'ISF';
(actor two_bank_access
  (clock clk)
  (interface
    (input write_req)
    (input data_in (width 8))
    (output data_out (width 8)))
  (storage
    (var wr_ptr (width 2))
    (var rd_ptr (width 2))
    (bank even_data (width 8) (depth 4))
    (bank odd_data (width 8) (depth 4)))
  (rule write_even write_req
    (store even_data wr_ptr data_in))
  (rule read_odd write_req
    (load odd_data rd_ptr as data_out)))
ISF
}

sub assert_two_bank_selection {
    my ($source) = @_;
    my $actor = FSM::Adapter::ISF->new()->parse_source($source, 'two-bank-access.isf');
    my $lowered = FSM::Scheduler::ISF->new()->lower($actor);
    my $fsm = $lowered->{files}{'two_bank_access.fsm'};

    like($fsm, qr/\(<- \(even_data_0 data_in\) <\(== wr_ptr 0\)\)/, 'store selects the named even_data bank');
    like($fsm, qr/\(<- \(data_out> odd_data_0\) <\(== rd_ptr 0\)\)/, 'load selects the named odd_data bank');
    unlike($fsm, qr/\(<- \(odd_data_0 data_in\)/, 'store does not write the other declared bank');
    unlike($fsm, qr/\(<- \(data_out> even_data_0\)/, 'load does not read the other declared bank');
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
