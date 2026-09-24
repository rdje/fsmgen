#!/usr/bin/env perl
use strict;
use warnings;
use Cwd qw(abs_path);
use FindBin;
use JSON::PP qw(decode_json);
use Test::More;
use lib "$FindBin::Bin/../perl";
use FSM::ProjectDataLocality qw(create_project_tempdir);
use FSM::Support::SemanticIntrospectionMCPAdapter;
use FSM::VIAL::Parser;
use FSM::VIAL::SourceProjection;
use FSM::VIAL::Tool qw(execute_vial_tool_request check_vial_source_file);
use FSM::VIAL::ToolCLI;

my $repo = abs_path("$FindBin::Bin/..");
my $workspace = create_project_tempdir(purpose => 'vial-declaration-order');
my $source_id = 'declaration_order.vial';
my $package = 'ahb_subordinate_base_output_arbitration';
my %base = map { $_ => read_file("$repo/vial/ahb_subordinate_base_output_arbitration"
    . ($_ == 2 ? '_v2' : '') . '.vial') } (1, 2);
my $adapter = FSM::Support::SemanticIntrospectionMCPAdapter->new(
    repo_root => $repo, workspace_root => $workspace);

sub execute {
    my ($version, $text, $action, $catalog) = @_;
    $action //= 'check';
    return execute_vial_tool_request({
        schema => "fsmgen.vial_tool_request.v$version", schema_version => $version,
        action => $action,
        vial_source => {source_id => $source_id, source_kind_hint => 'vial', text => $text,
            encoding => 'utf-8', origin => 'repository', display_name => $source_id,
            canonical_id => undef, relative_path => $source_id, metadata => {}},
        hial_source => undef,
        options => {source_style => 'auto', output_style => $action eq 'format' ? 'terse' : undef,
            fixture_id => undef, scenario_ids => [], execution_profile => undef,
            backend_profile => undef, replay_manifest => undef, native_extension_catalogs => [],
            artifact_policy => undef, quiet => JSON::PP::false},
    }, {source_catalog => $catalog // {}, artifact_sink => []});
}
sub public_parity {
    my ($version, $text, $catalog, $checked) = @_;
    write_file("$workspace/$source_id", $text);
    write_file("$workspace/$_", $catalog->{$_}) for sort keys %$catalog;
    my $file = check_vial_source_file({workspace_root => $workspace, source_id => $source_id,
        language_version => $version});
    is_deeply($file, $checked, 'filesystem API matches the complete portable report');
    my ($out, $err, $exit) = ('', '');
    {
        open my $stdout, '>', \$out or die $!;
        open my $stderr, '>', \$err or die $!;
        local *STDOUT = $stdout; local *STDERR = $stderr;
        $exit = FSM::VIAL::ToolCLI->run({repo_root => $workspace,
            argv => ['check', '--json', '--language-version', $version, $source_id]});
    }
    is($exit, 0, 'native CLI succeeds');
    is($err, '', 'native CLI emits no error');
    is_deeply(decode_json($out), $checked, 'native CLI preserves complete declaration-order report');
    my $mcp = $adapter->call_tool('fsmgen_semantic_introspect', {
        source_id => $source_id, language_version => $version});
    ok(!$mcp->{isError}, 'MCP succeeds');
    is_deeply($mcp->{structuredContent}{report}, $checked, 'MCP preserves complete native report');
    is_deeply(decode_json($mcp->{content}[0]{text}), $mcp->{structuredContent},
        'text and structured MCP content agree');
    is_deeply($checked->{artifacts}, [], 'source check publishes no artifact');
    ok(!defined($checked->{plan}), 'source check creates no execution plan');
    is(read_file("$workspace/$source_id"), $text, 'source remains unchanged');
    is(read_file("$workspace/$_"), $catalog->{$_}, 'import remains unchanged') for sort keys %$catalog;
}

sub authored {
    my ($version, $imported) = @_;
    my $text = $base{$version};
    $text =~ s/\(types/(types (type first (type later)) (type later (u 8))/ or die 'missing types';
    my $catalog = {};
    if ($imported) {
        my $library = $text;
        $library =~ s/package \Q$package\E/package library/ or die 'missing package';
        $catalog->{'library.vial'} = $library;
        $text =~ s/\(imports\)/(imports (import lib "library.vial"))/;
        $text =~ s/\(type first \(type later\)\)/(type first (type later)) (type imported (type lib.first))/;
    }
    return ($text, $catalog);
}
sub parse { FSM::VIAL::Parser->parse_source({text => $_[0], source_name => $source_id, source_catalog => $_[1] // {}}) }

for my $version (1, 2) {
    subtest "v$version authored declarations survive native/API/MCP projection" => sub {
        for my $imported (0, 1) {
            my ($text, $catalog) = authored($version, $imported);
            my $r = execute($version, $text, 'check', $catalog);
            ok($r->{success}, 'forward declarations check') or diag explain $r->{diagnostics};
            my $raw = parse($text, $catalog)->as_hashref;
            for my $index (0 .. $#{$raw->{packages}}) {
                my $p = $raw->{packages}[$index];
                my @names = ('first', ($imported && $index == 0 ? ('imported') : ()), qw(later htrans_t address_t data_t));
                is_deeply([map { $_->{name} } @{$p->{types}}], \@names, 'native declarations follow independently authored order');
                is_deeply([map { $_->{name} } @{$r->{semantic_report}{packages}[$index]{types}}], \@names,
                    'complete public summary preserves the same authored order');
                is_deeply([map { $_->{semantic_path} } @{$p->{types}}],
                    [map { "/packages/$index/types/$_" } 0 .. $#names], 'array positions match their declaration paths');
                my ($first) = grep { $_->{name} eq 'first' } @{$p->{types}};
                is($first->{type}{semantic_id}, "$p->{name}\::type::later", 'forward reference remains exactly resolved');
                is($first->{type}{resolved}{width}, 8, 'resolved type width is unchanged');
            }
            if ($imported) {
                my ($import) = grep { $_->{name} eq 'imported' } @{$raw->{packages}[0]{types}};
                is($import->{type}{semantic_id}, 'library::type::first', 'cross-package declaration identity stays exact');
                is($import->{type}{resolved}{semantic_id}, 'library::type::later', 'transitive imported alias remains resolved');
            }
            my $formatted = execute($version, $text, 'format', $catalog);
            ok($formatted->{success}, 'forward declarations format as terse');
            my $terse = execute($version, $formatted->{formatted_source}, 'check', $catalog);
            ok($terse->{success}, 'terse source checks');
            is($terse->{capability_evidence}{semantic_projection_sha256},
                $r->{capability_evidence}{semantic_projection_sha256}, 'formatting preserves corrected meaning identity');
            is_deeply($terse->{semantic_report}{packages}, $r->{semantic_report}{packages}, 'terse summaries preserve complete declaration structure');
            public_parity($version, $text, $catalog, $r);
        }
    };
}

subtest 'migration preserves ordering and compatibility identity' => sub {
    my ($text) = authored(1, 0);
    my $r = execute(2, $text, 'migrate');
    ok($r->{success}, 'forward declarations migrate') or diag explain $r->{diagnostics};
    my $promoted = $r->{source_migration}{sources}[0]{formatted_source};
    my $old = parse($text); my $new = parse($promoted);
    is_deeply([map { $_->{name} } @{$new->as_hashref->{packages}[0]{types}}],
        [qw(first later htrans_t address_t data_t)], 'migration retains authored order');
    is(FSM::VIAL::SourceProjection->compatibility_projection_sha256($old),
        FSM::VIAL::SourceProjection->compatibility_projection_sha256($new), 'migration retains corrected compatibility digest');
};

subtest 'recursive and unresolved aliases still fail before publishing records' => sub {
    for my $version (1, 2) {
        for my $case (['missing', 'VIAL_REFERENCE_ERROR'], ['cycle', 'VIAL_TYPE_ERROR']) {
            my ($text) = authored($version, 0);
            $text =~ s/\(type later \(u 8\)\)/(type later (type first))/ if $case->[0] eq 'cycle';
            $text =~ s/\(type first \(type later\)\)/(type first (type missing))/ if $case->[0] eq 'missing';
            my $r = execute($version, $text);
            ok(!$r->{success}, 'invalid dependency rejected');
            is($r->{diagnostics}[0]{code}, $case->[1], 'original diagnostic family retained');
            ok(!defined($r->{semantic_report}), 'failed construction returns no partial summary');
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
