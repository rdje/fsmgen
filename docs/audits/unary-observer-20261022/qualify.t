#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Cwd qw(abs_path);
use Digest::SHA qw(sha256_hex);
use Fcntl qw(O_WRONLY O_CREAT O_EXCL);
use JSON::PP;
use Storable qw(dclone);
use lib 'perl', 't/lib', 'docs/audits/native-group-witness-20260927',
    'docs/audits/native-group-witness-20260927/failure-only',
    'docs/audits/native-group-witness-20260927/priority-observer',
    'docs/audits/unary-observer-20261022';
use FSM::Test::ProjectDataLocality;
use FSM::Test::ProcessSupervisor qw(supervise_process);
use UnaryAdmission;

my $prefix = shift @ARGV;
die "one exclusive qualification name required\n" unless defined($prefix)
    && $prefix =~ /\A[a-z][a-z0-9_]{0,20}\z/ && !@ARGV;
die "unexpected inherited preload\n" if $ENV{PERL5OPT};
my $base = '.artifacts/unary-native-observer';
my $audit = 'docs/audits/unary-observer-20261022';
my $json = JSON::PP->new->canonical;
my @rows;
sub save {
    my ($path, $data) = @_;
    sysopen my $fh, $path, O_WRONLY | O_CREAT | O_EXCL, 0600 or die "exclusive qualification file: $!";
    print {$fh} $json->encode($data), "\n" or die $!;
    close $fh or die $!;
}
sub admission {
    my ($capture, $scenario) = @_;
    return {schema => 'fsmgen.fixed_unary_observer_admission.v1', capture => $capture,
        mode => 'qualification', target => UnaryAdmission::target('qualification'), scenario => $scenario,
        expected_stages => {compile => 1, runtime => 2},
        sha256 => {map {$_ => sha256_hex(StageObserver::_read($_, 2_097_152))} UnaryAdmission::paths('qualification')}};
}
sub run_driver {
    my ($capture) = @_;
    local $ENV{FSMGEN_DARWIN_VERILATOR_TEST_RUNTIME} = 1;
    return supervise_process(schema => 'fsmgen.test.priority_observer_control.v1', stage => 'control',
        bounds => {timeout_seconds => 60, capture_limit_bytes => 1_048_576},
        containment => 'priority_observer_control_group', cwd => abs_path('.'),
        argv => [$^X, "$audit/observe.t", $capture]);
}
for my $scenario (qw(healthy query_gap capture_gap retention_gap diagnostic_errno)) {
    my $capture = "${prefix}_$scenario";
    my $a = admission($capture, $scenario);
    UnaryAdmission::validate($a, $capture);
    save("$base/$capture-admission.json", $a);
    my $result = run_driver($capture);
    my $success = $scenario eq 'healthy' || $scenario eq 'diagnostic_errno';
    is(!!$result->{ok}, !!$success, "$scenario has intended observer status") or diag explain $result;
    like($result->{stdout}, qr/^1\.\.39$/m, "$scenario completes all original invariance assertions");
    unlike($result->{stdout}, qr/^not ok/m, "$scenario preserves original assertions");
    ok($result->{cleanup}{leader_reaped} && $result->{cleanup}{group_gone}, "$scenario driver cleanup");
    my $summary = $json->decode(StageObserver::_read("$base/$capture/summary.json", 65_536));
    is($summary->{stages}, 3, "$scenario traverses fixed adapters");
    my $diagnostics = $json->encode([$summary->{capture_gaps}, $summary->{retention_errors}]);
    my %gap = (healthy => qr/\A\[\[\],\[\]\]\z/, diagnostic_errno => qr/\A\[\[\],\[\]\]\z/,
        query_gap => qr/native_context_query/, capture_gap => qr/missing_or_duplicate_native_event/,
        retention_gap => qr/exclusive observer result/);
    like($diagnostics, $gap{$scenario}, "$scenario has explicit expected capture outcome");
    push @rows, {case => $scenario, capture => $capture, result => $result};
}
for my $case (qw(empty_inputs changed_digest wrong_target extra_field wrong_count wrong_scenario)) {
    my $capture = "${prefix}_$case";
    my $a = admission($capture, 'healthy');
    $a->{sha256} = {} if $case eq 'empty_inputs';
    $a->{sha256}{UnaryAdmission::target('qualification')} = '0' x 64 if $case eq 'changed_digest';
    $a->{target} = 't/1972-isf-constant-false-guards.t' if $case eq 'wrong_target';
    $a->{unexpected} = 1 if $case eq 'extra_field';
    $a->{expected_stages}{runtime} = 1 if $case eq 'wrong_count';
    $a->{scenario} = 'unselected' if $case eq 'wrong_scenario';
    save("$base/$capture-admission.json", $a);
    my $result = run_driver($capture);
    ok(!$result->{ok} && $result->{exit_code} != 0, "$case rejects admission");
    ok(!-e "$base/$capture", "$case creates no observation or child stage");
    ok($result->{cleanup}{leader_reaped} && $result->{cleanup}{group_gone}, "$case exact driver cleanup");
    push @rows, {case => $case, capture => $capture, result => $result};
}
my $reuse = run_driver("${prefix}_healthy");
ok(!$reuse->{ok} && $reuse->{stderr} =~ /exclusive observer work directory/, 'capture reuse fails before overwrite');
push @rows, {case => 'reuse', capture => "${prefix}_healthy", result => $reuse};
my $fixed = {schema => 'fsmgen.fixed_unary_observer_admission.v1',
    capture => "${prefix}_unary", mode => 'unary', scenario => 'none',
    target => UnaryAdmission::target('unary'), expected_stages => {compile=>3,runtime=>3},
    sha256 => {map {$_=>sha256_hex(StageObserver::_read($_,2_097_152))} UnaryAdmission::paths('unary')}};
