package NativeProxyCompilerProfile;

use strict;
use warnings;
use File::Basename qw(dirname);
use Digest::SHA qw(sha256_hex);
use JSON::PP ();

my $JSON = JSON::PP->new->canonical->ascii;

sub metadata_projection {
    my ($capture) = @_;
    return [map {
        my %row = %$_;
        if ($row{kind} eq 'file') {
            $row{size_bytes} = length($row{bytes});
            $row{sha256} = sha256_hex(delete $row{bytes});
        }
        \%row;
    } @{$capture->{nodes}}];
}

sub expected_request {
    my ($root, $workspace, $selection) = @_;
    my $tools = "$root/$workspace/rust-tools";
    return {schema => 'fsmgen.test.rust_proxy_compilation.v1', stage => 'compile_proxy',
        bounds => {timeout_seconds => 10, capture_limit_bytes => 4096},
        containment => 'rust_proxy_compiler_group', cwd => $root,
        argv => [$selection->{compiler}, '--no-default-config', '-isysroot', $selection->{sdk},
                 '-arch', 'arm64', '-mmacosx-version-min=11.0', '-O2', '-Wall', '-Wextra',
                 '-Werror', '-fno-builtin', '-fno-modules', "$tools/rustup.c", '-o', "$tools/rustup"]};
}

sub expected_environment {
    my ($root, $workspace, $selection) = @_;
    my $tools = "$root/$workspace/rust-tools";
    return {PATH => dirname($selection->{compiler}) . ':/usr/bin:/bin', LC_ALL => 'C', LANG => 'C',
        TMPDIR => "$tools/compiler-temp", TMP => "$tools/compiler-temp", TEMP => "$tools/compiler-temp",
        XDG_CACHE_HOME => "$tools/compiler-cache", CLANG_MODULE_CACHE_PATH => "$tools/compiler-cache"};
}

sub validate_request {
    my ($request, $environment, $root, $workspace, $selection) = @_;
    die "compiler workspace is outside the fixed profile domain\n"
        unless $workspace =~ m{\A\.artifacts/tmp/process-supervisor-tests/fsmgen-CompilerProfile20260913_(?:nonzero|decoy)\z};
    die "compiler selection is not native\n" unless $selection->{implementation} eq 'native';
    die "compiler request differs from the admitted original\n"
        unless $JSON->encode($request) eq $JSON->encode(expected_request($root, $workspace, $selection));
    die "compiler environment differs from the admitted original\n"
        unless $JSON->encode($environment) eq $JSON->encode(expected_environment($root, $workspace, $selection));
}

sub state_receipt {
    my ($state, $result) = @_;
    return {state_observed => 0, settled => 0, result => $result} unless defined $state;
    my $finished = $state->{phase} eq 'finished';
    my $same_result = $finished && $JSON->encode($state->{result}) eq $JSON->encode($result);
    my $raw = $state->{leader_status};
    my $raw_matches = defined($raw) && !ref($raw) && $raw =~ /\A[0-9]+\z/
        && defined($result->{signal}) && $result->{signal} == ($raw & 127)
        && (($raw & 127) ? !defined($result->{exit_code})
            : defined($result->{exit_code}) && $result->{exit_code} == ($raw >> 8));
    my $cleanup = $result->{cleanup};
    my $settled = $same_result && defined($state->{pid}) && $state->{pid} > 0
        && $state->{leader_reaped} && defined($state->{leader_status})
        && $raw_matches
        && $cleanup->{leader_started} && $cleanup->{leader_reaped} && $cleanup->{group_gone};
    return {state_observed => 1, phase => $state->{phase}, pid => $state->{pid},
        leader_reaped => $state->{leader_reaped} ? 1 : 0, native_wait_status => $state->{leader_status},
        original_result_equal => $same_result ? 1 : 0, raw_result_equal => $raw_matches ? 1 : 0,
        settled => $settled ? 1 : 0,
        result => $result,
        ownership_scope => 'original direct fork and wait state; not loaded-image or general receipt authentication'};
}

sub observe {
    my ($invoke, $request, $environment, $root, $workspace, $selection) = @_;
    validate_request($request, $environment, $root, $workspace, $selection);
    my $start = \&FSM::Support::ProcessSupervisor::_start_supervision;
    my $state;
    my $result;
    {
        no warnings 'redefine';
        # Preserve the original state object without adding I/O, validation or
        # an exception boundary between its owned fork and original driver.
        local *FSM::Support::ProcessSupervisor::_start_supervision = sub {
            $state = $start->(@_);
            return $state;
        };
        $result = $invoke->(%$request);
    }
    return ($result, state_receipt($state, $result));
}

1;
