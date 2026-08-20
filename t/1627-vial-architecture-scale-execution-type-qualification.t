#!/usr/bin/env perl

use strict;
use warnings;

use bytes ();
use Digest::SHA qw(sha256_hex);
use File::Spec;
use FindBin;
use JSON::PP ();
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::ArchitectureScaleExecutionGraph;
use FSM::VIAL::ArchitectureScaleWorkload;

my $class = 'FSM::VIAL::ArchitectureScaleExecutionGraph';
my $json = JSON::PP->new->canonical(1)->utf8(1);
my $reference_hial = slurp_raw(repo_path('ppif/ahb_lite_subordinate.ppif'));
my $vial_source =
    'generated/vial-scale/execution_graph/vial_architecture_scale.vial';
my $declaration_cap = 4_096;
my $manifest_cap = 16_777_216;

my %expected = (
    types => 8_192,
    hial_bytes => 293_894,
    vial_bytes => 1_023_293,
    hial_sha256 =>
        '335b9eb1830dfcf90b644dcf0f20490a4c5887e4c2fb934c3a5bc0f355a18cf6',
    vial_sha256 =>
        'c0c8a2cf387502d12dde066ef862fd4f4bca81fbc4f32b7cce7685eb244911b8',
    workload_identity =>
        'workload/746705c67e6fb47b5067d7db81dfae3d4ce7b7373641ecfe1d2ebda32a9f63ec',
);
my $semantic_diagnostic = {
    schema_version => 1,
    severity => 'error',
    code => 'VIAL_LIMIT_ERROR',
    phase => 'limit',
    message => "package section 'types' exceeds 4096 declarations",
    semantic_path => '/packages/0/types',
    source_location => {
        source_name => $vial_source,
        start_line => 1,
        start_column => 67,
        start_byte => 66,
        end_line => 1,
        end_column => 302_070,
        end_byte_exclusive => 302_070,
    },
    notes => [],
};
my $repair_owner = 'HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4';

sub construction {
    return $class->construct({
        primary_axis => 'execution_types',
        level => 'qualification_candidate_v1',
    });
}

