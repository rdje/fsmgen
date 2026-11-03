#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Basename qw(basename);
use File::Path qw(make_path remove_tree);
use File::Spec;
use FindBin;
use IPC::Cmd qw(run);
use lib "$FindBin::Bin/../perl", "$FindBin::Bin/lib";
use FSM::Test::SourceQueryCoverage qw(build_source_query_cohort);

my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $ci = File::Spec->catfile($repo_root, 'bin', 'ci-regression');
my %dedicated_relpath = (
    0 => 't/1436-ial2-ppif-parser-cli.t',
    1 => 't/1437-axi-ial2-manager-capacity-status-generator.t',
    2 => 't/1598-vial-vhdl-osvvm-emission.t',
    3 => 't/1648-vial-architecture-scale-backend-emission-osvvm.t',
    4 => 't/1650-vial-architecture-scale-backend-emission-family-qualification.t',
);
my $dynamic_relpath = 't/1438-axi-ial2-manager-dynamic-transaction-id-focused.t';
my $dynamic_test = File::Spec->catfile(
    $repo_root,
    split(m{/}, $dynamic_relpath),
);
my %corpus_relpath = (
    296 => 't/296-regression-corpus-supported-behavior.t',
    301 => 't/301-check-json-supported-corpus.t',
    303 => 't/303-normalized-semantic-json-supported-corpus.t',
    1884 => 't/1884-semantic-source-query-runner.t',
);
my %corpus_test = map {
    $_ => File::Spec->catfile($repo_root, split m{/}, $corpus_relpath{$_})
} keys %corpus_relpath;
my %separately_hosted_relpath = map { $_ => 1 } (
    values(%dedicated_relpath),
    values(%corpus_relpath),
    $dynamic_relpath,
);
my $workflow = File::Spec->catfile(
    $repo_root,
    '.github',
    'workflows',
    'regression.yml',
);
my $pages_workflow = File::Spec->catfile(
    $repo_root,
    '.github',
    'workflows',
    'pages.yml',
);
my $knowledge_map_workflow = File::Spec->catfile(
    $repo_root,
    '.github',
    'workflows',
    'knowledge-map-gate.yml',
);
my $mdbook_installer = File::Spec->catfile(
    $repo_root,
    'scripts',
    'install_hosted_mdbook.sh',
);
my $gate_fixture_root = File::Spec->catdir(
    $repo_root,
    '.artifacts',
    'tmp',
    "ci-regression-gate-fixture-$$",
);

END {
    remove_tree($gate_fixture_root) if -d $gate_fixture_root;
}

sub run_ci {
    return run_ci_at($ci, @_);
}

