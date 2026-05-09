#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::SerializablePlanReportContract qw(
    build_serializable_plan_report_contract
    serializable_plan_report_raw_shell_replacement_keys
    serializable_plan_report_raw_shell_replacement_map
);

subtest 'raw shell replacement keys are explicit and embedded' => sub {
    is_deeply(
        serializable_plan_report_raw_shell_replacement_keys(),
        [
            qw(
                composition_report
                composition_plan
                hdl_generator_result
                composition_spec
                fsm_module
                raw_ast
                resolved_package_imports
            ),
        ],
        'replacement key helper exposes the stable raw-shell family',
    );
    is_deeply(
        build_serializable_plan_report_contract()->{raw_shell_replacement_keys},
        serializable_plan_report_raw_shell_replacement_keys(),
        'parent contract embeds the replacement key list',
    );
};

subtest 'raw shell replacement map matches the advertised key list' => sub {
    is_deeply(
        as_set([keys %{serializable_plan_report_raw_shell_replacement_map()}]),
        as_set(serializable_plan_report_raw_shell_replacement_keys()),
        'replacement map keys match advertised raw-shell family',
    );
    is_deeply(
        as_set([keys %{build_serializable_plan_report_contract()->{raw_shell_replacement_map}}]),
        as_set(build_serializable_plan_report_contract()->{raw_shell_replacement_keys}),
        'embedded replacement map keys match embedded raw-shell family',
    );
};

done_testing();

sub as_set {
    my ($values) = @_;
    return {map { $_ => 1 } @{$values || []}};
}
