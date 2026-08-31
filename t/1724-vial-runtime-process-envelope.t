#!/usr/bin/env perl

use strict;
use warnings;

use File::Path qw(make_path remove_tree);
use File::Spec;
use FindBin;
use JSON::PP ();
use Scalar::Util qw(blessed);
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::Backend::ProcessSupervisor;
use FSM::VIAL::Backend::VerilatorLifecycle;

my $repo_root = File::Spec->rel2abs(
    File::Spec->catdir($FindBin::Bin, '..'),
);
my $stage_rel = ".artifacts/test/vial-runtime-process-envelope-$$";
my $stage_abs = File::Spec->catdir($repo_root, split m{/}, $stage_rel);

END {
    remove_tree($stage_abs)
        if -d $stage_abs && !-l $stage_abs;
}

my %error;
for my $path (qw(/tool_profile /compile /run)) {
    my $caught = capture_failure($path);
    ok(
        blessed($caught)
            && $caught->isa(
                'FSM::VIAL::Backend::VerilatorLifecycle::Failure'
            ),
        "$path supervisor failure remains a lifecycle failure",
    );
    is(
        blessed($caught) ? $caught->{code} : '',
        'VIAL_RUN_HOST_ERROR',
        "$path supervisor failure uses the stable host-error code",
    );
    is(
        blessed($caught) ? $caught->{path} : '',
        $path,
        "$path supervisor failure retains its exact lifecycle phase",
    );
    $error{$path} = $caught;
}

make_path($stage_abs);
open my $probe, '>', File::Spec->catfile($stage_abs, 'partial-object')
    or die "cannot create lifecycle cleanup probe: $!";
print {$probe} "partial\n"
    or die "cannot write lifecycle cleanup probe: $!";
close $probe or die "cannot close lifecycle cleanup probe: $!";

my $failure = FSM::VIAL::Backend::VerilatorLifecycle::_exception_result(
    $error{'/compile'},
    {
        repo_root => $repo_root,
        root_device => (stat($repo_root))[0],
        stage_rel => $stage_rel,
        stage_abs => $stage_abs,
        stage_created => JSON::PP::true,
        operation_id => 'op-' . ('1' x 64),
        lifecycle_identity => 'lifecycle/' . ('2' x 64),
    },
);
ok(!$failure->{ok}, 'supervisor exception remains an atomic failure');
is(
    $failure->{diagnostics}[0]{path},
    '/compile',
    'failure result retains the compile-phase diagnostic',
);
ok($failure->{cleanup}{removed}, 'failure removes its proven-owned stage');
is_deeply($failure->{cleanup}{residue}, [], 'failure reports zero residue');
ok(!-e $stage_abs && !-l $stage_abs, 'failure leaves no staging root');

done_testing();

sub capture_failure {
    my ($path) = @_;
    no warnings 'redefine';
    local *FSM::VIAL::Backend::ProcessSupervisor::capture = sub {
        die bless {
            code => 'VIAL_PROCESS_RESIDUE_ERROR',
            message => 'selected-tool process group retained a descendant',
            path => '/process',
        }, 'FSM::VIAL::Backend::ProcessSupervisor::Failure';
    };
    my $ok = eval {
        FSM::VIAL::Backend::VerilatorLifecycle::_capture_process(
            {
                repo_root => $repo_root,
                storage_context => {
                    containment => 'lifecycle_process_group',
                },
            },
            [$^X, '-e', 'exit 0'],
            10,
            65_536,
            $path,
        );
        1;
    };
    return '' if $ok;
    return $@;
}
