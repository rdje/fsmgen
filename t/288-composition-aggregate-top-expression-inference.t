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

subtest 'previously inferred aggregate top-port roots contribute exact width to concat inference' => sub {
    my @cases = (
        {
            name => 'whole_root_link_first',
            toplinks => <<'FSM',
    /in_frame/consumer.IN_FRAME/
    /in_frame.tag,payload/sink.data_in/
    /consumer.OUT_FLAG/flag_out/
FSM
        },
        {
            name => 'aggregate_path_link_first',
            toplinks => <<'FSM',
    /in_frame.tag,payload/sink.data_in/
    /in_frame/consumer.IN_FRAME/
    /consumer.OUT_FLAG/flag_out/
FSM
        },
    );

    for my $case (@cases) {
        my $tempdir = tempdir(CLEANUP => 1);
        my $composition_path = File::Spec->catfile($tempdir, $case->{name}.'.fsm');

        write_file(
            $composition_path,
            <<"FSM"
(?top:$case->{name}
  (?dtc:consumer consumer_src)
  (?rtl:sink)
  (?toplink:wiring
$case->{toplinks}  )
)

(?dt:consumer_src
  (+types
    (type frame_t (record (tag (bits 4)) (flag bit)))
  )
  (+size
    (IN_FRAME frame_t)
    (OUT_FLAG 1)
  )
  (-pass
    (OUT_FLAG = IN_FRAME.flag)
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
        my $hdl = $result->{hdl_code};

        ok($ports{in_frame}, "$case->{name}: aggregate root top port is inferred from the typed child input");
        is($ports{in_frame}->declared_type_spec->{kind}, 'record', "$case->{name}: inferred aggregate root keeps its record contract");
        is($ports{in_frame}->width, 5, "$case->{name}: inferred aggregate root keeps its packed width");
        ok($ports{payload}, "$case->{name}: remaining whole top-port concat operand is inferred");
        is($ports{payload}->width, 4, "$case->{name}: aggregate path leaves a four-bit remainder for payload");
        like($hdl, qr/\binput\s+frame_t__fsmgen_t\s+in_frame\b/s, "$case->{name}: generated HDL exposes inferred aggregate input with typedef");
        like($hdl, qr/\.data_in\(\{in_frame\.tag,\s*payload\}\)/s, "$case->{name}: generated HDL binds inferred aggregate path plus payload concat");
    }
};

subtest 'same-name aggregate child inputs can seed aggregate top-expression inference' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'same_name_aggregate_root_top.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'same_name_aggregate_root_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:same_name_aggregate_root_top
  (?dtc:consumer consumer_src)
  (?rtl:sink)
  (?toplink:wiring
    /in_frame.tag,payload/sink.data_in/
    /in_frame.tag/sink.nibble/
    /consumer.out_flag/flag_out/
  )
)

(?dt:consumer_src
  (+types
    (type frame_t (record (tag (bits 4)) (flag bit)))
  )
  (+size
    (in_frame frame_t)
    (out_flag 1)
  )
  (-pass
    (out_flag = in_frame.flag)
  )
)

(?rtlif:sink
  data_in<8:data
  nibble<4:data
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
    my $hdl = $result->{hdl_code};

    ok($ports{in_frame}, 'same-name child input seeds the aggregate root top port');
    is($ports{in_frame}->declared_type_spec->{kind}, 'record', 'same-name inferred aggregate root keeps its record contract');
    is($ports{in_frame}->width, 5, 'same-name inferred aggregate root keeps its packed width');
    ok($ports{payload}, 'same-name aggregate root still allows the concat remainder operand to be inferred');
    is($ports{payload}->width, 4, 'same-name aggregate root leaves a four-bit remainder for payload');
    like($hdl, qr/\binput\s+frame_t__fsmgen_t\s+in_frame\b/s, 'generated HDL exposes the same-name inferred aggregate input with typedef');
    like($hdl, qr/\.in_frame\(in_frame\)/s, 'generated HDL keeps the same-name child input fanout binding');
    like($hdl, qr/\.data_in\(\{in_frame\.tag,\s*payload\}\)/s, 'generated HDL binds concat source through the same-name inferred aggregate root');
    like($hdl, qr/\.nibble\(in_frame\.tag\)/s, 'generated HDL binds direct member source through the same-name inferred aggregate root');

    my ($success) = run(
        command => ['./bin/fsmgen', '--quiet', '--output', $output_path, $composition_path],
        verbose => 0,
    );
    ok($success, 'CLI succeeds for same-name aggregate-root top-expression inference');
    ok(-e $output_path, 'CLI writes HDL for same-name aggregate-root top-expression inference');
};

subtest 'explicitly linked same-name child inputs do not seed aggregate roots' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'explicitly_linked_same_name_aggregate_root_top.fsm');

    write_file(
        $composition_path,
        <<'FSM'
(?top:explicitly_linked_same_name_aggregate_root_top
  (?dtc:consumer consumer_src)
  (?rtl:sink)
  (?toplink:wiring
    /other_frame/consumer.in_frame/
    /in_frame.tag/sink.nibble/
    /consumer.out_flag/flag_out/
  )
)

(?dt:consumer_src
  (+types
    (type frame_t (record (tag (bits 4)) (flag bit)))
  )
  (+size
    (in_frame frame_t)
    (out_flag 1)
  )
  (-pass
    (out_flag = in_frame.flag)
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
        'pipeline does not reuse an explicitly linked same-name child input as aggregate-root inference evidence',
    );
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
