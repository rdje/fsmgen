#!/usr/bin/env perl
use strict;
use warnings;

use Cwd qw(abs_path);
use File::Basename qw(dirname);
use File::Path qw(make_path);
use File::Spec;
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP;
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use FSM::ProjectDataLocality qw(create_project_tempdir);

my $repo = abs_path(File::Spec->catdir($FindBin::Bin, '..'));
my $indexer = File::Spec->catfile($repo, 'scripts', 'focused_document_index.pl');
my $partition = File::Spec->catfile(
    $repo, 'scripts', 'check_isf_reference_partitions.pl');

ok(-x $indexer, 'focused-document index verifier is executable');
ok(-x $partition, 'ISF semantic-part verifier is executable');

subtest 'real generated index and exact activation partition pass' => sub {
    my ($index_ok, $index_output) = run_command($indexer, '--root', $repo, 'check');
    ok($index_ok, 'repository focused-document index is current') or diag($index_output);
    like($index_output, qr/1022 members/, 'complete focused plus ancillary census is reported');

    my ($part_ok, $part_output) = run_command(
        $partition, '--root', $repo, '--verify-activation-content', 'check');
    ok($part_ok, 'current semantic parts equal the exact transformed activation sources')
        or diag($part_output);
    like($part_output, qr/3 exact sources map contiguously to 11 bounded semantic parts/,
        'success reports exact source and semantic-part coverage');
};

subtest 'generated index rejects stale and unclassified membership' => sub {
    my $fixture = create_project_tempdir(purpose => 'focused-document-index-tests');
    seed_index_fixture($fixture);

    my ($generate_ok, $generate_output) = run_command(
        $indexer, '--root', $fixture, 'generate');
    ok($generate_ok, 'minimal complete classification fixture generates')
        or diag($generate_output);
    my ($check_ok, $check_output) = run_command($indexer, '--root', $fixture, 'check');
    ok($check_ok, 'fresh fixture projection passes') or diag($check_output);

    my $output = File::Spec->catfile(
        $fixture, qw(docs index FOCUSED_DOCUMENTS.md));
    append_file($output, "stale\n");
    my ($stale_ok, $stale_output) = run_command($indexer, '--root', $fixture, 'check');
    ok(!$stale_ok, 'stale generated projection fails');
    like($stale_output, qr/stale generated index/, 'stale failure names regeneration action');

    my ($refresh_ok, $refresh_output) = run_command(
        $indexer, '--root', $fixture, 'generate');
    ok($refresh_ok, 'fixture projection regenerates') or diag($refresh_output);
    write_file(File::Spec->catfile($fixture, qw(docs MYSTERY.md)), "mystery\n");
    my ($unknown_ok, $unknown_output) = run_command(
        $indexer, '--root', $fixture, 'check');
    ok(!$unknown_ok, 'unclassified focused document fails');
    like($unknown_output, qr/unclassified focused document: docs\/MYSTERY\.md/,
        'unclassified path is named');
};

