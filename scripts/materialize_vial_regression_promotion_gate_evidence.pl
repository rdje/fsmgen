#!/usr/bin/env perl

use v5.20;
use strict;
use warnings;

use bytes ();
use Cwd qw(realpath);
use Digest::SHA qw(sha256_hex);
use Errno qw(EAGAIN EWOULDBLOCK);
use Fcntl qw(
    FD_CLOEXEC F_GETFD F_SETFD LOCK_EX LOCK_NB O_CREAT O_EXCL O_NOFOLLOW
    O_RDONLY O_WRONLY
);
use File::Basename qw(dirname);
use File::Find qw(find);
use File::Spec;
use FindBin;
use IPC::Open3 qw(open3);
use JSON::PP ();
use Symbol qw(gensym);

my $ROOT = realpath(File::Spec->catdir($FindBin::Bin, '..'))
    // die "cannot resolve repository root\n";
my $BUNDLE_RELATIVE =
    'vial/qualification/regression_promotion_gate/evidence-v1';
my $MANIFEST_RELATIVE = "$BUNDLE_RELATIVE/transport-manifest.json";
my $SOURCE_VERIFIER_RELATIVE =
    'scripts/verify_vial_regression_promotion_evidence_transport.pl';
my $DESTINATION_BASE = '.artifacts/qualification/vial-scale/v2';
my $CORPUS_NAME = 'regression-promotion-corpus-v1';
my $QUALIFICATION_NAME =
    'regression-promotion-budget-qualification-v1';
my $CORPUS_DESTINATION = "$DESTINATION_BASE/$CORPUS_NAME";
my $QUALIFICATION_DESTINATION =
    "$DESTINATION_BASE/$QUALIFICATION_NAME";
my $STATE_BASE = join '/', qw(
    .artifacts tmp vial-scale
    regression-promotion-gate-evidence-transport v1
);
my $BUNDLE_DIGEST =
    '3b4c486e8e3f853f626d85d2abc713846d0594230d922913c8655be3f682bbc6';
my $BUNDLE_IDENTITY =
    "regression-promotion-gate-evidence-transport/$BUNDLE_DIGEST";
my $MANIFEST_SHA256 =
    'd20cae857a6799c1ea54a830d72552cb0587ea647018761007089587b21d94f7';
my $SOURCE_VERIFICATION_IDENTITY =
    'regression-promotion-gate-evidence-transport-verification/'
    . 'ae9c67c927912c96174422bc0ef0b754c25855597c9095be71b85ee767fb55b6';
my $TRANSACTION_RELATIVE =
    "$STATE_BASE/transactions/$BUNDLE_DIGEST";
my $STAGE_RELATIVE = "$TRANSACTION_RELATIVE/stage";
my $JOURNAL_RELATIVE = "$TRANSACTION_RELATIVE/journal.json";
my $PENDING_RECEIPT_RELATIVE =
    "$TRANSACTION_RELATIVE/receipt.pending.json";
my $RECEIPT_RELATIVE = "$STATE_BASE/receipts/$BUNDLE_DIGEST.json";
my $MANIFEST_MAX_BYTES = 32_768;
my $SOURCE_RESULT_MAX_BYTES = 32_768;
my $RESULT_MAX_BYTES = 32_768;
my $PAYLOAD_MAX_BYTES = 8_388_608;
my $PAYLOAD_TOTAL_BYTES = 7_012_284;
my $JSON = JSON::PP->new->canonical(1)->utf8(1);

my @RESULT_NONCLAIMS = qw(
    evidence_recalibration evidence_reinterpretation gate_execution
    provider_execution simulator_execution performance_enforcement
    support_promotion architecture_scale_capacity
);

@ARGV == 1 && $ARGV[0] =~ /\A(?:materialize|cleanup)\z/
    or die "usage: scripts/materialize_vial_regression_promotion_gate_evidence.pl materialize|cleanup\n";
my $operation = $ARGV[0];

my $result;
my $ok = eval {
    $result = _run($operation);
    1;
};
if (!$ok) {
    my $error = _sanitize_error($@);
    print STDERR "evidence materializer: $error\n";
    exit 1;
}
my $encoded = _canonical($result) . "\n";
die "evidence materialization result exceeds its bounded ceiling\n"
    if bytes::length($encoded) > $RESULT_MAX_BYTES;
print $encoded;

sub _run {
    my ($selected_operation) = @_;
    my @root_stat = lstat($ROOT);
    die "repository root identity is invalid\n"
        unless @root_stat && -d _ && !-l _ && $root_stat[4] == $>;
    my ($root_device, $root_owner) = @root_stat[0, 4];

    my $lock = _acquire_lock($root_device, $root_owner);
    my $manifest = _authenticate_source(
        $lock, $root_device, $root_owner,
    );
    _validate_state_envelope($root_device, $root_owner);
    my $receipt = _expected_receipt('installed');
    my $adopted_receipt = _expected_receipt('adopted_exact');
    my $journal = _expected_journal($receipt);

    return $selected_operation eq 'materialize'
        ? _materialize(
            $manifest, $receipt, $adopted_receipt, $journal,
            $root_device, $root_owner,
        )
        : _cleanup(
            $manifest, $receipt, $adopted_receipt, $journal,
            $root_device, $root_owner,
        );
}

