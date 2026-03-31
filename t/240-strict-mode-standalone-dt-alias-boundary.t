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

my $tempdir = tempdir(CLEANUP => 1);
my $canonical_dt_path = File::Spec->catfile($tempdir, 'strict_dt_ok.fsm');
my $canonical_dt_out_path = File::Spec->catfile($tempdir, 'strict_dt_ok.sv');
my $mod_path = File::Spec->catfile($tempdir, 'strict_mod_root.fsm');
my $mod_out_path = File::Spec->catfile($tempdir, 'strict_mod_root.sv');
my $module_path = File::Spec->catfile($tempdir, 'strict_module_root.fsm');
my $module_out_path = File::Spec->catfile($tempdir, 'strict_module_root.sv');
my $embedded_top_path = File::Spec->catfile($tempdir, 'strict_embedded_mod_root_top.fsm');
my $external_top_path = File::Spec->catfile($tempdir, 'strict_external_module_root_top.fsm');

write_file(
    $canonical_dt_path,
    <<'FSM'
(?dt:strict_dt_ok
  (+size
    (DATA_IN 8)
    (DATA_OUT 8)
  )
  (-route
    (DATA_OUT = DATA_IN)
  )
)
FSM
);

write_file(
    $mod_path,
    <<'FSM'
(?mod:strict_mod_root
  (+size
    (DATA_IN 8)
    (DATA_OUT 8)
  )
  (-route
    (DATA_OUT = DATA_IN)
  )
)
FSM
);

write_file(
    $module_path,
    <<'FSM'
(?module:strict_module_root
  (+size
    (ACC 8)
    (DATA_IN 8)
  )
  (:= ACC=8'0)
  (-accumulate
    (ACC <- DATA_IN)
  )
)
FSM
);

write_file(
    $embedded_top_path,
    <<'FSM'
(?top:strict_embedded_mod_alias_top
  (?ports:public_io
    data_in<8
    result_data>8
  )
  (?dtc:router route_src)
)

(?mod:route_src
  (+size
    (data_in 8)
    (result_data 8)
  )
  (-route
    (result_data> = data_in)
  )
)
FSM
);

my $libdir = File::Spec->catdir($tempdir, 'strict_module_alias_lib');
mkdir $libdir or die "Cannot create $libdir: $!";
my $external_child_path = File::Spec->catfile($libdir, 'route_src.fsm');
write_file(
    $external_child_path,
    <<'FSM'
(?module:route_src
  (+size
    (data_in 8)
    (result_data 8)
  )
  (-route
    (result_data> = data_in)
  )
)
FSM
);

write_file(
    $external_top_path,
    <<'FSM'
(?top:strict_external_module_alias_top
  (?ports:public_io
    data_in<8
    result_data>8
  )
  (?dtc:router route_src)
)
FSM
);

subtest 'strict mode still accepts the canonical ?dt root family' => sub {
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug_level => 0,
        quiet => 1,
        strict_mode => 1,
    );
    my $result = $pipeline->generate_hdl_from_file($canonical_dt_path);

    like(
        $result->{hdl_code},
        qr/\bmodule\s+strict_dt_ok\b/s,
        'strict mode still compiles canonical ?dt roots',
    );
};

subtest 'strict mode also accepts top-level ?mod and ?module roots' => sub {
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug_level => 0,
        quiet => 1,
        strict_mode => 1,
    );

    for my $case (
        [$mod_path, qr/\bmodule\s+strict_mod_root\b/s, 'top-level ?mod root'],
        [$module_path, qr/\bmodule\s+strict_module_root\b/s, 'top-level ?module root'],
    ) {
        my ($path, $module_regex, $label) = @$case;
        my $result = $pipeline->generate_hdl_from_file($path);

        like(
            $result->{hdl_code},
            $module_regex,
            "strict pipeline still compiles $label",
        );
    }
};

subtest 'CLI strict mode also accepts top-level ?dt, ?mod, and ?module roots' => sub {
    my ($mod_success, $mod_error_message, $mod_full_buf, $mod_stdout_buf, $mod_stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--quiet', '-o', $mod_out_path, $mod_path],
    );

    ok($mod_success, 'CLI strict mode still accepts top-level ?mod roots');
    ok(-e $mod_out_path, 'CLI strict mode still emits HDL for top-level ?mod roots');

    my ($module_success, $module_error_message, $module_full_buf, $module_stdout_buf, $module_stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--quiet', '-o', $module_out_path, $module_path],
    );

    ok($module_success, 'CLI strict mode still accepts top-level ?module roots');
    ok(-e $module_out_path, 'CLI strict mode still emits HDL for top-level ?module roots');

    my ($dt_success, $dt_error_message, $dt_full_buf, $dt_stdout_buf, $dt_stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--quiet', '-o', $canonical_dt_out_path, $canonical_dt_path],
    );

    ok($dt_success, 'CLI strict mode still accepts canonical ?dt roots');
    ok(-e $canonical_dt_out_path, 'CLI strict mode still emits HDL for canonical ?dt roots');
};

subtest 'strict mode still realizes embedded and external ?dtc children rooted at ?mod and ?module' => sub {
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug_level => 0,
        quiet => 1,
        strict_mode => 1,
        source_search_paths => [$libdir],
    );

    my $embedded_result = $pipeline->generate_hdl_from_file($embedded_top_path);
    like(
        $embedded_result->{hdl_code},
        qr/\bmodule\s+route_src\b/s,
        'strict mode still realizes embedded ?mod dtc children',
    );

    my $external_result = $pipeline->generate_hdl_from_file($external_top_path);
    like(
        $external_result->{hdl_code},
        qr/\bmodule\s+route_src\b/s,
        'strict mode still realizes external ?module dtc children',
    );
};

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
