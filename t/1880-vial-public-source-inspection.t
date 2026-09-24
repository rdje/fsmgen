#!/usr/bin/env perl
use strict;
use warnings;
use Cwd qw(abs_path);
use Digest::SHA qw(sha256_hex);
use File::Find;
use FindBin;
use JSON::PP ();
use Test::More;
use lib "$FindBin::Bin/../perl";
use FSM::ProjectDataLocality qw(create_project_tempdir);
use FSM::Support::VIALToolingContract qw(build_vial_tooling_contract);
use FSM::VIAL::SourceInspection;
use FSM::VIAL::Tool qw(execute_vial_tool_request check_vial_source_file);
use FSM::VIAL::ToolCLI;

my $portable=FSM::VIAL::Tool->can('inspect_vial_source');
my $filesystem=FSM::VIAL::Tool->can('inspect_vial_source_file');
ok($portable,'portable source inspection API exists');
ok($filesystem,'filesystem source inspection API exists');
if (!$portable || !$filesystem) { done_testing();exit 0 }
my $repo=abs_path("$FindBin::Bin/..");
my $workspace=create_project_tempdir(purpose=>'vial-public-source-inspection');
my $id='inspect.vial';
my $json=JSON::PP->new->canonical;
my %base=map {$_=>read_file("$repo/vial/ahb_subordinate_base_output_arbitration".($_==2?'_v2':'').'.vial')} (1,2);
my $lifecycle=read_file("$repo/vial/ahb_subordinate_base_output_arbitration_lifecycle_v2.vial");
my $start=$lifecycle;$start =~ s/\(target fixture_background\)/(target fixture_background) (start_requires (reset_inactive bus))/;
my $empty=$lifecycle;
$empty =~ s/\(services\s+\(service background\s+\(target fixture_background\)\)\)/(services)/;
$empty =~ s/\(dependencies\s+\(dependency configured_gate \(when \(configured\)\)\)\s+\(dependency reset_gate \(when \(reset_inactive bus\)\)\)\)/(dependencies)/;

