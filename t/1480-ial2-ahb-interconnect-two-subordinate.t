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

use FSM::Adapter::IAL2::PPIF;

subtest 'adapter parses the selected two-subordinate AHB interconnect PPIF shape' => sub {
    ok(-f sample_two_subordinate_ppif_path(), 'tracked runnable AHB two-subordinate PPIF sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_two_subordinate_ppif_path());

    is($result->{layer}, 'IAL2', 'AHB two-subordinate adapter result stays IAL2');
    is($result->{kind}, 'protocol_intent.ahb_interconnect', 'adapter returns the AHB interconnect kind');
    is($result->{mode}, 'requester-subordinate-interconnect', 'AHB interconnect mode remains explicit');
    is($result->{report}{schema}, 'fsmgen.ial2.protocol_intent.ahb_interconnect.v1', 'AHB interconnect report schema is selected');
    is($result->{report}{source_object}{id}, 'fsmgen-ahb-interconnect-two-subordinate', 'source object id is preserved');
    is($result->{report}{source_object}{intent_name}, 'ahb_interconnect_two_subordinate', 'source intent name is preserved');
    is($result->{report}{composition}{topology}, 'one_requester_two_subordinate_static_window_interconnect', 'report captures selected topology');
    is($result->{report}{composition}{child_instance_count}, 4, 'report captures requester/interconnect/two-subordinate child count');
    is($result->{report}{composition}{endpoint_child_instance_count}, 3, 'report captures requester plus two subordinate endpoints');
    is(scalar(@{$result->{report}{composition}{subordinates}}), 2, 'report carries two subordinate entries');
    is_deeply(
        [map { $_->{instance_name} } @{$result->{report}{composition}{subordinates}}],
        [qw(status control)],
        'report preserves authored subordinate child order',
    );
    is($result->{report}{composition}{address_map}{windows}[0]{name}, 'status', 'first window maps status child');
    is($result->{report}{composition}{address_map}{windows}[1]{name}, 'control', 'second window maps control child');
    is($result->{report}{composition}{address_map}{windows}[1]{base}{default}, 4, 'control window base is selected static offset');
    is($result->{report}{composition}{address_map}{windows}[1]{limit}, 8, 'control window limit is selected static offset plus size');
    is($result->{report}{composition}{response_mux}{subordinate_sources}[0]{response}{name}, 'HRESP_STATUS', 'response mux records status response source');
    is($result->{report}{composition}{response_mux}{subordinate_sources}[1]{response}{name}, 'HRESP_CONTROL', 'response mux records control response source');
    is($result->{report}{composition}{width_policy}{supported_subordinate_cardinality}, 2, 'width policy records selected two-subordinate cardinality');

    is_deeply(
        [map { $_->{name} } @{$result->{generated_ial1}{items}}],
        [qw(amba_requester.isf ahb_status_subordinate.isf ahb_control_subordinate.isf ahb_interconnect.isf)],
        'AHB two-subordinate source exposes requester, both subordinates, and fabric IAL1 artifacts',
    );
    is_deeply(
        [map { $_->{entry_artifact} } @{$result->{generated_ial0}{items}}],
        [qw(amba_requester.fsm ahb_status_subordinate.fsm ahb_control_subordinate.fsm ahb_interconnect.fsm ahb_tb.fsm)],
        'AHB two-subordinate source reports generated IAL0 artifacts in review order',
    );
    is_deeply(
        sorted([keys %{$result->{generated_ial0}{files}}]),
        [qw(ahb_control_subordinate.fsm ahb_interconnect.fsm ahb_status_subordinate.fsm ahb_tb.fsm amba_requester.fsm)],
        'AHB two-subordinate source exposes all generated IAL0 files',
    );

    my ($interconnect_isf_item) = grep { $_->{name} eq 'ahb_interconnect.isf' } @{$result->{generated_ial1}{items}};
    my $interconnect_isf = $interconnect_isf_item->{text};
    like($interconnect_isf, qr/\(output HSEL_STATUS \(reset 0\) \(default 0\)\)/, 'generated interconnect IAL1 drives status select');
    like($interconnect_isf, qr/\(output HSEL_CONTROL \(reset 0\) \(default 0\)\)/, 'generated interconnect IAL1 drives control select');
    like($interconnect_isf, qr/\(window status\s+\(base STATUS_BASE width 32 default 0\)\s+\(size STATUS_SIZE width 32 default 4\)\)/s, 'generated interconnect IAL1 records status window');
    like($interconnect_isf, qr/\(window control\s+\(base CONTROL_BASE width 32 default 4\)\s+\(size CONTROL_SIZE width 32 default 4\)\)/s, 'generated interconnect IAL1 records control window');

    my $interconnect_fsm = $result->{generated_ial0}{files}{'ahb_interconnect.fsm'};
    like($interconnect_fsm, qr/\(= \(HSEL_STATUS> 1\)\)/, 'generated interconnect IAL0 asserts status select on status hits');
    like($interconnect_fsm, qr/\(= \(HSEL_CONTROL> 1\)\)/, 'generated interconnect IAL0 asserts control select on control hits');
    like($interconnect_fsm, qr/\(= \(HADDR_STATUS> HADDR\)\)/, 'generated interconnect IAL0 emits zero-base status local address');
    like($interconnect_fsm, qr/\(= \(HADDR_CONTROL> \(- HADDR 4\)\)\)/, 'generated interconnect IAL0 subtracts control base for local address');
    like(
        $interconnect_fsm,
        qr/\(<\(! \(& \(! \(== HTRANS 2'b00\)\) \(< HADDR 4\)\)\)\s+\(= \(HSEL_STATUS> 0\)\)\s+\(= \(HADDR_STATUS> 0\)\)/s,
        'generated interconnect IAL0 gives status a complementary not-hit default',
    );
    like(
        $interconnect_fsm,
        qr/\(<\(! \(& \(! \(== HTRANS 2'b00\)\) \(& \(>= HADDR 4\) \(< HADDR 8\)\)\)\)\s+\(= \(HSEL_CONTROL> 0\)\)\s+\(= \(HADDR_CONTROL> 0\)\)/s,
        'generated interconnect IAL0 gives control a complementary not-hit default',
    );
    like(
        $interconnect_fsm,
        qr/\(<\(& \(! \(\| ahb_data_owner_0_q ahb_data_owner_1_q\)\) \(! \(& \(! \(== HTRANS 2'b00\)\) \(! \(\| \(< HADDR 4\) \(& \(>= HADDR 4\) \(< HADDR 8\)\)\)\)\)\)\)\s+\(= \(HREADY> 1\)\)\s+\(= \(HRESP> 2'b00\)\)\s+\(= \(HRDATA> 0\)\)/s,
        'generated interconnect IAL0 ordinary response default excludes every owner and unmapped address',
    );
    like($interconnect_fsm, qr/<HRESP_STATUS\s+\(= \(HRESP> 2'b01\)\)/s, 'generated interconnect IAL0 maps status ERROR to requester ERROR');
    like($interconnect_fsm, qr/<HRESP_CONTROL\s+\(= \(HRESP> 2'b01\)\)/s, 'generated interconnect IAL0 maps control ERROR to requester ERROR');
    like($interconnect_fsm, qr/\(! \(\| \(< HADDR 4\) \(& \(>= HADDR 4\) \(< HADDR 8\)\)\)\).*?\(! \(\| ahb_data_owner_0_q ahb_data_owner_1_q\)\)/s, 'generated interconnect IAL0 treats unmapped as no selected window and no retained data-phase owner');

    my $top = $result->{generated_ial0}{files}{'ahb_tb.fsm'};
    like($top, qr/\(\?fsmc:status ahb_status_subordinate\)/, 'generated top instantiates status subordinate');
    like($top, qr/\(\?fsmc:control ahb_control_subordinate\)/, 'generated top instantiates control subordinate');
    like($top, qr/\(fabric\.HSEL_STATUS status\.HSEL_STATUS\)/, 'generated top wires status select through the legal fabric instance');
    like($top, qr/\(fabric\.HSEL_CONTROL control\.HSEL_CONTROL\)/, 'generated top wires control select through the legal fabric instance');
    like($top, qr/\(status\.HRESP_STATUS fabric\.HRESP_STATUS\)/, 'generated top wires status response into the legal fabric instance');
    like($top, qr/\(control\.HRESP_CONTROL fabric\.HRESP_CONTROL\)/, 'generated top wires control response into the legal fabric instance');

    my %residue = map { $_->{id} => 1 } @{$result->{report}{unsupported_residue}};
    ok(!$residue{ahb_multi_subordinate_decode_deferred}, 'two-subordinate report removes old multi-subordinate deferred residue');
    ok($residue{ahb_broader_interconnect_decode_deferred}, 'two-subordinate report keeps broader interconnect/decode residue explicit');
    ok($residue{ahb_aggregate_profile_alias_deferred}, 'two-subordinate generic PPIF keeps aggregate .ahb alias residue explicit');
};

subtest 'malformed two-subordinate AHB interconnect PPIF sources fail closed' => sub {
    my @cases = (
        [
            'duplicate subordinate object names',
            sub {
                my $source = sample_two_subordinate_ppif();
                $source =~ s/\(ahb-subordinate ahb_control_subordinate/(ahb-subordinate ahb_status_subordinate/;
                return $source;
            },
            qr/duplicate subordinate object 'ahb_status_subordinate'/,
        ],
        [
            'duplicate subordinate child instances',
            sub {
                my $source = sample_two_subordinate_ppif();
                $source =~ s/\(subordinate control ahb_control_subordinate\)/(subordinate status ahb_control_subordinate)/;
                return $source;
            },
            qr/child instance aliases must be unique/,
        ],
        [
            'duplicate child object references',
            sub {
                my $source = sample_two_subordinate_ppif();
                $source =~ s/\(subordinate control ahb_control_subordinate\)/(subordinate control ahb_status_subordinate)/;
                return $source;
            },
            qr/duplicate subordinate child object reference 'ahb_status_subordinate'/,
        ],
        [
            'missing matching control window',
            sub {
                my $source = sample_two_subordinate_ppif();
                $source =~ s/\(window control\n        \(base CONTROL_BASE width 32 default 4\)\n        \(size CONTROL_SIZE width 32 default 4\)\)/(window other\n        (base CONTROL_BASE width 32 default 4)\n        (size CONTROL_SIZE width 32 default 4))/;
                return $source;
            },
            qr/address-map window 'other' does not match a subordinate child instance/,
        ],
        [
            'overlapping windows',
            sub {
                my $source = sample_two_subordinate_ppif();
                $source =~ s/\(base CONTROL_BASE width 32 default 4\)/(base CONTROL_BASE width 32 default 0)/;
                return $source;
            },
            qr/address-map windows 'status' and 'control' overlap/,
        ],
        [
            'scalar subordinate wiring in two-subordinate source',
            sub {
                my $source = sample_two_subordinate_ppif();
                $source =~ s/\(lock HLOCK\)\n      \(write-data HWDATA width 32\)/(lock HLOCK)\n      (write-data HWDATA width 32)\n      (subordinate-select HSEL_STATUS)/;
                return $source;
            },
            qr/two-subordinate wiring must omit scalar bus.subordinate_select/,
        ],
    );

    for my $case (@cases) {
        my ($label, $build_source, $pattern, $source_label) = @$case;
        my $ok = eval {
            FSM::Adapter::IAL2::PPIF->new()->parse_source($build_source->(), $source_label // "$label.ppif");
            1;
        };
        ok(!$ok, "$label is rejected");
        like($@, $pattern, "$label diagnostic is targeted");
    }
};

subtest 'CLI checks, semantic export, schedule report, and outdir use the public two-subordinate path' => sub {
    my $check = run_json_command('./bin/fsmgen', '--quiet', '--strict', '--check', '--json', sample_two_subordinate_ppif_path());
    ok($check->{success}, 'strict check JSON succeeds for AHB two-subordinate PPIF');
    is($check->{result}{module_name}, 'ahb_tb', 'check JSON reports generated aggregate module name');
    is($check->{result}{composition_child_count}, 4, 'check JSON reports requester/interconnect/two-subordinate children');
    is($check->{support_accounting}{entry_id}, 'intent.ppif_ahb_interconnect_two_subordinate', 'check JSON matches AHB two-subordinate support accounting');
    is($check->{support_accounting}{source_kind}, 'ppif', 'check JSON reports PPIF source kind');
    is($check->{support_accounting}{coverage}, 'ial2_ppif_ahb_interconnect_two_subordinate_pipeline_cli', 'check JSON reports selected coverage key');

    my $semantic = run_json_command('./bin/fsmgen', '--quiet', '--strict', '--emit-semantic-json', sample_two_subordinate_ppif_path());
    ok($semantic->{success}, 'strict semantic JSON succeeds for AHB two-subordinate PPIF');
    is($semantic->{generation_result_snapshot}{summary}{module_name}, 'ahb_tb', 'semantic JSON reports generated aggregate module name');
    is($semantic->{generation_result_snapshot}{summary}{source_root_kind}, 'top', 'semantic JSON reports generated composition top source root');
    is($semantic->{support_accounting}{entry_id}, 'intent.ppif_ahb_interconnect_two_subordinate', 'semantic JSON matches support accounting');

    my $schedule = run_json_command('./bin/fsmgen', '--quiet', '--emit-schedule-json', sample_two_subordinate_ppif_path());
    is($schedule->{schema}, 'fsmgen.ial2.protocol_intent.ahb_interconnect.v1', 'schedule/report JSON exposes AHB interconnect schema');
    is($schedule->{composition}{topology}, 'one_requester_two_subordinate_static_window_interconnect', 'schedule/report JSON exposes selected topology');
    is($schedule->{composition}{child_instance_count}, 4, 'schedule/report JSON exposes four generated children');
    is($schedule->{composition}{generated_interconnect}{ial1_artifact}, 'ahb_interconnect.isf', 'schedule/report JSON exposes generated interconnect IAL1 artifact');
    is_deeply(
        [map { $_->{name} } @{$schedule->{composition}{address_map}{windows}}],
        [qw(status control)],
        'schedule/report JSON exposes both static windows',
    );
    my %schedule_residue = map { $_->{id} => 1 } @{$schedule->{unsupported_residue}};
    ok($schedule_residue{ahb_broader_interconnect_decode_deferred}, 'schedule/report JSON keeps narrowed broader AHB residue explicit');
    ok(!$schedule_residue{ahb_multi_subordinate_decode_deferred}, 'schedule/report JSON removes old multi-subordinate residue for selected source');

    my $tempdir = tempdir(CLEANUP => 1);
    my $outdir = File::Spec->catdir($tempdir, 'out');
    my $hdl = File::Spec->catfile($tempdir, 'ahb_tb.sv');
    my ($success, undef, undef, undef, $stderr) = run(
        command => ['./bin/fsmgen', '--quiet', '--outdir', $outdir, '--output', $hdl, sample_two_subordinate_ppif_path()],
    );
    ok($success, 'AHB two-subordinate PPIF emits HDL and review artifacts through --outdir');
    is(join('', @{$stderr || []}), '', 'outdir generation keeps stderr clean');
    for my $artifact (qw(
        amba_requester.isf
        ahb_status_subordinate.isf
        ahb_control_subordinate.isf
        ahb_interconnect.isf
        amba_requester.fsm
        ahb_status_subordinate.fsm
        ahb_control_subordinate.fsm
        ahb_interconnect.fsm
        ahb_tb.fsm
    )) {
        ok(-f File::Spec->catfile($outdir, $artifact), "outdir contains generated $artifact");
    }
    ok(-f $hdl, 'outdir command emits selected aggregate HDL output');
    like(slurp($hdl), qr/\bmodule\s+ahb_tb\b/, 'generated HDL contains the AHB aggregate module');
    like(slurp(File::Spec->catfile($outdir, 'ahb_interconnect.fsm')), qr/HSEL_CONTROL/, 'outdir generated interconnect FSM keeps control decode path');
};

done_testing();

sub sample_two_subordinate_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'ahb_interconnect_two_subordinate.ppif');
}

sub sample_two_subordinate_ppif {
    return slurp(sample_two_subordinate_ppif_path());
}

sub run_json_command {
    my @command = @_;
    my ($success, undef, undef, $stdout, $stderr) = run(command => \@command);
    my $json = join('', @{$stdout || []});
    my $decoded = eval { decode_json($json) };
    ok($decoded, join(' ', @command) . ' emits decodable JSON')
        or do {
            diag($json);
            diag(join('', @{$stderr || []}));
            diag('command failed') unless $success;
            return {};
        };
    return $decoded;
}

sub slurp {
    my ($path) = @_;
    open my $fh, '<', $path or die "Cannot read $path: $!";
    local $/;
    return <$fh>;
}

sub sorted {
    my ($values) = @_;
    return [sort @$values];
}
