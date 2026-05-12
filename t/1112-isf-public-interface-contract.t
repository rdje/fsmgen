#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use JSON::PP ();

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::EmbeddingContract qw(
    embedding_nested_presence_key_map
);
use FSM::Support::ISFPublicInterfaceContract qw(
    build_isf_public_interface_contract
    isf_public_interface_contract_source
    isf_public_interface_lower_result_presence_keys
    isf_public_interface_public_top_level_keys
    isf_public_interface_schedule_report_presence_key_family_map
    isf_public_interface_schedule_report_top_level_keys
);

sub assert_keys_present {
    my ($payload, $keys, $label) = @_;
    for my $key (@{$keys || []}) {
        ok(exists $payload->{$key}, "$label keeps key $key");
    }
}

subtest 'contract advertises the bounded ISF public interface' => sub {
    my $contract = build_isf_public_interface_contract();

    is($contract->{schema_version}, 1, 'contract exposes schema version');
    is($contract->{status}, 'bounded_public', 'contract marks the ISF seam as bounded public');
    is(
        $contract->{contract_source},
        isf_public_interface_contract_source(),
        'contract records its own owner',
    );
    assert_keys_present(
        $contract,
        isf_public_interface_public_top_level_keys(),
        'direct ISF public-interface contract',
    );
    is_deeply(
        $contract->{lower_result_presence_keys},
        isf_public_interface_lower_result_presence_keys(),
        'contract publishes the lower-result key family',
    );
    is_deeply(
        $contract->{schedule_report_top_level_keys},
        isf_public_interface_schedule_report_top_level_keys(),
        'contract publishes schedule-report top-level keys',
    );
    is_deeply(
        $contract->{schedule_report_presence_key_family_map},
        isf_public_interface_schedule_report_presence_key_family_map(),
        'contract publishes grouped schedule-report key families',
    );
    ok($contract->{live_contract_documentation}, 'contract flags the docs as live');
    ok($contract->{evolves_with_isf_implementation}, 'contract flags implementation-coupled evolution');
    ok(!$contract->{raw_actor_full_hash_stable}, 'contract does not freeze the raw actor hash as a full API');
    ok(!$contract->{lowering_ir_full_hash_stable}, 'contract does not freeze LoweringIR as a full API');
    ok(!$contract->{schedule_report_full_schema_stable}, 'contract does not freeze the whole schedule report schema');
};

subtest 'capability manifest advertises ISF public interface contract' => sub {
    my $manifest = build_capability_manifest();
    my $contract = build_isf_public_interface_contract();

    is_deeply(
        $manifest->{embedding}{isf_public_interface},
        $contract,
        'manifest embeds the ISF public-interface contract',
    );
    is(
        $manifest->{embedding}{section_contract}{nested_contract_source_map}{isf_public_interface},
        isf_public_interface_contract_source(),
        'embedding section maps the ISF interface to its contract owner',
    );
    is_deeply(
        $manifest->{embedding}{section_contract}{nested_presence_key_map}{isf_public_interface},
        embedding_nested_presence_key_map()->{isf_public_interface},
        'embedding section advertises the ISF interface key family',
    );
};

subtest 'current parser scheduler outputs conform to advertised key families' => sub {
    my $isf_file = File::Spec->catfile($FindBin::Bin, '..', 'isf', 'apb_requester.isf');
    my $actor    = FSM::Adapter::ISF->new()->parse_file($isf_file);
    my $scheduler = FSM::Scheduler::ISF->new();

    my $lowered = $scheduler->lower($actor);
    assert_keys_present(
        $lowered,
        isf_public_interface_lower_result_presence_keys(),
        'ISF lower result',
    );
    ok(exists $lowered->{files}{'apb_requester.fsm'}, 'lower result exposes scheduled .fsm text by basename');
    like($lowered->{files}{'apb_requester.fsm'}, qr/\(\?fsm:apb_requester\b/, 'scheduled .fsm text contains actor module');

    my $report = JSON::PP->new->decode($scheduler->report($actor));
    assert_keys_present(
        $report,
        isf_public_interface_schedule_report_top_level_keys(),
        'ISF schedule report',
    );
    assert_keys_present(
        $report->{reset},
        isf_public_interface_schedule_report_presence_key_family_map()->{schedule_report_reset_keys},
        'ISF schedule report reset summary',
    );
    assert_keys_present(
        $report->{transactions}[0],
        isf_public_interface_schedule_report_presence_key_family_map()->{schedule_report_transaction_keys},
        'ISF schedule report transaction summary',
    );
    assert_keys_present(
        $report->{dt_blocks}[0],
        isf_public_interface_schedule_report_presence_key_family_map()->{schedule_report_dt_keys},
        'ISF schedule report DT summary',
    );
};

done_testing();
