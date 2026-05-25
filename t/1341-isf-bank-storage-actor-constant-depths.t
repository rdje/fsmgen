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

subtest 'actor constants bank depths lower like literal depths' => sub {
    my $source = <<'ISF';
(actor constant_bank_storage_depths
  (clock clk)
  (constants
    (DEPTH 3))
  (interface
    (input start)
    (input idx (width 2))
    (input wdata (width 7))
    (output rdata (width 7))
    (output done))
  (storage
    (bank data (width 7) (depth DEPTH)))
  (transaction main
    (on start)
    (store data idx wdata)
    (load data idx as rdata)
    (complete done)))
ISF

    my $actor = parse_source($source, 'constant-bank-storage-depths.isf');
    is(storage_depth($actor, 'data'), 3, 'bank depth resolves from actor constant');
    is_deeply(storage_signal_names($actor, 'data'), [qw(data_0 data_1 data_2)], 'bank signal family is finalized');
    is_deeply(storage_signal_widths($actor, 'data'), [7, 7, 7], 'bank signal widths remain finalized');

    my $scheduler = FSM::Scheduler::ISF->new();
    my $lowered = $scheduler->lower($actor);
    my $fsm = $lowered->{files}{'constant_bank_storage_depths.fsm'};

    like($fsm, qr/\(\+constants\s+\(DEPTH 3\)\s+\)/s, 'scheduled .fsm preserves actor constant declaration');
    like($fsm, qr/\(\+size[\s\S]*\(data_0 7\)[\s\S]*\(data_2 7\)/, 'scheduled .fsm uses resolved bank depth');
    like($fsm, qr/\(<- \(data_2 wdata\) <\(== idx 2\)\)/, 'store includes the resolved final bank entry');
    like($fsm, qr/\(<- \(rdata> data_2\) <\(== idx 2\)\)/, 'load includes the resolved final bank entry');

    my $report = decode_json($scheduler->report($actor));
    assert_actor_storage($report, 'data_0', 7);
    assert_actor_storage($report, 'data_1', 7);
    assert_actor_storage($report, 'data_2', 7);
    assert_bank_accesses($report, 3, [qw(data_0 data_1 data_2)]);

    assert_fsm_reaches_hdl($fsm, 'constant_bank_storage_depths', qr/\breg\s+\[6:0\]\s+data_2\b/, 'HDL final bank entry width is resolved');
};

subtest 'actor constants compose for bank width and depth' => sub {
    my $actor = parse_source(<<'ISF', 'constant-bank-width-and-depth.isf');
(actor constant_bank_width_and_depth
  (clock clk)
  (constants
    (DATA_W 6)
    (DEPTH 2))
  (interface
    (input start)
    (output done))
  (storage
    (bank data (width DATA_W) (depth DEPTH)))
  (transaction main
    (on start)
    (complete done)))
ISF

    is(storage_width($actor, 'data'), 6, 'bank width resolves from actor constant');
    is(storage_depth($actor, 'data'), 2, 'bank depth resolves from actor constant');
    is_deeply(storage_signal_widths($actor, 'data'), [6, 6], 'bank signal widths compose with constant depth');

    my $fsm = FSM::Scheduler::ISF->new()->lower($actor)->{files}{'constant_bank_width_and_depth.fsm'};
    like($fsm, qr/\(\+size[\s\S]*\(data_0 6\)[\s\S]*\(data_1 6\)/, 'scheduled .fsm uses composed constant width and depth');
};

subtest 'enum-resolved actor constant bank depth lowers' => sub {
    my $actor = parse_source(<<'ISF', 'enum-constant-bank-depth.isf');
(actor enum_constant_bank_depth
  (clock clk)
  (enums
    (sizes (DEPTH 3)))
  (constants
    (BANK_DEPTH sizes.DEPTH))
  (interface
    (input start)
    (output done))
  (storage
    (bank data (width 7) (depth BANK_DEPTH)))
  (transaction main
    (on start)
    (complete done)))
ISF

    is(storage_depth($actor, 'data'), 3, 'enum-resolved actor constant becomes a positive bank depth');
    is_deeply(storage_signal_names($actor, 'data'), [qw(data_0 data_1 data_2)], 'enum-resolved depth scalarizes the bank');

    my $fsm = FSM::Scheduler::ISF->new()->lower($actor)->{files}{'enum_constant_bank_depth.fsm'};
    like($fsm, qr/\(\+size[\s\S]*\(data_0 7\)[\s\S]*\(data_2 7\)/, 'scheduled .fsm uses enum-resolved bank depth');
};

subtest 'unsupported actor constant bank depth sources fail closed' => sub {
    assert_parse_rejected(
        <<'ISF',
(actor zero_constant_bank_depth
  (clock clk)
  (constants
    (DEPTH 0))
  (interface
    (input start)
    (output done))
  (storage
    (bank data (width 7) (depth DEPTH))))
ISF
        qr/\AError: actor 'zero_constant_bank_depth' storage bank 'data' depth constant 'DEPTH' must resolve to a positive integer/,
        'zero-valued actor constant is rejected',
    );

    assert_parse_rejected(
        <<'ISF',
(actor unknown_constant_bank_depth
  (clock clk)
  (interface
    (input start)
    (output done))
  (storage
    (bank data (width 7) (depth DEPTH))))
ISF
        qr/\AError: actor 'unknown_constant_bank_depth' storage bank 'data' depth token 'DEPTH' is not a declared actor scalar parameter, actor constant, or imported package scalar constant/,
        'unknown symbolic depth is rejected',
    );

    assert_parse_rejected(
        <<'ISF',
(actor runtime_constant_bank_depth
  (clock clk)
  (interface
    (input start)
    (input DEPTH)
    (output done))
  (storage
    (bank data (width 7) (depth DEPTH))))
ISF
        qr/\AError: actor 'runtime_constant_bank_depth' storage bank 'data' depth token 'DEPTH' is a runtime interface signal/,
        'runtime interface signals are rejected as depths',
    );

    assert_parse_rejected(
        <<'ISF',
(actor expression_constant_bank_depth
  (clock clk)
  (interface
    (input start)
    (output done))
  (storage
    (bank data (width 7) (depth (+ DEPTH 1)))))
ISF
        qr/\AError: actor 'expression_constant_bank_depth' storage 'data' depth requires '\(depth positive_integer_or_actor_scalar_parameter_or_actor_constant_or_qualified_package_scalar_constant\)'/,
        'depth expressions are rejected at parse time',
    );
};

subtest 'constant bank depths preserve duplicate scalarized signal rejection' => sub {
    assert_parse_rejected(
        <<'ISF',
(actor duplicate_constant_bank_depth
  (clock clk)
  (constants
    (DEPTH 2))
  (interface
    (input start)
    (output done))
  (storage
    (var data_1 (width 7))
    (bank data (width 7) (depth DEPTH))))
ISF
        qr/\AError: actor 'duplicate_constant_bank_depth' storage 'data' lowers to duplicate signal 'data_1'/,
        'constant depth scalarization still rejects duplicate lowered signals',
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

sub storage_depth {
    my ($actor, $name) = @_;
    my $entry = storage_entry($actor, $name);
    return $entry ? $entry->{depth} : undef;
}

sub storage_signal_names {
    my ($actor, $name) = @_;
    my $entry = storage_entry($actor, $name);
    return [
        map { $_->{name} }
        @{$entry->{signals} || []}
    ];
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
    my ($report, $depth, $scalar_entries) = @_;
    is(scalar(@{$report->{bank_accesses} || []}), 2, 'schedule report exposes store and load bank accesses');
    for my $entry (@{$report->{bank_accesses} || []}) {
        is($entry->{bank}, 'data', 'bank access records bank name');
        is($entry->{width}, 7, 'bank access records resolved bank width');
        is($entry->{depth}, $depth, 'bank access records resolved bank depth');
        is_deeply($entry->{scalar_entries}, $scalar_entries, 'bank access records scalarized entries');
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
