use strict;
use warnings;
use lib 'perl', 't/lib';
use JSON::PP;
use Cwd qw(abs_path);
use FSM::Test::SourceQueryRunner qw(normalize_repository_paths);
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Support::SemanticIntrospectionMCPAdapter;
my $root=abs_path('.');
my $json=JSON::PP->new->canonical;
my $source='docs/audits/first-when-activation-body-20261002/drafts/first-select.isf';
my $api=FSM::Support::SemanticIntrospectionMCPAdapter->new(repo_root=>$root,workspace_root=>$root);
my %flags=(check=>[qw(--strict --check --json)],semantic=>[qw(--strict --emit-semantic-json)],schedule=>['--emit-schedule-json']);
my %tool=(check=>'fsmgen_check',semantic=>'fsmgen_semantic_introspect',schedule=>'fsmgen_schedule_preview');
my %out;
for my $kind (qw(check semantic schedule)) {
 my $argv=[$^X,'bin/fsmgen',@{$flags{$kind}},$source];
 my $native=FSM::Test::SourceQueryRunner::_capture($argv,'');
 my $req={jsonrpc=>'2.0',id=>1,method=>'tools/call',params=>{name=>$tool{$kind},arguments=>{source_id=>$source}}};
 my $response=$api->handle_jsonrpc_request($req);
 my $wireargv=[$^X,'bin/fsmgen-mcp','--workspace-root','.'];
 my $wire=FSM::Test::SourceQueryRunner::_capture($wireargv,$json->encode($req)."\n");
 $out{$kind}={argv=>$argv,native=>$native,request=>$req,api=>$response,wire_argv=>$wireargv,wire=>$wire};
}
print $json->encode(normalize_repository_paths(\%out,$root)),"\n";
