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

subtest 'actor constants bank widths lower like literal widths' => sub {
    my $source = <<'ISF';
(actor constant_bank_storage_widths
  (clock clk)
  (constants
    (DATA_W 7))
  (interface
    (input start)
    (input idx)
    (input wdata (width 7))
    (output rdata (width 7))
    (output done))
  (storage
    (bank data (width DATA_W) (depth 2)))
  (transaction main
    (on start)
    (store data idx wdata)
    (load data idx as rdata)
    (complete done)))
ISF

    my $actor = parse_source($source, 'constant-bank-storage-widths.isf');
    is(storage_width($actor, 'data'), 7, 'bank width resolves from actor constant');
    is_deeply(storage_signal_widths($actor, 'data'), [7, 7], 'bank signal widths are finalized');

    my $scheduler = FSM::Scheduler::ISF->new();
    my $lowered = $scheduler->lower($actor);
    my $fsm = $lowered->{files}{'constant_bank_storage_widths.fsm'};

    like($fsm, qr/\(\+constants\s+\(DATA_W 7\)\s+\)/s, 'scheduled .fsm preserves actor constant declaration');
    like($fsm, qr/\(\+size[\s\S]*\(data_0 7\)[\s\S]*\(data_1 7\)/, 'scheduled .fsm uses resolved bank widths');
    like($fsm, qr/\(<- \(data_0 wdata\) <\(== idx 0\)\)/, 'store uses resolved scalarized bank entry');
    like($fsm, qr/\(<- \(rdata> data_0\) <\(== idx 0\)\)/, 'load uses resolved scalarized bank entry');

    my $report = decode_json($scheduler->report($actor));
    assert_actor_storage($report, 'data_0', 7);
    assert_actor_storage($report, 'data_1', 7);
    assert_bank_accesses($report);

    assert_fsm_reaches_hdl($fsm, 'constant_bank_storage_widths', qr/\breg\s+\[6:0\]\s+data_0\b/, 'HDL data_0 width is resolved');
    assert_fsm_reaches_hdl($fsm, 'constant_bank_storage_widths', qr/\breg\s+\[6:0\]\s+data_1\b/, 'HDL data_1 width is resolved');
};

subtest 'enum-resolved actor constant bank width lowers' => sub {
    my $actor = parse_source(<<'ISF', 'enum-constant-bank-width.isf');
(actor enum_constant_bank_width
  (clock clk)
  (enums
    (sizes (W 6)))
  (constants
    (DATA_W sizes.W))
  (interface
    (input start)
    (output done))
  (storage
    (bank data (width DATA_W) (depth 2)))
  (transaction main
    (on start)
    (complete done)))
ISF

    is(storage_width($actor, 'data'), 6, 'enum-resolved actor constant becomes a positive bank width');

    my $fsm = FSM::Scheduler::ISF->new()->lower($actor)->{files}{'enum_constant_bank_width.fsm'};
    like($fsm, qr/\(\+size[\s\S]*\(data_0 6\)[\s\S]*\(data_1 6\)/, 'scheduled .fsm uses enum-resolved bank width');
};

subtest 'unsupported actor constant bank width sources fail closed' => sub {
    assert_parse_rejected(
        <<'ISF',
(actor zero_constant_bank_width
  (clock clk)
  (constants
    (DATA_W 0))
  (interface
    (input start)
    (output done))
  (storage
    (bank data (width DATA_W) (depth 2))))
ISF
        qr/\AError: actor 'zero_constant_bank_width' storage bank 'data' width constant 'DATA_W' must resolve to a positive integer/,
        'zero-valued actor constant is rejected',
    );

    assert_parse_rejected(
        <<'ISF',
(actor unknown_constant_bank_width
  (clock clk)
  (interface
    (input start)
    (output done))
  (storage
    (bank data (width DATA_W) (depth 2))))
ISF
        qr/\AError: actor 'unknown_constant_bank_width' storage bank 'data' width token 'DATA_W' is not a declared actor scalar parameter, actor constant, or imported package scalar constant/,
        'unknown symbolic width is rejected',
    );

    assert_parse_rejected(
        <<'ISF',
(actor runtime_constant_bank_width
  (clock clk)
  (interface
    (input start)
    (input DATA_W)
    (output done))
  (storage
    (bank data (width DATA_W) (depth 2))))
ISF
        qr/\AError: actor 'runtime_constant_bank_width' storage bank 'data' width token 'DATA_W' is a runtime interface signal/,
        'runtime interface signals are rejected as widths',
    );

    assert_parse_rejected(
        <<'ISF',
(actor expression_constant_bank_width
  (clock clk)
  (interface
    (input start)
    (output done))
  (storage
    (bank data (width (+ DATA_W 1)) (depth 2))))
ISF
        qr/\AError: actor 'expression_constant_bank_width' storage 'data' width requires '\(width positive_integer_or_actor_scalar_parameter_or_actor_constant_or_qualified_package_scalar_constant\)'/,
        'width expressions are rejected at parse time',
    );

};

done_testing();

sub parse_source {
    my ($source, $label) = @_;
    return FSM::Adapter::ISF->new()->parse_source($source, $label);
}

sub assert_parse_rejected {
    my ($source, $diagnostic_re, $label) = @_;
    my $ok = eval {
        parse_source($source, "$label.isf");
        1;
    };
    my $diagnostic = $@;

    ok(!$ok, "$label fails closed");
    ok(!ref($diagnostic), "$label diagnostic is scalar");
    like($diagnostic, $diagnostic_re, "$label diagnostic is targeted");
}

sub storage_entry {
    my ($actor, $name) = @_;
    my ($entry) = grep { $_->{name} eq $name } @{$actor->{storage} || []};
    ok($entry, "found storage '$name'");
    return $entry;
}

sub storage_width {
    my ($actor, $name) = @_;
    my $entry = storage_entry($actor, $name);
    return $entry ? $entry->{width} : undef;
}

sub storage_signal_widths {
    my ($actor, $name) = @_;
    my $entry = storage_entry($actor, $name);
    return [
        map { $_->{width} }
        @{$entry->{signals} || []}
    ];
}

sub assert_actor_storage {
    my ($report, $name, $width) = @_;
    my ($entry) = grep { $_->{name} eq $name } @{$report->{inferred_storage} || []};

    ok($entry, "schedule report includes actor storage '$name'");
    is($entry->{kind}, 'register', "actor storage '$name' reports register kind") if $entry;
    is($entry->{role}, 'actor_storage', "actor storage '$name' reports actor_storage role") if $entry;
    is($entry->{width}, $width, "actor storage '$name' reports width") if $entry;
}

sub assert_bank_accesses {
    my ($report) = @_;
    is(scalar(@{$report->{bank_accesses} || []}), 2, 'schedule report exposes store and load bank accesses');
    for my $entry (@{$report->{bank_accesses} || []}) {
        is($entry->{bank}, 'data', 'bank access records bank name');
        is($entry->{width}, 7, 'bank access records resolved bank width');
        is($entry->{depth}, 2, 'bank access records bank depth');
        is_deeply($entry->{scalar_entries}, [qw(data_0 data_1)], 'bank access records scalarized entries');
    }
}

sub assert_fsm_reaches_hdl {
    my ($fsm, $module_name, $hdl_re, $label) = @_;
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
    ok($fsm_module, "$label scheduled .fsm parses through the normal frontend");

    my $hdl = FSM::HDL::FlattenedDT->new(debug => 0)->generate_systemverilog($fsm_module);
    like($hdl, $hdl_re, $label);
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
