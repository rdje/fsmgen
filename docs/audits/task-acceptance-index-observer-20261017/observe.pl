use strict;
use warnings;
use Cwd qw(abs_path);
use Config;
use Digest::SHA qw(sha256_hex);
use Fcntl qw(O_WRONLY O_CREAT O_EXCL O_APPEND);
use JSON::PP ();
use lib 'perl', 't/lib', 'docs/audits/native-group-witness-20260927',
    'docs/audits/native-group-witness-20260927/failure-only',
    'docs/audits/task-acceptance-index-observer-20261017';
use FSM::Test::ProjectDataLocality;
use GroupWitness;
use IndexObserver;

my $selector = shift @ARGV;
die "exactly one fixed selector required\n" unless defined($selector) && !@ARGV;
die "injected Perl configuration\n" if $ENV{PERL5OPT};
my ($name, $target, $scenario) = IndexObserver::selection($selector);
my $admission = JSON::PP->new->decode(IndexObserver::read_bytes("$IndexObserver::WORK/$name-admission.json", 65_536));
IndexObserver::validate($admission, $selector);
my $base = 'docs/audits/native-group-witness-20260927';
my $qualified = JSON::PP->new->decode(IndexObserver::read_bytes("$base/manifest.json", 65_536));
die "qualified native Perl ABI changed\n" unless $Config{version} eq $qualified->{build}{perl_version};
for my $path (qw(GroupWitness.pm context.c)) {
    die "qualified native source changed\n" unless sha256_hex(IndexObserver::read_bytes("$base/$path", 2_097_152))
        eq $qualified->{sha256}{$path};
}
my $failure = JSON::PP->new->decode(IndexObserver::read_bytes("$base/failure-only/manifest.json", 65_536));
die "qualified failure-only source changed\n" unless sha256_hex(IndexObserver::read_bytes("$base/failure-only/FailureWitness.pm", 65_536))
    eq $failure->{sha256}{'FailureWitness.pm'};
my $helper = '.artifacts/native-group-witness/context.bundle';
die "qualified native helper changed\n" unless sha256_hex(IndexObserver::read_bytes($helper, 2_097_152))
    eq $qualified->{build}{binary_sha256};
our $observer_directory = "$IndexObserver::WORK/$name";
mkdir $observer_directory or die "exclusive observer directory: $!";
sysopen my $sink, "$observer_directory/events.jsonl", O_WRONLY | O_CREAT | O_EXCL | O_APPEND, 0600 or die $!;
GroupWitness->load_context(abs_path($helper));
if ($scenario ne 'none') {
    require Control;
    Control::before_install($observer_directory, $scenario);
}
my $observer = IndexObserver->new($sink, $observer_directory);
$observer->install();
Control::after_install($observer_directory) if $scenario ne 'none';
my $completed = do "./$target";
my $test_error = defined($completed) ? undef : ($@ || "selected test load failed: $!");
eval {IndexObserver::validate($admission, $selector); 1};
my $input_error = $@ || undef;
pop @{$observer->{receipts}} if $scenario eq 'coverage_gap';
my $summary = $observer->finish($admission, $input_error, $test_error);
close $sink or die "close native capture: $!";
die "selected test error: $test_error\n" if $test_error;
die "observer input error: $input_error\n" if $input_error;
die "observer gaps retained in summary.json\n" if @{$summary->{retention_errors}}
    || @{$summary->{capture_gaps}} || $summary->{coverage_error} || $summary->{receipt_coverage_error};
