#!/usr/bin/env perl
use strict;
use warnings;
use Cwd qw(abs_path);
use Digest::SHA qw(sha256_hex);
use File::Find;
use FindBin;
use IPC::Cmd ();
use IPC::Open3 qw(open3);
use JSON::PP ();
use Test::More;
use Symbol qw(gensym);
use lib "$FindBin::Bin/../perl";
use FSM::ProjectDataLocality qw(create_project_tempdir);
use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::SemanticIntrospectionMCPAdapter;
use FSM::VIAL::SourceProjection;
use FSM::VIAL::Tool qw(inspect_vial_source_file vial_source_inspection_capabilities);

my $repo=abs_path("$FindBin::Bin/..");
my $workspace=create_project_tempdir(purpose=>'mcp-vial-inspection');
my $json=JSON::PP->new->canonical;
my $runner_calls=0;
sub adapter {FSM::Support::SemanticIntrospectionMCPAdapter->new(repo_root=>$repo,workspace_root=>$_[0],runner=>sub {++$runner_calls;die 'inspection must not use hardware runner'})}
my $native=adapter($repo);my $local=adapter($workspace);
my ($descriptor)=grep {$_->{name} eq 'fsmgen_vial_inspect'} @{$native->list_tools()->{tools}};
ok($descriptor,'dedicated VIAL inspection tool is discoverable');
my $initial=rpc($native,'tools/call',{name=>'fsmgen_vial_inspect',arguments=>{source_id=>'vial/ahb_subordinate_base_output_arbitration.vial'}});
ok(!$initial->{error},'dedicated VIAL inspection tool is callable');
if (!$descriptor || $initial->{error}) {done_testing();exit 0}
my %base=map {$_=>read_file("$repo/vial/ahb_subordinate_base_output_arbitration".($_==2?'_v2':'').'.vial')} (1,2);
my $lifecycle=read_file("$repo/vial/ahb_subordinate_base_output_arbitration_lifecycle_v2.vial");
sub rpc {$_[0]->handle_jsonrpc_request({jsonrpc=>'2.0',id=>1,method=>$_[1],params=>$_[2]})}
sub queried {
    my ($adapter,$args,$expected)=@_;
    my $response=rpc($adapter,'tools/call',{name=>'fsmgen_vial_inspect',arguments=>$args});
    ok(!$response->{error},'inspection returns MCP tool result') or return;
    my $result=$response->{result};my $payload=$result->{structuredContent};
    is_deeply($json->decode($result->{content}[0]{text}),$payload,'text and structured content agree completely');
    is_deeply($payload->{report},$expected,'complete native inspection result is preserved');
    is($payload->{query_kind},'inspection','query kind identifies deep inspection');
    is($result->{isError}?1:0,$expected->{success}?0:1,'isError follows outer inspection success');
    is($payload->{adapter_provenance}{api_entrypoint},'FSM::VIAL::Tool::inspect_vial_source_file','provenance names clean public API');
    ok(!defined $payload->{adapter_provenance}{command_shape},'no invented subprocess command');
    unlike($json->encode($payload),qr/\Q$repo\E|\Q$workspace\E/,'no machine-local root leaks');
    return $payload;
}
sub snapshot {
    my %files;find({no_chdir=>1,wanted=>sub {return unless -f $_ && !-l $_;$files{substr($_,length($workspace)+1)}=sha256_hex(read_file($_));}},$workspace);return \%files;
}

subtest 'tool resource and capability discovery state the exact public boundary' => sub {
    is_deeply([sort keys %{$descriptor->{inputSchema}{properties}}],[qw(language_version source_id source_style)],'closed selected arguments');
    is_deeply($descriptor->{inputSchema}{required},['source_id'],'explicit source identity required');
    ok(!$descriptor->{inputSchema}{additionalProperties},'unknown keys not advertised');
    is_deeply($descriptor->{inputSchema}{properties}{language_version}{enum},[1,2],'explicit versions advertised');
    is_deeply($descriptor->{inputSchema}{properties}{source_style}{enum},[qw(auto normal terse)],'exact style selectors advertised');
    ok($descriptor->{annotations}{readOnlyHint} && !$descriptor->{annotations}{openWorldHint},'tool remains read-only and closed-world');
    is($descriptor->{outputSchema}{properties}{report}{properties}{schema}{const},'fsmgen.vial_source_inspection.v1','output schema names independent result');
    ok(!$descriptor->{outputSchema}{properties}{report}{additionalProperties},'inspection wrapper output schema is closed');
    my $uri='fsmgen://vial/{language_version}/source/{source_id}/inspection';
    ok(grep({$_->{uriTemplate} eq $uri} @{$native->list_resource_templates()->{resourceTemplates}}),'explicit versioned inspection resource advertised');
    my $manifest=build_capability_manifest()->{semantic_introspection};
    ok(grep({$_ eq 'fsmgen_vial_inspect'} @{$manifest->{mcp_tool_names}}),'manifest tool inventory agrees');
    ok(grep({$_ eq $uri} @{$manifest->{mcp_resource_uri_templates}}),'manifest resource inventory agrees');
    ok(grep({$_ eq 'vial_inspect'} @{$manifest->{query_family_names}}),'manifest query-family inventory agrees');
    ok(grep({$_ eq 'vial_source_inspection'} @{$manifest->{query_domain_names}}),'manifest query-domain inventory agrees');
    is_deeply($manifest->{source_query_kinds}{vial},[qw(check semantic inspection)],'VIAL discovery includes deep inspection but no schedule');
    my $r=rpc($native,'tools/call',{name=>'fsmgen_capability_query',arguments=>{section=>'vial_inspection'}});
    ok(!$r->{error},'inspection capabilities query succeeds');
    is_deeply($r->{result}{structuredContent}{payload},vial_source_inspection_capabilities(),'complete independent capabilities preserved');
};

