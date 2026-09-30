use strict;
use warnings;
use Cwd qw(abs_path);
use File::Spec;
use Test::More;
use lib 'perl', 't/lib';
use FSM::ProjectDataLocality qw(create_project_tempdir repository_root);
use FSM::Test::ProjectDataLocality;
use FSM::Test::RamGuardFixtureRuntime qw(prepare_ram_guard_fixture);
use FSM::Test::SourceQueryRunner;

my $root = repository_root();
my $workspace = create_project_tempdir(purpose => 'ram-guard-tests');
prepare_ram_guard_fixture($workspace);
my $perl = abs_path($^X);
my $guard = File::Spec->catfile($root, 'scripts', 'run_with_ram_guard.sh');
my $sample = File::Spec->catfile($workspace, 'healthy.vm_stat');
write_file($sample, <<'SAMPLE');
Mach Virtual Memory Statistics: (page size of 4096 bytes)
Pages active: 400.
Pages inactive: 300.
Pages speculative: 20.
Pages wired down: 100.
Pages purgeable: 20.
File-backed pages: 300.
Pages occupied by compressor: 50.
SAMPLE
my @tools = File::Spec->path();
my $bash = (grep { -f $_ && -x $_ } map { File::Spec->catfile($_, 'bash') } @tools)[0];
die 'Bash unavailable' unless defined $bash;
$bash = abs_path($bash);
my $payload = "guarded-input\n" . pack('C*', 0, 255, 1, 13, 10) . ('q' x 1024);
my $echo = 'binmode STDIN; binmode STDOUT; local $/; print scalar(<STDIN>) // q();';

sub capture {
    my ($argv, $input) = @_;
    local %ENV = %ENV;
    delete @ENV{grep { /\ABASH_FUNC_/ } keys %ENV};
    delete @ENV{qw(BASH_ENV ENV SHELLOPTS BASHOPTS CDPATH GLOBIGNORE)};
    $ENV{PATH} = join(':', File::Spec->catdir($workspace, 'fake-bin'), @tools);
    $ENV{FSMGEN_TEST_TOTAL_BYTES} = 4_096_000;
    $ENV{FSMGEN_TEST_VM_STAT_FILE} = $sample;
    return FSM::Test::SourceQueryRunner::_capture($argv, $input);
}

sub command {
    my ($script, $shell, @child) = @_;
    return [$shell, $script, '--host-max-pct', '88', '--process-max-rss-mb', '4096',
        '--poll-seconds', '0.02', '--grace-seconds', '0', '--', @child];
}

subtest 'piped bytes and an EOF-only stream preserve exact stdin' => sub {
    my $result = capture(command($guard, $bash, $perl, '-e', $echo), $payload);
    is($result->{exit_code}, 0, 'guard completes the admitted child');
    is($result->{stdout}, $payload, 'binary, newline and complete payload bytes survive');
    like($result->{stderr}, qr/host 55[.]0%; host cutoff 88%; descendant RSS cutoff 4096 MiB/,
        'independent fixture preserves the complete guard envelope');
    my $empty = capture(command($guard, $bash, $perl, '-e', 'local $/; print length(scalar(<STDIN>) // q()), qq(\n);'), '');
    is($empty->{exit_code}, 0, 'no-input command completes');
    is($empty->{stdout}, "0\n", 'empty stdin remains EOF');
};

subtest 'a program supplied on stdin executes and preserves nonzero exit' => sub {
    my $result = capture(command($guard, $bash, $perl, '-'), 'print qq(stdin-program-ran\n); exit 17;');
    is($result->{stdout}, "stdin-program-ran\n", 'actual stdin-fed program executes');
    is($result->{exit_code}, 17, 'child nonzero exit remains exact');
    is($result->{signal}, 0, 'nonzero exit is not fabricated as a signal');
};

subtest 'file stdin and inherited descriptor three are independent' => sub {
    my $file = File::Spec->catfile($workspace, 'stdin-payload');
    write_file($file, $payload);
    my $argv = command($guard, $bash, $perl, '-e', $echo);
    my $result = capture([$bash, '-c', 'guard_input=$1; shift; exec "$@" < "$guard_input"',
                         'guard-file-stdin', $file, @$argv], '');
    is($result->{exit_code}, 0, 'file-directed command completes');
    is($result->{stdout}, $payload, 'the original file stream reaches the child');
    my $fd_file = File::Spec->catfile($workspace, 'fd3-payload');
    write_file($fd_file, 'independent-fd3');
    my $body = 'binmode STDIN; local $/; my $input=<STDIN> // q(); open my $fd, q(<&=3) or die $!; print $input, q(:), scalar(<$fd>);';
    $argv = command($guard, $bash, $perl, '-e', $body);
    my $fd = capture([$bash, '-c', 'guard_fd3=$1; shift; exec 3< "$guard_fd3"; exec "$@"',
                      'guard-inherited-fd', $fd_file, @$argv], 'stdin');
    is($fd->{exit_code}, 0, 'inherited-descriptor command completes');
    is($fd->{stdout}, 'stdin:independent-fd3', 'forwarding stdin does not overwrite descriptor three');
};

subtest 'the system Bash accepts the same forwarding syntax' => sub {
    my $system = '/bin/bash';
    plan skip_all => 'system Bash unavailable' unless -f $system && -x $system;
    my $result = capture(command($guard, $system, $perl, '-e', $echo), 'system-bash-stdin');
    is($result->{exit_code}, 0, 'system Bash completes');
    is($result->{stdout}, 'system-bash-stdin', 'system Bash preserves stdin without newer descriptor syntax');
};

subtest 'exact committed predecessor independently reproduces silent loss' => sub {
    my $old = File::Spec->catdir($workspace, 'old-launcher');
    mkdir $old or die $!;
    for my $name ('run_with_ram_guard.sh', 'project_data_locality_env.sh') {
        my $result = FSM::Test::SourceQueryRunner::_capture([
            'git', '--no-replace-objects', '-C', $root, 'show',
            'ce4d0029028a3e25f517ea93632cf50f2712354a:scripts/' . $name], '');
        is($result->{exit_code}, 0, 'exact source capsule is independently recovered');
        write_file(File::Spec->catfile($old, $name), $result->{stdout});
    }
    my $result = capture(command(File::Spec->catfile($old, 'run_with_ram_guard.sh'), $bash, $perl, '-e', $echo), $payload);
    is($result->{exit_code}, 0, 'old guard produces misleading success');
    is($result->{stdout}, '', 'old committed guard loses every supplied byte');
    like($result->{stderr}, qr/host 55[.]0%; host cutoff 88%/, 'old oracle actually entered the guard');
};

done_testing();

sub write_file {
    my ($path, $bytes) = @_;
    open my $fh, '>:raw', $path or die $!;
    print {$fh} $bytes or die $!;
    close $fh or die $!;
}
