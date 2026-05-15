#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP qw(decode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::ISFPublicInterfaceContract qw(build_isf_public_interface_contract);

my $repo_root = File::Spec->catdir($FindBin::Bin, '..');

my $expected_tested_by = [
    't/1096-isf-schedule-json-report.t',
    't/1112-isf-public-interface-contract.t',
    't/1113-isf-public-interface-contract-json-roundtrip-audit.t',
    't/1114-isf-public-interface-contract-defensive-copy-audit.t',
    't/1115-isf-public-interface-cli-manifest-audit.t',
    't/1116-isf-public-schedule-report-key-family-audit.t',
    't/1117-isf-public-lower-result-files-audit.t',
    't/1118-isf-public-parse-source-facade-audit.t',
    't/1119-isf-deterministic-dt-block-order.t',
    't/1120-isf-public-live-document-path-audit.t',
    't/1121-isf-public-cli-schedule-report-audit.t',
    't/1122-isf-public-cli-outdir-lowering-audit.t',
    't/1123-isf-public-cli-hdl-generation-audit.t',
    't/1124-isf-public-cli-strict-mode-audit.t',
    't/1125-isf-public-constructor-boundary-audit.t',
    't/1126-isf-public-parser-method-boundary-audit.t',
    't/1127-isf-public-scheduler-method-boundary-audit.t',
    't/1128-isf-public-multifile-schedule-report-audit.t',
    't/1129-isf-public-actor-shell-contract-audit.t',
    't/1130-isf-public-compile-issues-success-audit.t',
    't/1131-isf-public-top-level-discovery-audit.t',
    't/1132-isf-public-method-receiver-boundary-audit.t',
    't/1133-isf-public-constructor-receiver-boundary-audit.t',
    't/1134-isf-public-parse-file-path-boundary-audit.t',
    't/1135-isf-public-entrypoint-metadata-audit.t',
    't/1136-isf-public-cli-option-metadata-audit.t',
    't/1137-isf-public-method-name-metadata-audit.t',
    't/1138-isf-public-constructor-option-metadata-audit.t',
    't/1139-isf-public-lower-result-metadata-audit.t',
    't/1140-isf-public-schedule-report-metadata-audit.t',
    't/1141-isf-public-identity-flags-metadata-audit.t',
    't/1142-isf-public-guidance-metadata-audit.t',
    't/1143-isf-public-facade-shape-metadata-audit.t',
    't/1144-isf-public-tested-by-metadata-audit.t',
    't/1145-isf-public-scheduled-fsm-metadata-audit.t',
    't/1146-isf-public-dt-assignment-metadata-audit.t',
    't/1147-isf-public-report-dt-assignment-count-audit.t',
    't/1148-isf-public-storage-metadata-audit.t',
    't/1149-isf-public-transaction-metadata-audit.t',
    't/1150-isf-public-reset-metadata-audit.t',
    't/1151-isf-public-report-count-metadata-audit.t',
    't/1152-isf-public-report-scalar-metadata-audit.t',
    't/1153-isf-public-cli-success-metadata-audit.t',
    't/1154-isf-public-facade-return-metadata-audit.t',
    't/1155-isf-public-cli-strict-success-metadata-audit.t',
    't/1156-isf-public-lower-result-file-shape-audit.t',
    't/1157-isf-public-report-transaction-ordering-audit.t',
    't/1158-isf-public-report-dt-kind-metadata-audit.t',
    't/1159-isf-public-report-reset-shape-metadata-audit.t',
    't/1160-isf-public-actor-shell-value-shape-audit.t',
    't/1161-isf-public-facade-failure-diagnostic-metadata-audit.t',
    't/1162-isf-public-actor-shell-interface-shape-audit.t',
    't/1163-isf-public-actor-shell-transaction-shape-audit.t',
    't/1164-isf-public-actor-shell-actor-name-shape-audit.t',
    't/1165-isf-public-actor-shell-timing-shape-audit.t',
    't/1166-isf-public-actor-shell-rule-shape-audit.t',
    't/1167-isf-public-actor-shell-drive-shape-audit.t',
    't/1168-isf-rule-guard-factoring.t',
    't/1169-isf-rule-shorthand-guard.t',
    't/1171-isf-rule-trigger-fanin.t',
    't/1172-isf-rule-trigger-fanin-schedule-report.t',
    't/1173-isf-shift-right-explicit-width.t',
    't/1174-isf-extract-explicit-widths.t',
    't/1175-isf-contract-fail-closed.t',
    't/1176-isf-resource-priority-boundary.t',
    't/1177-isf-do-child-done-pulse.t',
    't/1178-isf-handshake-compatibility-boundary.t',
    't/1179-isf-phase-stage-boundary.t',
    't/1180-isf-unsupported-transaction-clause-boundary.t',
    't/1181-isf-rule-action-boundary.t',
    't/1182-isf-rule-trigger-target-boundary.t',
    't/1184-isf-child-transaction-target-boundary.t',
    't/1185-isf-transaction-name-boundary.t',
    't/1186-isf-rule-name-boundary.t',
    't/1187-isf-drive-name-boundary.t',
    't/1188-isf-interface-port-boundary.t',
    't/1189-isf-drive-parameter-boundary.t',
    't/1190-isf-rule-priority-target-boundary.t',
    't/1191-isf-actor-priority-target-boundary.t',
    't/1192-isf-singleton-actor-clause-boundary.t',
    't/1193-isf-drive-call-arity-boundary.t',
    't/1194-isf-drive-body-boundary.t',
    't/1195-isf-sample-clause-boundary.t',
    't/1196-isf-complete-clause-boundary.t',
    't/1197-isf-latency-clause-boundary.t',
    't/1198-isf-update-clause-boundary.t',
    't/1199-isf-shift-clause-boundary.t',
    't/1200-isf-assemble-clause-boundary.t',
    't/1201-isf-extract-clause-boundary.t',
    't/1202-isf-repeat-clause-boundary.t',
    't/1203-isf-await-sync-clause-boundary.t',
    't/1204-isf-child-composition-clause-boundary.t',
    't/1205-isf-switch-clause-boundary.t',
    't/1206-isf-when-clause-boundary.t',
    't/1209-isf-static-conflict-detection.t',
    't/1210-isf-priority-conflict-resolution.t',
    't/1211-isf-runtime-selector-conflict-instrumentation.t',
    't/1212-isf-schedule-report-compile-issues-projection.t',
    't/1213-isf-schedule-report-compatible-fanin-projection.t',
    't/1214-isf-rejected-conflict-diagnostics.t',
    't/1215-isf-spawn-parameter-binding.t',
    't/1216-isf-generated-composition-top.t',
    't/1217-isf-generated-composition-schedule-report.t',
    't/1218-isf-rule-slot-resource-arbitration.t',
    't/1219-isf-rule-transaction-priority.t',
    't/1220-isf-arbitration-schedule-report.t',
    't/1221-isf-rule-expression-assignment.t',
    't/1222-isf-rule-expression-conflict-report.t',
    't/1223-isf-stage-lowering.t',
    't/1224-isf-contract-lowering.t',
    't/1225-isf-stage-contract-schedule-report.t',
    't/1226-isf-data-width-storage-report.t',
    't/1227-isf-schedule-report-freeze-boundary.t',
    't/1228-isf-spi-fixture-coverage.t',
    't/1229-isf-compatibility-cli-parity.t',
    't/1230-isf-library-import-resolution.t',
    't/1231-isf-library-generated-top.t',
    't/1232-isf-actor-storage-declarations.t',
    't/1233-isf-rule-expression-guards.t',
    't/1234-isf-disjoint-rule-writes.t',
    't/1235-isf-fifo-same-cycle-update-matrix.t',
    't/1236-isf-bank-access-lowering.t',
    't/1237-isf-fifo-library-fixture.t',
    't/1238-isf-fifo-library-hdl-generation.t',
    't/1239-isf-library-catalog-contract.t',
    't/1240-isf-transaction-port-declarations.t',
];

