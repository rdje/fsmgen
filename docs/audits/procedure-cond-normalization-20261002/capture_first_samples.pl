use strict;
use warnings;
use lib 'perl', 't/lib';
use JSON::PP;
use Cwd qw(abs_path);
use Digest::SHA qw(sha256_hex);
use FSM::Test::SourceQueryRunner qw(normalize_repository_paths);
use FSM::Support::SemanticIntrospectionMCPAdapter;
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
my $j=JSON::PP->new->canonical;
my $root=abs_path('.');
my $path='docs/audits/procedure-cond-normalization-20261002/sources/first_samples.isf';
sub read_file {open my $f,'<:raw',$_[0] or die $!; local $/;return <$f>}
my $source=read_file($path);
my $actor=FSM::Adapter::ISF->new->parse_file($path);
my $loaded_parser=$INC{'FSM/Adapter/ISF/Parser.pm'};
my $parser_before=sha256_hex(read_file($loaded_parser));
my $before=$j->encode($actor);
my ($ir,$lowered,$private_error,$lower_error);
eval {$ir=FSM::Scheduler::ISF->new->{ir}->build_module($actor);1} or $private_error=$@;
eval {$lowered=FSM::Scheduler::ISF->new->lower($actor);1} or $lower_error=$@;
die 'caller mutation' unless $before eq $j->encode($actor);
my $adapter=FSM::Support::SemanticIntrospectionMCPAdapter->new(repo_root=>$root,workspace_root=>$root);
my %flags=(check=>[qw(--strict --check --json)],semantic=>[qw(--strict --emit-semantic-json)],schedule=>['--emit-schedule-json']);
my %tools=(check=>'fsmgen_check',semantic=>'fsmgen_semantic_introspect',schedule=>'fsmgen_schedule_preview');
my %queries;
for my $kind (qw(check semantic schedule)) {
    my $producer_before=FSM::Test::SourceQueryRunner::_producers($root);
    my $native=FSM::Test::SourceQueryRunner::_capture([$^X,'bin/fsmgen',@{$flags{$kind}},$path],'');
    my $report=eval {$j->decode($native->{stdout})};
    my $request={jsonrpc=>'2.0',id=>1,method=>'tools/call',params=>{name=>$tools{$kind},arguments=>{source_id=>$path}}};
    my $api=$adapter->handle_jsonrpc_request($request);
    my $stdio=FSM::Test::SourceQueryRunner::_capture([$^X,'bin/fsmgen-mcp','--workspace-root','.'],$j->encode($request)."\n");
    my $wire=eval {$j->decode($stdio->{stdout})};
    $queries{$kind}={native=>$native,native_report=>$report,api=>$api,stdio=>$stdio,stdio_response=>$wire,
        producer_before=>$producer_before,producer_after=>FSM::Test::SourceQueryRunner::_producers($root)};
}
die 'source mutation' unless $source eq read_file($path);
my $parser_after=sha256_hex(read_file($loaded_parser));
die 'loaded parser bytes changed' unless $parser_before eq $parser_after;
print $j->encode(normalize_repository_paths({source=>$source,actor=>$j->decode($before),private_ir=>$ir,
    private_error=>$private_error,lowered=>$lowered,lower_error=>$lower_error,queries=>\%queries,
    parser_mode=>$ARGV[0]//'live parser',source_sha256=>sha256_hex($source),
    loaded_parser=>$loaded_parser,loaded_parser_sha256=>$parser_after,
    loaded_parser_before_sha256=>$parser_before,
},$root)),"\n";
