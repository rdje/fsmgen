#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use JSON::PP ();
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::Test::TaskAcceptanceIndexRuntime qw(run_index_case);

sub observed {
    my ($case) = @_;
    my $record = run_index_case($case);
    diag('audit scope case: ' . JSON::PP->new->canonical->encode($record));
    is($record->{status}, 'checker_returned', "$case runs the actual checker") or return;
    ok($record->{main_index_conserved}, 'main index remains byte-identical');
    ok($record->{cleanup}{retired} && !$record->{cleanup}{retained}, 'settled fixture retires');
    for my $native (@{$record->{stages}}) {
        ok($native->{ok}, 'native fixture Git stage succeeds');
        ok($native->{cleanup}{leader_reaped} && $native->{cleanup}{group_gone}, 'Git group settles');
    }
    my $native = $record->{checker};
    ok($native->{cleanup}{leader_reaped} && $native->{cleanup}{group_gone}, 'checker group settles');
    return $record;
}

subtest 'every executable audit format requires fresh owning evidence' => sub {
    for my $extension (qw(py pl pm sh c t)) {
        my $path = "docs/audits/acceptance-index-fixture/source.$extension";
        my $unchecked = observed("audit_$extension") or next;
        my $native = $unchecked->{checker};
        is($native->{exit_code}, 1, "$extension unchecked evidence is refused");
        ok(!$native->{ok}, 'native refusal is not promoted');
        like($native->{stderr}, qr/^    - \Q$path\E$/m,
            'native classified-path diagnostic identifies the audit source');
        like($native->{stderr}, qr/fresh checked ROOT CAUSE box/,
            'native evidence refusal is explicit');
        my $fresh = observed("audit_${extension}_fresh") or next;
        is($fresh->{checker}{exit_code}, 0, "$extension fresh owner is accepted");
        like($fresh->{checker}{stdout}, qr/root=git_history, no-regression=prove_summary/,
            'required evidence is actually checked, not exempted');
    }
};

subtest 'absent and historical owners cannot authorize audit source' => sub {
    my $missing = observed('audit_py_none');
    if ($missing) {
        is($missing->{checker}{exit_code}, 1, 'missing audit owner is refused');
        like($missing->{checker}{stderr}, qr/no owning docs\/tasks\/\*\.md file is staged/,
            'native absent-owner cause retains');
    }
    my $stale = observed('audit_py_stale');
    if ($stale) {
        is($stale->{checker}{exit_code}, 1, 'historical checked boxes remain insufficient');
        like($stale->{checker}{stderr}, qr/fresh checked ROOT CAUSE box/,
            'native freshness cause retains');
    }
};

subtest 'neighboring documents remain outside the classified source set' => sub {
    for my $row (
        ['audit_document_md_unchecked', 'docs/audits/acceptance-index-fixture/notes.md'],
        ['audit_document_json_unchecked', 'docs/audits/acceptance-index-fixture/receipt.json'],
        ['audit_document_txt_unchecked', 'docs/audits/acceptance-index-fixture/notes.txt'],
        ['audit_source_suffix_md_unchecked', 'docs/audits/acceptance-index-fixture/source.py.md'],
        ['audit_neighbor_prefix_unchecked', 'docs/audit-notes/source.py'],
    ) {
        my ($case, $path) = @$row;
        my $record = observed($case) or next;
        my $native = $record->{checker};
        if ($record->{registry_co_staged}) {
            is($native->{exit_code}, 1, 'co-staged registry itself requires owning evidence');
            like($native->{stderr}, qr/^    - doctrine\/task_acceptance\/change_paths\.tsv$/m,
                'native classification identifies the registry delta');
            unlike($native->{stderr}, qr/^    - \Q$path\E$/m,
                'neighbor is absent from native classified paths');
            note('Document-only zero must be requalified after committing the registry.');
        }
        else {
            is($native->{exit_code}, 0, 'committed-registry document-only change is exempt');
            like($native->{stdout}, qr/no configured implementation change staged/,
                'native documentation exemption remains explicit');
        }
    }
};

subtest 'nested audit sources are classified independently of co-staged registry' => sub {
    my $record = observed('audit_nested_py_unchecked') or return;
    is($record->{checker}{exit_code}, 1, 'nested unchecked source is refused');
    like($record->{checker}{stderr},
        qr/^    - docs\/audits\/acceptance-index-fixture\/nested\/source\.py$/m,
        'native diagnostic classifies the nested source itself');
};

done_testing();
