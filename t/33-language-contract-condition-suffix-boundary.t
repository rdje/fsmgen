#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw/ tempdir /;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use Lispish;
use FSM::Adapter::FSMGenFull;

my $tempdir = tempdir(CLEANUP => 1);

subtest 'bare assignment condition suffixes are rejected explicitly' => sub {
    my $error = parse_failure(<<'FSM');
(?fsm:bad_assignment_suffix
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-dt
    (A <= B start)
  )
)
FSM

    like($error, qr/Unsupported bare condition suffix 'start'/, 'bare assignment suffix gets a targeted diagnostic');
};

subtest 'bare transition condition suffixes are rejected explicitly' => sub {
    my $error = parse_failure(<<'FSM');
(?fsm:bad_transition_suffix
  (+system
    (clock clk)
    (sreset rstn)
  )
  (idle
    (-> busy full)
  )
  (busy
    (A = 1)
  )
)
FSM

    like($error, qr/Unsupported bare condition suffix 'full'/, 'bare transition suffix gets a targeted diagnostic');
};

done_testing();

sub parse_failure {
    my ($fsm_text) = @_;
    my $error;
    eval {
        parse_fsm_with_adapter($fsm_text);
        1;
    } or do {
        $error = $@;
    };
    ok($error, 'parse failed as expected');
    return $error;
}

sub parse_fsm_with_adapter {
    my ($fsm_text) = @_;
    my $fsm_path = File::Spec->catfile($tempdir, "suffix_" . int(rand(1_000_000)) . ".fsm");
    write_file($fsm_path, $fsm_text);

    my $raw_ast = Lispish::multi($fsm_path);
    my $adapter = FSM::Adapter::FSMGenFull->new(debug => 0);
    return $adapter->parse_fsm($raw_ast);
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
