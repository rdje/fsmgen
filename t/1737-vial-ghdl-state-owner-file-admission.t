#!/usr/bin/env perl

use strict;
use warnings;

use Cwd qw(abs_path);
use Digest::SHA qw(sha256_hex);
use File::Path qw(make_path remove_tree);
use File::Spec;
use JSON::PP ();
use Test::More;

use lib 'perl';

use FSM::VIAL::Backend::GHDLLifecycle;

my $JSON = JSON::PP->new->canonical(1);
my $repo_root = abs_path('.');
my @root_stat = stat($repo_root);
my $stage_rel = ".artifacts/tmp/tests/vial-ghdl-state-owner-admission-$$";
my $stage_abs = File::Spec->catdir(
    $repo_root, split(m{/}, $stage_rel),
);
my $states_abs = File::Spec->catdir($stage_abs, 'states');
my $owned_root = $stage_abs;

END {
    remove_tree($owned_root)
        if defined($owned_root) && -d $owned_root && !-l $owned_root;
}

make_path($states_abs);

my $authority = {
    schema => 'focused.ghdl.authority.v1',
    schema_version => 1,
};
my $session = {
    repo_root => $repo_root,
    root_device => $root_stat[0],
    stage_rel => $stage_rel,
    stage_abs => $stage_abs,
    state_schema => 'fsmgen.vial_ghdl_lifecycle_state.v1',
    schema_version => 1,
    lifecycle_identity => 'lifecycle/' . ('1' x 64),
    authority => $authority,
};
my $state_rel = "$stage_rel/states/00-focused.json";
my $state_abs = File::Spec->catfile($states_abs, '00-focused.json');
my $owner_abs = File::Spec->catfile($stage_abs, '.owner.json');

subtest 'state file size and mode are admitted before JSON semantics' => sub {
    ok(FSM::VIAL::Backend::GHDLLifecycle->can('_read_state'),
        'state-file admission seam exists') or return;

    no warnings 'redefine';
    local *FSM::VIAL::Backend::GHDLLifecycle::_validate_state_shape = sub { 1 };

    my $control = state_record($session, {});
    write_json_line($state_abs, $control, 0600);
    ok(read_state($session, $state_rel),
        'canonical sub-limit state at mode 0600 admits');

    chmod 0644, $state_abs
        or die "cannot change focused GHDL state mode: $!\n";
    rejects_state($session, $state_rel,
        'content-correct state with foreign mode rejects');

    my $oversized = state_record(
        $session, {padding => 'x' x 1_048_576},
    );
    write_json_line($state_abs, $oversized, 0600);
    cmp_ok(-s $state_abs, '>', 1_048_576,
        'state byte-excess control is larger than one MiB');
    rejects_state($session, $state_rel,
        'canonical state over one MiB rejects before decode');

    write_json_line($state_abs, $control, 0600);
    ok(read_state($session, $state_rel),
        'restored state file admits');
};

subtest 'owner marker is one small closed numeric-version 0600 file' => sub {
    ok(FSM::VIAL::Backend::GHDLLifecycle->can('_owner_matches'),
        'owner-marker admission seam exists') or return;

    my $control = owner_record($session);
    write_json_line($owner_abs, $control, 0600);
    ok(owner_matches($session), 'canonical owner marker admits');

    chmod 0644, $owner_abs
        or die "cannot change focused GHDL owner mode: $!\n";
    ok(!owner_matches($session),
        'content-correct owner marker with foreign mode rejects');

    my $string_version = clone($control);
    $string_version->{schema_version} = sprintf('%d', 1);
    is($JSON->encode($string_version->{schema_version}), '"1"',
        'owner schema-version forgery is a JSON string control');
    write_json_line($owner_abs, $string_version, 0600);
    ok(!owner_matches($session),
        'numeric-looking owner schema-version string rejects');

    my $open_shape = clone($control);
    $open_shape->{foreign} = 'field';
    write_json_line($owner_abs, $open_shape, 0600);
    ok(!owner_matches($session), 'foreign owner-marker field rejects');

    my $large_identity = 'lifecycle/' . ('x' x 4_096);
    my $large_session = {%$session, lifecycle_identity => $large_identity};
    my $oversized = owner_record($large_session);
    write_json_line($owner_abs, $oversized, 0600);
    cmp_ok(-s $owner_abs, '>', 4_096,
        'owner byte-excess control is larger than four KiB');
    ok(!owner_matches($large_session),
        'canonical owner marker over four KiB rejects before decode');

    write_json_line($owner_abs, $control, 0600);
    ok(owner_matches($session), 'restored owner marker admits');
};

remove_tree($owned_root);
$owned_root = undef;
ok(!-e $stage_abs && !-l $stage_abs,
    'focused same-volume state/owner tree is removed exactly');

done_testing();

sub state_record {
    my ($session, $evidence) = @_;
    my $record = {
        schema => $session->{state_schema},
        schema_version => $session->{schema_version},
        lifecycle_identity => $session->{lifecycle_identity},
        state => 'admitted',
        ordinal => 0,
        state_identity => undef,
        predecessor_identity => undef,
        predecessor_relpath => undef,
        next_state => 'prepared',
        authority => clone($session->{authority}),
        objects => [],
        evidence => $evidence,
    };
    my $copy = clone($record);
    $copy->{state_identity} = undef;
    $record->{state_identity} =
        'state/' . sha256_hex($JSON->encode($copy));
    return $record;
}

sub owner_record {
    my ($session) = @_;
    return {
        schema => 'fsmgen.vial_ghdl_lifecycle_owner.v1',
        schema_version => 1,
        lifecycle_identity => $session->{lifecycle_identity},
        staging_identity => $session->{stage_rel},
    };
}

sub write_json_line {
    my ($path, $value, $mode) = @_;
    open my $fh, '>:raw', $path
        or die "cannot create focused GHDL admission file: $!\n";
    print {$fh} $JSON->encode($value), "\n"
        or die "cannot write focused GHDL admission file: $!\n";
    close $fh or die "cannot close focused GHDL admission file: $!\n";
    chmod $mode, $path
        or die "cannot seal focused GHDL admission mode: $!\n";
}

sub read_state {
    my ($session, $relative) = @_;
    return eval {
        FSM::VIAL::Backend::GHDLLifecycle::_read_state(
            $session, $relative,
        );
        1;
    } ? 1 : 0;
}

sub rejects_state {
    my ($session, $relative, $label) = @_;
    my $ok = eval {
        FSM::VIAL::Backend::GHDLLifecycle::_read_state(
            $session, $relative,
        );
        1;
    };
    return unless ok(!$ok, $label);
    isa_ok($@, 'FSM::VIAL::Backend::GHDLLifecycle::Failure');
    is(ref($@) ? $@->{code} : undef,
        'VIAL_GHDL_LIFECYCLE_STATE_ERROR',
        "$label uses state-admission authority");
}

sub owner_matches {
    my ($session) = @_;
    return FSM::VIAL::Backend::GHDLLifecycle::_owner_matches($session)
        ? 1 : 0;
}

sub clone {
    return $JSON->decode($JSON->encode($_[0]));
}
