use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use JSON::PP;
use Storable qw(dclone);
use Cwd qw(abs_path);
use Digest::SHA qw(sha256_hex);
use File::Temp qw(tempdir);
use FSM::Test::ProjectDataLocality;
use FSM::Test::SourceQueryRunner qw(normalize_repository_paths);
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Scheduler::ISF::DomainSource qw(_domain_actor_for_scheduled_artifact);
use FSM::Support::SemanticIntrospectionMCPAdapter;

my $parser=FSM::Adapter::ISF->new;
my $scheduler=FSM::Scheduler::ISF->new;
my $root=abs_path('.');
my $api=FSM::Support::SemanticIntrospectionMCPAdapter->new(repo_root=>$root,workspace_root=>$root);
my $work=tempdir(CLEANUP=>1);
my $json=JSON::PP->new->canonical;
my $header=<<'ISF';
(actor domain_drives
 (clock-domains (domain core (clock clk) :default) (domain aux (clock aux_clk)))
 (interface (input start) (input data (width 8)) (output seen (width 8)) (output done)
  (input aux_start (domain aux)) (input aux_data (width 12) (domain aux))
  (output aux_seen (width 12) (domain aux)) (output aux_done (domain aux)))
 (drive (publish value) (seen value))
 (drive (aux_publish value) (aux_seen value))
ISF
sub read_file { open my $f,'<:raw',$_[0] or die $!;local $/;return <$f>; }
sub write_file {
    open my $f,'>',$_[0] or die $!;print {$f} $_[1];close $f or die $!;
}
sub replay_files {
    my ($files,$dir)=@_;
    write_file("$dir/$_",$files->{$_}) for sort keys %$files;
    for my $name (sort keys %$files) {
        open my $cli,'-|','./bin/fsmgen','--quiet','--strict','--check','--json',"$dir/$name" or die $!;
        my $text=do {local $/;<$cli>};close $cli;
        my $exit=$? >> 8;
        diag($text) if $exit;
        is($exit,0,"actual $name strictly replays");
        ok($json->decode($text)->{success},"$name reports complete strict success");
    }
}
sub qualify {
    my ($label,$body,$expected)=@_;
    my $source=$header.$body.')';
    my $actor=$parser->parse_source($source,'domain-drives.isf');
    my $before=$json->encode($actor);
    my $prepared=$scheduler->{ir}->prepare_formal_source($actor);
    my $partition=$prepared->{domain_partition};
    for my $domain (@{$partition->{domains}}) {
        my $name=$domain->{name};
        my $actual=_domain_actor_for_scheduled_artifact($actor,$domain,'core');
        is_deeply([sort keys %{$actual->{drives}}],$expected->{$name},"$name contains exactly its independently selected drive bodies");
        is_deeply($prepared->{domain_source_products}{$name}{preparation}{actor}{drives},$actual->{drives},
            "$name actual and formal preparation use complete equal definitions");
    }
    my $result=$scheduler->lower($actor);
    is($json->encode($actor),$before,'complete caller JSON remains unchanged');
    my $dir="$work/$label";mkdir $dir or die $!;
    replay_files($result->{files},$dir);
    for my $domain (qw(core aux)) {
        my $text=$result->{files}{"domain_drives__domain_$domain.fsm"};
        for my $drive (qw(publish aux_publish)) {
            my $wanted=grep {$_ eq $drive} @{$expected->{$domain}};
            if (!$wanted) {
                unlike($text,qr/\b\Q$drive\E(?:_start|_value)\b/,"unused $drive creates no $domain request/payload declarations or references");
            }
        }
    }
    return ($source,$actor,$dir);
}

subtest 'unused parameterized drives cannot invent domain or top inputs' => sub {
    my ($source,$actor,$dir)=qualify('unused','(transaction main (on start) (set seen data) (complete done))',
        {core=>[],aux=>[]});
    write_file("$dir/source.isf",$source);
    my $relative="$dir/source.isf";$relative =~ s/\A\Q$root\E\///;
    for my $kind (qw(check semantic schedule)) {
        my %flags=(check=>[qw(--strict --check --json)],semantic=>[qw(--strict --emit-semantic-json)],schedule=>['--emit-schedule-json']);
        my %tools=(check=>'fsmgen_check',semantic=>'fsmgen_semantic_introspect',schedule=>'fsmgen_schedule_preview');
        my $before=sha256_hex(read_file("$dir/source.isf"));
        my $r=FSM::Test::SourceQueryRunner::_capture([$^X,'bin/fsmgen',@{$flags{$kind}},$relative],'');
        my $native=normalize_repository_paths($json->decode($r->{stdout}),$root);
        my $request={jsonrpc=>'2.0',id=>1,method=>'tools/call',params=>{name=>$tools{$kind},arguments=>{source_id=>$relative}}};
        my $response=$api->handle_jsonrpc_request($request);
        ok(!$response->{error},"$kind returns complete API tool result");
        my $tool=normalize_repository_paths($response->{result},$root);
        my $wire=FSM::Test::SourceQueryRunner::_capture([$^X,'bin/fsmgen-mcp','--workspace-root','.'],$json->encode($request)."\n");
        is($r->{exit_code},0,"$kind actual authored source succeeds natively");
        is($r->{stderr},'',"$kind native machine-report stderr is clean");
        is_deeply($tool->{structuredContent}{report},$native,"$kind complete native/API products agree");
        is($wire->{exit_code},0,"$kind actual newline transport succeeds");
        is($wire->{stderr},'',"$kind newline stderr is clean");
        like($wire->{stdout},qr/\A[^\n]+\n\z/,"$kind returns exactly one actual newline response");
        is_deeply(normalize_repository_paths($json->decode($wire->{stdout}),$root),
            normalize_repository_paths($response,$root),"$kind complete actual newline/API response agrees");
        is_deeply($json->decode($tool->{content}[0]{text}),$tool->{structuredContent},"$kind complete text/structured products agree");
        ok(!$tool->{isError},"$kind returns successful tool result");
        is(sha256_hex(read_file("$dir/source.isf")),$before,"$kind transports preserve exact source bytes");
    }
};

subtest 'used nested drives retain only their actual activation domains' => sub {
    qualify('nested','(transaction main (on start) (when data (repeat 2 (drive publish data))) (complete done))'
        . ' (transaction other (domain aux) (on aux_start) (drive aux_publish aux_data) (complete aux_done))',
        {core=>['publish'],aux=>['aux_publish']});
};

subtest 'generated child drive calls retain their parent-domain shared body' => sub {
    qualify('generated','(transaction worker (drive publish data) (complete done))'
        . ' (transaction main (on start) (spawn worker as job) (await_all done) (complete done))',
        {core=>['publish'],aux=>[]});
};

subtest 'selected domain definitions are detached and malformed selection refuses' => sub {
    my $actor=$parser->parse_source($header.'(transaction main (on start) (drive publish data) (complete done)))','selection-boundary.isf');
    my $partition=$scheduler->{ir}->prepare_formal_source($actor)->{domain_partition};
    my ($domain)=grep {$_->{name} eq 'core'} @{$partition->{domains}};
    my $before=$json->encode($actor);
    my $actual=_domain_actor_for_scheduled_artifact($actor,$domain,'core');
    $actual->{drives}{publish}{body}[0][1]='changed';
    is($json->encode($actor),$before,'selected drive body mutation cannot reach caller declarations');
    for my $selection (undef,{},['unknown'],['publish','publish'],[{}]) {
        my $bad=dclone($domain);$bad->{drive_names}=$selection;
        my $snapshot=$json->encode($bad);
        my $ok=eval {_domain_actor_for_scheduled_artifact($actor,$bad,'core');1};
        my ($line)=split /\n/,$@;
        ok(!$ok,'malformed missing unknown or duplicate selection refuses');
        like($line // '',qr/ISF domain source (?:requires selected drive names|has an invalid selected drive)/,
            'first diagnostic locates the closed selection boundary');
        is($json->encode($bad),$snapshot,'refused selection stays unchanged');
        is($json->encode($actor),$before,'refused selection preserves all caller facts');
    }
};

done_testing;
