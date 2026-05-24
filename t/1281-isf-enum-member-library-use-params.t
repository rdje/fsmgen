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

subtest 'actor-local enum members specialize reusable-library use-site overrides' => sub {
    my $source = library_source() . <<'ISF';
(actor local_enum_library_use_params
  (enums
    (mode (IDLE 0) (BUSY 1)))
  (clock clk)
  (reset rst)
  (interface
    (input trigger)
    (output fired))
  (imports
    (library common.pulse as pulse_lib))
  (use pulse_lib.pulse_actor as rx
    (params
      (MODE mode.BUSY)
      (MODES (mode.BUSY mode.IDLE)))
    (bind
      (clock clk)
      (reset rst)
      (input trigger trigger)
      (output fired fired))))
ISF

    my $actor = FSM::Adapter::ISF->new()->parse_source($source, 'local-enum-library-use-params.isf');
    is_deeply(
        $actor->{library_uses}[0]{parameter_overrides},
        [
            { name => 'MODE', value => '1' },
            { name => 'MODES', value => [ '1', '0' ] },
        ],
        'parser resolves local enum use-site overrides before publishing library use metadata',
    );

    my $scheduler = FSM::Scheduler::ISF->new();
    my $lowered = $scheduler->lower($actor);
    my $top_fsm = $lowered->{files}{'local_enum_library_use_params_top.fsm'};
    like(
        $top_fsm,
        qr/\(\?fsmc:rx local_enum_library_use_params__rx\s+\(params\s+\(MODE 1\)\s+\(MODES \(1 0\)\)\s+\)\s+\)/s,
        'generated top applies resolved local enum use-site overrides',
    );
    unlike(
        $top_fsm,
        qr/mode\./,
        'generated top does not leak local enum tokens in use-site overrides',
    );
    like(
        $lowered->{files}{'local_enum_library_use_params__rx.fsm'},
        qr/\(\+params[\s\S]*\(MODE 0\)[\s\S]*\(MODES \(0 0\)\)/,
        'library child artifact preserves exported actor parameter defaults',
    );

    my $report = decode_json($scheduler->report($actor));
    my %params = map { $_->{name} => $_ } @{$report->{library_uses}[0]{parameters}};
    is($params{MODE}{source}, 'override', 'report marks scalar enum use-site parameter as override');
    is($params{MODE}{value}, '1', 'report exposes resolved scalar enum use-site value');
    is($params{MODES}{source}, 'override', 'report marks aggregate enum use-site parameter as override');
    is($params{MODES}{value}, '(1 0)', 'report exposes resolved aggregate enum use-site leaves');

    my $dir = tempdir(CLEANUP => 1);
    my $isf_path = File::Spec->catfile($dir, 'local_enum_library_use_params.isf');
    write_file($isf_path, $source);
    my $hdl_path = File::Spec->catfile($dir, 'local_enum_library_use_params.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--strict', '--outdir', $dir, '--output', $hdl_path, $isf_path],
    );
    ok($success, 'CLI HDL generation succeeds for local enum library use-site overrides');
    is(join('', @{$stderr_buf || []}), '', 'CLI keeps stderr clean for local enum library use-site overrides');
    ok(-s $hdl_path, 'CLI writes HDL for local enum library use-site overrides');
};

