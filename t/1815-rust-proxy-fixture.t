#!/usr/bin/env perl
use strict;
use warnings;

use Cwd qw(abs_path);
use Digest::SHA qw(sha256_hex);
use File::Spec;
use File::Temp ();
use JSON::PP ();
use POSIX ();
use Test::More;
use lib 'perl', 't/lib';
use FSM::ProjectDataLocality qw(ensure_project_artifact_dir repository_root);
use FSM::Test::ProjectDataLocality;
use FSM::Test::RustProxyFixture qw(prepare_rust_proxy);

my $root = repository_root();
my $parent = ensure_project_artifact_dir(qw(tmp process-supervisor-tests));
my $perl = abs_path($^X);
my $calls = 0;

sub workspace { return File::Temp->newdir('fsmgen-XXXXXXXX', DIR => $parent, CLEANUP => 1); }
sub read_bytes {
    my ($path) = @_;
    open my $fh, '<', $path or die "read $path: $!";
    binmode $fh;
    return do { local $/; <$fh> };
}
sub write_bytes {
    my ($path, $bytes) = @_;
    open my $fh, '>', $path or die "write $path: $!";
    binmode $fh;
    print {$fh} $bytes or die "write bytes: $!";
    close $fh or die "close bytes: $!";
}
sub native_selection {
    return {implementation => 'native', reason => 'controlled_native_model',
            compiler => '/controlled/compiler', sdk => '/controlled/sdk'};
}
sub compile_success {
    return {ok => 1, status => 'success', diagnostic => 'controlled compiler success',
            cleanup => {leader_reaped => 1, group_gone => 1}};
}
sub model_header { return pack('V8', 0xfeedfacf, 0x0100000c, 0, 2, 0, 0, 0, 0); }

subtest 'invalid callers cannot prepare or launch anything' => sub {
    my $work = workspace();
    no warnings 'redefine';
    local *FSM::Test::RustProxyFixture::supervise_process = sub { die 'unexpected process launch'; };
    for my $args ([], ["$work"], ["$work", 'other'], ["$work", 'proxy_nonzero', {}],
                  [[], 'proxy_nonzero'], [$root, 'proxy_nonzero']) {
        my $result = prepare_rust_proxy(@$args);
        ok(!$result->{ok}, 'invalid invocation rejects');
        ok(!-e "$work/rust-tools", 'rejection writes no fixture');
    }
    my $link = "$work/linked";
    symlink "$work", $link or die "symlink: $!";
    ok(!prepare_rust_proxy($link, 'proxy_nonzero')->{ok}, 'indirect workspace rejects');
};

subtest 'native selection is bounded and absence preserves portable controls' => sub {
    no warnings 'redefine';
    local *FSM::Test::RustProxyFixture::_installed_toolchain = sub { die 'unexpected tool lookup'; };
    for my $host (['linux', 'x86_64'], ['darwin', 'x86_64'], ['darwin', undef]) {
        my $selection = FSM::Test::RustProxyFixture::_select_toolchain(@$host);
        is($selection->{implementation}, 'perl', 'unqualified native platform keeps Perl');
    }
    {
        local *FSM::Test::RustProxyFixture::_installed_toolchain = sub { return (undef, undef); };
        my $selection = FSM::Test::RustProxyFixture::_select_toolchain('darwin', 'arm64');
        is($selection->{implementation}, 'perl', 'missing tools keep Perl');
        is($selection->{reason}, 'native_toolchain_unavailable', 'absence is explicit');
    }
    my $first = FSM::Test::RustProxyFixture::_selection();
    my $before = JSON::PP->new->canonical->encode($first);
    $first->{compiler} = '/changed/by/caller';
    is(JSON::PP->new->canonical->encode(FSM::Test::RustProxyFixture::_selection()),
       $before, 'caller cannot mutate the load-time selection');
};

