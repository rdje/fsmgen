#!/usr/bin/env perl

use v5.20;
use strict;
use warnings;

use bytes ();
use Digest::SHA qw(sha256_hex);
use Fcntl qw(LOCK_EX LOCK_NB O_RDONLY O_NOFOLLOW);
use File::Basename qw(dirname);
use File::Copy qw(copy);
use File::Find qw(find);
use File::Path qw(make_path remove_tree);
use FindBin;
use File::Spec;
use IPC::Open3 qw(open3);
use JSON::PP ();
use POSIX qw(mkfifo);
use Symbol qw(gensym);
use Test::More;

my $root = File::Spec->catdir($FindBin::Bin, '..');
my $materializer = File::Spec->catfile(
    $root,
    'scripts',
    'materialize_vial_regression_promotion_gate_evidence.pl',
);

ok -x $materializer, 'tracked evidence materializer exists';

my $scratch = File::Spec->catdir(
    $root,
    '.artifacts',
    'tmp',
    "vial-regression-promotion-evidence-materialization-$$",
);
my $fixture = File::Spec->catdir($scratch, 'fixture');
my $fixture_materializer = File::Spec->catfile(
    $fixture,
    'scripts',
    'materialize_vial_regression_promotion_gate_evidence.pl',
);
my $bundle_relative =
    'vial/qualification/regression_promotion_gate/evidence-v1';
my $destination_base = '.artifacts/qualification/vial-scale/v2';
my $corpus_relative =
    "$destination_base/regression-promotion-corpus-v1";
my $qualification_relative =
    "$destination_base/regression-promotion-budget-qualification-v1";
my $state_relative = join '/', qw(
    .artifacts tmp vial-scale
    regression-promotion-gate-evidence-transport v1
);
my $bundle_digest =
    '3b4c486e8e3f853f626d85d2abc713846d0594230d922913c8655be3f682bbc6';
my $transaction_relative =
    "$state_relative/transactions/$bundle_digest";
my $journal_relative = "$transaction_relative/journal.json";
my $receipt_relative = "$state_relative/receipts/$bundle_digest.json";
my $json = JSON::PP->new->canonical(1)->utf8(1);

END {
    _remove_tree($scratch) if defined($scratch) && -e $scratch;
}

_remove_tree($scratch) if -e $scratch;
make_path(File::Spec->catdir($fixture, 'scripts'));
for my $script (qw(
    materialize_vial_regression_promotion_gate_evidence.pl
    verify_vial_regression_promotion_evidence_transport.pl
    verify_vial_regression_promotion_current_corpus.pl
    verify_vial_regression_promotion_budget_qualification.pl
)) {
    copy(
        File::Spec->catfile($root, 'scripts', $script),
        File::Spec->catfile($fixture, 'scripts', $script),
    ) or die "cannot copy fixture script $script: $!";
}
_copy_tree(
    File::Spec->catdir($root, split m{/}, $bundle_relative),
    File::Spec->catdir($fixture, split m{/}, $bundle_relative),
);

my $materializer_bytes = _read_raw($fixture_materializer);
my $manifest = $json->decode(_read_raw(_fixture_path(
    "$bundle_relative/transport-manifest.json",
)));
my $first_entry = $manifest->{entries}[0];
my $first_source = _fixture_path(
    "$bundle_relative/$first_entry->{source_relative_path}",
);
my $first_destination = _fixture_path(
    $first_entry->{destination_relative_path},
);
my $first_bytes = _read_raw($first_source);

