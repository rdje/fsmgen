#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use JSON::PP qw(decode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Support::ISFPublicInterfaceContract qw(
    isf_public_interface_schedule_report_library_use_binding_keys
    isf_public_interface_schedule_report_library_use_keys
    isf_public_interface_schedule_report_library_use_parameter_keys
);

subtest 'actor imports external library actor and emits scheduled child artifact' => sub {
    my $dir = tempdir(CLEANUP => 1);
    write_library($dir);
    my $top = write_top($dir, <<'ISF');
(actor library_top
  (clock clk)
  (interface
    (input trigger)
    (output fired))
  (imports
    (library common.pulse as pulse_lib))
  (use pulse_lib.pulse_actor as rx
    (params
      (WIDTH 4))
    (bind
      (clock clk)
      (input trigger trigger)
      (output fired fired))))
ISF

    my $actor = FSM::Adapter::ISF->new()->parse_file($top);
    is(scalar(@{$actor->{library_uses}}), 1, 'parser resolves one library use');

    my $use = $actor->{library_uses}[0];
    is($use->{library}, 'common.pulse', 'resolved use records library namespace');
    is($use->{export}, 'pulse_actor', 'resolved use records actor export');
    is($use->{instance}, 'rx', 'resolved use records authored instance');
    is($use->{module}, 'library_top__rx', 'resolved use records deterministic generated module');

    my $lowered = FSM::Scheduler::ISF->new()->lower($actor);
    ok(exists $lowered->{files}{'library_top.fsm'}, 'parent scheduled .fsm is emitted');
    ok(exists $lowered->{files}{'library_top__rx.fsm'}, 'library actor scheduled .fsm is emitted');
    like(
        $lowered->{files}{'library_top__rx.fsm'},
        qr/\A\(\?fsm:library_top__rx\b/,
        'library actor artifact uses the specialized module name',
    );
    like(
        $lowered->{files}{'library_top__rx.fsm'},
        qr/\(\+params\s+\(WIDTH 1\)\s+\)/s,
        'library actor artifact preserves exported actor parameter defaults',
    );

    my $report = decode_json(FSM::Scheduler::ISF->new()->report($actor));
    is_deeply(
        [sort keys %{$report->{library_uses}[0]}],
        sorted(isf_public_interface_schedule_report_library_use_keys()),
        'library use summary exposes the advertised keys',
    );
    is_deeply(
        [sort keys %{$report->{library_uses}[0]{parameters}[0]}],
        sorted(isf_public_interface_schedule_report_library_use_parameter_keys()),
        'library use parameter summary exposes the advertised keys',
    );
    for my $binding (@{$report->{library_uses}[0]{bindings}}) {
        is_deeply(
            [sort keys %$binding],
            sorted(isf_public_interface_schedule_report_library_use_binding_keys()),
            "library use binding '$binding->{role}' exposes the advertised keys",
        );
    }
    is($report->{library_uses}[0]{parameters}[0]{source}, 'override', 'report marks overridden parameter source');
    is($report->{library_uses}[0]{parameters}[0]{value}, '4', 'report records overridden parameter value');
};

subtest 'library import resolution fails closed for missing and malformed use cases' => sub {
    my $dir = tempdir(CLEANUP => 1);
    write_library($dir);

    my $missing_library = write_top($dir, <<'ISF');
(actor missing_library
  (clock clk)
  (interface (input trigger) (output fired))
  (imports (library missing.lib as missing))
  (use missing.pulse_actor as rx
    (bind
      (clock clk)
      (input trigger trigger)
      (output fired fired))))
ISF
    assert_parse_rejected($missing_library, qr/library 'missing.lib' not found/, 'missing library is rejected');

    my $unknown_export = write_top($dir, <<'ISF');
(actor unknown_export
  (clock clk)
  (interface (input trigger) (output fired))
  (imports (library common.pulse as pulse_lib))
  (use pulse_lib.not_exported as rx
    (bind
      (clock clk)
      (input trigger trigger)
      (output fired fired))))
ISF
    assert_parse_rejected($unknown_export, qr/references missing actor export 'not_exported'/, 'unknown actor export is rejected');

    my $unknown_parameter = write_top($dir, <<'ISF');
(actor unknown_parameter
  (clock clk)
  (interface (input trigger) (output fired))
  (imports (library common.pulse as pulse_lib))
  (use pulse_lib.pulse_actor as rx
    (params (MODE 1))
    (bind
      (clock clk)
      (input trigger trigger)
      (output fired fired))))
ISF
    assert_parse_rejected($unknown_parameter, qr/overrides unknown parameter 'MODE'/, 'unknown parameter override is rejected');

    my $missing_binding = write_top($dir, <<'ISF');
(actor missing_binding
  (clock clk)
  (interface (input trigger) (output fired))
  (imports (library common.pulse as pulse_lib))
  (use pulse_lib.pulse_actor as rx
    (bind
      (clock clk)
      (input trigger trigger))))
ISF
    assert_parse_rejected($missing_binding, qr/does not bind library port 'fired'/, 'missing interface binding is rejected');

    my $width_mismatch = write_top($dir, <<'ISF');
(actor width_mismatch
  (clock clk)
  (interface (input trigger) (output fired))
  (imports (library common.pulse as pulse_lib))
  (use pulse_lib.wide_actor as rx
    (bind
      (clock clk)
      (input trigger trigger)
      (output fired fired))))
ISF
    assert_parse_rejected($width_mismatch, qr/width 2 does not match parent 'fired' width 1/, 'width mismatch is rejected');
};

done_testing();

sub write_library {
    my ($dir) = @_;
    my $lib_dir = File::Spec->catdir($dir, 'common');
    make_path($lib_dir);
    my $path = File::Spec->catfile($lib_dir, 'pulse.isf');
    write_file($path, <<'ISF');
(library common.pulse
  (exports
    (actor pulse_actor)
    (actor wide_actor))
  (actor pulse_actor
    (params
      (WIDTH 1))
    (clock clk)
    (interface
      (input trigger)
      (output fired))
    (transaction main
      (on trigger)
      (complete fired)))
  (actor wide_actor
    (clock clk)
    (interface
      (input trigger)
      (output fired (width 2)))
    (transaction main
      (on trigger)
      (complete fired))))
ISF
    return $path;
}

sub write_top {
    my ($dir, $source) = @_;
    my $path = File::Spec->catfile($dir, 'top.isf');
    write_file($path, $source);
    return $path;
}

sub write_file {
    my ($path, $source) = @_;
    open my $fh, '>', $path or die "cannot write $path: $!";
    print {$fh} $source;
    close $fh or die "cannot close $path: $!";
}

sub assert_parse_rejected {
    my ($path, $diagnostic_re, $label) = @_;
    my $ok = eval {
        FSM::Adapter::ISF->new()->parse_file($path);
        1;
    };
    my $diagnostic = $@;
    ok(!$ok, "$label");
    like($diagnostic, $diagnostic_re, "$label diagnostic");
}

sub sorted {
    my ($items) = @_;
    return [sort @$items];
}