sub run_ci_at {
    my ($ci_path, @args) = @_;
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => [$ci_path, @args],
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

sub write_raw {
    my ($path, $bytes) = @_;
    open my $fh, '>', $path or die "cannot write $path: $!";
    print {$fh} $bytes or die "cannot populate $path: $!";
    close $fh or die "cannot close $path: $!";
}

sub create_gate_fixture {
    remove_tree($gate_fixture_root) if -d $gate_fixture_root;
    make_path(
        File::Spec->catdir($gate_fixture_root, 'bin'),
        File::Spec->catdir($gate_fixture_root, 'scripts'),
    );

    my $fixture_ci = File::Spec->catfile(
        $gate_fixture_root, 'bin', 'ci-regression',
    );
    my $locality = File::Spec->catfile(
        $gate_fixture_root, 'scripts', 'project_data_locality_env.sh',
    );
    write_raw($fixture_ci, slurp($ci));
    write_raw(
        $locality,
        slurp(File::Spec->catfile(
            $repo_root, 'scripts', 'project_data_locality_env.sh',
        )),
    );
    chmod 0755, $fixture_ci, $locality
        or die "cannot make copied CI fixture executable: $!";

    my $stub = <<'STUB';
#!/usr/bin/env perl
use strict;
use warnings;
use File::Basename qw(basename);

my $base = basename($0);
my $key = $base eq 'materialize_vial_regression_promotion_gate_evidence.pl'
    ? ($ARGV[0] // 'missing')
    : $base eq 'verify_vial_regression_promotion_current_corpus.pl'
        ? 'corpus'
        : $base eq 'verify_vial_regression_promotion_budget_qualification.pl'
            ? 'qualification'
            : $base eq 'run_with_ram_guard.sh'
                ? 'guard'
                : $base eq 'run_vial_regression_promotion_gate.pl'
                    ? 'gate'
                    : die "unknown stub: $base\n";

my $log = $ENV{FSMGEN_CI_GATE_FIXTURE_LOG}
    // die "missing fixture log\n";
open my $log_fh, '>>', $log or die "cannot open fixture log: $!\n";
print {$log_fh} join(' ', $key, @ARGV), "\n"
    or die "cannot write fixture log: $!\n";
close $log_fh or die "cannot close fixture log: $!\n";

exit 23 if ($ENV{FSMGEN_CI_GATE_FIXTURE_FAIL} // '') eq $key;
if ($key eq 'guard') {
    shift @ARGV if @ARGV && $ARGV[0] eq '--';
    die "guard stub has no command\n" unless @ARGV;
    system {$ARGV[0]} @ARGV;
    exit 127 if $? == -1;
    exit 128 + ($? & 127) if $? & 127;
    exit $? >> 8;
}

print "{}\n";
exit 0;
STUB

    for my $name (qw(
        materialize_vial_regression_promotion_gate_evidence.pl
        verify_vial_regression_promotion_current_corpus.pl
        verify_vial_regression_promotion_budget_qualification.pl
        run_with_ram_guard.sh
        run_vial_regression_promotion_gate.pl
    )) {
        my $path = File::Spec->catfile(
            $gate_fixture_root, 'scripts', $name,
        );
        write_raw($path, $stub);
        chmod 0755, $path
            or die "cannot make gate fixture stub executable: $!";
    }

    return $fixture_ci;
}

sub run_gate_fixture {
    my ($fixture_ci, $failure) = @_;
    my $log = File::Spec->catfile($gate_fixture_root, 'gate.log');
    unlink $log if -e $log;
    local $ENV{FSMGEN_CI_GATE_FIXTURE_LOG} = $log;
    local $ENV{FSMGEN_CI_GATE_FIXTURE_FAIL};
    if (defined $failure) {
        $ENV{FSMGEN_CI_GATE_FIXTURE_FAIL} = $failure;
    } else {
        delete $ENV{FSMGEN_CI_GATE_FIXTURE_FAIL};
    }

    my $result = run_ci_at($fixture_ci, 'vial-gate', '--no-book');
    $result->{log} = -e $log ? slurp($log) : '';
    return $result;
}

sub run_dynamic_case_list {
    my (%args) = @_;
    local $ENV{FSMGEN_DYNAMIC_CASE_LIST_ONLY} = 1;
    local $ENV{FSMGEN_DYNAMIC_CASE_SHARD_INDEX};
    local $ENV{FSMGEN_DYNAMIC_CASE_SHARD_COUNT};
    delete $ENV{FSMGEN_DYNAMIC_CASE_SHARD_INDEX};
    delete $ENV{FSMGEN_DYNAMIC_CASE_SHARD_COUNT};
    delete $ENV{FSMGEN_DYNAMIC_CASE_FILTER};

    if (defined($args{index}) || defined($args{count})) {
        $ENV{FSMGEN_DYNAMIC_CASE_SHARD_INDEX} = $args{index};
        $ENV{FSMGEN_DYNAMIC_CASE_SHARD_COUNT} = $args{count};
    }

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => [$^X, $dynamic_test],
    );
    return {
        success => $success,
        stdout  => join('', @{$stdout_buf || []}),
        stderr  => join('', @{$stderr_buf || []}),
        error   => $error_message,
    };
}

sub run_corpus_workload_list {
    my (%args) = @_;
    my $test_id = $args{test_id};
    my $test_file = $corpus_test{$test_id}
        or die "unknown corpus test id: $test_id";

    local $ENV{FSMGEN_HOSTED_CORPUS_LIST_ONLY} = 1;
    local $ENV{FSMGEN_SOURCE_QUERY_ALL} = 1;
    local $ENV{FSMGEN_SOURCE_QUERY_SOURCES};
    delete $ENV{FSMGEN_SOURCE_QUERY_SOURCES};
    local $ENV{FSMGEN_HOSTED_CORPUS_SHARD_INDEX};
    local $ENV{FSMGEN_HOSTED_CORPUS_SHARD_COUNT};
    delete $ENV{FSMGEN_HOSTED_CORPUS_SHARD_INDEX};
    delete $ENV{FSMGEN_HOSTED_CORPUS_SHARD_COUNT};

    if (defined($args{index}) || defined($args{count})) {
        $ENV{FSMGEN_HOSTED_CORPUS_SHARD_INDEX} = $args{index};
        $ENV{FSMGEN_HOSTED_CORPUS_SHARD_COUNT} = $args{count};
    }

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => [$^X, $test_file],
    );
    return {
        success => $success,
        stdout  => join('', @{$stdout_buf || []}),
        stderr  => join('', @{$stderr_buf || []}),
        error   => $error_message,
    };
}

sub tracked_perl_tests {
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['git', '-C', $repo_root, 'ls-files', 't/*.t'],
    );
    die "cannot enumerate tracked Perl tests: $error_message"
        unless $success;
    die 'tracked Perl test inventory wrote to stderr: '
        . join('', @{$stderr_buf || []})
        if @{$stderr_buf || []};

    my $stdout = join('', @{$stdout_buf || []});
    return sort grep { length } split /\n/, $stdout;
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
    unlike($quick_block || '', qr/t\/1316-isf-rule-resource-fixture-coverage\.t/, 'quick tier does not include the broader rule/resource fixture');
    like($isf_block || '', qr/t\/1316-isf-rule-resource-fixture-coverage\.t/, 'ISF tier includes the rule/resource fixture coverage');
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
    unlike($quick_block || '', qr/t\/1329-isf-atl-trigger-batch-wait-fixture-coverage\.t/, 'quick tier does not include the broader ATL trigger-batch wait fixture');
    like($isf_block || '', qr/t\/1329-isf-atl-trigger-batch-wait-fixture-coverage\.t/, 'ISF tier includes the ATL trigger-batch wait fixture coverage');
    unlike($quick_block || '', qr/t\/1330-isf-atl-resolved-child-fixture-coverage\.t/, 'quick tier does not include the broader ATL resolved-child fixture');
    like($isf_block || '', qr/t\/1330-isf-atl-resolved-child-fixture-coverage\.t/, 'ISF tier includes the ATL resolved-child fixture coverage');
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
    like($isf->{stdout}, qr/t\/1316-isf-rule-resource-fixture-coverage\.t/, 'ISF dry-run includes rule/resource fixture coverage');
    like($isf->{stdout}, qr/t\/1318-isf-shift-left-explicit-width\.t/, 'ISF dry-run includes shift-left explicit-width coverage');
    like($isf->{stdout}, qr/t\/1319-isf-fifo-datapath-fixture-coverage\.t/, 'ISF dry-run includes FIFO datapath fixture coverage');
    like($isf->{stdout}, qr/t\/1320-isf-fifo-controller-fixture-coverage\.t/, 'ISF dry-run includes FIFO controller fixture coverage');
    like($isf->{stdout}, qr/t\/1321-isf-fifo-library-fixture-coverage\.t/, 'ISF dry-run includes FIFO library fixture coverage');
    like($isf->{stdout}, qr/t\/1324-isf-atl-fixture-coverage\.t/, 'ISF dry-run includes ATL temporary trigger-batch fixture coverage');
    like($isf->{stdout}, qr/t\/1325-isf-atl-data-route-fixture-coverage\.t/, 'ISF dry-run includes ATL data-route fixture coverage');
    like($isf->{stdout}, qr/t\/1326-isf-atl-pin-ingress-fixture-coverage\.t/, 'ISF dry-run includes ATL pin-ingress fixture coverage');
    like($isf->{stdout}, qr/t\/1327-isf-atl-pin-egress-fixture-coverage\.t/, 'ISF dry-run includes ATL pin-egress fixture coverage');
    like($isf->{stdout}, qr/t\/1328-isf-atl-trigger-wait-fixture-coverage\.t/, 'ISF dry-run includes ATL trigger-wait fixture coverage');
    like($isf->{stdout}, qr/t\/1329-isf-atl-trigger-batch-wait-fixture-coverage\.t/, 'ISF dry-run includes ATL trigger-batch wait fixture coverage');
    like($isf->{stdout}, qr/t\/1330-isf-atl-resolved-child-fixture-coverage\.t/, 'ISF dry-run includes ATL resolved-child fixture coverage');
    unlike($isf->{stdout}, qr/mdBook build/, '--no-book suppresses book build');

    my $full = run_ci('full', '--dry-run');
    ok($full->{success}, 'full dry-run succeeds');
    is($full->{stderr}, '', 'full dry-run keeps stderr clean');
    like($full->{stdout}, qr/==> Perl regression suite/, 'full dry-run selects full suite');
    like($full->{stdout}, qr/\bprove\s+-I\s+perl\s+t\b/, 'full dry-run preserves default prove command');
    like($full->{stdout}, qr/FSMGEN_SOURCE_QUERY_ALL=1\s+prove/, 'full mode explicitly selects the complete source-query cohort');
};

