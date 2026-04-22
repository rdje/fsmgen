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

my $manifest_contract = build_capability_manifest_contract();
my @expected_sections = sort keys %{$manifest_contract->{top_level_contract_source_map} || {}};
my @section_specs = discover_section_specs();
my @discovered_sections = map { $_->{section} } @section_specs;

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

subtest 'top-level public manifest sections all have dedicated section modules' => sub {
    is_deeply(
        \@discovered_sections,
        \@expected_sections,
        'discovered section modules match the public top-level manifest sections exactly',
    );
};

subtest 'section builders follow the common builder naming convention' => sub {
    for my $spec (@section_specs) {
        ok(
            $spec->{builder},
            "$spec->{module} exposes $spec->{builder_name}",
        );
    }
};

subtest 'section builders return bounded contract-carrying hashes' => sub {
    for my $spec (@section_specs) {
        my $payload = $spec->{builder}->();

        ok(ref($payload) eq 'HASH', "$spec->{module} returns a hashref");

        my @contract_keys = grep { exists $payload->{$_} } qw(section_contract surface_contract);
        is(
            scalar(@contract_keys),
            1,
            "$spec->{module} exposes exactly one top-level contract key",
        );

        my $contract = $payload->{$contract_keys[0]};
        ok(ref($contract) eq 'HASH', "$spec->{module} keeps $contract_keys[0] as a hashref");
        is($contract->{schema_version}, 1, "$spec->{module} keeps schema_version 1");
        is($contract->{status}, 'bounded_public', "$spec->{module} keeps bounded_public status");
        ok(
            defined($contract->{contract_source}) && !ref($contract->{contract_source}) && length($contract->{contract_source}),
            "$spec->{module} keeps a non-empty contract_source",
        );
    }
};

subtest 'every manifest view keeps top-level sections as exact dedicated-builder projections' => sub {
    for my $view (@manifest_views) {
        my $manifest = $view->{manifest};
        my $label = $view->{label};

        for my $spec (@section_specs) {
            is_deeply(
                $manifest->{$spec->{section}},
                $spec->{builder}->(),
                "$label keeps $spec->{section} as an exact dedicated-builder projection",
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
            builder_name => $builder_name,
            builder => $builder,
        };
    }

    return @specs;
}

sub camel_to_snake {
    my ($name) = @_;
    $name =~ s/([a-z0-9])([A-Z])/$1_$2/g;
    return lc($name);
}
