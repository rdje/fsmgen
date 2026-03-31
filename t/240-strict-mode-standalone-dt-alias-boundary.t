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
my $mod_alias_path = File::Spec->catfile($tempdir, 'strict_mod_alias.fsm');
my $mod_alias_out_path = File::Spec->catfile($tempdir, 'strict_mod_alias.sv');
my $module_alias_path = File::Spec->catfile($tempdir, 'strict_module_alias.fsm');
my $module_alias_out_path = File::Spec->catfile($tempdir, 'strict_module_alias.sv');
my $embedded_top_path = File::Spec->catfile($tempdir, 'strict_embedded_mod_alias_top.fsm');
my $external_top_path = File::Spec->catfile($tempdir, 'strict_external_module_alias_top.fsm');

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
    $mod_alias_path,
    <<'FSM'
(?mod:strict_mod_alias
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
    $module_alias_path,
    <<'FSM'
(?module:strict_module_alias
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

subtest 'strict mode rejects top-level ?mod and ?module aliases with migration guidance' => sub {
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug_level => 0,
        quiet => 1,
        strict_mode => 1,
    );

    for my $case (
        [$mod_alias_path, qr/\?mod:strict_mod_alias/, 'top-level ?mod alias'],
        [$module_alias_path, qr/\?module:strict_module_alias/, 'top-level ?module alias'],
    ) {
        my ($path, $header_regex, $label) = @$case;
        my $error = eval {
            $pipeline->generate_hdl_from_file($path);
            undef;
        };
        $error = $@;

        like(
            $error,
            qr/Strict mode rejects the legacy standalone-DT root alias/s,
            "strict pipeline rejects $label explicitly",
        );
        like(
            $error,
            $header_regex,
            "strict pipeline names the rejected alias for $label",
        );
        like(
            $error,
            qr/\?dt:module_name/,
            "strict pipeline gives the canonical ?dt migration hint for $label",
        );
    }
};

subtest 'CLI strict mode rejects top-level ?mod and ?module aliases too' => sub {
    my ($mod_success, $mod_error_message, $mod_full_buf, $mod_stdout_buf, $mod_stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--quiet', '-o', $mod_alias_out_path, $mod_alias_path],
    );

    ok(!$mod_success, 'CLI strict mode rejects top-level ?mod alias');
    ok(!-e $mod_alias_out_path, 'CLI strict mode does not emit HDL for top-level ?mod alias');

    my $mod_output = join('', @{ $mod_stdout_buf || [] }, @{ $mod_stderr_buf || [] }, ($mod_error_message || ''));
    like($mod_output, qr/Strict mode rejects the legacy standalone-DT root alias '\?mod:strict_mod_alias'/, 'CLI surfaces the strict ?mod-alias boundary');
    like($mod_output, qr/\?dt:module_name/, 'CLI gives the canonical ?dt migration hint for ?mod');

    my ($module_success, $module_error_message, $module_full_buf, $module_stdout_buf, $module_stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--quiet', '-o', $module_alias_out_path, $module_alias_path],
    );

    ok(!$module_success, 'CLI strict mode rejects top-level ?module alias');
    ok(!-e $module_alias_out_path, 'CLI strict mode does not emit HDL for top-level ?module alias');

    my $module_output = join('', @{ $module_stdout_buf || [] }, @{ $module_stderr_buf || [] }, ($module_error_message || ''));
    like($module_output, qr/Strict mode rejects the legacy standalone-DT root alias '\?module:strict_module_alias'/, 'CLI surfaces the strict ?module-alias boundary');
    like($module_output, qr/\?dt:module_name/, 'CLI gives the canonical ?dt migration hint for ?module');

    my ($dt_success, $dt_error_message, $dt_full_buf, $dt_stdout_buf, $dt_stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--quiet', '-o', $canonical_dt_out_path, $canonical_dt_path],
    );

    ok($dt_success, 'CLI strict mode still accepts canonical ?dt roots');
    ok(-e $canonical_dt_out_path, 'CLI strict mode still emits HDL for canonical ?dt roots');
};

subtest 'strict mode also rejects legacy standalone-DT aliases inside dtc child realization' => sub {
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug_level => 0,
        quiet => 1,
        strict_mode => 1,
        source_search_paths => [$libdir],
    );

    my $embedded_error = eval {
        $pipeline->generate_hdl_from_file($embedded_top_path);
        undef;
    };
    $embedded_error = $@;
    like(
        $embedded_error,
        qr/Strict mode rejects the legacy standalone-DT root alias '\?mod:route_src'/,
        'strict mode rejects embedded ?mod dtc children too',
    );

    my $external_error = eval {
        $pipeline->generate_hdl_from_file($external_top_path);
        undef;
    };
    $external_error = $@;
    like(
        $external_error,
        qr/Strict mode rejects the legacy standalone-DT root alias '\?module:route_src'/,
        'strict mode rejects external ?module dtc children too',
    );
};

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