subtest 'package enum members specialize reusable-library use-site overrides' => sub {
    my $dir = tempdir(CLEANUP => 1);
    write_file(File::Spec->catfile($dir, 'shared.fsm'), <<'FSM');
(?pkg:shared
  (+enums
    (mode (IDLE 0) (BUSY 1)))
)
FSM

    my $isf_path = File::Spec->catfile($dir, 'package_enum_library_use_params.isf');
    write_file($isf_path, library_source() . <<'ISF');
(actor package_enum_library_use_params
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
      (MODE shared.mode.BUSY)
      (MODES (shared.mode.BUSY shared.mode.IDLE)))
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
        'parser resolves package enum use-site overrides before lowering',
    );

    my $top_fsm = FSM::Scheduler::ISF->new()->lower($actor)->{files}{'package_enum_library_use_params_top.fsm'};
    like(
        $top_fsm,
        qr/\(\?fsmc:rx package_enum_library_use_params__rx\s+\(params\s+\(MODE 1\)\s+\(MODES \(1 0\)\)\s+\)\s+\)/s,
        'generated top applies resolved package enum use-site overrides',
    );
    unlike($top_fsm, qr/shared\.mode\./, 'generated top does not leak package enum tokens in use-site overrides');

    my $hdl_path = File::Spec->catfile($dir, 'package_enum_library_use_params.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--strict', '--outdir', $dir, '--output', $hdl_path, $isf_path],
    );
    ok($success, 'CLI HDL generation succeeds for package enum library use-site overrides');
    is(join('', @{$stderr_buf || []}), '', 'CLI keeps stderr clean for package enum library use-site overrides');
    ok(-s $hdl_path, 'CLI writes HDL for package enum library use-site overrides');
};

subtest 'actor static values specialize reusable-library use-site overrides' => sub {
    my $source = library_source() . <<'ISF';
(actor actor_static_library_use_params
  (params
    (MODE_PARAM 1)
    (IDLE_PARAM 0)
    (MODE_PAIR (1 0)))
  (constants
    (BUSY_CONST 1)
    (IDLE_CONST 0))
  (clock clk)
  (reset rst)
  (interface
    (input trigger)
    (output fired))
  (imports
    (library common.pulse as pulse_lib))
  (use pulse_lib.pulse_actor as rx
    (params
      (MODE MODE_PARAM)
      (MODES (BUSY_CONST IDLE_PARAM)))
    (bind
      (clock clk)
      (reset rst)
      (input trigger trigger)
      (output fired fired))))
ISF

    my $actor = FSM::Adapter::ISF->new()->parse_source($source, 'actor-static-library-use-params.isf');
    is_deeply(
        $actor->{library_uses}[0]{parameter_overrides},
        [
            { name => 'MODE', value => '1' },
            { name => 'MODES', value => [ '1', '0' ] },
        ],
        'parser resolves actor static use-site overrides before publishing library use metadata',
    );

    my $scheduler = FSM::Scheduler::ISF->new();
    my $lowered = $scheduler->lower($actor);
    my $top_fsm = $lowered->{files}{'actor_static_library_use_params_top.fsm'};
    like(
        $top_fsm,
        qr/\(\?fsmc:rx actor_static_library_use_params__rx\s+\(params\s+\(MODE 1\)\s+\(MODES \(1 0\)\)\s+\)\s+\)/s,
        'generated top applies resolved actor static use-site overrides',
    );
    my ($rx_fsmc_block) = $top_fsm =~ /(\(\?fsmc:rx\b[\s\S]*?\n  \))/;
    unlike(
        $rx_fsmc_block // '',
        qr/MODE_PARAM|BUSY_CONST|IDLE_PARAM/,
        'generated top instance parameter block does not leak actor static tokens in use-site overrides',
    );
    like(
        $lowered->{files}{'actor_static_library_use_params__rx.fsm'},
        qr/\(\+params[\s\S]*\(MODE 0\)[\s\S]*\(MODES \(0 0\)\)/,
        'library child artifact still preserves exported actor parameter defaults',
    );

    my $report = decode_json($scheduler->report($actor));
    my %params = map { $_->{name} => $_ } @{$report->{library_uses}[0]{parameters}};
    is($params{MODE}{source}, 'override', 'report marks scalar actor static use-site parameter as override');
    is($params{MODE}{value}, '1', 'report exposes resolved scalar actor static use-site value');
    is($params{MODES}{source}, 'override', 'report marks aggregate actor static use-site parameter as override');
    is($params{MODES}{value}, '(1 0)', 'report exposes resolved aggregate actor static use-site leaves');

    my $dir = tempdir(CLEANUP => 1);
    my $isf_path = File::Spec->catfile($dir, 'actor_static_library_use_params.isf');
    write_file($isf_path, $source);
    my $hdl_path = File::Spec->catfile($dir, 'actor_static_library_use_params.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--strict', '--outdir', $dir, '--output', $hdl_path, $isf_path],
    );
    ok($success, 'CLI HDL generation succeeds for actor static library use-site overrides');
    is(join('', @{$stderr_buf || []}), '', 'CLI keeps stderr clean for actor static library use-site overrides');
    ok(-s $hdl_path, 'CLI writes HDL for actor static library use-site overrides');
};

