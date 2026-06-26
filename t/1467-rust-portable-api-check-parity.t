#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP qw(decode_json);

my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $fixture = File::Spec->catfile(
    $repo_root,
    qw(t corpus direct_sreset_active_high.fsm),
);
my $rust_manifest = File::Spec->catfile($repo_root, qw(rust Cargo.toml));

my $perl_oracle = run_json_command(
    'Perl oracle check JSON',
    [
        './bin/fsmgen',
        '--check-json',
        $fixture,
    ],
);
my $rust_projection = run_json_command(
    'Rust portable API check projection',
    [
        'cargo',
        'run',
        '--quiet',
        '--manifest-path',
        $rust_manifest,
        '--bin',
        'fsmgen-portable-api-check-smoke',
        '--',
        $fixture,
    ],
);

is_deeply(
    parity_projection($rust_projection),
    parity_projection($perl_oracle),
    'Rust direct .fsm check projection matches the normalized Perl oracle fields',
);

done_testing();

sub run_json_command {
    my ($label, $command) = @_;

    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => $command,
    );
    my $stdout = join('', @{$stdout_buf || []});
    my $stderr = join('', @{$stderr_buf || []});

    ok($success, "$label command succeeds")
        or do {
            diag("stderr:\n$stderr") if length $stderr;
            diag("stdout:\n$stdout") if length $stdout;
            done_testing();
            exit 0;
        };

    my $decoded = eval { decode_json($stdout) };
    ok($decoded, "$label emits decodable JSON")
        or do {
            diag($@) if $@;
            diag("stderr:\n$stderr") if length $stderr;
            diag("stdout:\n$stdout") if length $stdout;
            done_testing();
            exit 0;
        };

    return $decoded;
}

sub parity_projection {
    my ($decoded) = @_;

    return {
        check_schema_version => $decoded->{check_schema_version},
        success => json_bool($decoded->{success}),
        diagnostics => scalar @{$decoded->{diagnostics} || []},
        source => {
            input_leaf => source_leaf($decoded->{source}{input}),
        },
        result => {
            module_name => $decoded->{result}{module_name},
            state_count => $decoded->{result}{state_count},
            signal_count => $decoded->{result}{signal_count},
            composition_child_count => $decoded->{result}{composition_child_count},
        },
        generated_output => {
            emitted => json_bool($decoded->{generated_output}{emitted}),
        },
        support_accounting => {
            matched => json_bool($decoded->{support_accounting}{matched}),
            entry_id => $decoded->{support_accounting}{entry_id},
            family => $decoded->{support_accounting}{family},
            coverage => $decoded->{support_accounting}{coverage},
            classification => $decoded->{support_accounting}{classification},
            source_kind => $decoded->{support_accounting}{source_kind},
            strict_supported => json_bool($decoded->{support_accounting}{strict_supported}),
        },
    };
}

sub json_bool {
    my ($value) = @_;
    return $value ? 1 : 0;
}

sub source_leaf {
    my ($path) = @_;
    my (undef, undef, $file) = File::Spec->splitpath($path || '');
    return $file;
}
