use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use JSON::PP;
use Digest::SHA qw(sha256_hex);
use File::Path qw(make_path);
use FSM::Scheduler::ISF;
use FSM::Test::ConditionalOriginAuthority;
use FSM::Test::LibraryDocumentOriginAuthority;
use FSM::Test::ATLDocumentOriginAuthority;
my $base='docs/audits/source-origin-validator-causes-20261003';
my $json=JSON::PP->new->canonical;
my $bindings=read_json("$base/bindings.json");
my $inputs=read_json("$base/inputs.json");
require "./$base/late-packages.pl";
my $local=$inputs->{local}{product};
my $parser=FSM::Test::ConditionalOriginParser->new;
my $local_actor=$parser->parse_source($local->{source},$local->{label});
my $local_ledger=$parser->ledger;
my $authority=FSM::Test::ConditionalOriginAuthority->from_source($local->{source},$local->{label});
my $macro=$inputs->{twin_macro}{product};
my $authored=$inputs->{twin_authored}{product};
my $twin=FSM::Test::ConditionalOriginAuthority->from_source($macro->{source},$macro->{label});
my %documents;
my %authorities;
for my $kind (qw(library ATL)) {
    my $old=$inputs->{$kind}{product};
    my $directory="$base/fixtures/$kind";make_path($directory);
    my %docs=map {my($name)=m{/([^/]+)$};("$directory/$name"=>$old->{documents}{$_})} keys %{$old->{documents}};
    my $label="$directory/authority-root.isf";
    for my $path (sort keys %docs) {write_file($path,$docs{$path}) unless $path eq $label}
    $documents{$kind}=[$label,\%docs,[$directory]];
    $authorities{$kind}=$kind eq 'library'
        ? FSM::Test::LibraryDocumentOriginAuthority->from_documents($label,\%docs,[$directory])
        : FSM::Test::ATLDocumentOriginAuthority->from_documents($label,\%docs,[$directory]);
}
my @contexts;
sub context {push @contexts,{id=>$_[0],site=>$_[1],kind=>$_[2],wanted=>$_[3],expected=>$_[4],variant=>$_[5]}}
context('scheduler','t/2043-isf-conditional-origin-parser.t:132','scheduler',"unsupported '(cond ...)' clause","Transaction 'main': unsupported '(cond ...)' clause in transaction",'');
my %generic=(omission=>'incomplete coverage',duplicate=>'missing, extra or duplicate path',wrong_path=>'missing, extra or duplicate path',changed_target=>'target identity mismatch',forged_origin=>'differs from the actual producer result',source_identity=>'differs from the actual producer result',unknown_field=>'unknown or missing fields',schema_kind=>'schema mismatch');
for my $name (sort keys %generic) {context("generic_$name",'t/2043-isf-conditional-origin-parser.t:174','generic','conditional origin',"conditional origin $generic{$name}",$name)}
for my $variant (qw(actor ledger)) {context("local_$variant",'t/2044-isf-conditional-origin-source-authority.t:50','local',"conditional origin $variant differs from authoritative source","conditional origin $variant differs from authoritative source",$variant)}
context('twins','t/2044-isf-conditional-origin-source-authority.t:79','twins','ledger differs from authoritative source','conditional origin ledger differs from authoritative source','');
context('missing','t/2044-isf-conditional-origin-source-authority.t:91','missing','independent source authority required','conditional origin independent source authority required','');
for my $kind (qw(library ATL)) {
    my $site=$kind eq 'library'?'t/2046-isf-library-document-origin-authority.t:79':'t/2047-isf-atl-document-origin-authority.t:77';
    for my $variant (qw(actor proof)) {context("${kind}_$variant",$site,$kind,'differs from authoritative document set',"library origin $variant differs from authoritative document set",$variant)}
}
context('same_late','t/2045-isf-same-source-library-origins.t:161','same_late','conditional origin target identity mismatch','conditional origin target identity mismatch','target');
for my $variant (qw(target instance coverage parameter_kind)) {context("library_late_$variant",'t/2046-isf-library-document-origin-authority.t:195','library_late','library origin final use '.($variant eq 'coverage'?'coverage':'target or identity').' differs','library origin final use '.($variant eq 'coverage'?'coverage':'target or identity').' differs',$variant)}
for my $variant (qw(target declaration coverage)) {context("ATL_late_$variant",'t/2047-isf-atl-document-origin-authority.t:118','ATL_late','ATL origin final '.($variant eq 'coverage'?'resolved actor coverage':'target or instance identity').' differs','ATL origin final '.($variant eq 'coverage'?'resolved actor coverage':'target or instance identity').' differs',$variant)}
my @products;
for my $c (@contexts) {
    my @bands=$c->{kind}=~/_late$/ ? qw(positive wrong_source_echo wrong_source_plain wrong_label_echo) : qw(positive wrong_argument_echo wrong_argument_plain);
    for my $band (@bands) {
        my $payload=payload($c,$band);
        # Only actual API inputs/producer selection travel into the failing call.
        my $accepted=eval {invoke($c->{kind},$payload);1};
        my $error=$@;
        my $diagnostic=$error;
        my $statement=$bindings->{sites}{$c->{site}}{statement};
        my $matched=eval 'local $@=$error;'.$statement;
        die $@ if $@;
        my $first=(split /\n/,$error)[0] // '';
        my $pattern=$statement; $pattern=~s/^like\(\$(?:\@|diagnostic),\s*//; $pattern=~s/,.*\z//s;
        my $first_matched=eval '$first =~ '.$pattern;die $@ if $@;
        push @products,{%$c,band=>$band,payload=>$payload,accepted=>$accepted?1:0,error=>$error,first_line=>$first,matched=>$matched?1:0,first_line_matched=>$first_matched?1:0};
        ok(($matched?1:0)==($band eq 'positive'?1:0),"$c->{id} $band cause classification");
    }
}
write_file("$base/products.json",$json->encode({contexts=>\@contexts,products=>\@products,original=>{actor=>$local_actor,ledger=>$local_ledger},documents=>\%documents})."\n");
done_testing;
sub payload {
    my($c,$band)=@_;my($kind,$variant)=@$c{qw(kind variant)};
    if ($kind=~/_late$/) {
        if ($band eq 'positive') {return $kind eq 'same_late' ? {source=>$inputs->{same}{product}{source},label=>'late.isf',variant=>$variant} : {documents=>$documents{$kind eq 'library_late'?'library':'ATL'},variant=>$variant}}
        my $source=$band eq 'wrong_source_echo'?"; $c->{wanted}\n(not_actor)":'(not_actor)';
        my $label=$band eq 'wrong_label_echo'?"$c->{wanted}.isf":'wrong.isf';
        return {source=>$source,label=>$label,documents=>[$label,{$label=>$source},[]],variant=>$variant};
    }
    if ($band ne 'positive') {return {actor=>$band eq 'wrong_argument_echo'?$c->{wanted}:'unrelated argument',variant=>$variant}}
    return {source=>$inputs->{scheduler}{source}} if $kind eq 'scheduler';
    if ($kind eq 'generic') {
        my $bad=clone($local_ledger);
        if ($variant eq 'omission') {shift @{$bad->{entries}}}
        elsif ($variant eq 'duplicate') {push @{$bad->{entries}},clone($bad->{entries}[0])}
        elsif ($variant eq 'wrong_path') {$bad->{entries}[0]{path}[-1]=9999}
        elsif ($variant eq 'changed_target') {$bad->{entries}[0]{target}[1]='other'}
        elsif ($variant eq 'forged_origin') {$bad->{entries}[0]{origin}{calls}=[];$bad->{catalog}[$bad->{entries}[0]{origin}{catalog_id}]{owner}{name}='forged'}
        elsif ($variant eq 'source_identity') {$bad->{source_sha256}='0'x64}
        elsif ($variant eq 'unknown_field') {$bad->{entries}[0]{extra}=1}
        else {$bad->{schema_version}='1'}
        return {actor=>clone($local_actor),ledger=>$bad};
    }
    if ($kind eq 'local') {my($a,$l)=(clone($local_actor),clone($local_ledger));if($variant eq 'actor'){$a->{actor_name}='forged'}else{$l->{schema_version}=9}return {actor=>$a,ledger=>$l}}
    if ($kind eq 'twins') {my$l=clone($authored->{ledger});$l->{source_sha256}=$macro->{ledger}{source_sha256};return {actor=>clone($authored->{instrumented}),ledger=>$l}}
    return {actor=>clone($local_actor),ledger=>clone($local_ledger)} if $kind eq 'missing';
    my $a=$authorities{$kind}->actor;my$p=$authorities{$kind}->proof;if($variant eq 'actor'){$a->{actor_name}='forged'}else{$p->{schema_version}=9}return {actor=>$a,proof=>$p};
}
sub invoke {
    my($kind,$p)=@_;
    if ($kind eq 'scheduler') {my$a=exists($p->{source})?FSM::Adapter::ISF::Parser->new->parse_source($p->{source},'first_samples.isf'):$p->{actor};return FSM::Scheduler::ISF->new->lower($a)}
    if ($kind eq 'generic') {
        return $parser->validate($p->{actor},$p->{ledger}) if exists $p->{ledger};
        my$l={schema_version=>1,actor_sha256=>sha256_hex($json->encode($p->{actor})),source_sha256=>'0'x64,catalog=>[],entries=>[],residuals=>[]};
        return FSM::Test::ConditionalOriginParser->new->validate($p->{actor},$l);
    }
    if ($kind eq 'local'||$kind eq 'twins') {my$self=exists($p->{ledger})?($kind eq 'twins'?$twin:$authority):bless({},'FSM::Test::ConditionalOriginAuthority');return $self->validate($p->{actor},$p->{ledger}||{})}
    if ($kind eq 'missing') {my$self=exists($p->{ledger})?bless({},'FSM::Test::ConditionalOriginAuthority'):$authority;return $self->validate($p->{actor},$p->{ledger}||{})}
    if ($kind eq 'library'||$kind eq 'ATL') {my$self=exists($p->{proof})?$authorities{$kind}:bless({},$kind eq 'library'?'FSM::Test::LibraryDocumentOriginAuthority':'FSM::Test::ATLDocumentOriginAuthority');return $self->validate($p->{actor},$p->{proof}||{})}
    if ($kind eq 'same_late') {return FSM::Test::LibraryLateTargetMutation->new->parse_source($p->{source},$p->{label})}
    my$self=$kind eq 'library_late'?FSM::Test::DocumentLateCloneMutation->new:FSM::Test::ATLLateOriginMutation->new;
    $self->{mutation}=$p->{variant};local$ENV{FSMLIB}=join ':',@{$p->{documents}[2]};return $self->parse_documents(@{$p->{documents}}[0,1]);
}
sub clone {$json->decode($json->encode($_[0]))}
sub read_json {open my$f,'<:raw',$_[0]or die$!;local$/;return$json->decode(<$f>)}
sub write_file {open my$f,'>:raw',$_[0]or die$!;print{$f}$_[1]or die$!;close$f or die$!}
