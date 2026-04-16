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
use FSM::Pipeline::HDLGenerator;
use FSM::Pipeline::SourceFrontend;

my $tempdir = tempdir(CLEANUP => 1);
my $canonical_dt_path = File::Spec->catfile($tempdir, 'strict_dt_ok.fsm');
my $canonical_dt_out_path = File::Spec->catfile($tempdir, 'strict_dt_ok.sv');
my $mod_path = File::Spec->catfile($tempdir, 'strict_mod_root.fsm');
my $mod_out_path = File::Spec->catfile($tempdir, 'strict_mod_root.sv');
my $module_path = File::Spec->catfile($tempdir, 'strict_module_root.fsm');
my $module_out_path = File::Spec->catfile($tempdir, 'strict_module_root.sv');
my $embedded_top_path = File::Spec->catfile($tempdir, 'strict_embedded_mod_root_top.fsm');
my $embedded_top_out_path = File::Spec->catfile($tempdir, 'strict_embedded_mod_root_top.sv');
my $external_top_path = File::Spec->catfile($tempdir, 'strict_external_module_root_top.fsm');
my $external_top_out_path = File::Spec->catfile($tempdir, 'strict_external_module_root_top.sv');

write_file(
    $canonical_dt_path,
    <<'FSM'
(?dt:strict_dt_ok
  (+size
    (DATA_IN 8)
    (DATA_OUT 8)
  )
  (-route
    (= (DATA_OUT DATA_IN))
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
    (= (DATA_OUT DATA_IN))
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

subtest 'default mode still accepts top-level ?module roots as compatibility aliases' => sub {
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug_level => 0,
        quiet => 1,
    );

    my $result = $pipeline->generate_hdl_from_file($module_path);

    like(
        $result->{hdl_code},
        qr/\bmodule\s+strict_module_root\b/s,
        'default-mode pipeline still compiles top-level ?module roots',
    );
};

subtest 'strict mode still accepts top-level ?mod roots' => sub {
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug_level => 0,
        quiet => 1,
        strict_mode => 1,
    );

    my $result = $pipeline->generate_hdl_from_file($mod_path);

    like(
        $result->{hdl_code},
        qr/\bmodule\s+strict_mod_root\b/s,
        'strict pipeline still compiles top-level ?mod roots',
    );
};

subtest 'shared frontend strict boundary rejects top-level ?module roots explicitly' => sub {
    my $raw_ast = Lispish::multi($module_path);

    my $error = eval {
        FSM::Pipeline::SourceFrontend->enforce_strict_source_boundary(
            raw_ast => $raw_ast,
            strict_mode => 1,
            source_label => $module_path,
        );
        undef;
    };
    $error = $@ if !$error;

    like(
        $error,
        qr/Strict mode rejects the legacy '\?module:' direct-root alias for source '\Q$module_path\E'.*Use the canonical '\?mod:module_name' root form/s,
        'shared frontend surfaces the canonical ?mod migration hint for top-level ?module roots',
    );
};

subtest 'CLI strict mode still accepts top-level ?dt and ?mod roots' => sub {
    my ($mod_success, $mod_error_message, $mod_full_buf, $mod_stdout_buf, $mod_stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--quiet', '-o', $mod_out_path, $mod_path],
    );

    ok($mod_success, 'CLI strict mode still accepts top-level ?mod roots');
    ok(-e $mod_out_path, 'CLI strict mode still emits HDL for top-level ?mod roots');

    my ($dt_success, $dt_error_message, $dt_full_buf, $dt_stdout_buf, $dt_stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--quiet', '-o', $canonical_dt_out_path, $canonical_dt_path],
    );

    ok($dt_success, 'CLI strict mode still accepts canonical ?dt roots');
    ok(-e $canonical_dt_out_path, 'CLI strict mode still emits HDL for canonical ?dt roots');
};

subtest 'strict pipeline and CLI reject top-level ?module roots' => sub {
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug_level => 0,
        quiet => 1,
        strict_mode => 1,
    );

    my $pipeline_error = eval {
        $pipeline->generate_hdl_from_file($module_path);
        undef;
    };
    $pipeline_error = $@ if !$pipeline_error;

    like(
        $pipeline_error,
        qr/Source file:\s+'\Q$module_path\E'.*Strict mode rejects the legacy '\?module:' direct-root alias.*Use the canonical '\?mod:module_name' root form/s,
        'strict pipeline keeps source-file context around the top-level ?module alias boundary',
    );

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--quiet', '-o', $module_out_path, $module_path],
    );

    ok(!$success, 'CLI strict mode rejects top-level ?module roots');
    ok(!-e $module_out_path, 'CLI strict mode does not emit HDL for top-level ?module roots');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like(
        $combined_output,
        qr/Source file:\s+'\Q$module_path\E'.*Strict mode rejects the legacy '\?module:' direct-root alias.*Use the canonical '\?mod:module_name' root form/s,
        'CLI strict mode surfaces the same canonical ?mod migration hint for top-level ?module roots',
    );
};

