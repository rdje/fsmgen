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

subtest 'adapter parses the selected APB requester/completer composition PPIF shape' => sub {
    ok(-f sample_apb_composition_ppif_path(), 'tracked runnable APB composition PPIF sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_ppif_path());

    is($result->{layer}, 'IAL2', 'APB composition adapter result stays IAL2');
    is($result->{kind}, 'protocol_intent.apb_composition', 'adapter returns the APB composition kind');
    is($result->{mode}, 'requester-completer-composition', 'APB composition mode is explicit');
    is($result->{report}{schema}, 'fsmgen.ial2.protocol_intent.apb_composition.v1', 'APB composition report schema is selected');
    is($result->{report}{source_object}{id}, 'fsmgen-apb-composition', 'APB composition source object id is preserved');
    is($result->{report}{source_object}{intent_name}, 'apb_composition', 'APB composition source intent name is preserved');
    is($result->{report}{target_protocol}{profile}, 'apb', 'APB composition report carries the APB profile');
    is($result->{report}{target_protocol}{object}, 'apb-composition', 'APB composition report carries the APB composition object');
    is($result->{report}{target_protocol}{role}, 'composition', 'APB composition report carries the composition role');

    is_deeply(
        [map { $_->{name} } @{$result->{generated_ial1}{items}}],
        [qw(apb_requester.isf apb_completer.isf)],
        'APB composition exposes both generated IAL1 endpoint artifacts',
    );
    is_deeply(
        sorted([keys %{$result->{generated_ial0}{files}}]),
        [qw(apb_completer.fsm apb_requester.fsm apb_tb.fsm)],
        'APB composition exposes requester, completer, and top .fsm artifacts',
    );

    my $top = $result->{generated_ial0}{files}{'apb_tb.fsm'};
    like($top, qr/\A\(\?top:apb_tb\b/, 'generated top starts with the APB composition root');
    like($top, qr/\(\?fsmc:requester apb_requester\)/, 'generated top instantiates the requester child');
    like($top, qr/\(\?fsmc:completer apb_completer\)/, 'generated top instantiates the completer child');
    like($top, qr/\(requester\.PSEL completer\.PSEL\)/, 'generated top wires APB select requester to completer');
    like($top, qr/\(completer\.PREADY requester\.PREADY\)/, 'generated top wires APB ready completer to requester');
    like($top, qr/\(\?fsm:apb_requester\b/, 'generated top carries requester child FSM text for standalone lowering');
    like($top, qr/\(\?fsm:apb_completer\b/, 'generated top carries completer child FSM text for standalone lowering');
    unlike($top, qr/=busy\b/, 'generated top does not expose deferred requester busy status');

    is($result->{report}{composition}{name}, 'apb_tb', 'report captures the composition top name');
    is($result->{report}{composition}{child_instance_count}, 2, 'report captures the two child instances');
    is($result->{report}{children}[0]{role}, 'requester', 'report carries requester child metadata first');
    is($result->{report}{children}[1]{role}, 'completer', 'report carries completer child metadata second');
    is($result->{report}{generated_artifacts}{hdl_entry}{entry_artifact}, 'apb_tb.fsm', 'report selects generated composition top as HDL entry');
    is_deeply(
        $result->{report}{generated_artifacts}{hdl_entry}{child_artifacts},
        [qw(apb_requester.fsm apb_completer.fsm)],
        'report lists child artifacts under the selected HDL entry',
    );

    my %residue = map { $_->{id} => 1 } @{$result->{report}{unsupported_residue}};
    ok($residue{apb_interconnect_multi_peripheral_decode_deferred}, 'report keeps multi-peripheral interconnect residue explicit');
    ok($residue{apb_requester_busy_status_deferred}, 'report keeps requester busy/status residue explicit');
};

subtest 'adapter rejects malformed APB composition PPIF shapes with targeted diagnostics' => sub {
    my $missing_composition = sample_apb_composition_ppif();
    $missing_composition =~ s/\n  \(apb-composition apb_tb\n    \(role composition\)\n    \(clock clk\)\n    \(reset \(rst_n active_low async\)\)\n    \(children\n      \(requester requester apb_requester\)\n      \(completer completer apb_completer\)\)\n    \(wiring apb_bus\n      \(select PSEL\)\n      \(enable PENABLE\)\n      \(write PWRITE\)\n      \(address PADDR width 32\)\n      \(write-data PWDATA width 32\)\n      \(ready PREADY\)\n      \(read-data PRDATA width 32\)\n      \(error PSLVERR\)\)\)//;

    my $bad_child = sample_apb_composition_ppif();
    $bad_child =~ s/\(requester requester apb_requester\)/(requester requester apb_requester_other)/;

    my $bad_bus = sample_apb_composition_ppif();
    $bad_bus =~ s/\(ready PREADY\)\n      \(read-data PRDATA width 32\)\n      \(error PSLVERR\)\)\)\)\n\z/(ready PREADY_OTHER)\n      (read-data PRDATA width 32)\n      (error PSLVERR))))\n/;

    my @cases = (
        ['missing apb composition object', $missing_composition, qr/cannot mix \(apb-requester \.\.\.\) with .* \(apb-completer \.\.\.\).*outside the explicit APB composition shape/s],
        ['bad requester child reference', $bad_child, qr/APB composition requester child references .*expected 'apb_requester'/],
        ['bad ready bus wiring', $bad_bus, qr/APB composition IAL2 contract bus\.ready must be scalar signal 'PREADY_OTHER'/],
    );

    for my $case (@cases) {
        my ($label, $source, $pattern) = @$case;
        my $ok = eval { FSM::Adapter::IAL2::PPIF->new()->parse_source($source, "$label.ppif"); 1 };
        ok(!$ok, "$label is rejected");
        like($@, $pattern, "$label diagnostic is targeted");
    }
};

