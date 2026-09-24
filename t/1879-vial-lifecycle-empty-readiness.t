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
use FSM::VIAL::SourceInspection;
use FSM::VIAL::Tool qw(execute_vial_tool_request check_vial_source_file);
use FSM::VIAL::ToolCLI;

my $repo=abs_path("$FindBin::Bin/..");
my $workspace=create_project_tempdir(purpose=>'vial-lifecycle-empty-readiness');
my $source_id='empty_readiness.vial';
my $base=read_file("$repo/vial/ahb_subordinate_base_output_arbitration_lifecycle_v2.vial");
my $hial_id='ppif/ahb_lite_subordinate.ppif';
my $hial=read_file("$repo/$hial_id");
my $package='ahb_subordinate_base_output_arbitration';
my $fixture="$package\::fixture::base_output_arbitration";
my $domain="$fixture\::domain::bus";
my $adapter=FSM::Support::SemanticIntrospectionMCPAdapter->new(repo_root=>$repo,workspace_root=>$workspace);
sub condition { +{kind=>$_[0],reference_id=>$_[1],domain_id=>$_[2],operands=>$_[3]//[]} }
sub all { condition('all',undef,undef,[@_]) }
sub envelope {
    my ($id,$text,$kind)=@_;
    return {source_id=>$id,source_kind_hint=>$kind,text=>$text,encoding=>'utf-8',origin=>'repository',
        display_name=>$id,canonical_id=>undef,relative_path=>$id,metadata=>{}};
}
sub execute {
    my ($text,$action,$catalog)=@_; $action //= 'check';
    return execute_vial_tool_request({schema=>'fsmgen.vial_tool_request.v2',schema_version=>2,action=>$action,
        vial_source=>envelope($source_id,$text,'vial'),
        hial_source=>$action eq 'plan' ? envelope($hial_id,$hial,'ppif') : undef,
        options=>{source_style=>'auto',output_style=>$action eq 'format' ? 'terse' : undef,
            fixture_id=>$action eq 'plan' ? 'base_output_arbitration' : undef,scenario_ids=>[],
            execution_profile=>$action eq 'plan' ? 'core_directed_single_clock_execution_v2' : undef,
            backend_profile=>undef,replay_manifest=>undef,native_extension_catalogs=>[],
            artifact_policy=>$action eq 'plan' ? {mode=>'virtual',artifact_root=>undef} : undef,quiet=>JSON::PP::false},
    },{source_catalog=>$catalog//{},artifact_sink=>[]});
}
sub authored {
    my ($requires)=@_; my $text=$base;
    $text =~ s/\(services\s+\(service background\s+\(target fixture_background\)\)\)/(services)/ or die 'missing service';
    $text =~ s/\(dependencies\s+\(dependency configured_gate \(when \(configured\)\)\)\s+\(dependency reset_gate \(when \(reset_inactive bus\)\)\)\)/(dependencies)/ or die 'missing dependencies';
    $text =~ s/\(readiness ready\)/(readiness ready (requires $requires))/ if defined $requires;
    return $text;
}
sub parse { FSM::VIAL::Parser->parse_source({text=>$_[0],source_name=>$source_id,source_catalog=>$_[1]//{}}) }
sub readiness { (grep { $_->{node_kind} eq 'readiness' } @{$_[0]{packages}[0]{intent_families}[0]{nodes}})[0] }
sub parity {
    my ($text,$catalog,$checked)=@_;
    write_file("$workspace/$source_id",$text); write_file("$workspace/$_",$catalog->{$_}) for sort keys %$catalog;
    is_deeply(check_vial_source_file({workspace_root=>$workspace,source_id=>$source_id,language_version=>2}),$checked,'filesystem and portable complete reports agree');
    my ($out,$err,$exit)=('','');
    { open my $stdout,'>',\$out or die $!;open my $stderr,'>',\$err or die $!;
      local *STDOUT=$stdout;local *STDERR=$stderr;
      $exit=FSM::VIAL::ToolCLI->run({repo_root=>$workspace,argv=>['check','--json','--language-version',2,$source_id]}); }
    is($exit,0,'native CLI succeeds');is($err,'','native CLI emits no error');
    is_deeply(decode_json($out),$checked,'native complete report agrees');
    my $mcp=$adapter->call_tool('fsmgen_semantic_introspect',{source_id=>$source_id,language_version=>2});
    ok(!$mcp->{isError},'MCP succeeds');is_deeply($mcp->{structuredContent}{report},$checked,'MCP retains complete native report');
    is_deeply(decode_json($mcp->{content}[0]{text}),$mcp->{structuredContent},'MCP transports identical text/structured content');
    is_deeply($checked->{artifacts},[],'source check publishes no artifact');ok(!defined $checked->{plan},'source check creates no plan');
    is(read_file("$workspace/$source_id"),$text,'source unchanged');
    is(read_file("$workspace/$_"),$catalog->{$_},'import unchanged') for sort keys %$catalog;
}

subtest 'readiness without prerequisites explicitly retains configured state' => sub {
    my $text=authored(); my $checked=execute($text);
    ok($checked->{success},'legal empty dependency/service collections check') or do {diag explain $checked->{diagnostics};return};
    my $native=parse($text)->as_hashref; my $ready=readiness($native);
    my $expected=all(condition('configured'));
    is_deeply($ready->{payload}{condition},$expected,'vacuous readiness explicitly requires the configured entry precondition');
    is_deeply($ready->{payload}{intrinsic_after},[],'no dependency or service identity invented');
    is_deeply($ready->{payload}{additional_after},[],'no authored relation invented');
    is_deeply($ready->{order}{after},[],'order relation set remains exact');
    is($ready->{order}{domain_id},$domain,'logical coordination domain retained');
    is_deeply([map {$_->{node_kind}} @{$native->{packages}[0]{intent_families}[0]{nodes}}],
        [qw(readiness stimulus_start completion drain shutdown finalize deadline deadline failure)],'only authored lifecycle record kinds remain');
    my $detail=FSM::VIAL::SourceInspection->build(parse($text));
    is_deeply(readiness($detail)->{payload}{condition},$expected,'typed inspection retains exact configured readiness');
    is(readiness($detail)->{payload}{fixture_id},$fixture,'typed fixture scope preserved');
    my $explicit=execute(authored('(configured)'));
    ok($explicit->{success},'equivalent explicit configured condition checks');
    is($checked->{capability_evidence}{semantic_projection_sha256},$explicit->{capability_evidence}{semantic_projection_sha256},'implicit entry precondition and explicit configured readiness have equal meaning');
    my $formatted=execute($text,'format');ok($formatted->{success},'source formats as terse');
    my $terse=execute($formatted->{formatted_source});ok($terse->{success},'terse empty readiness checks');
    is($terse->{capability_evidence}{semantic_projection_sha256},$checked->{capability_evidence}{semantic_projection_sha256},'style preserves normalized readiness');
    parity($text,{},$checked);
    my $planned=execute($text,'plan');ok($planned->{success},'actual target-neutral planning accepts empty prerequisites') or do {diag explain $planned->{diagnostics};return};
    my ($record)=grep {$_->{semantic}{node_kind} eq 'readiness'} @{$planned->{plan}{semantic_families}};
    is_deeply($record->{semantic}{payload}{condition},$expected,'plan retains configured readiness exactly');
    ok(!defined $planned->{run},'planning performs no backend run');
};

subtest 'authored nonempty requirements and imported fixture scope remain exact' => sub {
    my $text=authored('(reset_inactive bus)');my $checked=execute($text);
    ok($checked->{success},'explicit nonempty readiness still checks');
    is_deeply(readiness(parse($text)->as_hashref)->{payload}{condition},all(condition('reset_inactive',undef,$domain)),
        'existing nonempty readiness receives no added condition');
    my $library=authored();$library =~ s/package \Q$package\E/package library/;
    $text =~ s/\(imports\)/(imports (import lib "library.vial"))/;
    my $catalog={'library.vial'=>$library};my $import=execute($text,'check',$catalog);
    ok($import->{success},'imported empty readiness checks') or do {diag explain $import->{diagnostics};return};
    my $detail=FSM::VIAL::SourceInspection->build(parse($text,$catalog));
    my ($r)=grep {$_->{node_kind} eq 'readiness'} @{$detail->{packages}[1]{intent_families}[0]{nodes}};
    is($r->{payload}{fixture_id},'library::fixture::base_output_arbitration','imported readiness retains its fixture');
    is_deeply($r->{payload}{condition},all(condition('configured')),'imported configured condition is complete');
    is($r->{source_location}{source_name},'library.vial','imported source coordinates retained');
    parity($text,$catalog,$import);
};

subtest 'authored empty conjunction, unknown scope and cycles remain invalid' => sub {
    for my $case (
        ['(all)','VIAL_PARSE_ERROR'],
        ['(reset_inactive missing)','VIAL_SEMANTIC_ERROR'],
        ['(lifecycle_point ready)','VIAL_SEMANTIC_ERROR'],
        ['(all '.join(' ',('(configured)') x 65).')','VIAL_LIMIT_ERROR'],
    ) {
        my $r=execute(authored($case->[0]));ok(!$r->{success},'invalid authored readiness refused');
        is($r->{diagnostics}[0]{code},$case->[1],'original specific diagnostic family retained');
        ok(!defined $r->{semantic_report},'no partial semantic report');
        is_deeply($r->{artifacts},[],'no artifacts published');
    }
};
done_testing();
sub read_file {open my $fh,'<:raw',$_[0] or die $!;local $/;my $s=<$fh>;close $fh or die $!;return $s}
sub write_file {open my $fh,'>:raw',$_[0] or die $!;print {$fh} $_[1] or die $!;close $fh or die $!}
