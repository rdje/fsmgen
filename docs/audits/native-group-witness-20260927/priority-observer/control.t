use strict;
use warnings;
use Test::More;
use Scalar::Util qw(refaddr);
use JSON::PP;
use Fcntl qw(O_WRONLY O_CREAT O_EXCL);
use FSM::Test::VerilatorRuntime qw(run_verilator_compile run_generated_binary);
our ($observer_work, $observer_scenario);
my $json = JSON::PP->new->canonical;
my @evidence;
my $original_group = CORE::getpgrp(0);
for my $name (qw(verilator fixture_binary)) {
    sysopen my $fh, "$observer_work/$name", O_WRONLY | O_CREAT | O_EXCL, 0700 or die $!;
    print {$fh} '#!/usr/bin/perl', "\n", 'die "unexpected preload" if $ENV{PERL5OPT}; print "control-body=$$\n";', "\n" or die $!;
    close $fh or die $!;
}
if ($observer_scenario eq 'retention_gap') {
    sysopen my $collision, "$observer_work/compile_a.json", O_WRONLY | O_CREAT | O_EXCL, 0600 or die $!;
    print {$collision} "exclusive collision control\n" or die $!;
    close $collision or die $!;
}
for my $kind (qw(ordinary stale session)) {
    $ControlFixture::kind = $kind;
    ($ControlFixture::calls, $ControlFixture::queries, $ControlFixture::writes) = (0, 0, 0);
    my $compile = $kind eq 'ordinary';
    my $argv = $compile ? ["$observer_work/verilator", '--binary', '--Mdir', "$observer_work/obj"]
        : ["$observer_work/fixture_binary"];
    my $result = $compile ? run_verilator_compile($argv) : run_generated_binary($argv);
    my $error = 0 + $!;
    is(refaddr($result), refaddr($ControlFixture::reference), "$kind preserves original result identity");
    is_deeply($result, $ControlFixture::before, "$kind preserves every original result field");
    is_deeply($ControlFixture::arguments, [$argv], "$kind preserves arguments");
    is($error, $ControlFixture::errno, "$kind preserves stage errno through retention");
    my $child = $json->decode(StageObserver::_read("$observer_work/$kind-child.json", 4096));
    my $failure = $kind eq 'session';
    is($child->{calls}, 1, "$kind has exactly one original child call");
    is($ControlFixture::calls, $failure ? 0 : 1, "$kind preserves parent except intentional session control");
    is($child->{queries}, $failure ? 1 : 0, "$kind queries only on rejection");
    is($child->{writes}, $failure ? 1 : 0, "$kind writes only on rejection");
    if ($failure) {
        ok(!defined($child->{result}) && $child->{errno} == 1, 'real session rejection retains native result and errno');
        is($result->{status}, 'exec_error', 'native rejection stays a pre-exec failure');
        like($result->{exec_error}, qr/pid=$child->{pid} operation=setpgid result=undef errno=1 /, 'exact native failure retained');
        is($result->{stdout}, '', 'rejected body never executes');
    } else {
        ok($result->{ok}, "$kind executes") or diag explain $result;
        is($result->{stdout}, "control-body=$child->{pid}\n", "$kind exact body, no inherited preload");
        is($child->{errno}, 1, 'stale errno preserved on success') if $kind eq 'stale';
    }
    ok($result->{cleanup}{leader_reaped} && $result->{cleanup}{group_gone}, "$kind cleanup completes");
    is(CORE::getpgrp(0), $original_group, "$kind observer group remains unchanged");
    push @evidence, {kind => $kind, child => $child, result => $result};
}
sysopen my $fh, "$observer_work/control-results.json", O_WRONLY | O_CREAT | O_EXCL, 0600 or die $!;
print {$fh} $json->encode(\@evidence), "\n" or die $!;
close $fh or die $!;
done_testing();
1;