subtest 'portable bodies retain exact semantics and immutable paths' => sub {
    no warnings 'redefine';
    local *FSM::Test::RustProxyFixture::_selection = sub {
        return {implementation => 'perl', reason => 'native_toolchain_unavailable'};
    };
    local *FSM::Test::RustProxyFixture::supervise_process = sub { die 'unexpected compiler'; };
    for my $mode (qw(proxy_nonzero proxy_decoy)) {
        my $work = workspace();
        my %environment = %ENV;
        my $result = prepare_rust_proxy("$work", $mode);
        ok($result->{ok}, "$mode prepared") or diag explain $result;
        is_deeply(\%ENV, \%environment, 'environment preserved');
        is($result->{implementation}, 'perl', 'portable implementation reported');
        is($result->{selection_reason}, 'native_toolchain_unavailable', 'reason retained');
        ok(!defined($result->{compilation}), 'no compiler attempted');
        my $body = $mode eq 'proxy_nonzero' ? "print STDERR qq(resolution-failed\\n); exit 9;\n"
                                          : "print qq(relative-cargo\\n);\n";
        my $proxy = "$work/rust-tools/rustup";
        is(read_bytes($proxy), "#!$perl\n$body", 'matches the original Perl body exactly');
        is((stat($proxy))[2] & 0777, 0500, 'executable is private and read-only');
        is($result->{sources}[0]{sha256}, sha256_hex(read_bytes($proxy)), 'retained hash matches bytes');
        ok(!File::Spec->file_name_is_absolute($result->{executable}), 'reported path is root-relative');
        ok(!prepare_rust_proxy("$work", $mode)->{ok}, 'existing mode cannot be overwritten');
        is(read_bytes($proxy), "#!$perl\n$body", 'repeat rejection preserves exact bytes');
    }
};

