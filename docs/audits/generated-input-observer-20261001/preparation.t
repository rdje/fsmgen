use strict;
use warnings;
use lib 'perl', 't/lib', 'docs/audits/native-group-witness-20260927',
    'docs/audits/native-group-witness-20260927/failure-only',
    'docs/audits/native-group-witness-20260927/priority-observer',
    'docs/audits/generated-input-observer-20261001';
use Test::More;
use JSON::PP;
use Digest::SHA qw(sha256_hex);
use FSM::Test::ProjectDataLocality;
use GeneratedInputAdmission;

my $json = JSON::PP->new->canonical;
my @paths = GeneratedInputAdmission::paths('generated_input');
is(GeneratedInputAdmission::target('generated_input'), 't/2025-isf-record-input-generated-runtime.t',
    'only the committed generated witness is selected');
my @fixtures = grep {m{\At/data/}} @paths;
is_deeply(\@fixtures, [qw(t/data/isf_record_input_generated_blocking_runtime.isf
    t/data/isf_record_input_generated_domains_runtime.isf t/data/isf_record_input_generated_runtime_tb.sv)],
    'the complete independently named fixed fixture cohort is required');
my %unique = map {$_ => 1} @paths;
is(scalar(keys %unique),scalar(@paths),'all declared producer identities are distinct');
my $a = {schema=>'fsmgen.fixed_generated_input_observer_admission.v1', capture=>'generated_pure',
    mode=>'generated_input', scenario=>'none', target=>'t/2025-isf-record-input-generated-runtime.t',
    expected_stages=>{compile=>5,runtime=>5},
    sha256=>{map {$_=>sha256_hex(StageObserver::_read($_,2_097_152))} @paths}};
for my $kind (qw(number string)) {
    my $value = $json->decode($json->encode($a));
    $value->{expected_stages} = {compile=>'5',runtime=>'5'} if $kind eq 'string';
    my $before = $json->encode($value);
    ok(GeneratedInputAdmission::validate($value,'generated_pure'),"$kind coverage accepts the exact target");
    GeneratedInputAdmission::check_inputs($value);
    is($json->encode($value),$before,"$kind acceptance preserves complete caller JSON primitive kinds");
    $value->{expected_stages}{runtime} = $kind eq 'string' ? '4' : 4;
    $before = $json->encode($value);
    my $ok = eval {GeneratedInputAdmission::validate($value,'generated_pure');1};
    ok(!$ok,"$kind incorrect coverage rejects");
    is($json->encode($value),$before,"$kind refusal preserves complete caller kinds");
}
for my $target ('t/2024-isf-record-input-runtime.t', 't/1974-isf-priority-contributor-union.t') {
    my $bad = $json->decode($json->encode($a));
    $bad->{target} = $target;
    my $before = $json->encode($bad);
    my $ok = eval {GeneratedInputAdmission::validate($bad,'generated_pure');1};
    ok(!$ok,"other qualified target $target has no authority here");
    is($json->encode($bad),$before,'wrong target refusal preserves caller JSON');
}
for my $path (@fixtures) {
    my $bad = $json->decode($json->encode($a));
    delete $bad->{sha256}{$path};
    ok(!eval {GeneratedInputAdmission::validate($bad,'generated_pure');1},"missing $path rejects");
}
done_testing;
