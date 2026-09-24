#!/usr/bin/env perl
use strict;
use warnings;
use Cwd qw(abs_path);
use Digest::SHA qw(sha256_hex);
use FindBin;
use JSON::PP qw(decode_json encode_json);
use Test::More;
use lib "$FindBin::Bin/../perl";
use FSM::ProjectDataLocality qw(create_project_tempdir);
use FSM::Support::SemanticIntrospectionMCPAdapter;
use FSM::VIAL::Parser;
use FSM::VIAL::PlanBuilder;
use FSM::VIAL::SourceProjection;
use FSM::VIAL::Tool qw(execute_vial_tool_request check_vial_source_file);
use FSM::VIAL::ToolCLI;

my $repo = abs_path("$FindBin::Bin/..");
my $workspace = create_project_tempdir(purpose => 'vial-model-reference-identity');
my $source_id = 'model_reference.vial';
my $package = 'ahb_subordinate_base_output_arbitration';
my $fixture_id = "$package\::fixture::base_output_arbitration";
my $state_id = "$package\::model::event_counter::state::count";
my $adapter = FSM::Support::SemanticIntrospectionMCPAdapter->new(
    repo_root => $repo, workspace_root => $workspace);
my %base = (
    1 => read_file("$repo/vial/ahb_subordinate_base_output_arbitration.vial"),
    2 => read_file("$repo/vial/ahb_subordinate_base_output_arbitration_v2.vial"),
);

