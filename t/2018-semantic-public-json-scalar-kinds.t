use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use JSON::PP;
use Storable qw(dclone);
use Cwd qw(abs_path);
use FSM::Support::SemanticIntrospectionMCPAdapter;
use FSM::Test::SourceQueryRunner qw(normalize_repository_paths);

my $root = abs_path('.');
my $json = JSON::PP->new->canonical;
my $literal = '{"integer":3,"zero":0,"negative":-2,"ratio":1.5,"strings":["3","0","1.5","01"],"true":true,"false":false,"null":null,"nested":{"schema_version":1}}';
my $source = 'docs/audits/specforge-aggregate-intake-20260930/baseline-good.isf';

subtest 'fresh decoded scalar kinds survive test path normalization' => sub {
    my $value = $json->decode($literal);
    $value->{path} = "$root/$source";
    my $before = $json->encode($value);
    my $expected = $json->decode($before);
    $expected->{path} = $source;
    my $normalized = normalize_repository_paths($value, $root);
    is($json->encode($normalized), $json->encode($expected),
        'only exact repository path changes; numeric and string kinds remain literal');
    is($json->encode(dclone($normalized)), $json->encode($expected),
        'a later detached copy retains every literal scalar kind');
    is($json->encode($value), $before, 'normalization leaves complete first-touch input unchanged');
};

subtest 'public source result keeps decoded primitive kinds while sanitizing paths' => sub {
    my $value = $json->decode($literal);
    $value->{path} = "$root/$source";
    $value->{external} = '/unowned-public-fixture/outside.fsm';
    $value->{expression} = '(div a/b c)';
    $value->{uri} = 'https://example.invalid/reference';
    my $before = $json->encode($value);
    my $expected = $json->decode($before);
    $expected->{path} = $source;
    $expected->{external} = '[absolute-path-redacted]';
    my $api = FSM::Support::SemanticIntrospectionMCPAdapter->new(
        repo_root => $root, workspace_root => $root, runner => sub {return $value});
    my $result = $api->call_tool('fsmgen_check', {source_id => $source});
    is($json->encode($result->{structuredContent}{report}), $json->encode($expected),
        'public projection changes only paths and retains literal primitive kinds');
    is($json->encode(dclone($result->{structuredContent}{report})), $json->encode($expected),
        'copying the public report cannot turn numbers into strings');
    is($json->encode($value), $before, 'public projection leaves complete supplied report unchanged');
    is($json->encode($json->decode($result->{content}[0]{text})), $json->encode($result->{structuredContent}),
        'complete public text and structured kinds agree');
};

subtest 'recognized source failures retain copied schema version kinds' => sub {
    for my $case (['fsmgen_check', 'check_schema_version', 'FSM::Support::CheckDiagnostics', 'check'],
                  ['fsmgen_semantic_introspect', 'normalized_semantic_schema_version',
                   'FSM::Support::NormalizedSemanticReport', 'semantic_export']) {
        my ($tool, $version, $producer, $mode) = @$case;
        my $value = $json->decode('{"success":false,"diagnostics":[{"code":null,"message":"source refused"}]}');
        $value->{$version} = $json->decode('1');
        $value->{producer} = {name => 'FSMGen', report_source => $producer};
        $value->{command} = {mode => $mode};
        $value->{source} = {input => $source};
        my $before = $json->encode($value);
        my $api = FSM::Support::SemanticIntrospectionMCPAdapter->new(
            repo_root => $root, workspace_root => $root, runner => sub {return $value});
        my $result = $api->call_tool($tool, {source_id => $source});
        ok($result->{isError}, "$tool recognizes the actual failure signature");
        is($json->encode(dclone($result->{structuredContent}{report})), $before,
            "$tool classification and sanitization leave copied version numeric");
        is($json->encode($value), $before, "$tool failure leaves supplied report unchanged");
    }
};

subtest 'VIAL failure classification preserves caller copy kinds' => sub {
    my $check = $json->decode('{"schema":"fsmgen.vial_tool_result.v2","schema_version":2,"success":false,"action":"check","implementation":{"component":"FSM::VIAL::Tool"},"diagnostics":[{"message":"refused"}]}');
    my $inspection = $json->decode('{"schema":"fsmgen.vial_source_inspection.v1","schema_version":1,"success":false,"inspection":null,"check_result":{},"diagnostics":[{"message":"refused"}]}');
    for my $case ([$check, 'check', \&FSM::Support::SemanticIntrospectionMCPAdapter::_is_vial_check_failure_report],
                  [$inspection, 'inspection', \&FSM::Support::SemanticIntrospectionMCPAdapter::_is_vial_inspection_failure_report]) {
        my ($value, $kind, $classify) = @$case;
        my $before = $json->encode($value);
        ok($classify->($value, $kind), "$kind VIAL failure signature remains recognized");
        is($json->encode(dclone($value)), $before, "$kind classifier retains copied caller scalar kinds");
    }
};

done_testing;
