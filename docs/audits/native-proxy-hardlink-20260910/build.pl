use strict;
use warnings;
use Cwd qw(abs_path);
use Digest::SHA qw(sha256_hex);
use File::Basename qw(dirname);
use File::Spec;
use JSON::PP;
use lib 'perl', 't/lib';
use FSM::ProjectDataLocality qw(repository_root);
use FSM::Test::RustProxyFixture qw(prepare_rust_proxy);

die "this isolated control accepts no arguments\n" if @ARGV;
my $root = repository_root();
my $base = File::Spec->catdir($root, qw(.artifacts tmp process-supervisor-tests fsmgen-HardlinkBase20260910));
my $source = File::Spec->catfile($root, qw(t fixtures rust-tool-proxy.c));
my $held = File::Spec->catfile(dirname(abs_path(__FILE__)), 'held.c');
my $selection = FSM::Test::RustProxyFixture::_selection();
die "the admitted native toolchain is required\n"
    unless $selection->{implementation} eq 'native';

# Reuse the qualified builder's compiler/group/custody policy. Only this
# explicitly admitted control's source read differs, through a local test seam.
# Actual generated C bytes must match the controller's independent expectation
# before any native release. Shipped source files are never modified.
my $read = \&FSM::Test::RustProxyFixture::_read_file;
my ($control) = $read->($held);
my ($original) = $read->($source);
my $prepared;
{
    no warnings 'redefine';
    local *FSM::Test::RustProxyFixture::_read_file = sub {
        my ($path, @rest) = @_;
        my @result = $read->($path, @rest);
        $result[0] = $control if $path eq $source;
        return @result;
    };
    $prepared = prepare_rust_proxy($base, 'proxy_nonzero');
}
print JSON::PP->new->ascii->canonical->encode({
    schema => 'fsmgen.hardlink_control_preparation.v1',
    control => 'held_path_observation_only',
    original_source_sha256 => sha256_hex($original),
    control_source_sha256 => sha256_hex($control),
    prepared => $prepared,
}), "\n" or die "cannot retain control preparation: $!\n";
