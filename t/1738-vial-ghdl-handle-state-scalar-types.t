#!/usr/bin/env perl

use strict;
use warnings;

use Cwd qw(abs_path);
use Digest::SHA qw(sha256_hex);
use File::Basename qw(dirname);
use File::Path qw(make_path remove_tree);
use File::Spec;
use JSON::PP ();
use Test::More;

use lib 'perl';

use FSM::VIAL::Backend::GHDLLifecycle;
use FSM::VIAL::Backend::VHDLPortableTraceValidator;

my $JSON = JSON::PP->new->canonical(1);
my $repo_root = abs_path('.');
my $test_rel = ".artifacts/tmp/tests/vial-ghdl-scalar-types-$$";
my $test_abs = repo_path($test_rel);
my $source_rel = "$test_rel/source/input.vhd";
my $source_abs = repo_path($source_rel);
my $case = 0;
my @stage_rel;

END {
    for my $stage (@stage_rel) {
        my $absolute = repo_path($stage);
        remove_tree($absolute)
            if -d $absolute && !-l $absolute;
    }
    remove_tree($test_abs)
        if defined($test_abs) && -d $test_abs && !-l $test_abs;
}

write_file($source_abs, "entity input is end entity;\n", 0600);

subtest 'exact handle and state numerics remain admitted JSON numbers' => sub {
    my ($request, $begin) = begin_case('numeric-control');
    return unless $begin->{ok};

    is($JSON->encode($begin->{handle}{schema_version}), '1',
        'handle schema version is a JSON number');
    is($JSON->encode($begin->{handle}{ordinal}), '0',
        'handle ordinal is a JSON number');
    my $state = decode_file(repo_path($begin->{handle}{state_relpath}));
    is($JSON->encode($state->{schema_version}), '1',
        'state schema version is a JSON number');
    is($JSON->encode($state->{ordinal}), '0',
        'state ordinal is a JSON number');

    my $prepared = lifecycle_advance($request, $begin->{handle});
    ok($prepared->{ok}, 'exact numeric handle and state resume');
    cleanup_success($request, $prepared);
};

subtest 'numeric-looking handle values do not impersonate JSON numbers' => sub {
    for my $control (
        [schema_version => sprintf('%d', 1), '"1"', 'string'],
        [ordinal => sprintf('%d', 0), '"0"', 'string'],
        [schema_version => JSON::PP::true, 'true', 'boolean'],
        [ordinal => JSON::PP::false, 'false', 'boolean'],
    ) {
        my ($field, $forged, $encoded, $form) = @$control;
        my ($request, $begin) = begin_case("handle-$field");
        next unless $begin->{ok};
        my $handle = clone($begin->{handle});
        $handle->{$field} = $forged;
        is($JSON->encode($handle->{$field}), $encoded,
            "handle $field forgery is a JSON $form control");

        my $result = lifecycle_advance($request, $handle);
        rejects_resume($result,
            "numeric-looking handle $field $form rejects");
        cleanup_handle_case($request, $begin, $result);
    }
};

subtest 'rehashed state values do not impersonate JSON numbers' => sub {
    for my $control (
        [schema_version => sprintf('%d', 1), '"1"', 'string'],
        [ordinal => sprintf('%d', 0), '"0"', 'string'],
        [schema_version => JSON::PP::true, 'true', 'boolean'],
        [ordinal => JSON::PP::false, 'false', 'boolean'],
    ) {
        my ($field, $forged, $encoded, $form) = @$control;
        my ($request, $begin) = begin_case("state-$field");
        next unless $begin->{ok};
        my $handle = forge_state_field(
            $request, $begin->{handle}, $field, $forged,
        );
        my $state = decode_file(repo_path($handle->{state_relpath}));
        is($JSON->encode($state->{$field}), $encoded,
            "rehashed state $field forgery is a JSON $form control");

        my $result = lifecycle_advance($request, $handle);
        rejects_resume($result,
            "rehashed numeric-looking state $field $form rejects");
        cleanup_state_case($request, $result);
    }
};

