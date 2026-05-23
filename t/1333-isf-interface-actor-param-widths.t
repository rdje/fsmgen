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

subtest 'actor scalar parameter interface widths lower like literal widths' => sub {
    my $source = <<'ISF';
(actor parameter_interface_widths
  (clock clk)
  (params
    (DATA_W 8))
  (interface
    (input start)
    (input data_in (width DATA_W))
    (output data_out (width DATA_W)))
  (transaction main
    (on start)
    (set data_out data_in)))
ISF

    my $actor = parse_source($source, 'parameter-interface-widths.isf');
    is(port_width($actor->{interface}{inputs}, 'data_in'), 8, 'input width resolves from actor parameter');
    is(port_width($actor->{interface}{outputs}, 'data_out'), 8, 'output width resolves from actor parameter');

    my $scheduler = FSM::Scheduler::ISF->new();
    my $lowered = $scheduler->lower($actor);
    my $fsm = $lowered->{files}{'parameter_interface_widths.fsm'};

    like($fsm, qr/\(\+params\s+\(DATA_W 8\)\s+\)/s, 'scheduled .fsm preserves actor parameter declaration');
    like($fsm, qr/\(\+size[\s\S]*\(data_in 8\)[\s\S]*\(data_out 8\)/, 'scheduled .fsm uses resolved interface widths');
    like($fsm, qr/\(<- \(data_out> data_in\)\)/, 'scheduled .fsm preserves data movement');

    my $report = decode_json($scheduler->report($actor));
    is($report->{inputs}, 2, 'schedule report input count is unchanged');
    is($report->{outputs}, 1, 'schedule report output count is unchanged');

    assert_fsm_reaches_hdl($fsm, 'parameter_interface_widths', qr/\binput\s+wire\s+\[7:0\]\s+data_in\b/, 'HDL input width is resolved');
    assert_fsm_reaches_hdl($fsm, 'parameter_interface_widths', qr/\boutput\s+reg\s+\[7:0\]\s+data_out\b/, 'HDL output width is resolved');
};

subtest 'enum-resolved actor scalar parameter interface width lowers' => sub {
    my $actor = parse_source(<<'ISF', 'enum-parameter-interface-width.isf');
(actor enum_parameter_interface_width
  (clock clk)
  (enums
    (sizes (W 4)))
  (params
    (DATA_W sizes.W))
  (interface
    (input start)
    (output data_out (width DATA_W)))
  (transaction main
    (on start)
    (set data_out 0)))
ISF

    is(port_width($actor->{interface}{outputs}, 'data_out'), 4, 'enum-resolved actor parameter becomes a positive width');

    my $fsm = FSM::Scheduler::ISF->new()->lower($actor)->{files}{'enum_parameter_interface_width.fsm'};
    like($fsm, qr/\(\+size[\s\S]*\(data_out 4\)/, 'scheduled .fsm uses enum-resolved parameter width');
};

subtest 'unsupported actor parameter interface width sources fail closed' => sub {
    assert_parse_rejected(
        <<'ISF',
(actor zero_parameter_width
  (clock clk)
  (params
    (DATA_W 0))
  (interface
    (output data_out (width DATA_W))))
ISF
        qr/\AError: actor 'zero_parameter_width' interface port 'data_out' width parameter 'DATA_W' must resolve to a positive integer/,
        'zero-valued actor parameter is rejected',
    );

    assert_parse_rejected(
        <<'ISF',
(actor aggregate_parameter_width
  (clock clk)
  (params
    (DATA_W (4 4)))
  (interface
    (output data_out (width DATA_W))))
ISF
        qr/\AError: actor 'aggregate_parameter_width' interface port 'data_out' width parameter 'DATA_W' must resolve to a positive integer/,
        'non-scalar actor parameter is rejected',
    );

    assert_parse_rejected(
        <<'ISF',
(actor unknown_parameter_width
  (clock clk)
  (interface
    (output data_out (width DATA_W))))
ISF
        qr/\AError: actor 'unknown_parameter_width' interface port 'data_out' width token 'DATA_W' is not a declared actor scalar parameter/,
        'unknown symbolic width is rejected',
    );

    assert_parse_rejected(
        <<'ISF',
(actor constant_parameter_width
  (clock clk)
  (constants
    (DATA_W 8))
  (interface
    (output data_out (width DATA_W))))
ISF
        qr/\AError: actor 'constant_parameter_width' interface port 'data_out' width token 'DATA_W' is an actor constant/,
        'actor constants remain outside this interface-width slice',
    );

    assert_parse_rejected(
        <<'ISF',
(actor runtime_parameter_width
  (clock clk)
  (interface
    (input DATA_W)
    (output data_out (width DATA_W))))
ISF
        qr/\AError: actor 'runtime_parameter_width' interface port 'data_out' width token 'DATA_W' is a runtime interface signal/,
        'runtime interface signals are rejected as widths',
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

sub port_width {
    my ($ports, $name) = @_;
    my ($port) = grep { $_->{name} eq $name } @{$ports || []};
    ok($port, "found port '$name'");
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
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
