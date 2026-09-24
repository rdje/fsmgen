#!/usr/bin/env perl
use strict;
use warnings;
use bytes ();
use Cwd qw(abs_path);
use Digest::SHA qw(sha256_hex);
use File::Find;
use FindBin;
use IPC::Cmd ();
use JSON::PP qw(decode_json encode_json);
use Test::More;
use lib "$FindBin::Bin/../perl";
use FSM::ProjectDataLocality qw(create_project_tempdir);
use FSM::Support::VIALToolingContract qw(build_vial_tooling_contract build_vial_source_file_check_contract);
use FSM::VIAL::Tool qw(execute_vial_tool_request);
use FSM::VIAL::ToolCLI;
use FSM::Support::SemanticIntrospectionContract qw(semantic_introspection_contract_surface_map);

my $repo = abs_path("$FindBin::Bin/..");
my $workspace = create_project_tempdir(purpose => 'vial-filesystem-source-query');
my $limits = build_vial_tooling_contract()->{limits};
my $api = FSM::VIAL::Tool->can('check_vial_source_file');
my %source = (1 => 'vial/ahb_subordinate_base_output_arbitration.vial',
              2 => 'vial/ahb_subordinate_base_output_arbitration_v2.vial');
my %text;
for my $version (1, 2) {
    open my $fh, '<:raw', "$repo/$source{$version}" or die $!;
    local $/; $text{$version} = <$fh>; close $fh or die $!;
}
sub write_source {
    my ($id, $text) = @_;
    open my $fh, '>:raw', "$workspace/$id" or die $!;
    print {$fh} $text; close $fh or die $!;
}
sub with_imports {
    my ($version, @ids) = @_;
    my $root = $text{$version};
    my $imports = join(' ', map { qq{(import p$_ "$ids[$_]")} } 0 .. $#ids);
    $root =~ s/\(imports\)/(imports $imports)/ or die 'missing import marker';
    return $root;
}
sub imported {
    my ($version, $name) = @_;
    my $value = $text{$version};
    $value =~ s/package ahb_subordinate_base_output_arbitration/package $name/ or die 'missing package';
    return $value;
}
sub invoke {
    my ($args) = @_;
    my ($out, $err, $result) = ('', '');
    {
        open my $stdout, '>', \$out or die $!;
        open my $stderr, '>', \$err or die $!;
        local *STDOUT = $stdout; local *STDERR = $stderr;
        $result = $api->($args);
    }
    is($out, '', 'filesystem API does not print stdout');
    is($err, '', 'filesystem API does not print stderr');
    is_deeply($result->{artifacts}, [], 'filesystem check publishes no artifact');
    ok(!defined($result->{plan}), 'filesystem check does not plan');
    return $result;
}
sub memory_request {
    my ($version, $id, $value) = @_;
    return {schema => "fsmgen.vial_tool_request.v$version", schema_version => $version, action => 'check',
        vial_source => {source_id => $id, source_kind_hint => 'vial', text => $value, encoding => 'utf-8',
            origin => 'repository', display_name => $id, canonical_id => undef, relative_path => $id, metadata => {}},
        hial_source => undef, options => {source_style => 'auto', output_style => undef,
            fixture_id => undef, scenario_ids => [], execution_profile => undef, backend_profile => undef,
            replay_manifest => undef, native_extension_catalogs => [], artifact_policy => undef, quiet => JSON::PP::false}};
}
sub snapshot {
    my %files;
    find({no_chdir => 1, wanted => sub {
        return unless -f $_ && !-l $_;
        open my $fh, '<:raw', $_ or die $!; local $/;
        $files{substr($_, length($workspace) + 1)} = sha256_hex(<$fh> // ''); close $fh or die $!;
    }}, $workspace);
    return \%files;
}

subtest 'filesystem loading refuses oversized source before returning text' => sub {
    my $oversize = ' ' x ($limits->{source_bytes} + 1);
    write_source('oversize.vial', $oversize);
    my ($loaded, $error, $code) = FSM::VIAL::ToolCLI::_read_repo_source($workspace, 'oversize.vial', 'vial');
    ok(!defined($loaded), 'over-limit source is not materialized for the semantic producer');
    like($error // '', qr/source.*byte.*limit/, 'filesystem admission explains the byte limit');
    is($code, 'VIAL_LIMIT_ERROR', 'filesystem admission keeps the public limit family');
};

subtest 'filesystem import admission caps distinct files and combined bytes' => sub {
    my @ids = map { "part_$_.vial" } 1 .. ($limits->{imported_sources} + 1);
    for my $i (0 .. $#ids) { write_source($ids[$i], imported(1, "part_$i")); }
    my $root = with_imports(1, @ids);
    write_source('imports.vial', $root);
    my ($catalog, $error, $code) = FSM::VIAL::ToolCLI::_load_import_catalog($workspace, 'imports.vial', $root, 1);
    ok(!defined($catalog), 'excess distinct import catalog is not returned');
    like($error // '', qr/import.*limit/, 'import admission identifies count limit');
    is($code, 'VIAL_LIMIT_ERROR', 'import admission uses public limit family');

    my $blocks = int($limits->{combined_source_bytes} / $limits->{source_bytes});
    my @large_ids = map { "large_$_.vial" } 1 .. $blocks;
    $root = with_imports(1, @large_ids);
    $root .= ' ' x ($limits->{source_bytes} - bytes::length($root));
    for my $i (0 .. $#large_ids - 1) {
        my $part = imported(1, "large_$i");
        $part .= ' ' x ($limits->{source_bytes} - bytes::length($part));
        write_source($large_ids[$i], $part);
    }
    write_source($large_ids[-1], ' ');
    write_source('combined.vial', $root);
    ($catalog, $error, $code) = FSM::VIAL::ToolCLI::_load_import_catalog($workspace, 'combined.vial', $root, 1);
    ok(!defined($catalog), 'one-byte-over combined source catalog is not returned');
    like($error // '', qr/combined.*byte.*limit/, 'combined admission identifies byte limit');
    is($code, 'VIAL_LIMIT_ERROR', 'combined admission uses public limit family');
};

subtest 'stream guard handles exact, excess and empty input independently of stat' => sub {
    for my $case ([0, 0], [10, 10], [10, 11], [131072, 131073]) {
        my ($limit, $size) = @$case;
        my $bytes = 'x' x $size;
        open my $fh, '<', \$bytes or die $!;
        my ($value, $status) = FSM::VIAL::ToolCLI::_read_bounded_source_bytes($fh, $limit);
        if ($size > $limit) {
            ok(!defined($value), 'over-limit stream never returns truncated source text');
            is($status, 'limit', 'stream growth/excess is independently refused');
        } else {
            is($value, $bytes, 'exact/empty stream bytes are preserved');
            ok(!defined($status), 'admitted stream reaches clean EOF');
        }
        close $fh or die $!;
    }
};

subtest 'closed filesystem facade exposes existing v1/v2 native results' => sub {
    ok($api, 'public filesystem check API is exported');
    return unless $api;
    my $policy = build_vial_source_file_check_contract();
    is($policy->{entrypoint}, 'FSM::VIAL::Tool::check_vial_source_file($invocation)', 'public capability names the callable facade');
    is_deeply(semantic_introspection_contract_surface_map()->{vial_source_file_check}{file_query_contract}, $policy, 'semantic introspection advertises the separate filesystem contract');
    is_deeply($policy->{loading_limits}, {map { $_ => $limits->{$_} } qw(source_bytes combined_source_bytes imported_sources)}, 'filesystem admission and frozen native tooling declare the same limits');
    ok(!$policy->{writes_files} && !$policy->{prints_output}, 'public filesystem policy is query-only');
    for my $version (1, 2) {
        my ($ok, $error, $all, $out) = IPC::Cmd::run(command => ["$repo/bin/fsmgen", 'vial', 'check', '--json', '--language-version', $version, $source{$version}]);
        ok($ok, "native v$version check succeeds");
        my $native = decode_json(join('', @{$out || []}));
        my $checked = invoke({workspace_root => $repo, source_id => $source{$version}, language_version => $version});
        is_deeply($checked, $native, "filesystem API v$version exactly matches native CLI report");
        unlike(encode_json($checked), qr/\Q$repo\E/, 'result contains no absolute root');
        my $root = with_imports($version, "shared_$version.vial");
        my $part = imported($version, "shared_$version");
        write_source("root_$version.vial", $root); write_source("shared_$version.vial", $part);
        my $before = snapshot();
        $checked = invoke({workspace_root => $workspace, source_id => "root_$version.vial", language_version => $version});
        my $memory = execute_vial_tool_request(memory_request($version, "root_$version.vial", $root),
            {source_catalog => {"shared_$version.vial" => $part}, artifact_sink => []});
        ok($checked->{success}, "v$version imported source succeeds");
        is_deeply($checked, $memory, "v$version imports preserve public in-memory semantics and provenance");
        is_deeply(snapshot(), $before, 'filesystem query leaves exact input files and directory inventory unchanged');
    }
};

subtest 'exact declared source, import and combined boundaries remain admissible' => sub {
    plan skip_all => 'facade not implemented' unless $api;
    my $exact = $text{1} . (' ' x ($limits->{source_bytes} - bytes::length($text{1})));
    write_source('exact.vial', $exact);
    my $checked = invoke({workspace_root => $workspace, source_id => 'exact.vial'});
    ok($checked->{success}, 'exact source byte boundary remains valid');
    is($checked->{source_identities}[0]{content_sha256}, sha256_hex($exact), 'source identity authenticates the complete exact-size input');
    is(-s "$workspace/exact.vial", $limits->{source_bytes}, 'independent file size is the declared boundary');
    my @ids = map { "part_$_.vial" } 1 .. $limits->{imported_sources};
    write_source('exact_imports.vial', with_imports(1, @ids));
    $checked = invoke({workspace_root => $workspace, source_id => 'exact_imports.vial'});
    ok($checked->{success}, 'exact distinct import boundary remains valid');
    is(scalar(@{$checked->{source_identities}}), $limits->{imported_sources} + 1, 'root is counted separately from imported files');
    my $blocks = int($limits->{combined_source_bytes} / $limits->{source_bytes});
    @ids = map { "large_$_.vial" } 1 .. ($blocks - 1);
    $exact = with_imports(1, @ids);
    $exact .= ' ' x ($limits->{source_bytes} - bytes::length($exact));
    write_source('exact_combined.vial', $exact);
    $checked = invoke({workspace_root => $workspace, source_id => 'exact_combined.vial'});
    ok($checked->{success}, 'exact combined byte boundary remains valid');
    my $total = 0;
    my $files = snapshot();
    for my $identity (@{$checked->{source_identities}}) {
        is($identity->{content_sha256}, $files->{$identity->{source_name}}, 'reported source identity matches independently read bytes');
        $total += -s "$workspace/$identity->{source_name}";
    }
    is($total, $limits->{combined_source_bytes}, 'independent identified-file sizes total the admitted bytes');
};

subtest 'filesystem API preserves failures and rejects authority widening' => sub {
    plan skip_all => 'facade not implemented' unless $api;
    for my $arguments ([], [undef], [[]], [{}], [{workspace_root => $workspace}],
                       [{workspace_root => $workspace, source_id => 'root_1.vial'}, {}]) {
        my $result = $api->(@$arguments);
        ok(!$result->{success}, 'missing, malformed or extra invocation arguments fail closed');
        is($result->{diagnostics}[0]{code}, 'VIAL_TOOL_INVOCATION_ERROR', 'invocation failure is a public diagnostic');
    }
    for my $change ({language_version => 3}, {language_version => JSON::PP::true}, {source_style => 'unknown'},
                    {action => 'run'}, {workspace_root => []}, {source_id => '../escape.vial'},
                    {source_id => "$repo/$source{1}"}) {
        my $result = invoke({workspace_root => $workspace, source_id => 'root_1.vial', %$change});
        ok(!$result->{success}, 'invalid version/style/shape/path/action fails closed');
        ok(@{$result->{diagnostics}}, 'failure remains a structured public result');
    }
    symlink "$repo/$source{1}", "$workspace/linked.vial" or die $!;
    my $linked = invoke({workspace_root => $workspace, source_id => 'linked.vial'});
    ok(!$linked->{success}, 'symlink source is rejected');
    write_source('empty.vial', '');
    my $empty = invoke({workspace_root => $workspace, source_id => 'empty.vial'});
    my $empty_memory = execute_vial_tool_request(memory_request(1, 'empty.vial', ''), {source_catalog => {}, artifact_sink => []});
    is_deeply($empty, $empty_memory, 'empty file preserves the portable source diagnostic');
    my $cycle_text = with_imports(1, 'cycle.vial'); write_source('cycle.vial', $cycle_text);
    my $cycle = invoke({workspace_root => $workspace, source_id => 'cycle.vial'});
    my $cycle_memory = execute_vial_tool_request(memory_request(1, 'cycle.vial', $cycle_text), {source_catalog => {'cycle.vial' => $cycle_text}, artifact_sink => []});
    is_deeply($cycle, $cycle_memory, 'cycle diagnosis remains owned by native semantics');
    my $missing = with_imports(2, 'missing.vial'); write_source('missing_root.vial', $missing);
    my $result = invoke({workspace_root => $workspace, source_id => 'missing_root.vial', language_version => 2});
    my $memory = execute_vial_tool_request(memory_request(2, 'missing_root.vial', $missing), {source_catalog => {}, artifact_sink => []});
    is_deeply($result, $memory, 'missing import preserves native diagnostic and source location');
    for my $id (qw(oversize.vial imports.vial combined.vial)) {
        $result = invoke({workspace_root => $workspace, source_id => $id});
        is($result->{diagnostics}[0]{code}, 'VIAL_LIMIT_ERROR', "$id returns typed filesystem admission failure");
        ok(!$result->{success}, "$id does not claim valid semantics");
    }
    $result = invoke({workspace_root => $workspace, source_id => 'oversize.vial', language_version => 2});
    is($result->{schema}, 'fsmgen.vial_tool_result.v2', 'filesystem refusal retains the requested version');
    is($result->{diagnostics}[0]{code}, 'VIAL_LIMIT_ERROR', 'v2 retains the public limit diagnostic');
    is($result->{diagnostics}[0]{phase}, 'limit', 'v2 identifies the limit failure phase');
};

done_testing();
