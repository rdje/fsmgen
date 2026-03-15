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

subtest 'legacy placeholder test selectors are rejected explicitly' => sub {
    my $fsm_path = write_fsm('placeholder_selector.fsm', <<'FSM');
(?fsm:placeholder_selector
  (+system (clock clk) (sreset rstn))
  (+size (X 1))
  (s0
    (?[READ]
      (=1 (X = 1))
    )
  )
)
FSM

    my $error = parse_error_for($fsm_path);
    like($error, qr/Unsupported generic\/template test selector '\?\[READ\]'/, 'placeholder selector gets a targeted diagnostic');
};

subtest 'legacy repeat macros are rejected explicitly' => sub {
    my $fsm_path = write_fsm('repeat_macro.fsm', <<'FSM');
(?fsm:repeat_macro
  (+system (clock clk) (sreset rstn))
  (+size (X 1))
  (s0
    (?repeat:[MAX_COUNT]
      (X = 1)
    )
  )
)
FSM

    my $error = parse_error_for($fsm_path);
    like($error, qr/Unsupported generic\/template repeat action '\?repeat:\[MAX_COUNT\]'/, 'repeat macro gets a targeted diagnostic');
};

subtest 'legacy placeholder tokens are rejected explicitly in expressions' => sub {
    my $fsm_path = write_fsm('placeholder_token.fsm', <<'FSM');
(?fsm:placeholder_token
  (+system (clock clk) (sreset rstn))
  (+size (X 8))
  (s0
    (X = [DATAIN])
  )
)
FSM

    my $error = parse_error_for($fsm_path);
    like($error, qr/Unsupported generic\/template placeholder token '\[DATAIN\]'/, 'placeholder expression token gets a targeted diagnostic');
};

done_testing();

sub write_fsm {
    my ($name, $content) = @_;
    my $path = File::Spec->catfile($tempdir, $name);
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
    return $path;
}

sub parse_error_for {
    my ($fsm_path) = @_;
    my $raw_ast = Lispish::multi($fsm_path);
    my $adapter = FSM::Adapter::FSMGenFull->new(debug => 0);

    my $error;
    eval {
        $adapter->parse_fsm($raw_ast);
        1;
    } or do {
        $error = $@;
    };

    ok($error, 'parse failed as expected');
    return $error;
}
