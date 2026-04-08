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

subtest 'direct-root +types drive +size widths regardless of declaration order and across imported packages' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $libdir = File::Spec->catdir($tempdir, 'pkg_lib');
    mkdir $libdir or die "Cannot create $libdir: $!";

    my $fsm_path = File::Spec->catfile($tempdir, 'typed_direct_root.fsm');
    my $package_path = File::Spec->catfile($libdir, 'shared_types.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'typed_direct_root.sv');

    write_file(
        $package_path,
        <<'FSM'
(?pkg:shared_types
  (+types
    (type byte (bits 8))
  )
)
FSM
    );

    write_file(
        $fsm_path,
        <<'FSM'
(?fsm:typed_direct_root
  (+import shared_types)
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+size
    (OUT byte_t)
    (FLAG bit_t)
  )
  (+types
    (type bit_t bit)
    (type byte_t shared_types.byte)
  )
  (idle
    (OUT = 8'hA5)
    (FLAG = 1)
  )
)
FSM
    );

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        quiet => 1,
        target_language => 'systemverilog',
        source_search_paths => [$libdir],
    );
    my $result = $pipeline->generate_hdl_from_file($fsm_path);
    my $hdl = $result->{hdl_code};
    my $symbol_contract = $result->{intent_hir}{symbol_contract};

    is($symbol_contract->{type_count}, 2, 'direct symbol contract counts declared local types');
    is_deeply($symbol_contract->{type_names}, ['bit_t', 'byte_t'], 'direct symbol contract preserves stable local type names');
    is($symbol_contract->{types}{bit_t}{width}, 1, 'direct symbol contract preserves bit alias width');
    is($symbol_contract->{types}{byte_t}{width}, 8, 'direct symbol contract preserves imported alias width');

    like($hdl, qr/reg\s+\[7:0\]\s+OUT\b/s, 'generated HDL uses imported scalar type alias width on OUT');
    like($hdl, qr/reg\s+FLAG\b/s, 'generated HDL uses local bit alias width on FLAG');

    my @cmd = ('./bin/fsmgen', '--quiet', '--path', $libdir, '--output', $output_path, $fsm_path);
    my ($success, $error_code, $full_buf, $stdout_buf, $stderr_buf) = run(command => \@cmd, verbose => 0);
    my $combined_output = join('', @{$stdout_buf || []}, @{$stderr_buf || []});
    my $output_text = slurp_file($output_path);

    ok($success, 'CLI accepts direct-root scalar type aliases');
    ok(-e $output_path, 'CLI emits HDL for direct-root scalar type aliases');
    ok(!defined($error_code) || $error_code == 0, 'CLI exits successfully for direct-root scalar type aliases');
    unlike($combined_output, qr/declarative type|named scalar type/s, 'successful direct-root type CLI run does not report type failures');
    like($output_text, qr/reg\s+\[7:0\]\s+OUT\b/s, 'CLI output preserves imported scalar type alias width');
};