subtest 'fresh, exact-existing, production validation, and owned cleanup' => sub {
    _reset_generated();
    my $fresh = _run_materializer('materialize');
    is $fresh->{exit}, 0, 'fresh materialization succeeds';
    is $fresh->{stderr}, '', 'fresh materialization is diagnostically quiet';
    my $fresh_result = _decode_result($fresh->{stdout});
    is $fresh_result->{outcome}, 'materialized',
        'fresh result reports materialized';
    is_deeply $fresh_result->{receipt}{created_roots},
        [$corpus_relative, $qualification_relative],
        'fresh receipt owns exactly the two installed roots';

    my $corpus = _run_script(
        'verify_vial_regression_promotion_current_corpus.pl',
    );
    is $corpus->{exit}, 0,
        'production current-corpus validator accepts fresh materialization';
    is $corpus->{stderr}, '', 'corpus validator is quiet';
    my $qualification = _run_script(
        'verify_vial_regression_promotion_budget_qualification.pl',
    );
    is $qualification->{exit}, 0,
        'production qualification validator accepts fresh materialization';
    is $qualification->{stderr}, '', 'qualification validator is quiet';

    my $again = _run_materializer('materialize');
    is $again->{exit}, 0, 'exact existing materialization is idempotent';
    is _decode_result($again->{stdout})->{outcome},
        'already_materialized', 'idempotent result is explicit';
    is $again->{stderr}, '', 'idempotent materialization is quiet';

    my $cleanup = _run_materializer('cleanup');
    is $cleanup->{exit}, 0, 'owned cleanup succeeds';
    is _decode_result($cleanup->{stdout})->{outcome}, 'cleaned',
        'cleanup reports owned removal';
    is $cleanup->{stderr}, '', 'owned cleanup is quiet';
    _assert_no_evidence_state('fresh cleanup leaves no evidence state');

    my $empty = _run_materializer('cleanup');
    is $empty->{exit}, 0, 'empty cleanup is idempotent';
    is _decode_result($empty->{stdout})->{outcome}, 'nothing_owned',
        'empty cleanup claims nothing';
};

subtest 'pre-existing exact evidence is adopted but never cleanup-owned' => sub {
    _reset_generated();
    my $fresh = _run_materializer('materialize');
    is $fresh->{exit}, 0, 'setup materialization succeeds';
    unlink _fixture_path($receipt_relative)
        or die "cannot remove setup receipt: $!";
    _prune_empty(dirname($receipt_relative));

    my $adopted = _run_materializer('materialize');
    is $adopted->{exit}, 0, 'exact unreceipted evidence is adopted';
    my $adopted_result = _decode_result($adopted->{stdout});
    is $adopted_result->{outcome}, 'adopted_exact',
        'adoption is explicit';
    is_deeply $adopted_result->{receipt}{created_roots}, [],
        'adopted receipt owns no destination root';

    my $cleanup = _run_materializer('cleanup');
    is $cleanup->{exit}, 0, 'adopted receipt cleanup succeeds';
    is _decode_result($cleanup->{stdout})->{outcome},
        'released_adopted_receipt', 'cleanup releases only adopted receipt';
    ok -d _fixture_path($corpus_relative),
        'adopted corpus remains';
    ok -d _fixture_path($qualification_relative),
        'adopted qualification remains';
    _remove_tree(_fixture_path($corpus_relative));
    _remove_tree(_fixture_path($qualification_relative));
    _prune_empty($destination_base);
};

