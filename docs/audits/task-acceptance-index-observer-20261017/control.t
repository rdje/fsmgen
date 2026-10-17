use strict;
use warnings;
use Test::More;
use JSON::PP ();
use IndexObserver;
use FSM::Test::TaskAcceptanceIndexRuntime qw(run_index_case);
our ($observer_directory);
my $group = CORE::getpgrp(0);
for my $kind (qw(ordinary stale session)) {
    $Control::kind = $kind;
    ($Control::calls, $Control::queries, $Control::writes) = (0, 0, 0);
    my $result = run_index_case('documentation');
    diag(IndexObserver::encode(IndexObserver::normalize($result)));
    is($result->{status}, $kind eq 'session' ? 'preparation_failed' : 'checker_returned', "$kind native status");
    ok($result->{cleanup}{retired} && !$result->{cleanup}{retained}, "$kind fixture retires");
    is(CORE::getpgrp(0), $group, "$kind original parent group retains");
    my @files = glob "$observer_directory/$kind-*.json";
    is(scalar(@files), $kind eq 'session' ? 1 : 11, "$kind exact child population");
    for my $path (@files) {
        my $child = JSON::PP->new->decode(IndexObserver::read_bytes($path, 4096));
        is($child->{queries}, $kind eq 'session' ? 1 : 0, "$kind failure-only query");
        is($child->{writes}, $kind eq 'session' ? 1 : 0, "$kind failure-only capture");
        is($child->{calls}, 1, "$kind original child call exactly once");
        if ($kind eq 'session') {
            ok(!defined($child->{result}) && $child->{errno} == 1, 'intentional native session rejection');
            like($result->{stages}[0]{exec_error}, qr/pid=$child->{pid} operation=setpgid result=undef errno=1 /,
                'first native rejection remains unchanged');
        } else {
            cmp_ok($child->{result}, '==', 0, "$kind native return admits");
            is($child->{errno}, 1, 'genuine stale EPERM after native success retains') if $kind eq 'stale';
        }
        ok(!kill(0, $child->{pid}) && $!{ESRCH}, "$kind independent exact child absence");
        ok(!kill(0, -$child->{pid}) && $!{ESRCH}, "$kind independent exact group absence");
    }
    is($result->{checker}{exit_code}, 0, "$kind genuine checker success") if $kind ne 'session';
    ok(!grep(!$_->{invariant}, @Control::checks), "$kind all native and case invariants hold");
}
done_testing();
1;