subtest 'direct-root +size widths may use local and imported positive integer scalar symbols' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $libdir = File::Spec->catdir($tempdir, 'pkg_lib');
    mkdir $libdir or die "Cannot create $libdir: $!";

    my $fsm_path = File::Spec->catfile($tempdir, 'scalar_symbol_direct_root.fsm');
    my $package_path = File::Spec->catfile($libdir, 'shared_cfg.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'scalar_symbol_direct_root.sv');

    write_file(
        $package_path,
        <<'FSM'
(?pkg:shared_cfg
  (+constants
    (BYTE_W 8)
  )
)
FSM
    );

    write_file(
        $fsm_path,
        <<'FSM'
(?fsm:scalar_symbol_direct_root
  (+import shared_cfg)
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+size
    (OUT shared_cfg.BYTE_W)
    (FLAG FLAG_W)
  )
  (+constants
    (FLAG_W 1)
  )
  (idle
    (OUT = 8'hA5)
    (FLAG = 1)
  )
)
FSM
    );

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        quiet => 1,
        target_language => 'systemverilog',
        source_search_paths => [$libdir],
    );
    my $result = $pipeline->generate_hdl_from_file($fsm_path);
    my $hdl = $result->{hdl_code};

    like($hdl, qr/reg\s+\[7:0\]\s+OUT\b/s, 'generated HDL uses imported positive integer scalar symbol width on OUT');
    like($hdl, qr/reg\s+FLAG\b/s, 'generated HDL uses local positive integer scalar symbol width on FLAG');

    my @cmd = ('./bin/fsmgen', '--quiet', '--path', $libdir, '--output', $output_path, $fsm_path);
    my ($success, $error_code, $full_buf, $stdout_buf, $stderr_buf) = run(command => \@cmd, verbose => 0);
    my $combined_output = join('', @{$stdout_buf || []}, @{$stderr_buf || []});
    my $output_text = slurp_file($output_path);

    ok($success, 'CLI accepts direct-root positive integer scalar symbols on +size widths');
    ok(-e $output_path, 'CLI emits HDL for direct-root positive integer scalar symbol widths');
    ok(!defined($error_code) || $error_code == 0, 'CLI exits successfully for direct-root positive integer scalar symbol widths');
    unlike($combined_output, qr/positive integer scalar symbol|Malformed '\+size' entry/s, 'successful direct-root scalar symbol width CLI run does not report width failures');
    like($output_text, qr/reg\s+\[7:0\]\s+OUT\b/s, 'CLI output preserves imported positive integer scalar symbol width');
};

subtest 'direct-root +size rejects non-positive scalar symbol widths explicitly' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'bad_scalar_symbol_direct_root.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'bad_scalar_symbol_direct_root.sv');

    write_file(
        $fsm_path,
        <<'FSM'
(?fsm:bad_scalar_symbol_direct_root
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+size
    (OUT ZERO_W)
  )
  (+constants
    (ZERO_W 0)
  )
  (idle
    (OUT = 1)
  )
)
FSM
    );

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        quiet => 1,
        target_language => 'systemverilog',
    );

    my $pipeline_error = eval {
        $pipeline->generate_hdl_from_file($fsm_path);
        undef;
    };
    $pipeline_error = $@ if !$pipeline_error;

    like(
        $pipeline_error,
        qr/Malformed '\+size' entry for signal 'OUT'.*positive integer width, a named scalar type.*positive integer scalar symbol/s,
        'pipeline reports non-positive direct-root scalar symbol widths explicitly',
    );

    my @cmd = ('./bin/fsmgen', '--quiet', '--output', $output_path, $fsm_path);
    my ($success, $error_code, $full_buf, $stdout_buf, $stderr_buf) = run(command => \@cmd, verbose => 0);
    my $combined_output = join('', @{$stdout_buf || []}, @{$stderr_buf || []});

    ok(!$success, 'CLI rejects non-positive direct-root scalar symbol widths');
    ok(!-e $output_path, 'CLI does not emit HDL for non-positive direct-root scalar symbol widths');
    like(
        $combined_output,
        qr/Malformed '\+size' entry for signal 'OUT'.*positive integer width, a named scalar type.*positive integer scalar symbol/s,
        'CLI surfaces the non-positive direct-root scalar symbol width boundary',
    );
    isnt($error_code, 0, 'CLI exits non-zero for non-positive direct-root scalar symbol widths');
};

subtest 'composition-top +types drive local ?ports widths regardless of declaration order' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'typed_top_ports.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'typed_top_ports.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:typed_top_ports
  (?ports:public_io
    out_data>byte_t
    out_flag>flag_t
  )
  (+types
    (type flag_t bit)
    (type byte_t (bits 8))
  )
  (?rtl:uart_tx)
  (?toplink:wiring
    /uart_tx.data_out/out_data/
    /uart_tx.flag_out/out_flag/
  )
)

