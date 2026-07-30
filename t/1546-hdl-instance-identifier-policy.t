#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use IPC::Cmd qw(run);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::IAL2::PPIF;
use FSM::Adapter::ISF;
use FSM::Backend::VHDL::StructuralRTLIREmitter;
use FSM::Backend::VerilogFamily::StructuralRTLIREmitter;
use FSM::Composition::Parser;
use FSM::Scheduler::ISF;
use FSM::Support::HDLExternalValidation qw(hdl_external_validation_tools);
use FSM::Support::HDLInstanceIdentifierPolicy;

subtest 'portable registry follows each target language case rule' => sub {
    is_deeply(
        FSM::Support::HDLInstanceIdentifierPolicy->reserved_target_languages('interconnect'),
        ['SystemVerilog'],
        'SystemVerilog interconnect keyword is reserved',
    );
    is_deeply(
        FSM::Support::HDLInstanceIdentifierPolicy->reserved_target_languages('INTERCONNECT'),
        [],
        'SystemVerilog keyword lookup remains case-sensitive',
    );
    is_deeply(
        FSM::Support::HDLInstanceIdentifierPolicy->reserved_target_languages('PrOcEsS'),
        ['VHDL'],
        'VHDL keyword lookup is case-insensitive',
    );
    is_deeply(
        FSM::Support::HDLInstanceIdentifierPolicy->reserved_target_languages('alias'),
        [qw(SystemVerilog VHDL)],
        'shared keyword reports every reserving target',
    );
    ok(
        FSM::Support::HDLInstanceIdentifierPolicy->is_portable_instance_identifier('worker_0'),
        'ordinary simple identifier is portable',
    );
    ok(
        !FSM::Support::HDLInstanceIdentifierPolicy->is_portable_instance_identifier('worker-0'),
        'non-simple identifier is not portable',
    );
};

subtest 'generated allocator preserves legal labels and resolves keywords and collisions' => sub {
    my %reserved = (clk => 1, status => 1, WORKER => 1);

    is(
        FSM::Support::HDLInstanceIdentifierPolicy->allocate_generated_instance_identifier(
            desired => 'control', role => 'peripheral', reserved => \%reserved,
        ),
        'control',
        'legal non-colliding generated label remains byte-stable',
    );
    is(
        FSM::Support::HDLInstanceIdentifierPolicy->allocate_generated_instance_identifier(
            desired => 'interconnect', role => 'interconnect', reserved => \%reserved,
        ),
        'interconnect_instance',
        'keyword seed gains the deterministic instance suffix',
    );
    is(
        FSM::Support::HDLInstanceIdentifierPolicy->allocate_generated_instance_identifier(
            desired => 'status', role => 'peripheral', reserved => \%reserved,
        ),
        'status_peripheral',
        'ordinary collision gains the deterministic role suffix',
    );
    is(
        FSM::Support::HDLInstanceIdentifierPolicy->allocate_generated_instance_identifier(
            desired => 'worker', role => 'requester', reserved => \%reserved,
        ),
        'worker_requester',
        'case-only collision is allocated safely for VHDL',
    );

    $reserved{interconnect_instance_2} = 1;
    is(
        FSM::Support::HDLInstanceIdentifierPolicy->allocate_generated_instance_identifier(
            desired => 'interconnect', role => 'interconnect', reserved => \%reserved,
        ),
        'interconnect_instance_3',
        'further keyword-seed collisions use the first free numeric suffix',
    );
};