ok(UnaryAdmission::validate($fixed,$fixed->{capture}),'only the exact prepared T2090 target has native admission');
UnaryAdmission::check_inputs($fixed);
ok(length($json->encode($fixed)) < 65_536, 'complete fixed producer admission fits unchanged read envelope');
for my $case (qw(old_target wrong_count omitted_fixture omitted_vectors extra_identity changed_fixture changed_producer)) {
    my $bad = dclone($fixed);
    $bad->{target}='t/1974-isf-priority-contributor-union.t' if $case eq 'old_target';
    $bad->{expected_stages}{runtime}=2 if $case eq 'wrong_count';
    delete $bad->{sha256}{'t/data/unary_reduction_runtime_tb.sv'} if $case eq 'omitted_fixture';
    delete $bad->{sha256}{'t/data/unary_reduction_runtime_vectors.hex'} if $case eq 'omitted_vectors';
    $bad->{sha256}{'perl/FSM/ExpressionNamer.pm'}='0' x 64 if $case eq 'changed_producer';
    $bad->{sha256}{unexpected}='0' x 64 if $case eq 'extra_identity';
    $bad->{sha256}{'t/data/unary_reduction_runtime.isf'}='0' x 64 if $case eq 'changed_fixture';
    my $accepted=eval {UnaryAdmission::validate($bad,$bad->{capture});UnaryAdmission::check_inputs($bad);1};
    ok(!$accepted,"unary $case rejects before any target execution");
}
save("$base/$fixed->{capture}-admission.json",$fixed);
my $unqualified=run_driver($fixed->{capture});
ok(!$unqualified->{ok} && $unqualified->{stderr} =~ /unary observer qualification required/,
    'genuine target cannot execute before observer qualification is sealed');
ok(!-e "$base/$fixed->{capture}",'missing qualification creates no observation or HDL stage');
ok($unqualified->{cleanup}{leader_reaped} && $unqualified->{cleanup}{group_gone},'unqualified driver cleanup completes');
push @rows,{case=>'qualification_missing',capture=>$fixed->{capture},result=>$unqualified};
save("$base/$prefix-results.json", FSM::Test::SourceQueryRunner::normalize_repository_paths(\@rows, abs_path('.')));
done_testing();
