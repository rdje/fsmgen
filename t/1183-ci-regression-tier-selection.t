#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use IPC::Cmd qw(run);

my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $ci = File::Spec->catfile($repo_root, 'bin', 'ci-regression');

sub run_ci {
    my (@args) = @_;
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => [$ci, @args],
    );

    return {
        success => $success,
        stdout  => join('', @{$stdout_buf || []}),
        stderr  => join('', @{$stderr_buf || []}),
        error   => $error_message,
    };
}

sub slurp {
    my ($path) = @_;
    open my $fh, '<', $path or die "cannot read $path: $!";
    my $text = do { local $/; <$fh> };
    close $fh or die "cannot close $path: $!";
    return $text;
}

subtest 'list mode advertises concrete quick and ISF test tiers' => sub {
    my $result = run_ci('--list');

    ok($result->{success}, '--list succeeds');
    is($result->{stderr}, '', '--list keeps stderr clean');
    like($result->{stdout}, qr/\Aquick tests:\n/, '--list starts with quick tests');
    like($result->{stdout}, qr/t\/01-regression\.t/, 'quick tier includes basic direct regression');
    like($result->{stdout}, qr/t\/13-composition-source-classification\.t/, 'quick tier includes composition classification');
    like($result->{stdout}, qr/t\/1091-isf-parser-apb-requester\.t/, 'quick tier includes ISF parsing smoke');
    like($result->{stdout}, qr/isf tests:\n/, '--list includes ISF tier');
    like($result->{stdout}, qr/t\/1246-isf-setter-syntax\.t/, 'ISF tier includes the latest ISF setter syntax test');

    my ($quick_block) = $result->{stdout} =~ /\Aquick tests:\n(.*?)isf tests:\n/s;
    my ($isf_block) = $result->{stdout} =~ /isf tests:\n(.*)\z/s;
    unlike($quick_block || '', qr/t\/1228-isf-spi-fixture-coverage\.t/, 'quick tier does not include the broader SPI-like fixture');
    like($isf_block || '', qr/t\/1228-isf-spi-fixture-coverage\.t/, 'ISF tier includes the SPI-like fixture coverage');
    unlike($quick_block || '', qr/t\/1309-isf-i2c-fixture-coverage\.t/, 'quick tier does not include the broader I2C-like fixture');
    like($isf_block || '', qr/t\/1309-isf-i2c-fixture-coverage\.t/, 'ISF tier includes the I2C-like fixture coverage');
    unlike($quick_block || '', qr/t\/1310-isf-burst-fixture-coverage\.t/, 'quick tier does not include the broader burst-reader fixture');
    like($isf_block || '', qr/t\/1310-isf-burst-fixture-coverage\.t/, 'ISF tier includes the burst-reader fixture coverage');
    unlike($quick_block || '', qr/t\/1311-isf-uart-fixture-coverage\.t/, 'quick tier does not include the broader UART-like fixture');
    like($isf_block || '', qr/t\/1311-isf-uart-fixture-coverage\.t/, 'ISF tier includes the UART-like fixture coverage');
    unlike($quick_block || '', qr/t\/1312-isf-phase-fixture-coverage\.t/, 'quick tier does not include the broader phase fixture');
    like($isf_block || '', qr/t\/1312-isf-phase-fixture-coverage\.t/, 'ISF tier includes the phase fixture coverage');
    unlike($quick_block || '', qr/t\/1313-isf-switch-fixture-coverage\.t/, 'quick tier does not include the broader switch fixture');
    like($isf_block || '', qr/t\/1313-isf-switch-fixture-coverage\.t/, 'ISF tier includes the switch fixture coverage');
    unlike($quick_block || '', qr/t\/1314-isf-when-fixture-coverage\.t/, 'quick tier does not include the broader when fixture');
    like($isf_block || '', qr/t\/1314-isf-when-fixture-coverage\.t/, 'ISF tier includes the when fixture coverage');
    unlike($quick_block || '', qr/t\/1315-isf-generated-composition-fixture-coverage\.t/, 'quick tier does not include the broader generated-composition fixture');
    like($isf_block || '', qr/t\/1315-isf-generated-composition-fixture-coverage\.t/, 'ISF tier includes the generated-composition fixture coverage');
    unlike($quick_block || '', qr/t\/1316-isf-rule-resource-fixture-coverage\.t/, 'quick tier does not include the broader rule/resource fixture');
    like($isf_block || '', qr/t\/1316-isf-rule-resource-fixture-coverage\.t/, 'ISF tier includes the rule/resource fixture coverage');
    unlike($quick_block || '', qr/t\/1317-isf-stage-contract-fixture-coverage\.t/, 'quick tier does not include the broader stage/contract fixture');
    like($isf_block || '', qr/t\/1317-isf-stage-contract-fixture-coverage\.t/, 'ISF tier includes the stage/contract fixture coverage');
    like($isf_block || '', qr/t\/1318-isf-shift-left-explicit-width\.t/, 'ISF tier includes the shift-left explicit-width coverage');
    unlike($quick_block || '', qr/t\/1319-isf-fifo-datapath-fixture-coverage\.t/, 'quick tier does not include the broader FIFO datapath fixture');
    like($isf_block || '', qr/t\/1319-isf-fifo-datapath-fixture-coverage\.t/, 'ISF tier includes the FIFO datapath fixture coverage');
    unlike($quick_block || '', qr/t\/1320-isf-fifo-controller-fixture-coverage\.t/, 'quick tier does not include the broader FIFO controller fixture');
    like($isf_block || '', qr/t\/1320-isf-fifo-controller-fixture-coverage\.t/, 'ISF tier includes the FIFO controller fixture coverage');
    unlike($quick_block || '', qr/t\/1321-isf-fifo-library-fixture-coverage\.t/, 'quick tier does not include the broader FIFO library fixture');
    like($isf_block || '', qr/t\/1321-isf-fifo-library-fixture-coverage\.t/, 'ISF tier includes the FIFO library fixture coverage');
    unlike($quick_block || '', qr/t\/1324-isf-atl-fixture-coverage\.t/, 'quick tier does not include the broader ATL temporary trigger-batch fixture');
    like($isf_block || '', qr/t\/1324-isf-atl-fixture-coverage\.t/, 'ISF tier includes the ATL temporary trigger-batch fixture coverage');
    unlike($quick_block || '', qr/t\/1325-isf-atl-data-route-fixture-coverage\.t/, 'quick tier does not include the broader ATL data-route fixture');
    like($isf_block || '', qr/t\/1325-isf-atl-data-route-fixture-coverage\.t/, 'ISF tier includes the ATL data-route fixture coverage');
    unlike($quick_block || '', qr/t\/1326-isf-atl-pin-ingress-fixture-coverage\.t/, 'quick tier does not include the broader ATL pin-ingress fixture');
    like($isf_block || '', qr/t\/1326-isf-atl-pin-ingress-fixture-coverage\.t/, 'ISF tier includes the ATL pin-ingress fixture coverage');
    unlike($quick_block || '', qr/t\/1327-isf-atl-pin-egress-fixture-coverage\.t/, 'quick tier does not include the broader ATL pin-egress fixture');
    like($isf_block || '', qr/t\/1327-isf-atl-pin-egress-fixture-coverage\.t/, 'ISF tier includes the ATL pin-egress fixture coverage');
    unlike($quick_block || '', qr/t\/1328-isf-atl-trigger-wait-fixture-coverage\.t/, 'quick tier does not include the broader ATL trigger-wait fixture');
    like($isf_block || '', qr/t\/1328-isf-atl-trigger-wait-fixture-coverage\.t/, 'ISF tier includes the ATL trigger-wait fixture coverage');
};

