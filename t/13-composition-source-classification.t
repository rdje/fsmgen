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
use FSM::Adapter::FSMGenFull;
use Lispish;

my $tempdir = tempdir(CLEANUP => 1);
my $fsm_path = File::Spec->catfile($tempdir, 'classifier_smoke.fsm');
my $top_path = File::Spec->catfile($tempdir, 'composition_smoke.fsm');
my $top_out_path = File::Spec->catfile($tempdir, 'composition_smoke.sv');

write_file(
    $fsm_path,
    <<'FSM'
(?fsm:classifier_smoke
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (OUT <= 1)
  )
  (+size
    (OUT 1)
  )
)
FSM
);

write_file(
    $top_path,
    <<'TOP'
(?top:composition_smoke
  (?ports)
)
TOP
);

my $pipeline = FSM::Pipeline::HDLGenerator->new(
    debug_level => 0,
    quiet => 1,
);

my $fsm_ast = Lispish::multi($fsm_path);
my $fsm_source_info = $pipeline->classify_source_ast($fsm_ast);
is($fsm_source_info->{kind}, 'fsm', 'FSM root is classified as fsm');
is($fsm_source_info->{header}, '?fsm:classifier_smoke', 'FSM classifier preserves the source header');

my $composition_ast = Lispish::multi($top_path);
my $composition_source_info = $pipeline->classify_source_ast($composition_ast);
is($composition_source_info->{kind}, 'composition', 'top root is classified as composition');
is($composition_source_info->{header}, '?top:composition_smoke', 'composition classifier preserves the source header');

my $pipeline_error = eval {
    $pipeline->generate_hdl_from_file($top_path);
    undef;
};
my $pipeline_exception = $@;

ok(!$pipeline_error, 'pipeline does not return a result for composition input yet');
like(
    $pipeline_exception,
    qr/Composition source '\?top:composition_smoke'.*recognized and parsed into typed composition IR.*current active C1 lane requires exactly one '\?fsmc' child instance/s,
    'pipeline rejects unsupported composition shapes after typed parsing with an active-lane diagnostic',
);
like(
    $pipeline_exception,
    qr/docs\/COMPOSITION_SCOPE\.md/s,
    'pipeline composition boundary points to the scoped composition doc',
);
like(
    $pipeline_exception,
    qr/docs\/COMPOSITION_LEGACY_MAPPING\.md/s,
    'pipeline composition boundary points to the legacy-to-modern composition note',
);
unlike(
    $pipeline_exception,
    qr/Expected FSM structure containing '\?fsm:name' or '\+fsm'/s,
    'pipeline no longer falls through to the generic FSM-shape parser error for top-level composition input',
);

my $adapter = FSM::Adapter::FSMGenFull->new(debug => 0);
my $adapter_exception = eval {
    $adapter->parse_fsm($composition_ast);
    undef;
};
$adapter_exception = $@;

like(
    $adapter_exception,
    qr/Composition source '\?top:composition_smoke' is not supported by the FSM-only parser/s,
    'direct adapter callers also get a composition-specific boundary error',
);
unlike(
    $adapter_exception,
    qr/Expected FSM structure containing '\?fsm:name' or '\+fsm'/s,
    'direct adapter callers no longer see the generic FSM-shape parser error for top-level composition input',
);

my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
    command => ['./bin/fsmgen', '-o', $top_out_path, '--quiet', $top_path],
);

ok(!$success, 'CLI rejects composition input while the composition pipeline is not implemented');
ok(!-e $top_out_path, 'CLI does not emit output for unsupported composition input');

my $combined_output = join(
    '',
    @{ $stdout_buf || [] },
    @{ $stderr_buf || [] },
    ($error_message || ''),
);

like(
    $combined_output,
    qr/Composition source '\?top:composition_smoke'.*recognized and parsed into typed composition IR.*current active C1 lane requires exactly one '\?fsmc' child instance/s,
    'CLI surfaces the active-lane composition diagnostic',
);
unlike(
    $combined_output,
    qr/Expected FSM structure containing '\?fsm:name' or '\+fsm'/s,
    'CLI no longer leaks the generic FSM-shape parser error for top-level composition input',
);

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
