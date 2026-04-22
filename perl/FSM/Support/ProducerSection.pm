package FSM::Support::ProducerSection;

use strict;
use warnings;

use Exporter 'import';
use File::Basename qw(dirname);
use File::Spec;
use JSON::PP ();

use FSM::Support::ProducerContract qw(build_producer_contract);

our @EXPORT_OK = qw(
    build_producer_section
);

sub build_producer_section {
    return {
        name => 'FSMGen',
        version => '0.1-dev',
        git_commit => _git_head_short() || 'unknown',
        contract_authority => JSON::PP::true,
        source => 'FSM::Support::CapabilityManifest',
        section_contract => build_producer_contract(),
    };
}

sub _git_head_short {
    my $repo_root = File::Spec->rel2abs(
        File::Spec->catdir(dirname(__FILE__), '..', '..', '..'),
    );
    my $git_dir = File::Spec->catdir($repo_root, '.git');
    my $head_path = File::Spec->catfile($git_dir, 'HEAD');
    return undef unless -f $head_path;

    open my $head_fh, '<', $head_path or return undef;
    my $head = <$head_fh>;
    close $head_fh or return undef;
    return undef unless defined $head;
    chomp $head;

    if ($head =~ /^ref:\s*(.+)$/) {
        my $ref_path = File::Spec->catfile($git_dir, split m{/}, $1);
        return undef unless -f $ref_path;
        open my $ref_fh, '<', $ref_path or return undef;
        my $commit = <$ref_fh>;
        close $ref_fh or return undef;
        return _short_commit($commit);
    }

    return _short_commit($head);
}

sub _short_commit {
    my ($commit) = @_;
    return undef unless defined $commit;
    chomp $commit;
    return undef unless $commit =~ /\A([0-9a-fA-F]{7,40})\z/;
    return substr(lc($1), 0, 12);
}

1;
