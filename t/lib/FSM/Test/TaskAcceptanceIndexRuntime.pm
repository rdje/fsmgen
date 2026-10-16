package FSM::Test::TaskAcceptanceIndexRuntime;

use strict;
use warnings;

use Cwd qw(abs_path);
use Config ();
use Digest::SHA qw(sha256_hex);
use Exporter qw(import);
use Fcntl qw(O_WRONLY O_CREAT O_EXCL);
use File::Basename qw(dirname);
use File::Path qw(make_path remove_tree);
use File::Spec;
use File::Temp ();

use FSM::ProjectDataLocality qw(ensure_project_artifact_dir);
use FSM::Test::ProcessSupervisor qw(
    repository_contained_path repository_root supervise_process
);

our @EXPORT_OK = qw(run_index_case);

my $ROOT = repository_root();
my $GIT = _executable('git');
my $BASH = _executable('bash');
my @TOOL_PATH = grep { File::Spec->file_name_is_absolute($_) } File::Spec->path();
my $SCHEMA = 'fsmgen.test.task_acceptance_index_case.v1';
my %CASES = (
    documentation => ['README.md', 'unchecked'],
    existing_source => ['perl/TaskAcceptanceIndexFixture.pm', 'none'],
    fresh_owner => ['perl/TaskAcceptanceIndexFixture.pm', 'fresh'],
    unchecked_owner => ['perl/TaskAcceptanceIndexFixture.pm', 'unchecked'],
    stale_owner => ['perl/TaskAcceptanceIndexFixture.pm', 'stale'],
    (map { ('audit_' . $_) => ['docs/audits/acceptance-index-fixture/source.' . $_, 'unchecked'] }
        qw(py pl pm sh c t)),
    (map {
        my $extension = $_;
        map {
            ('audit_' . $extension . '_' . $_) =>
                ['docs/audits/acceptance-index-fixture/source.' . $extension, $_]
        } qw(fresh none stale)
    } qw(py pl pm sh c t)),
    audit_document_md => ['docs/audits/acceptance-index-fixture/notes.md', 'none'],
    audit_document_json => ['docs/audits/acceptance-index-fixture/receipt.json', 'none'],
    audit_document_txt => ['docs/audits/acceptance-index-fixture/notes.txt', 'none'],
    audit_source_suffix_md => ['docs/audits/acceptance-index-fixture/source.py.md', 'none'],
    audit_neighbor_prefix => ['docs/audit-notes/source.py', 'none'],
    audit_nested_py => ['docs/audits/acceptance-index-fixture/nested/source.py', 'none'],
    audit_document_md_unchecked => ['docs/audits/acceptance-index-fixture/notes.md', 'unchecked'],
    audit_document_json_unchecked => ['docs/audits/acceptance-index-fixture/receipt.json', 'unchecked'],
    audit_document_txt_unchecked => ['docs/audits/acceptance-index-fixture/notes.txt', 'unchecked'],
    audit_source_suffix_md_unchecked => ['docs/audits/acceptance-index-fixture/source.py.md', 'unchecked'],
    audit_neighbor_prefix_unchecked => ['docs/audit-notes/source.py', 'unchecked'],
    audit_nested_py_unchecked => ['docs/audits/acceptance-index-fixture/nested/source.py', 'unchecked'],
);