sub _materialize {
    my (
        $manifest, $receipt, $adopted_receipt, $journal,
        $root_device, $root_owner,
    ) = @_;
    my $transaction_exists = _exists($TRANSACTION_RELATIVE);
    my $receipt_exists = _exists($RECEIPT_RELATIVE);

    if ($transaction_exists) {
        my $outcome = eval {
            _recover_transaction(
                $manifest, $receipt, $journal,
                $root_device, $root_owner,
                $receipt_exists,
            );
        };
        if (!defined $outcome) {
            my $error = $@;
            if (!_exists($CORPUS_DESTINATION)
                    && !_exists($QUALIFICATION_DESTINATION)) {
                my $discarded = eval {
                    _remove_owned_tree(
                        $TRANSACTION_RELATIVE,
                        $root_device,
                        $root_owner,
                        32,
                        $PAYLOAD_MAX_BYTES + 131_072,
                    );
                    _prune_empty_parents(dirname($TRANSACTION_RELATIVE));
                    1;
                };
                die "invalid evidence transaction was discarded\n"
                    if $discarded;
            }
            die $error;
        }
        return _result('materialize', $outcome, $receipt);
    }

    if ($receipt_exists) {
        my $existing = _read_receipt($root_device, $root_owner);
        die "evidence receipt identity is invalid\n"
            unless _same($existing, $receipt)
                || _same($existing, $adopted_receipt);
        _validate_destination_pair(
            $manifest, $root_device, $root_owner,
        );
        return _result('materialize', 'already_materialized', $existing);
    }

    my $corpus_exists = _exists($CORPUS_DESTINATION);
    my $qualification_exists = _exists($QUALIFICATION_DESTINATION);
    if ($corpus_exists || $qualification_exists) {
        die "partial evidence destination exists without ownership proof\n"
            unless $corpus_exists && $qualification_exists;
        _validate_destination_pair(
            $manifest, $root_device, $root_owner,
        );
        _ensure_directory(dirname($RECEIPT_RELATIVE), $root_device, $root_owner);
        _write_canonical_exclusive(
            $RECEIPT_RELATIVE,
            $adopted_receipt,
            $root_device,
            $root_owner,
        );
        return _result('materialize', 'adopted_exact', $adopted_receipt);
    }

    _ensure_directory($DESTINATION_BASE, $root_device, $root_owner);
    _ensure_directory(dirname($TRANSACTION_RELATIVE), $root_device, $root_owner);
    _ensure_directory(dirname($RECEIPT_RELATIVE), $root_device, $root_owner);
    _create_directory_exclusive(
        $TRANSACTION_RELATIVE, $root_device, $root_owner,
    );
    _create_directory_exclusive($STAGE_RELATIVE, $root_device, $root_owner);

    my $prepared = eval {
        _stage_payload($manifest, $root_device, $root_owner);
        _validate_staged_pair($manifest, $root_device, $root_owner);
        _write_canonical_exclusive(
            $PENDING_RECEIPT_RELATIVE,
            $receipt,
            $root_device,
            $root_owner,
        );
        _write_canonical_exclusive(
            $JOURNAL_RELATIVE,
            $journal,
            $root_device,
            $root_owner,
        );
        _validate_transaction_census(
            $manifest, $root_device, $root_owner,
            1, 1, 1,
        );
        1;
    };
    if (!$prepared) {
        my $error = $@;
        my $removed = eval {
            _remove_owned_tree(
                $TRANSACTION_RELATIVE,
                $root_device,
                $root_owner,
                32,
                $PAYLOAD_MAX_BYTES + 131_072,
            );
            _prune_empty_parents(dirname($TRANSACTION_RELATIVE));
            1;
        };
        die $removed
            ? $error
            : "failed evidence preparation left unsafe owned state\n";
    }

    _boundary('journal_committed');
    _install_stage_root($CORPUS_NAME, $CORPUS_DESTINATION);
    _boundary('corpus_installed');
    _install_stage_root(
        $QUALIFICATION_NAME, $QUALIFICATION_DESTINATION,
    );
    _boundary('qualification_installed');
    _commit_receipt($receipt, $root_device, $root_owner);
    _boundary('receipt_committed');
    _finish_transaction($root_device, $root_owner);
    _validate_destination_pair($manifest, $root_device, $root_owner);
    return _result('materialize', 'materialized', $receipt);
}

sub _cleanup {
    my (
        $manifest, $receipt, $adopted_receipt, $journal,
        $root_device, $root_owner,
    ) = @_;
    if (_exists($TRANSACTION_RELATIVE)) {
        my $receipt_exists = _exists($RECEIPT_RELATIVE);
        my $state = eval {
            _inspect_transaction(
                $manifest, $receipt, $journal,
                $root_device, $root_owner,
                $receipt_exists,
            );
        };
        die $@ unless defined $state;

        my @owned;
        push @owned, $QUALIFICATION_DESTINATION
            if $state->{qualification_destination};
        push @owned, $CORPUS_DESTINATION
            if $state->{corpus_destination};
        for my $relative (@owned) {
            my $name = $relative eq $CORPUS_DESTINATION
                ? $CORPUS_NAME : $QUALIFICATION_NAME;
            _validate_evidence_tree(
                $relative, $name, $manifest, $root_device, $root_owner,
            );
        }
        for my $relative (@owned) {
            _remove_exact_evidence_tree(
                $relative, $manifest, $root_device, $root_owner,
            );
        }
        _remove_owned_tree(
            $TRANSACTION_RELATIVE,
            $root_device,
            $root_owner,
            32,
            $PAYLOAD_MAX_BYTES + 131_072,
        );
        if ($receipt_exists) {
            my $existing = _read_receipt($root_device, $root_owner);
            die "evidence receipt identity is invalid\n"
                unless _same($existing, $receipt);
            unlink _absolute($RECEIPT_RELATIVE)
                or die "cannot remove evidence receipt\n";
        }
        _prune_empty_parents(dirname($TRANSACTION_RELATIVE));
        _prune_empty_parents(dirname($RECEIPT_RELATIVE));
        _prune_empty_parents($DESTINATION_BASE);
        return _result('cleanup', 'cleaned_interrupted_transaction', $receipt);
    }

    return _result('cleanup', 'nothing_owned', $adopted_receipt)
        unless _exists($RECEIPT_RELATIVE);
    my $existing = _read_receipt($root_device, $root_owner);
    die "evidence receipt identity is invalid\n"
        unless _same($existing, $receipt)
            || _same($existing, $adopted_receipt);

    my @owned = @{$existing->{created_roots}};
    for my $relative (@owned) {
        my $name = $relative eq $CORPUS_DESTINATION
            ? $CORPUS_NAME : $QUALIFICATION_NAME;
        _validate_evidence_tree(
            $relative, $name, $manifest, $root_device, $root_owner,
        );
    }
    for my $relative (reverse @owned) {
        _remove_exact_evidence_tree(
            $relative, $manifest, $root_device, $root_owner,
        );
    }
    unlink _absolute($RECEIPT_RELATIVE)
        or die "cannot remove evidence receipt\n";
    _prune_empty_parents(dirname($RECEIPT_RELATIVE));
    _prune_empty_parents($DESTINATION_BASE);
    return _result('cleanup', @owned ? 'cleaned' : 'released_adopted_receipt', $existing);
}

