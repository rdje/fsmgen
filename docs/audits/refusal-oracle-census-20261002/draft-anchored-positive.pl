use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use JSON::PP;
use Digest::SHA qw(sha256_hex);
use FSM::Test::FileDocumentOriginAuthority;

my $base='docs/audits/refusal-oracle-census-20261002';
my $json=JSON::PP->new->canonical;
my (@bindings,@results);
for my $case (
    ['file','t/2048-isf-file-document-origin-authority.t','FSM::Census::FileHelper'],
    ['value','t/1986-isf-record-port-value-gates.t','FSM::Census::ValueHelper'],
) {
    my ($kind,$path,$package)=@$case;
    my $source=read_file($path);
    my ($helper)=$source =~ /^(sub refuses \{.*?^\})/msg;
    die "helper not found $path" unless defined $helper;
    my ($line_helper)=$source =~ /^(sub diagnostic_line[^\n]*)/m;
    my $program="package $package; use strict; use warnings; use Test::More;\n$helper\n"
        . (defined($line_helper)?$line_helper.'\n':'');
    # Exact byte-bound consumer function, rehosted without executing unrelated
    # top-level/native tests. Its body and actual Test::More assertions remain
    # unchanged; the callback executes the real public file authority.
    $program =~ s/\\n\z/\n/;
    eval $program;die $@ if $@;
    push @bindings,{path=>$path,source_sha256=>sha256_hex($source),
        helper=>$helper,helper_sha256=>sha256_hex($helper),line_helper=>$line_helper};
    no strict 'refs';
    my $consumer=\&{"${package}::refuses"};
    for my $mode (qw(wrong_echo correct)) {
        my $pattern=$mode eq 'wrong_echo' ? qr/oracle_echo_expected_marker/
            : qr/\Afile origin independent document set required\z/;
        my @controls;
        my $error;
        my $callback=sub {
            eval {FSM::Test::FileDocumentOriginAuthority->from_files('missing.isf',{},[])};
            $error=$@;
            die $error; # preserve the exact actual Carp diagnostic
        };
        if ($kind eq 'file') {
            $consumer->("$kind-$mode",$callback,$pattern,\@controls);
        } else {
            $consumer->($callback,$pattern,"$kind-$mode");
        }
        my ($first)=split /\n/,$error;
        push @results,{kind=>$kind,mode=>$mode,error=>$error,first_line=>$first,
            controls=>\@controls,full_trace_matches=>$error =~ $pattern?1:0,
            first_line_matches=>$first =~ $pattern?1:0};
    }
}
write_file("$base/helper-controls.json",$json->encode({bindings=>\@bindings,results=>\@results})."\n");
done_testing;
sub read_file {open my $fh,'<:raw',$_[0] or die $!;local $/;my $raw=<$fh>;close $fh or die $!;return $raw}
sub write_file {open my $fh,'>',$_[0] or die $!;print {$fh} $_[1];close $fh or die $!}
