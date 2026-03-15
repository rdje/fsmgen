#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use IPC::Cmd qw(run);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::Pipeline::HDLGenerator;
use FSM::SourceClassifier;

my $tempdir = tempdir(CLEANUP => 1);
my $flat_path = File::Spec->catfile($tempdir, 'flat_plus_fsm_ok.fsm');
my $flat_out_path = File::Spec->catfile($tempdir, 'flat_plus_fsm_ok.sv');
my $nested_path = File::Spec->catfile($tempdir, 'nested_plus_fsm_ok.fsm');
my $nested_out_path = File::Spec->catfile($tempdir, 'nested_plus_fsm_ok.sv');
my $bad_path = File::Spec->catfile($tempdir, 'flat_plus_fsm_bad.fsm');
my $bad_out_path = File::Spec->catfile($tempdir, 'flat_plus_fsm_bad.sv');

write_file(
    $flat_path,
    <<'FSM'
(+fsm flat_plus_fsm_ok)
(+system
  (clock clk)
  (sreset rstn)
)
(+size
  (OUT 1)
  (IN 1)
)
(idle
  (OUT = IN)
)
FSM
);

write_file(
    $nested_path,
    <<'FSM'
(+fsm nested_plus_fsm_ok
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+size
    (OUT 1)
    (IN 1)
  )
  (idle
    (OUT = IN)
  )
)
FSM
);

write_file(
    $bad_path,
    <<'FSM'
(+fsm)
(+system
  (clock clk)
  (sreset rstn)
)
(+size
  (OUT 1)
)
(idle
  (OUT = 1)
)
FSM
);

my $flat_raw_ast = Lispish::multi($flat_path);
my $flat_source_info = FSM::SourceClassifier::classify_source_ast($flat_raw_ast);
is($flat_source_info->{kind}, 'fsm', 'flattened +fsm root is classified as an FSM source');
is($flat_source_info->{header}, '+fsm', 'classifier preserves the flattened +fsm header');

my $adapter = FSM::Adapter::FSMGenFull->new(debug => 0);
my $flat_module = $adapter->parse_fsm($flat_raw_ast);
is($flat_module->name, 'flat_plus_fsm_ok', 'flattened +fsm root preserves the scalar module name');
is_deeply(
    [map { $_->name } @{$flat_module->states || []}],
    ['idle'],
    'flattened +fsm root still parses state blocks through the active FSM parser',
);

my $pipeline = FSM::Pipeline::HDLGenerator->new(
    debug_level => 0,
    quiet => 1,
);

my $flat_result = $pipeline->generate_hdl_from_file($flat_path);
like(
    $flat_result->{hdl_code},
    qr/\bmodule\s+flat_plus_fsm_ok\b/s,
    'pipeline generates HDL for the flattened +fsm root',
);

my ($cli_success, $cli_error_message, $cli_full_buf, $cli_stdout_buf, $cli_stderr_buf) = run(
    command => ['./bin/fsmgen', '-o', $flat_out_path, '--quiet', $flat_path],
);

ok($cli_success, 'CLI accepts the flattened +fsm root');
ok(-e $flat_out_path, 'CLI emits output for the flattened +fsm root');

my $nested_raw_ast = Lispish::multi($nested_path);
my $nested_source_info = FSM::SourceClassifier::classify_source_ast($nested_raw_ast);
is($nested_source_info->{kind}, 'fsm', 'nested legacy +fsm root is also classified as an FSM source');
is($nested_source_info->{header}, '+fsm', 'classifier preserves the nested legacy +fsm header');

my $nested_module = $adapter->parse_fsm($nested_raw_ast);
is($nested_module->name, 'nested_plus_fsm_ok', 'nested legacy +fsm root preserves the scalar module name');
is_deeply(
    [map { $_->name } @{$nested_module->states || []}],
    ['idle'],
    'nested legacy +fsm root still parses state blocks through the active FSM parser',
);

my $nested_result = $pipeline->generate_hdl_from_file($nested_path);
like(
    $nested_result->{hdl_code},
    qr/\bmodule\s+nested_plus_fsm_ok\b/s,
    'pipeline also generates HDL for the nested legacy +fsm root',
);

my ($nested_cli_success, $nested_cli_error_message, $nested_cli_full_buf, $nested_cli_stdout_buf, $nested_cli_stderr_buf) = run(
    command => ['./bin/fsmgen', '-o', $nested_out_path, '--quiet', $nested_path],
);

ok($nested_cli_success, 'CLI accepts the nested legacy +fsm root');
ok(-e $nested_out_path, 'CLI emits output for the nested legacy +fsm root');

my $bad_raw_ast = Lispish::multi($bad_path);
my $bad_source_info = FSM::SourceClassifier::classify_source_ast($bad_raw_ast);
is($bad_source_info->{kind}, 'fsm', 'malformed flattened +fsm root still classifies as an FSM source kind');
is($bad_source_info->{header}, '+fsm', 'malformed flattened +fsm root still preserves the +fsm header');

my $bad_adapter_error = eval {
    $adapter->parse_fsm($bad_raw_ast);
    undef;
};
$bad_adapter_error = $@;

like(
    $bad_adapter_error,
    qr/Malformed '\+fsm' root/,
    'FSM-only parser rejects a malformed +fsm root without a scalar module name explicitly',
);

my $bad_pipeline_error = eval {
    $pipeline->generate_hdl_from_file($bad_path);
    undef;
};
$bad_pipeline_error = $@;

like(
    $bad_pipeline_error,
    qr/Malformed '\+fsm' root/,
    'pipeline surfaces the same malformed flattened +fsm diagnostic',
);

my ($bad_cli_success, $bad_cli_error_message, $bad_cli_full_buf, $bad_cli_stdout_buf, $bad_cli_stderr_buf) = run(
    command => ['./bin/fsmgen', '-o', $bad_out_path, '--quiet', $bad_path],
);

ok(!$bad_cli_success, 'CLI rejects a malformed flattened +fsm root');
ok(!-e $bad_out_path, 'CLI does not emit output for a malformed flattened +fsm root');

my $bad_cli_output = join(
    '',
    @{ $bad_cli_stdout_buf || [] },
    @{ $bad_cli_stderr_buf || [] },
    ($bad_cli_error_message || ''),
);

like(
    $bad_cli_output,
    qr/Malformed '\+fsm' root/,
    'CLI surfaces the malformed +fsm root diagnostic clearly',
);

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
