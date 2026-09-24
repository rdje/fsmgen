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
my $workspace=create_project_tempdir(purpose=>'vial-lifecycle-start-requirements');
my $source_id='start_requirements.vial';
my $base=read_file("$repo/vial/ahb_subordinate_base_output_arbitration_lifecycle_v2.vial");
my $hial_id='ppif/ahb_lite_subordinate.ppif';
my $hial=read_file("$repo/$hial_id");
my $package='ahb_subordinate_base_output_arbitration';
my $fixture="$package\::fixture::base_output_arbitration";
my $domain="$fixture\::domain::bus";
my $flow="$package\::package::$package\::intent_family::lifecycle_control::lifecycle::fixture_flow";
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
    my ($condition,$no_dependencies)=@_; my $text=$base;
    $text =~ s/\(target fixture_background\)/(target fixture_background) (start_requires $condition)/ or die 'missing service';
    if ($no_dependencies) {
        $text =~ s/\(dependencies\s+\(dependency configured_gate \(when \(configured\)\)\)\s+\(dependency reset_gate \(when \(reset_inactive bus\)\)\)\)/(dependencies)/ or die 'missing dependencies';
    }
    return $text;
}
sub parse { FSM::VIAL::Parser->parse_source({text=>$_[0],source_name=>$source_id,source_catalog=>$_[1]//{}}) }
sub service { (grep { $_->{node_kind} eq 'service' } @{$_[0]{packages}[0]{intent_families}[0]{nodes}})[0] }
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

subtest 'authored start conditions remain separate from dependency identities' => sub {
    my @cases=(
        ['(configured)',condition('configured')],
        ['(reset_inactive bus)',condition('reset_inactive',undef,$domain)],
        ['(all (configured) (reset_inactive bus))',all(condition('configured'),condition('reset_inactive',undef,$domain))],
    );
    for my $no_dependencies (0,1) {
        for my $case (@cases) {
            my $text=authored($case->[0],$no_dependencies);my $checked=execute($text);
            ok($checked->{success},"legal $case->[0] checks with no_dependencies=$no_dependencies") or do {diag explain $checked->{diagnostics};next};
            my @intrinsic=$no_dependencies ? () : map { "$flow\::dependency::$_" } qw(configured_gate reset_gate);
            my $expected=all(condition('configured'),(map {condition('dependency_satisfied',$_)} @intrinsic),$case->[1]);
            my $native=service(parse($text)->as_hashref);
            is_deeply($native->{payload}{condition},$expected,'native condition is the independent ordered conjunction');
            is_deeply($native->{payload}{detail}{start_condition},$expected,'service detail retains the complete start condition');
            is_deeply($native->{payload}{intrinsic_after},\@intrinsic,'intrinsic dependency IDs remain scalar and exact');
            my $detail=FSM::VIAL::SourceInspection->build(parse($text));
            is_deeply(service($detail)->{payload}{condition},$expected,'typed inspection preserves exact authored additional condition');
            my $formatted=execute($text,'format');ok($formatted->{success},'source formats as terse');
            my $terse=execute($formatted->{formatted_source});ok($terse->{success},'terse source checks');
            is($terse->{capability_evidence}{semantic_projection_sha256},$checked->{capability_evidence}{semantic_projection_sha256},'style preserves repaired meaning');
            parity($text,{},$checked);
        }
    }
};

subtest 'imported service condition scope and target-neutral planning remain exact' => sub {
    my $text=authored('(reset_inactive bus)',0);my $library=$text;$library =~ s/package \Q$package\E/package library/;
    $text =~ s/\(imports\)/(imports (import lib "library.vial"))/;
    my $catalog={'library.vial'=>$library};my $checked=execute($text,'check',$catalog);
    ok($checked->{success},'imported service start requirements check') or do {diag explain $checked->{diagnostics};return};
    my $detail=FSM::VIAL::SourceInspection->build(parse($text,$catalog));
    my ($s)=grep {$_->{node_kind} eq 'service'} @{$detail->{packages}[1]{intent_families}[0]{nodes}};
    is($s->{payload}{detail}{start_condition}{operands}[-1]{domain_id},'library::fixture::base_output_arbitration::domain::bus','imported reset condition retains its own domain');
    parity($text,$catalog,$checked);
    my $planned=execute(authored('(reset_inactive bus)',0),'plan');
    ok($planned->{success},'actual public target-neutral planning succeeds') or do {diag explain $planned->{diagnostics};return};
    my ($record)=grep {$_->{semantic}{node_kind} eq 'service'} @{$planned->{plan}{semantic_families}};
    is_deeply($record->{semantic}{payload}{detail}{start_condition}{operands}[-1],condition('reset_inactive',undef,$domain),'plan preserves the added condition without reinterpretation');
    ok(@{$planned->{artifacts}},'planning returns virtual artifacts');
    ok(!defined $planned->{run},'planning performs no backend run');
};

subtest 'unknown, cyclic and excessive start conditions still fail source admission' => sub {
    for my $case (
        ['(reset_inactive missing)','VIAL_SEMANTIC_ERROR'],
        ['(service_ready background)','VIAL_SEMANTIC_ERROR'],
        ['(uvm_build_complete)','VIAL_PARSE_ERROR'],
        ['(all)','VIAL_PARSE_ERROR'],
        ['(all '.join(' ',('(configured)') x 65).')','VIAL_LIMIT_ERROR'],
    ) {
        my $r=execute(authored($case->[0],0));ok(!$r->{success},'invalid start condition rejected');
        is($r->{diagnostics}[0]{code},$case->[1],'specific diagnostic retained');
        ok(!defined $r->{semantic_report},'failure publishes no partial semantic report');
        is_deeply($r->{artifacts},[],'failure publishes no artifacts');
    }
};
done_testing();
sub read_file {open my $fh,'<:raw',$_[0] or die $!;local $/;my $s=<$fh>;close $fh or die $!;return $s}
sub write_file {open my $fh,'>:raw',$_[0] or die $!;print {$fh} $_[1] or die $!;close $fh or die $!}