subtest 'authored source boundaries reject reserved child labels early' => sub {
    my @composition_cases = (
        [ ['?fsmc:interconnect', ['child_fsm']], 'interconnect', 'SystemVerilog' ],
        [ ['?rtl:process', []], 'process', 'VHDL' ],
    );
    for my $case (@composition_cases) {
        my ($child, $name, $target) = @$case;
        my $ok = eval {
            FSM::Composition::Parser->new()->parse_top_child('portable_top', $child);
            1;
        };
        ok(!$ok, "direct composition child '$name' is rejected");
        like(
            $@,
            qr/Composition top 'portable_top'.*child instance '$name'.*reserved in $target/s,
            "direct composition child '$name' reports its reserving target",
        );
    }

    my $library_ok = eval {
        FSM::Adapter::ISF->new()->parse_source(<<'ISF', 'reserved-library-use.isf');
(actor reserved_library_use
  (clock clk)
  (interface (input trigger) (output done))
  (use pulse_lib.pulse_actor as interconnect
    (bind (clock clk)))
  (transaction run (on trigger) (complete done)))
ISF
        1;
    };
    ok(!$library_ok, 'reusable-library use instance keyword is rejected during parsing');
    like(
        $@,
        qr/Actor 'reserved_library_use' library use instance 'interconnect'.*reserved in SystemVerilog/s,
        'reusable-library use diagnostic identifies the source boundary and target',
    );

    my $atl_ok = eval {
        FSM::Adapter::ISF->new()->parse_source(<<'ISF', 'reserved-atl-instance.isf');
(actor reserved_atl_instance
  (clock clk)
  (interface (input trigger) (output done))
  (instance PrOcEsS of worker)
  (transaction run (on trigger) (complete done)))
ISF
        1;
    };
    ok(!$atl_ok, 'ATL static instance VHDL keyword is rejected during parsing');
    like(
        $@,
        qr/Actor 'reserved_atl_instance' static actor instance 'PrOcEsS'.*reserved in VHDL/s,
        'ATL diagnostic applies VHDL case-insensitive keyword lookup',
    );

    my $spawn_ok = eval {
        my $actor = FSM::Adapter::ISF->new()->parse_source(<<'ISF', 'reserved-spawn-instance.isf');
(actor reserved_spawn_instance
  (clock clk)
  (interface (input trigger) (output done))
  (transaction run
    (on trigger)
    (spawn worker as interconnect)
    (complete done))
  (transaction worker (complete done)))
ISF
        FSM::Scheduler::ISF->new()->lower($actor);
        1;
    };
    ok(!$spawn_ok, 'spawn instance keyword is rejected during lowering');
    like(
        $@,
        qr/Transaction 'run' spawn instance 'interconnect'.*reserved in SystemVerilog/s,
        'spawn diagnostic identifies the authored instance and target',
    );
};

subtest 'structural emitters defend direct IR callers' => sub {
    my $sv_ok = eval {
        FSM::Backend::VerilogFamily::StructuralRTLIREmitter->emit_module({
            target_language => 'systemverilog',
            module_name => 'portable_top',
            ports => [],
            nets => [],
            instances => [{
                kind => 'rtl',
                module_name => 'child_module',
                instance_name => 'interconnect',
                port_bindings => [],
            }],
        });
        1;
    };
    ok(!$sv_ok, 'Verilog-family emitter rejects a direct-IR keyword label');
    like(
        $@,
        qr/StructuralRTLIR verilog-family child instance 'interconnect'.*reserved in SystemVerilog/s,
        'Verilog-family emitter diagnostic names the keyword target',
    );

    my $vhdl_ok = eval {
        FSM::Backend::VHDL::StructuralRTLIREmitter->emit_module({
            target_language => 'vhdl',
            module_name => 'portable_top',
            ports => [],
            nets => [],
            instances => [{
                kind => 'rtl',
                module_name => 'child_module',
                instance_name => 'PROCESS',
                port_bindings => [],
            }],
        });
        1;
    };
    ok(!$vhdl_ok, 'VHDL emitter rejects a direct-IR case-folded keyword label');
    like(
        $@,
        qr/StructuralRTLIR VHDL child instance 'PROCESS'.*reserved in VHDL/s,
        'VHDL emitter diagnostic names the case-insensitive keyword target',
    );
};

