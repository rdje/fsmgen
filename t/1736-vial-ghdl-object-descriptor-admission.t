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
my $stage_rel = ".artifacts/tmp/tests/vial-ghdl-object-admission-$$";
my $stage_abs = File::Spec->catdir(
    $repo_root, split(m{/}, $stage_rel),
);
my $objects_abs = File::Spec->catdir($stage_abs, 'objects');
my $owned_root = $stage_abs;

END {
    remove_tree($owned_root)
        if defined($owned_root) && -d $owned_root && !-l $owned_root;
}

make_path($objects_abs);

my $content = "sealed GHDL object\n";
my $digest = sha256_hex($content);
my $object_abs = File::Spec->catfile($objects_abs, $digest);
open my $object_fh, '>:raw', $object_abs
    or die "cannot create focused GHDL object: $!\n";
print {$object_fh} $content
    or die "cannot write focused GHDL object: $!\n";
close $object_fh or die "cannot close focused GHDL object: $!\n";
chmod 0600, $object_abs
    or die "cannot seal focused GHDL object mode: $!\n";

my $session = {
    repo_root => $repo_root,
    root_device => $root_stat[0],
    stage_rel => $stage_rel,
    stage_abs => $stage_abs,
};
my $object = {
    kind => 'lifecycle_authority',
    sha256 => $digest,
    bytes => length($content),
    executable => JSON::PP::false,
    relative_path => "$stage_rel/objects/$digest",
};

subtest 'descriptor fields retain exact JSON types and vocabularies' => sub {
    ok(validate_objects($session, [clone($object)]),
        'canonical non-executable descriptor admits');

    my $foreign_kind = clone($object);
    $foreign_kind->{kind} = 'foreign/kind';
    rejects_objects($session, [$foreign_kind],
        'foreign object-kind spelling rejects');

    my $string_bytes = clone($object);
    $string_bytes->{bytes} = sprintf('%d', $object->{bytes});
    is($JSON->encode($string_bytes->{bytes}),
        '"' . length($content) . '"',
        'byte-count forgery is a JSON string control');
    rejects_objects($session, [$string_bytes],
        'numeric-looking string byte count rejects');

    my $numeric_executable = clone($object);
    $numeric_executable->{executable} = 0;
    rejects_objects($session, [$numeric_executable],
        'numeric false executable flag rejects');
};

subtest 'descriptor executable authority matches the exact file mode' => sub {
    chmod 0700, $object_abs
        or die "cannot change focused GHDL object mode: $!\n";
    rejects_objects($session, [clone($object)],
        'non-executable descriptor rejects executable object mode');

    my $executable = clone($object);
    $executable->{executable} = JSON::PP::true;
    ok(validate_objects($session, [$executable]),
        'canonical executable descriptor admits exact executable mode');

    chmod 0600, $object_abs
        or die "cannot restore focused GHDL object mode: $!\n";
    rejects_objects($session, [$executable],
        'executable descriptor rejects non-executable object mode');
    ok(validate_objects($session, [clone($object)]),
        'restored non-executable descriptor and mode admit');
};

remove_tree($owned_root);
$owned_root = undef;
ok(!-e $stage_abs && !-l $stage_abs,
    'focused same-volume object tree is removed exactly');

done_testing();

sub validate_objects {
    my ($session, $objects) = @_;
    return eval {
        FSM::VIAL::Backend::GHDLLifecycle::_validate_objects(
            $session, $objects,
        );
        1;
    } ? 1 : 0;
}

sub rejects_objects {
    my ($session, $objects, $label) = @_;
    my $ok = eval {
        FSM::VIAL::Backend::GHDLLifecycle::_validate_objects(
            $session, $objects,
        );
        1;
    };
    return unless ok(!$ok, $label);
    isa_ok($@, 'FSM::VIAL::Backend::GHDLLifecycle::Failure');
    is(ref($@) ? $@->{code} : undef,
        'VIAL_GHDL_LIFECYCLE_OBJECT_ERROR',
        "$label uses object-admission authority");
}

sub clone {
    return $JSON->decode($JSON->encode($_[0]));
}
