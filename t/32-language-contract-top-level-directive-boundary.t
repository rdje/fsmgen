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

subtest 'unknown top-level + directives no longer drift into fake state parsing' => sub {
    my $error = parse_failure(<<'FSM');
(?fsm:bad_top_level_directive
  (+bogus
    (foo bar)
  )
  (-dt
    (A = 1)
  )
)
FSM

    like($error, qr/Unsupported top-level directive '\+bogus'/, 'unknown + directive gets a targeted diagnostic');
};

subtest 'future-looking alternative directive spellings are rejected explicitly for now' => sub {
    my $error = parse_failure(<<'FSM');
(?fsm:future_clock_directive
  (+clock clk)
  (+asreset rstn)
  (-dt
    (A = 1)
  )
)
FSM

    like($error, qr/Unsupported top-level directive '\+clock'/, 'unsupported future-style +clock directive is rejected explicitly');
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
    my $fsm_path = File::Spec->catfile($tempdir, "directive_" . int(rand(1_000_000)) . ".fsm");
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
