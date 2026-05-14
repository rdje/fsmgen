#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use IPC::Cmd qw(run);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

subtest 'library actor use emits generated top wiring' => sub {
    my $dir = tempdir(CLEANUP => 1);
    write_library($dir);
    my $top = write_top($dir);

    my $actor = FSM::Adapter::ISF->new()->parse_file($top);
    my $lowered = FSM::Scheduler::ISF->new()->lower($actor);
    my $top_fsm = $lowered->{files}{'library_wrapper_top.fsm'};

    ok(defined($top_fsm), 'lowering emits a generated top for a library actor use');
    like($top_fsm, qr/\A\(\?top:library_wrapper_top\b/, 'library generated top is a composition root');
    like($top_fsm, qr/\(\?fsmc:library_wrapper library_wrapper\)/, 'generated top instantiates the importing actor');
    like($top_fsm, qr/\(\?fsmc:rx library_wrapper__rx\b/, 'generated top instantiates the library actor instance');
    unlike($top_fsm, qr{/clk/rx\.clk/}, 'generated top leaves same-name clock binding to system auto-wiring');
    unlike($top_fsm, qr{/rst_n/rx\.rst_n/}, 'generated top leaves same-name reset binding to system auto-wiring');
    like($top_fsm, qr{/trigger/rx\.trigger/}, 'generated top wires bound parent input to library input');
    like($top_fsm, qr{/rx\.fired/fired/}, 'generated top wires library output to parent output');
    unlike($top_fsm, qr{/library_wrapper\.fired/fired/}, 'generated top does not also drive a library-owned output from the parent');
};

subtest 'CLI compiles library generated top through normal HDL generation' => sub {
    my $dir = tempdir(CLEANUP => 1);
    write_library($dir);
    my $top = write_top($dir);
    my $output = File::Spec->catfile($dir, 'library_wrapper.sv');

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => [
            './bin/fsmgen',
            '--quiet',
            '--outdir',
            $dir,
            '--output',
            $output,
            $top,
        ],
    );

    ok($success, 'CLI generation succeeds for a library actor generated top');
    is(join('', @{$stderr_buf || []}), '', 'CLI generation keeps stderr empty');
    ok(-f File::Spec->catfile($dir, 'library_wrapper_top.fsm'), 'CLI writes the library generated top .fsm');
    ok(-f $output, 'CLI writes generated HDL');

    my $hdl = slurp($output);
    like($hdl, qr/\bmodule\s+library_wrapper_top\b/, 'HDL contains the generated top module');
    like($hdl, qr/library_wrapper__rx rx \([\s\S]*?\.clk\(clk\)/, 'library child clock is bound to top clock');
    like($hdl, qr/library_wrapper__rx rx \([\s\S]*?\.rst_n\(rst_n\)/, 'library child reset is bound to top reset');
    like($hdl, qr/library_wrapper__rx rx \([\s\S]*?\.trigger\(trigger\)/, 'library child input is bound to top input');
    like($hdl, qr/library_wrapper__rx rx \([\s\S]*?\.fired\(fired\)/, 'library child output is bound to top output');
};

subtest 'library generated top fails closed for system-name remapping' => sub {
    assert_lower_rejected(<<'ISF', 'clock remapping', qr/requires same-name system clocks/);
(library common.pulse
  (exports (actor pulse_actor))
  (actor pulse_actor
    (clock lib_clk)
    (interface (input trigger) (output fired))
    (transaction main
      (on trigger)
      (complete fired))))
(actor library_clock_remap
  (clock clk)
  (interface (input trigger) (output fired))
  (imports (library common.pulse as pulse_lib))
  (use pulse_lib.pulse_actor as rx
    (bind
      (clock clk)
      (input trigger trigger)
      (output fired fired))))
ISF

    assert_lower_rejected(<<'ISF', 'reset remapping', qr/requires same-name system resets/);
(library common.pulse
  (exports (actor pulse_actor))
  (actor pulse_actor
    (clock clk)
    (reset lib_rst_n)
    (interface (input trigger) (output fired))
    (transaction main
      (on trigger)
      (complete fired))))
(actor library_reset_remap
  (clock clk)
  (reset rst_n)
  (interface (input trigger) (output fired))
  (imports (library common.pulse as pulse_lib))
  (use pulse_lib.pulse_actor as rx
    (bind
      (clock clk)
      (reset rst_n)
      (input trigger trigger)
      (output fired fired))))
ISF
};

done_testing();

sub write_library {
    my ($dir) = @_;
    my $lib_dir = File::Spec->catdir($dir, 'common');
    make_path($lib_dir);
    my $path = File::Spec->catfile($lib_dir, 'pulse.isf');
    write_file($path, <<'ISF');
(library common.pulse
  (exports
    (actor pulse_actor))
  (actor pulse_actor
    (clock clk)
    (reset (rst_n async active_low))
    (interface
      (input trigger)
      (output fired))
    (transaction main
      (on trigger)
      (complete fired))))
ISF
    return $path;
}

sub write_top {
    my ($dir) = @_;
    my $path = File::Spec->catfile($dir, 'top.isf');
    write_file($path, <<'ISF');
(actor library_wrapper
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input trigger)
    (output fired))
  (imports
    (library common.pulse as pulse_lib))
  (use pulse_lib.pulse_actor as rx
    (bind
      (clock clk)
      (reset rst_n)
      (input trigger trigger)
      (output fired fired))))
ISF
    return $path;
}

sub write_file {
    my ($path, $source) = @_;
    open my $fh, '>', $path or die "cannot write $path: $!";
    print {$fh} $source;
    close $fh or die "cannot close $path: $!";
}

sub slurp {
    my ($path) = @_;
    open my $fh, '<', $path or die "cannot read $path: $!";
    my $text = do { local $/; <$fh> };
    close $fh or die "cannot close $path: $!";
    return $text;
}

sub assert_lower_rejected {
    my ($source, $label, $diagnostic_re) = @_;

    my $ok = eval {
        my $actor = FSM::Adapter::ISF->new()->parse_source($source, "$label.isf");
        FSM::Scheduler::ISF->new()->lower($actor);
        1;
    };
    my $diagnostic = $@;

    ok(!$ok, "$label is rejected");
    like($diagnostic, $diagnostic_re, "$label diagnostic");
}