subtest 'CLI check and semantic JSON support-account APB composition PPIF identity' => sub {
    my $path = sample_apb_composition_ppif_path();
    my ($check_success, undef, undef, $check_stdout, $check_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--check', '--json', $path],
    );
    ok($check_success, 'APB composition --check --json succeeds');
    is(join('', @{$check_stderr || []}), '', 'APB composition --check --json keeps stderr clean');
    my $check_report = decode_json(join('', @{$check_stdout || []}));
    ok($check_report->{success}, 'APB composition check JSON reports success');
    is($check_report->{source}{resolved_path}, File::Spec->rel2abs($path), 'APB composition check JSON reports the public .ppif source path');
    is($check_report->{support_accounting}{entry_id}, 'intent.ppif_apb_composition', 'APB composition check JSON names the corpus entry');
    is($check_report->{support_accounting}{source_kind}, 'ppif', 'APB composition check JSON records PPIF source kind');

    my ($semantic_success, undef, undef, $semantic_stdout, $semantic_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', $path],
    );
    ok($semantic_success, 'APB composition --emit-semantic-json succeeds');
    is(join('', @{$semantic_stderr || []}), '', 'APB composition --emit-semantic-json keeps stderr clean');
    my $semantic_report = decode_json(join('', @{$semantic_stdout || []}));
    ok($semantic_report->{success}, 'APB composition semantic JSON reports success');
    is($semantic_report->{support_accounting}{entry_id}, 'intent.ppif_apb_composition', 'APB composition semantic JSON names the corpus entry');
    is($semantic_report->{semantic}{module}{source_root_kind}, 'top', 'APB composition semantic JSON payload describes the generated composition root');
    is($semantic_report->{semantic}{module}{name}, 'apb_tb', 'APB composition semantic JSON records the generated top module');
};

subtest 'CLI schedule JSON, outdir, and .apb alias expose APB composition review artifacts' => sub {
    my $path = sample_apb_composition_ppif_path();
    my ($schedule_success, undef, undef, $schedule_stdout, $schedule_stderr) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', $path],
    );
    ok($schedule_success, 'APB composition --emit-schedule-json succeeds');
    is(join('', @{$schedule_stderr || []}), '', 'APB composition --emit-schedule-json keeps stderr clean');
    my $schedule_report = decode_json(join('', @{$schedule_stdout || []}));
    is($schedule_report->{schema}, 'fsmgen.ial2.protocol_intent.apb_composition.v1', 'APB composition schedule JSON reports schema');
    is($schedule_report->{generated_artifacts}{hdl_entry}{entry_artifact}, 'apb_tb.fsm', 'APB composition schedule JSON reports the HDL entry');

    my $tempdir = tempdir(CLEANUP => 1);
    my $outdir = File::Spec->catdir($tempdir, 'out');
    my $hdl = File::Spec->catfile($tempdir, 'apb_tb.sv');
    my ($success, undef, undef, undef, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--outdir', $outdir, '--output', $hdl, $path],
    );

    ok($success, 'APB composition CLI generation succeeds');
    is(join('', @{$stderr_buf || []}), '', 'APB composition generation keeps stderr clean');
    for my $artifact (qw(apb_requester.isf apb_completer.isf apb_requester.fsm apb_completer.fsm apb_tb.fsm)) {
        ok(-f File::Spec->catfile($outdir, $artifact), "APB composition --outdir writes $artifact");
    }
    ok(-f $hdl, 'APB composition --output writes generated HDL');
    my $sv = slurp($hdl);
    like($sv, qr/\bmodule\s+apb_tb\b/, 'APB composition HDL contains the generated top module');
    like($sv, qr/\bmodule\s+apb_requester\b/, 'APB composition HDL contains the requester child module');
    like($sv, qr/\bmodule\s+apb_completer\b/, 'APB composition HDL contains the completer child module');
    unlike($sv, qr/\bbusy\b/, 'APB composition HDL does not expose deferred requester busy status');

    ok(-f sample_apb_composition_apb_path(), 'tracked runnable APB composition .apb sample exists');
    my $alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_apb_path());
    my $ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_ppif_path());
    is($alias->{kind}, 'protocol_intent.apb_composition', '.apb APB composition alias returns the composition kind');
    is_deeply($alias->{generated_ial1}{items}, $ppif->{generated_ial1}{items}, '.apb APB composition alias mirrors .ppif generated IAL1 artifacts');
    is_deeply($alias->{generated_ial0}{files}, $ppif->{generated_ial0}{files}, '.apb APB composition alias mirrors .ppif generated IAL0');
};

done_testing();

sub sample_apb_composition_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition.ppif');
}

sub sample_apb_composition_apb_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition.apb');
}

sub sample_apb_composition_ppif {
    return slurp(sample_apb_composition_ppif_path());
}

sub sorted {
    my ($values) = @_;
    return [sort @$values];
}

sub write_file {
    my ($path, $text) = @_;
    open my $fh, '>', $path or die "write $path: $!";
    print {$fh} $text;
    close $fh or die "close $path: $!";
}

sub slurp {
    my ($path) = @_;
    open my $fh, '<', $path or die "read $path: $!";
    my $text = do { local $/; <$fh> };
    close $fh or die "close $path: $!";
    return $text;
}