subtest 'caller, lock, source, destination, and partial controls fail closed' => sub {
    _reset_generated();
    for my $args (
        [],
        ['materialize', 'caller-root'],
        ['cleanup', 'caller-receipt'],
        ['unknown'],
    ) {
        my $run = _run_command($^X, $fixture_materializer, @{$args});
        isnt $run->{exit}, 0, 'caller-controlled operation input is rejected';
        is $run->{stdout}, '', 'caller rejection emits no partial result';
        like $run->{stderr}, qr/\Ausage: scripts\/materialize_/,
            'caller rejection uses bounded usage diagnostic';
    }

    sysopen(
        my $lock,
        _fixture_path("$bundle_relative/transport-manifest.json"),
        O_RDONLY | O_NOFOLLOW,
    ) or die "cannot open fixture lock: $!";
    flock($lock, LOCK_EX | LOCK_NB)
        or die "cannot acquire fixture lock: $!";
    my $collision = _run_materializer('materialize');
    isnt $collision->{exit}, 0, 'concurrent process lock rejects';
    is $collision->{stdout}, '', 'lock collision emits no partial result';
    like $collision->{stderr}, qr/concurrently owned/,
        'lock collision is stable and sanitized';
    close $lock or die "cannot close fixture lock: $!";

    _write_raw($first_source, $first_bytes . " ");
    my $source_mutation = _run_materializer('materialize');
    isnt $source_mutation->{exit}, 0, 'source mutation rejects';
    is $source_mutation->{stdout}, '',
        'source mutation emits no partial result';
    _assert_no_evidence_state('source mutation creates no evidence state');
    _write_raw($first_source, $first_bytes);

    make_path(_fixture_path($corpus_relative));
    my $partial = _run_materializer('materialize');
    isnt $partial->{exit}, 0, 'partial destination rejects';
    is $partial->{stdout}, '', 'partial destination emits no result';
    ok -d _fixture_path($corpus_relative),
        'partial destination is not overwritten';
    _remove_tree(_fixture_path($corpus_relative));
    _prune_empty($destination_base);

    my $fresh = _run_materializer('materialize');
    is $fresh->{exit}, 0, 'destination-mutation setup succeeds';
    _write_raw($first_destination, $first_bytes . " ");
    my $destination_mutation = _run_materializer('materialize');
    isnt $destination_mutation->{exit}, 0, 'destination mutation rejects';
    is $destination_mutation->{stdout}, '',
        'destination mutation emits no partial result';
    is _read_raw($first_destination), $first_bytes . " ",
        'destination mismatch is not overwritten';
    _write_raw($first_destination, $first_bytes);
    my $cleanup = _run_materializer('cleanup');
    is $cleanup->{exit}, 0, 'restored exact destination cleans';
};

subtest 'every install boundary recovers only the exact transaction' => sub {
    for my $boundary (qw(
        journal_committed corpus_installed qualification_installed
        receipt_committed
    )) {
        _reset_generated();
        _instrument_boundary($boundary);
        my $interrupted = _run_materializer('materialize');
        isnt $interrupted->{exit}, 0, "$boundary interruption is observed";
        is $interrupted->{stdout}, '',
            "$boundary interruption emits no partial result";
        _write_raw($fixture_materializer, $materializer_bytes);

        my $recovered = _run_materializer('materialize');
        is $recovered->{exit}, 0, "$boundary transaction recovers";
        is _decode_result($recovered->{stdout})->{outcome}, 'recovered',
            "$boundary recovery is explicit";
        my $corpus = _run_script(
            'verify_vial_regression_promotion_current_corpus.pl',
        );
        is $corpus->{exit}, 0,
            "$boundary recovery passes production corpus validation";
        my $qualification = _run_script(
            'verify_vial_regression_promotion_budget_qualification.pl',
        );
        is $qualification->{exit}, 0,
            "$boundary recovery passes production qualification validation";
        my $cleanup = _run_materializer('cleanup');
        is $cleanup->{exit}, 0, "$boundary recovered evidence cleans";
        _assert_no_evidence_state(
            "$boundary recovery cleanup leaves no residue",
        );
    }
};