subtest 'actual native and MCP source results retain authored base and lifecycle detail' => sub {
    for my $case ([1,'vial/ahb_subordinate_base_output_arbitration.vial'],[2,'vial/ahb_subordinate_base_output_arbitration_v2.vial'],[2,'vial/ahb_subordinate_base_output_arbitration_lifecycle_v2.vial']) {
        my ($version,$id)=@$case;
        my ($ok,$error,$all,$out,$err)=IPC::Cmd::run(command=>[$^X,"$repo/bin/fsmgen",'vial','inspect','--json','--language-version',$version,$id]);
        ok($ok,'actual native inspection succeeds');is(join('',@{$err||[]}), '','native stderr empty');
        my $expected=$json->decode(join('',@{$out||[]}));
        my $p=queried($native,{source_id=>$id,language_version=>$version},$expected);
        is($p->{report}{inspection}{packages}[0]{fixtures}[0]{scenarios}[0]{actions}[0]{kind},'reset','authored action body is inspectable through MCP');
        if ($id =~ /lifecycle/) {
            my @nodes=@{$p->{report}{inspection}{packages}[0]{intent_families}[0]{nodes}};
            my ($deadline)=grep {$_->{node_kind} eq 'deadline'} @nodes;
            is($deadline->{payload}{detail}{max_cycles},1024,'authored deadline preserved');
            ok($deadline->{payload}{detail}{last_cycle_inclusive},'inclusive deadline preserved');
            my ($service)=grep {$_->{node_kind} eq 'service'} @nodes;
            is($service->{payload}{detail}{cancellation},'cooperative','service policy preserved');
            my ($failure)=grep {$_->{node_kind} eq 'failure'} @nodes;
            is($failure->{payload}{detail}{cleanup},'finalize','failure cleanup preserved');
        }
        my $encoded=$id;$encoded =~ s{/}{%2F}g;
        for my $path ($id,$encoded) {
            my $r=rpc($native,'resources/read',{uri=>"fsmgen://vial/$version/source/$path/inspection"});
            ok(!$r->{error},'versioned inspection resource succeeds');
            is_deeply($json->decode($r->{result}{contents}[0]{text}),$p,'complete resource and tool envelopes agree');
        }
        my $request=$json->encode({jsonrpc=>'2.0',id=>1,method=>'tools/call',params=>{name=>'fsmgen_vial_inspect',arguments=>{source_id=>$id,language_version=>$version}}});
        ($ok,$error,$all,$out,$err)=IPC::Cmd::run(command=>[$^X,"$repo/bin/fsmgen-mcp",'--workspace-root','.','--request-json',$request]);
        ok($ok,'actual MCP JSON-RPC process succeeds');
        is_deeply($json->decode(join('',@{$out||[]}))->{result}{structuredContent},$p,'actual MCP process preserves complete envelope');
        if ($id =~ /lifecycle/) {
            my $stderr=gensym;
            my $pid=open3(my $stdin,my $stdout,$stderr,$^X,"$repo/bin/fsmgen-mcp",'--workspace-root',$repo);
            print {$stdin} $request,"\n" or die $!;close $stdin or die $!;
            local $/;my $output=<$stdout>//'';my $errors=<$stderr>//'';
            close $stdout;close $stderr;waitpid($pid,0);
            is($? >> 8,0,'actual newline stdio inspection exits cleanly');is($errors,'','stdio stderr empty');
            is_deeply($json->decode($output)->{result}{structuredContent},$p,'newline MCP transport preserves complete lifecycle inspection');
        }
    }
};

