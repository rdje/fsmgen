#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP qw(decode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::CapabilityManifest qw(build_capability_manifest);

my $repo_root = File::Spec->catdir($FindBin::Bin, '..');

subtest 'direct support contracts publish existing local test provenance' => sub {
    my $payload = build_direct_contract_payload();
    assert_tested_by_provenance($payload, 'direct support contracts');
};

subtest 'capability manifest publishes existing local test provenance' => sub {
    my @views = (
        {
            label => 'in-process capability manifest',
            payload => build_capability_manifest(),
        },
        {
            label => 'CLI capability manifest',
            payload => run_capability_manifest('--capability-manifest'),
        },
        {
            label => 'CLI alias capability manifest',
            payload => run_capability_manifest('--emit-capability-manifest'),
        },
    );

    for my $view (@views) {
        assert_tested_by_provenance($view->{payload}, $view->{label});
    }
};

done_testing();

sub build_direct_contract_payload {
    my $support_dir = File::Spec->catdir($repo_root, 'perl', 'FSM', 'Support');
    my @contract_files = sort glob(File::Spec->catfile($support_dir, '*Contract.pm'));
    my %contracts;

    ok(@contract_files, 'found support contract modules to inspect');

    for my $file (@contract_files) {
        my $module = module_name_from_file($file);
        require_ok($module);

        no strict 'refs';
        my @builders = grep { /^build_.*_contract$/ } @{"${module}::EXPORT_OK"};
        use strict 'refs';

        next unless @builders == 1;

        no strict 'refs';
        my $builder = \&{"${module}::$builders[0]"};
        use strict 'refs';

        $contracts{$module} = $builder->();
    }

    return \%contracts;
}

sub assert_tested_by_provenance {
    my ($payload, $label) = @_;
    my @entries = collect_tested_by_entries($payload, $label);

    ok(@entries, "$label publishes at least one tested_by list");

    for my $entry (@entries) {
        my $path = $entry->{path};
        my $value = $entry->{value};

        ok(ref($value) eq 'ARRAY', "$path is an array");
        next unless ref($value) eq 'ARRAY';

        ok(@$value, "$path is non-empty");

        my %seen;
        for my $test_path (@$value) {
            ok(!ref($test_path), "$path entry '$test_path' is a scalar path");
            next if ref($test_path);

            ok(!$seen{$test_path}++, "$path does not duplicate '$test_path'");
            ok(
                !File::Spec->file_name_is_absolute($test_path),
                "$path entry '$test_path' is repo-relative",
            );
            unlike(
                $test_path,
                qr{(?:\A|/)\.\.(?:/|\z)},
                "$path entry '$test_path' does not escape the repo",
            );
            like(
                $test_path,
                qr{\At/[^/].*\.t\z},
                "$path entry '$test_path' points at a test file",
            );
            ok(
                -f repo_file($test_path),
                "$path entry '$test_path' exists on disk",
            );
        }
    }
}

sub collect_tested_by_entries {
    my ($value, $path) = @_;
    my @entries;

    return @entries unless ref($value);

    if (ref($value) eq 'HASH') {
        for my $key (sort keys %$value) {
            my $child_path = "$path.$key";
            if ($key eq 'tested_by') {
                push @entries, {
                    path => $child_path,
                    value => $value->{$key},
                };
                next;
            }
            push @entries, collect_tested_by_entries($value->{$key}, $child_path);
        }
        return @entries;
    }

    if (ref($value) eq 'ARRAY') {
        for my $index (0 .. $#$value) {
            push @entries, collect_tested_by_entries($value->[$index], "$path\[$index]");
        }
        return @entries;
    }

    return @entries;
}

sub run_capability_manifest {
    my ($mode) = @_;
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', $mode],
    );

    ok($success, "$mode succeeds");
    is(join('', @{$stderr_buf || []}), '', "$mode keeps stderr clean");

    return decode_json(join('', @{$stdout_buf || []}));
}

sub repo_file {
    my ($relpath) = @_;
    return File::Spec->catfile($repo_root, split m{/}, $relpath);
}

sub module_name_from_file {
    my ($file) = @_;
    my $base = File::Spec->abs2rel($file, File::Spec->catdir($repo_root, 'perl'));
    $base =~ s{\.pm$}{};
    $base =~ s{[/\\]}{::}g;
    return $base;
}