sub run_index_case {
    my ($case, @extra) = @_;
    my $record = {
        schema => $SCHEMA, case => !ref($case) ? $case : undef,
        stages => [], invocations => [], checker => undef, workspace => undef,
        status => 'invocation_error', diagnostic => '',
        cleanup => { retired => 0, retained => 0 },
    };
    unless (!@extra && defined($case) && !ref($case) && exists $CASES{$case}) {
        $record->{diagnostic} = 'expected one sealed acceptance-index case name';
        return $record;
    }
    unless (defined($GIT) && defined($BASH)) {
        $record->{diagnostic} = 'canonical Git and Bash executables are required';
        return $record;
    }

    my $parent = File::Spec->catdir($ROOT, qw(.artifacts tmp task-acceptance-index-tests));
    my ($contained_parent, $parent_error) = repository_contained_path($parent);
    if (defined $parent_error) {
        $record->{diagnostic} = "index workspace is invalid: $parent_error";
        return $record;
    }
    my $directory = ensure_project_artifact_dir(qw(tmp task-acceptance-index-tests));
    my $workspace = File::Temp::tempdir('fsmgen-XXXXXXXX', DIR => $directory, CLEANUP => 0);
    $record->{workspace} = File::Spec->abs2rel($workspace, $ROOT);
    my $index = File::Spec->catfile($workspace, 'index');
    my $hooks = File::Spec->catdir($workspace, 'hooks');
    make_path($hooks);
    my %environment = %ENV;
    delete @environment{grep { /\A(?:GIT_|BASH_FUNC_)/ } keys %environment};
    delete @environment{qw(BASH_ENV ENV SHELLOPTS BASHOPTS)};
    $environment{PATH} = join($Config::Config{path_sep}, dirname($GIT), dirname($BASH), @TOOL_PATH);
    $environment{GIT_CONFIG_NOSYSTEM} = '1';
    $environment{GIT_CONFIG_GLOBAL} = File::Spec->devnull();
    $environment{GIT_INDEX_FILE} = $index;
    $environment{GIT_CONFIG_COUNT} = '2';
    $environment{GIT_CONFIG_KEY_0} = 'core.hooksPath';
    $environment{GIT_CONFIG_VALUE_0} = $hooks;
    $environment{GIT_CONFIG_KEY_1} = 'core.fsmonitor';
    $environment{GIT_CONFIG_VALUE_1} = 'false';
    $environment{TMPDIR} = $workspace;
    $environment{TMP} = $workspace;
    $environment{TEMP} = $workspace;
    my $git = sub {
        my (@arguments) = @_;
        my $command = [$GIT, '-C', $ROOT, '-c', 'core.hooksPath=' . $hooks, @arguments];
        push @{$record->{invocations}}, $command;
        my $result = supervise_process(
            schema => 'fsmgen.test.task_acceptance_index_git.v1',
            stage => 'index_git', containment => 'task_acceptance_index_group',
            bounds => { timeout_seconds => 10, capture_limit_bytes => 1_048_576 },
            cwd => $ROOT, environment => \%environment,
            argv => $command,
        );
        push @{$record->{stages}}, $result;
        die "fixture Git failed: $result->{diagnostic}\n" unless $result->{ok};
        return $result->{stdout};
    };
    my $main_index;
    eval {
        my $git_dir = $git->('rev-parse', '--absolute-git-dir');
        chomp $git_dir;
        my ($contained, $error) = repository_contained_path($git_dir, must_exist => 1);
        die "Git metadata is outside the project boundary: $error\n" if defined $error;
        die "Git metadata must be a directory\n" unless -d $contained;
        $main_index = File::Spec->catfile($contained, 'index');
        $record->{main_index_before} = _pin(_read($main_index, 67_108_864));
        my $revision = $git->('rev-parse', 'HEAD');
        chomp $revision;
        $record->{revision} = $revision;
        $git->('read-tree', 'HEAD');

        my $number = 0;
        my $stage = sub {
            my ($path, $body) = @_;
            my $payload = File::Spec->catfile($workspace, 'blob-' . ++$number);
            sysopen my $stream, $payload, O_WRONLY | O_CREAT | O_EXCL, 0600
                or die "cannot create index fixture payload: $!\n";
            binmode $stream;
            print {$stream} $body or die "cannot write index fixture payload: $!\n";
            close $stream or die "cannot close index fixture payload: $!\n";
            my $relative = File::Spec->abs2rel($payload, $ROOT);
            my $oid = $git->('hash-object', '-w', '--no-filters', '--', $relative);
            chomp $oid;
            die "invalid fixture object identity\n"
                unless $oid =~ /\A(?:[0-9a-f]{40}|[0-9a-f]{64})\z/;
            push @{$record->{inputs}}, { path => $path, body => $body, identity => _pin($body) };
            $git->('update-index', '--add', '--cacheinfo', "100644,$oid,$path");
        };
        my $registry_path = 'doctrine/task_acceptance/change_paths.tsv';
        my $registry = _read(File::Spec->catfile($ROOT, split m{/}, $registry_path), 65_536);
        $stage->($registry_path, $registry);
        my ($candidate, $owner) = @{$CASES{$case}};
        $stage->($candidate, "# owned index fixture\n");
        if ($owner eq 'fresh' || $owner eq 'unchecked') {
            my $checked = $owner eq 'fresh' ? 'x' : ' ';
            my $task = "# Index acceptance fixture\n\n"
                . "- [$checked] **ROOT CAUSE (WHY + WHERE)** — git log -S fixture locates the fixture.\n"
                . "- [$checked] **ADDRESSED (verified)** — fixture input exercises evidence shape only.\n"
                . "- [$checked] **NO REGRESSION** — All tests successful (fixture signature).\n";
            $stage->('docs/tasks/INDEX-ACCEPTANCE-FIXTURE.md', $task);
        }
        elsif ($owner eq 'stale') {
            my $task_path = 'docs/tasks/TASK-ACCEPTANCE-PORTABLE-DOCTRINE.md';
            my $task = $git->('show', 'HEAD:' . $task_path);
            die "stale fixture baseline has no checked cause box\n"
                unless $task =~ /^- \[x\] \*\*ROOT CAUSE/m;
            $stage->($task_path, $task . "\nIndex fixture changes only this unrelated note.\n");
        }
        my $paths = $git->('diff', '--cached', '--name-only', '-z');
        $record->{staged_paths} = [grep { length } split /\0/, $paths];
        $record->{registry_co_staged} = (grep { $_ eq $registry_path } @{$record->{staged_paths}}) ? 1 : 0;
        my $checker_path = File::Spec->catfile($ROOT, 'scripts', 'check_task_acceptance.sh');
        my ($checker, $checker_error) = repository_contained_path($checker_path, must_exist => 1);
        die "checker path is invalid: $checker_error\n" if defined $checker_error;
        die "checker must be a readable regular file\n" unless -f $checker && -r $checker;
        $record->{checker_invocation} = [$BASH, $checker];
        $record->{checker} = supervise_process(
            schema => 'fsmgen.test.task_acceptance_index_checker.v1',
            stage => 'index_checker', containment => 'task_acceptance_index_group',
            bounds => { timeout_seconds => 10, capture_limit_bytes => 4_194_304 },
            cwd => $ROOT, environment => \%environment, argv => $record->{checker_invocation},
        );
        $record->{status} = 'checker_returned';
        1;
    } or do {
        $record->{status} = 'preparation_failed';
        $record->{diagnostic} = "$@";
    };
    if (defined($main_index)) {
        my $after = eval { _pin(_read($main_index, 67_108_864)) };
        $record->{main_index_after} = $after;
        $record->{main_index_conserved} = defined($after)
            && $after->{sha256} eq $record->{main_index_before}{sha256}
            && $after->{bytes} == $record->{main_index_before}{bytes} ? 1 : 0;
    }
    my @processes = (@{$record->{stages}}, defined($record->{checker}) ? $record->{checker} : ());
    my $settled = !grep { !$_->{cleanup}{leader_reaped} || !$_->{cleanup}{group_gone} } @processes;
    if ($settled) {
        my $errors;
        remove_tree($workspace, { error => \$errors });
        $record->{cleanup}{retired} = !-e $workspace ? 1 : 0;
        $record->{cleanup}{errors} = $errors if $errors && @$errors;
    }
    $record->{cleanup}{retained} = -e $workspace ? 1 : 0;
    return $record;
}

sub _read {
    my ($path, $limit) = @_;
    my ($contained, $error) = repository_contained_path($path, must_exist => 1);
    die "fixture input path is invalid: $error\n" if defined $error;
    die "fixture input must be a bounded readable regular file\n"
        unless -f $contained && -r $contained && -s $contained <= $limit;
    open my $stream, '<:raw', $contained or die "cannot open fixture input: $!\n";
    local $/;
    my $body = <$stream>;
    $body = '' unless defined $body;
    close $stream or die "cannot close fixture input: $!\n";
    die "fixture input exceeds its read ceiling\n" if length($body) > $limit;
    return $body;
}

sub _pin {
    my ($body) = @_;
    return { bytes => length($body), sha256 => sha256_hex($body) };
}

sub _executable {
    my ($name) = @_;
    for my $directory (File::Spec->path()) {
        next unless File::Spec->file_name_is_absolute($directory);
        my $path = File::Spec->catfile($directory, $name);
        next unless -f $path && -x $path;
        my $resolved = abs_path($path);
        return $resolved if defined($resolved) && -f $resolved && -x $resolved;
    }
    return undef;
}

1;
