#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;
use FindBin;
use IPC::Open3 qw(open3);
use JSON::PP ();
use Symbol qw(gensym);
use Test::More;

my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $script = File::Spec->catfile(
    $repo_root, 'scripts',
    'audit_vial_semantic_bridge_profile_isolation.pl',
);
my $current_profile_publication = File::Spec->catdir(
    $repo_root, '.artifacts', 'qualification', 'vial-scale', 'v1',
    'semantic-catalog-v1.imports.gate-candidate-v1',
);
my $disposition = File::Spec->catfile(
    $repo_root, 'perl', 'FSM', 'VIAL',
    'ArchitectureScaleCalibrationDisposition.pm',
);
my $json = JSON::PP->new->canonical(1)->utf8(1);

subtest 'audit drift partition is pinned to the canonical disposition' => sub {
    my $audit_source = slurp_raw($script);
    my $disposition_source = slurp_raw($disposition);
    my ($audit_block) = $audit_source =~
        /my %expected_drift = map \{ \$_ => 1 \} qw\((.*?)\);/s;
    my ($disposition_block) = $disposition_source =~
        /my \@EXPECTED_DRIFT = \((.*?)\n\);/s;
    ok(defined $audit_block && defined $disposition_block,
        'both expected-drift authorities remain inspectable');
    my @audit_ids = $audit_block =~ /([a-z][a-z0-9.-]+-v1)/g;
    my @disposition_ids = $disposition_block =~
        /'(bridge-fanout-v1[.]\w[\w.-]*-v1)'/g;
    is_deeply(\@audit_ids, \@disposition_ids,
        'the read-only audit admits exactly decision 0095 drift profiles');
    is(scalar(@audit_ids), 6,
        'the sealed drift partition contains exactly six profiles');
    like($audit_source, qr/_load_report_publication/,
        'the audit traverses the exact matrix publication loader');
};

subtest 'direct and isolated modes agree on current and drift controls' => sub {
    plan skip_all =>
        'ignored revision-1 semantic/bridge publication is absent on a fresh checkout'
        unless -d $current_profile_publication;
    my @controls = (
        ['semantic-catalog-v1.imports.gate-candidate-v1', 1, 0],
        ['bridge-fanout-v1.configurations.limit-v1', 0, 1],
    );
    for my $mode (qw(direct isolated)) {
        for my $control (@controls) {
            my ($profile, $current, $drift) = @$control;
            my ($status, $output) = capture_command(
                $script, '--mode', $mode, '--profile', $profile,
            );
            is($status, 0, "$mode $profile audit accepts");
            my $report = eval { $json->decode($output) };
            ok(defined $report,
                "$mode $profile emits one JSON report");
            is_deeply([sort keys %$report], [sort qw(
                schema schema_version mode selected_profile profile_count
                current_match_count expected_drift_count outcome
                synthetic_allocation_bytes explicit_nonclaims
            )], "$mode $profile report schema is closed");
            is($report->{schema},
                'fsmgen.vial_semantic_bridge_profile_isolation_audit.v1',
                "$mode $profile retains the audit schema");
            is($report->{mode}, $mode,
                "$mode $profile retains its process model");
            is($report->{profile_count}, 1,
                "$mode $profile reports one selected profile");
            is($report->{synthetic_allocation_bytes}, 0,
                "$mode $profile adds no undeclared synthetic state");
            is($report->{current_match_count}, $current,
                "$mode $profile current-match count is exact");
            is($report->{expected_drift_count}, $drift,
                "$mode $profile drift count is exact");
            is($report->{outcome}, 'accepted',
                "$mode $profile completes read-only validation");
        }
    }
};

subtest 'bounded synthetic allocation crosses both process modes' => sub {
    plan skip_all =>
        'ignored revision-1 semantic/bridge publication is absent on a fresh checkout'
        unless -d $current_profile_publication;
    for my $mode (qw(direct isolated)) {
        my ($status, $output) = capture_command(
            $script,
            '--mode', $mode,
            '--profile', 'semantic-catalog-v1.imports.gate-candidate-v1',
            '--synthetic-allocation-bytes', 67_108_864,
        );
        is($status, 0, "$mode bounded synthetic control accepts");
        my $report = $json->decode($output);
        is($report->{synthetic_allocation_bytes}, 67_108_864,
            "$mode reports the exact child-lifecycle control allocation");
        is($report->{current_match_count}, 1,
            "$mode control preserves the current profile result");
    }
};

subtest 'caller surface rejects unknown modes and profiles' => sub {
    my ($mode_status, $mode_output) = capture_command(
        $script, '--mode', 'borrowed',
    );
    isnt($mode_status, 0, 'unknown process mode rejects');
    like($mode_output, qr/mode must be direct or isolated/,
        'unknown process mode reports the closed vocabulary');

    my ($profile_status, $profile_output) = capture_command(
        $script, '--profile', 'forged-profile-v1',
    );
    isnt($profile_status, 0, 'unknown profile rejects');
    like($profile_output, qr/profile is not selected/,
        'unknown profile reports the inventory boundary');

    my ($allocation_status, $allocation_output) = capture_command(
        $script, '--synthetic-allocation-bytes', 67_108_865,
    );
    isnt($allocation_status, 0, 'cap-plus-one synthetic allocation rejects');
    like($allocation_output, qr/integer from 0 through 67108864/,
        'cap-plus-one reports the bounded control envelope');
};

done_testing;

sub slurp_raw {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "cannot read $path: $!\n";
    local $/;
    my $content = <$fh>;
    close $fh or die "cannot close $path: $!\n";
    return $content;
}

sub capture_command {
    my (@command) = @_;
    my $stderr = gensym;
    my $stdout;
    my $pid = eval { open3(undef, $stdout, $stderr, @command) };
    return (127, '') unless defined $pid;
    my $output = do { local $/; <$stdout> // '' };
    $output .= do { local $/; <$stderr> // '' };
    waitpid($pid, 0);
    my $status = $? & 127 ? 128 + ($? & 127) : $? >> 8;
    return ($status, $output);
}
