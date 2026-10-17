use strict;
use warnings;
use Test::More;
use JSON::PP ();
use File::Temp qw(tempdir);
use File::Path qw(remove_tree);
use lib 'perl', 't/lib', 'docs/audits/native-group-witness-20260927',
    'docs/audits/native-group-witness-20260927/failure-only',
    'docs/audits/task-acceptance-index-observer-20261017';
use IndexObserver;
use FSM::ProjectDataLocality qw(ensure_project_artifact_dir);

# Admission controls do not execute any selected test or native Git stage.
my $original = IndexObserver::admission('control_healthy');
ok(IndexObserver::validate($original, 'control_healthy'), 'complete fixed admission passes');
for my $case (qw(empty_inputs changed_digest wrong_target extra_field wrong_count wrong_scenario)) {
    my $candidate = JSON::PP->new->decode(IndexObserver::encode($original));
    $candidate->{sha256} = {} if $case eq 'empty_inputs';
    $candidate->{sha256}{'scripts/check_task_acceptance.sh'} = '0' x 64 if $case eq 'changed_digest';
    $candidate->{target} = 't/unselected.t' if $case eq 'wrong_target';
    $candidate->{extra} = 1 if $case eq 'extra_field';
    $candidate->{expected}[1] = 1 if $case eq 'wrong_count';
    $candidate->{scenario} = 'unselected' if $case eq 'wrong_scenario';
    eval {IndexObserver::validate($candidate, 'control_healthy')};
    like($@, qr/closed observer admission or source identity changed/, "$case refuses before observation");
}
for my $selector ('../index', 't/1972-isf-constant-false-guards.t', 'control_unselected') {
    eval {IndexObserver::selection($selector)};
    like($@, qr/target outside fixed index observation scope/, 'unselected target refuses');
}
my $directory = tempdir('observer-record-XXXXXXXX', DIR => ensure_project_artifact_dir(qw(tmp tests)), CLEANUP => 0);
IndexObserver::save("$directory/events.jsonl", '{"event":"partial"}');
my $observer = bless {directory => $directory, receipts => []}, 'IndexObserver';
eval {$observer->capture_gaps()};
like($@, qr/partial native capture/, 'partial native row cannot pass as no event');
remove_tree($directory);
ok(!-e $directory, 'exact inert record fixture retires');
done_testing();
