#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::EmbeddingContract qw(
    embedding_nested_contract_keys
    embedding_public_top_level_keys
);
use FSM::Support::EmbeddingSection qw(build_embedding_section);
use FSM::Support::ExtensionContract qw(build_extension_contract);
use FSM::Support::HDLGeneratorResultContract qw(build_hdl_generator_result_contract);
use FSM::Support::ISFPublicInterfaceContract qw(build_isf_public_interface_contract);
use FSM::Support::SerializablePlanReportContract qw(build_serializable_plan_report_contract);

my $sentinel = '__mutated_by_t437__';

subtest 'embedding section builder returns fresh nested structures' => sub {
    my $first = build_embedding_section();
    mutate_structure($first);

    my $second = build_embedding_section();
    ok(!contains_sentinel($second), 'fresh build_embedding_section result is not affected by prior caller mutation');
    is_deeply(
        sorted([keys %{$second}]),
        sorted(embedding_public_top_level_keys()),
        'fresh embedding section still has exactly the advertised top-level keys after prior mutation',
    );
    is_deeply(
        sorted($second->{section_contract}{public_top_level_presence_keys}),
        sorted(embedding_public_top_level_keys()),
        'fresh embedding section contract still advertises the top-level keys after prior mutation',
    );
    is_deeply(
        sorted($second->{section_contract}{nested_contract_keys}),
        sorted(embedding_nested_contract_keys()),
        'fresh embedding section contract still advertises the nested contract keys after prior mutation',
    );
};

subtest 'embedding section child contracts remain fresh and aligned' => sub {
    my $first = build_embedding_section();
    $first->{typed_extensions}{hook_names}[0] = $sentinel;
    $first->{hdl_generator_result}{known_top_level_keys}[0] = $sentinel;
    $first->{isf_public_interface}{parser_method_names}[0] = $sentinel;
    $first->{serializable_plan_reports}{json_safe_surface_keys}[0] = $sentinel;
    push @{$first->{section_contract}{nested_presence_key_map}{typed_extensions}}, $sentinel;

    my $second = build_embedding_section();
    ok(!contains_sentinel($second->{typed_extensions}), 'fresh typed_extensions child contract is not polluted');
    ok(!contains_sentinel($second->{hdl_generator_result}), 'fresh hdl_generator_result child contract is not polluted');
    ok(!contains_sentinel($second->{isf_public_interface}), 'fresh isf_public_interface child contract is not polluted');
    ok(!contains_sentinel($second->{serializable_plan_reports}), 'fresh serializable_plan_reports child contract is not polluted');
    ok(!contains_sentinel($second->{section_contract}{nested_presence_key_map}), 'fresh nested_presence_key_map is not polluted');
    is_deeply(
        $second->{typed_extensions},
        build_extension_contract(),
        'fresh embedding section embeds a clean typed-extension contract',
    );
    is_deeply(
        $second->{hdl_generator_result},
        build_hdl_generator_result_contract(),
        'fresh embedding section embeds a clean HDLGenerator result contract',
    );
    is_deeply(
        $second->{isf_public_interface},
        build_isf_public_interface_contract(),
        'fresh embedding section embeds a clean ISF public-interface contract',
    );
    is_deeply(
        $second->{serializable_plan_reports},
        build_serializable_plan_report_contract(),
        'fresh embedding section embeds a clean serializable plan/report contract',
    );
};

done_testing();

sub mutate_structure {
    my ($value) = @_;
    return unless ref($value);

    if (ref($value) eq 'ARRAY') {
        push @{$value}, $sentinel;
        mutate_structure($_) for @{$value};
        return;
    }

    if (ref($value) eq 'HASH') {
        $value->{$sentinel} = $sentinel;
        mutate_structure($_) for values %{$value};
        return;
    }
}

sub contains_sentinel {
    my ($value) = @_;
    return 1 if defined($value) && !ref($value) && $value eq $sentinel;
    return 0 unless ref($value);

    if (ref($value) eq 'ARRAY') {
        for my $entry (@{$value}) {
            return 1 if contains_sentinel($entry);
        }
        return 0;
    }

    if (ref($value) eq 'HASH') {
        return 1 if exists($value->{$sentinel});
        for my $entry (values %{$value}) {
            return 1 if contains_sentinel($entry);
        }
        return 0;
    }

    return 0;
}

sub sorted {
    my ($values) = @_;
    return [sort @{$values || []}];
}
