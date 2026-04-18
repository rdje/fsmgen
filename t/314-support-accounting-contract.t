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
use FSM::Support::SupportAccountingContract qw(
    build_support_accounting_contract
    support_accounting_bucket_keys
    support_accounting_catalog_entry_optional_keys
    support_accounting_catalog_entry_required_keys
    support_accounting_id_list_keys
    support_accounting_public_top_level_keys
);

my $manifest = build_capability_manifest();

subtest 'contract exposes the bounded support-accounting surface' => sub {
    my $contract = build_support_accounting_contract();

    is($contract->{schema_version}, 1, 'contract exposes schema version');
    is($contract->{status}, 'bounded_public', 'contract marks support accounting as bounded public');
    is(
        $contract->{contract_source},
        'FSM::Support::SupportAccountingContract',
        'contract records its own owner',
    );
    is(
        $contract->{report_source},
        'FSM::Support::RegressionCorpus',
        'contract records the support-accounting owner',
    );
    ok($contract->{sanitized_catalog_entries}, 'contract says catalog entries are sanitized');
    ok($contract->{derived_from_regression_corpus}, 'contract says the section is derived from the regression corpus');

    is_deeply(
        $contract->{public_top_level_presence_keys},
        support_accounting_public_top_level_keys(),
        'contract publishes the bounded support-accounting top-level keys',
    );
    is_deeply(
        $contract->{bucket_presence_keys},
        support_accounting_bucket_keys(),
        'contract publishes the bounded bucket-map keys',
    );
    is_deeply(
        $contract->{id_list_presence_keys},
        support_accounting_id_list_keys(),
        'contract publishes the bounded id-list keys',
    );
    is_deeply(
        $contract->{catalog_entry_required_keys},
        support_accounting_catalog_entry_required_keys(),
        'contract publishes the bounded required catalog-entry keys',
    );
    is_deeply(
        $contract->{catalog_entry_optional_keys},
        support_accounting_catalog_entry_optional_keys(),
        'contract publishes the bounded optional catalog-entry keys',
    );
};

subtest 'in-process capability manifest support-accounting payload conforms to the bounded contract' => sub {
    my $support = $manifest->{support_accounting};

    assert_keys_present(
        $support,
        support_accounting_public_top_level_keys(),
        'support-accounting section keeps bounded top-level keys',
    );
    assert_keys_present(
        $support,
        support_accounting_bucket_keys(),
        'support-accounting section keeps bounded bucket-map keys',
    );
    assert_keys_present(
        $support,
        support_accounting_id_list_keys(),
        'support-accounting section keeps bounded id-list keys',
    );

    ok(@{$support->{catalog_entries} || []}, 'support-accounting section exposes catalog entries');
    for my $entry (@{$support->{catalog_entries} || []}) {
        assert_keys_present(
            $entry,
            support_accounting_catalog_entry_required_keys(),
            "catalog entry $entry->{id} keeps bounded required keys",
        );
    }

    my ($composition_entry) = grep { $_->{id} eq 'protocol.apb_tb' } @{$support->{catalog_entries} || []};
    ok($composition_entry, 'support-accounting section exposes the composition protocol fixture');
    assert_keys_present(
        $composition_entry,
        [qw(expected_top_name expected_lane expected_instance_count expected_child_modules)],
        'composition catalog entry keeps its bounded optional keys',
    );
};

subtest 'CLI capability manifest keeps the bounded support-accounting contract' => sub {
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--capability-manifest'],
    );

    ok($success, 'capability manifest CLI succeeds');
    is(join('', @{$stderr_buf || []}), '', 'capability manifest CLI keeps stderr clean');

    my $decoded = eval { decode_json(join('', @{$stdout_buf || []})) };
    ok($decoded, 'capability manifest CLI emits decodable JSON');

    my $support = $decoded->{support_accounting};
    assert_keys_present(
        $support,
        support_accounting_public_top_level_keys(),
        'CLI support-accounting section keeps bounded top-level keys',
    );
    ok(@{$support->{catalog_entries} || []}, 'CLI support-accounting section exposes catalog entries');
    assert_keys_present(
        $support->{catalog_entries}[0],
        support_accounting_catalog_entry_required_keys(),
        'CLI support-accounting catalog entries keep bounded required keys',
    );
};

done_testing();

sub assert_keys_present {
    my ($payload, $keys, $label) = @_;
    for my $key (@{$keys || []}) {
        ok(exists $payload->{$key}, "$label: keeps key $key");
    }
}
