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
my $source_path = File::Spec->catfile($tempdir, 'legacy_define_wrapper.fsm');
my $out_path = File::Spec->catfile($tempdir, 'legacy_define_wrapper.sv');

write_file(
    $source_path,
    <<'FSM'
(?define:legacy_template
  (?fsm:inner_smoke
    (+system
      (clock clk)
      (sreset rstn)
    )
    (+size
      (A 1)
    )
    (-dt
      (A = 1)
    )
  )
)
FSM
);

my $raw_ast = Lispish::multi($source_path);
my $source_info = FSM::SourceClassifier::classify_source_ast($raw_ast);
is($source_info->{kind}, 'unknown', 'legacy tagged top-level source stays outside active source kinds');
is($source_info->{header}, '?define:legacy_template', 'classifier preserves the unsupported top-level header');

my $adapter = FSM::Adapter::FSMGenFull->new(debug => 0);
my $adapter_exception = eval {
    $adapter->parse_fsm($raw_ast);
    undef;
};
$adapter_exception = $@;

like(
    $adapter_exception,
    qr/Unsupported top-level source '\?define:legacy_template'/,
    'FSM-only parser rejects unsupported tagged top-level source explicitly',
);
unlike(
    $adapter_exception,
    qr/Expected FSM structure containing '\?fsm:name' or '\+fsm'/,
    'FSM-only parser no longer falls through to the generic FSM-shape error',
);
unlike(
    $adapter_exception,
    qr/inner_smoke/,
    'FSM-only parser does not silently honor the nested inner FSM inside the unsupported wrapper',
);

my $pipeline = FSM::Pipeline::HDLGenerator->new(
    debug_level => 0,
    quiet => 1,
);

my $pipeline_exception = eval {
    $pipeline->generate_hdl_from_file($source_path);
    undef;
};
$pipeline_exception = $@;

like(
    $pipeline_exception,
    qr/Unsupported top-level source '\?define:legacy_template'/,
    'pipeline rejects unsupported tagged top-level source explicitly',
);
unlike(
    $pipeline_exception,
    qr/Expected FSM structure containing '\?fsm:name' or '\+fsm'/,
    'pipeline no longer falls through to the generic FSM-shape error',
);
ok(!-e $out_path, 'no HDL output exists before the CLI attempt');

my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
    command => ['./bin/fsmgen', '-o', $out_path, '--quiet', $source_path],
);

ok(!$success, 'CLI rejects unsupported tagged top-level source');
ok(!-e $out_path, 'CLI does not emit output for unsupported tagged top-level source');

my $combined_output = join(
    '',
    @{ $stdout_buf || [] },
    @{ $stderr_buf || [] },
    ($error_message || ''),
);

like(
    $combined_output,
    qr/Unsupported top-level source '\?define:legacy_template'/,
    'CLI surfaces the tagged top-level source boundary clearly',
);
unlike(
    $combined_output,
    qr/Expected FSM structure containing '\?fsm:name' or '\+fsm'/,
    'CLI no longer leaks the generic FSM-shape parser error for unsupported tagged top-level source',
);

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