subtest 'selected and unsharded full modes own one ordered guarded gate lifecycle' => sub {
    my @gate_labels = (
        'VIAL regression-promotion evidence materialization',
        'VIAL regression-promotion current-corpus validation',
        'VIAL regression-promotion budget-qualification validation',
        'VIAL regression-promotion guarded gate',
        'VIAL regression-promotion evidence cleanup',
    );

    my $selected = run_ci('vial-gate', '--dry-run', '--no-book');
    ok($selected->{success}, 'selected VIAL gate dry-run succeeds');
    is($selected->{stderr}, '', 'selected VIAL gate dry-run keeps stderr clean');
    my @selected_labels = $selected->{stdout} =~ /^==> (.+)$/mg;
    is_deeply(
        \@selected_labels,
        \@gate_labels,
        'selected mode exposes only the ordered authenticated gate lifecycle',
    );
    my @selected_gate_runs = $selected->{stdout}
        =~ /run_vial_regression_promotion_gate\.pl\s+--run/g;
    is(scalar(@selected_gate_runs), 1, 'selected mode invokes the real gate exactly once');
    like(
        $selected->{stdout},
        qr{run_with_ram_guard\.sh\s+--\s+scripts/run_vial_regression_promotion_gate\.pl\s+--run},
        'selected mode puts the gate beneath the common RAM guard',
    );

    my $full = run_ci('full', '--dry-run', '--no-book');
    ok($full->{success}, 'unsharded full gate dry-run succeeds');
    is($full->{stderr}, '', 'unsharded full gate dry-run keeps stderr clean');
    my @full_labels = $full->{stdout} =~ /^==> (.+)$/mg;
    is_deeply(
        \@full_labels,
        ['Perl regression suite', @gate_labels],
        'unsharded full runs the gate lifecycle exactly once after ordinary regression',
    );
    my @full_gate_runs = $full->{stdout}
        =~ /run_vial_regression_promotion_gate\.pl\s+--run/g;
    is(scalar(@full_gate_runs), 1, 'unsharded full does not double-execute the gate');

    my $with_book = run_ci('vial-gate', '--dry-run');
    ok($with_book->{success}, 'selected VIAL gate retains the ordinary default book check');
    like($with_book->{stdout}, qr/==> mdBook build/, 'selected mode builds the book unless suppressed');
};

subtest 'focused modes and every hosted shard family stay gate-free' => sub {
    for my $mode (qw(quick smoke isf)) {
        my $result = run_ci($mode, '--dry-run', '--no-book');
        ok($result->{success}, "$mode dry-run succeeds");
        unlike(
            $result->{stdout},
            qr/VIAL regression-promotion|materialize_vial_regression|run_vial_regression_promotion_gate/,
            "$mode remains free of the expensive gate lifecycle",
        );
    }

    my @hosted = (
        '--hosted-file-shard=0/16',
        '--hosted-dedicated-shard=0/5',
        '--hosted-dynamic-shard=0/68',
        '--hosted-corpus-shard=301:0/16',
        '--hosted-corpus-shard=1884:0/16',
    );
    for my $option (@hosted) {
        my $result = run_ci('full', '--dry-run', '--no-book', $option);
        ok($result->{success}, "$option dry-run succeeds");
        unlike(
            $result->{stdout},
            qr/VIAL regression-promotion|materialize_vial_regression|run_vial_regression_promotion_gate/,
            "$option remains free of the unsharded local gate lifecycle",
        );
    }
};

subtest 'selected gate lifecycle propagates failure and always cleans successful materialization' => sub {
    my $fixture_ci = create_gate_fixture();

    my $success = run_gate_fixture($fixture_ci, undef);
    ok($success->{success}, 'copied selected gate lifecycle succeeds');
    is_deeply(
        [map { /^([^ ]+)/ ? $1 : () } grep { length } split /\n/, $success->{log}],
        [qw(materialize corpus qualification guard gate cleanup)],
        'successful copied lifecycle has one exact ordered command census',
    );

    my $materialize_failure = run_gate_fixture($fixture_ci, 'materialize');
    ok(!$materialize_failure->{success}, 'materialization failure propagates');
    like($materialize_failure->{error}, qr/exited with value 23\z/,
        'materialization failure status is retained');
    is($materialize_failure->{log}, "materialize materialize\n",
        'failed materialization does not claim a cleanup-owned receipt');

    for my $failure (qw(corpus qualification guard gate)) {
        my $result = run_gate_fixture($fixture_ci, $failure);
        ok(!$result->{success}, "$failure failure propagates");
        like($result->{error}, qr/exited with value 23\z/,
            "$failure failure status is retained");
        like($result->{log}, qr/^materialize materialize\n/, "$failure begins after materialization");
        like($result->{log}, qr/^cleanup cleanup$/m,
            "$failure still invokes receipt-bounded cleanup");
        my @cleanup = $result->{log} =~ /^cleanup cleanup$/mg;
        is(scalar(@cleanup), 1, "$failure invokes cleanup exactly once");
    }

    my $cleanup_failure = run_gate_fixture($fixture_ci, 'cleanup');
    ok(!$cleanup_failure->{success}, 'cleanup failure propagates after a successful gate');
    like($cleanup_failure->{error}, qr/exited with value 23\z/,
        'cleanup failure status is retained');
    like($cleanup_failure->{log}, qr/^gate --run$/m,
        'cleanup failure occurs after the gate has completed');
};

subtest 'selected gate mode and hosted boundary fail closed' => sub {
    my $case_variant = run_ci('VIAL-gate', '--dry-run', '--no-book');
    ok(!$case_variant->{success}, 'case-variant selected mode fails');
    like($case_variant->{stderr}, qr/unknown argument: VIAL-gate/,
        'case-variant diagnostic names the rejected mode');

    my $hosted = run_ci(
        'vial-gate', '--dry-run', '--no-book', '--hosted-file-shard=0/16',
    );
    ok(!$hosted->{success}, 'selected mode cannot acquire a hosted shard option');
    like($hosted->{stderr}, qr/hosted shards require full mode/,
        'selected/hosted mixing fails at the closed ownership boundary');
};

