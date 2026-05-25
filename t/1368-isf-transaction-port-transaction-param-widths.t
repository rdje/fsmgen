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

subtest 'generated child transaction parameters are valid transaction port widths' => sub {
    my $actor = parse_source(<<'ISF', 'generated-child-transaction-port-transaction-param-widths.isf');
(actor generated_child_transaction_port_param_widths
  (clock clk)
  (reset rst_n)
  (constants
    (DATA_W 5))
  (interface
    (input start)
    (input req_addr (width 8))
    (input req_tag (width 4))
    (output done)
    (output resp (width 8))
    (output tag_resp (width 4)))
  (transaction child
    (params
      (DATA_W 8)
      (TAG_W 4)
      (DERIVED_W DATA_W))
    (ports
      (input addr (width DERIVED_W))
      (input tag (width TAG_W))
      (output data (width DATA_W))
      (output tag_data (width TAG_W)))
    (update data addr)
    (update tag_data tag)
    (complete done))
  (transaction parent
    (on start)
    (spawn child as c0
      (bind
        (input addr req_addr)
        (input tag req_tag)
        (output data resp)
        (output tag_data tag_resp)))
    (complete done)))
ISF

    is(transaction_port_width($actor, 'child', 'inputs', 'addr'), 8,
        'input port width resolves from an earlier transaction parameter default');
    is(transaction_port_width($actor, 'child', 'inputs', 'tag'), 4,
        'second input port width resolves from a literal transaction parameter default');
    is(transaction_port_width($actor, 'child', 'outputs', 'data'), 8,
        'transaction parameter names resolve before actor constants of the same name');
    is(transaction_port_width($actor, 'child', 'outputs', 'tag_data'), 4,
        'output tag port width resolves from a literal transaction parameter default');

    my $scheduler = FSM::Scheduler::ISF->new();
    my $lowered = $scheduler->lower($actor);
    my $parent_fsm = $lowered->{files}{'generated_child_transaction_port_param_widths.fsm'};
    my $child_fsm = $lowered->{files}{'child.fsm'};

    like($parent_fsm, qr/\(c0_addr 8\)/, 'parent handoff storage uses resolved transaction parameter input width');
    like($parent_fsm, qr/\(c0_tag 4\)/, 'parent handoff storage uses resolved transaction parameter tag width');
    like($parent_fsm, qr/\(c0_data 8\)/, 'parent handoff storage uses resolved transaction parameter output width');
    like($parent_fsm, qr/\(c0_tag_data 4\)/, 'parent handoff storage uses resolved transaction parameter tag output width');
    like($child_fsm, qr/\(\+size[\s\S]*\(addr 8\)[\s\S]*\(tag 4\)[\s\S]*\(data 8\)[\s\S]*\(tag_data 4\)/,
        'generated child .fsm uses resolved transaction parameter transaction port widths');

    my $report = decode_json($scheduler->report($actor));
    is_deeply(
        [map { $_->{width} } @{$report->{transaction_port_bindings} || []}],
        [8, 4, 8, 4],
        'schedule report binding widths use resolved transaction parameter transaction port widths',
    );

    assert_fsm_reaches_hdl($child_fsm, 'child', qr/\binput\s+wire\s+\[7:0\]\s+addr\b/,
        'HDL addr width is resolved');
    assert_fsm_reaches_hdl($child_fsm, 'child', qr/\binput\s+wire\s+\[3:0\]\s+tag\b/,
        'HDL tag width is resolved');
    assert_fsm_reaches_hdl($child_fsm, 'child', qr/\breg\s+\[7:0\]\s+data\b/,
        'HDL data width is resolved');
    assert_fsm_reaches_hdl($child_fsm, 'child', qr/\breg\s+\[3:0\]\s+tag_data\b/,
        'HDL tag_data width is resolved');
};

subtest 'direct transaction parameters are valid transaction port widths' => sub {
    my $actor = parse_source(<<'ISF', 'direct-transaction-port-param-width.isf');
(actor direct_transaction_port_param_width
  (clock clk)
  (interface
    (input start)
    (output data (width 8))
    (output done))
  (transaction main
    (on start)
    (params
      (DATA_W 8)
      (DERIVED_W DATA_W))
    (ports
      (input addr (width DERIVED_W))
      (output resp (width DATA_W)))
    (update resp addr)
    (complete done)))
ISF

    is(transaction_port_width($actor, 'main', 'inputs', 'addr'), 8,
        'direct input port width resolves from a transaction parameter default');
    is(transaction_port_width($actor, 'main', 'outputs', 'resp'), 8,
        'direct output port width resolves from a transaction parameter default');

    my $fsm = FSM::Scheduler::ISF->new()->lower($actor)->{files}{'direct_transaction_port_param_width.fsm'};
    like($fsm, qr/\(\+size[\s\S]*\(addr 8\)[\s\S]*\(resp 8\)/,
        'direct scheduled .fsm uses resolved transaction parameter port widths');
    unlike($fsm, qr/DATA_W|DERIVED_W/, 'direct transaction parameter port widths leave no scheduled placeholders');

    assert_fsm_reaches_hdl($fsm, 'direct_transaction_port_param_width', qr/\binput\s+wire\s+\[7:0\]\s+addr\b/,
        'direct HDL addr port width is resolved');
    assert_fsm_reaches_hdl($fsm, 'direct_transaction_port_param_width', qr/\breg\s+\[7:0\]\s+resp\b/,
        'direct HDL resp port width is resolved');
};

subtest 'unrelated direct transaction parameters remain gated' => sub {
    assert_lower_rejected(
        <<'ISF',
(actor unrelated_direct_transaction_port_param
  (clock clk)
  (interface
    (input start)
    (output done))
  (transaction main
    (on start)
    (params
      (UNUSED_W 8))
    (ports
      (input addr (width 8)))
    (complete done)))
ISF
        qr/\ATransaction 'main': params are supported only on generated child transactions, same-transaction temporal contract windows, same-transaction data-operation width evidence, same-transaction transaction-port width evidence, same-transaction repeat counts, same-transaction wait counts, or same-transaction latency bounds/,
        'unrelated direct transaction parameters still fail closed',
    );
};

subtest 'transaction parameter transaction port width diagnostics fail closed' => sub {
    assert_parse_rejected(
        <<'ISF',
(actor zero_generated_child_transaction_port_param_width
  (clock clk)
  (interface
    (input start)
    (output done))
  (transaction child
    (params
      (DATA_W 0))
    (ports
      (input addr (width DATA_W)))
    (complete done))
  (transaction parent
    (on start)
    (spawn child as c0)
    (complete done)))
ISF
        qr/\AError: actor 'zero_generated_child_transaction_port_param_width' transaction 'child' port 'addr' width transaction parameter 'DATA_W' must resolve to a positive integer/,
        'zero-valued generated child transaction parameter width',
    );

    assert_parse_rejected(
        <<'ISF',
(actor aggregate_generated_child_transaction_port_param_width
  (clock clk)
  (interface
    (input start)
    (output done))
  (transaction child
    (params
      (DATA_W (4 4)))
    (ports
      (input addr (width DATA_W)))
    (complete done))
  (transaction parent
    (on start)
    (spawn child as c0)
    (complete done)))
ISF
        qr/\AError: actor 'aggregate_generated_child_transaction_port_param_width' transaction 'child' port 'addr' width transaction parameter 'DATA_W' must resolve to a positive integer/,
        'aggregate generated child transaction parameter width',
    );

    assert_parse_rejected(
        <<'ISF',
(actor forward_generated_child_transaction_port_param_width
  (clock clk)
  (interface
    (input start)
    (output done))
  (transaction child
    (params
      (DATA_W LATER_W)
      (LATER_W 8))
    (ports
      (input addr (width DATA_W)))
    (complete done))
  (transaction parent
    (on start)
    (spawn child as c0)
    (complete done)))
ISF
        qr/\ATransaction 'child': parameter 'DATA_W' transaction parameter 'LATER_W' must reference an earlier scalar transaction parameter default/,
        'forward transaction parameter defaults remain rejected as port width evidence',
    );

    assert_parse_rejected(
        <<'ISF',
(actor self_generated_child_transaction_port_param_width
  (clock clk)
  (interface
    (input start)
    (output done))
  (transaction child
    (params
      (DATA_W DATA_W))
    (ports
      (input addr (width DATA_W)))
    (complete done))
  (transaction parent
    (on start)
    (spawn child as c0)
    (complete done)))
ISF
        qr/\ATransaction 'child': parameter 'DATA_W' transaction parameter 'DATA_W' must reference an earlier scalar transaction parameter default/,
        'self-referential transaction parameter defaults remain rejected as port width evidence',
    );

    assert_parse_rejected(
        <<'ISF',
(actor cross_transaction_port_param_width
  (clock clk)
  (interface
    (input start)
    (output done))
  (transaction helper
    (params
      (OTHER_W 8))
    (complete done))
  (transaction child
    (ports
      (input addr (width OTHER_W)))
    (complete done))
  (transaction parent
    (on start)
    (spawn child as c0)
    (complete done)))
ISF
        qr/\AError: actor 'cross_transaction_port_param_width' transaction 'child' port 'addr' width token 'OTHER_W' is not a same-transaction scalar parameter, declared actor scalar parameter, actor constant, or imported package scalar constant/,
        'cross-transaction parameter widths remain rejected',
    );

    assert_parse_rejected(
        <<'ISF',
(actor runtime_generated_child_transaction_port_param_width
  (clock clk)
  (interface
    (input start)
    (input DATA_W)
    (output done))
  (transaction child
    (ports
      (input addr (width DATA_W)))
    (complete done))
  (transaction parent
    (on start)
    (spawn child as c0)
    (complete done)))
ISF
        qr/\AError: actor 'runtime_generated_child_transaction_port_param_width' transaction 'child' port 'addr' width token 'DATA_W' is a runtime interface signal; transaction port widths accept positive integer literals, same-transaction scalar parameters, actor constants, actor scalar parameters, or qualified package scalar constants only/,
        'runtime interface signals remain rejected as transaction port widths',
    );

    assert_parse_rejected(
        <<'ISF',
(actor expression_generated_child_transaction_port_param_width
  (clock clk)
  (interface
    (input start)
    (output done))
  (transaction child
    (params
      (DATA_W 8))
    (ports
      (input addr (width (+ DATA_W 1))))
    (complete done))
  (transaction parent
    (on start)
    (spawn child as c0)
    (complete done)))
ISF
        qr/transaction 'child' port 'addr' width requires '\(width positive_integer_or_same_transaction_scalar_parameter_or_actor_scalar_parameter_or_actor_constant_or_qualified_package_scalar_constant\)'/,
        'width expressions remain rejected at parse time',
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

sub assert_lower_rejected {
    my ($source, $diagnostic_re, $label) = @_;
    my $ok = eval {
        my $actor = parse_source($source, "$label.isf");
        FSM::Scheduler::ISF->new()->lower($actor);
        1;
    };
    my $diagnostic = $@;

    ok(!$ok, "$label fails closed");
    ok(!ref($diagnostic), "$label diagnostic is scalar");
    like($diagnostic, $diagnostic_re, "$label diagnostic is targeted");
}

sub transaction_by_name {
    my ($actor, $name) = @_;
    my ($tx) = grep { $_->{name} eq $name } @{$actor->{transactions} || []};
    ok($tx, "found transaction '$name'");
    return $tx;
}

sub transaction_port_width {
    my ($actor, $transaction_name, $direction, $port_name) = @_;
    my $tx = transaction_by_name($actor, $transaction_name);
    my ($port) = grep { $_->{name} eq $port_name } @{($tx->{ports} || {})->{$direction} || []};
    ok($port, "found $direction port '$port_name'");
    return $port ? $port->{width} : undef;
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
    open my $fh, '>', $path or die "open $path: $!";
    print {$fh} $content or die "write $path: $!";
    close $fh or die "close $path: $!";
    return $path;
}