(?rtlif:uart_tx
  data_out>8:data
  flag_out>:data
)
FSM
    );

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        quiet => 1,
        target_language => 'systemverilog',
    );
    my $result = $pipeline->generate_hdl_from_file($composition_path);
    my $ports = $result->{composition_spec}->top->ports_blocks->[0]->ports;
    my %ports_by_name = map { $_->name => $_ } @$ports;
    my $symbol_contract = $result->{intent_hir}{symbol_contract};
    my $hdl = $result->{hdl_code};

    is($ports_by_name{out_data}->width, 8, 'composition ?ports local scalar type alias resolves to width 8');
    is($ports_by_name{out_flag}->width, 1, 'composition ?ports local bit alias resolves to width 1');
    is($symbol_contract->{type_count}, 2, 'composition symbol contract counts declared local types');
    is_deeply($symbol_contract->{type_names}, ['byte_t', 'flag_t'], 'composition symbol contract preserves stable local type names');
    is($symbol_contract->{types}{byte_t}{width}, 8, 'composition symbol contract preserves byte alias width');
    is($symbol_contract->{types}{flag_t}{width}, 1, 'composition symbol contract preserves bit alias width');
    like($hdl, qr/output\s+\[7:0\]\s+out_data\b/s, 'generated top HDL uses local scalar type alias width on out_data');
    like($hdl, qr/output\s+out_flag\b/s, 'generated top HDL uses local bit alias width on out_flag');

    my @cmd = ('./bin/fsmgen', '--quiet', '--output', $output_path, $composition_path);
    my ($success, $error_code, $full_buf, $stdout_buf, $stderr_buf) = run(command => \@cmd, verbose => 0);
    my $combined_output = join('', @{$stdout_buf || []}, @{$stderr_buf || []});

    ok($success, 'CLI accepts composition-top local scalar type aliases');
    ok(-e $output_path, 'CLI emits HDL for composition-top local scalar type aliases');
    ok(!defined($error_code) || $error_code == 0, 'CLI exits successfully for composition-top local scalar type aliases');
    unlike($combined_output, qr/declarative type|local scalar type alias/s, 'successful composition type CLI run does not report type failures');
};

subtest 'composition ?ports widths may use local and imported positive integer scalar symbols' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $libdir = File::Spec->catdir($tempdir, 'pkg_lib');
    mkdir $libdir or die "Cannot create $libdir: $!";

    my $composition_path = File::Spec->catfile($tempdir, 'scalar_symbol_top_ports.fsm');
    my $package_path = File::Spec->catfile($libdir, 'shared_cfg.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'scalar_symbol_top_ports.sv');

    write_file(
        $package_path,
        <<'FSM'
(?pkg:shared_cfg
  (+constants
    (BYTE_W 8)
  )
)
FSM
    );

    write_file(
        $composition_path,
        <<'FSM'
(?top:scalar_symbol_top_ports
  (+import shared_cfg)
  (?ports:public_io
    out_data>shared_cfg.BYTE_W
    out_flag>FLAG_W
  )
  (+constants
    (FLAG_W 1)
  )
  (?rtl:uart_tx)
  (?toplink:wiring
    /uart_tx.data_out/out_data/
    /uart_tx.flag_out/out_flag/
  )
)

(?rtlif:uart_tx
  data_out>8:data
  flag_out>:data
)
FSM
    );

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        quiet => 1,
        target_language => 'systemverilog',
        source_search_paths => [$libdir],
    );
    my $result = $pipeline->generate_hdl_from_file($composition_path);
    my $ports = $result->{composition_spec}->top->ports_blocks->[0]->ports;
    my %ports_by_name = map { $_->name => $_ } @$ports;
    my $hdl = $result->{hdl_code};

    is($ports_by_name{out_data}->width, 8, 'composition ?ports imported positive integer scalar symbol resolves to width 8');
    is($ports_by_name{out_flag}->width, 1, 'composition ?ports local positive integer scalar symbol resolves to width 1');
    like($hdl, qr/output\s+\[7:0\]\s+out_data\b/s, 'generated top HDL uses imported positive integer scalar symbol width on out_data');
    like($hdl, qr/output\s+out_flag\b/s, 'generated top HDL uses local positive integer scalar symbol width on out_flag');

    my @cmd = ('./bin/fsmgen', '--quiet', '--path', $libdir, '--output', $output_path, $composition_path);
    my ($success, $error_code, $full_buf, $stdout_buf, $stderr_buf) = run(command => \@cmd, verbose => 0);
    my $combined_output = join('', @{$stdout_buf || []}, @{$stderr_buf || []});

    ok($success, 'CLI accepts composition positive integer scalar symbols on ?ports widths');
    ok(-e $output_path, 'CLI emits HDL for composition positive integer scalar symbol widths');
    ok(!defined($error_code) || $error_code == 0, 'CLI exits successfully for composition positive integer scalar symbol widths');
    unlike($combined_output, qr/composition port sizing is blocked|positive integer scalar symbol/s, 'successful composition scalar symbol width CLI run does not report width failures');
};