subtest 'hosted file shards form one exact disjoint full-suite inventory' => sub {
    my @tracked = tracked_perl_tests();
    my @expected = grep { !$separately_hosted_relpath{$_} } @tracked;
    my %seen;

    is(
        scalar(keys %separately_hosted_relpath),
        10,
        'ten exact tests have non-ordinary hosted ownership',
    );
    is_deeply(
        [sort(@expected, keys(%separately_hosted_relpath))],
        \@tracked,
        'ordinary and separately hosted file owners form the complete tracked test inventory',
    );

    for my $index (0 .. 15) {
        my $result = run_ci(
            'full',
            '--no-book',
            "--hosted-file-shard=$index/16",
            '--dry-run',
        );
        ok($result->{success}, "hosted file shard $index/16 dry-run succeeds");
        is($result->{stderr}, '', "hosted file shard $index/16 keeps stderr clean");
        like(
            $result->{stdout},
            qr/==> Perl regression file shard \Q$index\/16\E/,
            "hosted file shard $index/16 identifies itself",
        );
        my @selected = $result->{stdout} =~ m{\b(t/[^\s]+\.t)\b}g;
        ok(@selected, "hosted file shard $index/16 is non-empty");
        for my $test_file (@selected) {
            ok(!$seen{$test_file}++, "$test_file appears in only one hosted file shard");
        }
    }

    is_deeply(
        [sort keys %seen],
        \@expected,
        'sixteen hosted file shards cover every ordinary tracked Perl test exactly once',
    );
    for my $test_file (sort keys %separately_hosted_relpath) {
        ok(!$seen{$test_file}, "ordinary file shards exclude separately hosted $test_file");
    }
};

subtest 'hosted dedicated shards select the five exact outlier/provider tests' => sub {
    my @selected;
    for my $index (0 .. 4) {
        my $result = run_ci(
            'full',
            '--no-book',
            "--hosted-dedicated-shard=$index/5",
            '--dry-run',
        );
        ok($result->{success}, "hosted dedicated shard $index/5 dry-run succeeds");
        is($result->{stderr}, '', "hosted dedicated shard $index/5 keeps stderr clean");
        like(
            $result->{stdout},
            qr/==> Perl dedicated test \Q$index\/5\E/,
            "hosted dedicated shard $index/5 identifies itself",
        );
        my @test_files = $result->{stdout} =~ m{\b(t/[^\s]+\.t)\b}g;
        is_deeply(
            \@test_files,
            [$dedicated_relpath{$index}],
            "hosted dedicated shard $index/5 selects its exact test",
        );
        push @selected, @test_files;
    }

    is_deeply(
        [sort @selected],
        [sort values %dedicated_relpath],
        'dedicated coordinates cover all five outlier/provider tests exactly once',
    );
};

subtest 'hosted dynamic shards cover all canonical cases exactly once' => sub {
    my $all = run_dynamic_case_list();
    ok($all->{success}, 'unsharded dynamic case inventory succeeds');
    is($all->{stderr}, '', 'unsharded dynamic case inventory keeps stderr clean');
    my @all_cases = grep { length } split /\n/, $all->{stdout};
    is(scalar(@all_cases), 68, 'dynamic focused test exposes the current 68-case canonical inventory');

    my %seen;
    for my $index (0 .. 67) {
        my $dry_run = run_ci(
            'full',
            '--no-book',
            "--hosted-dynamic-shard=$index/68",
            '--dry-run',
        );
        ok($dry_run->{success}, "hosted dynamic shard $index/68 dry-run succeeds");
        is($dry_run->{stderr}, '', "hosted dynamic shard $index/68 keeps stderr clean");
        like(
            $dry_run->{stdout},
            qr/FSMGEN_DYNAMIC_CASE_SHARD_INDEX=\Q$index\E\s+FSMGEN_DYNAMIC_CASE_SHARD_COUNT=68/,
            "hosted dynamic shard $index/68 passes its exact coordinates",
        );

        my $listed = run_dynamic_case_list(index => $index, count => 68);
        ok($listed->{success}, "dynamic case shard $index/68 inventory succeeds");
        is($listed->{stderr}, '', "dynamic case shard $index/68 inventory keeps stderr clean");
        my @selected = grep { length } split /\n/, $listed->{stdout};
        is(scalar(@selected), 1, "dynamic case shard $index/68 selects one case");
        for my $case (@selected) {
            ok(!$seen{$case}++, "$case appears in only one dynamic case shard");
        }
    }

    is_deeply(
        [sort keys %seen],
        [sort @all_cases],
        'sixty-eight dynamic shards cover all canonical cases exactly once',
    );

    my $dynamic_source = slurp($dynamic_test);
    my @shared_guards = $dynamic_source =~ /\} if \$run_dynamic_shared_cases;/g;
    is(scalar(@shared_guards), 4, 'the four non-matrix dynamic checks execute only in shard zero');
};

