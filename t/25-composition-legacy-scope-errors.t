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
use FSM::Composition::Parser;
use Lispish;

my $parser = FSM::Composition::Parser->new;
my $tempdir = tempdir(CLEANUP => 1);

my $macro_path = File::Spec->catfile($tempdir, 'legacy_macro_top.fsm');
my $nested_top_path = File::Spec->catfile($tempdir, 'nested_top_top.fsm');
my $ports_mapping_path = File::Spec->catfile($tempdir, 'ports_mapping_top.fsm');
my $toplink_nested_path = File::Spec->catfile($tempdir, 'nested_toplink_top.fsm');
my $macro_out_path = File::Spec->catfile($tempdir, 'legacy_macro_top.sv');

write_file(
    $macro_path,
    <<'FSM'
(?top:legacy_macro_top
  (?ports:public_io
    clk
    rstn
  )
  (?&legacy_emit
    foo=bar
  )
)
FSM
);

write_file(
    $nested_top_path,
    <<'FSM'
(?top:outer_top
  (?top:inner_top
    (?ports:public_io
      clk
    )
  )
)
FSM
);

write_file(
    $ports_mapping_path,
    <<'FSM'
(?top:ports_mapping_top
  (?ports:public_io
    /foo/bar/
  )
)
FSM
);

write_file(
    $toplink_nested_path,
    <<'FSM'
(?top:nested_toplink_top
  (?ports:public_io
    clk
    rstn
  )
  (?fsmc:child child_src)
  (?toplink:wiring
    (foo bar)
  )
)

(?fsm:child_src
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

my $macro_error = eval {
    $parser->parse_source(scalar Lispish::multi($macro_path));
    undef;
};
$macro_error = $@;

like(
    $macro_error,
    qr/legacy macro\/plugin child '\?&legacy_emit'.*outside the active R6 composition scope/s,
    'parser rejects legacy macro/plugin composition constructs explicitly',
);
like(
    $macro_error,
    qr/docs\/COMPOSITION_SCOPE\.md/s,
    'legacy macro/plugin rejection points to the scoped composition doc',
);
like(
    $macro_error,
    qr/docs\/COMPOSITION_LEGACY_MAPPING\.md/s,
    'legacy macro/plugin rejection points to the legacy mapping note',
);

my $nested_top_error = eval {
    $parser->parse_source(scalar Lispish::multi($nested_top_path));
    undef;
};
$nested_top_error = $@;

like(
    $nested_top_error,
    qr/nested '\?top:name' blocks are outside the first active R6 composition lane/s,
    'parser rejects nested top blocks explicitly',
);

my $ports_mapping_error = eval {
    $parser->parse_source(scalar Lispish::multi($ports_mapping_path));
    undef;
};
$ports_mapping_error = $@;

like(
    $ports_mapping_error,
    qr/\?ports' mapping directive '\/foo\/bar\/'.*only supports explicit top-port declarations/s,
    'parser rejects legacy ports mapping directives explicitly',
);

my $nested_toplink_error = eval {
    $parser->parse_source(scalar Lispish::multi($toplink_nested_path));
    undef;
};
$nested_toplink_error = $@;

like(
    $nested_toplink_error,
    qr/nested '\?toplink' item.*only supports flat '\/source\/target\/' link tokens/s,
    'parser rejects nested toplink structures explicitly',
);

my $pipeline = FSM::Pipeline::HDLGenerator->new(
    debug_level => 0,
    target_language => 'systemverilog',
    quiet => 1,
);

my $pipeline_exception = eval {
    $pipeline->generate_hdl_from_file($macro_path);
    undef;
};
$pipeline_exception = $@;

like(
    $pipeline_exception,
    qr/legacy macro\/plugin child '\?&legacy_emit'.*outside the active R6 composition scope/s,
    'pipeline surfaces the explicit legacy macro/plugin scope failure',
);

my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
    command => ['./bin/fsmgen', '-o', $macro_out_path, '--quiet', $macro_path],
);

ok(!$success, 'CLI rejects legacy macro/plugin composition constructs outside the scoped model');
ok(!-e $macro_out_path, 'CLI does not emit output for out-of-scope legacy macro/plugin composition input');

my $combined_output = join(
    '',
    @{ $stdout_buf || [] },
    @{ $stderr_buf || [] },
    ($error_message || ''),
);

like(
    $combined_output,
    qr/legacy macro\/plugin child '\?&legacy_emit'.*outside the active R6 composition scope/s,
    'CLI surfaces the explicit legacy macro/plugin scope failure',
);
like(
    $combined_output,
    qr/docs\/COMPOSITION_SCOPE\.md/s,
    'CLI legacy macro/plugin rejection points to the scoped composition doc',
);

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