subtest 'strict mode rejects ?dtc children rooted at ?mod and ?module' => sub {
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug_level => 0,
        quiet => 1,
        strict_mode => 1,
        source_search_paths => [$libdir],
    );

    my $embedded_exception = eval {
        $pipeline->generate_hdl_from_file($embedded_top_path);
        undef;
    };
    $embedded_exception = $@;

    like(
        $embedded_exception,
        qr/Source file:\s+'\Q$embedded_top_path\E'.*Generated child source:\s+'\?dtc' 'route_src'.*Strict mode rejects '\?mod:route_src' as the root of '\?dtc' source 'route_src'.*Use the canonical '\?dt:source_name' root form/s,
        'strict mode rejects embedded ?mod dtc children with the canonical ?dt migration hint',
    );

    my $external_exception = eval {
        $pipeline->generate_hdl_from_file($external_top_path);
        undef;
    };
    $external_exception = $@;

    like(
        $external_exception,
        qr/Source file:\s+'\Q$external_child_path\E'.*Parent composition source:\s+'\Q$external_top_path\E'.*Generated child source:\s+'\?dtc' 'route_src'.*Strict mode rejects '\?module:route_src' as the root of '\?dtc' source 'route_src'.*Use the canonical '\?dt:source_name' root form/s,
        'strict mode rejects external ?module dtc children with full child-source context and the canonical ?dt migration hint',
    );
};

subtest 'CLI strict mode also rejects ?dtc children rooted at ?mod and ?module' => sub {
    my ($embedded_success, $embedded_error_message, $embedded_full_buf, $embedded_stdout_buf, $embedded_stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--quiet', '-o', $embedded_top_out_path, $embedded_top_path],
    );

    ok(!$embedded_success, 'CLI strict mode rejects embedded ?mod dtc children');
    ok(!-e $embedded_top_out_path, 'CLI strict mode does not emit HDL for embedded ?mod dtc children');

    my $embedded_output = join(
        '',
        @{ $embedded_stdout_buf || [] },
        @{ $embedded_stderr_buf || [] },
        ($embedded_error_message || ''),
    );

    like(
        $embedded_output,
        qr/Source file:\s+'\Q$embedded_top_path\E'.*Generated child source:\s+'\?dtc' 'route_src'.*Strict mode rejects '\?mod:route_src' as the root of '\?dtc' source 'route_src'.*Use the canonical '\?dt:source_name' root form/s,
        'CLI strict mode surfaces the canonical ?dt migration hint for embedded ?mod dtc children',
    );

    my ($external_success, $external_error_message, $external_full_buf, $external_stdout_buf, $external_stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--quiet', '--path', $libdir, '-o', $external_top_out_path, $external_top_path],
    );

    ok(!$external_success, 'CLI strict mode rejects external ?module dtc children');
    ok(!-e $external_top_out_path, 'CLI strict mode does not emit HDL for external ?module dtc children');

    my $external_output = join(
        '',
        @{ $external_stdout_buf || [] },
        @{ $external_stderr_buf || [] },
        ($external_error_message || ''),
    );

    like(
        $external_output,
        qr/Source file:\s+'\Q$external_child_path\E'.*Parent composition source:\s+'\Q$external_top_path\E'.*Generated child source:\s+'\?dtc' 'route_src'.*Strict mode rejects '\?module:route_src' as the root of '\?dtc' source 'route_src'.*Use the canonical '\?dt:source_name' root form/s,
        'CLI strict mode surfaces the canonical ?dt migration hint for external ?module dtc children',
    );
};

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
