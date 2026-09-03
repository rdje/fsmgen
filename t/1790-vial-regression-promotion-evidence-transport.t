#!/usr/bin/env perl

use v5.20;
use strict;
use warnings;

use bytes ();
use Cwd qw(realpath);
use Digest::SHA qw(sha256_hex);
use File::Copy qw(copy);
use File::Find qw(find);
use File::Path qw(make_path remove_tree);
use File::Spec;
use FindBin;
use IPC::Open3 qw(open3);
use JSON::PP ();
use POSIX qw(mkfifo);
use Symbol qw(gensym);
use Test::More;

my $root = realpath(File::Spec->catdir($FindBin::Bin, '..'))
    // die "cannot resolve repository root\n";
my $script_relative =
    'scripts/verify_vial_regression_promotion_evidence_transport.pl';
my $bundle_relative =
    'vial/qualification/regression_promotion_gate/evidence-v1';
my $script = repo_path($root, $script_relative);
my $bundle = repo_path($root, $bundle_relative);
my $manifest = repo_path($bundle, 'transport-manifest.json');
my $corpus = repo_path(
    $root,
    '.artifacts/qualification/vial-scale/v2/'
        . 'regression-promotion-corpus-v1',
);
my $qualification = repo_path(
    $root,
    '.artifacts/qualification/vial-scale/v2/'
        . 'regression-promotion-budget-qualification-v1',
);
my $scratch = repo_path(
    $root,
    ".artifacts/tmp/vial-regression-promotion-evidence-transport-tests-$$",
);
my $fixture_root = repo_path($scratch, 'repository');
my $fixture_script = repo_path($fixture_root, $script_relative);
my $fixture_bundle = repo_path($fixture_root, $bundle_relative);
my $fixture_manifest = repo_path($fixture_bundle, 'transport-manifest.json');
my $json = JSON::PP->new->canonical(1)->utf8(1);

die "evidence-transport test scratch path already exists\n"
    if -e($scratch) || -l($scratch);
END {
    remove_tree($scratch) if defined($scratch) && -d($scratch);
}

subtest 'verifier is repository-derived, production-independent, and read-only' => sub {
    ok(-f($script) && !-l($script), 'tracked verifier exists');
    ok(-x($script), 'tracked verifier is executable');
    ok(-f($manifest) && !-l($manifest), 'tracked transport manifest exists');
    my $source = read_raw($script);
    unlike(
        $source,
        qr/^\s*(?:use|require)\s+FSM::/m,
        'verifier imports no FSMGEN production module',
    );
    unlike(
        $source,
        qr/^\s*use\s+lib\b/m,
        'verifier does not expose the production library path',
    );
    unlike(
        $source,
        qr/(?:GetOptions|caller_(?:root|source|evidence)|source_root)/,
        'verifier has no caller-selected evidence seam',
    );

    my $bundle_before = tree_census($bundle);
    my $corpus_before = tree_census($corpus);
    my $qualification_before = tree_census($qualification);
    my $run = run_verifier($script);
    is($run->{status}, 0, 'real tracked evidence transport verifies')
        or diag($run->{stderr});
    is($run->{stderr}, '', 'successful verification is diagnostic-free');
    is_deeply(
        tree_census($bundle),
        $bundle_before,
        'verification leaves every tracked source path and byte unchanged',
    );
    is_deeply(
        tree_census($corpus),
        $corpus_before,
        'verification leaves generated corpus coordinates unchanged',
    );
    is_deeply(
        tree_census($qualification),
        $qualification_before,
        'verification leaves generated qualification coordinates unchanged',
    );
};

