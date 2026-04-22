#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Basename qw(basename);
use File::Spec;
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP qw(decode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::CapabilityManifestContract qw(build_capability_manifest_contract);

my $expected_contract = build_capability_manifest_contract();
my @section_specs = discover_section_specs();

my @manifest_views = (
    {
        label => 'in-process capability manifest',
        manifest => build_capability_manifest(),
    },
    {
        label => 'CLI capability manifest',
        manifest => run_capability_manifest('--capability-manifest'),
    },
    {
        label => 'CLI alias capability manifest',
        manifest => run_capability_manifest('--emit-capability-manifest'),
    },
);

subtest 'top-level contract-source discovery map matches the section builders' => sub {
    for my $spec (@section_specs) {
        my $payload = $spec->{builder}->();
        my $contract_key = discover_contract_key($payload, $spec->{module});
        my $contract_source = $payload->{$contract_key}{contract_source};

        is(
            $expected_contract->{top_level_contract_source_map}{$spec->{section}},
            $contract_source,
            "$spec->{section} keeps its advertised top-level contract owner aligned with the section builder",
        );
    }
};

subtest 'top-level section presence-key discovery map matches the section builders' => sub {
    for my $spec (@section_specs) {
        my $payload = $spec->{builder}->();
        is_deeply(
            [sort keys %{$payload || {}}],
            [sort @{$expected_contract->{top_level_section_presence_key_map}{$spec->{section}} || []}],
            "$spec->{section} keeps its advertised top-level key family aligned with the section builder",
        );
    }
};

subtest 'live manifest views keep section discovery maps aligned with section payloads' => sub {
    for my $view (@manifest_views) {
        my $manifest = $view->{manifest};
        my $label = $view->{label};
        my $contract = $manifest->{manifest_contract};

        for my $spec (@section_specs) {
            my $payload = $manifest->{$spec->{section}};
            my $contract_key = discover_contract_key($payload, "$label $spec->{section}");

            is(
                $payload->{$contract_key}{contract_source},
                $contract->{top_level_contract_source_map}{$spec->{section}},
                "$label keeps $spec->{section} contract owner aligned with the grouped discovery map",
            );
            is_deeply(
                [sort keys %{$payload || {}}],
                [sort @{$contract->{top_level_section_presence_key_map}{$spec->{section}} || []}],
                "$label keeps $spec->{section} top-level keys aligned with the grouped discovery map",
            );
        }
    }
};

done_testing();

sub run_capability_manifest {
    my ($mode) = @_;
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', $mode],
    );

    ok($success, "$mode succeeds");
    is(join('', @{$stderr_buf || []}), '', "$mode keeps stderr clean");

    return decode_json(join('', @{$stdout_buf || []}));
}

sub discover_section_specs {
    my $support_dir = File::Spec->catdir($FindBin::Bin, '..', 'perl', 'FSM', 'Support');
    my @files = sort glob File::Spec->catfile($support_dir, '*Section.pm');
    my @specs;

    for my $file (@files) {
        my $module_basename = basename($file, '.pm');
        my $stem = $module_basename;
        $stem =~ s/Section\z//;
        my $section = camel_to_snake($stem);
        my $module = "FSM::Support::$module_basename";
        eval "require $module; 1" or die "Failed to load $module: $@";

        my $builder_name = "build_${section}_section";
        no strict 'refs';
        my $builder = *{"${module}::$builder_name"}{CODE};
        use strict 'refs';

        push @specs, {
            section => $section,
            module => $module,
            builder => $builder,
        };
    }

    return @specs;
}

sub discover_contract_key {
    my ($payload, $label) = @_;
    my @contract_keys = grep { exists $payload->{$_} } qw(section_contract surface_contract);
    is(
        scalar(@contract_keys),
        1,
        "$label exposes exactly one top-level contract key",
    );
    return $contract_keys[0];
}

sub camel_to_snake {
    my ($name) = @_;
    $name =~ s/([a-z0-9])([A-Z])/$1_$2/g;
    return lc($name);
}