subtest 'composition ?ports reject non-positive scalar symbol widths explicitly' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'bad_scalar_symbol_top_ports.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'bad_scalar_symbol_top_ports.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:bad_scalar_symbol_top_ports
  (?ports:public_io
    out_data>ZERO_W
  )
  (+constants
    (ZERO_W 0)
  )
  (?rtl:uart_tx)
  (?toplink:wiring
    /uart_tx.data_out/out_data/
  )
)

(?rtlif:uart_tx
  data_out>8:data
)
FSM
    );

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        quiet => 1,
        target_language => 'systemverilog',
    );

    my $pipeline_error = eval {
        $pipeline->generate_hdl_from_file($composition_path);
        undef;
    };
    $pipeline_error = $@ if !$pipeline_error;

    like(
        $pipeline_error,
        qr/Composition top 'bad_scalar_symbol_top_ports' contains '\?ports' token 'out_data>ZERO_W', .*positive integer, a resolved scalar type alias, nor a positive integer scalar symbol/s,
        'pipeline reports non-positive composition scalar symbol widths explicitly',
    );

    my @cmd = ('./bin/fsmgen', '--quiet', '--output', $output_path, $composition_path);
    my ($success, $error_code, $full_buf, $stdout_buf, $stderr_buf) = run(command => \@cmd, verbose => 0);
    my $combined_output = join('', @{$stdout_buf || []}, @{$stderr_buf || []});

    ok(!$success, 'CLI rejects non-positive composition scalar symbol widths');
    ok(!-e $output_path, 'CLI does not emit HDL for non-positive composition scalar symbol widths');
    like(
        $combined_output,
        qr/Composition top 'bad_scalar_symbol_top_ports' contains '\?ports' token 'out_data>ZERO_W', .*positive integer, a resolved scalar type alias, nor a positive integer scalar symbol/s,
        'CLI surfaces the non-positive composition scalar symbol width boundary',
    );
    isnt($error_code, 0, 'CLI exits non-zero for non-positive composition scalar symbol widths');
};