subtest 'bounded canonical result exposes the exact transport and source seals' => sub {
    my $first = run_verifier($script);
    my $second = run_verifier($script);
    is($first->{status}, 0, 'first result inspection succeeds')
        or diag($first->{stderr});
    is($second->{status}, 0, 'second result inspection succeeds')
        or diag($second->{stderr});
    is($second->{stdout}, $first->{stdout},
        'verification result is byte-deterministic');
    cmp_ok(bytes::length($first->{stdout}), '<=', 32_768,
        'result stays within its closed output ceiling');
    my $decoded = eval { $json->decode($first->{stdout}) };
    is($@, '', 'result is JSON');
    is($first->{stdout}, $json->encode($decoded) . "\n",
        'result is canonical newline JSON');
    is(
        $decoded->{schema},
        'fsmgen.vial_regression_promotion_gate_evidence_transport_verification.v1',
        'result exposes the independent transport-verification contract',
    );
    is($decoded->{schema_version}, 1, 'verification schema version is exact');
    is(
        $decoded->{bundle_identity},
        'regression-promotion-gate-evidence-transport/'
            . '3b4c486e8e3f853f626d85d2abc713846d0594230d922913c8655be3f682bbc6',
        'selected transport identity is exact',
    );
    is(
        $decoded->{verification_identity},
        'regression-promotion-gate-evidence-transport-verification/'
            . 'ae9c67c927912c96174422bc0ef0b754c25855597c9095be71b85ee767fb55b6',
        'verification result identity is exact',
    );
    is_deeply(
        $decoded->{manifest},
        {
            bytes => 8_725,
            sha256 =>
                'd20cae857a6799c1ea54a830d72552cb0587ea647018761007089587b21d94f7',
        },
        'canonical manifest byte and digest seal is exact',
    );
    is_deeply(
        $decoded->{summary},
        {
            manifest_file_count => 1,
            payload_file_count => 15,
            payload_total_bytes => 7_012_284,
            corpus_file_count => 13,
            qualification_file_count => 2,
        },
        'result exposes the closed manifest/payload census',
    );
    is(
        $decoded->{source_seals}{corpus}{file_set_sha256},
        'dc5b315b827389eb466776716f6851cdd9ddd13b2f1aec441f8a51b7d72dc66f',
        'corpus file-set seal is exact',
    );
    is(
        $decoded->{source_seals}{qualification}{file_set_sha256},
        '28ba972c3f8cbcc00d1d32c9db0d4015de57f0df49d11d7076262cd050069095',
        'qualification file-set seal is exact',
    );
    is(scalar(@{$decoded->{files}}), 15,
        'result inventories all fifteen ordered payloads');
    is_deeply(
        [map { $_->{ordinal} } @{$decoded->{files}}[2 .. 12]],
        [1 .. 11],
        'profile payload order is exact',
    );
};

subtest 'closed invocation rejects caller evidence selection' => sub {
    for my $argument ('foreign-root', '--source', '--evidence') {
        my $run = run_verifier($script, $argument);
        isnt($run->{status}, 0, "$argument rejects");
        like(
            $run->{stderr},
            qr/^usage: scripts\/verify_vial_regression_promotion_evidence_transport[.]pl/m,
            "$argument reports the closed invocation",
        );
        is($run->{stdout}, '', "$argument emits no result");
        cmp_ok(bytes::length($run->{stderr}), '<=', 4_096,
            "$argument diagnostic is bounded");
    }
};

