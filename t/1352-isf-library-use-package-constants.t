#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP qw(decode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

subtest 'package scalar constants specialize reusable-library use-site overrides' => sub {
    my $dir = tempdir(CLEANUP => 1);
    write_file(File::Spec->catfile($dir, 'shared.fsm'), <<'FSM');
(?pkg:shared
  (+constants
    (DEFAULT_MODE 1)
    (IDLE_MODE 0))
)
FSM

    my $isf_path = File::Spec->catfile($dir, 'library_use_package_constants.isf');
    write_file($isf_path, library_source() . <<'ISF');
(actor library_use_package_constants
  (imports
    (package shared)
    (library common.pulse as pulse_lib))
  (clock clk)
  (reset rst)
  (interface
    (input trigger)
    (output fired))
  (use pulse_lib.pulse_actor as rx
    (params
      (MODE shared.DEFAULT_MODE)
      (MODES (shared.DEFAULT_MODE shared.IDLE_MODE)))
    (bind
      (clock clk)
      (reset rst)
      (input trigger trigger)
      (output fired fired))))
ISF

    my $actor = FSM::Adapter::ISF->new()->parse_file($isf_path);
    is_deeply(
        $actor->{library_uses}[0]{parameter_overrides},
        [
            { name => 'MODE', value => '1' },
            { name => 'MODES', value => [ '1', '0' ] },
        ],
        'parser resolves package constant use-site overrides before publication',
    );

    my $scheduler = FSM::Scheduler::ISF->new();
    my $lowered = $scheduler->lower($actor);
    my $top_fsm = $lowered->{files}{'library_use_package_constants_top.fsm'};
    like(
        $top_fsm,
        qr/\(\?fsmc:rx library_use_package_constants__rx\s+\(params\s+\(MODE 1\)\s+\(MODES \(1 0\)\)\s+\)\s+\)/s,
        'generated top applies resolved package constant use-site overrides',
    );
    unlike($top_fsm, qr/shared\./, 'generated top does not leak package constant tokens in use-site overrides');

    my $report = decode_json($scheduler->report($actor));
    my %params = map { $_->{name} => $_ } @{$report->{library_uses}[0]{parameters}};
    is($params{MODE}{source}, 'override', 'report marks scalar package constant use-site parameter as override');
    is($params{MODE}{value}, '1', 'report exposes resolved scalar package constant use-site value');
    is($params{MODES}{source}, 'override', 'report marks aggregate package constant use-site parameter as override');
    is($params{MODES}{value}, '(1 0)', 'report exposes resolved aggregate package constant leaves');

    my $hdl_path = File::Spec->catfile($dir, 'library_use_package_constants.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--strict', '--outdir', $dir, '--output', $hdl_path, $isf_path],
    );
    ok($success, 'CLI HDL generation succeeds for package constant library use-site overrides');
    is(join('', @{$stderr_buf || []}), '', 'CLI keeps stderr clean for package constant library use-site overrides');
    ok(-s $hdl_path, 'CLI writes HDL for package constant library use-site overrides');
};