subtest 'composition ?ports accept imported package scalar type aliases through package-qualified width tokens' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $libdir = File::Spec->catdir($tempdir, 'pkg_lib');
    mkdir $libdir or die "Cannot create $libdir: $!";

    my $composition_path = File::Spec->catfile($tempdir, 'typed_top_imported_ports.fsm');
    my $package_path = File::Spec->catfile($libdir, 'shared_types.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'typed_top_imported_ports.sv');

    write_file(
        $package_path,
        <<'FSM'
(?pkg:shared_types
  (+types
    (type byte (bits 8))
    (type flag bit)
  )
)
FSM
    );

    write_file(
        $composition_path,
        <<'FSM'
(?top:typed_top_imported_ports
  (+import shared_types)
  (?ports:public_io
    out_data>shared_types.byte
    out_flag>shared_types.flag
  )
  (?rtl:uart_tx)
  (?toplink:wiring
    /uart_tx.data_out/out_data/
    /uart_tx.flag_out/out_flag/
  )
)

(?rtlif:uart_tx
  data_out>8:data
  flag_out>:data
)
FSM
    );

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        quiet => 1,
        target_language => 'systemverilog',
        source_search_paths => [$libdir],
    );
    my $result = $pipeline->generate_hdl_from_file($composition_path);
    my $ports = $result->{composition_spec}->top->ports_blocks->[0]->ports;
    my %ports_by_name = map { $_->name => $_ } @$ports;
    my $hdl = $result->{hdl_code};

    is($ports_by_name{out_data}->width, 8, 'composition ?ports imported package byte alias resolves to width 8');
    is($ports_by_name{out_flag}->width, 1, 'composition ?ports imported package bit alias resolves to width 1');
    like($hdl, qr/output\s+\[7:0\]\s+out_data\b/s, 'generated top HDL uses imported package scalar type alias width on out_data');
    like($hdl, qr/output\s+out_flag\b/s, 'generated top HDL uses imported package bit alias width on out_flag');

    my @cmd = ('./bin/fsmgen', '--quiet', '--path', $libdir, '--output', $output_path, $composition_path);
    my ($success, $error_code, $full_buf, $stdout_buf, $stderr_buf) = run(command => \@cmd, verbose => 0);
    my $combined_output = join('', @{$stdout_buf || []}, @{$stderr_buf || []});

    ok($success, 'CLI accepts composition ?ports imported package scalar type aliases');
    ok(-e $output_path, 'CLI emits HDL for composition ?ports imported package scalar type aliases');
    ok(!defined($error_code) || $error_code == 0, 'CLI exits successfully for composition ?ports imported package scalar type aliases');
    unlike($combined_output, qr/composition port sizing is blocked|resolved scalar type alias/s, 'successful imported composition type CLI run does not report width-token failures');
};

subtest 'composition local scalar type aliases may target imported package scalar types' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $libdir = File::Spec->catdir($tempdir, 'pkg_lib');
    mkdir $libdir or die "Cannot create $libdir: $!";

    my $composition_path = File::Spec->catfile($tempdir, 'typed_top_local_import_alias_ports.fsm');
    my $package_path = File::Spec->catfile($libdir, 'shared_types.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'typed_top_local_import_alias_ports.sv');

    write_file(
        $package_path,
        <<'FSM'
(?pkg:shared_types
  (+types
    (type byte (bits 8))
    (type flag bit)
  )
)
FSM
    );

    write_file(
        $composition_path,
        <<'FSM'
(?top:typed_top_local_import_alias_ports
  (+import shared_types)
  (?ports:public_io
    out_data>byte_t
    out_flag>flag_t
  )
  (+types
    (type flag_t shared_types.flag)
    (type byte_t shared_types.byte)
  )
  (?rtl:uart_tx)
  (?toplink:wiring
    /uart_tx.data_out/out_data/
    /uart_tx.flag_out/out_flag/
  )
)

(?rtlif:uart_tx
  data_out>8:data
  flag_out>:data
)
FSM
    );

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        quiet => 1,
        target_language => 'systemverilog',
        source_search_paths => [$libdir],
    );
    my $result = $pipeline->generate_hdl_from_file($composition_path);
    my $ports = $result->{composition_spec}->top->ports_blocks->[0]->ports;
    my %ports_by_name = map { $_->name => $_ } @$ports;
    my $symbol_contract = $result->{intent_hir}{symbol_contract};
    my $hdl = $result->{hdl_code};

    is($ports_by_name{out_data}->width, 8, 'composition local alias to imported package byte type resolves to width 8');
    is($ports_by_name{out_flag}->width, 1, 'composition local alias to imported package bit type resolves to width 1');
    is($symbol_contract->{types}{byte_t}{width}, 8, 'composition symbol contract finalizes imported local byte alias width');
    is($symbol_contract->{types}{flag_t}{width}, 1, 'composition symbol contract finalizes imported local bit alias width');
    like($hdl, qr/output\s+\[7:0\]\s+out_data\b/s, 'generated top HDL uses local alias to imported package byte width on out_data');
    like($hdl, qr/output\s+out_flag\b/s, 'generated top HDL uses local alias to imported package bit width on out_flag');

    my @cmd = ('./bin/fsmgen', '--quiet', '--path', $libdir, '--output', $output_path, $composition_path);
    my ($success, $error_code, $full_buf, $stdout_buf, $stderr_buf) = run(command => \@cmd, verbose => 0);
    my $combined_output = join('', @{$stdout_buf || []}, @{$stderr_buf || []});

    ok($success, 'CLI accepts composition local scalar type aliases that target imported package scalar types');
    ok(-e $output_path, 'CLI emits HDL for composition local scalar type aliases that target imported package scalar types');
    ok(!defined($error_code) || $error_code == 0, 'CLI exits successfully for composition local scalar type aliases that target imported package scalar types');
    unlike($combined_output, qr/composition port sizing is blocked|malformed '\+types' entry/s, 'successful imported local composition alias CLI run does not report type failures');
};