subtest 'partition manifest rejects gaps and source-identity drift' => sub {
    my $gap = copied_manifest();
    mutate_manifest($gap->{path}, sub {
        return if ($_[0]{path} // '') ne
            'docs/isf-spec/02-interface-transactions.md';
        $_[0]{source_start}++;
    });
    my ($gap_ok, $gap_output) = run_command(
        $partition, '--root', $repo, '--manifest', $gap->{relative}, 'check');
    ok(!$gap_ok, 'partition gap fails');
    like($gap_output, qr/gap or overlap/, 'gap failure names the partition invariant');

    my $identity = copied_manifest();
    mutate_manifest($identity->{path}, sub {
        return if ($_[0]{record_type} // '') ne 'source'
            || ($_[0]{source_id} // '') ne 'isf_public';
        $_[0]{sha256} = '0' x 64;
    });
    my ($identity_ok, $identity_output) = run_command(
        $partition, '--root', $repo, '--manifest', $identity->{relative}, 'check');
    ok(!$identity_ok, 'wrong activation-source digest fails');
    like($identity_output, qr/archived identity mismatch/, 'identity failure is explicit');
};

subtest 'partition link verification fails on a missing routed target' => sub {
    my $fixture = create_project_tempdir(purpose => 'isf-partition-link-tests');
    seed_partition_current_fixture($fixture);
    my ($baseline_ok, $baseline_output) = run_command(
        $partition, '--root', $repo, '--current-root', $fixture,
        '--verify-activation-content', 'check');
    ok($baseline_ok, 'isolated current-reference fixture passes') or diag($baseline_output);

    my $target = File::Spec->catfile(
        $fixture, qw(docs tasks ISF-STAGES-CONTRACTS.md));
    ok(unlink($target), 'remove one exact routed target from the isolated fixture');
    my ($missing_ok, $missing_output) = run_command(
        $partition, '--root', $repo, '--current-root', $fixture, 'check');
    ok(!$missing_ok, 'missing local-link target fails');
    like($missing_output, qr/broken local link .*ISF-STAGES-CONTRACTS\.md/,
        'failure names the broken target');
};

done_testing();

sub run_command {
    my ($program, @args) = @_;
    my ($ok, undef, undef, $stdout, $stderr) = run(
        command => [$^X, $program, @args],
    );
    return ($ok, join('', @{$stdout || []}, @{$stderr || []}));
}

sub seed_index_fixture {
    my ($root) = @_;
    my @focused = qw(
        ISF_SPEC.md
        ISF_DOWNSTREAM_INTEGRATION_SPEC.md
        ISF_PUBLIC_INTERFACE_CONTRACT.md
        BIN_FSMGEN_IMPORT_TREE.md
        COMPOSITION_SCOPE.md
        DOWNSTREAM_ISSUE_REPORTING.md
        EXTENSION_MODEL.md
        FEATURE_BACKLOG.md
        FSMGEN_SOURCE_HIR_CONCRETE_CONTROL_V2_CONTRACT.md
        FSMGEN_SOURCE_HIR_V1_CONTRACT.md
        HIAL_VIAL_BRIDGE_MANIFEST_V1_CONTRACT.md
        IAL2_NEW_PROTOCOL_SUPPORT_WORKFLOW.md
        ISF_LIBRARY_CATALOG.md
        NEXSIM_API_MCP_AGENT_CONSUMER_REQUIREMENTS.md
        PDF_EXTRACTION_WORKFLOW.md
        REGRESSION_CORPUS.md
        TASK_TREE_LIVE_NODE_INTEGRITY.md
        VHDL_SCOPE.md
        VIAL_EXECUTION_IR_V1_CONTRACT.md
        VIAL_PORTABLE_SYSTEMVERILOG_BACKEND_V1_CONTRACT.md
        VIAL_PUBLIC_TOOLING_V1_CONTRACT.md
        VIAL_SOURCE_AND_SEMANTIC_IR_V1_CONTRACT.md
        LIVE_DOCUMENT_SIZE_CONTAINMENT_ADOPTION_GUIDE.md
        LIVE_DOCUMENT_SIZE_CONTAINMENT_EXTERNAL_REVIEW_DISPOSITION.md
        LIVE_DOCUMENT_SIZE_CONTAINMENT_EXTERNAL_REVIEW_PACKET.md
        LIVE_DOCUMENT_SIZE_CONTAINMENT_REVIEW.md
        TASK_TREE.md
        TASK_TREE_README.md
        AXI_MANAGER_USER_API_BRAINSTORM.md
        INTENT_CAPTURE_AXI_CASE_STUDY.md
        INTENT_SCHEDULING_BRAINSTORM.md
        EXAMPLE_AUDIT.md
    );
    write_file(File::Spec->catfile($root, 'docs', $_), "# $_\n") for @focused;
    write_file(File::Spec->catfile($root, qw(docs audits REVIEW.md)), "# Review\n");
    write_file(File::Spec->catfile($root, qw(.github README.md)), "# GitHub\n");

    my $json = JSON::PP->new->canonical(1)->utf8(1);
    my @records = (
        {record_type => 'registry', schema_version => 1},
        {surface_id => 'focused_documents', targets => ['docs/*.md']},
        {surface_id => 'ancillary_documents',
            targets => ['docs/audits/*.md', '.github/*.md']},
    );
    write_file(
        File::Spec->catfile(
            $root, qw(doctrine live_document_size surfaces.jsonl)),
        join('', map { $json->encode($_) . "\n" } @records),
    );
}

sub copied_manifest {
    my $directory = create_project_tempdir(purpose => 'isf-partition-manifest-tests');
    my $path = File::Spec->catfile($directory, 'manifest.jsonl');
    write_file($path, slurp(File::Spec->catfile(
        $repo, qw(doctrine live_document_size isf_reference_partitions.jsonl))));
    my $relative = File::Spec->abs2rel($path, $repo);
    $relative =~ s{\\}{/}g;
    return {path => $path, relative => $relative};
}

sub seed_partition_current_fixture {
    my ($fixture) = @_;
    my @records = map { JSON::PP::decode_json($_) }
        grep { $_ ne '' } split /\n/, slurp(File::Spec->catfile(
            $repo, qw(doctrine live_document_size isf_reference_partitions.jsonl)));
    my %current_paths;
    for my $record (@records) {
        my $relative = ($record->{record_type} // '') eq 'source'
            ? $record->{landing}
            : ($record->{record_type} // '') eq 'part'
                ? $record->{path}
                : undef;
        next if !defined $relative;
        $current_paths{$relative} = 1;
        write_file(
            File::Spec->catfile($fixture, split m{/}, $relative),
            slurp(File::Spec->catfile($repo, split m{/}, $relative)),
        );
    }

    for my $relative (sort keys %current_paths) {
        my $contents = slurp(File::Spec->catfile($repo, split m{/}, $relative));
        while ($contents =~ /\]\((?:<([^>]+)>|([^\s\)]+))(?:\s+[^\)]*)?\)/g) {
            my $destination = defined($1) ? $1 : $2;
            $destination =~ s/[?#].*\z//;
            next if $destination eq ''
                || $destination =~ /\A(?:[a-z][a-z0-9+.-]*:|#)/i;
            my $actual = abs_path(File::Spec->catfile(
                $repo, dirname($relative), split(m{/+}, $destination),
            ));
            die "fixture source has unresolved link $relative -> $destination"
                if !defined $actual;
            my $target_relative = File::Spec->abs2rel($actual, $repo);
            my $target = File::Spec->catfile(
                $fixture, split m{/+}, $target_relative);
            next if -e $target;
            if (-d $actual) {
                make_path($target);
            } else {
                write_file($target, "link target fixture\n");
            }
        }
    }
}

sub mutate_manifest {
    my ($path, $mutator) = @_;
    my @records = map { JSON::PP::decode_json($_) }
        grep { $_ ne '' } split /\n/, slurp($path);
    $mutator->($_) for @records;
    my $json = JSON::PP->new->canonical(1)->utf8(1);
    write_file($path, join('', map { $json->encode($_) . "\n" } @records));
}

sub slurp {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "cannot read $path: $!";
    local $/;
    my $contents = <$fh> // '';
    close $fh;
    return $contents;
}

sub write_file {
    my ($path, $contents) = @_;
    make_path(dirname($path)) if !-d dirname($path);
    open my $fh, '>:raw', $path or die "cannot write $path: $!";
    print {$fh} $contents or die "cannot write $path: $!";
    close $fh or die "cannot close $path: $!";
}

sub append_file {
    my ($path, $contents) = @_;
    open my $fh, '>>:raw', $path or die "cannot append $path: $!";
    print {$fh} $contents or die "cannot append $path: $!";
    close $fh or die "cannot close $path: $!";
}