sub native {
    my ($version,$text,$catalog,$style)=@_;
    return execute_vial_tool_request({schema=>"fsmgen.vial_tool_request.v$version",schema_version=>$version,action=>'check',
        vial_source=>{source_id=>$id,source_kind_hint=>'vial',text=>$text,encoding=>'utf-8',origin=>'repository',
            display_name=>$id,canonical_id=>undef,relative_path=>$id,metadata=>{}},hial_source=>undef,
        options=>{source_style=>$style//'auto',output_style=>undef,fixture_id=>undef,scenario_ids=>[],
            execution_profile=>undef,backend_profile=>undef,replay_manifest=>undef,native_extension_catalogs=>[],
            artifact_policy=>undef,quiet=>JSON::PP::false}}, {source_catalog=>$catalog//{},artifact_sink=>[]});
}
sub invoke {
    my ($api,@args)=@_;my ($out,$err,$r)=('','');
    {open my $stdout,'>',\$out or die $!;open my $stderr,'>',\$err or die $!;
     local *STDOUT=$stdout;local *STDERR=$stderr;$r=$api->(@args)}
    is($out,'','API does not print stdout');is($err,'','API does not print stderr');return $r;
}
sub args { +{source_id=>$id,text=>$_[1],language_version=>$_[0],source_catalog=>$_[2]//{},source_style=>$_[3]//'auto'} }
sub snapshot {
    my %files;find({no_chdir=>1,wanted=>sub {
        return unless -f $_ && !-l $_;
        $files{substr($_,length($workspace)+1)}=sha256_hex(read_file($_));
    }},$workspace);return \%files;
}
sub failure_shape {
    my ($r)=@_;ok(!$r->{success},'inspection fails');ok(!defined $r->{inspection},'no partial inspection');
    ok(@{$r->{diagnostics}},'failure has diagnostics');
    is_deeply($r->{check_result}{artifacts},[],'failed check publishes no artifact');
}

subtest 'public typed detail covers both versions and current lifecycle features' => sub {
    ok(grep({$_ eq 'inspect_vial_source'} @FSM::VIAL::Tool::EXPORT_OK),'portable function exportable');
    ok(grep({$_ eq 'inspect_vial_source_file'} @FSM::VIAL::Tool::EXPORT_OK),'filesystem function exportable');
    for my $case ([1,$base{1}],[2,$base{2}],[2,$lifecycle],[2,$start],[2,$empty],[1,"; caf\xc3\xa9\n".$base{1}]) {
        my ($version,$text)=@$case;my $input=args($version,$text);my $before=$json->encode($input);
        my $checked=native($version,$text);ok($checked->{success},'native source checks');
        my $r=invoke($portable,$input);ok($r->{success},'portable inspection succeeds');
        is_deeply([sort keys %$r],[sort qw(schema schema_version success check_result inspection diagnostics)],'closed independent result envelope');
        is($r->{schema},'fsmgen.vial_source_inspection.v1','public inspection result schema independent of language');
        is($r->{schema_version},1,'inspection schema version');ok(JSON::PP::is_bool($r->{success}),'success is JSON boolean');
        is_deeply($r->{check_result},$checked,'complete native check report preserved');
        is_deeply($r->{diagnostics},[],'success has no diagnostics');
        is($r->{inspection}{root_source}{content_sha256},sha256_hex($text),'detail names the captured root bytes');
        is($r->{inspection}{language_version},$version,'explicit language version retained');
        is($r->{inspection}{packages}[0]{fixtures}[0]{scenarios}[0]{actions}[0]{kind},'reset','base action bodies available through public API');
        if ($text =~ /\(family lifecycle_control/) {
            my @nodes=@{$r->{inspection}{packages}[0]{intent_families}[0]{nodes}};
            my ($deadline)=grep {$_->{node_kind} eq 'deadline'} @nodes;
            is($deadline->{payload}{detail}{max_cycles},1024,'authored full lifecycle deadline inspectable');
            my ($ready)=grep {$_->{node_kind} eq 'readiness'} @nodes;
            is($ready->{payload}{condition}{kind},'all','complete lifecycle condition exposed');
        }
        write_file("$workspace/$id",$text);my $files=snapshot();
        my $file=invoke($filesystem,{workspace_root=>$workspace,source_id=>$id,language_version=>$version});
        is_deeply($file,$r,'filesystem and portable complete inspection results agree');
        is_deeply(snapshot(),$files,'filesystem inspection creates or changes no files');
        is($json->encode($input),$before,'portable caller input unchanged');
        my $saved=$json->decode($json->encode($r));$r->{inspection}{packages}[0]{name}='mutated';
        is_deeply($portable->($input),$saved,'later calls return fresh deterministic values');
    }
    ok($portable->({source_id=>$id,text=>$base{1}})->{success},'omitted version/style/catalog use documented defaults');
};

subtest 'styles imports and native failure diagnostics retain exact identity' => sub {
    for my $version (1,2) {
        my $library=$base{$version};$library =~ s/package ahb_subordinate_base_output_arbitration/package library/;
        my $text=$base{$version};$text =~ s/\(imports\)/(imports (import lib "library.vial"))/;
        my $catalog={'library.vial'=>$library};my $input=args($version,$text,$catalog);
        my $r=$portable->($input);ok($r->{success},'imported source inspects');
        is($r->{inspection}{packages}[1]{name},'library','imported declaration bodies retained');
        write_file("$workspace/$id",$text);write_file("$workspace/library.vial",$library);
        is_deeply($filesystem->({workspace_root=>$workspace,source_id=>$id,language_version=>$version}),$r,'complete imported file/memory result equality');
        my $terse=FSM::VIAL::SourceProjection->format_source({text=>$text,source_name=>$id,output_style=>'terse'})->{text};
        my $formatted=$portable->(args($version,$terse,$catalog,'terse'));ok($formatted->{success},'explicit terse style inspects');
        is($formatted->{check_result}{capability_evidence}{semantic_projection_sha256},$r->{check_result}{capability_evidence}{semantic_projection_sha256},'style preserves exact native meaning identity');
        for my $case (['(vial',{},'auto'],[$text,{},'auto'],[$text,$catalog,'terse'],[$base{$version==1?2:1},{},'auto']) {
            my ($bad,$imports,$style)=@$case;my $expected=native($version,$bad,$imports,$style);
            my $failed=invoke($portable,args($version,$bad,$imports,$style));failure_shape($failed);
            is_deeply($failed->{check_result},$expected,'complete native failure report preserved');
            is_deeply($failed->{diagnostics},$expected->{diagnostics},'ordered native diagnostics preserved');
        }
    }
};

subtest 'closed invocations and bounded filesystem admission fail without detail' => sub {
    my @invalid=([],[undef],[[]],[bless({},'InspectionForeign')],
        [{text=>$base{1}}],[{source_id=>$id}], [{source_id=>$id,text=>[]}],
        [{source_id=>$id,text=>$base{1},language_version=>3}], [{source_id=>$id,text=>$base{1},source_style=>undef}],
        [{source_id=>$id,text=>$base{1},source_catalog=>[]}], [{source_id=>$id,text=>$base{1},backend_profile=>'sv'}],
        [{source_id=>$id,text=>$base{1}},{}], [{source_id=>'../outside.vial',text=>$base{1}}]);
    for my $call (@invalid) {my $r=invoke($portable,@$call);failure_shape($r);is($r->{diagnostics}[0]{code},'VIAL_TOOL_INVOCATION_ERROR','closed portable invocation rejected specifically')}
    write_file("$workspace/$id",$base{1});symlink($id,"$workspace/link.vial") or die $!;
    for my $call ([],[undef],[{workspace_root=>$workspace,source_id=>$id,text=>$base{1}}],
        [{workspace_root=>$workspace,source_id=>'missing.vial'}],[{workspace_root=>$workspace,source_id=>'link.vial'}],
        [{workspace_root=>$workspace,source_id=>'../outside.vial'}],
        [{workspace_root=>$workspace,source_id=>$id,language_version=>2,source_style=>undef}]) {
        my $native=check_vial_source_file(@$call);my $r=invoke($filesystem,@$call);failure_shape($r);
        is_deeply($r->{check_result},$native,'filesystem refusal preserves exact established check report');
    }
    my $oversize=' ' x (build_vial_tooling_contract()->{limits}{source_bytes}+1);
    my $r=$portable->(args(1,$oversize));failure_shape($r);is_deeply($r->{check_result},native(1,$oversize),'portable byte limit preserves native refusal');
    write_file("$workspace/oversize.vial",$oversize);
    $r=$filesystem->({workspace_root=>$workspace,source_id=>'oversize.vial'});failure_shape($r);
    is($r->{diagnostics}[0]{code},'VIAL_LIMIT_ERROR','filesystem byte admission remains bounded');
};

subtest 'captured bytes are not reopened or borrowed from mutable caller data' => sub {
    my $text=$base{1};$text =~ s/\(imports\)/(imports (import lib "library.vial"))/;
    my $library=$base{1};$library =~ s/package ahb_subordinate_base_output_arbitration/package library/;
    write_file("$workspace/$id",$text);write_file("$workspace/library.vial",$library);
    my ($checks,%reads);my $read=\&FSM::VIAL::ToolCLI::_read_repo_source;my $execute=\&FSM::VIAL::Tool::execute_vial_tool_request;
    my $r;
    {no warnings qw(redefine once);
     local *FSM::VIAL::ToolCLI::_read_repo_source=sub {$reads{$_[1]}++;$read->(@_)};
     local *FSM::VIAL::Tool::execute_vial_tool_request=sub {my $c=$execute->(@_);$checks++;write_file("$workspace/$id",'changed after check');write_file("$workspace/library.vial",'changed import after check');return $c};
     $r=$filesystem->({workspace_root=>$workspace,source_id=>$id});}
    is($checks,1,'one native public check precedes detail');is_deeply(\%reads,{$id=>1,'library.vial'=>1},'each source captured once');
    ok($r->{success},'inspection uses validated captured bytes after files change');
    is($r->{inspection}{root_source}{content_sha256},sha256_hex($text),'original root identity retained');
    is($r->{inspection}{sources}[1]{content_sha256},sha256_hex($library),'original import identity retained');
    my $input=args(1,$text,{'library.vial'=>$library});
    {no warnings qw(redefine once);
     local *FSM::VIAL::Tool::execute_vial_tool_request=sub {my $c=$execute->(@_);$input->{text}='changed';$input->{source_catalog}{'library.vial'}='changed';return $c};
     $r=$portable->($input);}
    ok($r->{success},'portable inspection owns captured caller bytes');
    is($r->{inspection}{sources}[1]{content_sha256},sha256_hex($library),'caller catalog mutation cannot alter checked detail');
};

subtest 'inspection has no execution effects and projection faults are sanitized' => sub {
    {no warnings qw(redefine once);
     local *FSM::VIAL::ToolCLI::_read_repo_source=sub {die 'unexpected filesystem access'};
     local *FSM::VIAL::Tool::_execute_plan_action=sub {die 'unexpected v1 planning'};
     local *FSM::VIAL::Tool::_execute_plan_action_v2=sub {die 'unexpected v2 planning'};
     local *FSM::VIAL::ArtifactTransaction::publish=sub {die 'unexpected publication'};
     ok($portable->(args(1,$base{1}))->{success},'v1 portable inspection needs no filesystem/planning/publication');
     ok($portable->(args(2,$lifecycle))->{success},'v2 lifecycle inspection needs no filesystem/planning/publication');}
    for my $version (1,2) {
        my $checked=native($version,$base{$version});my $r;
        {no warnings qw(redefine once);local *FSM::VIAL::SourceInspection::build=sub {die 'secret compiler path /private/internal/source.pm'};
         $r=invoke($portable,args($version,$base{$version}));}
        failure_shape($r);is_deeply($r->{check_result},$checked,'projection failure preserves successful native check');
        is($r->{diagnostics}[0]{code},'VIAL_SOURCE_INSPECTION_ERROR','separate projection diagnostic');
        unlike($json->encode($r),qr/secret compiler|private\/internal/,'private exception never leaks');
    }
};
done_testing();
sub read_file {open my $fh,'<:raw',$_[0] or die $!;local $/;my $s=<$fh>;close $fh or die $!;return $s}
sub write_file {open my $fh,'>:raw',$_[0] or die $!;print {$fh} $_[1] or die $!;close $fh or die $!}