subtest 'library use-site enum diagnostics stay explicit' => sub {
    assert_parse_rejected(
        library_source() . <<'ISF',
(actor unknown_enum_library_use_param
  (enums
    (mode (IDLE 0)))
  (clock clk)
  (reset rst)
  (interface
    (input trigger)
    (output fired))
  (imports
    (library common.pulse as pulse_lib))
  (use pulse_lib.pulse_actor as rx
    (params
      (MODE mode.BUSY))
    (bind
      (clock clk)
      (reset rst)
      (input trigger trigger)
      (output fired fired))))
ISF
        qr/actor 'unknown_enum_library_use_param' use 'rx' parameter 'MODE' references unknown enum member 'mode\.BUSY'/,
        'unknown use-site enum member fails before lowering',
    );

    assert_parse_rejected(
        library_source() . <<'ISF',
(actor symbolic_library_use_param
  (clock clk)
  (reset rst)
  (interface
    (input trigger)
    (output fired))
  (imports
    (library common.pulse as pulse_lib))
  (use pulse_lib.pulse_actor as rx
    (params
      (MODE TOP_WIDTH))
    (bind
      (clock clk)
      (reset rst)
      (input trigger trigger)
      (output fired fired))))
ISF
        qr/use 'rx' parameter 'MODE' uses unsupported parameter value 'TOP_WIDTH'; reusable-library use-site parameter overrides accept numeric, exact-width, actor-constant, actor scalar parameter, enum member, and aggregate\/list literal values only/,
        'unknown symbolic use-site overrides remain rejected',
    );

    assert_parse_rejected(
        library_source() . <<'ISF',
(actor runtime_signal_library_use_param
  (clock clk)
  (reset rst)
  (interface
    (input trigger)
    (output fired))
  (imports
    (library common.pulse as pulse_lib))
  (use pulse_lib.pulse_actor as rx
    (params
      (MODE trigger))
    (bind
      (clock clk)
      (reset rst)
      (input trigger trigger)
      (output fired fired))))
ISF
        qr/use 'rx' parameter 'MODE' value 'trigger' is a runtime interface signal; reusable-library use-site parameter overrides accept static literals, actor constants, actor scalar parameters, enum members, and aggregate\/list literals only/,
        'runtime signal-looking use-site overrides remain rejected',
    );

    assert_parse_rejected(
        library_source() . <<'ISF',
(actor nonscalar_actor_param_library_use_param
  (params
    (MODE_PAIR (1 0)))
  (clock clk)
  (reset rst)
  (interface
    (input trigger)
    (output fired))
  (imports
    (library common.pulse as pulse_lib))
  (use pulse_lib.pulse_actor as rx
    (params
      (MODE MODE_PAIR))
    (bind
      (clock clk)
      (reset rst)
      (input trigger trigger)
      (output fired fired))))
ISF
        qr/use 'rx' parameter 'MODE' actor parameter 'MODE_PAIR' must resolve to a scalar numeric or exact-width literal/,
        'non-scalar actor parameters remain rejected as scalar use-site overrides',
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

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "open $path: $!";
    print {$fh} $content;
    close $fh or die "close $path: $!";
    return $path;
}

sub assert_parse_rejected {
    my ($source, $regex, $label) = @_;
    my $ok = eval {
        FSM::Adapter::ISF->new()->parse_source($source, "$label.isf");
        1;
    };
    ok(!$ok, "$label is rejected");
    like($@, $regex, "$label diagnostic");
}