subtest 'composition local scalar type aliases reject unresolved imported package scalar types explicitly' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $libdir = File::Spec->catdir($tempdir, 'pkg_lib');
    mkdir $libdir or die "Cannot create $libdir: $!";

    my $composition_path = File::Spec->catfile($tempdir, 'bad_typed_top_local_import_alias_ports.fsm');
    my $package_path = File::Spec->catfile($libdir, 'shared_types.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'bad_typed_top_local_import_alias_ports.sv');

    write_file(
        $package_path,
        <<'FSM'
(?pkg:shared_types
  (+types
    (type byte (bits 8))
  )
)
FSM
    );

    write_file(
        $composition_path,
        <<'FSM'
(?top:bad_typed_top_local_import_alias_ports
  (+import shared_types)
  (?ports:public_io
    out_data>byte_t
  )
  (+types
    (type byte_t shared_types.missing)
  )
  (?rtl:uart_tx)
  (?toplink:wiring
    /uart_tx.data_out/out_data/
  )
)

(?rtlif:uart_tx
  data_out>8:data
)
FSM
    );

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        quiet => 1,
        target_language => 'systemverilog',
        source_search_paths => [$libdir],
    );

    my $pipeline_error = eval {
        $pipeline->generate_hdl_from_file($composition_path);
        undef;
    };
    $pipeline_error = $@ if !$pipeline_error;

    like(
        $pipeline_error,
        qr/Composition top 'bad_typed_top_local_import_alias_ports' contains '\?ports' token 'out_data>byte_t', .*width token 'byte_t' is neither a positive integer, a resolved scalar type alias, nor a positive integer scalar symbol/s,
        'pipeline reports unresolved imported local composition scalar type aliases explicitly at the port-width boundary',
    );

    my @cmd = ('./bin/fsmgen', '--quiet', '--path', $libdir, '--output', $output_path, $composition_path);
    my ($success, $error_code, $full_buf, $stdout_buf, $stderr_buf) = run(command => \@cmd, verbose => 0);
    my $combined_output = join('', @{$stdout_buf || []}, @{$stderr_buf || []});

    ok(!$success, 'CLI rejects composition local scalar type aliases that target unresolved imported package scalar types');
    ok(!-e $output_path, 'CLI does not emit HDL for unresolved imported local composition scalar type aliases');
    like(
        $combined_output,
        qr/Composition top 'bad_typed_top_local_import_alias_ports' contains '\?ports' token 'out_data>byte_t', .*width token 'byte_t' is neither a positive integer, a resolved scalar type alias, nor a positive integer scalar symbol/s,
        'CLI surfaces the unresolved imported local composition scalar type alias boundary',
    );
    isnt($error_code, 0, 'CLI exits non-zero for unresolved imported local composition scalar type aliases');
};