ok(!grep({ -e repo_path($_) || -l repo_path($_) } @stage_rel),
    'all focused lifecycle roots are removed exactly');

done_testing();

sub begin_case {
    my ($label) = @_;
    my $request = request_for(++$case, $label);
    my $begin = lifecycle_begin($request);
    diag($JSON->encode($begin->{diagnostics})) unless $begin->{ok};
    ok($begin->{ok}, "$label lifecycle admits exact numeric state");
    return ($request, $begin);
}

sub request_for {
    my ($ordinal, $label) = @_;
    my $provider_root = 't/data/vial_fake_ghdl_provider';
    my $binary = "$provider_root/bin/ghdl";
    my $archive = "$provider_root/ghdl.tar.gz";
    my $stage = '.artifacts/tmp/vial-ghdl-qualification/'
        . sha256_hex("scalar-json-$ordinal-$label-$$");
    push @stage_rel, $stage;
    my $source_set = [{
        relpath => $source_rel,
        bytes => 0 + (-s $source_abs),
        sha256 => file_sha256($source_abs),
    }];
    my $authority =
        FSM::VIAL::Backend::VHDLPortableTraceValidator
            ->checked_reference_authority;
    return {
        repo_root => $repo_root,
        provider => {
            root => $provider_root,
            archive => $archive,
            archive_bytes => 0 + (-s repo_path($archive)),
            archive_sha256 => file_sha256(repo_path($archive)),
            binary => $binary,
            binary_sha256 => file_sha256(repo_path($binary)),
            version_output => 'fake GHDL 1',
        },
        source_set => $source_set,
        source_identity =>
            'source/' . sha256_hex($JSON->encode($source_set)),
        emission_identity =>
            'emission/' . sha256_hex("scalar-types-$label-$$"),
        commands => {
            version => [$binary, '--version'],
            analyze => [
                $binary, '-a', '--std=08', '--work=fsmgen_vial',
                "--workdir=$stage/library", $source_rel,
            ],
            elaborate => [
                $binary, '-e', '--std=08', '--work=fsmgen_vial',
                "--workdir=$stage/library", 'input',
            ],
            run => [
                $binary, '-r', '--std=08', '--work=fsmgen_vial',
                "--workdir=$stage/library", 'input',
                '--assert-level=error',
            ],
        },
        validation => {
            expected_record_counts => reference_counts(),
            %$authority,
            run_repetitions => 2,
        },
        storage_context => {
            schema => 'fsmgen.vial_ghdl_lifecycle_storage.v1',
            schema_version => 1,
            mode => 'qualification',
            staging_identity => $stage,
            containment => 'lifecycle_process_group',
        },
    };
}

sub forge_state_field {
    my ($request, $handle, $field, $value) = @_;
    my $forged_handle = clone($handle);
    my $old_rel = $handle->{state_relpath};
    my $record = decode_file(repo_path($old_rel));
    $record->{$field} = $value;
    $record->{state_identity} = undef;
    my $digest = sha256_hex($JSON->encode($record));
    $record->{state_identity} = "state/$digest";
    my $new_rel = sprintf(
        '%s/states/%02d-%s-%s.json',
        $request->{storage_context}{staging_identity},
        0, 'admitted', $digest,
    );
    unlink repo_path($old_rel)
        or die "cannot replace focused GHDL state: $!\n";
    write_file(repo_path($new_rel), canonical_line($record), 0600);
    $forged_handle->{state_identity} = $record->{state_identity};
    $forged_handle->{state_relpath} = $new_rel;
    return $forged_handle;
}

sub rejects_resume {
    my ($result, $label) = @_;
    my $rejected = ok(!$result->{ok}, $label);
    return unless $rejected;
    is($result->{diagnostics}[0]{code},
        'VIAL_GHDL_LIFECYCLE_STATE_ERROR',
        "$label uses state-admission authority");
}

