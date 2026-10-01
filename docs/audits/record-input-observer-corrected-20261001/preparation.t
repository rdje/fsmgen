use strict;
use warnings;
use Test::More;
use JSON::PP;
use Digest::SHA qw(sha256_hex);
use lib 'perl', 't/lib', 'docs/audits/native-group-witness-20260927',
    'docs/audits/native-group-witness-20260927/failure-only',
    'docs/audits/native-group-witness-20260927/priority-observer',
    'docs/audits/record-input-observer-corrected-20261001';
use RecordInputAdmission;

my $json=JSON::PP->new->canonical;
is(RecordInputAdmission::target('record_input'),'t/2024-isf-record-input-runtime.t',
    'the fixed feature target remains independently named');
is(RecordInputAdmission::target('qualification'),
    'docs/audits/native-group-witness-20260927/priority-observer/control.t',
    'the immutable native control target remains separately named');
my @paths=RecordInputAdmission::paths('record_input');
is_deeply(\@paths,[sort @paths],'declared identities retain canonical ordering');
ok(!(grep {!-f $_} @paths),'every declared identity resolves to an existing repository input');
my %paths=map {$_=>1} @paths;
ok($paths{'t/2024-isf-record-input-runtime.t'}
    && $paths{'t/data/isf_record_input_runtime.isf'}
    && $paths{'t/data/isf_record_input_runtime_tb.sv'},
    'the independently required feature source and public-pin bench identities are mandatory');
my $packet={schema=>'fsmgen.fixed_record_input_observer_admission.v1',capture=>'preparation',
    mode=>'record_input',scenario=>'none',target=>'t/2024-isf-record-input-runtime.t',
    expected_stages=>{compile=>3,runtime=>3},sha256=>{map {$_=>'0'x64} @paths}};
my $before=$json->encode($packet);
ok(RecordInputAdmission::validate($packet,'preparation'),'exact complete feature coverage is admitted structurally');
is(sha256_hex($json->encode($packet)),sha256_hex($before),'validation preserves complete caller primitive kinds');
for my $change (
    sub {$_[0]{target}='t/1974-isf-priority-contributor-union.t'},
    sub {$_[0]{expected_stages}{compile}=2},
    sub {$_[0]{expected_stages}{runtime}=4},
    sub {delete $_[0]{sha256}{'t/data/isf_record_input_runtime_tb.sv'}},
    sub {$_[0]{sha256}{extra}='0'x64},
    sub {$_[0]{scenario}='healthy'},
    sub {$_[0]{expected_stages}={compile=>'2',runtime=>'3'}},
) {
    my $bad=$json->decode($json->encode($packet));$change->($bad);
    my $original=$json->encode($bad);
    my $accepted=eval {RecordInputAdmission::validate($bad,'preparation');1};
    ok(!$accepted,'wrong target, coverage, identity or control scenario refuses before execution');
    is(sha256_hex($json->encode($bad)),sha256_hex($original),'refusal preserves complete caller values');
}
my $strings=$json->decode($json->encode($packet));
$strings->{expected_stages}={compile=>'3',runtime=>'3'};
my $strings_before=$json->encode($strings);
ok(RecordInputAdmission::validate($strings,'preparation'),'accepted numeric-string coverage retains its existing admission');
is(sha256_hex($json->encode($strings)),sha256_hex($strings_before),
    'accepted numeric-string caller primitive kinds remain exact');
{
    open my $fh, '<', 'docs/audits/record-input-observer-corrected-20261001/preparation-before.pm'
        or die "read preserved before module: $!";
    local $/;
    my $source=<$fh>;
    close $fh or die $!;
    # Only its package name changes to isolate the preserved actual before
    # implementation; admission, bounds and validation code remain untouched.
    $source =~ s/\Apackage RecordInputAdmission;/package PreparationBefore;/
        or die "unexpected preserved package";
    eval $source or die $@;
    my $old=$json->decode($strings_before);
    ok(PreparationBefore::validate($old,'preparation'),
        'preserved before implementation accepts the same numeric-string values');
    isnt(sha256_hex($json->encode($old)),sha256_hex($strings_before),
        'preserved actual before implementation falsifies caller-kind preservation');
}
done_testing;
