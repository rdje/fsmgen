package FSM::Test::AhbReference;

use v5.20;
use strict;
use warnings;

use bytes ();
use Cwd qw(abs_path);
use Digest::SHA qw(sha256_hex);
use Exporter qw(import);
use File::Spec;
use JSON::PP ();

use FSM::Adapter::IAL2::PPIF;
use FSM::Adapter::ISF;
use FSM::HIAL::VIALBridge::Builder;
use FSM::ProjectDataLocality qw(repository_root);

our @EXPORT_OK = qw(
    checked_ahb_reference current_ahb_report_sha256 reference_contract_sha256
);

my $json = JSON::PP->new->canonical(1)->utf8(1);
my $frozen_contract = '64946a809cb57d932f41696baaf25f664194257d13dd57b7da7a251ca42fdf14';

sub checked_ahb_reference {
    die "checked_ahb_reference expects no arguments\n" if @_;
    my $source_id = 'ppif/ahb_lite_subordinate.ppif';
    my $text = _read_fixture($source_id);
    my $ppif = FSM::Adapter::IAL2::PPIF->new()->parse_source($text, $source_id);
    my $ial1 = $ppif->{generated_ial1};
    my $ial0_text = $ppif->{generated_ial0}{files}{'ahb_lite_subordinate.fsm'};
    my @ports = qw(clk rst_n HSEL HREADY HADDR HTRANS HWRITE HSIZE HWDATA wait_cycles HREADYOUT HRESP HRDATA);
    my $built = FSM::HIAL::VIALBridge::Builder->build_ial2_via_ial1({
        profile => 'core_single_unit_v1',
        authored_source => _source_record($text, $source_id, 'ahb_lite_subordinate.ppif'),
        generated_ial1 => {
            source => _source_record($ial1->{text}, undef, $ial1->{name}),
            actor => FSM::Adapter::ISF->new()->parse_source($ial1->{text}, $ial1->{name}),
            schedule_report => $ppif->{generated_ial1_schedule_report},
        },
        generated_ial0 => _source_record($ial0_text, undef, 'ahb_lite_subordinate.fsm'),
        backend_names => {
            map {
                $_ => {
                    unit => 'ahb_lite_subordinate',
                    endpoints => {map { $_ => $_ } @ports},
                    configurations => {},
                    probes => {reg_data_q => 'reg_data_q'},
                }
            } qw(systemverilog vhdl)
        },
    });
    die "Checked AHB reference failed: " . $json->encode($built->{diagnostics}) . "\n"
        unless $built->{ok};

    my $report = $built->{report};
    my ($source, $artifact) = _generated_records($report);
    my $expected = _source_record($ial0_text, undef, 'ahb_lite_subordinate.fsm');
    my @keys = qw(content_sha256 byte_length line_count);
    my $actual_provenance = $json->encode([@{$source}{@keys}, $artifact->{content_sha256}]);
    my $expected_provenance = $json->encode([@{$expected}{@keys}, $expected->{content_sha256}]);
    die "Checked AHB generated provenance differs from current raw bytes or JSON types\n"
        unless $actual_provenance eq $expected_provenance;
    my $contract = reference_contract_sha256($report);
    die "Checked AHB reference contract drifted: $contract\n"
        unless $contract eq $frozen_contract;

    # Build fresh data on each call; callers cannot poison another test's oracle.
    return {
        report => $report,
        report_sha256 => sha256_hex($json->encode($report)),
        ial0_text => $ial0_text,
    };
}

sub current_ahb_report_sha256 {
    die "current_ahb_report_sha256 expects no arguments\n" if @_;
    return checked_ahb_reference()->{report_sha256};
}

sub reference_contract_sha256 {
    die "reference_contract_sha256 expects one report hash\n"
        unless @_ == 1 && ref($_[0]) eq 'HASH';
    my $copy = $json->decode($json->encode($_[0]));
    my ($source, $artifact) = _generated_records($copy);
    # Current raw provenance is checked before the frozen contract is sealed.
    # Every other field, key, type, order, semantic ID and source map remains.
    @{$source}{qw(content_sha256 byte_length line_count)} = (undef, undef, undef);
    $artifact->{content_sha256} = undef;
    return sha256_hex($json->encode($copy));
}

sub _generated_records {
    my ($report) = @_;
    die "Expected AHB source and review-artifact arrays\n"
        unless ref($report->{sources}) eq 'ARRAY'
            && ref($report->{review_artifacts}) eq 'ARRAY';
    my @sources = grep { $_->{source_id} eq 'source/generated_ial0' } @{$report->{sources}};
    my @artifacts = grep { $_->{artifact_id} eq 'artifact/generated_ial0' } @{$report->{review_artifacts}};
    die "Expected exactly one generated IAL0 source and artifact\n"
        unless @sources == 1 && @artifacts == 1;
    return ($sources[0], $artifacts[0]);
}

sub _source_record {
    my ($text, $path, $name) = @_;
    my $lines = (() = $text =~ /\n/g) + (length($text) && $text !~ /\n\z/ ? 1 : 0);
    return {
        text => $text, repository_path => $path, artifact_name => $name,
        content_sha256 => sha256_hex($text),
        byte_length => bytes::length($text), line_count => $lines,
    };
}

sub _read_fixture {
    my ($relative) = @_;
    my $root = repository_root();
    my $path = File::Spec->catfile($root, split m{/}, $relative);
    die "Expected regular checked fixture $relative\n" unless -f $path && !-l $path;
    my $physical = abs_path($path) or die "Cannot resolve checked fixture $relative: $!\n";
    my $within = File::Spec->abs2rel($physical, $root);
    die "Checked fixture escapes its repository: $relative\n"
        if File::Spec->file_name_is_absolute($within) || $within =~ m{\A\.\.(?:[/\\]|\z)};
    die "Checked fixture is on another volume: $relative\n"
        unless (stat($physical))[0] == (stat($root))[0];
    open my $fh, '<:raw', $physical or die "Cannot read checked fixture $relative: $!\n";
    local $/;
    my $text = <$fh> // '';
    close $fh or die "Cannot close checked fixture $relative: $!\n";
    return $text;
}

1;