subtest 'package constant reusable-library use-site diagnostics fail closed' => sub {
    my $dir = tempdir(CLEANUP => 1);
    write_file(File::Spec->catfile($dir, 'shared.fsm'), <<'FSM');
(?pkg:shared
  (+constants
    (MODES (1 0))
    (DEFAULT_MODE 1))
)
FSM

    assert_parse_file_rejected(
        $dir,
        'unknown_package_constant.isf',
        library_source() . <<'ISF',
(actor unknown_package_constant
  (imports
    (package shared)
    (library common.pulse as pulse_lib))
  (interface
    (input trigger)
    (output fired))
  (use pulse_lib.pulse_actor as rx
    (params
      (MODE shared.MISSING))
    (bind
      (clock clk)
      (reset rst)
      (input trigger trigger)
      (output fired fired))))
ISF
        qr/actor 'unknown_package_constant' use 'rx' parameter 'MODE' references unknown package constant 'shared\.MISSING'/,
        'unknown package constants are rejected',
    );

    assert_parse_file_rejected(
        $dir,
        'unqualified_package_constant.isf',
        library_source() . <<'ISF',
(actor unqualified_package_constant
  (imports
    (package shared)
    (library common.pulse as pulse_lib))
  (interface
    (input trigger)
    (output fired))
  (use pulse_lib.pulse_actor as rx
    (params
      (MODE DEFAULT_MODE))
    (bind
      (clock clk)
      (reset rst)
      (input trigger trigger)
      (output fired fired))))
ISF
        qr/actor 'unqualified_package_constant' use 'rx' parameter 'MODE' uses unsupported parameter value 'DEFAULT_MODE'/,
        'unqualified package constants are rejected',
    );

    assert_parse_file_rejected(
        $dir,
        'aggregate_package_constant.isf',
        library_source() . <<'ISF',
(actor aggregate_package_constant
  (imports
    (package shared)
    (library common.pulse as pulse_lib))
  (interface
    (input trigger)
    (output fired))
  (use pulse_lib.pulse_actor as rx
    (params
      (MODE shared.MODES))
    (bind
      (clock clk)
      (reset rst)
      (input trigger trigger)
      (output fired fired))))
ISF
        qr/actor 'aggregate_package_constant' use 'rx' parameter 'MODE' package constant 'shared\.MODES' must resolve to a scalar numeric or exact-width literal value/,
        'aggregate package constants remain deferred as use-site overrides',
    );

    assert_parse_file_rejected(
        $dir,
        'package_constant_leaf_path.isf',
        library_source() . <<'ISF',
(actor package_constant_leaf_path
  (imports
    (package shared)
    (library common.pulse as pulse_lib))
  (interface
    (input trigger)
    (output fired))
  (use pulse_lib.pulse_actor as rx
    (params
      (MODE shared.MODES[0]))
    (bind
      (clock clk)
      (reset rst)
      (input trigger trigger)
      (output fired fired))))
ISF
        qr/actor 'package_constant_leaf_path' use 'rx' parameter 'MODE' package constant 'shared\.MODES' aggregate\/member path 'shared\.MODES\[0\]' remains deferred/,
        'package aggregate constant scalar-leaf paths remain deferred',
    );

    my $mode_dir = tempdir(CLEANUP => 1);
    write_file(File::Spec->catfile($mode_dir, 'mode.fsm'), <<'FSM');
(?pkg:mode
  (+constants
    (BUSY 1))
)
FSM
    assert_parse_file_rejected(
        $mode_dir,
        'ambiguous_package_constant.isf',
        library_source() . <<'ISF',
(actor ambiguous_package_constant
  (imports
    (package mode)
    (library common.pulse as pulse_lib))
  (enums
    (mode (BUSY 1)))
  (interface
    (input trigger)
    (output fired))
  (use pulse_lib.pulse_actor as rx
    (params
      (MODE mode.BUSY))
    (bind
      (clock clk)
      (reset rst)
      (input trigger trigger)
      (output fired fired))))
ISF
        qr/actor 'ambiguous_package_constant' use 'rx' parameter 'MODE' token 'mode\.BUSY' is ambiguous: it matches local enum member 'mode\.BUSY' and imported package constant 'mode\.BUSY'/,
        'ambiguous local-enum and package-constant tokens are rejected',
    );
};

done_testing();

sub library_source {
    return <<'ISF';
(library common.pulse
  (exports
    (actor pulse_actor))
  (actor pulse_actor
    (params
      (MODE 0)
      (MODES (0 0)))
    (clock clk)
    (reset rst)
    (interface
      (input trigger)
      (output fired))
    (transaction main
      (on trigger)
      (complete fired))))
ISF
}

sub assert_parse_file_rejected {
    my ($dir, $filename, $source, $regex, $label) = @_;
    my $path = File::Spec->catfile($dir, $filename);
    write_file($path, $source);
    my $ok = eval {
        FSM::Adapter::ISF->new()->parse_file($path);
        1;
    };
    ok(!$ok, "$label fails closed");
    like($@, $regex, "$label diagnostic");
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "open $path: $!";
    print {$fh} $content or die "write $path: $!";
    close $fh or die "close $path: $!";
    return $path;
}