subtest 'copied hostile transport mutations fail closed' => sub {
    make_path(repo_path($fixture_root, 'scripts'));
    copy($script, $fixture_script)
        or die "cannot copy evidence-transport verifier: $!\n";
    chmod 0755, $fixture_script
        or die "cannot make copied verifier executable: $!\n";
    copy_tree($bundle, $fixture_bundle);

    my $baseline = run_verifier($fixture_script);
    is($baseline->{status}, 0, 'copied baseline verifies')
        or diag($baseline->{stderr});
    my $manifest_bytes = read_raw($fixture_manifest);
    my $payload = repo_path(
        $fixture_bundle,
        'payload/regression-promotion-corpus-v1/complete/corpus-manifest.json',
    );
    my $payload_bytes = read_raw($payload);

    reject_manifest_mutation(
        'extra manifest key',
        sub { $_[0]{foreign} = 1 },
        qr/transport manifest keys changed/,
    );
    reject_manifest_mutation(
        'manifest schema',
        sub { $_[0]{schema} =~ s/[.]v1\z/.v2/ },
        qr/transport manifest schema changed/,
    );
    reject_manifest_mutation(
        'entry order',
        sub {
            my $first = $_[0]{entries}[0];
            $_[0]{entries}[0] = $_[0]{entries}[1];
            $_[0]{entries}[1] = $first;
        },
        qr/transport manifest entry order changed/,
    );
    reject_manifest_mutation(
        'unsafe source path',
        sub { $_[0]{entries}[0]{source_relative_path} = '../evidence.json' },
        qr/transport source path is unsafe/,
    );
    reject_manifest_mutation(
        'destination mapping',
        sub { $_[0]{entries}[0]{destination_relative_path} .= '.foreign' },
        qr/transport source\/destination mapping changed/,
    );
    reject_manifest_mutation(
        'entry byte count',
        sub { ++$_[0]{entries}[0]{bytes} },
        qr/transport manifest aggregate byte count changed/,
    );
    reject_manifest_mutation(
        'entry digest',
        sub { substr($_[0]{entries}[0]{sha256}, 0, 1, '0') },
        qr/transport manifest content identity changed/,
    );
    reject_manifest_mutation(
        'bundle identity',
        sub { substr($_[0]{bundle_identity}, -1, 1, '0') },
        qr/transport manifest content identity changed/,
    );
    reject_manifest_mutation(
        'source seal',
        sub { ++$_[0]{source_seals}{corpus}{file_count} },
        qr/transport manifest source seals changed/,
    );

    write_raw($fixture_manifest, substr($manifest_bytes, 0, -1) . ' ');
    reject_current(
        'noncanonical manifest',
        qr/transport manifest is not canonical newline JSON/,
    );
    write_raw($fixture_manifest, $manifest_bytes);

    write_raw($payload, substr($payload_bytes, 0, -1) . ' ');
    reject_current(
        'noncanonical payload',
        qr/evidence payload is not canonical newline JSON/,
    );
    write_raw($payload, $payload_bytes);

    my $payload_document = $json->decode($payload_bytes);
    $payload_document->{schema} =~ s/[.]v1\z/.v2/;
    my $schema_mutation = $json->encode($payload_document) . "\n";
    is(bytes::length($schema_mutation), bytes::length($payload_bytes),
        'payload schema mutation preserves the admitted byte count');
    write_raw($payload, $schema_mutation);
    reject_current(
        'payload schema',
        qr/evidence payload SHA-256 changed/,
    );
    write_raw($payload, $payload_bytes);

    write_raw($payload, $payload_bytes . 'x');
    reject_current(
        'payload byte count',
        qr/evidence payload byte count changed/,
    );
    write_raw($payload, $payload_bytes);

    my $extra = repo_path($fixture_bundle, 'payload/foreign.json');
    write_raw($extra, "{}\n");
    reject_current('extra payload', qr/evidence transport file census changed/);
    unlink($extra) or die "cannot remove copied extra payload: $!\n";

    my $held = repo_path($scratch, 'held-payload.json');
    rename($payload, $held) or die "cannot hold copied payload: $!\n";
    reject_current('missing payload', qr/evidence transport file census changed/);
    rename($held, $payload) or die "cannot restore copied payload: $!\n";

    rename($payload, $held) or die "cannot hold copied payload: $!\n";
    symlink($fixture_manifest, $payload)
        or die "cannot create copied payload symlink: $!\n";
    reject_current('payload symlink', qr/evidence transport contains a symlink/);
    unlink($payload) or die "cannot remove copied payload symlink: $!\n";
    rename($held, $payload) or die "cannot restore copied payload: $!\n";

    rename($payload, $held) or die "cannot hold copied payload: $!\n";
    link($held, $payload) or die "cannot create copied payload hardlink: $!\n";
    reject_current('payload hardlink', qr/evidence transport contains an aliased file/);
    unlink($payload) or die "cannot remove copied payload hardlink: $!\n";
    rename($held, $payload) or die "cannot restore copied payload: $!\n";

    rename($payload, $held) or die "cannot hold copied payload: $!\n";
    mkfifo($payload, 0600) or die "cannot create copied payload FIFO: $!\n";
    reject_current('payload FIFO', qr/evidence transport contains a non-regular node/);
    unlink($payload) or die "cannot remove copied payload FIFO: $!\n";
    rename($held, $payload) or die "cannot restore copied payload: $!\n";

    my $restored = run_verifier($fixture_script);
    is($restored->{status}, 0, 'copied baseline verifies after every restoration')
        or diag($restored->{stderr});
    is($restored->{stdout}, $baseline->{stdout},
        'copied verification identity is restored exactly');
};