subtest 'imports styles latest lifecycle clauses and refusal retain API identity' => sub {
    my $start=$lifecycle;$start =~ s/\(target fixture_background\)/(target fixture_background) (start_requires (reset_inactive bus))/;
    my $empty=$lifecycle;
    $empty =~ s/\(services\s+\(service background\s+\(target fixture_background\)\)\)/(services)/;
    $empty =~ s/\(dependencies\s+\(dependency configured_gate \(when \(configured\)\)\)\s+\(dependency reset_gate \(when \(reset_inactive bus\)\)\)\)/(dependencies)/;
    for my $case ([1,$base{1}],[2,$base{2}],[2,$start,'start'],[2,$empty,'empty']) {
        my ($version,$text,$feature)=@$case;my $library=$base{$version};$library =~ s/package ahb_subordinate_base_output_arbitration/package library/;
        $text =~ s/\(imports\)/(imports (import lib "part.vial"))/;
        write_file("$workspace/part.vial",$library);
        for my $style (qw(normal terse)) {
            my $text_view=FSM::VIAL::SourceProjection->format_source({text=>$text,source_name=>'root.vial',output_style=>$style})->{text};
            write_file("$workspace/root.vial",$text_view);my $before=snapshot();
            my $r=inspect_vial_source_file({workspace_root=>$workspace,source_id=>'root.vial',language_version=>$version,source_style=>$style});ok($r->{success},'public imported/style source succeeds');
            my $p=queried($local,{source_id=>'root.vial',language_version=>$version,source_style=>$style},$r);
            is($p->{report}{inspection}{packages}[1]{name},'library','imported declaration bodies retained');
            if (defined $feature) {
                my @nodes=@{$p->{report}{inspection}{packages}[0]{intent_families}[0]{nodes}};
                if ($feature eq 'start') {
                    my ($service)=grep {$_->{node_kind} eq 'service'} @nodes;
                    is($service->{payload}{detail}{start_condition}{operands}[-1]{kind},'reset_inactive','authored additional start condition reaches MCP');
                } else {
                    my ($ready)=grep {$_->{node_kind} eq 'readiness'} @nodes;
                    is_deeply($ready->{payload}{condition},{kind=>'all',reference_id=>undef,domain_id=>undef,operands=>[{kind=>'configured',reference_id=>undef,domain_id=>undef,operands=>[]}]},'empty readiness retains exact configured precondition through MCP');
                }
            }
            is_deeply(snapshot(),$before,'MCP query has no writes');
        }
    }
    write_file("$workspace/invalid.vial",'(');write_file("$workspace/oversize.vial",' ' x (vial_source_inspection_capabilities()->{loading_limits}{source_bytes}+1));
    symlink 'root.vial',"$workspace/linked.vial" or die $!;symlink $workspace,"$workspace/aliased" or die $!;
    for my $id (qw(invalid.vial oversize.vial missing.vial linked.vial aliased/root.vial ../outside.vial)) {
        my $r=inspect_vial_source_file({workspace_root=>$workspace,source_id=>$id,language_version=>2});ok(!$r->{success},'public source refuses specifically');
        my $p=queried($local,{source_id=>$id,language_version=>2},$r);
        my $resource=rpc($local,'resources/read',{uri=>"fsmgen://vial/2/source/$id/inspection"});
        is_deeply($json->decode($resource->{result}{contents}[0]{text}),$p,'resource preserves complete failed inspection');
    }
    my $id='vial/ahb_subordinate_base_output_arbitration_lifecycle_v2.vial';
    queried($native,{source_id=>$id},inspect_vial_source_file({workspace_root=>$repo,source_id=>$id}));
    write_file("$workspace/root.vial",$base{2});my $expected;
    {no warnings qw(redefine once);local *FSM::VIAL::SourceInspection::build=sub {die 'private compiler path'};
     $expected=inspect_vial_source_file({workspace_root=>$workspace,source_id=>'root.vial',language_version=>2});
     queried($local,{source_id=>'root.vial',language_version=>2},$expected);}
    ok($expected->{check_result}{success} && !$expected->{success},'projection failure flags outer failure even when native check passed');
};

subtest 'protocol parameters stay closed before source evaluation' => sub {
    for my $args ({},{source_id=>[]},{source_id=>'fsm/x.fsm'},{source_id=>'/absolute.vial'},
        {source_path=>'x.vial'},{source_id=>'x.vial',language_version=>3},{source_id=>'x.vial',language_version=>JSON::PP::true},
        {source_id=>'x.vial',source_style=>'invalid'},{source_id=>'x.vial',source_style=>undef},
        {source_id=>'x.vial',action=>'run'},{source_id=>'x.vial',workspace_root=>'.'}) {
        my $r=rpc($local,'tools/call',{name=>'fsmgen_vial_inspect',arguments=>$args});
        is($r->{error}{code},-32602,'malformed or inapplicable argument is invalid params');
    }
    for my $uri ('fsmgen://vial/3/source/root.vial/inspection','fsmgen://vial/2/source/x.fsm/inspection','fsmgen://vial/2/source/%2Fabsolute.vial/inspection') {
        my $r=rpc($local,'resources/read',{uri=>$uri});is($r->{error}{code},-32602,'resource validates version and relative VIAL identity');
    }
    is($runner_calls,0,'no inspection reaches hardware runner');
};
done_testing();
sub read_file {open my $fh,'<:raw',$_[0] or die $!;local $/;my $s=<$fh>;close $fh or die $!;return $s}
sub write_file {open my $fh,'>:raw',$_[0] or die $!;print {$fh} $_[1] or die $!;close $fh or die $!}
