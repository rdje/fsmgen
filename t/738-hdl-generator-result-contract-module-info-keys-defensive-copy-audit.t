#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::HDLGeneratorResultContract qw(
    build_hdl_generator_result_contract
    hdl_generator_result_module_info_identity_keys
    hdl_generator_result_module_info_optional_composition_summary_keys
    hdl_generator_result_module_info_summary_keys
);

my $sentinel = '__mutated_by_t738__';

subtest 'HDLGenerator result module_info key lists rebuild cleanly after caller mutation' => sub {
    my $first = build_hdl_generator_result_contract();
    push @{$first->{module_info_identity_presence_keys}}, $sentinel;
    $first->{module_info_summary_presence_keys}[0] = $sentinel;
    push @{$first->{module_info_optional_composition_summary_keys}}, $sentinel;

    my $second = build_hdl_generator_result_contract();
    ok(!contains_sentinel($second->{module_info_identity_presence_keys}), 'fresh module_info identity key list is not polluted');
    ok(!contains_sentinel($second->{module_info_summary_presence_keys}), 'fresh module_info summary key list is not polluted');
    ok(!contains_sentinel($second->{module_info_optional_composition_summary_keys}), 'fresh module_info optional key list is not polluted');
    is_deeply(
        $second->{module_info_identity_presence_keys},
        hdl_generator_result_module_info_identity_keys(),
        'fresh contract embeds canonical module_info identity keys',
    );
    is_deeply(
        $second->{module_info_summary_presence_keys},
        hdl_generator_result_module_info_summary_keys(),
        'fresh contract embeds canonical module_info summary keys',
    );
    is_deeply(
        $second->{module_info_optional_composition_summary_keys},
        hdl_generator_result_module_info_optional_composition_summary_keys(),
        'fresh contract embeds canonical module_info optional composition keys',
    );
};

done_testing();

sub contains_sentinel {
    my ($value) = @_;
    return 1 if defined($value) && !ref($value) && $value eq $sentinel;
    return 0 unless ref($value);

    if (ref($value) eq 'ARRAY') {
        return 1 if grep { contains_sentinel($_) } @{$value};
        return 0;
    }

    if (ref($value) eq 'HASH') {
        return 1 if exists($value->{$sentinel});
        return 1 if grep { contains_sentinel($_) } values %{$value};
        return 0;
    }

    return 0;
}
