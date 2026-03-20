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
use FSM::SourceClassifier;

my $tempdir = tempdir(CLEANUP => 1);

subtest '?mod root aliases the standalone-DT source family directly' => sub {
    my $source_path = write_file(
        'mod_alias_root.fsm',
        <<'FSM'
(?mod:mod_alias_root
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

    my $raw_ast = Lispish::multi($source_path);
    my $source_info = FSM::SourceClassifier::classify_source_ast($raw_ast);
    is($source_info->{kind}, 'dt', '?mod root is classified as a dt source');
    is($source_info->{header}, '?mod:mod_alias_root', 'classifier preserves the ?mod header');

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug_level => 0,
        quiet => 1,
    );
    my $result = $pipeline->generate_hdl_from_file($source_path);

    is($result->{source_info}{kind}, 'dt', 'pipeline preserves dt source kind for ?mod roots');
    is($result->{fsm_module}->source_root_kind, 'dt', '?mod root keeps the dt source_root_kind');
    like($result->{hdl_code}, qr/\bmodule\s+mod_alias_root\b/s, '?mod root still generates the expected module');
    unlike($result->{hdl_code}, qr/\binput\s+wire\s+clk\b/s, 'combinational ?mod root keeps the honest non-system interface');
};

subtest '?module root can be compiled directly through the CLI bare-name lookup path' => sub {
    my $libdir = File::Spec->catdir($tempdir, 'module_alias_lib');
    mkdir $libdir or die "Cannot create $libdir: $!";

    my $source_path = File::Spec->catfile($libdir, 'module_alias_root.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'module_alias_root.sv');

    write_raw_file(
        $source_path,
        <<'FSM'
(?module:module_alias_root
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

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--path', $libdir, '-o', $output_path, 'module_alias_root'],
    );

    ok($success, 'CLI compiles a bare source whose root is ?module:name');
    ok(-e $output_path, 'CLI writes HDL for the ?module alias root');

    my $hdl = slurp($output_path);
    like($hdl, qr/\bmodule\s+module_alias_root\b/s, '?module root generates the expected module name');
    like($hdl, qr/\binput\s+wire\s+clk\b/s, 'sequential ?module root still exposes implicit clk');
    like($hdl, qr/\binput\s+wire\s+rst_n\b/s, 'sequential ?module root still exposes implicit rst_n');
};

subtest 'composition dtc children can realize embedded ?mod and external ?module roots' => sub {
    my $libdir = File::Spec->catdir($tempdir, 'composition_dt_alias_lib');
    mkdir $libdir or die "Cannot create $libdir: $!";

    my $embedded_path = write_file(
        'embedded_mod_alias_top.fsm',
        <<'FSM'
(?top:embedded_mod_alias_top
  (?ports:public_io
    data_in<8
    result_data>8
  )
  (?dtc:router route_src)
)

(?mod:route_src
  (-route
    (result_data> = data_in)
  )
  (+size
    (data_in 8)
    (result_data 8)
  )
)
FSM
    );

    my $external_path = File::Spec->catfile($libdir, 'route_src.fsm');
    write_raw_file(
        $external_path,
        <<'FSM'
(?module:route_src
  (-route
    (result_data> = data_in)
  )
  (+size
    (data_in 8)
    (result_data 8)
  )
)
FSM
    );

    my $external_top_path = write_file(
        'external_module_alias_top.fsm',
        <<'FSM'
(?top:external_module_alias_top
  (?ports:public_io
    data_in<8
    result_data>8
  )
  (?dtc:router route_src)
)
FSM
    );

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug_level => 0,
        quiet => 1,
        source_search_paths => [$libdir],
    );

    my $embedded_result = $pipeline->generate_hdl_from_file($embedded_path);
    is($embedded_result->{composition_plan}->lane, 'C1', 'embedded ?mod dt child uses the single-child passthrough lane');
    is($embedded_result->{composition_plan}->instances->[0]->kind, 'dtc', 'embedded ?mod child is realized as a dtc child');
    like($embedded_result->{hdl_code}, qr/\bmodule\s+route_src\b/s, 'embedded ?mod dt child module is emitted');

    my $external_result = $pipeline->generate_hdl_from_file($external_top_path);
    is($external_result->{composition_plan}->lane, 'C1', 'external ?module dt child also uses the single-child passthrough lane');
    is($external_result->{composition_plan}->instances->[0]->kind, 'dtc', 'external ?module child is realized as a dtc child');
    like($external_result->{hdl_code}, qr/\bmodule\s+route_src\b/s, 'external ?module dt child module is emitted');
};

done_testing();

sub write_file {
    my ($filename, $content) = @_;
    my $path = File::Spec->catfile($tempdir, $filename);
    write_raw_file($path, $content);
    return $path;
}

sub write_raw_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}

sub slurp {
    my ($path) = @_;
    open my $fh, '<', $path or die "Cannot open $path: $!";
    local $/ = undef;
    my $content = <$fh>;
    close $fh or die "Cannot close $path: $!";
    return $content;
}
