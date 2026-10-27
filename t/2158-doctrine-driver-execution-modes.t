use strict;
use warnings;
use lib 'perl';
use Test::More;
use File::Path qw(make_path);
use File::Basename qw(dirname);
use File::Copy qw(copy);
use IPC::Open3 qw(open3);
use Symbol qw(gensym);
use FSM::ProjectDataLocality qw(create_project_tempdir);

my @expected = qw(DOCTRINE-BOOTSTRAP MEMORY-ARCH KNOWLEDGE-MAP DOC-PATHS
    LIVE-DOCUMENT-SIZE README-ENTRYPOINT PROJECT-DATA-LOCALITY TASK-TREE-INTEGRITY
    CLAIM-VERIFICATION CLAIM-INVENTORY CLAIM-DISPOSITIONS TASK-ACCEPTANCE);
my $root = create_project_tempdir(purpose => 'doctrine-driver-modes');
make_path("$root/scripts");
copy('scripts/check_doctrines.sh', "$root/scripts/check_doctrines.sh") or die $!;
chmod 0755, "$root/scripts/check_doctrines.sh" or die $!;
my @registry = split /\n/, qx{scripts/check_doctrines.sh --list};
is_deeply([map {(split /\t/)[0]} @registry], \@expected, 'current mandatory registry remains independently enumerated');
for my $row (@registry) {
    my ($id, $path) = split /\t/, $row;
    make_path(dirname("$root/$path"));
    open my $out, '>', "$root/$path" or die $!;
    print {$out} q{#!/usr/bin/env bash
printf '[stub] %s\n' '} . $id . q{'
selected=''
if [[ -f "$FSMGEN_DOCTRINE_TEST_ROOT/failure-selection" ]]; then
    read -r selected < "$FSMGEN_DOCTRINE_TEST_ROOT/failure-selection"
    selected="${selected// /}"
fi
[[ "$selected" == '} . $id . q{' ]] && exit 7
} . ($id eq 'README-ENTRYPOINT'
    ? qq{[[ "\$*" == --routing-only ]] || exit 9\n} : '') . qq{exit 0\n};
    close $out or die $!;
    chmod 0755, "$root/$path" or die $!;
}
sub run_driver {
    local $ENV{FSMGEN_DOCTRINE_TEST_ROOT} = $root;
    my $err = gensym;
    my $pid = open3(undef, my $out, $err, "$root/scripts/check_doctrines.sh", @_);
    my $text = do {local $/; <$out> // ''} . do {local $/; <$err> // ''};
    waitpid($pid, 0);
    return ($? >> 8, $text);
}
sub executed { return [$_[0] =~ /^\[stub\] ([A-Z-]+)$/mg] }
sub select_failure {
    open my $out, '>', "$root/failure-selection" or die $!;
    printf {$out} "%-20s\n", $_[0]; close $out or die $!;
}

subtest 'ordinary full diagnostics retain every mandatory check and exit meaning' => sub {
    my ($status, $text) = run_driver();
    is($status, 0, 'ordinary success'); is_deeply(executed($text), \@expected, 'all checks execute in registry order');
    like($text, qr/\[doctrine\] all doctrine checks passed/, 'complete success remains explicit');
    unlike($text, qr/\[doctrine\] TIME:/, 'ordinary CI output remains untimed');
    select_failure('MEMORY-ARCH');
    ($status, $text) = run_driver();
    isnt($status, 0, 'ordinary failure'); is_deeply(executed($text), \@expected, 'full diagnostic mode continues through failures');
    unlike($text, qr/\[doctrine\] all doctrine checks passed/, 'a failed run cannot claim complete success');
    select_failure('NONE');
};

subtest 'timed local success still qualifies every registered check' => sub {
    my ($status, $text) = run_driver('--timings', '--fail-fast');
    is($status, 0, 'timed fail-fast success'); is_deeply(executed($text), \@expected, 'success skips no check');
    my @timed = $text =~ /^\[doctrine\] TIME: ([A-Z-]+) real_s=[0-9.]+ user_s=[0-9.]+ sys_s=[0-9.]+$/mg;
    is_deeply(\@timed, \@expected, 'each actual check gets a separate timing record');
    like($text, qr/\[doctrine\] all doctrine checks passed/, 'only complete success is green');
};

subtest 'changed input after a passed preflight is freshly rejected, with size and whole-second mtime preserved' => sub {
    select_failure('NONE');
    my ($status, $text) = run_driver('--timings', '--fail-fast'); is($status, 0, 'earlier preflight passes');
    my @before = stat "$root/failure-selection";
    select_failure('MEMORY-ARCH');
    utime $before[8], $before[9], "$root/failure-selection" or die $!;
    is(-s "$root/failure-selection", $before[7], 'control preserves input byte count');
    is((stat("$root/failure-selection"))[9], $before[9], 'control preserves whole-second mtime');
    ($status, $text) = run_driver('--timings', '--fail-fast');
    isnt($status, 0, 'fresh validation rejects changed content');
    is_deeply(executed($text), [@expected[0, 1]], 'local failure stops before unrelated expensive checks');
    like($text, qr/fail-fast.*remaining checks were not run/, 'unexecuted checks are disclosed');
    unlike($text, qr/\[doctrine\] all doctrine checks passed/, 'old success is never reused');
    select_failure('NONE');
};

subtest 'README composition requires an actual passed live-document result' => sub {
    select_failure('LIVE-DOCUMENT-SIZE');
    my ($status, $text) = run_driver();
    isnt($status, 0, 'a failed prerequisite rejects the complete gate');
    like($text, qr/README-ENTRYPOINT requires successful LIVE-DOCUMENT-SIZE in this invocation/, 'missing prerequisite is explicit');
    is_deeply(executed($text), \@expected, 'collect-all still executes routing and all independent diagnostics');
    like($text, qr/\[doctrine\] FAIL: README-ENTRYPOINT/, 'routing alone cannot satisfy a failed pressure prerequisite');
    unlike($text, qr/\[doctrine\] all doctrine checks passed/, 'prerequisite failure cannot produce complete success');
    select_failure('NONE');
};

subtest 'invalid invocation and missing registry members cannot skip enforcement' => sub {
    my ($status, $text) = run_driver('--skip-check');
    isnt($status, 0, 'unknown flag refuses'); is_deeply(executed($text), [], 'no execution is misreported');
    unlink "$root/scripts/check_memory_architecture.sh" or die $!;
    ($status, $text) = run_driver('--fail-fast');
    isnt($status, 0, 'missing mandatory executable rejects');
    unlike($text, qr/\[doctrine\] all doctrine checks passed/, 'incomplete registry is never green');
    unlink "$root/scripts/check_live_document_size.sh" or die $!;
    ($status, $text) = run_driver();
    isnt($status, 0, 'missing live-document prerequisite rejects the complete gate');
    like($text, qr/LIVE-DOCUMENT-SIZE registry path missing/, 'missing prerequisite is named by the meta-check');
};
done_testing();
