#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use IPC::Cmd qw(run);

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
};

subtest 'hosted file shards form one exact disjoint full-suite inventory' => sub {
    my @tracked = tracked_perl_tests();
    my @expected = grep { !$separately_hosted_relpath{$_} } @tracked;
    my %seen;

    is(
        scalar(keys %separately_hosted_relpath),
        9,
        'nine exact tests have non-ordinary hosted ownership',
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
        qr/requires T:I\/N with T in 296,301,303/,
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
    my ($dynamic_job) = $yaml =~ /\n  perl_dynamic:(.*?)\n  build:/s;

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
        qr/test:\s+\[296, 301, 303\]/,
        'workflow schedules all three supported-corpus tests',
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
        qr/needs:\s+\[doctrines, book, perl_files, perl_dedicated, perl_corpus, perl_dynamic\]/,
        'aggregate waits for every required CI family',
    );
    for my $result_name (qw(
        DOCTRINES_RESULT BOOK_RESULT PERL_FILES_RESULT PERL_DEDICATED_RESULT
        PERL_CORPUS_RESULT PERL_DYNAMIC_RESULT
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
        'actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1' => 8,
        'shogo82148/actions-setup-perl@53e33bb27be492a926eee378e8a5f7ff6618b061' => 4,
        'actions/configure-pages@45bfe0192ca1faeb007ade9deae92b16b8254a0d' => 1,
        'actions/upload-pages-artifact@fc324d3547104276b827a68afc52ff2a11cc49c9' => 1,
        'actions/deploy-pages@cd2ce8fcbc39b97be8ca5fce6e763baed58fa128' => 1,
    );
    for my $pin (sort keys %pins) {
        my @matches = $all =~ /\Q$pin\E/g;
        is(scalar(@matches), $pins{$pin}, "$pin has the exact expected workflow use count");
    }

    my @uses = $all =~ /^\s*uses:\s+(\S+)/mg;
    is(scalar(@uses), 15, 'all fifteen direct workflow action uses are inventoried');
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

    like($script, qr/quick\|smoke\|isf\|full/, 'mode parser accepts smoke beside quick');
    like($script, qr/quick\|smoke\)\n\s+require_test_files "\$\{QUICK_TESTS\[@\]\}"/,
        'smoke and quick use the same curated test list');
};

done_testing();
