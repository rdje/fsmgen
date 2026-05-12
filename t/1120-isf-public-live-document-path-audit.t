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
    isf_public_interface_live_document_paths
);

my $repo_root = File::Spec->rel2abs(File::Spec->catdir($FindBin::Bin, '..'));
my $expected_paths = isf_public_interface_live_document_paths();

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

subtest 'ISF public contract publishes the expected live document list' => sub {
    for my $view (@contract_views) {
        is_deeply(
            $view->{contract}{live_document_paths},
            $expected_paths,
            "$view->{label} keeps the owner live document path list",
        );
    }
};

subtest 'ISF public live document paths are repo-local markdown files' => sub {
    for my $view (@contract_views) {
        my $paths = $view->{contract}{live_document_paths};
        my $label = $view->{label};

        ok(ref($paths) eq 'ARRAY', "$label keeps live_document_paths as an array");
        ok(@{$paths || []}, "$label keeps live_document_paths non-empty");

        my %seen;
        for my $path (@{$paths || []}) {
            ok(!ref($path), "$label path entry $path is scalar");
            next if ref($path);

            ok(!File::Spec->file_name_is_absolute($path), "$label path $path is repo-relative");
            unlike($path, qr{(?:\A|/)\.\.(?:/|\z)}, "$label path $path does not escape the repo");
            like($path, qr{\.md\z}, "$label path $path points at markdown");
            ok(!$seen{$path}++, "$label path $path is unique");
            ok(-f repo_file($path), "$label path $path exists on disk");
        }
    }
};

done_testing();

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
