#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use IPC::Cmd qw(run);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;

subtest 'declared aggregate top-port paths contribute exact width to concat inference' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'aggregate_concat_inference_top.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'aggregate_concat_inference_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:aggregate_concat_inference_top
  (+types
    (type frame_t (record (tag (bits 4)) (flag bit)))
  )
  (?ports:public_io
    in_frame<frame_t
  )
  (?rtl:sink)
  (?toplink:wiring
    /in_frame.tag,payload/sink.data_in/
  )
)

(?rtlif:sink
  data_in<8:data
)
FSM
    );

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        quiet => 1,
    );
    my $result = $pipeline->generate_hdl_from_file($composition_path);

    my %ports = map { $_->name => $_ } @{$result->{composition_plan}->ports};
    ok($ports{in_frame}, 'declared aggregate top port remains present');
    ok($ports{payload}, 'remaining whole top-port concat operand is inferred');
    is($ports{payload}->direction, 'input', 'inferred remainder top port is an input');
    is($ports{payload}->width, 4, 'aggregate member path width leaves a four-bit remainder for payload');

    my $hdl = $result->{hdl_code};
    like($hdl, qr/\binput\s+frame_t__fsmgen_t\s+in_frame\b/s, 'generated HDL keeps the declared aggregate top input');
    like($hdl, qr/\binput\s+\[3:0\]\s+payload\b/s, 'generated HDL exposes the inferred remainder input with exact width');
    like($hdl, qr/\.data_in\(\{in_frame\.tag,\s*payload\}\)/s, 'generated HDL binds the aggregate path plus inferred operand concat');

    my ($success) = run(
        command => ['./bin/fsmgen', '--quiet', '--output', $output_path, $composition_path],
        verbose => 0,
    );
    ok($success, 'CLI succeeds for aggregate top-expression concat inference');
    ok(-e $output_path, 'CLI writes HDL for aggregate top-expression concat inference');
};

subtest 'undeclared aggregate roots fail with a user-facing inference diagnostic' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'undeclared_aggregate_root_top.fsm');

    write_file(
        $composition_path,
        <<'FSM'
(?top:undeclared_aggregate_root_top
  (?rtl:sink)
  (?toplink:wiring
    /in_frame.tag/sink.nibble/
  )
)

(?rtlif:sink
  nibble<4:data
)
FSM
    );

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        quiet => 1,
    );

    my $exception = eval {
        $pipeline->generate_hdl_from_file($composition_path);
        undef;
    };
    $exception = $@;

    like(
        $exception,
        qr/omits top port 'in_frame', .*explicit top-link port inference is blocked because top expression 'in_frame\.tag' uses aggregate member\/item access before the root top port has a declared aggregate type/s,
        'pipeline explains why aggregate member inference needs a declared aggregate root',
    );
    unlike(
        $exception,
        qr/TopPortInferenceBuilder requires a supported top-expression exact-width rule/s,
        'pipeline no longer leaks the internal exact-width assertion',
    );
};

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
