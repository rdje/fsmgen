package FSM::Test::RustProxyFixture;

use strict;
use warnings;

use Cwd qw(abs_path);
use Digest::SHA qw(sha256_hex);
use Exporter qw(import);
use Fcntl qw(O_CREAT O_EXCL O_NOFOLLOW O_NONBLOCK O_RDONLY O_WRONLY S_ISREG);
use File::Basename qw(basename dirname);
use File::Spec;
use POSIX ();
use FSM::Test::ProcessSupervisor qw(repository_contained_path repository_root supervise_process);

our @EXPORT_OK = qw(prepare_rust_proxy);

my $ROOT = repository_root();
my $PARENT = File::Spec->catdir($ROOT, qw(.artifacts tmp process-supervisor-tests));
my $SOURCE = File::Spec->catfile($ROOT, qw(t fixtures rust-tool-proxy.c));
my $PERL = abs_path($^X);
my $LIMIT = 65_536;
my $SELECTION = _select_toolchain($^O, (POSIX::uname())[4]);

# The caller owns the workspace lifetime. It must retain it on unproved process
# cleanup, and keep it unchanged while the wrapper or diagnostic observer runs.
# No compiler, interpreter, flags, deadlines or cache locations are caller options.
sub prepare_rust_proxy {
    my ($workspace, $mode, @extra) = @_;
    my $result = {
        schema => 'fsmgen.test.rust_proxy_fixture.v1', ok => 0,
        status => 'invocation_error', failure_stage => 'invocation',
        diagnostic => '', implementation => undef, selection_reason => undef,
        executable => undef, sources => [], compilation => undef, compilation_argv => undef,
    };
    return _failure($result, 'invocation', 'expected one owned workspace and one fixed proxy mode')
        if @extra || !defined($workspace) || ref($workspace) || !defined($mode) || ref($mode)
            || ($mode ne 'proxy_nonzero' && $mode ne 'proxy_decoy');

    my $phase = 'workspace';
    my $completed = eval {
        my ($absolute, $error) = repository_contained_path($workspace, must_exist => 1);
        die "$error\n" if defined $error;
        die "workspace must be one direct private process-supervisor test directory\n"
            unless dirname($absolute) eq $PARENT && basename($absolute) =~ /\Afsmgen-[A-Za-z0-9_]+\z/;
        my @metadata = stat($absolute);
        die "workspace must be an owned private directory\n"
            unless -d $absolute && @metadata && $metadata[4] == $< && !($metadata[2] & 0077);
        my $bin = File::Spec->catdir($absolute, 'rust-tools');
        mkdir($bin, 0700) or die "cannot exclusively create proxy directory: $!\n";
        my $proxy = File::Spec->catfile($bin, 'rustup');
        my $selection = _selection();
        $result->{implementation} = $selection->{implementation};
        $result->{selection_reason} = $selection->{reason};
        $phase = 'source';
        if ($selection->{implementation} eq 'perl') {
            die "selected Perl cannot be used in a direct shebang\n"
                unless defined($PERL) && -f $PERL && -x $PERL && $PERL !~ /[\s\x00]/;
            my $body = $mode eq 'proxy_nonzero'
                ? 'print STDERR qq(resolution-failed\n); exit 9;' . "\n"
                : 'print qq(relative-cargo\n);' . "\n";
            _write_exclusive($proxy, "#!$PERL\n" . $body);
        }
        else {
            my ($source) = _read_file($SOURCE);
            # Each retained C file contains its mode; reconstructing the chosen
            # source does not depend on an unavailable compiler command line.
            $source = '#define PROXY_NONZERO ' . ($mode eq 'proxy_nonzero' ? 1 : 0) . "\n" . $source;
            die "generated proxy source exceeds custody bound\n" if length($source) > $LIMIT;
            my $input = File::Spec->catfile($bin, 'rustup.c');
            _write_exclusive($input, $source);
            my $source_identity = _identity($input);
            push @{$result->{sources}}, $source_identity;
            my $temporary = File::Spec->catdir($bin, 'compiler-temp');
            my $cache = File::Spec->catdir($bin, 'compiler-cache');
            mkdir($_, 0700) or die "cannot exclusively create compiler storage: $!\n"
                for ($temporary, $cache);
            $phase = 'compile';
            {
                # Exclude caller compiler flags/configuration and off-volume
                # caches. HOME is neither repurposed nor needed by this command.
                local %ENV = (
                    PATH => dirname($selection->{compiler}) . ':/usr/bin:/bin',
                    LC_ALL => 'C', LANG => 'C',
                    TMPDIR => $temporary, TMP => $temporary, TEMP => $temporary,
                    XDG_CACHE_HOME => $cache, CLANG_MODULE_CACHE_PATH => $cache,
                );
                my @argv = ($selection->{compiler}, '--no-default-config',
                    '-isysroot', $selection->{sdk}, '-arch', 'arm64',
                    '-mmacosx-version-min=11.0', '-O2', '-Wall', '-Wextra', '-Werror',
                    '-fno-builtin', '-fno-modules', $input, '-o', $proxy);
                # Project paths are portable; installed OS/toolchain inputs are
                # explicit read-only dependencies, retained at their native paths.
                $result->{compilation_argv} = [map {
                    index($_, "$ROOT/") == 0 ? File::Spec->abs2rel($_, $ROOT) : $_
                } @argv];
                $result->{compilation} = supervise_process(
                    schema => 'fsmgen.test.rust_proxy_compilation.v1',
                    stage => 'compile_proxy',
                    bounds => {timeout_seconds => 10, capture_limit_bytes => 4096},
                    containment => 'rust_proxy_compiler_group', cwd => $ROOT,
                    argv => \@argv,
                );
            }
            my $compilation = $result->{compilation};
            if (!$compilation->{ok} || !$compilation->{cleanup}{leader_reaped}
                    || !$compilation->{cleanup}{group_gone}) {
                _failure($result, 'compile', $compilation->{diagnostic});
                $result->{status} = $compilation->{ok} ? 'cleanup_failed' : $compilation->{status};
                return $result;
            }
            $phase = 'artifact_admission';
            _unchanged($input, $source_identity);
        }
        $phase = 'artifact_admission';
        push @{$result->{sources}}, _seal_executable($proxy, $selection->{implementation});
        _unchanged(File::Spec->catfile($ROOT, $_->{path}), $_) for @{$result->{sources}};
        $result->{executable} = File::Spec->abs2rel($proxy, $ROOT);
        $result->{status} = 'success';
        $result->{failure_stage} = undef;
        $result->{diagnostic} = 'immutable proxy fixture prepared';
        $result->{ok} = 1;
        1;
    };
    return _failure($result, $phase, $@ || 'fixture preparation did not finish') unless $completed;
    return $result;
}

