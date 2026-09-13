#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin;
use Test::More;
use JSON::PP ();
use Digest::SHA qw(sha256_hex);
use Fcntl qw(O_WRONLY O_CREAT O_EXCL);
require "$FindBin::Bin/qualify_controls.pl";
my $json=JSON::PP->new->canonical->ascii;
open my $input, '<:raw', "$FindBin::Bin/prepared.json" or die "data input: $!\n";
my $raw=do {local $/; <$input>};close($input) or die "data close: $!\n";
my $data=$json->decode($raw);
my $attempts=0;
my @traps=(
    (map {"NativeProxyLifetimeFiles::$_"} qw(initialize _metadata _ancestors absent directory_identity create_directory write_exclusive _file _members _walk snapshot cleanup_exact)),
    (map {"NativeProxyLifetimeControlQualification::$_"} qw(main authenticate journal remember_ownership observe probe measure prepare_case execute_event cleanup_case invoke_control measure_control execute_control)),
    'NativeProxyLifetimeTrace::observe',
    'NativeProxyReferenceAcquisition::acquire_runtime_reference','NativeProxyRuntimeRetirement::retire_runtime_reference',
    'NativeProxyObservationAcquisition::acquire_observation_reference','NativeProxyObservationAcquisition::reuse_observation_reference',
    'NativeProxyObservationArchive::archive_retained_sources','NativeProxyObservationRelease::release_observation_reference',
    'NativeProxyImageMaintenance::remove_unreferenced_image',
    'FSM::Test::RustProxyFixture::supervise_process','FSM::Test::ProcessSupervisor::supervise_process','FSM::Support::ProcessSupervisor::supervise_process');
for my $name (@traps) {
    no strict 'refs';no warnings 'redefine';
    *{$name}=sub {++$attempts;die "forbidden data-only operation: $name\n";};
}
sub materialize {
    my ($value)=@_;
    return [map {materialize($_)} @$value] if ref($value) eq 'ARRAY';
    return {map {$_ eq 'bytes_hex' ? (bytes=>pack('H*',$value->{$_})) : ($_=>materialize($value->{$_}))} keys %$value}
        if ref($value) eq 'HASH';
    return $value;
}
my @checks;
sub record {
    my ($name,$value)=@_;
    ok($value,$name);push @checks,{name=>$name,passed=>$value?1:0};
}
for my $row (@{$data->{cases}}) {
    my $case=$row->{case};my $context=materialize($row->{context});
    my $before=$json->encode(NativeProxyLifetimeControlQualification::retain($context));
    my $inputs=NativeProxyLifetimeControls::inputs($context,$case);
    record("$case->{name} exact cloned API inputs",NativeProxyLifetimeControlQualification::same($inputs,materialize($row->{expected_inputs})));
    record("$case->{name} original context unchanged",$before eq $json->encode(NativeProxyLifetimeControlQualification::retain($context)));
    record("$case->{name} exact primary diagnostic",NativeProxyLifetimeControls::expected_error($case) eq $row->{expected_error});
    my $selector=NativeProxyLifetimeControls::selector($context,$case);
    record("$case->{name} exact role selector",NativeProxyLifetimeControlQualification::same($selector,$row->{selector}));
    my $after=NativeProxyLifetimeControls::expected_nodes($row->{before},$context,$case->{fault}//'none');
    record("$case->{name} independent physical projection",sha256_hex($json->encode($after)) eq $row->{expected_after_sha256});
    if (defined($selector)) {
        my $call=$row->{inert_successful_call};
        record("$case->{name} selected successful call matches",NativeProxyLifetimeControls::matches($selector,$call));
        for my $kind (qw(failed wrong_path wrong_operation)) {
            my $changed=NativeProxyLifetimeControls::clone($call);
            $changed->{returned}=0 if $kind eq 'failed';
            if ($kind eq 'wrong_path') {
                $changed->{path}.='_wrong' if exists($changed->{path});
                $changed->{paths}[0].='_wrong' if exists($changed->{paths});
            }
            $changed->{operation}='mkdir' if $kind eq 'wrong_operation';
            record("$case->{name} $kind call does not match",!NativeProxyLifetimeControls::matches($selector,$changed));
        }
        my @hits;
        no warnings 'once';
        local $NativeProxyLifetimeTrace::ROW={calls=>[]};
        local $NativeProxyLifetimeTrace::LIMITS={calls=>4};
        my $returned=eval {NativeProxyLifetimeControls::with_fault($selector,\@hits,sub {
            # An inert already-returned call row exercises only the observer's
            # recording boundary. No syscall or actual interruption occurs.
            NativeProxyLifetimeTrace::_call($call);
        });1};my $error=$@;
        record("$case->{name} synchronous injected exception",!$returned && $error eq $row->{expected_error});
        record("$case->{name} original call recorded before exception",NativeProxyLifetimeControlQualification::same($NativeProxyLifetimeTrace::ROW->{calls},[$call]));
        record("$case->{name} one exact hit retained",NativeProxyLifetimeControlQualification::same(\@hits,[{ordinal=>0,call=>$call}]));
    }
    if (($case->{mutation}//'') eq 'unreaped_runtime') {
        my $ok=eval {NativeProxyRuntimeRetirement::_request(@$inputs{qw(store acquired cleanup)});1};my $error=$@;
        record("$case->{name} unchanged runtime validator rejects",!$ok && $error eq $row->{expected_error});
    }
    if (($case->{mutation}//'') eq 'unsettled_work' || ($case->{mutation}//'') eq 'unsealed_work') {
        my $ok=eval {NativeProxyObservationWorkRecord::validate_work_settlement(@$inputs{qw(store request acquired selection settlement)});1};my $error=$@;
        record("$case->{name} unchanged work validator rejects",!$ok && $error eq $row->{expected_error});
    }
}
record('no fixture or lifecycle operations',$attempts==0);
record('no subprocess attempts',$NativeProxyLifetimeControlQualification::FORBIDDEN==0);
sysopen(my $output,"$FindBin::Bin/corrected-data-qualification.json",O_WRONLY|O_CREAT|O_EXCL,0600) or die "exclusive data report: $!\n";
binmode($output) or die "data report mode: $!\n";
print {$output} $json->encode({schema=>'fsmgen.inactive_lifetime_control_data_qualification.v1',checks=>\@checks,
    fixture_attempts=>$attempts,process_attempts=>$NativeProxyLifetimeControlQualification::FORBIDDEN})."\n" or die "data report write: $!\n";
close($output) or die "data report close: $!\n";
done_testing();
