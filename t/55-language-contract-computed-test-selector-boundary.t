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
use FSM::Pipeline::HDLGenerator;

my $tempdir = tempdir(CLEANUP => 1);

subtest 'computed test selectors must start with a selector expression' => sub {
    my $error = parse_failure(<<'FSM');
(?fsm:missing_computed_selector_expr
  (+system
    (clock clk)
    (sreset rstn)
  )
  (idle
    (?
      (=0 (OUT <= 0))
      (=1 (OUT <= 1))
    )
  )
)
FSM

    like(
        $error,
        qr/Malformed computed test selector '\?'/,
        'missing computed selector expression gets a targeted diagnostic',
    );
};

subtest 'computed test selectors must include at least one branch' => sub {
    my $error = parse_failure(<<'FSM');
(?fsm:branchless_computed_selector
  (+system
    (clock clk)
    (sreset rstn)
  )
  (idle
    (?(| A B))
  )
)
FSM

    like(
        $error,
        qr/Malformed computed test selector '\?'/,
        'branchless computed selector gets a targeted diagnostic',
    );
};

subtest 'pipeline and CLI do not emit HDL for malformed computed test selectors' => sub {
    my $fsm_path = write_fsm('bad_computed_test_selector_cli.fsm', <<'FSM');
(?fsm:bad_computed_test_selector_cli
  (+system
    (clock clk)
    (sreset rstn)
  )
  (idle
    (?
      (=0 (OUT <= 0))
      (=1 (OUT <= 1))
    )
  )
)
FSM

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug => 0,
    );
    my $pipeline_error = eval {
        $pipeline->generate_hdl_from_file($fsm_path);
        undef;
    };
    $pipeline_error = $@ if !$pipeline_error;
    ok($pipeline_error, 'pipeline rejects malformed computed test selector');
    like(
        $pipeline_error,
        qr/Malformed computed test selector '\?'/,
        'pipeline surfaces the explicit computed-selector boundary',
    );

    my $out_path = File::Spec->catfile($tempdir, 'bad_computed_test_selector_cli.sv');
    my $success = system($^X, '-I', 'perl', 'bin/fsmgen', '--output', $out_path, $fsm_path) == 0;
    ok(!$success, 'CLI rejects malformed computed test selector');
    ok(!-e $out_path, 'CLI does not emit output for malformed computed test selector');
};

done_testing();

sub parse_failure {
    my ($fsm_text) = @_;
    my $fsm_path = write_fsm('parse_failure_' . int(rand(1_000_000)) . '.fsm', $fsm_text);
    my $raw_ast = Lispish::multi($fsm_path);
    my $adapter = FSM::Adapter::FSMGenFull->new(debug => 0);

    my $error = eval {
        $adapter->parse_fsm($raw_ast);
        undef;
    };
    $error = $@ if !$error;
    ok($error, "parse fails for generated fixture");
    return $error;
}

sub write_fsm {
    my ($filename, $content) = @_;
    my $path = File::Spec->catfile($tempdir, $filename);
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
    return $path;
}