subtest 'hosted corpus shards cover every selected workload exactly once' => sub {
    for my $test_id (sort keys %corpus_test) {
        my $all = run_corpus_workload_list(test_id => $test_id);
        ok($all->{success}, "unsharded corpus test $test_id workload inventory succeeds");
        is($all->{stderr}, '', "unsharded corpus test $test_id workload inventory keeps stderr clean");
        my @all_workloads = grep { length } split /\n/, $all->{stdout};
        ok(@all_workloads, "corpus test $test_id exposes a non-empty workload inventory");
        if ($test_id == 1884) {
            my $rows = build_source_query_cohort();
            is_deeply(\@all_workloads, [map {my $r = $_; map {"$_:$r->{source_id}"} @{$r->{query_kinds}}} @$rows],
                'source-query inventory covers every applicable query for every supported source');
        }
        if ($test_id == 301 || $test_id == 303) {
            unlike(
                $all->{stdout},
                qr/(?:^|:)feature\.vial_/m,
                "corpus test $test_id excludes tool-specific VIAL sources from the main CLI",
            );
            my @observation_metadata = grep {
                /verification_observation_metadata/
            } @all_workloads;
            is_deeply(
                \@observation_metadata,
                [
                    'default:feature.isf_verification_observation_metadata',
                    'strict:feature.isf_verification_observation_metadata',
                ],
                "corpus test $test_id selects the canonical duplicate-path ISF owner",
            );
        }

        my %seen;
        for my $index (0 .. 15) {
            my $dry_run = run_ci(
                'full',
                '--no-book',
                "--hosted-corpus-shard=$test_id:$index/16",
                '--dry-run',
            );
            ok($dry_run->{success}, "hosted corpus test $test_id shard $index/16 dry-run succeeds");
            is($dry_run->{stderr}, '', "hosted corpus test $test_id shard $index/16 keeps stderr clean");
            like(
                $dry_run->{stdout},
                qr/Perl supported-corpus test \Q$test_id\E entry shard \Q$index\/16\E/,
                "hosted corpus test $test_id shard $index/16 identifies itself",
            );
            like(
                $dry_run->{stdout},
                qr/FSMGEN_HOSTED_CORPUS_SHARD_INDEX=\Q$index\E\s+FSMGEN_HOSTED_CORPUS_SHARD_COUNT=16/,
                "hosted corpus test $test_id shard $index/16 passes exact coordinates",
            );
            like(
                $dry_run->{stdout},
                qr/\Q$corpus_relpath{$test_id}\E/,
                "hosted corpus test $test_id shard $index/16 selects its exact file",
            );
            like($dry_run->{stdout}, qr/FSMGEN_SOURCE_QUERY_ALL=1/, 'source-query shard forces complete cohort before partitioning')
                if $test_id == 1884;

            my $listed = run_corpus_workload_list(
                test_id => $test_id,
                index => $index,
                count => 16,
            );
            ok($listed->{success}, "corpus test $test_id shard $index/16 workload inventory succeeds");
            is($listed->{stderr}, '', "corpus test $test_id shard $index/16 workload inventory keeps stderr clean");
            my @selected = grep { length } split /\n/, $listed->{stdout};
            ok(@selected, "corpus test $test_id shard $index/16 selects workloads");
            for my $workload (@selected) {
                ok(!$seen{$workload}++, "$test_id:$workload appears in only one hosted corpus shard");
            }
        }

        is_deeply(
            [sort keys %seen],
            [sort @all_workloads],
            "sixteen hosted shards cover corpus test $test_id workloads exactly once",
        );
    }
};