sub _failure {
    my ($result, $stage, $message) = @_;
    $message //= 'fixture preparation failed';
    $message =~ s/\Q$ROOT\E/./g;
    $result->{ok} = 0;
    $result->{failure_stage} = $stage;
    $result->{diagnostic} = substr($message, 0, 2048);
    return $result;
}

sub _select_toolchain {
    my ($os, $machine) = @_;
    return {implementation => 'perl', reason => 'unqualified_native_platform'}
        unless $os eq 'darwin' && defined($machine) && $machine eq 'arm64';
    # Required installed OS/toolchain inputs are read-only; do not invoke xcrun
    # or a PATH-selected wrapper, and do not download a toolchain for this test.
    my ($compiler, $sdk) = _installed_toolchain();
    return {implementation => 'perl', reason => 'native_toolchain_unavailable'}
        unless defined($compiler) && -f $compiler && -x $compiler
            && defined($sdk) && -d $sdk;
    return {implementation => 'native', reason => 'darwin_arm64_command_line_tools',
            compiler => $compiler, sdk => $sdk};
}

sub _installed_toolchain {
    return (abs_path('/Library/Developer/CommandLineTools/usr/bin/clang'),
            abs_path('/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk'));
}

sub _selection { return {%$SELECTION}; }

sub _write_exclusive {
    my ($path, $body) = @_;
    my (undef, $error) = repository_contained_path($path);
    die "$error\n" if defined $error;
    sysopen(my $fh, $path, O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW, 0400)
        or die "cannot exclusively create fixture source: $!\n";
    binmode($fh);
    print {$fh} $body or die "cannot write fixture source: $!\n";
    close($fh) or die "cannot close fixture source: $!\n";
}

