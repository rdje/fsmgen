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

subtest 'actor scalar parameter storage widths lower like literal widths' => sub {
    my $source = <<'ISF';
(actor parameter_scalar_storage_widths
  (clock clk)
  (params
    (STATE_W 5))
  (interface
    (input start)
    (output done))
  (storage
    (var counter (width STATE_W))
    (variable shadow (width STATE_W)))
  (transaction main
    (on start)
    (update counter (+ counter 1))
    (update shadow counter)
    (complete done)))
ISF

    my $actor = parse_source($source, 'parameter-scalar-storage-widths.isf');
    is(storage_width($actor, 'counter'), 5, 'var width resolves from actor parameter');
    is(storage_width($actor, 'shadow'), 5, 'variable alias width resolves from actor parameter');
    is(storage_signal_width($actor, 'counter'), 5, 'var signal width is finalized');
    is(storage_signal_width($actor, 'shadow'), 5, 'variable alias signal width is finalized');

    my $scheduler = FSM::Scheduler::ISF->new();
    my $lowered = $scheduler->lower($actor);
    my $fsm = $lowered->{files}{'parameter_scalar_storage_widths.fsm'};

    like($fsm, qr/\(\+params\s+\(STATE_W 5\)\s+\)/s, 'scheduled .fsm preserves actor parameter declaration');
    like($fsm, qr/\(\+size[\s\S]*\(counter 5\)[\s\S]*\(shadow 5\)/, 'scheduled .fsm uses resolved storage widths');
    like($fsm, qr/\(<- \(counter \(\+ counter 1\)\)\)/, 'scheduled .fsm preserves counter update');
    like($fsm, qr/\(<- \(shadow counter\)\)/, 'scheduled .fsm preserves shadow update');

    my $report = decode_json($scheduler->report($actor));
    assert_actor_storage($report, 'counter', 5);
    assert_actor_storage($report, 'shadow', 5);

    assert_fsm_reaches_hdl($fsm, 'parameter_scalar_storage_widths', qr/\breg\s+\[4:0\]\s+counter\b/, 'HDL counter width is resolved');
    assert_fsm_reaches_hdl($fsm, 'parameter_scalar_storage_widths', qr/\breg\s+\[4:0\]\s+shadow\b/, 'HDL shadow width is resolved');
};

subtest 'enum-resolved actor scalar parameter storage width lowers' => sub {
    my $actor = parse_source(<<'ISF', 'enum-parameter-storage-width.isf');
(actor enum_parameter_storage_width
  (clock clk)
  (enums
    (sizes (W 6)))
  (params
    (STATE_W sizes.W))
  (interface
    (input start)
    (output done))
  (storage
    (var counter (width STATE_W)))
  (transaction main
    (on start)
    (update counter (+ counter 1))
    (complete done)))
ISF

    is(storage_width($actor, 'counter'), 6, 'enum-resolved actor parameter becomes a positive storage width');

    my $fsm = FSM::Scheduler::ISF->new()->lower($actor)->{files}{'enum_parameter_storage_width.fsm'};
    like($fsm, qr/\(\+size[\s\S]*\(counter 6\)/, 'scheduled .fsm uses enum-resolved storage parameter width');
};

subtest 'unsupported actor parameter storage width sources fail closed' => sub {
    assert_parse_rejected(
        <<'ISF',
(actor zero_parameter_storage_width
  (clock clk)
  (params
    (STATE_W 0))
  (interface
    (input start)
    (output done))
  (storage
    (var counter (width STATE_W))))
ISF
        qr/\AError: actor 'zero_parameter_storage_width' storage 'counter' width parameter 'STATE_W' must resolve to a positive integer/,
        'zero-valued actor parameter is rejected',
    );

    assert_parse_rejected(
        <<'ISF',
(actor aggregate_parameter_storage_width
  (clock clk)
  (params
    (STATE_W (4 4)))
  (interface
    (input start)
    (output done))
  (storage
    (var counter (width STATE_W))))
ISF
        qr/\AError: actor 'aggregate_parameter_storage_width' storage 'counter' width parameter 'STATE_W' must resolve to a positive integer/,
        'non-scalar actor parameter is rejected',
    );

    assert_parse_rejected(
        <<'ISF',
(actor unknown_parameter_storage_width
  (clock clk)
  (interface
    (input start)
    (output done))
  (storage
    (var counter (width STATE_W))))
ISF
        qr/\AError: actor 'unknown_parameter_storage_width' storage 'counter' width token 'STATE_W' is not a declared actor scalar parameter/,
        'unknown symbolic width is rejected',
    );

    assert_parse_rejected(
        <<'ISF',
(actor constant_parameter_storage_width
  (clock clk)
  (constants
    (STATE_W 5))
  (interface
    (input start)
    (output done))
  (storage
    (var counter (width STATE_W))))
ISF
        qr/\AError: actor 'constant_parameter_storage_width' storage 'counter' width token 'STATE_W' is an actor constant/,
        'actor constants remain outside this storage-width slice',
    );

    assert_parse_rejected(
        <<'ISF',
(actor runtime_parameter_storage_width
  (clock clk)
  (interface
    (input start)
    (input STATE_W)
    (output done))
  (storage
    (var counter (width STATE_W))))
ISF
        qr/\AError: actor 'runtime_parameter_storage_width' storage 'counter' width token 'STATE_W' is a runtime interface signal/,
        'runtime interface signals are rejected as widths',
    );

    assert_parse_rejected(
        <<'ISF',
(actor expression_parameter_storage_width
  (clock clk)
  (interface
    (input start)
    (output done))
  (storage
    (var counter (width (+ STATE_W 1)))))
ISF
        qr/\AError: actor 'expression_parameter_storage_width' storage 'counter' width requires '\(width positive_integer_or_actor_scalar_parameter\)'/,
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

sub storage_signal_width {
    my ($actor, $name) = @_;
    my $entry = storage_entry($actor, $name);
    my ($signal) = grep { $_->{name} eq $name } @{$entry->{signals} || []};
    ok($signal, "found storage signal '$name'");
    return $signal ? $signal->{width} : undef;
}

sub assert_actor_storage {
    my ($report, $name, $width) = @_;
    my ($entry) = grep { $_->{name} eq $name } @{$report->{inferred_storage} || []};

    ok($entry, "schedule report includes actor storage '$name'");
    is($entry->{kind}, 'register', "actor storage '$name' reports register kind") if $entry;
    is($entry->{role}, 'actor_storage', "actor storage '$name' reports actor_storage role") if $entry;
    is($entry->{width}, $width, "actor storage '$name' reports width") if $entry;
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