subtest 'the 8,192-type qualification level is authored deterministically' => sub {
    my $first = construction();
    my $second = construction();
    ok($first->{ok}, 'qualification construction satisfies the workload contract');
    diag($json->encode($first->{diagnostics})) unless $first->{ok};
    is($json->encode($second), $json->encode($first),
        'independent qualification construction is byte-identical');
    is($first->{specification}{requested_counts}{execution_types},
        $expected{types}, 'construction retains exactly 8,192 execution types');
    is($first->{workload_identity}, $expected{workload_identity},
        'execution-type qualification workload identity is exact');

    my %input = map { $_->{role} => $_ } @{$first->{inputs}};
    is_deeply([sort keys %input], [qw(hial_source vial_source)],
        'construction contains only generated HIAL and VIAL source');
    is(bytes::length($input{hial_source}{content}), $expected{hial_bytes},
        'generated direct-IAL1 byte count is exact');
    is(sha256_hex($input{hial_source}{content}), $expected{hial_sha256},
        'generated direct-IAL1 identity is frozen');
    is(bytes::length($input{vial_source}{content}), $expected{vial_bytes},
        'generated VIAL byte count is exact');
    is(sha256_hex($input{vial_source}{content}), $expected{vial_sha256},
        'generated VIAL identity is frozen');
    cmp_ok(bytes::length($input{vial_source}{content}), '<', 1_048_576,
        'the generated source is inside the parser source cap, so the cap that'
            . ' rejects is a declaration cap and not a byte cap');
    is(scalar(() = $input{vial_source}{content} =~ /\(type width_[0-9]{8}_t /g),
        $expected{types}, 'source authors exactly 8,192 genuine type declarations');
    is(scalar(() = $input{vial_source}{content} =~ /\(endpoint typed_[0-9]{8} /g),
        $expected{types}, 'every authored type is bound by one public endpoint');

    my $rejected = eval {
        $class->construct({
            primary_axis => 'execution_types',
            level => 'qualification_candidate_v1',
            reference_hial_text => $reference_hial,
        });
        1;
    };
    ok(!$rejected, 'the direct-IAL1 route refuses a caller-supplied checked-AHB source');
    like($@, qr/accepted only for checked-AHB execution gates/,
        'the refusal names the checked-AHB boundary');
};

subtest 'the declared stage order makes the semantic cap the authority' => sub {
    my $built = $class->build({construction => construction()});
    my $again = $class->build({construction => construction()});
    ok(!$built->{ok}, 'the qualification level is rejected');
    is($json->encode($again), $json->encode($built),
        'independent rejection is byte-identical');
    is($built->{execution_ir}, undef, 'rejection exposes no partial execution IR');
    is($built->{plan}, undef, 'rejection exposes no partial plan');
    is_deeply($built->{diagnostics}, [$semantic_diagnostic],
        'the ordinary VIAL parser owns the rejection, ahead of any bridge cap');
    is($built->{diagnostics}[0]{semantic_path}, '/packages/0/types',
        'the diagnostic names the authored package section it rejected');
};

subtest 'evaluation records an unreachable qualification level' => sub {
    my $evaluation = $class->evaluate({construction => construction()});
    ok($evaluation->{ok}, 'qualification evaluation satisfies every closed oracle');
    diag($json->encode($evaluation->{diagnostics})) unless $evaluation->{ok};
    is($evaluation->{status}, 'expected_rejection',
        'evaluation classifies the dominated qualification level as expected');
    is($evaluation->{observed_outcome}, 'rejected',
        'evaluation records the rejected outcome');
    is_deeply($evaluation->{diagnostics}, [$semantic_diagnostic],
        'evaluation preserves the exact parser diagnostic');
    is_deeply($evaluation->{metrics}, {},
        'rejection reports no measurements from a partial plan');
    is($evaluation->{semantic_ir_sha256}, undef,
        'a semantic-stage rejection claims no SemanticIR identity');
    is($evaluation->{bridge_manifest_sha256}, undef,
        'no bridge is built behind a semantic rejection');

    is(scalar(@{$evaluation->{contract_discrepancies}}), 1,
        'the pre-empted qualification records exactly one interaction');
    my $discrepancy = $evaluation->{contract_discrepancies}[0];
    is($discrepancy->{code}, 'VIAL_SCALE_LIMIT_INTERACTION',
        'the interaction code is exact');
    is($discrepancy->{path}, '/requested_counts/execution_types',
        'the interaction names its own axis');
    is($discrepancy->{repair_owner}, $repair_owner,
        'limit-policy repair stays routed to .17.4');
    like($discrepancy->{message}, qr/\b$declaration_cap\b/,
        'the interaction names the declaration cap that decides');
    like($discrepancy->{message}, qr/\b$manifest_cap\b/,
        'the interaction names the manifest cap that bounds the route');
    like($discrepancy->{message}, qr/\b1043\b/,
        'the interaction names the measured route boundary');
};

subtest 'the execution-type ladder still fails closed on mutation and unowned shapes' => sub {
    my $forged = clone_json(construction());
    my ($vial) = grep { $_->{role} eq 'vial_source' } @{$forged->{inputs}};
    $vial->{content} .= ' ';
    my $accepted = eval { $class->evaluate({construction => $forged}); 1 };
    ok(!$accepted, 'post-identity source padding fails closed');
    like($@, qr/construction is not canonical/,
        'mutation rejection names canonical regeneration');

    # The owned frontier is published by the generator, so this proves the
    # boundary by deriving it from the catalog instead of restating a list that
    # goes stale the moment the next level lands.
    my %owned;
    $owned{"$_->{primary_axis}/$_->{level}"} = 1
        for @{$class->owned_shapes};
    my $axes = FSM::VIAL::ArchitectureScaleWorkload->catalog
        ->{families}{execution_graph_v1}{axes};
    my @unowned;
    for my $axis (sort keys %{$axes}) {
        for my $level (sort keys %{$axes->{$axis}{levels}}) {
            push @unowned, [$axis, $level] unless $owned{"$axis/$level"};
        }
    }
    cmp_ok(scalar(@unowned), '>', 0,
        'the caller-sealed generator still has an unowned frontier');

    my (@accepted, %reason);
    for my $shape (@unowned) {
        my ($axis, $level) = @{$shape};
        if (eval { $class->construct({primary_axis => $axis, level => $level}); 1 }) {
            push @accepted, "$axis/$level";
            next;
        }
        $reason{"$axis/$level"} = $@;
    }
    is_deeply(\@accepted, [],
        'every catalog shape outside the published owned frontier fails closed');
    is_deeply(
        [grep { $reason{$_} !~ /does not own the requested shape/ } sort keys %reason],
        [],
        'each unowned rejection names the caller-sealed generator boundary');
};

subtest 'exact route-boundary proof is explicit and RAM-guarded' => sub {
    plan skip_all => 'set FSMGEN_VIAL_SCALE_EXACT=1 under'
        . ' scripts/run_with_ram_guard.sh for exact execution-type boundary proof'
        unless $ENV{FSMGEN_VIAL_SCALE_EXACT};

    my $accepted = $class->_test_direct_ial1_bridge(1_043);
    ok($accepted->{ok}, 'the direct-IAL1 route accepts exactly 1,043 types');
    diag($json->encode($accepted->{diagnostics})) unless $accepted->{ok};
    my $manifest = $accepted->{manifest}->as_hashref;
    is(scalar(@{$manifest->{types}}), 1_043,
        'the accepted manifest carries every authored type');
    is(scalar(@{$manifest->{endpoints}}), 1_045,
        'the accepted manifest binds one endpoint per type plus clock and reset');
    cmp_ok(bytes::length($json->encode($manifest)), '<=', $manifest_cap,
        'the accepted manifest is inside the serialized bridge cap');

    # A bridge that accepts is not yet a route that accepts, so the boundary is
    # carried through the public binder to a real plan.
    my $planned = $class->_test_direct_ial1_route(1_043);
    ok($planned->{ok}, 'the whole canonical route, not only its bridge, accepts 1,043 types');
    diag($planned->{why}) unless $planned->{ok};
    is($planned->{types}, 1_043, 'the accepted plan materializes every authored type');
    is($planned->{bindings}, 1_045,
        'the accepted plan binds one endpoint per type plus clock and reset');
    is($planned->{plan_bytes}, 1_493_527, 'the accepted plan is exactly 1,493,527 bytes');

    my $rejected = $class->_test_direct_ial1_bridge(1_044);
    ok(!$rejected->{ok}, 'one further type crosses the serialized bridge cap');
    is($rejected->{diagnostics}[0]{code}, 'HIAL_VIAL_BRIDGE_LIMIT_ERROR',
        'the boundary rejection uses the stable bridge limit code');
    is($rejected->{diagnostics}[0]{message},
        'serialized manifest exceeds 16777216 bytes',
        'the serialized-manifest cap is the route boundary, not the type cap');
    is($rejected->{diagnostics}[0]{path}, '/',
        'the boundary diagnostic names the whole manifest');
};

done_testing();

sub repo_path {
    my ($relative) = @_;
    return File::Spec->catfile($FindBin::Bin, '..', split m{/}, $relative);
}

sub slurp_raw {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "Cannot read $path: $!";
    local $/;
    my $text = <$fh>;
    close $fh or die "Cannot close $path: $!";
    return $text;
}

sub clone_json {
    my ($value) = @_;
    return $json->decode($json->encode($value));
}

package FSM::VIAL::ArchitectureScaleExecutionGraph;

# The route boundary lies between two catalog levels, so it is proved through
# the same renderer and canonical bridge the owned levels use rather than
# through a level the generator does not own.
sub _test_direct_ial1_bridge {
    my ($class, $type_count) = @_;
    my $hial = _render_type_hial($type_count);
    my $actor = FSM::Adapter::ISF->new()->parse_source(
        $hial, 'vial_architecture_scale.isf');
    my $scheduler = FSM::Scheduler::ISF->new();
    my $schedule_report = JSON::PP->new->decode($scheduler->report($actor));
    my $lowered = $scheduler->lower($actor);
    my $artifact_name = $actor->{actor_name} . '.fsm';
    $artifact_name = $actor->{actor_name} . '_top.fsm'
        unless exists $lowered->{files}{$artifact_name};
    return FSM::HIAL::VIALBridge::Builder->build_ial1({
        profile => 'core_single_unit_v1',
        authored_source => _source_record(
            $hial,
            'generated/vial-scale/execution_graph/vial_architecture_scale.isf'),
        actor => $actor,
        schedule_report => $schedule_report,
        generated_ial0 => _source_record(
            $lowered->{files}{$artifact_name}, undef, $artifact_name),
        backend_names => _backend_names($actor),
    });
}

# A bridge-stage measurement cannot support a whole-route claim, so the boundary
# is also carried through the public binder to a real plan.
sub _test_direct_ial1_route {
    my ($class, $type_count) = @_;
    my $bridge = $class->_test_direct_ial1_bridge($type_count);
    return {ok => 0, why => $bridge->{diagnostics}[0]{message}} unless $bridge->{ok};
    my ($semantic_ir, $diagnostics) = _canonical_semantic_ir({
        content => _render_type_vial($type_count),
        relative_path => 'generated/vial-scale/execution_graph/vial_architecture_scale.vial',
    });
    return {ok => 0, why => $diagnostics->[0]{message}} unless $semantic_ir;
    my $fixture = $semantic_ir->as_hashref->{packages}[0]{fixtures}[0];
    my $built = FSM::VIAL::ExecutionBuilder->build({
        semantic_ir => $semantic_ir,
        bridge_manifest => $bridge->{manifest},
        fixture_id => $fixture->{semantic_id},
        scenario_ids => [map { $_->{semantic_id} } @{$fixture->{scenarios}}],
        execution_profile => 'core_directed_single_clock_execution_v1',
        replay_manifest => undef,
        native_extension_catalog => [],
    });
    return {ok => 0, why => $built->{diagnostics}[0]{message}} unless $built->{ok};
    my $ir = $built->{execution_ir}->as_hashref;
    my $canonical = JSON::PP->new->canonical(1)->utf8(1);
    return {
        ok => 1,
        types => scalar(@{$ir->{type_table}}),
        bindings => $ir->{resource_summary}{bindings},
        plan_bytes => bytes::length($canonical->encode($built->{plan})),
    };
}
