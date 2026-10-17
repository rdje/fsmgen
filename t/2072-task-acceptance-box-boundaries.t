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
    diag('box boundary case: ' . JSON::PP->new->canonical->encode($record));
    is($record->{status}, 'checker_returned', "$case reaches the actual checker") or return;
    is($record->{schema}, 'fsmgen.test.task_acceptance_index_case.v1', 'schema retains');
    ok($record->{main_index_conserved}, 'primary index stays byte-identical');
    is($record->{registry_co_staged}, 0, 'committed declaration has no co-staged delta');
    ok($record->{cleanup}{retired} && !$record->{cleanup}{retained}, 'settled workspace retires');
    for my $native (@{$record->{stages}}) {
        ok($native->{ok}, 'native fixture Git stage succeeds');
        is($native->{timeout_seconds}, 10, 'Git deadline retains');
        is($native->{capture_limit_bytes}, 1_048_576, 'Git capture retains');
        ok($native->{cleanup}{leader_reaped} && $native->{cleanup}{group_gone}, 'Git group settles');
    }
    my $native = $record->{checker};
    is($native->{timeout_seconds}, 10, 'checker deadline retains');
    is($native->{capture_limit_bytes}, 4_194_304, 'checker capture retains');
    ok($native->{cleanup}{leader_reaped} && $native->{cleanup}{group_gone}, 'checker group settles');
    return $record;
}

subtest 'sibling text cannot supply a box signature' => sub {
    for my $row (
        ['box_root_sibling', 'ROOT CAUSE'],
        ['box_regression_sibling', 'NO REGRESSION'],
        ['box_indented_sibling', 'NO REGRESSION'],
    ) {
        my ($case, $box) = @$row;
        my $record = observed($case) or next;
        is($record->{checker}{exit_code}, 1, "$case refuses borrowed evidence");
        ok(!$record->{checker}{ok}, 'native refusal remains non-success');
        like($record->{checker}{stderr}, qr/fresh checked \Q$box\E box/,
            'native diagnostic identifies the missing own-box evidence');
    }
};

subtest 'indented evidence survives wrapping blank lines nesting and tabs' => sub {
    for my $case (qw(box_wrapped box_blank_wrapped box_nested box_tab_wrapped)) {
        my $record = observed($case) or next;
        is($record->{checker}{exit_code}, 0, "$case accepts its own evidence");
        ok($record->{checker}{ok}, 'native acceptance is successful');
        like($record->{checker}{stdout}, qr/root=git_history, no-regression=prove_summary/,
            'required evidence is checked rather than exempted');
    }
};

subtest 'existing peer checkbox and heading boundaries retain' => sub {
    for my $case (qw(box_peer_checkbox box_heading)) {
        my $record = observed($case) or next;
        is($record->{checker}{exit_code}, 1, "$case refuses unrelated evidence");
        ok(!$record->{checker}{ok}, 'native refusal is not promoted');
        like($record->{checker}{stderr}, qr/fresh checked NO REGRESSION box/,
            'existing native regression evidence refusal retains');
    }
};

done_testing();
