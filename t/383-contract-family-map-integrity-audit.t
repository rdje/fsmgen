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

subtest 'direct support contracts keep grouped discovery maps internally consistent' => sub {
    my $payload = build_direct_contract_payload();
    assert_family_map_integrity($payload, 'direct support contracts');
};

subtest 'capability manifest keeps grouped discovery maps internally consistent' => sub {
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
        assert_family_map_integrity($view->{payload}, $view->{label});
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

sub assert_family_map_integrity {
    my ($payload, $label) = @_;
    my @maps = collect_family_maps($payload, $label);

    ok(@maps, "$label publishes grouped discovery maps");

    for my $entry (@maps) {
        my $map = $entry->{value};
        my $path = $entry->{path};
        my $parent = $entry->{parent};

        ok(ref($map) eq 'HASH', "$path is a hash");
        next unless ref($map) eq 'HASH';

        ok(keys(%$map) > 0, "$path is non-empty");

        for my $family (sort keys %$map) {
            my $values = $map->{$family};
            my $family_path = "$path.$family";

            ok(ref($values) eq 'ARRAY', "$family_path is an array");
            next unless ref($values) eq 'ARRAY';

            ok(@$values, "$family_path is non-empty");
            assert_unique_scalar_list($values, $family_path);

            if (ref($parent) eq 'HASH'
                && exists $parent->{$family}
                && ref($parent->{$family}) eq 'ARRAY') {
                is_deeply(
                    $values,
                    $parent->{$family},
                    "$family_path matches sibling $family",
                );
            }
        }
    }
}

sub assert_unique_scalar_list {
    my ($values, $path) = @_;
    my %seen;

    for my $value (@$values) {
        ok(!ref($value), "$path entry '$value' is scalar");
        next if ref($value);
        ok(length($value), "$path entry '$value' is non-empty");
        ok(!$seen{$value}++, "$path does not duplicate '$value'");
    }
}

sub collect_family_maps {
    my ($value, $path, $parent) = @_;
    my @maps;

    return @maps unless ref($value);

    if (ref($value) eq 'HASH') {
        for my $key (sort keys %$value) {
            my $child_path = "$path.$key";

            if (is_grouped_discovery_map_name($key)) {
                push @maps, {
                    path => $child_path,
                    value => $value->{$key},
                    parent => $value,
                };
                next;
            }

            push @maps, collect_family_maps($value->{$key}, $child_path, $value);
        }
        return @maps;
    }

    if (ref($value) eq 'ARRAY') {
        for my $index (0 .. $#$value) {
            push @maps, collect_family_maps($value->[$index], "$path\[$index]", $value);
        }
        return @maps;
    }

    return @maps;
}

sub is_grouped_discovery_map_name {
    my ($key) = @_;
    return 1 if $key =~ /\A(?:presence_key_family_map|nested_presence_key_map|top_level_section_presence_key_map|constructor_option_family_map|name_family_map|family_map)\z/;
    return 1 if $key =~ /(?:_presence_key_family_map|_nested_presence_key_map)\z/;
    return 0;
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

sub module_name_from_file {
    my ($file) = @_;
    my $base = File::Spec->abs2rel($file, File::Spec->catdir($repo_root, 'perl'));
    $base =~ s{\.pm$}{};
    $base =~ s{[/\\]}{::}g;
    return $base;
}
