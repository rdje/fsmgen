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

subtest 'pipeline and CLI preserve direct top-input fanout to top outputs beside shared-datapath runtime rewrites' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'top_input_top_output_fanout_top.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'top_input_top_output_fanout_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:top_input_top_output_fanout_top
  (?ports:public_io
    clk
    rstn
    start<8
    tap_a>8
    tap_b>8
    left_seen>1
    right_seen>1
  )
  (?fsmc:left left_src)
  (?fsmc:right right_src)
  (?wiring:wiring
    /start/tap_a/
    /start/tap_b/
    /start/left.payload/
    /start/right.payload/
    /left.seen/left_seen/
    /right.seen/right_seen/
  )
)

(?fsm:left_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (seen> <= payload[0])
  )
  (+size
    (payload 8)
    (seen 1)
  )
)

(?fsm:right_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (seen> <= payload[7])
  )
  (+size
    (payload 8)
    (seen 1)
  )
)
FSM
    );

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        quiet => 1,
    );

    my $result = $pipeline->generate_hdl_from_file($composition_path);

    isa_ok($result->{composition_plan}, 'FSM::Composition::Plan');
    is($result->{composition_plan}->lane, 'C2', 'top-input fanout to top outputs stays on the explicit-link C2 lane');

    my $auxiliary_assignments = join("\n", @{$result->{composition_plan}->auxiliary_assignments || []});
    like($auxiliary_assignments, qr/assign tap_a = start;/, 'composition plan preserves the first direct top-output assignment');
    like($auxiliary_assignments, qr/assign tap_b = start;/, 'composition plan preserves the second direct top-output assignment');
    like($auxiliary_assignments, qr/assign left_seen = seen_shared_q;/, 'shared-datapath runtime assignments still coexist with the direct top-output fanout');

    my $hdl = $result->{hdl_code};
    unlike($hdl, qr/\bcomp_link_start\b/, 'generated HDL does not invent a helper carrier for direct top-input fanout');
    like($hdl, qr/assign tap_a = start;/, 'generated HDL emits the first direct top-output assignment');
    like($hdl, qr/assign tap_b = start;/, 'generated HDL emits the second direct top-output assignment');
    like($hdl, qr/left_src left \(\s*.*\.payload\(start\)/s, 'left child input binds directly to the top input');
    like($hdl, qr/right_src right \(\s*.*\.payload\(start\)/s, 'right child input binds directly to the same top input');

    my ($success) = run(
        command => ['./bin/fsmgen', '-o', $output_path, '--quiet', $composition_path],
    );

    ok($success, 'CLI succeeds for direct top-input fanout to top outputs');
    ok(-e $output_path, 'CLI writes HDL for direct top-input fanout to top outputs');
};

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
