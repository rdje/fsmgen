#!/usr/bin/env perl

use strict;
use warnings;

use Cwd qw(abs_path);
use File::Path qw(make_path remove_tree);
use File::Spec;
use FindBin;
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::Backend::GHDLLifecycle;

my $PUBLICATION_BYTES = 67_108_864;

subtest 'report-only aggregate admits the exact publication boundary' => sub {
    my $total = eval {
        FSM::VIAL::Backend::GHDLLifecycle::_preflight_osvvm_report_bytes(
            [
                {name => 'OsvvmRun.yml', bytes => 16_777_216},
                {name => 'AlertLogTop_alerts.yml', bytes => 16_777_216},
                {name => 'AlertLogTop_cov.yml', bytes => 16_777_216},
                {name => 'AlertLogTop_sb_slv.yml', bytes => 16_777_216},
            ],
            $PUBLICATION_BYTES,
        );
    };
    is($@, '', 'exact report-only boundary is admitted');
    is($total, $PUBLICATION_BYTES,
        'preflight returns the exact aggregate report bytes');
};

subtest 'one adjacent report byte rejects with stable authority' => sub {
    my $error = preflight_failure([
        {name => 'OsvvmRun.yml', bytes => $PUBLICATION_BYTES},
        {name => 'AlertLogTop_alerts.yml', bytes => 1},
        {name => 'AlertLogTop_cov.yml', bytes => 0},
        {name => 'AlertLogTop_sb_slv.yml', bytes => 0},
    ]);
    isa_ok($error, 'FSM::VIAL::Backend::GHDLLifecycle::Failure');
    is(ref($error) ? $error->{code} : undef,
        'VIAL_GHDL_LIFECYCLE_LIMIT_ERROR',
        'adjacent report bytes use the lifecycle limit diagnostic');
    is(ref($error) ? $error->{path} : undef, '/ran/provider_reports',
        'adjacent report bytes point to the provider-report boundary');
};

subtest 'known adjacent excess rejects before report reads or object writes' => sub {
    my ($session, $owned_root) = report_session();
    my ($read_count, $write_count) = (0, 0);
    my $error;
    {
        no warnings 'redefine';
        local *FSM::VIAL::Backend::GHDLLifecycle::_osvvm_report_file_bytes =
            sub {
                return $_[0] =~ /OsvvmRun[.]yml\z/
                    ? $PUBLICATION_BYTES : 1;
            };
        local *FSM::VIAL::Backend::GHDLLifecycle::_slurp = sub {
            ++$read_count;
            die "provider report was read before byte admission\n";
        };
        local *FSM::VIAL::Backend::GHDLLifecycle::_write_object = sub {
            ++$write_count;
            die "provider report object was written before byte admission\n";
        };
        my $ok = eval {
            FSM::VIAL::Backend::GHDLLifecycle::_snapshot_osvvm_reports(
                $session, 0,
            );
            1;
        };
        ok(!$ok, 'known adjacent report-only excess rejects');
        $error = $@;
    }
    is($read_count, 0, 'known excess performs zero report reads');
    is($write_count, 0, 'known excess performs zero object writes');
    isa_ok($error, 'FSM::VIAL::Backend::GHDLLifecycle::Failure');
    is(ref($error) ? $error->{code} : undef,
        'VIAL_GHDL_LIFECYCLE_LIMIT_ERROR',
        'pre-read rejection retains the lifecycle limit diagnostic');
    remove_tree($owned_root);
    ok(!-e $owned_root, 'focused report staging is removed exactly');
};

subtest 'post-preflight report size drift rejects before object writes' => sub {
    my ($session, $owned_root) = report_session();
    my ($read_count, $write_count) = (0, 0);
    my $error;
    {
        no warnings 'redefine';
        local *FSM::VIAL::Backend::GHDLLifecycle::_osvvm_report_file_bytes =
            sub { 0 };
        local *FSM::VIAL::Backend::GHDLLifecycle::_slurp = sub {
            ++$read_count;
            return "changed\n";
        };
        local *FSM::VIAL::Backend::GHDLLifecycle::_write_object = sub {
            ++$write_count;
            die "changed provider report reached object persistence\n";
        };
        my $ok = eval {
            FSM::VIAL::Backend::GHDLLifecycle::_snapshot_osvvm_reports(
                $session, 0,
            );
            1;
        };
        ok(!$ok, 'report size drift rejects');
        $error = $@;
    }
    is($read_count, 1, 'size drift is detected on the first report read');
    is($write_count, 0, 'size drift performs zero object writes');
    isa_ok($error, 'FSM::VIAL::Backend::GHDLLifecycle::Failure');
    is(ref($error) ? $error->{code} : undef,
        'VIAL_GHDL_LIFECYCLE_OBJECT_ERROR',
        'size drift uses the lifecycle object-integrity diagnostic');
    is(ref($error) ? $error->{path} : undef,
        '/ran/provider_reports/0',
        'size drift points to the first changed provider report');
    remove_tree($owned_root);
    ok(!-e $owned_root, 'size-drift staging is removed exactly');
};

done_testing();

sub preflight_failure {
    my ($reports) = @_;
    my $ok = eval {
        FSM::VIAL::Backend::GHDLLifecycle::_preflight_osvvm_report_bytes(
            $reports, $PUBLICATION_BYTES,
        );
        1;
    };
    ok(!$ok, 'controlled report-byte excess rejects');
    return $@;
}

sub report_session {
    my $repo_root = abs_path(File::Spec->catdir($FindBin::Bin, '..'));
    my @root_stat = stat($repo_root);
    my $stage_rel = ".artifacts/tmp/tests/vial-ghdl-report-preflight-$$";
    my $owned_root = File::Spec->catdir(
        $repo_root, split(m{/}, $stage_rel),
    );
    my $report_root = File::Spec->catdir($owned_root, 'provider_reports');
    make_path($report_root);
    my @name = qw(
        OsvvmRun.yml AlertLogTop_alerts.yml AlertLogTop_cov.yml
        AlertLogTop_sb_slv.yml
    );
    my @authority;
    for my $name (@name) {
        my $path = File::Spec->catfile($report_root, $name);
        open my $fh, '>:raw', $path or die "cannot create report control: $!\n";
        close $fh or die "cannot close report control: $!\n";
        push @authority, {
            name => $name,
            relpath => "$stage_rel/provider_reports/$name",
        };
    }
    return ({
        repo_root => $repo_root,
        root_device => $root_stat[0],
        stage_rel => $stage_rel,
        commands => {provider_reports => \@authority},
        objects => [],
    }, $owned_root);
}