subtest 'public APB composition allocates and reports the portable interconnect label' => sub {
    my $fixture = File::Spec->catfile(
        $FindBin::Bin,
        '..',
        'ppif',
        'apb_composition_multi_peripheral.ppif',
    );
    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_file($fixture);
    my $top = $result->{generated_ial0}{files}{'apb_tb.fsm'};

    like(
        $top,
        qr/\(\?fsmc:interconnect_instance apb_interconnect\)/,
        'APB top uses the deterministic portable interconnect instance',
    );
    unlike(
        $top,
        qr/\(\?fsmc:interconnect apb_interconnect\)/,
        'APB top no longer emits the SystemVerilog keyword instance',
    );
    like(
        $top,
        qr/\(interconnect_instance\.PSEL_STATUS status_peripheral\.PSEL_STATUS\)/,
        'APB top wiring follows the allocated interconnect identity',
    );
    is(
        $result->{report}{composition}{generated_interconnect}{instance_name},
        'interconnect_instance',
        'APB composition report exposes the generated interconnect identity',
    );
    is(
        $result->{report}{children}[1]{instance_name},
        'interconnect_instance',
        'APB child report uses the same generated interconnect identity',
    );

    my $reserved_source = slurp($fixture);
    $reserved_source =~ s/\(requester requester apb_requester\)/(requester interconnect apb_requester)/;
    my $reserved_ok = eval {
        FSM::Adapter::IAL2::PPIF->new()->parse_source(
            $reserved_source,
            'reserved-apb-child.ppif',
        );
        1;
    };
    ok(!$reserved_ok, 'authored APB child keyword is rejected during protocol normalization');
    like(
        $@,
        qr/APB composition requester child instance 'interconnect'.*reserved in SystemVerilog/s,
        'authored APB child diagnostic identifies the protocol boundary and target',
    );

    my $tools = hdl_external_validation_tools();
    my @missing = grep { !$tools->{$_} } qw(verilator yosys);
    SKIP: {
        skip 'Verilator/Yosys unavailable for public APB target proof', 5 if @missing;

        my $scratch_root = File::Spec->catdir($FindBin::Bin, '..', 'build', 'test-tmp');
        make_path($scratch_root);
        my $scratch = tempdir(
            'hdl-instance-identifiers-XXXXXX',
            DIR => $scratch_root,
            CLEANUP => 1,
        );
        my $hdl = File::Spec->catfile($scratch, 'apb_tb.sv');
        my ($success, undef, undef, undef, $stderr_buf) = run(
            command => ['./bin/fsmgen', '--quiet', '--output', $hdl, $fixture],
        );
        ok($success, 'public APB SystemVerilog generation succeeds');
        is(join('', @{$stderr_buf || []}), '', 'public APB generation keeps stderr clean');
        ok(-s $hdl, 'public APB generation writes repository-local HDL scratch');

        my ($verilator_ok, undef, undef, undef, $verilator_stderr) = run(
            command => [
                $tools->{verilator},
                '--lint-only',
                '--sv',
                '-Wno-fatal',
                $hdl,
            ],
        );
        ok(
            $verilator_ok,
            'verilator_lint accepts the public APB composition (pre-existing warnings remain non-fatal)',
        ) or diag(join('', @{$verilator_stderr || []}));

        my ($yosys_ok, undef, undef, undef, $yosys_stderr) = run(
            command => [
                $tools->{yosys},
                '-p',
                "read_verilog -sv -noautowire $hdl; synth -noabc -top apb_tb; stat",
            ],
        );
        ok($yosys_ok, 'yosys_synthesis accepts the public APB composition')
            or diag(join('', @{$yosys_stderr || []}));
    }
};

subtest 'public AHB generated labels remain stable' => sub {
    my $fixture = File::Spec->catfile(
        $FindBin::Bin,
        '..',
        'ppif',
        'ahb_interconnect.ppif',
    );
    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_file($fixture);
    my $top = $result->{generated_ial0}{files}{'ahb_tb.fsm'};

    like(
        $top,
        qr/\(\?fsmc:fabric ahb_interconnect\)/,
        'legal AHB fabric generated label remains byte-stable',
    );
    is(
        $result->{report}{children}[1]{instance_name},
        'fabric',
        'AHB report preserves the legal generated fabric identity',
    );
};

subtest 'public AXI generated labels remain stable' => sub {
    my $fixture = File::Spec->catfile(
        $FindBin::Bin,
        '..',
        'ppif',
        'axi_write_request_composition.ppif',
    );
    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_file($fixture);
    my $top = $result->{generated_ial0}{files}{'axi_write_request_composition.fsm'};

    like($top, qr/\(\?fsmc:aw_driver axi_aw_driver\)/, 'AXI AW driver label remains byte-stable');
    like($top, qr/\(\?fsmc:w_driver axi_w_driver\)/, 'AXI W driver label remains byte-stable');
    like(
        $top,
        qr/\(\?fsmc:coordinator axi_write_request_coordinator\)/,
        'AXI coordinator label remains byte-stable',
    );
};

sub slurp {
    my ($path) = @_;
    open my $fh, '<', $path or die "Cannot read $path: $!";
    local $/;
    return <$fh>;
}

done_testing();