subtest 'source-query dispatch enforces complete selection in actual child environments' => sub {
    my $fixture_ci = create_gate_fixture();
    make_path(File::Spec->catdir($gate_fixture_root, 't'));
    write_raw(File::Spec->catfile($gate_fixture_root, split m{/}, $corpus_relpath{1884}), "# Dispatch fixture only.\n");
    my $prove = File::Spec->catfile($gate_fixture_root, 'bin', 'prove');
    write_raw($prove, <<'PROVE');
#!/usr/bin/env perl
use strict;
use warnings;
print join('|', 'dispatch', $ENV{FSMGEN_SOURCE_QUERY_ALL} // '',
    $ENV{FSMGEN_HOSTED_CORPUS_SHARD_INDEX} // '', $ENV{FSMGEN_HOSTED_CORPUS_SHARD_COUNT} // '', @ARGV), "\n";
PROVE
    chmod 0755, $prove or die "make dispatch stub executable: $!";
    local $ENV{PATH} = File::Spec->catdir($gate_fixture_root, 'bin').":".$ENV{PATH};
    local $ENV{FSMGEN_SOURCE_QUERY_ALL} = 0;
    local $ENV{FSMGEN_CI_GATE_FIXTURE_LOG} = File::Spec->catfile($gate_fixture_root, 'dispatch-gate.log');
    my $hosted = run_ci_at($fixture_ci, 'full', '--no-book', '--hosted-corpus-shard=1884:2/16');
    ok($hosted->{success}, 'actual hosted dispatch succeeds without running a producer');
    is($hosted->{stderr}, '', 'hosted dispatch stderr is clean');
    like($hosted->{stdout}, qr{dispatch\|1\|2\|16\|-I\|perl\|t/1884-semantic-source-query-runner\.t},
        'child receives all-source mode, exact shard and only the source-query test');
    my $full = run_ci_at($fixture_ci, 'full', '--no-book');
    ok($full->{success}, 'actual full dispatch and stub gate lifecycle succeed');
    is($full->{stderr}, '', 'full dispatch stderr is clean');
    like($full->{stdout}, qr{dispatch\|1\|\|\|-I\|perl\|t\b},
        'full child receives all-source mode without stale shard coordinates');
};

subtest 'full source-query coverage refuses ambient narrowing before dispatch' => sub {
    for my $variable (qw(FSMGEN_SOURCE_QUERY_SOURCES FSMGEN_HOSTED_CORPUS_LIST_ONLY
        FSMGEN_HOSTED_CORPUS_SHARD_INDEX FSMGEN_HOSTED_CORPUS_SHARD_COUNT)) {
        for my $extra ([], ['--hosted-corpus-shard=1884:0/16']) {
            local $ENV{$variable} = $variable eq 'FSMGEN_SOURCE_QUERY_SOURCES' ? '[]' : '1';
            my $result = run_ci('full', '--no-book', '--dry-run', @$extra);
            ok(!$result->{success}, "$variable cannot narrow a full or hosted source-query claim");
            is($result->{stdout}, '', 'refusal occurs before dispatching any command');
            like($result->{stderr}, qr/coverage refuses ambient \Q$variable\E/, 'refusal names the exact narrowing control');
        }
    }
};

subtest 'hosted shard arguments fail closed' => sub {
    my $outside = run_ci('full', '--no-book', '--hosted-file-shard=16/16', '--dry-run');
    ok(!$outside->{success}, 'out-of-range file shard fails');
    like($outside->{stderr}, qr/index 16 is outside shard count 16/, 'out-of-range diagnostic is exact');

    my $dedicated_outside = run_ci(
        'full',
        '--no-book',
        '--hosted-dedicated-shard=5/5',
        '--dry-run',
    );
    ok(!$dedicated_outside->{success}, 'out-of-range dedicated shard fails');
    like(
        $dedicated_outside->{stderr},
        qr/--hosted-dedicated-shard index 5 is outside shard count 5/,
        'out-of-range dedicated diagnostic is exact',
    );

    my $dedicated_wrong_count = run_ci(
        'full',
        '--no-book',
        '--hosted-dedicated-shard=0/6',
        '--dry-run',
    );
    ok(!$dedicated_wrong_count->{success}, 'wrong dedicated shard count fails');
    like(
        $dedicated_wrong_count->{stderr},
        qr/--hosted-dedicated-shard requires I\/5: 0\/6/,
        'dedicated count diagnostic locks the exact closed coordinate set',
    );

    my $corpus_outside = run_ci(
        'full',
        '--no-book',
        '--hosted-corpus-shard=301:16/16',
        '--dry-run',
    );
    ok(!$corpus_outside->{success}, 'out-of-range corpus shard fails');
    like(
        $corpus_outside->{stderr},
        qr/--hosted-corpus-shard 301 index 16 is outside shard count 16/,
        'out-of-range corpus diagnostic is exact',
    );

    my $unknown_corpus = run_ci(
        'full',
        '--no-book',
        '--hosted-corpus-shard=999:0/16',
        '--dry-run',
    );
    ok(!$unknown_corpus->{success}, 'unknown corpus test id fails');
    like(
        $unknown_corpus->{stderr},
        qr/requires T:I\/N with T in 296,301,303,1884/,
        'unknown corpus test diagnostic names the closed test set',
    );

    my $book = run_ci('full', '--hosted-file-shard=0/16', '--dry-run');
    ok(!$book->{success}, 'hosted shard without --no-book fails');
    like($book->{stderr}, qr/hosted shards require --no-book/, 'book-separation diagnostic is exact');

    my $mixed = run_ci(
        'full',
        '--no-book',
        '--hosted-file-shard=0/16',
        '--hosted-corpus-shard=301:0/16',
        '--dry-run',
    );
    ok(!$mixed->{success}, 'mixed hosted shard families fail');
    like($mixed->{stderr}, qr/mutually exclusive/, 'mixed-family diagnostic is exact');
};

subtest 'hosted workflow runs every shard family to a terminal aggregate' => sub {
    my $yaml = slurp($workflow);
    my @non_fail_fast = $yaml =~ /fail-fast:\s+false/g;
    my ($book_job) = $yaml =~ /\n  book:(.*?)\n  perl_files:/s;
    my ($file_job) = $yaml =~ /\n  perl_files:(.*?)\n  perl_dedicated:/s;
    my ($dedicated_job) = $yaml =~ /\n  perl_dedicated:(.*?)\n  perl_corpus:/s;
    my ($corpus_job) = $yaml =~ /\n  perl_corpus:(.*?)\n  perl_dynamic:/s;
    my ($dynamic_job) = $yaml =~ /\n  perl_dynamic:(.*?)\n  vial_gate:/s;
    my ($gate_job) = $yaml =~ /\n  vial_gate:(.*?)\n  build:/s;

    is(scalar(@non_fail_fast), 4, 'all four hosted Perl matrices disable fail-fast cancellation');
    like($yaml, qr/timeout-minutes:\s+300/, 'long-running shard jobs have a five-hour ceiling');
    like($file_job || '', qr/runs-on:\s+ubuntu-24\.04/, 'ordinary shards pin the Ubuntu Noble package base');
    like(
        $file_job || '',
        qr/fetch-depth:\s+0/,
        'ordinary shards fetch complete history for retained-object tests',
    );
    unlike(
        $book_job || '',
        qr/fetch-depth:\s+0/,
        'mdBook job retains the default shallow checkout',
    );
    unlike(
        $dynamic_job || '',
        qr/fetch-depth:\s+0/,
        'dynamic shards retain the default shallow checkout',
    );
    unlike(
        $dedicated_job || '',
        qr/fetch-depth:\s+0/,
        'dedicated shards retain the default shallow main checkout',
    );
    unlike(
        $corpus_job || '',
        qr/fetch-depth:\s+0/,
        'corpus shards retain the default shallow checkout',
    );
    like(
        $file_job || '',
        qr/FSMGEN_CI_IVERILOG_APT_VERSION:\s+'12\.0-2build2'/,
        'ordinary shards pin the Icarus Verilog package revision',
    );
    like(
        $file_job || '',
        qr/FSMGEN_CI_VERILATOR_APT_VERSION:\s+'5\.020-1'/,
        'ordinary shards pin the Verilator package revision',
    );
    like(
        $file_job || '',
        qr/FSMGEN_CI_YOSYS_APT_VERSION:\s+'0\.33-5build2'/,
        'ordinary shards pin the Yosys package revision',
    );
    like(
        $file_job || '',
        qr/apt-get install --yes --no-install-recommends.*?iverilog=.*?verilator=.*?yosys=/s,
        'ordinary shards install all external HDL validation tools',
    );
    my @package_revision_checks = ($file_job || '') =~ /dpkg-query --show --showformat=/g;
    is(scalar(@package_revision_checks), 3, 'ordinary shards verify all installed package revisions');
    unlike(
        $dynamic_job || '',
        qr/Install hosted HDL validation tools|apt-get install/,
        'dynamic shards avoid unrelated HDL tool installation',
    );
    unlike(
        $corpus_job || '',
        qr/Install hosted HDL validation tools|apt-get install|OsvvmLibraries/,
        'corpus shards avoid unrelated HDL tools and provider materialization',
    );
    like(
        $gate_job || '',
        qr/runs-on:\s+ubuntu-24\.04/,
        'the unsharded VIAL gate pins its hosted platform',
    );
    like(
        $gate_job || '',
        qr/timeout-minutes:\s+300/,
        'the unsharded VIAL gate has the bounded long-job ceiling',
    );
    unlike(
        $gate_job || '',
        qr/apt-get|Install hosted HDL validation tools/,
        'the VIAL gate installs no substitute runtime provider package',
    );
    like(
        $gate_job || '',
        qr/command -v verilator.*?test ! -e \.artifacts\/cache\/providers\/ghdl\/6\.0\.0\/llvm-jit-tool\/ghdl-llvm-jit-6\.0\.0-macos15-aarch64\/bin\/ghdl.*?test ! -e \.artifacts\/cache\/providers\/ghdl\/6\.0\.0\/llvm-jit-archive\/ghdl-llvm-jit-6\.0\.0-macos15-aarch64\.tar\.gz/s,
        'the VIAL gate rejects ambient Verilator and both exact GHDL provider coordinates',
    );
    like(
        $gate_job || '',
        qr/test ! -e \.artifacts\/qualification\/vial-scale\/v2\/regression-promotion-corpus-v1.*?test ! -e \.artifacts\/qualification\/vial-scale\/v2\/regression-promotion-budget-qualification-v1.*?test ! -e \.artifacts\/tmp\/vial-scale\/regression-promotion-gate-evidence-transport\/v1/s,
        'the VIAL gate proves authenticated evidence coordinates absent before claiming cleanup ownership',
    );
    like(
        $gate_job || '',
        qr/git clone --recursive --branch 2026\.05 --single-branch\s+https:\/\/github\.com\/OSVVM\/OsvvmLibraries\.git\s+\.artifacts\/cache\/providers\/osvvm\/2026\.05\/source.*?2f7c391051dfb11890fa4bdbda9918d1db492250/s,
        'the VIAL gate materializes and verifies exact OSVVM 2026.05',
    );
    like(
        $gate_job || '',
        qr{\./bin/ci-regression\s+vial-gate\s+--no-book},
        'the hosted family uses the public selected-important-step gate command',
    );
    like(
        $gate_job || '',
        qr{scripts/run_with_ram_guard\.sh\s+--\s+scripts/verify_vial_regression_promotion_hosted_result\.pl},
        'the hosted family independently validates the stored result beneath the guard',
    );
    like(
        $gate_job || '',
        qr/name:\s+Clean hosted VIAL gate state\s+if:\s+\$\{\{ always\(\) \}\}.*?materialize_vial_regression_promotion_gate_evidence\.pl cleanup.*?rm -rf \.artifacts\/cache\/providers\/osvvm\/2026\.05\/source.*?rm -rf \.artifacts\/qualification\/vial-scale\/v2\/regression-promotion-gate-v1\/current.*?rm -rf \.artifacts\/tmp\/vial-scale\/regression-promotion-gate-publication\/v1/s,
        'the always cleanup covers owned evidence, provider, result, and staging coordinates',
    );
    like(
        $yaml,
        qr/shard:\s+\[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15\]/,
        'workflow schedules all sixteen ordinary file shards',
    );
    like(
        $dedicated_job || '',
        qr/runs-on:\s+ubuntu-24\.04/,
        'dedicated shards use the pinned Noble package base',
    );
    like(
        $dedicated_job || '',
        qr/include:\s*\n\s+- shard:\s+0.*?- shard:\s+1.*?- shard:\s+2.*?- shard:\s+3.*?- shard:\s+4/s,
        'workflow schedules all five exact dedicated coordinates',
    );
    like(
        $dedicated_job || '',
        qr/- shard:\s+0\s+install_hdl_tools:\s+true.*?- shard:\s+1\s+install_hdl_tools:\s+false.*?- shard:\s+2\s+install_hdl_tools:\s+false.*?- shard:\s+3\s+install_hdl_tools:\s+false.*?- shard:\s+4\s+install_hdl_tools:\s+false.*?Install dedicated HDL validation tools.*?if:\s+\$\{\{ matrix\.install_hdl_tools \}\}.*?verilator=.*?yosys=/s,
        'only dedicated t1436 receives its required pinned HDL tools',
    );
    like(
        $dedicated_job || '',
        qr/FSMGEN_CI_VERILATOR_APT_VERSION:\s+'5\.020-1'.*?FSMGEN_CI_YOSYS_APT_VERSION:\s+'0\.33-5build2'/s,
        'dedicated t1436 retains exact Verilator and Yosys revisions',
    );
    like(
        $dedicated_job || '',
        qr/- shard:\s+0.*?materialize_osvvm:\s+false.*?- shard:\s+1.*?materialize_osvvm:\s+false.*?- shard:\s+2.*?materialize_osvvm:\s+true.*?- shard:\s+3.*?materialize_osvvm:\s+true.*?- shard:\s+4.*?materialize_osvvm:\s+true.*?Materialize exact OSVVM 2026\.05.*?if:\s+\$\{\{ matrix\.materialize_osvvm \}\}.*?git clone --recursive --branch 2026\.05 --single-branch\s+https:\/\/github\.com\/OSVVM\/OsvvmLibraries\.git\s+\.artifacts\/cache\/providers\/osvvm\/2026\.05\/source/s,
        'exactly t1598, t1648, and t1650 materialize the repository-local OSVVM provider',
    );
    like(
        $dedicated_job || '',
        qr/2f7c391051dfb11890fa4bdbda9918d1db492250/,
        'dedicated provider setup verifies the immutable OSVVM root commit',
    );
    like(
        $corpus_job || '',
        qr/test:\s+\[296, 301, 303, 1884\]/,
        'workflow schedules all four supported-corpus tests',
    );
    like(
        $corpus_job || '',
        qr/shard:\s+\[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15\]/,
        'workflow schedules all sixteen entry coordinates per corpus test',
    );
    like(
        $corpus_job || '',
        qr/--hosted-corpus-shard\s+"\$\{\{ matrix\.test \}\}:\$\{\{ matrix\.shard \}\}\/16"/,
        'corpus matrix passes both exact dimensions to the CI driver',
    );
    my ($dynamic_matrix) = $yaml =~ /perl_dynamic:.*?matrix:\s*\n\s+shard:\s*\n(.*?)\n\s+steps:/s;
    my @dynamic_shards = ($dynamic_matrix || '') =~ /^\s+-\s+(\d+)\s*$/mg;
    is_deeply(\@dynamic_shards, [0 .. 67], 'workflow schedules all sixty-eight dynamic case shards');
    like($yaml, qr/if:\s+\$\{\{ always\(\) \}\}/, 'aggregate runs after success or failure');
    like(
        $yaml,
        qr/needs:\s+\[doctrines, book, perl_files, perl_dedicated, perl_corpus, perl_dynamic, vial_gate\]/,
        'aggregate waits for every required CI family',
    );
    for my $result_name (qw(
        DOCTRINES_RESULT BOOK_RESULT PERL_FILES_RESULT PERL_DEDICATED_RESULT
        PERL_CORPUS_RESULT PERL_DYNAMIC_RESULT VIAL_GATE_RESULT
    )) {
        like($yaml, qr/\Q$result_name\E:/, "aggregate consumes $result_name");
    }
};

subtest 'hosted workflows pin audited actions and exact official mdBook' => sub {
    my %yaml = (
        regression    => slurp($workflow),
        pages         => slurp($pages_workflow),
        knowledge_map => slurp($knowledge_map_workflow),
    );
    my $all = join "\n", values %yaml;

    my %pins = (
        'actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1' => 9,
        'shogo82148/actions-setup-perl@53e33bb27be492a926eee378e8a5f7ff6618b061' => 5,
        'actions/configure-pages@45bfe0192ca1faeb007ade9deae92b16b8254a0d' => 1,
        'actions/upload-pages-artifact@fc324d3547104276b827a68afc52ff2a11cc49c9' => 1,
        'actions/deploy-pages@cd2ce8fcbc39b97be8ca5fce6e763baed58fa128' => 1,
    );
    for my $pin (sort keys %pins) {
        my @matches = $all =~ /\Q$pin\E/g;
        is(scalar(@matches), $pins{$pin}, "$pin has the exact expected workflow use count");
    }

    my @uses = $all =~ /^\s*uses:\s+(\S+)/mg;
    is(scalar(@uses), 17, 'all seventeen direct workflow action uses are inventoried');
    for my $use (@uses) {
        like($use, qr/\A[^@\s]+\@[0-9a-f]{40}\z/, "$use is pinned to an immutable commit");
    }
    unlike($all, qr/^\s*uses:\s+\S+\@v[0-9]/m, 'no direct action use floats on a movable major tag');
    unlike($all, qr/ACTIONS_ALLOW_USE_UNSECURE_NODE_VERSION/, 'workflows do not enable an insecure Node fallback');
    unlike($all, qr/peaceiris\/actions-mdbook/, 'workflows do not depend on the broken mdBook setup action');

    for my $owner (qw(regression pages)) {
        like(
            $yaml{$owner},
            qr/run:\s+bash scripts\/install_hosted_mdbook\.sh.*?\.artifacts\/cache\/tools\/mdbook\/0\.5\.4\/mdbook test docs\/book.*?\.artifacts\/cache\/tools\/mdbook\/0\.5\.4\/mdbook build docs\/book/s,
            "$owner workflow installs, tests, and builds with exact repository-local mdBook 0.5.4",
        );
    }

    my $installer = slurp($mdbook_installer);
    like($installer, qr/mdbook_version='0\.5\.4'/, 'installer pins mdBook 0.5.4');
    like(
        $installer,
        qr/asset_name="mdbook-v\$\{mdbook_version\}-x86_64-unknown-linux-gnu\.tar\.gz"/,
        'installer selects the official Linux GNU release asset',
    );
    like($installer, qr/asset_size='4822940'/, 'installer pins the published archive size');
    like(
        $installer,
        qr/asset_sha256='3f28de05dafca9d0f2eab99c662116b0e37b89b1d96a08f8f430b9eeae958cd7'/,
        'installer pins the published archive SHA-256',
    );
    like(
        $installer,
        qr{https://github\.com/rust-lang/mdBook/releases/download/v\$\{mdbook_version\}/\$\{asset_name\}},
        'installer downloads only from the official mdBook release owner',
    );
    like(
        $installer,
        qr/tool_root="\.artifacts\/cache\/tools\/mdbook\/\$\{mdbook_version\}"/,
        'installer keeps the hosted tool beneath a repository-relative artifact root',
    );
    like($installer, qr/sha256sum --check --strict/, 'installer verifies SHA-256 before extraction');
    like(
        $installer,
        qr/actual_version.*?mdbook v\$\{mdbook_version\}/s,
        'installer fails closed unless the extracted binary reports the pinned version',
    );
    like(
        $yaml{pages},
        qr/actions\/upload-pages-artifact\@fc324d3547104276b827a68afc52ff2a11cc49c9.*?path:\s+docs\/book\/book\s+include-hidden-files:\s+true/s,
        'Pages upload retains the prior hidden-file archive scope under v5',
    );
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

    like($script, qr/quick\|smoke\|isf\|vial-gate\|full/,
        'mode parser accepts smoke beside quick and the selected VIAL gate');
    like($script, qr/quick\|smoke\)\n\s+require_test_files "\$\{QUICK_TESTS\[@\]\}"/,
        'smoke and quick use the same curated test list');
};

subtest 'pre-push selects critical downstream checks without exhaustive families' => sub {
    my $result = run_ci('pre-push', '--dry-run');
    ok($result->{success}, 'pre-push dry run succeeds');
    is($result->{stderr}, '', 'pre-push keeps stderr clean');
    my @selected = $result->{stdout} =~ m{(t/[^\s]+\.t)}g;
    is_deeply(\@selected, [qw(
        t/01-regression.t
        t/03-assignment-intent-metadata.t
        t/13-composition-source-classification.t
        t/29-language-contract-core-forms.t
        t/84-composition-external-fsm-child-sources.t
        t/1091-isf-parser-apb-requester.t
        t/1094-isf-scheduler-module-header.t
        t/1112-isf-public-interface-contract.t
        t/208-enable-graph-ast-support.t
        t/1183-ci-regression-tier-selection.t
        t/1435-axi-ial2-valid-ready-generator.t
        t/1473-ial2-ahb-requester.t
        t/1475-ial2-ahb-subordinate.t
        t/1500-ial2-axi-w-driver.t
        t/1505-ial2-axi-r-beat-acceptor.t
        t/1548-source-hir-phase-control.t
        t/1555-vial-public-source-tooling.t
        t/1556-vial-public-planning-artifacts.t
        t/1867-isf-apb-completion-outputs.t
        t/1885-semantic-source-query-oracles.t
        t/1892-explicit-reset-hdl-behavior.t
        t/2302-process-group-admission-order.t
    )], 'closed selection protects public outputs, timing, reports and containment');
    like($result->{stdout}, qr/Perl critical downstream suite/, 'selected scope is explicit');
    like($result->{stdout}, qr/--strict\s+--check\s+--json\s+ppif\/apb_completer\.ppif/,
        'APB target also reaches the public strict CLI');
    like($result->{stdout}, qr/--strict\s+--verify-hdl\s+ppif\/apb_completer\.ppif/,
        'APB target reaches real external HDL validation');
    like($result->{stdout}, qr/==> mdBook build/, 'normal pre-push includes the book');
    unlike($result->{stdout}, qr/VIAL regression-promotion|t\/(?:143[678]|147[012]|296|301|303|1884)-/,
        'exhaustive protocol, corpus and scale families stay outside pre-push');
    unlike($result->{stdout}, qr/prove\s+-I\s+perl\s+t\s*$/m,
        'pre-push never invokes the complete Perl directory');
    my $listed = run_ci('--list');
    like($listed->{stdout}, qr/pre-push tests:\n/, 'selection is discoverable');
    my $sharded = run_ci('pre-push', '--hosted-file-shard=0/16', '--no-book', '--dry-run');
    ok(!$sharded->{success}, 'pre-push cannot masquerade as a full hosted shard');
    like($sharded->{stderr}, qr/hosted shards require full mode/, 'scope refusal is explicit');
};

done_testing();
