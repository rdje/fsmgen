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
use FSM::Composition::Plan;

subtest 'declared connect-by-name fans one top input out to multiple matching child inputs' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'input_fanout_top.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'input_fanout_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:input_fanout_top
  (?ports:public_io
    =payload_in<8
    =left_seen>8
    =right_seen>8
  )
  (?dtc:left left_src)
  (?dtc:right right_src)
)

(?dt:left_src
  (-route
    (left_seen> = payload_in)
  )
  (+size
    (payload_in 8)
    (left_seen 8)
  )
)

(?dt:right_src
  (-route
    (right_seen> = payload_in)
  )
  (+size
    (payload_in 8)
    (right_seen 8)
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
    is($result->{composition_plan}->lane, 'C4', 'input fanout composition still uses the C4 lane');
    is(scalar(@{$result->{composition_plan}->links}), 4, 'input fanout plan preserves one shared input plus two top-output by-name links');
    is(scalar(@{$result->{composition_plan}->nets}), 0, 'input fanout by-name plan needs no synthetic nets');

    my %left_bindings = map { $_->{port_name} => $_->{signal_name} } @{$result->{composition_plan}->instances->[0]->port_bindings};
    my %right_bindings = map { $_->{port_name} => $_->{signal_name} } @{$result->{composition_plan}->instances->[1]->port_bindings};

    is($left_bindings{payload_in}, 'payload_in', 'first child input is driven from the shared top input');
    is($right_bindings{payload_in}, 'payload_in', 'second child input is also driven from the shared top input');
    is($left_bindings{left_seen}, 'left_seen', 'first child output is wired directly to the same-named top output');
    is($right_bindings{right_seen}, 'right_seen', 'second child output is wired directly to the same-named top output');

    my $hdl = $result->{hdl_code};
    like($hdl, qr/\.payload_in\(payload_in\)/s, 'generated HDL fans the same top input out to matching child inputs');
    like($hdl, qr/\.left_seen\(left_seen\)/s, 'generated HDL wires the first by-name output directly');
    like($hdl, qr/\.right_seen\(right_seen\)/s, 'generated HDL wires the second by-name output directly');

    my ($success) = run(
        command => ['./bin/fsmgen', '-o', $output_path, '--quiet', $composition_path],
    );

    ok($success, 'CLI succeeds for input fanout by-name composition');
    ok(-e $output_path, 'CLI writes HDL for input fanout by-name composition');
};

subtest 'declared connect-by-name rejects mixed-direction same-name candidates for top inputs' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'mixed_direction_fanout_top.fsm');

    write_file(
        $composition_path,
        <<'FSM'
(?top:mixed_direction_fanout_top
  (?ports:public_io
    =foo<8
    =bar>8
  )
  (?dtc:producer producer_src)
  (?dtc:consumer consumer_src)
)

(?dt:producer_src
  (-route
    (foo> = bar)
  )
  (+size
    (foo 8)
    (bar 8)
  )
)

(?dt:consumer_src
  (-route
    (bar> = foo)
  )
  (+size
    (foo 8)
    (bar 8)
  )
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
        qr/declared connect-by-name is blocked because same-name child endpoints include incompatible directions for a top input port/s,
        'top-input fanout by-name now says mixed-direction same-name child candidates block declared connect-by-name',
    );
    like(
        $exception,
        qr/producer\.foo\[output, width=8\], consumer\.foo\[input, width=8\]/s,
        'mixed-direction by-name diagnostics list the conflicting same-name candidates',
    );
};

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
