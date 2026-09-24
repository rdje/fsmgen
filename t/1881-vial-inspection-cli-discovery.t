#!/usr/bin/env perl
use strict;
use warnings;
use Cwd qw(abs_path);
use Digest::SHA qw(sha256_hex);
use File::Find;
use File::Temp qw(tempdir);
use FindBin;
use IPC::Cmd ();
use JSON::PP ();
use Test::More;
use lib "$FindBin::Bin/../perl";
use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::VIALToolingContract;
use FSM::VIAL::Tool qw(inspect_vial_source_file vial_tool_capabilities vial_tool_capabilities_v2);
use FSM::VIAL::ToolCLI;

my $repo=abs_path("$FindBin::Bin/..");
my $json=JSON::PP->new->canonical;
my $cap=FSM::VIAL::Tool->can('vial_source_inspection_capabilities');
ok($cap,'independent inspection capability API exists');
my ($ok,$out,$err)=cli('vial','inspect','--json','vial/ahb_subordinate_base_output_arbitration.vial');
ok($ok,'native inspect command succeeds');
if (!$cap || !$ok) {done_testing();exit 0}
# Native source IDs reject a leading dot; keep temporary public CLI inputs in
# an explicit non-hidden repository-local directory, with automatic cleanup.
my $workspace=tempdir('vial-inspection-XXXXXXXX',DIR=>"$repo/t",CLEANUP=>1);
my $prefix=substr($workspace,length($repo)+1);
my %base=map {$_=>read_file("$repo/vial/ahb_subordinate_base_output_arbitration".($_==2?'_v2':'').'.vial')} (1,2);
my $lifecycle=read_file("$repo/vial/ahb_subordinate_base_output_arbitration_lifecycle_v2.vial");
sub cli {
    my ($ok,$error,$all,$stdout,$stderr)=IPC::Cmd::run(command=>[$^X,"$repo/bin/fsmgen",@_]);
    return ($ok,join('',@{$stdout||[]}),join('',@{$stderr||[]}));
}
sub adapter_cli {
    my (@argv)=@_;my ($out,$err,$status)=('','');
    {open my $stdout,'>',\$out or die $!;open my $stderr,'>',\$err or die $!;
     local *STDOUT=$stdout;local *STDERR=$stderr;
     $status=FSM::VIAL::ToolCLI->run({argv=>['inspect',@argv],repo_root=>$repo});}
    return ($status,$out,$err);
}
sub snapshot {
    my %files;find({no_chdir=>1,wanted=>sub {return unless -f $_ && !-l $_;
        $files{substr($_,length($workspace)+1)}=sha256_hex(read_file($_));}},$workspace);return \%files;
}

subtest 'separate discovery is closed, accurate and defensive' => sub {
    my $c=$cap->();
    is_deeply([sort keys %$c],[sort qw(schema schema_version status contract_source entrypoints invocations language_versions source_styles defaults result_schema detail_schema intent_node_schema semantic_groups intent_families loading_limits effects error_behavior)],'closed independent capability fields');
    is($c->{schema},'fsmgen.vial_source_inspection_contract.v1','independent contract identity');
    is_deeply($c->{language_versions},[1,2],'explicit supported versions');
    is_deeply($c->{source_styles},[qw(auto normal terse)],'exact style selectors');
    is_deeply($c->{defaults},{language_version=>1,source_style=>'auto',source_catalog=>{}},'API defaults explicit');
    is_deeply($c->{intent_families},{1=>[],2=>[{family_id=>'lifecycle_control',revision=>1}]},'only implemented family is advertised');
    is_deeply($c->{effects},{read_only=>JSON::PP::true,planning=>JSON::PP::false,random_evaluation=>JSON::PP::false,backend_execution=>JSON::PP::false,artifact_publication=>JSON::PP::false},'discovery advertises exact source-only boundary');
    is($c->{error_behavior}{projection_code},'VIAL_SOURCE_INSPECTION_ERROR','projection failure discoverable');
    is_deeply($c,FSM::Support::VIALToolingContract::build_vial_source_inspection_contract(),'public facade equals canonical independent contract');
    is_deeply(build_capability_manifest()->{semantic_introspection}{contract_surface_map}{vial_source_inspection}{inspection_contract},$c,'manifest exposes separate contract');
    my ($ok,$out,$err)=cli('--capability-manifest');ok($ok,'actual manifest command succeeds');is($err,'','manifest has no stderr');
    is_deeply($json->decode($out)->{semantic_introspection}{contract_surface_map}{vial_source_inspection}{inspection_contract},$c,'actual native discovery agrees');
    my $saved=$json->decode($json->encode($c));$c->{intent_families}{2}[0]{family_id}='mutated';
    is_deeply($cap->(),$saved,'capability API returns independent records');
    eval {$cap->({})};like($@,qr/accepts no arguments/,'discovery invocation is closed');
    my ($help_ok,$help)=cli('vial','--help');ok($help_ok,'VIAL help succeeds');like($help,qr/vial inspect --json/,'native help advertises inspect');
    # Frozen hashes captured from the preceding committed public capability APIs.
    is(sha256_hex($json->encode(vial_tool_capabilities())),'42db05da519dffd97c3e40ec254c82d09b5f20ef53a849e53025b976f5aded4e','frozen v1 capability record unchanged');
    is(sha256_hex($json->encode(vial_tool_capabilities_v2())),'2efc33c476afc8617a43890b834c828efda0b5150f9c1fdf0e9e984142330dda','frozen v2 capability record unchanged');
};

