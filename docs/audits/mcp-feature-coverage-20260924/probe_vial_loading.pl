use strict;
use warnings;
use lib 'perl';
use JSON::PP ();
use bytes ();
use FSM::VIAL::ToolCLI;
use FSM::ProjectDataLocality qw(repository_root create_project_tempdir);
use FSM::Support::VIALToolingContract qw(build_vial_tooling_contract);
my $root = create_project_tempdir(purpose => 'vial-source-loading-probe');
my $limit = build_vial_tooling_contract()->{limits}{source_bytes};
open my $file, '>:raw', "$root/oversize.vial" or die $!;
print {$file} ' ' x ($limit + 1); close $file or die $!;
my ($text, $error) = FSM::VIAL::ToolCLI::_read_repo_source($root, 'oversize.vial', 'vial');
my $output = '';
my $exit;
{
    open my $capture, '>', \$output or die $!;
    local *STDOUT = $capture;
    $exit = FSM::VIAL::ToolCLI->run({repo_root => $root, argv => ['check', '--json', 'oversize.vial']});
}
my $report = JSON::PP->new->decode($output);
print JSON::PP->new->canonical->pretty->encode({
    declared_source_byte_limit => $limit,
    loaded_bytes_before_semantic_validation => defined($text) ? bytes::length($text) : 0,
    loader_error => $error,
    native_cli_exit => $exit,
    native_diagnostic_codes => [map { $_->{code} } @{$report->{diagnostics}}],
    source => 'oversize.vial',
});