done_testing();

sub reject_manifest_mutation {
    my ($label, $mutate, $diagnostic) = @_;
    my $original = read_raw($fixture_manifest);
    my $document = $json->decode($original);
    $mutate->($document);
    write_raw($fixture_manifest, $json->encode($document) . "\n");
    reject_current($label, $diagnostic);
    write_raw($fixture_manifest, $original);
}

sub reject_current {
    my ($label, $diagnostic) = @_;
    my $run = run_verifier($fixture_script);
    isnt($run->{status}, 0, "$label rejects");
    like($run->{stderr}, $diagnostic, "$label reports its failing boundary");
    is($run->{stdout}, '', "$label emits no verification result");
    cmp_ok(bytes::length($run->{stderr}), '<=', 4_096,
        "$label diagnostic is bounded");
}

sub run_verifier {
    my ($executable, @arguments) = @_;
    my $error = gensym;
    my $pid = open3(
        my $input,
        my $output,
        $error,
        $^X,
        $executable,
        @arguments,
    );
    close $input;
    local $/;
    my $stdout = <$output> // '';
    my $stderr = <$error> // '';
    close $output;
    close $error;
    waitpid($pid, 0) == $pid or die "cannot wait for verifier\n";
    return {
        status => $? == -1 ? -1 : $? >> 8,
        signal => $? & 127,
        stdout => $stdout,
        stderr => $stderr,
    };
}

sub copy_tree {
    my ($source, $destination) = @_;
    find({
        no_chdir => 1,
        wanted => sub {
            my $path = $File::Find::name;
            die "copied fixture source contains a symlink\n" if -l($path);
            my $relative = File::Spec->abs2rel($path, $source);
            my $target = $relative eq '.'
                ? $destination
                : repo_path($destination, $relative);
            if (-d($path)) {
                make_path($target);
                return;
            }
            die "copied fixture source contains a non-file\n" unless -f($path);
            copy($path, $target) or die "cannot copy hostile fixture path: $!\n";
        },
    }, $source);
}

sub tree_census {
    my ($base) = @_;
    my @entries;
    find({
        no_chdir => 1,
        wanted => sub {
            my $path = $File::Find::name;
            my @stat = lstat($path);
            die "cannot stat verifier test path\n" unless @stat;
            my $relative = File::Spec->abs2rel($path, $base);
            $relative = '' if $relative eq '.';
            $relative =~ s{\\}{/}g;
            my $entry = {
                relative_path => $relative,
                device => $stat[0],
                inode => $stat[1],
                mode => $stat[2],
                links => $stat[3],
                owner => $stat[4],
                bytes => $stat[7],
                type => -l _ ? 'symlink'
                    : -d _ ? 'directory'
                    : -f _ ? 'file' : 'other',
            };
            $entry->{sha256} = sha256_hex(read_raw($path)) if -f _;
            push @entries, $entry;
        },
    }, $base);
    return [sort {
        $a->{relative_path} cmp $b->{relative_path}
    } @entries];
}

sub repo_path {
    my ($base, @parts) = @_;
    return File::Spec->catfile($base, map { split m{/} } @parts);
}

sub read_raw {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "cannot read verifier test path\n";
    local $/;
    my $bytes = <$fh> // '';
    close $fh or die "cannot close verifier test path\n";
    return $bytes;
}

sub write_raw {
    my ($path, $bytes) = @_;
    open my $fh, '>:raw', $path or die "cannot write verifier test path\n";
    print {$fh} $bytes or die "cannot write verifier test path\n";
    close $fh or die "cannot close verifier test path\n";
}
