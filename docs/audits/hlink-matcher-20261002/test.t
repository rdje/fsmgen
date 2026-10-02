use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../perl", "$FindBin::Bin/lib";
use Test::More;
use FSM::Test::ProjectDataLocality;
use File::Temp qw(tempdir);
use File::Spec;
use IPC::Cmd qw(run);
use JSON::PP;

my $json = JSON::PP->new->canonical;
my $workspace = tempdir(CLEANUP => 1);
my $probe = "$workspace/probe.pl";
write_file($probe, <<'PERL');
use strict;
use warnings;
use File::Spec;
use JSON::PP;
use LinkedRE;
use LinkedSpec;

my ($mode, $source) = @ARGV;
my $module = File::Spec->rel2abs($ENV{FSMGEN_HLINK_SOURCE} || 'perl/HLinkSubst.pm');
require $module;
$INC{'HLinkSubst.pm'} = $module;
my $value;
if ($mode eq 'grammar') {
    my $parser = LinkedSpec::get_parser('hlink_substitution');
    $value = $parser->(\$source);
} elsif ($mode eq 'linked') {
    require HUtils;
    $value = HUtils::Link({NAME=>'literal_value', PATH=>'[NAME]/payload',
        nested=>{value=>'[NAME]'}, values=>['left','[NAME]']});
} else {
    if ($mode eq 'warm') {
        my $warm = 'last';
        LinkedRE::or(\$warm, LinkedRE::oredRE(qr/first/, qr/middle/, qr/last/));
    }
    $value = HLinkSubst::Get(\$source);
}
print JSON::PP->new->canonical->encode(freeze($value));

sub freeze {
    my ($value) = @_;
    return $value unless ref $value;
    return {reference=>$$value} if ref($value) eq 'SCALAR';
    return [map {freeze($_)} @$value] if ref($value) eq 'ARRAY';
    return {map {$_=>freeze($value->{$_})} keys %$value} if ref($value) eq 'HASH';
    die 'unexpected public substitution result kind';
}
PERL

my @cases = (
    {name=>'empty', source=>'', expected=>undef},
    {name=>'literal', source=>'literal_value', expected=>['literal_value']},
    {name=>'spaces', source=>'plain words', expected=>['plain words']},
    {name=>'reference', source=>'[ROOT]', expected=>[{reference=>'ROOT'}]},
    {name=>'interleaved', source=>'pre[ROOT]/tail', expected=>['pre',{reference=>'ROOT'},'/tail']},
    {name=>'adjacent', source=>'[A][B]', expected=>[{reference=>'A'},{reference=>'B'}]},
    {name=>'nested_reference', source=>'[A[B]]', expected=>[{reference=>'A[B]'}]},
    {name=>'braces', source=>'{a{b}}', expected=>['{a{b}}']},
    {name=>'mixed', source=>'before{a}[B]after', expected=>['before','{a}',{reference=>'B'},'after']},
    {name=>'escaped', source=>'\[literal\]', expected=>['\[literal\]']},
    {name=>'dangling', source=>']', status=>1, stdout=>"(HLinkSubst) -E- Dangling closing bracket\n"},
    {name=>'unclosed_reference', source=>'[ROOT', status=>2, stdout=>"(HLinkSubst) -E- Unmatched closing bracket\n"},
    {name=>'unclosed_brace', source=>'{body', status=>2, stdout=>"(HLinkSubst) -E- Unmatched closing brace\n"},
);
my @products;
for my $case (@cases) {
    subtest $case->{name} => sub {
        my %views;
        for my $mode (qw(grammar static warm)) {
            my $result = produce($mode, $case->{source});
            if (exists $case->{status}) {
                ok(!$result->{success}, "$mode rejects malformed source");
                is($result->{stdout}, $case->{stdout}, "$mode retains exact grammar diagnostic");
                like($result->{error}, qr/exited with value $case->{status}\z/, "$mode retains error exit code");
            } else {
                ok($result->{success}, "$mode accepts complete valid source");
                is_deeply($result->{product}, $case->{expected}, "$mode returns whole independently declared tokens and reference kinds");
            }
            is($result->{stderr}, '', "$mode keeps stderr clean");
            $views{$mode} = $result;
        }
        push @products, {case=>$case, views=>\%views};
    };
}
subtest 'whole linked configuration retains literals, references and nested values' => sub {
    my $result = produce('linked', '');
    ok($result->{success}, 'actual HUtils link succeeds');
    is($result->{stderr}, '', 'linked configuration keeps stderr clean');
    is_deeply($result->{product}, {NAME=>'literal_value',PATH=>'literal_value/payload',
        nested=>{value=>'literal_value'},values=>['left','literal_value']},
        'complete public linked product follows declared source values');
    push @products, {case=>{name=>'linked'}, views=>{linked=>$result}};
};
if (defined $ENV{FSMGEN_HLINK_CAPTURE}) {
    write_file($ENV{FSMGEN_HLINK_CAPTURE}, $json->encode({products=>\@products}) . "\n");
}
done_testing;

sub produce {
    my ($mode, $source) = @_;
    my ($ok, $error, $full, $stdout, $stderr) = run(command=>[$^X,'-Iperl',$probe,$mode,$source]);
    my $out = join '', @{$stdout || []};
    my $err = join '', @{$stderr || []};
    $err =~ s/\Q$workspace\E/<workspace>/g;
    my $diagnostic = $error || '';
    $diagnostic =~ s/\Q$workspace\E/<workspace>/g;
    my $product = eval { $json->decode($out) };
    return {success=>$ok?1:0,product=>$product,stdout=>$out,stderr=>$err,error=>$diagnostic};
}

sub write_file {
    my ($path, $bytes) = @_;
    open my $file, '>:raw', $path or die $!;
    print {$file} $bytes or die $!;
    close $file or die $!;
}
