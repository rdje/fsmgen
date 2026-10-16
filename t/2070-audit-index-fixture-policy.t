#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use JSON::PP ();
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::Test::TaskAcceptanceIndexRuntime qw(run_index_case);

sub observed {
    my ($case, $candidate, $owner) = @_;
    my $record = run_index_case($case);
    diag('audit fixture policy: ' . JSON::PP->new->canonical->encode($record));
    is($record->{status}, 'checker_returned', "$case reaches the real checker")
        or return;
    is($record->{schema}, 'fsmgen.test.task_acceptance_index_case.v1', 'original schema retains');
    ok($record->{main_index_conserved}, 'primary index bytes retain');
    ok($record->{cleanup}{retired} && !$record->{cleanup}{retained}, 'settled workspace retires');
    my %inputs = map { $_->{path} => $_->{body} } @{$record->{inputs}};
    is($inputs{$candidate}, "# owned index fixture\n", 'exact literal candidate is staged');
    ok(grep($_ eq $candidate, @{$record->{staged_paths}}), 'native Git staged paths contain candidate');
    if ($owner eq 'fresh') {
        my $task = $inputs{'docs/tasks/INDEX-ACCEPTANCE-FIXTURE.md'};
        like($task, qr/^- \[x\] \*\*ROOT CAUSE/m, 'fresh cause is literal fixture input');
        like($task, qr/^- \[x\] \*\*ADDRESSED/m, 'fresh addressed box is literal fixture input');
        like($task, qr/^- \[x\] \*\*NO REGRESSION/m, 'fresh regression is literal fixture input');
    }
    elsif ($owner eq 'unchecked') {
        like($inputs{'docs/tasks/INDEX-ACCEPTANCE-FIXTURE.md'}, qr/^- \[ \] \*\*ROOT CAUSE/m,
            'unchecked evidence remains unchecked');
    }
    elsif ($owner eq 'stale') {
        like($inputs{'docs/tasks/TASK-ACCEPTANCE-PORTABLE-DOCTRINE.md'},
            qr/Index fixture changes only this unrelated note\.\n\z/,
            'stale evidence changes only the unrelated note');
    }
    else {
        is_deeply([sort grep { m{\Adocs/tasks/} } keys %inputs], [], 'missing owner stages no task');
    }
    for my $native (@{$record->{stages}}) {
        ok($native->{ok}, 'native fixture Git operation succeeds');
        is($native->{timeout_seconds}, 10, 'original Git wall retains');
        is($native->{capture_limit_bytes}, 1_048_576, 'original Git capture retains');
        ok($native->{cleanup}{leader_reaped} && $native->{cleanup}{group_gone}, 'Git group settles');
    }
    my $checked = $record->{checker};
    is($checked->{timeout_seconds}, 10, 'original checker wall retains');
    is($checked->{capture_limit_bytes}, 4_194_304, 'original checker capture retains');
    ok($checked->{cleanup}{leader_reaped} && $checked->{cleanup}{group_gone}, 'checker group settles');
    my $output = $checked->{stdout} . $checked->{stderr};
    is($checked->{exit_code}, 0, 'fresh fixture must succeed with required evidence or explicit exemption')
        if $owner eq 'fresh';
    if (defined($checked->{exit_code}) && $checked->{exit_code} == 0) {
        ok($checked->{ok}, 'native zero has successful closed status');
        like($output, qr/\[task-acceptance\] OK:/, 'native checker success diagnostic retains');
        if ($output =~ /no configured implementation change staged/) {
            note('Native documentation exemption observed; this does not qualify audit-source scope.');
        }
        else {
            is($owner, 'fresh', 'only a fresh fixture can satisfy required evidence');
            like($output, qr/root=git_history, no-regression=prove_summary/,
                'native required-evidence acceptance identifies fixture signatures');
        }
    }
    else {
        is($checked->{exit_code}, 1, 'native refusal remains checker exit one');
        ok(!$checked->{ok}, 'fixture completion never promotes refusal');
        like($output, qr/no owning docs\/tasks\/\*\.md|fresh checked ROOT CAUSE box/,
            'native refusal identifies absent or insufficient evidence');
    }
    return $record;
}

subtest 'new fixed profiles admit no command or bound arguments' => sub {
    for my $arguments (['audit_py_fresh', {}], ['audit_py_none', '--index=other'],
                       ['audit_document_md', {timeout_seconds => 999}], ['audit_py_arbitrary']) {
        my $record = run_index_case(@$arguments);
        is($record->{status}, 'invocation_error', 'substitution is refused');
        is_deeply($record->{stages}, [], 'refusal starts no native process');
        ok(!defined($record->{workspace}) && !defined($record->{checker}),
            'refusal creates no fixture or checker');
    }
};

subtest 'pure audit evidence profiles preserve inputs and native truth' => sub {
    for my $extension (qw(py pl pm sh c t)) {
        my $candidate = "docs/audits/acceptance-index-fixture/source.$extension";
        observed("audit_$extension", $candidate, 'unchecked');
        observed("audit_${extension}_$_", $candidate, $_) for qw(fresh none stale);
    }
};

subtest 'neighboring documents and nested source have fixed literal paths' => sub {
    for my $row (
        ['audit_document_md', 'docs/audits/acceptance-index-fixture/notes.md'],
        ['audit_document_json', 'docs/audits/acceptance-index-fixture/receipt.json'],
        ['audit_document_txt', 'docs/audits/acceptance-index-fixture/notes.txt'],
        ['audit_source_suffix_md', 'docs/audits/acceptance-index-fixture/source.py.md'],
        ['audit_neighbor_prefix', 'docs/audit-notes/source.py'],
        ['audit_nested_py', 'docs/audits/acceptance-index-fixture/nested/source.py'],
    ) {
        observed(@$row, 'none');
        observed($row->[0] . '_unchecked', $row->[1], 'unchecked');
    }
};

done_testing();
