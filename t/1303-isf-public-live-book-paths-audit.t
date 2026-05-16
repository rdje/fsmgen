#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP qw(decode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::ISFPublicInterfaceContract qw(
    build_isf_public_interface_contract
);

my $repo_root = File::Spec->rel2abs(File::Spec->catdir($FindBin::Bin, '..'));
my @expected_isf_book_paths = expected_isf_book_paths_from_summary();
my @expected_support_book_paths = qw(
    docs/book/src/14-feature-backlog.md
    docs/book/src/90-reference-map.md
);

ok(@expected_isf_book_paths > 1, 'summary exposes ISF overview plus child book chapters');
is($expected_isf_book_paths[0], 'docs/book/src/13-intent-scheduling.md', 'ISF overview is first book path');
ok(
    scalar grep { $_ eq 'docs/book/src/13j-type-enum-aggregate.md' } @expected_isf_book_paths,
    'summary exposes the type/enum/aggregate shipped-surface chapter',
);

my @contract_views = (
    {
        label => 'direct ISF public-interface contract',
        contract => build_isf_public_interface_contract(),
    },
    {
        label => 'in-process capability manifest',
        contract => build_capability_manifest()->{embedding}{isf_public_interface},
    },
    {
        label => 'CLI capability manifest',
        contract => run_manifest('--capability-manifest')->{embedding}{isf_public_interface},
    },
    {
        label => 'CLI alias capability manifest',
        contract => run_manifest('--emit-capability-manifest')->{embedding}{isf_public_interface},
    },
);

for my $view (@contract_views) {
    my $label = $view->{label};
    my $paths = $view->{contract}{live_document_paths};

    ok(ref($paths) eq 'ARRAY', "$label exposes live_document_paths as an array");
    next unless ref($paths) eq 'ARRAY';

    my @advertised_isf_book_paths =
        grep { m{\Adocs/book/src/13[a-z]?-.*\.md\z} } @{$paths};

    is_deeply(
        \@advertised_isf_book_paths,
        \@expected_isf_book_paths,
        "$label advertises exactly the ISF mdBook chapter set from SUMMARY order",
    );

    my %path_present = map { $_ => 1 } @{$paths};
    for my $path (@expected_support_book_paths) {
        ok($path_present{$path}, "$label advertises support book path $path");
    }
}

done_testing();

sub expected_isf_book_paths_from_summary {
    my $summary_path = repo_file('docs/book/src/SUMMARY.md');
    open my $summary_fh, '<', $summary_path
        or die "Unable to read $summary_path: $!";
    my $summary = do { local $/; <$summary_fh> };
    close $summary_fh;

    my @files = $summary =~ m{^\s*-\s+\[[^\]]+\]\((13[a-z]?-.*?\.md)\)}mg;
    return map { "docs/book/src/$_" } @files;
}

sub run_manifest {
    my ($mode) = @_;
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', $mode],
    );

    ok($success, "$mode succeeds");
    is(join('', @{$stderr_buf || []}), '', "$mode keeps stderr clean");

    return decode_json(join('', @{$stdout_buf || []}));
}

sub repo_file {
    my ($relpath) = @_;
    return File::Spec->catfile($repo_root, split m{/}, $relpath);
}