subtest 'malformed, stale, mixed, and partial transaction state rejects' => sub {
    _reset_generated();
    my $stale_identity = '0' x 64;
    make_path(_fixture_path(
        "$state_relative/transactions/$stale_identity",
    ));
    my $stale_namespace = _run_materializer('materialize');
    isnt $stale_namespace->{exit}, 0,
        'stale identity-scoped transaction namespace rejects';
    is $stale_namespace->{stdout}, '',
        'stale transaction namespace emits no partial result';
    ok -d _fixture_path("$state_relative/transactions/$stale_identity"),
        'unowned stale identity is not removed';

    for my $mutation (
        sub {
            my $path = _fixture_path($journal_relative);
            _write_raw($path, _read_raw($path) . " ");
        },
        sub {
            my $path = _fixture_path($journal_relative);
            my $value = $json->decode(_one_json_line(_read_raw($path)));
            $value->{bundle_identity} =~ s/.$/0/;
            _write_json_line($path, $value);
        },
        sub {
            _write_raw(
                _fixture_path("$transaction_relative/stage/extra.json"),
                "{}\n",
            );
        },
        sub {
            unlink _fixture_path(
                "$transaction_relative/stage/"
                . substr(
                    $first_entry->{destination_relative_path},
                    length("$destination_base/"),
                ),
            ) or die "cannot remove staged fixture file: $!";
        },
    ) {
        _prepare_interrupted('journal_committed');
        $mutation->();
        my $rejected = _run_materializer('materialize');
        isnt $rejected->{exit}, 0, 'invalid transaction rejects';
        is $rejected->{stdout}, '',
            'invalid transaction emits no partial result';
        ok !-e _fixture_path($transaction_relative),
            'safe invalid transaction is discarded exactly';
        ok !-e _fixture_path($corpus_relative)
                && !-e _fixture_path($qualification_relative),
            'invalid transaction installs no destination';
    }

    _prepare_interrupted('journal_committed');
    make_path(_fixture_path($corpus_relative));
    my $mixed = _run_materializer('materialize');
    isnt $mixed->{exit}, 0, 'mixed transaction/destination rejects';
    is $mixed->{stdout}, '', 'mixed state emits no partial result';
    ok -e _fixture_path($transaction_relative),
        'mixed state is preserved when a destination prevents safe discard';
    _remove_tree(_fixture_path($corpus_relative));
    my $abort = _run_materializer('cleanup');
    is $abort->{exit}, 0, 'restored prepared transaction cleanup succeeds';
    _assert_no_evidence_state('prepared transaction cleanup leaves no residue');
};

subtest 'links, aliases, and special files are never traversed or removed' => sub {
    _prepare_interrupted('journal_committed');
    my $outside = File::Spec->catfile($scratch, 'outside-symlink-target');
    _write_raw($outside, "outside\n");
    my $symlink = _fixture_path(
        "$transaction_relative/stage/hostile-link",
    );
    symlink $outside, $symlink or die "cannot create fixture symlink: $!";
    my $link_reject = _run_materializer('materialize');
    isnt $link_reject->{exit}, 0, 'staged symlink rejects';
    is _read_raw($outside), "outside\n",
        'symlink target is untouched';
    ok -l $symlink, 'unsafe transaction is not recursively removed';
    unlink $symlink or die "cannot remove fixture symlink: $!";
    is _run_materializer('cleanup')->{exit}, 0,
        'restored symlink fixture transaction cleans';

    _prepare_interrupted('journal_committed');
    my $staged_first = _fixture_path(
        "$transaction_relative/stage/"
        . substr(
            $first_entry->{destination_relative_path},
            length("$destination_base/"),
        ),
    );
    my $alias = _fixture_path(
        "$transaction_relative/stage/hostile-hardlink",
    );
    link $staged_first, $alias or die "cannot create fixture hardlink: $!";
    my $alias_reject = _run_materializer('materialize');
    isnt $alias_reject->{exit}, 0, 'staged hardlink alias rejects';
    ok -e $alias, 'unsafe hardlink transaction is preserved';
    unlink $alias or die "cannot remove fixture hardlink: $!";
    is _run_materializer('cleanup')->{exit}, 0,
        'restored hardlink fixture transaction cleans';

    _prepare_interrupted('journal_committed');
    my $fifo = _fixture_path("$transaction_relative/stage/hostile-fifo");
    mkfifo($fifo, 0600) or die "cannot create fixture FIFO: $!";
    my $fifo_reject = _run_materializer('materialize');
    isnt $fifo_reject->{exit}, 0, 'staged special file rejects';
    ok -p $fifo, 'unsafe special-file transaction is preserved';
    unlink $fifo or die "cannot remove fixture FIFO: $!";
    is _run_materializer('cleanup')->{exit}, 0,
        'restored special-file fixture transaction cleans';
};