sub _read_file {
    my ($path, $keep_open) = @_;
    my ($absolute, $error) = repository_contained_path($path, must_exist => 1);
    die "$error\n" if defined $error;
    sysopen(my $fh, $absolute, O_RDONLY | O_NOFOLLOW | O_NONBLOCK) or die "cannot read fixture: $!\n";
    binmode($fh);
    my @before = stat($fh);
    die "fixture must be an owned bounded regular file\n"
        unless @before && S_ISREG($before[2]) && $before[4] == $<
            && $before[0] == (stat($ROOT))[0] && $before[7] <= $LIMIT;
    my $body = '';
    while (length($body) <= $LIMIT) {
        my $count = sysread($fh, my $chunk, $LIMIT + 1 - length($body));
        die "cannot read fixture bytes: $!\n" unless defined $count;
        last unless $count;
        $body .= $chunk;
    }
    my @after = stat($fh);
    my @named = lstat($absolute);
    die "fixture changed during its bounded read\n"
        unless @after && @named && length($body) == $before[7] && length($body) <= $LIMIT
            && join(':', @before[0,1,2,4,7,9,10]) eq join(':', @after[0,1,2,4,7,9,10])
            && join(':', @before[0,1,2,4,7,9,10]) eq join(':', @named[0,1,2,4,7,9,10]);
    close($fh) or die "cannot close fixture: $!\n" unless $keep_open;
    return ($body, \@before, $keep_open ? $fh : undef);
}

sub _seal_executable {
    my ($path, $implementation) = @_;
    my ($bytes, $before, $fh) = _read_file($path, 1);
    my $sealed = eval {
        # Header/architecture admission is separate from native behavior and
        # compiler attestation. The same open inode supplies the bytes and chmod.
        if ($implementation eq 'native') {
            die "compiler output has no complete Mach-O header\n" unless length($bytes) >= 32;
            my ($magic, $cpu, $subtype, $type) = unpack('V4', substr($bytes, 0, 16));
            die "compiler output is not a bounded arm64 Mach-O executable\n"
                unless $magic == 0xfeedfacf && $cpu == 0x0100000c && $subtype == 0 && $type == 2;
        }
        chmod(0500, $fh) == 1 or die "cannot seal proxy permissions: $!\n";
        my @named = lstat($path);
        die "proxy path changed during permission sealing\n"
            unless @named && $named[0] == $before->[0] && $named[1] == $before->[1]
                && S_ISREG($named[2]) && ($named[2] & 07777) == 0500;
        1;
    };
    my $error = $@;
    my $closed = close($fh);
    die $error unless $sealed;
    die "cannot close sealed proxy: $!\n" unless $closed;
    return {path => File::Spec->abs2rel($path, $ROOT), sha256 => sha256_hex($bytes),
            size_bytes => length($bytes), device => $before->[0], inode => $before->[1]};
}

sub _identity {
    my ($path) = @_;
    my ($body, $metadata) = _read_file($path);
    return {path => File::Spec->abs2rel($path, $ROOT), sha256 => sha256_hex($body),
            size_bytes => length($body), device => $metadata->[0], inode => $metadata->[1]};
}

sub _unchanged {
    my ($path, $before) = @_;
    my $after = _identity($path);
    die "retained fixture changed during preparation\n"
        if grep { $before->{$_} ne $after->{$_} } keys %$before;
}

1;
