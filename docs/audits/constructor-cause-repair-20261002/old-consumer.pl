use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use JSON::PP;
use FSM::Test::ConditionalOriginAuthority;
use FSM::Test::SameSourceLibraryOriginParser;
use FSM::Test::LibraryDocumentOriginAuthority;
use FSM::Test::ATLDocumentOriginAuthority;
use FSM::Test::FileDocumentOriginAuthority;
use FSM::Test::LocalFormalOriginAuthority;
my $base='docs/audits/constructor-cause-repair-20261002';
my $json=JSON::PP->new->canonical;
open my $b,'<:raw',"$base/bindings.json" or die $!;
my $bound=do {local $/;$json->decode(<$b>)};close $b or die $!;
for my $name (qw(library file)) {
    my $package=$name eq 'library' ? 'CurrentLibraryHelper' : 'CurrentFileHelper';
    eval "package $package;".$bound->{helpers}{$name};die $@ if $@;
}
delete @ENV{qw(FSMGEN_LIBRARY_DIAGNOSTIC_FULL_STACK FSMGEN_FILE_DIAGNOSTIC_FULL_STACK)};
my @cases=(
 ['local_import','t/2044-isf-conditional-origin-source-authority.t:98','local','conditional origin imported source authority is not qualified','(actor import_probe (imports (library missing.lib as lib)))','import_probe.isf',qr/conditional origin imported source authority is not qualified/],
 ['same_external','t/2045-isf-same-source-library-origins.t:147','same','external document authority is not qualified','(actor closed (clock clk) (interface (input start) (output done)) (imports (library missing.lib as lib)) (use lib.worker as child (bind (clock clk) (input start start) (output done done))))','closed.isf',qr/external document authority is not qualified/],
 ['same_package','t/2045-isf-same-source-library-origins.t:147','same','package source authority is not qualified','(actor closed (imports (package pkg)))','closed.isf',qr/package source authority is not qualified/],
 ['same_ATL','t/2045-isf-same-source-library-origins.t:147','same','ATL source authority is not qualified','(actor closed (instance child of Worker))','closed.isf',qr/ATL source authority is not qualified/],
 ['local_library','t/2045-isf-same-source-library-origins.t:151','local','imported source authority is not qualified','(actor closed (imports (library missing.lib as lib)))','closed.isf',qr/imported source authority is not qualified/],
 ['same_absolute','t/2045-isf-same-source-library-origins.t:155','same','repository-relative source label','(actor closed)','/foreign/probe.isf',qr/repository-relative source label/],
 ['same_escape','t/2045-isf-same-source-library-origins.t:155','same','repository-relative source label','(actor closed)','../probe.isf',qr/repository-relative source label/],
 ['library_ATL','t/2047-isf-atl-document-origin-authority.t:127','library','ATL source authority is not qualified','(actor closed (instance child of Worker))','closed.isf',qr/ATL source authority is not qualified/],
 ['ATL_external','t/2047-isf-atl-document-origin-authority.t:130','ATL','unresolved external actor authority is not qualified','(actor closed (instance child of Worker))','closed.isf',qr/(?:unresolved external actor authority|package source authority) is not qualified/],
 ['ATL_package','t/2047-isf-atl-document-origin-authority.t:130','ATL','package source authority is not qualified','(actor closed (imports (package pkg)))','closed.isf',qr/(?:unresolved external actor authority|package source authority) is not qualified/],
 ['formal_residual','t/2052-isf-local-formal-origin-authority.t:116','formal','residual normalization is not qualified','(actor formal_probe (interface (input allow) (input payload (width 3))) (proc choose (params (c)) (cond (c (sample payload as captured)) (else (sample payload as saved)))) (transaction main (call choose allow)))','decline.isf',qr/residual normalization is not qualified/],
);
my @products;
for my $case (@cases) {
    my ($id,$site,$kind,$literal,$positive_source,$positive_label,$reason)=@$case;
    for my $band (qw(positive wrong_source_echo wrong_source_plain wrong_label_echo)) {
        my $source=$band eq 'positive' ? $positive_source
            : $band eq 'wrong_source_echo' ? "; $literal\n(not_actor)" : '(not_actor)';
        my $label=$band eq 'positive' ? $positive_label : $band eq 'wrong_label_echo' ? "$literal.isf" : 'wrong.isf';
        # No expected-pattern parameter is introduced into the actual failing call stack.
        my $accepted=eval {
            if ($kind eq 'local') {FSM::Test::ConditionalOriginAuthority->from_source($source,$label)}
            elsif ($kind eq 'same') {FSM::Test::SameSourceLibraryOriginParser->new->parse_source($source,$label)}
            elsif ($kind eq 'library') {FSM::Test::LibraryDocumentOriginAuthority->from_documents($label,{$label=>$source},[])}
            elsif ($kind eq 'ATL') {FSM::Test::ATLDocumentOriginAuthority->from_documents($label,{$label=>$source},[])}
            else {FSM::Test::LocalFormalOriginAuthority->from_source($source,$label)}
            1;
        };
        my $error=$@;
        my ($diagnostic,$observed_error)=($error,$error);
        my $statement=$bound->{statements}{$site};
        my $matched=eval 'local $@=$error;'.$statement;
        die $@ if $@;
        my $first=(split /\n/,$error)[0] // '';
        push @products,{id=>$id,site=>$site,band=>$band,kind=>$kind,source=>$source,label=>$label,
            accepted=>$accepted?1:0,error=>$error,first_line=>$first,matched=>$matched?1:0,
            first_line_matched=>$first =~ $reason ? 1:0,literal=>$literal};
    }
}
my @helpers;
for my $kind (qw(library file)) {
    my $literal=$kind eq 'library' ? 'selected source bytes differ from authority' : 'selected source bytes differ from authority';
    my $label=$kind eq 'library' ? "$literal.isf" : "$base/file-workspace/$literal.isf";
    my $source='(not_actor)';
    if ($kind eq 'file') {
        mkdir "$base/file-workspace" or die $! unless -d "$base/file-workspace";
        if (-f $label) {open my $f,'<:raw',$label or die $!;my $actual=do {local $/;<$f>};close $f or die $!;die 'fixture changed' unless $actual eq $source}
        else {open my $f,'>:raw',$label or die $!;print {$f} $source or die $!;close $f or die $!}
    }
    my $accepted=eval {
        if ($kind eq 'library') {FSM::Test::LibraryDocumentOriginAuthority->from_documents($label,{$label=>$source},[])}
        else {FSM::Test::FileDocumentOriginAuthority->from_files($label,{$label=>$source},[])}
        1;
    };
    my $error=$@;my $pattern=qr/selected source bytes differ from authority/;
    my $matched=$kind eq 'library' ? CurrentLibraryHelper::diagnostic_matches($error,$pattern)
        : CurrentFileHelper::diagnostic_matches($error,$pattern);
    push @helpers,{kind=>$kind,label=>$label,source=>$source,accepted=>$accepted?1:0,error=>$error,
        first_line=>(split(/\n/,$error))[0],matched=>$matched?1:0,literal=>$literal};
}
open my $out,'>:raw',"$base/products.json" or die $!;
print {$out} $json->encode({products=>\@products,helpers=>\@helpers})."\n" or die $!;close $out or die $!;
done_testing;