sub _recover_transaction {
    my (
        $manifest, $receipt, $journal,
        $root_device, $root_owner, $receipt_exists,
    ) = @_;
    my $state = _inspect_transaction(
        $manifest, $receipt, $journal,
        $root_device, $root_owner, $receipt_exists,
    );
    if ($state->{receipt}) {
        _finish_transaction($root_device, $root_owner);
        _validate_destination_pair($manifest, $root_device, $root_owner);
        return 'recovered';
    }
    if ($state->{corpus_stage}) {
        _install_stage_root($CORPUS_NAME, $CORPUS_DESTINATION);
        _boundary('corpus_installed');
    }
    if ($state->{qualification_stage}) {
        _install_stage_root(
            $QUALIFICATION_NAME, $QUALIFICATION_DESTINATION,
        );
        _boundary('qualification_installed');
    }
    _commit_receipt($receipt, $root_device, $root_owner);
    _boundary('receipt_committed');
    _finish_transaction($root_device, $root_owner);
    _validate_destination_pair($manifest, $root_device, $root_owner);
    return 'recovered';
}

sub _inspect_transaction {
    my (
        $manifest, $receipt, $journal,
        $root_device, $root_owner, $receipt_exists,
    ) = @_;
    my $actual_journal = _decode_canonical_line(
        _read_stable(
            $JOURNAL_RELATIVE, $root_device, $root_owner,
            $MANIFEST_MAX_BYTES, undef, 'evidence journal',
        ),
        'evidence journal',
    );
    die "evidence journal identity is invalid\n"
        unless _same($actual_journal, $journal);

    my %state = (
        corpus_stage => _exists("$STAGE_RELATIVE/$CORPUS_NAME"),
        qualification_stage =>
            _exists("$STAGE_RELATIVE/$QUALIFICATION_NAME"),
        corpus_destination => _exists($CORPUS_DESTINATION),
        qualification_destination =>
            _exists($QUALIFICATION_DESTINATION),
        pending_receipt => _exists($PENDING_RECEIPT_RELATIVE),
        receipt => $receipt_exists ? 1 : 0,
    );
    my $shape = join '', map { $state{$_} ? 1 : 0 } qw(
        corpus_stage qualification_stage corpus_destination
        qualification_destination pending_receipt receipt
    );
    die "evidence transaction state is not recoverable\n"
        unless $shape eq '110010'
            || $shape eq '011010'
            || $shape eq '001110'
            || $shape eq '001101';

    if ($state{corpus_stage}) {
        _validate_evidence_tree(
            "$STAGE_RELATIVE/$CORPUS_NAME", $CORPUS_NAME,
            $manifest, $root_device, $root_owner,
        );
    }
    if ($state{qualification_stage}) {
        _validate_evidence_tree(
            "$STAGE_RELATIVE/$QUALIFICATION_NAME", $QUALIFICATION_NAME,
            $manifest, $root_device, $root_owner,
        );
    }
    if ($state{corpus_destination}) {
        _validate_evidence_tree(
            $CORPUS_DESTINATION, $CORPUS_NAME,
            $manifest, $root_device, $root_owner,
        );
    }
    if ($state{qualification_destination}) {
        _validate_evidence_tree(
            $QUALIFICATION_DESTINATION, $QUALIFICATION_NAME,
            $manifest, $root_device, $root_owner,
        );
    }
    if ($state{pending_receipt}) {
        my $pending = _decode_canonical_line(
            _read_stable(
                $PENDING_RECEIPT_RELATIVE,
                $root_device,
                $root_owner,
                $MANIFEST_MAX_BYTES,
                undef,
                'pending evidence receipt',
            ),
            'pending evidence receipt',
        );
        die "pending evidence receipt identity is invalid\n"
            unless _same($pending, $receipt);
    }
    if ($state{receipt}) {
        my $actual = _read_receipt($root_device, $root_owner);
        die "evidence receipt identity is invalid\n"
            unless _same($actual, $receipt);
    }
    _validate_transaction_census(
        $manifest, $root_device, $root_owner,
        $state{corpus_stage},
        $state{qualification_stage},
        $state{pending_receipt},
    );
    return \%state;
}

