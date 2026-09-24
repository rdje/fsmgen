use strict;
use warnings;
use File::Path qw(make_path);
use FindBin;
use Cwd qw(abs_path);
use JSON::PP;
use FSM::Test::ProjectDataLocality;
use FSM::Adapter::IAL2::PPIF;
my $root = abs_path("$FindBin::Bin/../../..");
chdir $root or die "chdir repository: $!\n";
my $dest = shift @ARGV or die "output directory required\n";
my $compositions = @ARGV && $ARGV[0] eq "--compositions" ? shift(@ARGV) : undef;
die "use a new repository-local artifact directory\n" unless !@ARGV && $dest =~ m{\A\.artifacts/(?:[A-Za-z0-9_-]+/)*[A-Za-z0-9_-]+\z};
die "output exists\n" if -e $dest;
make_path($dest);
my $json = JSON::PP->new->canonical->utf8->pretty;
my @cases = $compositions
    ? qw(axi_write_request_composition axi_write_transaction_composition axi_write_burst4_request_composition axi_read_transaction_composition axi_read_burst4_transaction_composition)
    : qw(axi_aw_driver axi_ar_driver axi_w_driver axi_w_burst4_driver axi_b_response_acceptor axi_r_beat_acceptor);
for my $name (@cases) {
    my $result = FSM::Adapter::IAL2::PPIF->new->parse_file("ppif/$name.ppif");
    my $dir = $compositions ? "$dest/$name" : $dest;
    make_path($dir);
    open my $out, '>:raw', "$dir/$name.json" or die $!;
    print {$out} $json->encode($result); close $out or die $!;
    for my $file (keys %{$result->{generated_ial0}{files}}) {
        die "unsafe generated name\n" unless $file =~ /\A[A-Za-z0-9_]+\.fsm\z/;
        open my $fsm, '>', "$dir/$file" or die $!;
        print {$fsm} $result->{generated_ial0}{files}{$file}; close $fsm or die $!;
    }
    print "$name captured with $INC{'FSM/Adapter/ISF/Parser.pm'}\n";
}