subtest 'receipt and cleanup authenticate ownership before deletion' => sub {
    _reset_generated();
    is _run_materializer('materialize')->{exit}, 0,
        'receipt-control setup materializes';
    my $receipt_path = _fixture_path($receipt_relative);
    my $receipt_bytes = _read_raw($receipt_path);

    _write_raw($first_source, $first_bytes . " ");
    my $source_changed = _run_materializer('cleanup');
    isnt $source_changed->{exit}, 0,
        'source mutation rejects receipt cleanup';
    ok -d _fixture_path($corpus_relative)
            && -d _fixture_path($qualification_relative),
        'source mutation deletes no evidence';
    _write_raw($first_source, $first_bytes);

    _write_raw($receipt_path, $receipt_bytes . " ");
    my $malformed = _run_materializer('cleanup');
    isnt $malformed->{exit}, 0, 'noncanonical receipt rejects cleanup';
    ok -d _fixture_path($corpus_relative)
            && -d _fixture_path($qualification_relative),
        'malformed receipt deletes no evidence';
    _write_raw($receipt_path, $receipt_bytes);

    my $receipt_value = $json->decode(_one_json_line($receipt_bytes));
    $receipt_value->{created_roots} = [];
    _write_json_line($receipt_path, $receipt_value);
    my $mixed = _run_materializer('cleanup');
    isnt $mixed->{exit}, 0, 'mixed receipt ownership rejects cleanup';
    ok -d _fixture_path($corpus_relative)
            && -d _fixture_path($qualification_relative),
        'mixed receipt deletes no evidence';
    _write_raw($receipt_path, $receipt_bytes);

    my $outside = File::Spec->catfile($scratch, 'outside-destination-target');
    _write_raw($outside, "outside-destination\n");
    unlink $first_destination
        or die "cannot remove destination fixture file: $!";
    symlink $outside, $first_destination
        or die "cannot create destination fixture symlink: $!";
    my $destination_link = _run_materializer('cleanup');
    isnt $destination_link->{exit}, 0,
        'destination symlink rejects cleanup';
    is _read_raw($outside), "outside-destination\n",
        'destination symlink target is untouched';
    unlink $first_destination
        or die "cannot remove destination fixture symlink: $!";
    copy($first_source, $first_destination)
        or die "cannot restore destination fixture file: $!";
    is _run_materializer('cleanup')->{exit}, 0,
        'restored exact receipt and destination clean';
    _assert_no_evidence_state('authenticated cleanup leaves no residue');
};

subtest 'result and diagnostic channels remain bounded and canonical' => sub {
    _reset_generated();
    my $run = _run_materializer('materialize');
    is $run->{exit}, 0, 'bounded-result setup materializes';
    ok bytes::length($run->{stdout}) <= 32_768,
        'materialization result stays within 32-KiB ceiling';
    my $result = _decode_result($run->{stdout});
    is $result->{schema},
        'fsmgen.vial_regression_promotion_gate_evidence_materialization_result.v1',
        'result schema is exact';
    is $json->encode($result) . "\n", $run->{stdout},
        'result is one canonical JSON line';
    my $result_identity = $result->{result_identity};
    $result->{result_identity} = undef;
    is $result_identity,
        'regression-promotion-gate-evidence-materialization-result/'
            . sha256_hex($json->encode($result)),
        'result identity derives from the canonical result projection';
    my $failure = _run_materializer('invalid');
    ok bytes::length($failure->{stderr}) <= 1_100,
        'diagnostic stays bounded';
    unlike $failure->{stderr}, qr/\Q$fixture\E/,
        'diagnostic exposes no fixture root';
    is _run_materializer('cleanup')->{exit}, 0,
        'bounded-result fixture cleans';
    _assert_no_evidence_state('final copied fixture has no residue');
};

done_testing;

sub _run_materializer {
    my (@args) = @_;
    return _run_command($^X, $fixture_materializer, @args);
}

sub _run_script {
    my ($name, @args) = @_;
    return _run_command(
        $^X,
        File::Spec->catfile($fixture, 'scripts', $name),
        @args,
    );
}

sub _run_command {
    my (@command) = @_;
    my $stderr = gensym;
    my $pid = open3(my $input, my $output, $stderr, @command);
    close $input;
    local $/;
    my $stdout_bytes = <$output> // '';
    my $stderr_bytes = <$stderr> // '';
    close $output or die "cannot close fixture stdout: $!";
    close $stderr or die "cannot close fixture stderr: $!";
    waitpid($pid, 0);
    return {
        exit => $? == -1 ? -1 : $? >> 8,
        stdout => $stdout_bytes,
        stderr => $stderr_bytes,
    };
}