subtest 'actual native command preserves full API detail across source forms' => sub {
    for my $case ([1,$base{1}],[2,$base{2}],[2,$lifecycle]) {
        my ($version,$text)=@$case;
        for my $style (qw(normal terse)) {
            my $id="$prefix/source.vial";
            my $projected=FSM::VIAL::SourceProjection->format_source({text=>$text,source_name=>$id,output_style=>$style})->{text};
            write_file("$repo/$id",$projected);my $before=snapshot();
            my ($ok,$out,$err)=cli('vial','inspect','--json','--language-version',$version,'--style',$style,$id);
            ok($ok,'native inspection succeeds');is($err,'','native JSON success has no stderr');
            my $r=$json->decode($out);my $api=inspect_vial_source_file({workspace_root=>$repo,source_id=>$id,language_version=>$version,source_style=>$style});
            is_deeply($r,$api,'entire command result equals public file API');
            is($r->{inspection}{packages}[0]{fixtures}[0]{scenarios}[0]{actions}[0]{kind},'reset','authored action body crosses native command');
            if ($text =~ /\(family lifecycle_control/) {
                my ($deadline)=grep {$_->{node_kind} eq 'deadline'} @{$r->{inspection}{packages}[0]{intent_families}[0]{nodes}};
                is($deadline->{payload}{detail}{max_cycles},1024,'authored deadline crosses native command');
            }
            is_deeply(snapshot(),$before,'command writes no source or artifact');
        }
    }
    for my $version (1,2) {
        my $id="$prefix/root.vial";my $import_id="$prefix/library.vial";
        my $text=$base{$version};$text =~ s/\(imports\)/(imports (import lib "$import_id"))/;
        my $library=$base{$version};$library =~ s/package ahb_subordinate_base_output_arbitration/package library/;
        write_file("$repo/$id",$text);write_file("$repo/$import_id",$library);
        my ($ok,$out,$err)=cli('vial','inspect','--json','--language-version',$version,$id);ok($ok,'actual imported command succeeds');
        my $r=$json->decode($out);is($r->{inspection}{packages}[1]{name},'library','imported bodies preserved');
        is_deeply($r,inspect_vial_source_file({workspace_root=>$repo,source_id=>$id,language_version=>$version}),'imported complete API equality');
        unlink "$repo/$import_id" or die $!;
        ($ok,$out,$err)=cli('vial','inspect','--json','--language-version',$version,$id);ok(!$ok,'actual missing import command fails');is($err,'','native failure stays JSON-only');
        is_deeply($json->decode($out),inspect_vial_source_file({workspace_root=>$repo,source_id=>$id,language_version=>$version}),'native failure preserves complete API report');
    }
};

subtest 'JSON-only command refuses extra effects and preserves failure exits' => sub {
    my $id="$prefix/valid.vial";write_file("$repo/$id",$base{1});
    for my $options ([qw(--dut x.fsm)],[qw(--fixture f)],[qw(--scenario s)],[qw(--profile p)],[qw(--replay x.json)],
        [qw(--native-catalog x.json)],[qw(--outdir output)],[qw(--backend b)],[qw(--quiet)],[qw(--unknown)],
        [qw(--language-version 3)],[qw(--language-version 2.0)],[qw(--style invalid)]) {
        my $before=snapshot();my ($status,$out,$err)=adapter_cli('--json',@$options,$id);
        is($status,2,'invalid invocation exit status');is($err,'','JSON refusal has no stderr');
        my $r=$json->decode($out);is($r->{schema},'fsmgen.vial_source_inspection.v1','invocation failure uses independent envelope');
        ok(!$r->{success} && !defined($r->{inspection}),'invalid invocation has no partial detail');
        is($r->{diagnostics}[0]{code},'VIAL_TOOL_INVOCATION_ERROR','specific invocation refusal');
        is_deeply(snapshot(),$before,'refused options have no write effects');
    }
    for my $args ([],[$id,$id]) {my ($status,$out)=adapter_cli('--json',@$args);is($status,2,'source cardinality fails specifically');ok(!$json->decode($out)->{success},'source cardinality never succeeds')}
    my ($status,$out,$err)=adapter_cli($id);is($status,2,'JSON mode required');is($out,'','no implicit JSON or success text');like($err,qr/requires --json/,'missing JSON explained');
    for my $case (['missing.vial',2],['../outside.vial',2]) {($status,$out,$err)=adapter_cli('--json',$case->[0]);is($status,$case->[1],'host/path failure exit preserved');ok(!$json->decode($out)->{success},'host failure has typed result')}
    write_file("$repo/$id",'(vial');($status,$out,$err)=adapter_cli('--json',$id);is($status,1,'source syntax failure exit preserved');
    write_file("$repo/$id",$base{1});
    {no warnings qw(redefine once);local *FSM::VIAL::SourceInspection::build=sub {die 'private path'};
     ($status,$out,$err)=adapter_cli('--json',$id);}
    is($status,1,'projection failure is a failed inspection');my $r=$json->decode($out);
    is($r->{diagnostics}[0]{code},'VIAL_SOURCE_INSPECTION_ERROR','projection failure survives CLI');ok($r->{check_result}{success},'successful check is retained');
};
done_testing();
sub read_file {open my $fh,'<:raw',$_[0] or die $!;local $/;my $s=<$fh>;close $fh or die $!;return $s}
sub write_file {open my $fh,'>:raw',$_[0] or die $!;print {$fh} $_[1] or die $!;close $fh or die $!}
