#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use JSON::PP ();
use Test::More;
use lib "$FindBin::Bin/../perl", "$FindBin::Bin/lib";
use FSM::Support::RegressionCorpus qw(regression_corpus_entries);
use FSM::Support::SemanticIntrospectionContract qw(semantic_introspection_source_query_kinds);
use FSM::Test::HostedCorpusShard qw(select_hosted_corpus_entries);
use FSM::VIAL::Tool qw(check_vial_source_file);

my $loaded=eval {require FSM::Test::SourceQueryCoverage;1};
ok($loaded,'source-query cohort selector exists');
if (!$loaded) {done_testing();exit 0}
my $build=FSM::Test::SourceQueryCoverage->can('build_source_query_cohort');
my $focus=FSM::Test::SourceQueryCoverage->can('select_source_query_cohort');
my $versions=FSM::Test::SourceQueryCoverage->can('vial_source_versions');
ok($build && $focus && $versions,'selector exposes cohort, focus and explicit VIAL version mapping');
if (!$build || !$focus || !$versions) {done_testing();exit 0}
my @catalog=regression_corpus_entries();
my $json=JSON::PP->new->canonical;
my $queries=semantic_introspection_source_query_kinds();
my $cohort=$build->();
sub clone {$json->decode($json->encode($_[0]))}
sub row {+{id=>$_[0]//'feature.example',relpath=>'fsm/example.fsm',source_kind=>'fsm',classification=>'supported_smoke',family=>'example',coverage=>'example_semantics',strict_supported=>1,expected_module_name=>'example'}}
sub sample {+{entries=>[row()],query_kinds=>clone($queries),vial_versions=>{}}}
sub rejected {my ($args,$message)=@_;eval {$build->($args)};like($@,$message,'invalid or unaccounted selection fails specifically')}

subtest 'live supported catalog is accounted exactly with source work deduplicated' => sub {
    my @supported=grep {$_->{classification} eq 'supported_smoke'} @catalog;
    my %expected;my @order;
    for my $entry (@supported) {push @order,$entry->{relpath} unless exists $expected{$entry->{relpath}};push @{$expected{$entry->{relpath}}},$entry}
    is_deeply([map {$_->{source_id}} @$cohort],\@order,'one source row in first catalog occurrence order');
    my @actual_ids;
    for my $r (@$cohort) {
        my $source=$r->{source_id};my @entries=@{$expected{$source}};
        is_deeply([map {$_->{id}} @{$r->{catalog_entries}}],[map {$_->{id}} @entries],'every source retains its exact catalog IDs and order');
        is_deeply([map {[$_->{id},$_->{family},$_->{coverage}]} @{$r->{catalog_entries}}],[map {[$_->{id},$_->{family},$_->{coverage}]} @entries],'ID-to-family/coverage allocation is retained');
        push @actual_ids,map {$_->{id}} @{$r->{catalog_entries}};
        my ($suffix)=$source =~ /\.([^.]+)$/;
        is($r->{file_kind},$suffix,'file kind comes from source suffix');
        is_deeply($r->{query_kinds},$queries->{$suffix},'every applicable public query is selected');
        if ($suffix eq 'vial') {
            is($r->{language_version},$versions->()->{$source},'VIAL version is explicitly mapped');
            ok(!$r->{strict},'VIAL uses versioned source admission');
            my $checked=check_vial_source_file({workspace_root=>"$FindBin::Bin/..",source_id=>$source,language_version=>$r->{language_version}});
            ok($checked->{success},'explicit mapping admits the actual public VIAL source') or diag($json->encode($checked->{diagnostics}));
        }
        else {ok($r->{strict},'hardware uses strict source admission');ok(!defined $r->{language_version},'hardware has no VIAL selector')}
    }
    is_deeply([sort @actual_ids],[sort map {$_->{id}} @supported],'no supported entry is lost or duplicated');
    my @public=map {s{^\Q$FindBin::Bin/..\E/}{}r} glob("$FindBin::Bin/../vial/*.vial");
    is_deeply([sort keys %{$versions->()}],[sort @public],'every public root VIAL example is explicitly versioned; runtime qualification fixtures are separate');
    is_deeply($build->(),$cohort,'selection is deterministic');
    my $mutated=$build->();$mutated->[0]{catalog_entries}[0]{coverage}='changed';
    is_deeply($build->(),$cohort,'selection returns independent records');
};

subtest 'focused selection is exact and preserves canonical order and shard compatibility' => sub {
    my @ids=map {$_->{source_id}} @$cohort;
    my $selected=$focus->({cohort=>$cohort,source_ids=>[$ids[-1],$ids[0]]});
    is_deeply([map {$_->{source_id}} @$selected],[$ids[0],$ids[-1]],'focus retains canonical order independent of argument order');
    is_deeply($focus->({cohort=>$cohort}),$cohort,'omitted focus selects all rows');
    for my $ids ([],['unknown.fsm'],[$ids[0],$ids[0]]) {eval {$focus->({cohort=>$cohort,source_ids=>$ids})};ok($@,'empty unknown or repeated focus is rejected')}
    my %seen;
    for my $i (0..2) {
        local $ENV{FSMGEN_HOSTED_CORPUS_SHARD_INDEX}=$i;local $ENV{FSMGEN_HOSTED_CORPUS_SHARD_COUNT}=3;
        my $shard=select_hosted_corpus_entries(entries=>$cohort);
        for my $r (@$shard) {ok(!$seen{$r->{source_id}}++,'hosted source partitions are disjoint');is_deeply($r->{query_kinds},$queries->{$r->{file_kind}},'all queries for each source remain together')}
    }
    is_deeply([sort keys %seen],[sort @ids],'hosted partitions cover the complete selected source set');
    $selected->[0]{query_kinds}[0]='changed';is_deeply($build->(),$cohort,'focused result does not alias original data');
};

subtest 'unknown source query version and conflicting metadata fail closed' => sub {
    my $a=sample();$a->{query_kinds}{vial}=[qw(check semantic)];rejected($a,qr/query applicability/);
    $a=sample();push @{$a->{query_kinds}{fsm}},'execute';rejected($a,qr/query applicability/);
    $a=sample();$a->{query_kinds}{future}=['check'];rejected($a,qr/source kind/);
    $a=sample();$a->{entries}[0]{relpath}='example.future';rejected($a,qr/source suffix/);
    $a=sample();$a->{entries}[0]{source_kind}='future';rejected($a,qr/source kind/);
    $a=sample();$a->{entries}[0]{strict_supported}=0;rejected($a,qr/strict/);
    $a=sample();$a->{entries}[0]{relpath}='../example.fsm';rejected($a,qr/relative source/);
    $a=sample();delete $a->{entries}[0]{coverage};rejected($a,qr/coverage/);
    $a=sample();push @{$a->{entries}},clone($a->{entries}[0]);rejected($a,qr/duplicate catalog ID/);
    $a=sample();my $second=row('feature.second');$second->{expected_module_name}='other';push @{$a->{entries}},$second;rejected($a,qr/conflicting.*expected_module_name/);
    $a=sample();$a->{vial_versions}{'vial/unused.vial'}=2;rejected($a,qr/unaccounted VIAL/);
    $a=sample();$a->{entries}[0]{relpath}='vial/new.vial';$a->{entries}[0]{source_kind}='vial';$a->{entries}[0]{strict_supported}=0;rejected($a,qr/unmapped VIAL/);
    $a->{vial_versions}{'vial/new.vial'}=3;rejected($a,qr/VIAL version/);
    $a=sample();$a->{entries}[0]{classification}='new_class';rejected($a,qr/classification/);
    $a=sample();$a->{entries}[0]{search_path_relpaths}=['../outside'];rejected($a,qr/relative search path/);
    for my $args (undef,[],{unknown=>1},{entries=>[]},{entries=>[undef]}) {rejected($args,qr/cohort|catalog/)}
};

subtest 'legitimate shared-source contracts retain all identities and defensive metadata' => sub {
    my $a=sample();my $second=row('feature.second');$second->{coverage}='another_surface';$second->{family}='another_family';push @{$a->{entries}},$second;
    $a->{entries}[0]{required_capabilities}=['feature.first'];$a->{entries}[0]{search_path_relpaths}=['fsm'];
    $second->{search_path_relpaths}=['fsm'];my $saved=clone($a);
    my $r=$build->($a);is(scalar(@$r),1,'shared physical source is queried once per kind');
    is_deeply([map {$_->{coverage}} @{$r->[0]{catalog_entries}}],['example_semantics','another_surface'],'distinct coverage memberships retained');
    is_deeply($r->[0]{search_path_relpaths},['fsm'],'explicit search paths retained for actual execution');
    $r->[0]{catalog_entries}[0]{required_capabilities}[0]='changed';is_deeply($a,$saved,'output never mutates or borrows caller input');
    $a->{entries}[0]{classification}='expected_failure';$r=$build->($a);is_deeply([map {$_->{id}} @{$r->[0]{catalog_entries}}],['feature.second'],'negative population does not become supported source evidence');
};
done_testing();