subtest 'native compiler policy excludes caller configuration and preserves custody' => sub {
    no warnings 'redefine';
    local *FSM::Test::RustProxyFixture::_selection = \&native_selection;
    local $ENV{CCC_OVERRIDE_OPTIONS} = '+-o/off-volume/trap';
    local $ENV{CPATH} = '/off-volume/headers';
    local $ENV{CFLAGS} = 'untrusted';
    for my $mode (qw(proxy_nonzero proxy_decoy)) {
        my $work = workspace();
        my %environment = %ENV;
        local *FSM::Test::RustProxyFixture::supervise_process = sub {
            my %request = @_;
            ++$calls;
            is_deeply($request{bounds}, {timeout_seconds => 10, capture_limit_bytes => 4096},
                      'compile wall and aggregate capture are sealed');
            is($request{argv}[0], '/controlled/compiler', 'selected canonical compiler used');
            ok(grep($_ eq '--no-default-config', @{$request{argv}}), 'default compiler configs disabled');
            ok(!exists($ENV{CCC_OVERRIDE_OPTIONS}) && !exists($ENV{CPATH}) && !exists($ENV{CFLAGS}),
               'caller compiler configuration does not cross the boundary');
            for my $key (qw(TMPDIR TMP TEMP XDG_CACHE_HOME CLANG_MODULE_CACHE_PATH)) {
                like($ENV{$key}, qr/\A\Q$work\E\/rust-tools\//, "$key stays in this fixture");
            }
            my $source = read_bytes("$work/rust-tools/rustup.c");
            like($source, $mode eq 'proxy_nonzero' ? qr/\A#define PROXY_NONZERO 1\n/
                                                 : qr/\A#define PROXY_NONZERO 0\n/,
                 'retained source carries the exact mode');
            write_bytes($request{argv}[-1], model_header());
            return compile_success();
        };
        my $result = prepare_rust_proxy("$work", $mode);
        ok($result->{ok}, 'controlled compiler artifact admitted') or diag explain $result;
        is_deeply(\%ENV, \%environment, 'compiler environment restoration is exact');
        is(scalar @{$result->{sources}}, 2, 'both C input and executable retained');
        is($result->{compilation_argv}[0], '/controlled/compiler', 'compiler command retained');
        is($result->{compilation_argv}[3], '/controlled/sdk', 'resolved read-only SDK retained');
        ok(!grep(index($_, "$root/") == 0, @{$result->{compilation_argv}}), 'project command paths are portable');
        for my $source (@{$result->{sources}}) {
            is($source->{sha256}, sha256_hex(read_bytes("$root/$source->{path}")), 'independent byte identity');
        }
    }
    is($calls, 2, 'one compiler invocation per selected mode');
};

subtest 'compiler failure never becomes a fallback or retry' => sub {
    no warnings 'redefine';
    local *FSM::Test::RustProxyFixture::_selection = \&native_selection;
    for my $outcome ('timeout', 'cleanup') {
        my $work = workspace();
        my $attempts = 0;
        my $failure = {ok => $outcome eq 'cleanup' ? 1 : 0,
            status => $outcome eq 'cleanup' ? 'success' : 'timed_out',
            diagnostic => 'first attempt failed', stderr => 'retained diagnostic',
            cleanup => {leader_reaped => 1, group_gone => $outcome eq 'cleanup' ? 0 : 1}};
        local *FSM::Test::RustProxyFixture::supervise_process = sub { ++$attempts; return $failure; };
        my %environment = %ENV;
        my $result = prepare_rust_proxy("$work", 'proxy_nonzero');
        ok(!$result->{ok}, 'failed build remains failed');
        is($result->{status}, $outcome eq 'cleanup' ? 'cleanup_failed' : 'timed_out', 'failure class preserved');
        is_deeply($result->{compilation}, $failure, 'complete first result retained');
        is_deeply(\%ENV, \%environment, 'failure restores caller environment');
        is($attempts, 1, 'no retry');
        ok(-f "$work/rust-tools/rustup.c" && !-e "$work/rust-tools/rustup", 'source retained without a Perl substitute');
    }
};

subtest 'inadmissible output and changed input cannot become success' => sub {
    no warnings 'redefine';
    local *FSM::Test::RustProxyFixture::_selection = \&native_selection;
    for my $kind (qw(short foreign_cpu foreign_subtype not_executable too_large directory symlink fifo source_changed missing)) {
        my $work = workspace();
        my $outside = "$work/untouched";
        write_bytes($outside, 'untouched');
        local *FSM::Test::RustProxyFixture::supervise_process = sub {
            my %request = @_;
            my $path = $request{argv}[-1];
            if ($kind eq 'directory') { mkdir $path or die $!; }
            elsif ($kind eq 'symlink') { symlink $outside, $path or die $!; }
            elsif ($kind eq 'fifo') { POSIX::mkfifo($path, 0600) == 0 or die $!; }
            elsif ($kind ne 'missing') {
                my $body = model_header();
                $body = 'bad' if $kind eq 'short';
                substr($body, 4, 4, pack('V', 0x01000007)) if $kind eq 'foreign_cpu';
                substr($body, 8, 4, pack('V', 2)) if $kind eq 'foreign_subtype';
                substr($body, 12, 4, pack('V', 1)) if $kind eq 'not_executable';
                $body = 'x' x 65_537 if $kind eq 'too_large';
                write_bytes($path, $body);
                if ($kind eq 'source_changed') {
                    chmod 0600, "$work/rust-tools/rustup.c" or die $!;
                    write_bytes("$work/rust-tools/rustup.c", 'changed source');
                }
            }
            return compile_success();
        };
        my $result = prepare_rust_proxy("$work", 'proxy_decoy');
        ok(!$result->{ok}, "$kind rejects") or diag explain $result;
        is($result->{failure_stage}, 'artifact_admission', 'failure is attributed before execution');
        is(read_bytes($outside), 'untouched', 'unrelated bytes preserved');
    }
};

subtest 'replaced output cannot redirect permissions or receive a success result' => sub {
    no warnings 'redefine';
    my $read = \&FSM::Test::RustProxyFixture::_read_file;
    for my $implementation (qw(native perl)) {
        my $work = workspace();
        my $proxy = "$work/rust-tools/rustup";
        my $victim = "$work/untouched";
        write_bytes($victim, 'unrelated');
        chmod 0600, $victim or die $!;
        my $replaced = 0;
        local *FSM::Test::RustProxyFixture::_selection = sub {
            return $implementation eq 'native' ? native_selection()
                : {implementation => 'perl', reason => 'controlled_portable_model'};
        };
        local *FSM::Test::RustProxyFixture::supervise_process = sub {
            my %request = @_;
            write_bytes($request{argv}[-1], model_header());
            return compile_success();
        };
        local *FSM::Test::RustProxyFixture::_read_file = sub {
            my @result = $read->(@_);
            if ($_[0] eq $proxy && !$replaced++) {
                rename $proxy, "$proxy.saved" or die $!;
                symlink $victim, $proxy or die $!;
            }
            return @result;
        };
        my $result = prepare_rust_proxy("$work", 'proxy_nonzero');
        ok(!$result->{ok}, "$implementation replacement rejects success");
        is((stat($victim))[2] & 0777, 0600, 'unrelated permissions unchanged');
        is(read_bytes($victim), 'unrelated', 'unrelated bytes unchanged');
    }
};

done_testing();
