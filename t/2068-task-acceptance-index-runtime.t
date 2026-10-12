#!/usr/bin/env perl
use strict;
use warnings;

use File::Path qw(remove_tree);
use File::Spec;
use FindBin;
use JSON::PP ();
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use lib File::Spec->catdir($FindBin::Bin, 'lib');
use FSM::ProjectDataLocality qw(create_project_tempdir repository_root);
use FSM::Test::TaskAcceptanceIndexRuntime qw(run_index_case);

my $root = repository_root();

sub observed_case {
    my ($case) = @_;
    my $record = run_index_case($case);
    diag('acceptance index case: ' . JSON::PP->new->canonical->encode($record));
    is($record->{status}, 'checker_returned', "$case reaches the real checker")
        or return $record;
    ok($record->{main_index_conserved}, "$case leaves the main index unchanged");
    ok($record->{cleanup}{retired}, "$case retires its settled fixture");
    ok(!$record->{cleanup}{retained}, "$case leaves no fixture directory");
    for my $native (@{$record->{stages}}) {
        ok($native->{ok}, "$case fixture Git operation succeeds");
        is($native->{timeout_seconds}, 10, 'Git wall is fixed');
        is($native->{capture_limit_bytes}, 1_048_576, 'Git capture is fixed');
        ok($native->{cleanup}{leader_reaped} && $native->{cleanup}{group_gone},
            'Git process group settles');
    }
    my $checked = $record->{checker};
    is($checked->{timeout_seconds}, 10, 'checker wall is fixed');
    is($checked->{capture_limit_bytes}, 4_194_304, 'checker capture is fixed');
    ok($checked->{cleanup}{leader_reaped} && $checked->{cleanup}{group_gone},
        'checker process group settles');
    return $record;
}

subtest 'closed case API rejects command, path and bound substitutions' => sub {
    my @invalid = (
        [undef], ['git init'], ['../index'], [File::Spec->catfile($root, '.git', 'index')],
        ['audit_unknown'], [{ command => ['git', 'init'] }],
        ['existing_source', { timeout_seconds => 99 }],
    );
    for my $arguments (@invalid) {
        my $record = run_index_case(@$arguments);
        is($record->{status}, 'invocation_error', 'invalid invocation is rejected');
        is_deeply($record->{stages}, [], 'rejection starts no Git process');
        ok(!defined($record->{workspace}), 'rejection creates no fixture workspace');
        ok(!defined($record->{checker}), 'rejection starts no checker');
    }
};

subtest 'ordinary documentation stays outside implementation scope' => sub {
    my $record = observed_case('documentation');
    my $checked = $record->{checker} or return;
    if ($record->{registry_co_staged}) {
        is($checked->{exit_code}, 1, 'co-staged registry itself requires evidence');
        unlike($checked->{stdout} . $checked->{stderr}, qr/^    - README\.md$/m,
            'documentation is absent from classified implementation paths');
        note('The registry delta prevents a docs-only exit assertion until committed acceptance.');
    }
    else {
        is($checked->{exit_code}, 0, 'documentation-only staged paths are exempt');
        like($checked->{stdout}, qr/no configured implementation change staged/,
            'native exemption remains explicit');
    }
};

subtest 'implementation without owner preserves native nonzero truth' => sub {
    my $record = observed_case('existing_source');
    my $checked = $record->{checker} or return;
    is($checked->{exit_code}, 1, 'missing task owner is a native failure');
    ok(!$checked->{ok}, 'native failure is not promoted by fixture completion');
    like($checked->{stderr}, qr/no owning docs\/tasks\/\*\.md file is staged/,
        'native first refusal identifies ownership');
};

subtest 'fresh evidence succeeds and unchecked evidence fails' => sub {
    my $fresh = observed_case('fresh_owner');
    if (my $checked = $fresh->{checker}) {
        is($checked->{exit_code}, 0, 'fresh checked fixture evidence is accepted');
        like($checked->{stdout}, qr/root=git_history, no-regression=prove_summary/,
            'real checker matches independently declared fixture signatures');
    }
    my $unchecked = observed_case('unchecked_owner');
    if (my $checked = $unchecked->{checker}) {
        is($checked->{exit_code}, 1, 'unchecked fixture evidence is refused');
        like($checked->{stdout} . $checked->{stderr}, qr/fresh checked ROOT CAUSE box/,
            'failure identifies the unchecked cause');
    }
};

subtest 'old checked evidence cannot authorize a new implementation change' => sub {
    my $record = observed_case('stale_owner');
    my $checked = $record->{checker} or return;
    is($checked->{exit_code}, 1, 'unchanged historical boxes remain insufficient');
    like($checked->{stdout} . $checked->{stderr}, qr/fresh checked ROOT CAUSE box/,
        'native refusal requires current-slice freshness');
};

subtest 'caller environment cannot redirect repository or selected tools' => sub {
    my $directory = create_project_tempdir(purpose => 'acceptance-index-environment');
    my $injection = File::Spec->catfile($directory, 'bash-env');
    open my $out, '>', $injection or die $!;
    print {$out} "exit 93\n" or die $!;
    close $out or die $!;
    local $ENV{GIT_DIR} = File::Spec->catdir($directory, 'not-a-repository');
    local $ENV{GIT_OBJECT_DIRECTORY} = File::Spec->catdir($directory, 'not-objects');
    local $ENV{GIT_INDEX_FILE} = File::Spec->catfile($root, '.git', 'index');
    local $ENV{BASH_ENV} = $injection;
    local $ENV{PATH} = File::Spec->catdir($directory, 'not-tools');
    my %before = %ENV;
    my $record = observed_case('existing_source');
    is_deeply(\%ENV, \%before, 'adapter leaves caller environment unchanged');
    if (my $checked = $record->{checker}) {
        is($checked->{exit_code}, 1, 'selected native checker reaches its ownership refusal');
    }
    ok(!-e $ENV{GIT_DIR} && !-e $ENV{GIT_OBJECT_DIRECTORY},
        'redirected repository and object paths are never created');
};

subtest 'unsettled supervisor receipt retains its owned workspace' => sub {
    # This is a synthetic receipt-policy control, not a claim of native child survival.
    no warnings 'redefine';
    local *FSM::Test::TaskAcceptanceIndexRuntime::supervise_process = sub {
        return { ok => 0, status => 'timeout', diagnostic => 'synthetic unsettled receipt',
            cleanup => { leader_reaped => 0, group_gone => 0 } };
    };
    my $record = run_index_case('existing_source');
    is($record->{status}, 'preparation_failed', 'failed preparation remains failed');
    ok(!defined($record->{checker}), 'failed preparation never starts the checker');
    ok($record->{cleanup}{retained} && !$record->{cleanup}{retired},
        'unknown cleanup prevents workspace retirement');
    my $directory = File::Spec->catdir($root, $record->{workspace});
    ok(-d $directory, 'owned fixture is actually retained');
    # No child was launched by the synthetic control, so this exact fixture can be removed.
    remove_tree($directory);
    ok(!-e $directory, 'synthetic control leaves no retained fixture');
};

done_testing();