sub cleanup_handle_case {
    my ($request, $begin, $result) = @_;
    my $handle = $result->{ok} ? $result->{handle} : $begin->{handle};
    my $cleanup = lifecycle_abort($request, $handle);
    ok($cleanup->{ok}, 'handle control remains exactly abortable');
    ok(!-e stage_path($request) && !-l stage_path($request),
        'handle control leaves no staging residue');
}

sub cleanup_state_case {
    my ($request, $result) = @_;
    if ($result->{ok}) {
        cleanup_success($request, $result);
        return;
    }
    ok($result->{cleanup}{removed},
        'rejected forged state reports exact cleanup');
    ok(!-e stage_path($request) && !-l stage_path($request),
        'rejected forged state leaves no staging residue');
}

sub cleanup_success {
    my ($request, $result) = @_;
    my $cleanup = lifecycle_abort($request, $result->{handle});
    ok($cleanup->{ok}, 'accepted numeric control aborts exactly');
    ok($cleanup->{cleanup}{removed},
        'accepted numeric control reports exact cleanup');
    ok(!-e stage_path($request) && !-l stage_path($request),
        'accepted numeric control leaves no staging residue');
}

sub lifecycle_begin {
    return FSM::VIAL::Backend::VHDLPortableGHDLQualification::_ghdl_lifecycle_begin_for_test(
        $_[0],
    );
}

sub lifecycle_advance {
    my ($request, $handle) = @_;
    return FSM::VIAL::Backend::VHDLPortableGHDLQualification::_ghdl_lifecycle_advance_for_test({
            %$request, handle => clone($handle),
        });
}

sub lifecycle_abort {
    my ($request, $handle) = @_;
    return FSM::VIAL::Backend::VHDLPortableGHDLQualification::_ghdl_lifecycle_abort_for_test({
            %$request, handle => clone($handle),
        });
}

sub stage_path {
    return repo_path($_[0]{storage_context}{staging_identity});
}

sub reference_counts {
    return {
        header => 1, scenario_start => 2, events => 2, samples => 35,
        expectations => 2, scoreboards => 2, coverage => 28, faults => 2,
        scenario_end => 2, footer => 1,
    };
}

sub write_file {
    my ($path, $content, $mode) = @_;
    make_path(dirname($path));
    open my $fh, '>:raw', $path
        or die "cannot create focused GHDL file '$path': $!\n";
    print {$fh} $content
        or die "cannot write focused GHDL file '$path': $!\n";
    close $fh
        or die "cannot close focused GHDL file '$path': $!\n";
    chmod $mode, $path
        or die "cannot seal focused GHDL file '$path': $!\n";
}

sub decode_file {
    my ($path) = @_;
    open my $fh, '<:raw', $path
        or die "cannot read focused GHDL file '$path': $!\n";
    local $/;
    my $text = <$fh>;
    close $fh
        or die "cannot close focused GHDL file '$path': $!\n";
    return $JSON->decode($text);
}

sub file_sha256 {
    my ($path) = @_;
    open my $fh, '<:raw', $path
        or die "cannot hash focused GHDL file '$path': $!\n";
    my $sha = Digest::SHA->new(256);
    $sha->addfile($fh);
    close $fh
        or die "cannot close focused GHDL file '$path': $!\n";
    return $sha->hexdigest;
}

sub canonical_line {
    return $JSON->encode($_[0]) . "\n";
}

sub clone {
    return $JSON->decode($JSON->encode($_[0]));
}

sub repo_path {
    return File::Spec->catfile($repo_root, split m{/}, $_[0]);
}

package FSM::VIAL::Backend::VHDLPortableGHDLQualification;

sub _ghdl_lifecycle_begin_for_test {
    return FSM::VIAL::Backend::GHDLLifecycle->begin_session($_[0]);
}

sub _ghdl_lifecycle_advance_for_test {
    return FSM::VIAL::Backend::GHDLLifecycle->advance_session($_[0]);
}

sub _ghdl_lifecycle_abort_for_test {
    return FSM::VIAL::Backend::GHDLLifecycle->abort_session($_[0]);
}

package main;