subtest 'direct ISF tested_by metadata is exact and valid' => sub {
    assert_tested_by(
        build_isf_public_interface_contract()->{tested_by},
        'direct ISF public-interface contract',
    );
};

subtest 'manifest ISF tested_by metadata is exact and valid' => sub {
    my @views = (
        {
            label => 'in-process capability manifest',
            payload => build_capability_manifest(),
        },
        {
            label => 'CLI capability manifest',
            payload => run_capability_manifest('--capability-manifest'),
        },
        {
            label => 'CLI capability manifest alias',
            payload => run_capability_manifest('--emit-capability-manifest'),
        },
    );

    for my $view (@views) {
        my $label = $view->{label};
        assert_tested_by(
            $view->{payload}{embedding}{isf_public_interface}{tested_by},
            "$label ISF public-interface contract",
        );
    }
};

done_testing();

sub assert_tested_by {
    my ($tested_by, $label) = @_;

    is_deeply($tested_by, $expected_tested_by, "$label tested_by list is exact");
    assert_unique_test_paths($tested_by, "$label tested_by list");
}

sub assert_unique_test_paths {
    my ($values, $label) = @_;
    my %seen;

    ok(ref($values) eq 'ARRAY', "$label is an array");
    for my $value (@{$values || []}) {
        ok(!ref($value), "$label entry '$value' is scalar");
        next if ref($value);
        ok(length($value), "$label entry '$value' is non-empty");
        ok(!$seen{$value}++, "$label does not duplicate '$value'");
        ok(!File::Spec->file_name_is_absolute($value), "$label entry '$value' is repo-relative");
        like($value, qr{\At/[^/].*\.t\z}, "$label entry '$value' points at a test file");
        ok(-f repo_file($value), "$label entry '$value' exists on disk");
    }
}

sub run_capability_manifest {
    my ($mode) = @_;
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', $mode],
    );

    ok($success, "$mode succeeds");
    is(join('', @{$stderr_buf || []}), '', "$mode keeps stderr clean");

    return decode_json(join('', @{$stdout_buf || []}));
}

sub repo_file {
    my ($relpath) = @_;
    return File::Spec->catfile($repo_root, split m{/}, $relpath);
}
