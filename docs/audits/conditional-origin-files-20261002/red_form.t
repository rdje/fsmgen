use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../../perl", "$FindBin::Bin/../../../t/lib";
use Test::More;
use JSON::PP;
use Cwd qw(getcwd);
use File::Path qw(make_path);
use File::Temp qw(tempdir);
use FSM::Test::ProjectDataLocality;
use FSM::Test::FileDocumentOriginAuthority;
my $json=JSON::PP->new->canonical;
my $repository=getcwd();
my @paths=sort glob 'docs/audits/conditional-origin-atl-20261002/current-bound/*.json';
@paths=grep {$_ !~ m{/(?:atl-only|finalization)\.json$}} @paths;
@paths=grep {
    open my $candidate,'<:raw',$_ or die $!;
    my $product=$json->decode(do {local $/;<$candidate>});close $candidate or die $!;
    $product->{proof}{uses}[0]{ledger}{catalog}[0]{operation} eq 'select';
} @paths;
die 'immutable original select witness missing' unless @paths;
open my $input,'<:raw',$paths[0] or die $!;
my $source=$json->decode(do {local $/;<$input>});close $input or die $!;
my $root=join "\n",$source->{documents}{$source->{label}},map {$source->{documents}{$_}}
    sort grep {$_ ne $source->{label}} keys %{$source->{documents}};
my $workspace=tempdir(CLEANUP=>1);make_path("$workspace/sources");
open my $file,'>:raw',"$workspace/sources/main.isf" or die $!;print {$file} $root or die $!;close $file or die $!;
chdir $workspace or die $!;
my $authority=eval {FSM::Test::FileDocumentOriginAuthority->from_files('sources/main.isf',{'sources/main.isf'=>$root},[])};
my $diagnostic=$@;
ok(defined($authority),'actual reused canonical form authenticates and publishes');
my $proof=defined($authority)?$authority->proof:undef;
if (defined($authority)) {
    is($json->encode($proof->{uses}[0]{ledger}),$json->encode($proof->{atl}[0]{ledger}),
        'actual repeated same-source form retains complete original producer intent');
}

chdir $repository or die $!;
if ($ENV{FSMGEN_FILE_FORM_CAPTURE}) {
    open my $out,'>:raw',$ENV{FSMGEN_FILE_FORM_CAPTURE} or die $!;
    print {$out} $json->encode({predecessor=>$paths[0],documents=>{'sources/main.isf'=>$root},actor=>defined($authority)?$authority->actor:undef,proof=>$proof,diagnostic=>($diagnostic =~ /\A([^\n]*)/ ? $1 : '')})."\n" or die $!;
    close $out or die $!;
}
done_testing;