subtest 'composition ?ports reject unresolved imported package scalar type aliases explicitly' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $libdir = File::Spec->catdir($tempdir, 'pkg_lib');
    mkdir $libdir or die "Cannot create $libdir: $!";

    my $composition_path = File::Spec->catfile($tempdir, 'bad_typed_top_imported_ports.fsm');
    my $package_path = File::Spec->catfile($libdir, 'shared_types.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'bad_typed_top_imported_ports.sv');

    write_file(
        $package_path,
        <<'FSM'
(?pkg:shared_types
  (+types
    (type byte (bits 8))
  )
)
FSM
    );

    write_file(
        $composition_path,
        <<'FSM'
(?top:bad_typed_top_imported_ports
  (+import shared_types)
  (?ports:public_io
    out_data>shared_types.missing
  )
  (?rtl:uart_tx)
  (?toplink:wiring
    /uart_tx.data_out/out_data/
  )
)

(?rtlif:uart_tx
  data_out>8:data
)
FSM
    );

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        quiet => 1,
        target_language => 'systemverilog',
        source_search_paths => [$libdir],
    );

    my $pipeline_error = eval {
        $pipeline->generate_hdl_from_file($composition_path);
        undef;
    };
    $pipeline_error = $@ if !$pipeline_error;

    like(
        $pipeline_error,
        qr/Composition top 'bad_typed_top_imported_ports' contains '\?ports' token 'out_data>shared_types\.missing', .*width token 'shared_types\.missing' is neither a positive integer, a resolved scalar type alias, nor a positive integer scalar symbol/s,
        'pipeline reports unresolved imported composition ?ports scalar type aliases explicitly',
    );

    my @cmd = ('./bin/fsmgen', '--quiet', '--path', $libdir, '--output', $output_path, $composition_path);
    my ($success, $error_code, $full_buf, $stdout_buf, $stderr_buf) = run(command => \@cmd, verbose => 0);
    my $combined_output = join('', @{$stdout_buf || []}, @{$stderr_buf || []});

    ok(!$success, 'CLI rejects unresolved imported composition ?ports scalar type aliases');
    ok(!-e $output_path, 'CLI does not emit HDL for unresolved imported composition ?ports scalar type aliases');
    like(
        $combined_output,
        qr/Composition top 'bad_typed_top_imported_ports' contains '\?ports' token 'out_data>shared_types\.missing', .*width token 'shared_types\.missing' is neither a positive integer, a resolved scalar type alias, nor a positive integer scalar symbol/s,
        'CLI surfaces the unresolved imported composition ?ports scalar type alias boundary',
    );
    isnt($error_code, 0, 'CLI exits non-zero for unresolved imported composition ?ports scalar type aliases');
};

subtest 'direct-root declarative type cycles fail explicitly' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'bad_direct_type_cycle.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'bad_direct_type_cycle.sv');

    write_file(
        $fsm_path,
        <<'FSM'
(?fsm:bad_direct_type_cycle
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+types
    (type A B)
    (type B A)
  )
  (+size
    (OUT A)
  )
  (idle
    (OUT = 1)
  )
)
FSM
    );

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        quiet => 1,
        target_language => 'systemverilog',
    );

    my $pipeline_error = eval {
        $pipeline->generate_hdl_from_file($fsm_path);
        undef;
    };
    $pipeline_error = $@ if !$pipeline_error;

    like(
        $pipeline_error,
        qr/Malformed declarative type scope in source 'bad_direct_type_cycle'.*Cycle:\s*type 'A' -> type 'B' -> type 'A'/s,
        'pipeline reports the explicit direct-root type dependency cycle',
    );

    my @cmd = ('./bin/fsmgen', '--quiet', '--output', $output_path, $fsm_path);
    my ($success, $error_code, $full_buf, $stdout_buf, $stderr_buf) = run(command => \@cmd, verbose => 0);
    my $combined_output = join('', @{$stdout_buf || []}, @{$stderr_buf || []});

    ok(!$success, 'CLI rejects direct-root declarative type cycles');
    ok(!-e $output_path, 'CLI does not emit HDL for direct-root declarative type cycles');
    like(
        $combined_output,
        qr/Malformed declarative type scope in source 'bad_direct_type_cycle'.*Cycle:\s*type 'A' -> type 'B' -> type 'A'/s,
        'CLI surfaces the explicit direct-root type dependency cycle',
    );
    isnt($error_code, 0, 'CLI exits non-zero for direct-root declarative type cycles');
};

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot write $path: $!";
    print {$fh} $content;
    close $fh or die "Cannot close $path: $!";
}

sub slurp_file {
    my ($path) = @_;
    open my $fh, '<', $path or die "Cannot read $path: $!";
    local $/;
    my $content = <$fh>;
    close $fh or die "Cannot close $path: $!";
    return $content;
}