sub _authenticate_source {
    my ($lock, $root_device, $root_owner) = @_;
    my $verifier = _absolute($SOURCE_VERIFIER_RELATIVE);
    my $stderr = gensym;
    my $pid = open3(my $input, my $output, $stderr, $^X, $verifier);
    close $input;
    my $stdout_bytes = _read_stream_bounded(
        $output, $SOURCE_RESULT_MAX_BYTES, 'source verifier output',
    );
    my $stderr_bytes = _read_stream_bounded(
        $stderr, 4_096, 'source verifier diagnostic',
    );
    waitpid($pid, 0);
    die "evidence source verification failed\n"
        unless $? == 0 && $stderr_bytes eq '';
    my $source_result = _decode_canonical_line(
        $stdout_bytes, 'source verifier output',
    );
    die "evidence source verification identity changed\n"
        unless ($source_result->{verification_identity} // '') eq
                $SOURCE_VERIFICATION_IDENTITY
            && ($source_result->{bundle_identity} // '') eq $BUNDLE_IDENTITY
            && _integer_equals(
                $source_result->{summary}{payload_file_count}, 15,
            )
            && _integer_equals(
                $source_result->{summary}{payload_total_bytes},
                $PAYLOAD_TOTAL_BYTES,
            );

    my $manifest_bytes = _read_locked_manifest(
        $lock, $root_device, $root_owner,
    );
    die "evidence transport manifest digest changed\n"
        unless sha256_hex($manifest_bytes) eq $MANIFEST_SHA256;
    my $manifest = _decode_canonical_line(
        $manifest_bytes, 'transport manifest',
    );
    die "evidence transport bundle identity changed\n"
        unless ($manifest->{bundle_identity} // '') eq $BUNDLE_IDENTITY
            && ref($manifest->{entries}) eq 'ARRAY'
            && @{$manifest->{entries}} == 15;
    return $manifest;
}

sub _stage_payload {
    my ($manifest, $root_device, $root_owner) = @_;
    for my $entry (@{$manifest->{entries}}) {
        my $source_relative = "$BUNDLE_RELATIVE/$entry->{source_relative_path}";
        my $destination = $entry->{destination_relative_path};
        my $prefix = "$DESTINATION_BASE/";
        die "evidence manifest destination escaped fixed root\n"
            unless index($destination, $prefix) == 0;
        my $tail = substr($destination, length($prefix));
        my $stage_relative = "$STAGE_RELATIVE/$tail";
        _ensure_directory(dirname($stage_relative), $root_device, $root_owner);
        my $bytes = _read_stable(
            $source_relative,
            $root_device,
            $root_owner,
            $entry->{bytes},
            $entry->{bytes},
            'evidence payload',
        );
        die "evidence payload digest changed during staging\n"
            unless sha256_hex($bytes) eq $entry->{sha256};
        _write_bytes_exclusive(
            $stage_relative, $bytes, $root_device, $root_owner,
        );
    }
    my $post = _read_stable(
        $MANIFEST_RELATIVE,
        $root_device,
        $root_owner,
        $MANIFEST_MAX_BYTES,
        undef,
        'transport manifest',
    );
    die "evidence transport changed during staging\n"
        unless sha256_hex($post) eq $MANIFEST_SHA256;
}

sub _validate_staged_pair {
    my ($manifest, $root_device, $root_owner) = @_;
    _validate_evidence_tree(
        "$STAGE_RELATIVE/$CORPUS_NAME", $CORPUS_NAME,
        $manifest, $root_device, $root_owner,
    );
    _validate_evidence_tree(
        "$STAGE_RELATIVE/$QUALIFICATION_NAME", $QUALIFICATION_NAME,
        $manifest, $root_device, $root_owner,
    );
}

sub _validate_destination_pair {
    my ($manifest, $root_device, $root_owner) = @_;
    _validate_evidence_tree(
        $CORPUS_DESTINATION, $CORPUS_NAME,
        $manifest, $root_device, $root_owner,
    );
    _validate_evidence_tree(
        $QUALIFICATION_DESTINATION, $QUALIFICATION_NAME,
        $manifest, $root_device, $root_owner,
    );
}

sub _validate_evidence_tree {
    my (
        $tree_relative, $namespace, $manifest,
        $root_device, $root_owner,
    ) = @_;
    my (%expected_files, %expected_directories);
    $expected_directories{''} = 1;
    my $destination_prefix = "$DESTINATION_BASE/$namespace/";
    for my $entry (@{$manifest->{entries}}) {
        next unless index(
            $entry->{destination_relative_path}, $destination_prefix,
        ) == 0;
        my $relative = substr(
            $entry->{destination_relative_path},
            length($destination_prefix),
        );
        $expected_files{$relative} = $entry;
        my $parent = dirname($relative);
        while ($parent ne '.' && $parent ne '') {
            $expected_directories{$parent} = 1;
            my $next = dirname($parent);
            last if $next eq $parent;
            $parent = $next;
        }
    }
    die "evidence namespace selection is empty\n"
        unless keys %expected_files;

    my $tree = _absolute($tree_relative);
    my (%actual_files, %actual_directories);
    find({
        no_chdir => 1,
        wanted => sub {
            my $path = $File::Find::name;
            my @stat = lstat($path);
            die "cannot stat evidence destination\n" unless @stat;
            die "evidence destination contains a symlink\n" if -l _;
            die "evidence destination crossed repository volume\n"
                unless $stat[0] == $root_device;
            die "evidence destination owner changed\n"
                unless $stat[4] == $root_owner;
            my $relative = File::Spec->abs2rel($path, $tree);
            $relative = '' if $relative eq '.';
            $relative =~ s{\\}{/}g;
            if (-d _) {
                $actual_directories{$relative} = 1;
                return;
            }
            die "evidence destination contains a non-regular node\n"
                unless -f _;
            die "evidence destination contains an aliased file\n"
                unless $stat[3] == 1;
            my $entry = $expected_files{$relative}
                // die "evidence destination file census changed\n";
            my $bytes = _read_stable_absolute(
                $path, $root_device, $root_owner,
                $entry->{bytes}, $entry->{bytes}, 'evidence destination',
            );
            die "evidence destination digest changed\n"
                unless sha256_hex($bytes) eq $entry->{sha256};
            $actual_files{$relative} = 1;
        },
    }, $tree);
    die "evidence destination file census changed\n"
        unless _same(
            [sort keys %actual_files], [sort keys %expected_files],
        );
    die "evidence destination directory census changed\n"
        unless _same(
            [sort keys %actual_directories],
            [sort keys %expected_directories],
        );
}

sub _validate_transaction_census {
    my (
        $manifest, $root_device, $root_owner,
        $corpus_stage, $qualification_stage,
        $pending_receipt,
    ) = @_;
    my %files = ($JOURNAL_RELATIVE => 1);
    $files{$PENDING_RECEIPT_RELATIVE} = 1 if $pending_receipt;
    my %directories = (
        $TRANSACTION_RELATIVE => 1,
        $STAGE_RELATIVE => 1,
    );
    for my $entry (@{$manifest->{entries}}) {
        my $destination = $entry->{destination_relative_path};
        my $prefix = "$DESTINATION_BASE/";
        my $tail = substr($destination, length($prefix));
        my ($namespace) = split m{/}, $tail, 2;
        next if $namespace eq $CORPUS_NAME && !$corpus_stage;
        next if $namespace eq $QUALIFICATION_NAME && !$qualification_stage;
        my $path = "$STAGE_RELATIVE/$tail";
        $files{$path} = 1;
        my $parent = dirname($path);
        while (index($parent, $TRANSACTION_RELATIVE) == 0) {
            $directories{$parent} = 1;
            last if $parent eq $TRANSACTION_RELATIVE;
            $parent = dirname($parent);
        }
    }
    my (%actual_files, %actual_directories);
    my $transaction = _absolute($TRANSACTION_RELATIVE);
    find({
        no_chdir => 1,
        wanted => sub {
            my $path = $File::Find::name;
            my @stat = lstat($path);
            die "cannot stat evidence transaction\n" unless @stat;
            die "evidence transaction contains a symlink\n" if -l _;
            die "evidence transaction crossed repository volume\n"
                unless $stat[0] == $root_device;
            die "evidence transaction owner changed\n"
                unless $stat[4] == $root_owner;
            my $relative = File::Spec->abs2rel($path, $ROOT);
            $relative =~ s{\\}{/}g;
            if (-d _) {
                $actual_directories{$relative} = 1;
                return;
            }
            die "evidence transaction contains a non-regular node\n"
                unless -f _;
            die "evidence transaction contains an aliased file\n"
                unless $stat[3] == 1;
            $actual_files{$relative} = 1;
        },
    }, $transaction);
    die "evidence transaction file census changed\n"
        unless _same([sort keys %actual_files], [sort keys %files]);
    die "evidence transaction directory census changed\n"
        unless _same(
            [sort keys %actual_directories], [sort keys %directories],
        );
}

sub _validate_state_envelope {
    my ($root_device, $root_owner) = @_;
    return 1 unless _exists($STATE_BASE);
    my $state_root = _absolute($STATE_BASE);
    my $transaction_prefix = "transactions/$BUNDLE_DIGEST";
    my $receipt_path = "receipts/$BUNDLE_DIGEST.json";
    find({
        no_chdir => 1,
        wanted => sub {
            my $path = $File::Find::name;
            my @stat = lstat($path);
            die "cannot stat evidence state namespace\n" unless @stat;
            die "evidence state namespace contains a symlink\n" if -l _;
            die "evidence state namespace crossed repository volume\n"
                unless $stat[0] == $root_device;
            die "evidence state namespace owner changed\n"
                unless $stat[4] == $root_owner;
            my $relative = File::Spec->abs2rel($path, $state_root);
            $relative = '' if $relative eq '.';
            $relative =~ s{\\}{/}g;
            my $allowed = $relative eq ''
                || $relative eq 'transactions'
                || $relative eq 'receipts'
                || $relative eq $transaction_prefix
                || index($relative, "$transaction_prefix/") == 0
                || $relative eq $receipt_path;
            die "evidence state namespace contains a stale identity\n"
                unless $allowed;
            return if -d _;
            die "evidence state namespace contains a non-regular node\n"
                unless -f _;
            die "evidence state namespace contains an aliased file\n"
                unless $stat[3] == 1;
        },
    }, $state_root);
    return 1;
}

sub _expected_receipt {
    my ($materialization) = @_;
    my $receipt = {
        schema =>
            'fsmgen.vial_regression_promotion_gate_evidence_receipt.v1',
        schema_version => 1,
        receipt_identity => undef,
        bundle_identity => $BUNDLE_IDENTITY,
        manifest_sha256 => $MANIFEST_SHA256,
        source_verification_identity => $SOURCE_VERIFICATION_IDENTITY,
        materialization => $materialization,
        created_roots => $materialization eq 'installed'
            ? [$CORPUS_DESTINATION, $QUALIFICATION_DESTINATION]
            : [],
        summary => {
            corpus_file_count => 13,
            qualification_file_count => 2,
            payload_file_count => 15,
            payload_total_bytes => $PAYLOAD_TOTAL_BYTES,
        },
    };
    $receipt->{receipt_identity} =
        'regression-promotion-gate-evidence-receipt/'
        . sha256_hex(_canonical($receipt));
    return $receipt;
}

sub _expected_journal {
    my ($receipt) = @_;
    my $journal = {
        schema =>
            'fsmgen.vial_regression_promotion_gate_evidence_journal.v1',
        schema_version => 1,
        journal_identity => undef,
        bundle_identity => $BUNDLE_IDENTITY,
        manifest_sha256 => $MANIFEST_SHA256,
        state => 'prepared',
        transaction_relative_path => $TRANSACTION_RELATIVE,
        stage_relative_path => $STAGE_RELATIVE,
        corpus_destination_relative_path => $CORPUS_DESTINATION,
        qualification_destination_relative_path =>
            $QUALIFICATION_DESTINATION,
        pending_receipt_relative_path => $PENDING_RECEIPT_RELATIVE,
        receipt_relative_path => $RECEIPT_RELATIVE,
        receipt_identity => $receipt->{receipt_identity},
    };
    $journal->{journal_identity} =
        'regression-promotion-gate-evidence-journal/'
        . sha256_hex(_canonical($journal));
    return $journal;
}

sub _result {
    my ($operation_name, $outcome, $receipt) = @_;
    my $result = {
        schema =>
            'fsmgen.vial_regression_promotion_gate_evidence_materialization_result.v1',
        schema_version => 1,
        result_identity => undef,
        operation => $operation_name,
        outcome => $outcome,
        bundle_identity => $BUNDLE_IDENTITY,
        receipt => {
            relative_path => $RECEIPT_RELATIVE,
            receipt_identity => $receipt->{receipt_identity},
            created_roots => [@{$receipt->{created_roots}}],
        },
        summary => {
            corpus_file_count => 13,
            qualification_file_count => 2,
            payload_file_count => 15,
            payload_total_bytes => $PAYLOAD_TOTAL_BYTES,
        },
        explicit_nonclaims => [@RESULT_NONCLAIMS],
    };
    $result->{result_identity} =
        'regression-promotion-gate-evidence-materialization-result/'
        . sha256_hex(_canonical($result));
    return $result;
}

sub _commit_receipt {
    my ($receipt, $root_device, $root_owner) = @_;
    die "evidence receipt destination already exists\n"
        if _exists($RECEIPT_RELATIVE);
    my $pending = _decode_canonical_line(
        _read_stable(
            $PENDING_RECEIPT_RELATIVE,
            $root_device,
            $root_owner,
            $MANIFEST_MAX_BYTES,
            undef,
            'pending evidence receipt',
        ),
        'pending evidence receipt',
    );
    die "pending evidence receipt identity is invalid\n"
        unless _same($pending, $receipt);
    rename _absolute($PENDING_RECEIPT_RELATIVE), _absolute($RECEIPT_RELATIVE)
        or die "cannot commit evidence receipt\n";
}

sub _finish_transaction {
    my ($root_device, $root_owner) = @_;
    my $journal = _absolute($JOURNAL_RELATIVE);
    unlink $journal or die "cannot remove committed evidence journal\n";
    my $stage = _absolute($STAGE_RELATIVE);
    rmdir $stage or die "cannot remove empty evidence stage\n";
    my $transaction = _absolute($TRANSACTION_RELATIVE);
    rmdir $transaction or die "cannot remove evidence transaction\n";
    _prune_empty_parents(dirname($TRANSACTION_RELATIVE));
}

sub _install_stage_root {
    my ($name, $destination_relative) = @_;
    my $source = _absolute("$STAGE_RELATIVE/$name");
    my $destination = _absolute($destination_relative);
    die "evidence destination collision\n"
        if -e $destination || -l $destination;
    rename $source, $destination
        or die "cannot atomically install evidence destination\n";
}

sub _read_receipt {
    my ($root_device, $root_owner) = @_;
    return _decode_canonical_line(
        _read_stable(
            $RECEIPT_RELATIVE,
            $root_device,
            $root_owner,
            $MANIFEST_MAX_BYTES,
            undef,
            'evidence receipt',
        ),
        'evidence receipt',
    );
}

sub _remove_exact_evidence_tree {
    my ($relative, $manifest, $root_device, $root_owner) = @_;
    my $namespace = $relative eq $CORPUS_DESTINATION
        ? $CORPUS_NAME : $QUALIFICATION_NAME;
    _validate_evidence_tree(
        $relative, $namespace, $manifest, $root_device, $root_owner,
    );
    _remove_owned_tree(
        $relative,
        $root_device,
        $root_owner,
        16,
        $PAYLOAD_MAX_BYTES,
    );
}

sub _remove_owned_tree {
    my (
        $relative, $root_device, $root_owner,
        $max_files, $max_bytes,
    ) = @_;
    _safe_relative($relative, 'owned tree');
    my $root = _absolute($relative);
    my (@files, @directories);
    my ($file_count, $total_bytes) = (0, 0);
    find({
        no_chdir => 1,
        wanted => sub {
            my $path = $File::Find::name;
            my @stat = lstat($path);
            die "cannot stat owned evidence tree\n" unless @stat;
            die "owned evidence tree contains a symlink\n" if -l _;
            die "owned evidence tree crossed repository volume\n"
                unless $stat[0] == $root_device;
            die "owned evidence tree owner changed\n"
                unless $stat[4] == $root_owner;
            if (-d _) {
                push @directories, [$path, [@stat]];
                return;
            }
            die "owned evidence tree contains a non-regular node\n"
                unless -f _;
            die "owned evidence tree contains an aliased file\n"
                unless $stat[3] == 1;
            ++$file_count;
            $total_bytes += $stat[7];
            die "owned evidence tree exceeds cleanup bounds\n"
                if $file_count > $max_files || $total_bytes > $max_bytes;
            push @files, [$path, [@stat]];
        },
    }, $root);
    for my $entry (@files) {
        my ($path, $expected) = @{$entry};
        my @stat = lstat($path);
        die "owned evidence file identity changed during cleanup\n"
            unless @stat && -f _ && !-l _ && $stat[3] == 1
                && $stat[0] == $expected->[0]
                && $stat[1] == $expected->[1]
                && $stat[4] == $root_owner;
        unlink $path or die "cannot remove owned evidence file\n";
    }
    for my $entry (sort {
        length($b->[0]) <=> length($a->[0])
    } @directories) {
        my ($path, $expected) = @{$entry};
        my @stat = lstat($path);
        die "owned evidence directory identity changed during cleanup\n"
            unless @stat && -d _ && !-l _
                && $stat[0] == $expected->[0]
                && $stat[1] == $expected->[1]
                && $stat[4] == $root_owner;
        rmdir $path or die "cannot remove owned evidence directory\n";
    }
}

sub _acquire_lock {
    my ($root_device, $root_owner) = @_;
    my $path = _absolute($MANIFEST_RELATIVE);
    sysopen(my $lock, $path, O_RDONLY | O_NOFOLLOW)
        or die "cannot open evidence process lock\n";
    my @path_stat = lstat($path);
    my @handle_stat = stat($lock);
    die "evidence process lock identity is invalid\n"
        unless @path_stat && @handle_stat && !-l $path && -f $lock
            && $path_stat[0] == $root_device
            && $handle_stat[0] == $root_device
            && $path_stat[0] == $handle_stat[0]
            && $path_stat[1] == $handle_stat[1]
            && $handle_stat[3] == 1
            && $handle_stat[4] == $root_owner
            && $handle_stat[7] <= $MANIFEST_MAX_BYTES;
    my $flags = fcntl($lock, F_GETFD, 0);
    die "cannot secure evidence process lock descriptor\n"
        unless defined($flags)
            && fcntl($lock, F_SETFD, $flags | FD_CLOEXEC);
    if (!flock($lock, LOCK_EX | LOCK_NB)) {
        my $contended = $! == EAGAIN || $! == EWOULDBLOCK;
        die $contended
            ? "evidence materialization is concurrently owned\n"
            : "cannot acquire evidence process lock\n";
    }
    return $lock;
}

sub _read_locked_manifest {
    my ($lock, $root_device, $root_owner) = @_;
    my $path = _absolute($MANIFEST_RELATIVE);
    my @path_stat = lstat($path);
    my @handle_stat = stat($lock);
    die "evidence process lock identity changed\n"
        unless @path_stat && @handle_stat && !-l $path && -f $lock
            && $path_stat[0] == $handle_stat[0]
            && $path_stat[1] == $handle_stat[1]
            && $handle_stat[0] == $root_device
            && $handle_stat[4] == $root_owner
            && $handle_stat[3] == 1
            && $handle_stat[7] <= $MANIFEST_MAX_BYTES;
    seek($lock, 0, 0) or die "cannot seek evidence manifest\n";
    my $bytes = '';
    while (1) {
        my $read = read($lock, my $chunk, 16_384);
        die "cannot read evidence manifest\n" unless defined $read;
        last if $read == 0;
        $bytes .= $chunk;
        die "evidence manifest exceeds bounded read\n"
            if bytes::length($bytes) > $MANIFEST_MAX_BYTES;
    }
    my @post = stat($lock);
    die "evidence manifest changed during read\n"
        unless @post && $post[0] == $handle_stat[0]
            && $post[1] == $handle_stat[1]
            && $post[7] == bytes::length($bytes)
            && $post[9] == $handle_stat[9]
            && $post[10] == $handle_stat[10];
    return $bytes;
}

sub _read_stable {
    my (
        $relative, $root_device, $root_owner,
        $max_bytes, $exact_bytes, $label,
    ) = @_;
    _safe_relative($relative, $label);
    return _read_stable_absolute(
        _absolute($relative), $root_device, $root_owner,
        $max_bytes, $exact_bytes, $label,
    );
}

sub _read_stable_absolute {
    my (
        $path, $root_device, $root_owner,
        $max_bytes, $exact_bytes, $label,
    ) = @_;
    sysopen(my $fh, $path, O_RDONLY | O_NOFOLLOW)
        or die "cannot open $label\n";
    my @path_stat = lstat($path);
    my @before = stat($fh);
    die "$label identity is invalid\n"
        unless @path_stat && @before && !-l $path && -f $fh
            && $path_stat[0] == $before[0]
            && $path_stat[1] == $before[1]
            && $before[0] == $root_device
            && $before[4] == $root_owner
            && $before[3] == 1
            && $before[7] <= $max_bytes
            && (!defined($exact_bytes) || $before[7] == $exact_bytes);
    my $bytes = '';
    while (1) {
        my $read = read($fh, my $chunk, 65_536);
        die "cannot read $label\n" unless defined $read;
        last if $read == 0;
        $bytes .= $chunk;
        die "$label exceeds bounded read\n"
            if bytes::length($bytes) > $max_bytes;
    }
    my @after = stat($fh);
    close $fh or die "cannot close $label\n";
    die "$label changed during read\n"
        unless @after
            && $after[0] == $before[0]
            && $after[1] == $before[1]
            && $after[7] == bytes::length($bytes)
            && $after[9] == $before[9]
            && $after[10] == $before[10]
            && (!defined($exact_bytes)
                || bytes::length($bytes) == $exact_bytes);
    return $bytes;
}

sub _write_canonical_exclusive {
    my ($relative, $value, $root_device, $root_owner) = @_;
    _write_bytes_exclusive(
        $relative, _canonical($value) . "\n",
        $root_device, $root_owner,
    );
}

sub _write_bytes_exclusive {
    my ($relative, $bytes, $root_device, $root_owner) = @_;
    my $path = _absolute($relative);
    sysopen(
        my $fh, $path,
        O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW,
        0600,
    ) or die "cannot create owned evidence file\n";
    my $offset = 0;
    while ($offset < bytes::length($bytes)) {
        my $written = syswrite(
            $fh, $bytes, bytes::length($bytes) - $offset, $offset,
        );
        die "cannot write owned evidence file\n"
            unless defined($written) && $written > 0;
        $offset += $written;
    }
    close $fh or die "cannot close owned evidence file\n";
    my @stat = lstat($path);
    die "owned evidence file identity is invalid\n"
        unless @stat && -f _ && !-l _ && $stat[0] == $root_device
            && $stat[4] == $root_owner && $stat[3] == 1
            && $stat[7] == bytes::length($bytes);
}

sub _ensure_directory {
    my ($relative, $root_device, $root_owner) = @_;
    _safe_relative($relative, 'evidence directory');
    my $path = $ROOT;
    for my $part (split m{/}, $relative) {
        $path = File::Spec->catdir($path, $part);
        if (!-e $path && !-l $path) {
            mkdir($path, 0700)
                or die "cannot create evidence directory\n";
        }
        my @stat = lstat($path);
        die "evidence directory identity is invalid\n"
            unless @stat && -d _ && !-l _
                && $stat[0] == $root_device
                && $stat[4] == $root_owner;
    }
}

sub _create_directory_exclusive {
    my ($relative, $root_device, $root_owner) = @_;
    my $path = _absolute($relative);
    mkdir($path, 0700)
        or die "cannot create exclusive evidence directory\n";
    my @stat = lstat($path);
    die "exclusive evidence directory identity is invalid\n"
        unless @stat && -d _ && !-l _
            && $stat[0] == $root_device
            && $stat[4] == $root_owner;
}

sub _prune_empty_parents {
    my ($relative) = @_;
    while (defined($relative) && $relative ne '.' && $relative ne '') {
        my $path = _absolute($relative);
        last unless rmdir $path;
        $relative = dirname($relative);
    }
}

sub _read_stream_bounded {
    my ($fh, $max_bytes, $label) = @_;
    my $bytes = '';
    while (1) {
        my $read = read($fh, my $chunk, 16_384);
        die "cannot read $label\n" unless defined $read;
        last if $read == 0;
        $bytes .= $chunk;
        die "$label exceeds bounded read\n"
            if bytes::length($bytes) > $max_bytes;
    }
    close $fh or die "cannot close $label\n";
    return $bytes;
}

sub _decode_canonical_line {
    my ($bytes, $label) = @_;
    die "$label is not one canonical JSON line\n"
        unless $bytes =~ s/\n\z// && $bytes !~ /[\r\n]/;
    return _decode_canonical($bytes, $label);
}

sub _decode_canonical {
    my ($bytes, $label) = @_;
    my $value = eval { $JSON->decode($bytes) };
    die "$label is not valid JSON\n" if $@;
    die "$label changed type\n" unless ref($value) eq 'HASH';
    die "$label is not canonical JSON\n"
        unless _canonical($value) eq $bytes;
    return $value;
}

sub _canonical {
    my ($value) = @_;
    return $JSON->encode($value);
}

sub _same {
    my ($left, $right) = @_;
    return _canonical($left) eq _canonical($right);
}

sub _integer_equals {
    my ($value, $expected) = @_;
    return 0 if !defined($value) || ref($value);
    return 0 unless "$value" =~ /\A(?:0|[1-9][0-9]*)\z/;
    return $value == $expected;
}

sub _exists {
    my ($relative) = @_;
    my $path = _absolute($relative);
    return -e $path || -l $path;
}

sub _absolute {
    my ($relative) = @_;
    _safe_relative($relative, 'repository path');
    return File::Spec->catfile($ROOT, split m{/}, $relative);
}

sub _safe_relative {
    my ($relative, $label) = @_;
    die "$label is unsafe\n"
        if !defined($relative) || ref($relative) || $relative eq ''
            || File::Spec->file_name_is_absolute($relative)
            || $relative =~ /(?:\A|\/)\.\.?(?:\/|\z)/
            || $relative =~ m{//}
            || $relative =~ /[\\\0\r\n]/;
    return 1;
}

sub _sanitize_error {
    my ($error) = @_;
    $error = 'unknown evidence materialization failure'
        unless defined($error) && !ref($error) && $error ne '';
    $error =~ s/\s+at\s+\S+\s+line\s+\d+[.]?\s*\z//;
    $error =~ s/[\r\n]+/ /g;
    $error =~ s/\s+/ /g;
    $error =~ s/^\s+|\s+$//g;
    $error = substr($error, 0, 1_024);
    return $error;
}

sub _boundary {
    return 1;
}