sub _decode_result {
    my ($bytes) = @_;
    my $line = _one_json_line($bytes);
    my $value = $json->decode($line);
    is ref($value), 'HASH', 'result decodes as an object';
    return $value;
}

sub _one_json_line {
    my ($bytes) = @_;
    die "fixture value is not one JSON line"
        unless $bytes =~ s/\n\z// && $bytes !~ /[\r\n]/;
    return $bytes;
}

sub _prepare_interrupted {
    my ($boundary) = @_;
    _reset_generated();
    _instrument_boundary($boundary);
    my $run = _run_materializer('materialize');
    _write_raw($fixture_materializer, $materializer_bytes);
    die "fixture did not interrupt at $boundary"
        if $run->{exit} == 0;
}

sub _instrument_boundary {
    my ($boundary) = @_;
    my $bytes = $materializer_bytes;
    my $needle = "sub _boundary {\n    return 1;\n}\n";
    my $replacement = "sub _boundary {\n"
        . "    my (\$name) = \@_;\n"
        . "    die \"injected interruption\\n\" if \$name eq '$boundary';\n"
        . "    return 1;\n}\n";
    my $count = ($bytes =~ s/\Q$needle\E/$replacement/);
    die "cannot instrument fixture boundary $boundary"
        unless $count == 1;
    _write_raw($fixture_materializer, $bytes);
}

sub _reset_generated {
    my $artifacts = File::Spec->catdir($fixture, '.artifacts');
    _remove_tree($artifacts) if -e $artifacts || -l $artifacts;
    _write_raw($fixture_materializer, $materializer_bytes)
        if defined $materializer_bytes;
}

sub _assert_no_evidence_state {
    my ($label) = @_;
    ok !-e _fixture_path($corpus_relative)
            && !-l _fixture_path($corpus_relative)
            && !-e _fixture_path($qualification_relative)
            && !-l _fixture_path($qualification_relative)
            && !-e _fixture_path($state_relative)
            && !-l _fixture_path($state_relative),
        $label;
}

sub _fixture_path {
    my ($relative) = @_;
    return File::Spec->catfile($fixture, split m{/}, $relative);
}

sub _prune_empty {
    my ($relative) = @_;
    while (defined($relative) && $relative ne '.' && $relative ne '') {
        my $path = _fixture_path($relative);
        last unless rmdir $path;
        $relative = dirname($relative);
    }
}

sub _copy_tree {
    my ($source, $destination) = @_;
    find({
        no_chdir => 1,
        wanted => sub {
            my $path = $File::Find::name;
            die "fixture source contains a symlink"
                if -l $path;
            my $relative = File::Spec->abs2rel($path, $source);
            my $target = $relative eq '.'
                ? $destination
                : File::Spec->catfile($destination, $relative);
            if (-d $path) {
                make_path($target);
                return;
            }
            die "fixture source contains a special node"
                unless -f $path;
            make_path(dirname($target));
            copy($path, $target)
                or die "cannot copy fixture source: $!";
        },
    }, $source);
}

sub _read_raw {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "cannot read fixture file: $!";
    local $/;
    my $bytes = <$fh>;
    close $fh or die "cannot close fixture file: $!";
    return $bytes;
}

sub _write_raw {
    my ($path, $bytes) = @_;
    make_path(dirname($path));
    open my $fh, '>:raw', $path or die "cannot write fixture file: $!";
    print {$fh} $bytes or die "cannot write fixture file: $!";
    close $fh or die "cannot close fixture file: $!";
}

sub _write_json_line {
    my ($path, $value) = @_;
    _write_raw($path, $json->encode($value) . "\n");
}

sub _remove_tree {
    my ($path) = @_;
    return unless -e $path || -l $path;
    my $errors;
    remove_tree($path, {error => \$errors});
    die "cannot remove fixture tree"
        if ref($errors) eq 'ARRAY' && @{$errors};
}