subtest 'dry-run modes select the expected command families' => sub {
    my $quick = run_ci('quick', '--dry-run');
    ok($quick->{success}, 'quick dry-run succeeds');
    is($quick->{stderr}, '', 'quick dry-run keeps stderr clean');
    like($quick->{stdout}, qr/==> Perl quick smoke suite/, 'quick dry-run selects quick suite');
    like($quick->{stdout}, qr/t\/1112-isf-public-interface-contract\.t/, 'quick dry-run includes ISF public contract smoke');
    like($quick->{stdout}, qr/==> mdBook build/, 'quick dry-run builds the book by default');

    my $smoke = run_ci('smoke', '--dry-run', '--no-book');
    ok($smoke->{success}, 'smoke alias dry-run succeeds');
    is($smoke->{stderr}, '', 'smoke alias dry-run keeps stderr clean');
    like($smoke->{stdout}, qr/==> Perl quick smoke suite/, 'smoke alias selects quick suite');
    like($smoke->{stdout}, qr/t\/01-regression\.t/, 'smoke alias includes basic direct regression');
    unlike($smoke->{stdout}, qr/mdBook build/, '--no-book suppresses book build for smoke alias');

    my $isf = run_ci('isf', '--dry-run', '--no-book');
    ok($isf->{success}, 'ISF dry-run succeeds');
    is($isf->{stderr}, '', 'ISF dry-run keeps stderr clean');
    like($isf->{stdout}, qr/==> Perl ISF regression suite/, 'ISF dry-run selects ISF suite');
    like($isf->{stdout}, qr/t\/1246-isf-setter-syntax\.t/, 'ISF dry-run includes latest ISF setter syntax test');
    like($isf->{stdout}, qr/t\/1228-isf-spi-fixture-coverage\.t/, 'ISF dry-run includes SPI-like fixture coverage');
    like($isf->{stdout}, qr/t\/1309-isf-i2c-fixture-coverage\.t/, 'ISF dry-run includes I2C-like fixture coverage');
    like($isf->{stdout}, qr/t\/1310-isf-burst-fixture-coverage\.t/, 'ISF dry-run includes burst-reader fixture coverage');
    like($isf->{stdout}, qr/t\/1311-isf-uart-fixture-coverage\.t/, 'ISF dry-run includes UART-like fixture coverage');
    like($isf->{stdout}, qr/t\/1312-isf-phase-fixture-coverage\.t/, 'ISF dry-run includes phase fixture coverage');
    like($isf->{stdout}, qr/t\/1313-isf-switch-fixture-coverage\.t/, 'ISF dry-run includes switch fixture coverage');
    like($isf->{stdout}, qr/t\/1314-isf-when-fixture-coverage\.t/, 'ISF dry-run includes when fixture coverage');
    like($isf->{stdout}, qr/t\/1315-isf-generated-composition-fixture-coverage\.t/, 'ISF dry-run includes generated-composition fixture coverage');
    like($isf->{stdout}, qr/t\/1316-isf-rule-resource-fixture-coverage\.t/, 'ISF dry-run includes rule/resource fixture coverage');
    like($isf->{stdout}, qr/t\/1317-isf-stage-contract-fixture-coverage\.t/, 'ISF dry-run includes stage/contract fixture coverage');
    like($isf->{stdout}, qr/t\/1318-isf-shift-left-explicit-width\.t/, 'ISF dry-run includes shift-left explicit-width coverage');
    like($isf->{stdout}, qr/t\/1319-isf-fifo-datapath-fixture-coverage\.t/, 'ISF dry-run includes FIFO datapath fixture coverage');
    like($isf->{stdout}, qr/t\/1320-isf-fifo-controller-fixture-coverage\.t/, 'ISF dry-run includes FIFO controller fixture coverage');
    like($isf->{stdout}, qr/t\/1321-isf-fifo-library-fixture-coverage\.t/, 'ISF dry-run includes FIFO library fixture coverage');
    like($isf->{stdout}, qr/t\/1324-isf-atl-fixture-coverage\.t/, 'ISF dry-run includes ATL temporary trigger-batch fixture coverage');
    like($isf->{stdout}, qr/t\/1325-isf-atl-data-route-fixture-coverage\.t/, 'ISF dry-run includes ATL data-route fixture coverage');
    like($isf->{stdout}, qr/t\/1326-isf-atl-pin-ingress-fixture-coverage\.t/, 'ISF dry-run includes ATL pin-ingress fixture coverage');
    like($isf->{stdout}, qr/t\/1327-isf-atl-pin-egress-fixture-coverage\.t/, 'ISF dry-run includes ATL pin-egress fixture coverage');
    like($isf->{stdout}, qr/t\/1328-isf-atl-trigger-wait-fixture-coverage\.t/, 'ISF dry-run includes ATL trigger-wait fixture coverage');
    unlike($isf->{stdout}, qr/mdBook build/, '--no-book suppresses book build');

    my $full = run_ci('full', '--dry-run');
    ok($full->{success}, 'full dry-run succeeds');
    is($full->{stderr}, '', 'full dry-run keeps stderr clean');
    like($full->{stdout}, qr/==> Perl regression suite/, 'full dry-run selects full suite');
    like($full->{stdout}, qr/\bprove\s+-I\s+perl\s+t\b/, 'full dry-run preserves default prove command');
};

subtest 'unknown modes fail with usage' => sub {
    my $result = run_ci('fast');

    ok(!$result->{success}, 'unknown mode fails');
    like($result->{stderr}, qr/ci-regression: unknown argument: fast/, 'unknown mode diagnostic names the argument');
    like($result->{stderr}, qr/Usage: \.\/bin\/ci-regression/, 'unknown mode prints usage');
};

subtest 'ISF tier remains ready for the next numbered band' => sub {
    my $script = slurp($ci);

    like($script, qr/t\/12\[0-9\]\[0-9\]-isf\*\.t/, 'ISF tier includes the 12xx ISF band');
    like($script, qr/t\/13\[0-9\]\[0-9\]-isf\*\.t/, 'ISF tier includes the 13xx ISF band');
    like($script, qr/shopt -s nullglob/, 'unmatched future ISF bands do not produce literal paths');
};

subtest 'smoke remains an explicit alias for quick turnaround' => sub {
    my $script = slurp($ci);

    like($script, qr/quick\|smoke\|isf\|full/, 'mode parser accepts smoke beside quick');
    like($script, qr/quick\|smoke\)\n\s+require_test_files "\$\{QUICK_TESTS\[@\]\}"/,
        'smoke and quick use the same curated test list');
};

done_testing();
