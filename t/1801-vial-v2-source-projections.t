#!/usr/bin/env perl

use strict;
use warnings;

use Digest::SHA qw(sha256_hex);
use File::Spec;
use FindBin;
use JSON::PP ();
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::Parser;
use FSM::VIAL::PlanBuilder;
use FSM::VIAL::SemanticReport;
use FSM::VIAL::SourceProjection;
use FSM::VIAL::Tool qw(execute_vial_tool_request vial_tool_capabilities);

my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $source_name = 'vial/ahb_subordinate_base_output_arbitration.vial';
my $v1_source = slurp_raw(File::Spec->catfile($repo_root, split m{/}, $source_name));
my $v2_source = to_v2_normal($v1_source);
my $json = JSON::PP->new->canonical->utf8;

sub slurp_raw {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "Cannot read $path: $!";
    local $/;
    my $text = <$fh>;
    close $fh or die "Cannot close $path: $!";
    return $text;
}

sub to_v2_normal {
    my ($source) = @_;
    my $converted = $source;
    $converted =~ s/\(version 1\)/\(version 2\)/
        or die 'version-1 selector was not found';
    $converted =~ s/\n    \(fixtures/\n    (intents)\n    (fixtures/
        or die 'fixtures section was not found';
    return $converted;
}

sub changed {
    my ($source, $before, $after, $label) = @_;
    my $changed = $source;
    my $count = ($changed =~ s/\Q$before\E/$after/);
    die "$label mutation did not match exactly once" unless $count == 1;
    return $changed;
}

sub contains_parser_node {
    my ($value) = @_;
    return 0 unless ref($value);
    if (ref($value) eq 'HASH') {
        return 1 if exists($value->{node_kind})
            || exists($value->{atom_kind}) || exists($value->{raw});
        return scalar grep { contains_parser_node($value->{$_}) } keys %{$value};
    }
    return scalar grep { contains_parser_node($_) } @{$value}
        if ref($value) eq 'ARRAY';
    return 1;
}

sub check_v2_failure {
    my ($label, $source, $code, $message, $path, $catalog, $location_source) = @_;
    my $first = FSM::VIAL::Parser->check_source({
        text => $source,
        source_name => $source_name,
        source_catalog => $catalog || {},
    });
    my $second = FSM::VIAL::Parser->check_source({
        source_catalog => $catalog || {},
        source_name => $source_name,
        text => $source,
    });
    ok(!$first->{ok}, "$label fails closed");
    is_deeply($second, $first, "$label diagnostic is deterministic");
    is(scalar(@{$first->{diagnostics}}), 1, "$label returns one primary diagnostic");
    my $diagnostic = $first->{diagnostics}[0];
    is($diagnostic->{schema}, 'fsmgen.vial_diagnostic.v2', "$label uses the v2 diagnostic identity");
    is($diagnostic->{schema_version}, 2, "$label uses diagnostic schema version two");
    is($diagnostic->{code}, $code, "$label uses $code");
    like($diagnostic->{message}, $message, "$label explains the rejected boundary");
    like($diagnostic->{semantic_path}, $path, "$label retains a stable semantic path");
    is_deeply(
        [sort keys %{$diagnostic}],
        [sort qw(schema schema_version severity code phase message semantic_path source_location notes)],
        "$label diagnostic is closed",
    );
    is($diagnostic->{source_location}{source_name}, $location_source || $source_name,
        "$label location stays repository-relative");
    return $diagnostic;
}

sub v1_tool_request {
    my ($source) = @_;
    return {
        schema => 'fsmgen.vial_tool_request.v1',
        schema_version => 1,
        action => 'check',
        vial_source => {
            source_id => $source_name,
            source_kind_hint => 'vial',
            text => $source,
            encoding => 'utf-8',
            origin => 'memory',
            display_name => $source_name,
            canonical_id => undef,
            relative_path => $source_name,
            metadata => {},
        },
        hial_source => undef,
        options => {
            source_style => 'auto',
            output_style => undef,
            fixture_id => undef,
            scenario_ids => [],
            execution_profile => undef,
            backend_profile => undef,
            replay_manifest => undef,
            native_extension_catalogs => [],
            artifact_policy => undef,
            quiet => JSON::PP::false,
        },
    };
}

subtest 'version-1 semantic and formatting identities remain byte-exact' => sub {
    my $ir = FSM::VIAL::Parser->parse_source({
        text => $v1_source,
        source_name => $source_name,
    });
    my $report = FSM::VIAL::SemanticReport->build($ir);
    my $normal = FSM::VIAL::SourceProjection->format_source({
        text => $v1_source,
        source_name => $source_name,
        output_style => 'normal',
    })->{text};
    my $terse = FSM::VIAL::SourceProjection->format_source({
        text => $v1_source,
        source_name => $source_name,
        output_style => 'terse',
    })->{text};

    is(sha256_hex($json->encode($ir->as_hashref)),
        'a83dbb89ecf5113168db2bd92a80697c0a3bf181771cbc7a0f564a6afd0f8750',
        'v1 private SemanticIR bytes retain the pre-v2 identity');
    is(sha256_hex($json->encode($report)),
        'af17c2dc659d3039501f91d0945d829d92b651569418ee624593c7aa2ec74264',
        'v1 semantic report bytes retain the pre-v2 identity');
    is(FSM::VIAL::SourceProjection->semantic_projection_sha256($ir),
        '8e517e29bbc39108369d9d5ddbf03633e7b48290d215d0a1d04a23c0eb79447c',
        'v1 semantic projection retains the pre-v2 identity');
    is(sha256_hex($normal),
        '6a9d93ba16d72f19dde3c1153a57b7255dedcbe1be83e98e87b86b54dd2139de',
        'v1 normal formatting retains the pre-v2 bytes');
    is(sha256_hex($terse),
        'b8087ea490ffb3a812cc5563e0f4188c85887ed016a7730f2ba4568991ded898',
        'v1 terse formatting retains the pre-v2 bytes');
    is_deeply(
        [sort keys %{$report}],
        [sort qw(schema_version language language_version profile root_source sources packages required_capabilities unresolved_bridge_refs diagnostics)],
        'v1 report gains no v2 schema field or shape change');
};

subtest 'normal-v2 and terse-v2 are one typed source meaning' => sub {
    my $normal = FSM::VIAL::SourceProjection->format_source({
        text => $v2_source,
        source_name => $source_name,
        output_style => 'normal',
    });
    my $terse = FSM::VIAL::SourceProjection->format_source({
        text => $v2_source,
        source_name => $source_name,
        output_style => 'terse',
    });
    is($normal->{input_style}, 'normal', 'the explicit v2 root is detected as normal');
    like($normal->{text}, qr/\A\(vial\n  \(version 2\)/, 'normal-v2 keeps the explicit version form');
    like($normal->{text}, qr/^    \(intents\)$/m, 'normal-v2 keeps the mandatory empty intents section');
    like($terse->{text}, qr/\A\(vial 2\n  \(package/, 'terse-v2 keeps the integer version discriminator');
    unlike($terse->{text}, qr/^    \(intents\b/m, 'terse-v2 omits the empty intents wrapper');
    unlike($terse->{text}, qr/^    \((?:imports|types|transactions|models|scoreboards|fixtures)\b/m,
        'terse-v2 omits every unchanged empty or declaration-family wrapper');

    my $normal_ir = FSM::VIAL::Parser->parse_source({
        text => $normal->{text}, source_name => $source_name,
    });
    my $terse_ir = FSM::VIAL::Parser->parse_source({
        text => $terse->{text}, source_name => $source_name,
    });
    is($normal_ir->schema_version, 2, 'normal-v2 constructs semantic schema version two');
    is($normal_ir->language_version, 2, 'normal-v2 retains language version two');
    is($normal_ir->profile, 'core_directed_single_clock_v2', 'normal-v2 selects only the base v2 profile');
    is_deeply(
        $normal_ir->as_hashref->{required_capabilities},
        [qw(vial.profile.core_directed_single_clock_v2 vial.semantic_ir.v2 vial.source.v2)],
        'the v2 base SemanticIR requires only its three sorted semantic capabilities');
    is_deeply($normal_ir->as_hashref->{packages}[0]{intent_families}, [],
        'the base v2 package has a typed empty intent-family collection');
    ok(!contains_parser_node($normal_ir->as_hashref),
        'v2 SemanticIR contains no lexer token or parser-form node');

    my $normal_digest = FSM::VIAL::SourceProjection->semantic_projection_sha256($normal_ir);
    is(FSM::VIAL::SourceProjection->semantic_projection_sha256($terse_ir), $normal_digest,
        'normal-v2 and terse-v2 reparses have one source-span-free meaning');
    is(FSM::VIAL::SourceProjection->format_source({
        text => $terse->{text}, source_name => $source_name, output_style => 'normal',
    })->{text}, $normal->{text}, 'terse-v2 formats back to the same canonical normal-v2 bytes');
    is(FSM::VIAL::SourceProjection->format_source({
        text => $terse->{text}, source_name => $source_name, output_style => 'terse',
    })->{text}, $terse->{text}, 'terse-v2 formatting is byte-idempotent');

    my $v1_ir = FSM::VIAL::Parser->parse_source({ text => $v1_source, source_name => $source_name });
    is(FSM::VIAL::SourceProjection->compatibility_projection_sha256($normal_ir),
        FSM::VIAL::SourceProjection->compatibility_projection_sha256($v1_ir),
        'empty-intents v2 and v1 have one exact base compatibility projection');

    my $intent_location = $normal_ir->source_location_for('/packages/0/intent_families');
    is($intent_location->{source_name}, $source_name, 'inserted v2 collection retains authored source identity');
    ok($intent_location->{start_byte} < $intent_location->{end_byte_exclusive},
        'inserted v2 collection retains a non-empty authored byte span');
    my $v1_fixture = $v1_ir->as_hashref->{packages}[0]{fixtures}[0];
    my $v2_fixture = $normal_ir->as_hashref->{packages}[0]{fixtures}[0];
    is($v2_fixture->{semantic_id}, $v1_fixture->{semantic_id},
        'unchanged base declarations retain stable rule-derived semantic identity');
    is($normal_ir->source_location_for($v2_fixture->{semantic_path})->{source_name}, $source_name,
        'unchanged v2 base facts retain authored provenance');

    my $report = FSM::VIAL::SemanticReport->build($normal_ir);
    is($report->{schema}, 'fsmgen.vial_semantic_report.v2', 'v2 report uses its exact schema identity');
    is($report->{schema_version}, 2, 'v2 report uses schema version two');
    is_deeply($report->{packages}[0]{intent_families}, [], 'v2 report sanitizes the empty family collection');

    my $defensive = $normal_ir->as_hashref;
    $defensive->{packages}[0]{intent_families}[0] = { family_id => 'mutated' };
    is_deeply($normal_ir->as_hashref->{packages}[0]{intent_families}, [],
        'v2 SemanticIR access is defensively cloned');
};

subtest 'v2 catalog imports retain authored traversal and reject mixed versions' => sub {
    my $imported = changed(
        $v2_source,
        'package ahb_subordinate_base_output_arbitration',
        'package imported_fixture',
        'v2 imported package name',
    );
    my $root = changed(
        $v2_source,
        '(imports)',
        '(imports (import common "vial/common.vial"))',
        'v2 import',
    );
    $root = changed(
        $root,
        '(address (type address_t))',
        '(address (type common.address_t))',
        'v2 imported type reference',
    );
    my $checked = FSM::VIAL::Parser->check_source({
        text => $root,
        source_name => $source_name,
        source_catalog => { 'vial/common.vial' => $imported },
    });
    ok($checked->{ok}, 'same-version v2 catalog import succeeds');
    is_deeply(
        [map { $_->{source_name} } @{$checked->{semantic_report}{sources}}],
        [$source_name, 'vial/common.vial'],
        'v2 catalog retains root-then-depth-first-authored source order');
    is($checked->{semantic_report}{packages}[0]{imports}[0]{package_id},
        'imported_fixture::package::imported_fixture',
        'v2 import resolves to the stable target package identity');
    my $normal_catalog_ir = FSM::VIAL::Parser->parse_source({
        text => $root,
        source_name => $source_name,
        source_catalog => { 'vial/common.vial' => $imported },
    });
    my $terse_imported = FSM::VIAL::SourceProjection->format_source({
        text => $imported,
        source_name => 'vial/common.vial',
        output_style => 'terse',
    })->{text};
    my $terse_catalog_ir = FSM::VIAL::Parser->parse_source({
        text => $root,
        source_name => $source_name,
        source_catalog => { 'vial/common.vial' => $terse_imported },
    });
    is(
        FSM::VIAL::SourceProjection->semantic_projection_sha256($terse_catalog_ir),
        FSM::VIAL::SourceProjection->semantic_projection_sha256($normal_catalog_ir),
        'one v2 catalog may mix normal and terse source styles without changing meaning',
    );

    my $mismatch = check_v2_failure(
        'v2-to-v1 import', $root, 'VIAL_IMPORT_VERSION_MISMATCH',
        qr/catalog root requires version 2/, qr{/imports$},
        { 'vial/common.vial' => changed($imported, '(version 2)', '(version 1)', 'mixed imported version')
            =~ s/\n    \(intents\)//r },
    );
    is($mismatch->{notes}[0]{source_location}{source_name}, 'vial/common.vial',
        'mixed-version note identifies the imported root');
};

subtest 'a version-1 root retains its pre-v2 import routing and diagnostics' => sub {
    my $root = changed(
        $v1_source,
        '(imports)',
        '(imports (import common "vial/common.vial"))',
        'v1 importing root',
    );
    my $normal = FSM::VIAL::Parser->check_source({
        text => $root,
        source_name => $source_name,
        source_catalog => { 'vial/common.vial' => $v2_source },
    });
    ok(!$normal->{ok}, 'v1 root rejects a normal-v2 import through the legacy route');
    is($normal->{diagnostics}[0]{schema_version}, 1, 'v1-root import error keeps diagnostic schema one');
    ok(!exists($normal->{diagnostics}[0]{schema}), 'v1-root import error gains no v2 schema key');
    is($normal->{diagnostics}[0]{code}, 'VIAL_LIMIT_ERROR',
        'normal-v2 import retains the legacy version-range diagnostic');
    like($normal->{diagnostics}[0]{message}, qr/bounded range 1 through 1/,
        'normal-v2 import retains the legacy version-range message');

    my $terse_v2 = FSM::VIAL::SourceProjection->format_source({
        text => $v2_source,
        source_name => 'vial/common.vial',
        output_style => 'terse',
    })->{text};
    my $terse = FSM::VIAL::Parser->check_source({
        text => $root,
        source_name => $source_name,
        source_catalog => { 'vial/common.vial' => $terse_v2 },
    });
    ok(!$terse->{ok}, 'v1 root rejects a terse-v2 import through the legacy route');
    is($terse->{diagnostics}[0]{code}, 'VIAL_SOURCE_STYLE_ERROR',
        'terse-v2 import retains the legacy style diagnostic');
    is($terse->{diagnostics}[0]{message},
        'source style is ambiguous; use normal (version 1) or terse integer 1 at the root',
        'terse-v2 import retains the legacy style message byte-for-byte');
};

subtest 'unknown versions, adapters, families, escapes, and family bounds fail closed' => sub {
    check_v2_failure(
        'unknown normal-root version',
        changed($v1_source, '(version 1)', '(version 3)', 'unknown normal version'),
        'VIAL_VERSION_UNSUPPORTED', qr/version '3'/, qr{/language_version$},
    );
    my $terse = FSM::VIAL::SourceProjection->format_source({
        text => $v2_source, source_name => $source_name, output_style => 'terse',
    })->{text};
    check_v2_failure(
        'unknown terse-root version',
        changed($terse, '(vial 2', '(vial 3', 'unknown terse version'),
        'VIAL_VERSION_UNSUPPORTED', qr/version '3'/, qr{/language_version$},
    );
    check_v2_failure(
        'noncanonical terse-root version',
        changed($terse, '(vial 2', '(vial 0x2', 'noncanonical terse version'),
        'VIAL_VERSION_UNSUPPORTED', qr/must use decimal integer 2/,
        qr{/language_version$},
    );

    my $adapter = changed(
        $v2_source,
        '(imports)',
        '(imports (import common "vial/common.vial" (adapter v1_to_v2)))',
        'reserved adapter',
    );
    check_v2_failure(
        'unregistered explicit adapter', $adapter,
        'VIAL_COMPATIBILITY_ADAPTER_UNAVAILABLE', qr/not registered/, qr{/imports$},
        { 'vial/common.vial' => $v1_source },
    );
    my $two_adapters = changed(
        $v2_source,
        '(imports)',
        '(imports (import common "vial/common.vial" (adapter first) (adapter second)))',
        'adapter count excess',
    );
    check_v2_failure(
        'per-edge adapter-count excess', $two_adapters,
        'VIAL_LIMIT_ERROR', qr/one-compatibility-adapter limit/,
        qr{/imports/0/adapter$},
    );

    my $escape = changed(
        $v2_source, '(intents)',
        '(intents (raw_systemverilog "initial begin end"))',
        'raw backend escape',
    );
    check_v2_failure(
        'backend-shaped top-level intent escape', $escape,
        'VIAL_PARSE_ERROR', qr/family form requires/, qr{/intent_families/0$},
    );
    my $unknown_family = changed(
        $v2_source, '(intents)',
        '(intents (family native_uvm (revision 1) (default uvm_phase)))',
        'unregistered family',
    );
    check_v2_failure(
        'unregistered family with backend-shaped default', $unknown_family,
        'VIAL_FAMILY_UNSUPPORTED', qr/no registered semantic grammar/,
        qr{/intent_families/0/family_id$},
    );
    my $base_escape = changed(
        $v2_source,
        '(reset bus 3)',
        '(systemverilog "initial begin end")',
        'v2 inherited action escape',
    );
    check_v2_failure(
        'backend escape in the inherited base grammar', $base_escape,
        'VIAL_PARSE_ERROR', qr/unknown action 'systemverilog'/,
        qr{/actions/0$},
    );

    my $too_many_blocks = join(' ', map { "(family family_$_ (revision 1))" } 1 .. 257);
    check_v2_failure(
        'per-package family-block excess',
        changed($v2_source, '(intents)', "(intents $too_many_blocks)", 'family block excess'),
        'VIAL_LIMIT_ERROR', qr/256 intent-family-block limit/,
        qr{/intent_families$},
    );
    my $too_many_nodes = join(' ', ('(node)') x 4_097);
    check_v2_failure(
        'per-family node excess',
        changed(
            $v2_source, '(intents)',
            "(intents (family bounded (revision 1) $too_many_nodes))",
            'family node excess',
        ),
        'VIAL_LIMIT_ERROR', qr/4096-node limit/,
        qr{/intent_families/0/nodes$},
    );

    my $duplicate_family = changed(
        $v2_source, '(intents)',
        '(intents (family repeated (revision 1)) (family repeated (revision 1)))',
        'duplicate family',
    );
    check_v2_failure(
        'duplicate family in one package', $duplicate_family,
        'VIAL_PARSE_ERROR', qr/duplicate intent family 'repeated'/,
        qr{/intent_families/1/family_id$},
    );

    my $revision_import = changed(
        $v2_source,
        'package ahb_subordinate_base_output_arbitration',
        'package revision_import',
        'revision import package name',
    );
    $revision_import = changed(
        $revision_import, '(intents)',
        '(intents (family shared (revision 2)))',
        'revision import family',
    );
    my $revision_root = changed(
        $v2_source, '(imports)',
        '(imports (import revision_import "vial/revision_import.vial"))',
        'revision mismatch import',
    );
    $revision_root = changed(
        $revision_root, '(intents)',
        '(intents (family shared (revision 1)))',
        'revision root family',
    );
    check_v2_failure(
        'cross-package family revision mismatch', $revision_root,
        'VIAL_FAMILY_REVISION_MISMATCH', qr/uses revision 2 after revision 1/,
        qr{/intent_families/0/revision$},
        { 'vial/revision_import.vial' => $revision_import },
        'vial/revision_import.vial',
    );

    my $full_block = join(' ', ('(node)') x 4_096);
    my $catalog_nodes = join(' ', map {
        "(family catalog_nodes_$_ (revision 1) $full_block)"
    } 1 .. 17);
    check_v2_failure(
        'connected-catalog family-node excess',
        changed($v2_source, '(intents)', "(intents $catalog_nodes)", 'catalog node excess'),
        'VIAL_LIMIT_ERROR', qr/65536-node limit/,
        qr{/intent_families/16/nodes$},
    );

    my $revision_blocks = join(' ', map {
        "(family revision_$_ (revision 1))"
    } 1 .. 256);
    my $revision_limit_root = changed(
        $v2_source, '(imports)',
        '(imports (import overflow "vial/revision_overflow.vial"))',
        'revision limit import',
    );
    $revision_limit_root = changed(
        $revision_limit_root, '(intents)', "(intents $revision_blocks)",
        'revision limit root families',
    );
    my $revision_overflow = changed(
        $revision_import, '(intents (family shared (revision 2)))',
        '(intents (family revision_257 (revision 1)))',
        'revision limit imported family',
    );
    check_v2_failure(
        'connected-catalog family-revision excess', $revision_limit_root,
        'VIAL_LIMIT_ERROR', qr/256-family-revision limit/,
        qr{/intent_families/0/revision$},
        { 'vial/revision_overflow.vial' => $revision_overflow },
        'vial/revision_overflow.vial',
    );
};

subtest 'public v1 tooling does not mislabel or advertise the private v2 foundation' => sub {
    my $result = execute_vial_tool_request(
        v1_tool_request($v2_source),
        { source_catalog => {}, artifact_sink => [] },
    );
    ok(!$result->{success}, 'v1 public tool request rejects v2 source');
    is($result->{schema}, 'fsmgen.vial_tool_result.v1', 'tool rejection remains in the v1 result envelope');
    is($result->{diagnostics}[0]{code}, 'VIAL_VERSION_UNSUPPORTED',
        'tool rejection names the unavailable version boundary');
    is($result->{semantic_report}, undef, 'tool rejection exposes no private v2 semantic report');
    is($result->{source_style}, undef, 'tool rejection does not mislabel v2 as normal_v1');
    my $capabilities = vial_tool_capabilities();
    is_deeply(
        [grep {
            $_ eq 'vial.source.v2'
                || $_ eq 'vial.semantic_ir.v2'
                || $_ eq 'vial.profile.core_directed_single_clock_v2'
        } @{$capabilities->{capabilities}}],
        [],
        'public capability discovery advertises no v2 source foundation before the tooling owner ships it');
    my $v2_with_import = changed(
        $v2_source,
        '(imports)',
        '(imports (import common "vial/common.vial"))',
        'unexposed v2 CLI import',
    );
    is_deeply(
        FSM::VIAL::SourceProjection->import_source_names({
            text => $v2_with_import,
            source_name => $source_name,
        }),
        [],
        'the v1 CLI catalog loader receives no v2 import path before v2 tooling exists');
    my $catalog_result = execute_vial_tool_request(
        v1_tool_request($v2_with_import),
        { source_catalog => {}, artifact_sink => [] },
    );
    is($catalog_result->{diagnostics}[0]{code}, 'VIAL_VERSION_UNSUPPORTED',
        'the v1 tool rejects a valid v2 catalog root before import resolution');

    my $v2_ir = FSM::VIAL::Parser->parse_source({
        text => $v2_source,
        source_name => $source_name,
    });
    my $plan = FSM::VIAL::PlanBuilder->build({
        semantic_ir => $v2_ir,
        hial_source => {},
        fixture_id => undef,
        scenario_ids => [],
        execution_profile => undef,
        replay_manifest => undef,
        native_extension_catalog => [],
    });
    ok(!$plan->{ok}, 'version-1 planning rejects the private v2 SemanticIR before HIAL work');
    is($plan->{diagnostics}[0]{code}, 'VIAL_VERSION_UNSUPPORTED',
        'planning rejection names the unimplemented downstream version boundary');
    is($plan->{diagnostics}[0]{semantic_path}, '/semantic_ir/language_version',
        'planning rejection points at the semantic version boundary');
};

done_testing();