sub source_envelope {
    my ($id, $text, $kind) = @_;
    return {source_id => $id, source_kind_hint => $kind, text => $text,
        encoding => 'utf-8', origin => 'repository', display_name => $id,
        canonical_id => undef, relative_path => $id, metadata => {}};
}
sub request {
    my ($version, $text, $action) = @_;
    $action //= 'check';
    my $planning = $action eq 'plan';
    return {
        schema => "fsmgen.vial_tool_request.v$version", schema_version => $version,
        action => $action, vial_source => source_envelope($source_id, $text, 'vial'),
        hial_source => $planning ? source_envelope('ppif/ahb_lite_subordinate.ppif',
            read_file("$repo/ppif/ahb_lite_subordinate.ppif"), 'ppif') : undef,
        options => {
            source_style => 'auto', output_style => $action eq 'format' ? 'terse' : undef,
            fixture_id => $planning ? 'base_output_arbitration' : undef,
            scenario_ids => [], execution_profile => $planning
                ? "core_directed_single_clock_execution_v$version" : undef,
            backend_profile => undef, replay_manifest => undef, native_extension_catalogs => [],
            artifact_policy => $planning ? {mode => 'virtual', artifact_root => undef} : undef,
            quiet => JSON::PP::false,
        },
    };
}
sub execute {
    my ($version, $text, $action) = @_;
    return execute_vial_tool_request(request($version, $text, $action),
        {source_catalog => {}, artifact_sink => [], repository_root => $repo});
}
sub authored {
    my ($version, $instance) = @_;
    my $text = $base{$version};
    my $changed = $text =~ s/\(value_eq \(event_count success_write accepted\) 1\)/(value_eq (model $instance count) 1)/;
    die 'expected exactly one authored replacement' unless $changed == 1;
    return $text;
}
sub model_references {
    my ($value) = @_;
    return () unless ref($value);
    return map { model_references($_) } @$value if ref($value) eq 'ARRAY';
    return () unless ref($value) eq 'HASH';
    return ($value) if ($value->{kind} // '') eq 'reference' && ($value->{op} // '') eq 'model';
    return map { model_references($value->{$_}) } sort keys %$value;
}
sub meaning { return $_[0]{capability_evidence}{semantic_projection_sha256}; }

for my $version (1, 2) {
    subtest "v$version selected instance survives semantics, tooling and MCP" => sub {
        my (%digests, %hashes);
        for my $instance (qw(accepts completions)) {
            my $text = authored($version, $instance);
            my $expected_instance = "$fixture_id\::model_instance::$instance";
            my $checked = execute($version, $text);
            ok($checked->{success}, "$instance model-state read checks")
                or diag explain $checked->{diagnostics};
            $digests{$instance} = meaning($checked);
            $hashes{$instance} = sha256_hex($text);
            my $ir = FSM::VIAL::Parser->parse_source({text => $text, source_name => $source_id});
            my @references = model_references($ir->as_hashref);
            is(scalar(@references), 1, 'one independently authored model-state read');
            is($references[0]{semantic_id}, $state_id, 'state declaration identity remains explicit');
            is($references[0]{model_instance_id}, $expected_instance,
                'selected instance identity is distinct from the shared state declaration');
            my %instances = map { $_->{semantic_id} => $_ }
                @{$ir->as_hashref->{packages}[0]{fixtures}[0]{instances}{model_instances}};
            ok(exists($instances{$expected_instance}), 'reference resolves to the authored fixture instance');
            is($instances{$expected_instance}{model_id}, "$package\::model::event_counter",
                'selected instance uses the declared counter model');
            my $event = $instance eq 'accepts' ? 'accepted' : 'completed';
            is($instances{$expected_instance}{bindings}[0]{value}{event_id},
                "$package\::transaction::ahb_write::event::$event",
                'independent authored binding distinguishes the selected counter');

            my $formatted = execute($version, $text, 'format');
            ok($formatted->{success}, 'normal source formats as terse');
            my $rechecked = execute($version, $formatted->{formatted_source});
            ok($rechecked->{success}, 'terse form checks');
            is(meaning($rechecked), meaning($checked), 'formatting preserves the selected-instance meaning');
            my $terse_ir = FSM::VIAL::Parser->parse_source({
                text => $formatted->{formatted_source}, source_name => $source_id});
            my @terse_refs = model_references($terse_ir->as_hashref);
            is($terse_refs[0]{model_instance_id}, $expected_instance, 'terse reference retains instance');

            write_file("$workspace/$source_id", $text);
            my $file_result = check_vial_source_file({workspace_root => $workspace,
                source_id => $source_id, language_version => $version});
            is_deeply($file_result, $checked, 'filesystem and portable reports agree completely');
            my ($out, $err, $exit) = ('', '');
            {
                open my $stdout, '>', \$out or die $!;
                open my $stderr, '>', \$err or die $!;
                local *STDOUT = $stdout; local *STDERR = $stderr;
                $exit = FSM::VIAL::ToolCLI->run({repo_root => $workspace,
                    argv => ['check', '--json', '--language-version', $version, $source_id]});
            }
            is($exit, 0, 'native ToolCLI succeeds');
            is($err, '', 'native ToolCLI emits no error');
            is_deeply(decode_json($out), $checked, 'native CLI report preserves corrected meaning');
            my $mcp = $adapter->call_tool('fsmgen_semantic_introspect', {
                source_id => $source_id, language_version => $version});
            ok(!$mcp->{isError}, 'MCP semantic query succeeds');
            is_deeply($mcp->{structuredContent}{report}, $checked,
                'MCP carries the complete corrected native report');
            is_deeply(decode_json($mcp->{content}[0]{text}), $mcp->{structuredContent},
                'text and structured MCP output agree');
            is_deeply($checked->{artifacts}, [], 'check publishes no artifacts');
            ok(!defined($checked->{plan}), 'check does not create a plan');
            is(read_file("$workspace/$source_id"), $text, 'read-only queries leave source untouched');
        }
        isnt($hashes{accepts}, $hashes{completions}, 'authored source identities differ');
        isnt($digests{accepts}, $digests{completions},
            'semantically different model selections cannot share the meaning digest');
    };
}

subtest 'planning and migration preserve selected model scope' => sub {
    for my $version (1, 2) {
        for my $instance (qw(accepts completions)) {
            my $result = execute($version, authored($version, $instance), 'plan');
            ok($result->{success}, "v$version $instance reaches target-neutral planning")
                or diag explain $result->{diagnostics};
            my $built = FSM::VIAL::PlanBuilder->build({
                semantic_ir => FSM::VIAL::Parser->parse_source({
                    text => authored($version, $instance), source_name => $source_id}),
                hial_source => {source_id => 'ppif/ahb_lite_subordinate.ppif', format => 'ppif',
                    text => read_file("$repo/ppif/ahb_lite_subordinate.ppif")},
                fixture_id => 'base_output_arbitration', scenario_ids => [],
                execution_profile => "core_directed_single_clock_execution_v$version",
                replay_manifest => undef, native_extension_catalog => [],
            });
            ok($built->{ok}, 'native execution builder succeeds')
                or diag explain $built->{diagnostics};
            my @references = model_references($built->{execution_ir}->as_hashref);
            ok(@references, 'typed execution retains the model read');
            is_deeply([map { $_->{model_instance_id} } @references],
                [("$fixture_id\::model_instance::$instance") x @references],
                'every execution model read retains its selected instance');
        }
    }
    my %migrated;
    for my $instance (qw(accepts completions)) {
        my $text = authored(1, $instance);
        my $result = execute(2, $text, 'migrate');
        ok($result->{success}, "$instance source migrates to v2")
            or diag explain $result->{diagnostics};
        my $migration = $result->{source_migration};
        my $promoted = $migration->{sources}[0]{formatted_source};
        my $v1 = FSM::VIAL::Parser->parse_source({text => $text, source_name => $source_id});
        my $v2 = FSM::VIAL::Parser->parse_source({text => $promoted, source_name => $source_id});
        is(FSM::VIAL::SourceProjection->compatibility_projection_sha256($v1),
            FSM::VIAL::SourceProjection->compatibility_projection_sha256($v2),
            'migration preserves exact cross-version selected-instance meaning');
        my @references = model_references($v2->as_hashref);
        is($references[0]{model_instance_id}, "$fixture_id\::model_instance::$instance",
            'migrated source preserves the chosen instance');
        $migrated{$instance} = $migration->{compatibility_projection_sha256};
    }
    isnt($migrated{accepts}, $migrated{completions},
        'compatibility digests distinguish different model selections too');
};

subtest 'unknown model and state names still fail closed' => sub {
    for my $version (1, 2) {
        for my $case (['missing', 'count'], ['accepts', 'missing']) {
            my $text = authored($version, $case->[0]);
            $text =~ s/\(model \Q$case->[0]\E count\)/(model $case->[0] $case->[1])/;
            my $result = execute($version, $text);
            ok(!$result->{success}, "v$version unknown selected identity fails");
            ok(!defined($result->{semantic_report}), 'failure publishes no partial semantic report');
            is($result->{diagnostics}[0]{code}, 'VIAL_REFERENCE_ERROR', 'reference diagnostic remains precise');
        }
    }
};

done_testing();
sub read_file {
    open my $fh, '<:raw', $_[0] or die $!;
    local $/; my $text = <$fh>; close $fh or die $!; return $text;
}
sub write_file {
    open my $fh, '>:raw', $_[0] or die $!;
    print {$fh} $_[1] or die $!; close $fh or die $!;
}
