use strict;
use warnings;
use lib 'perl', 't/lib';
use Cwd qw(abs_path);
use Fcntl qw(O_WRONLY O_CREAT O_EXCL);
use JSON::PP;
use FSM::Test::ProjectDataLocality;
use FSM::Test::ProcessSupervisor qw(supervise_process);
use FSM::Test::SourceQueryRunner;
my $root = abs_path('.');
my %local = (
    CCACHE_DIR => '.artifacts/cache/unary-runtime/ccache',
    CCACHE_TEMPDIR => '.artifacts/tmp/unary-runtime-ccache',
    CLANG_MODULE_CACHE_PATH => '.artifacts/cache/unary-runtime/clang-modules',
    XDG_CACHE_HOME => '.artifacts/cache/unary-runtime/xdg',
);
require File::Path;
for my $name (sort keys %local) {
    File::Path::make_path($local{$name});
    $ENV{$name} = "$root/$local{$name}";
}
$ENV{FSMGEN_DARWIN_VERILATOR_TEST_RUNTIME} = 1;
my $result = supervise_process(
    schema => 'fsmgen.unary_observed_test_run.v1', stage => 'verification',
    bounds => {timeout_seconds => 600, capture_limit_bytes => 8_388_608},
    containment => 'unary_observed_test_group', cwd => $root,
    argv => ['prove','-v','docs/audits/unary-observer-20261022/observe.t','::','unary_oct22']);
my $record = FSM::Test::SourceQueryRunner::normalize_repository_paths(
    {result => $result, local_cache_environment => \%local},$root);
sysopen my $out, '.artifacts/tmp/unary-runtime-5dce0bc6a-20261022/outer.json',
    O_WRONLY | O_CREAT | O_EXCL, 0600 or die $!;
print {$out} JSON::PP->new->canonical->encode($record), "\n" or die $!;
close $out or die $!;
print "outer_ok=",0+!!$result->{ok}," status=$result->{status} exit=$result->{exit_code}\n";
print $result->{stdout};
print STDERR $result->{stderr};
exit($result->{ok} ? 0 : 1);
