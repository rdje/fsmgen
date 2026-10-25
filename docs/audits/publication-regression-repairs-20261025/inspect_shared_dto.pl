#!/usr/bin/env perl
use strict;
use warnings;
use Cwd qw(abs_path);
use Digest::SHA qw(sha256_hex);
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use JSON::PP;
use lib "$FindBin::Bin/../../../perl";
use FSM::Pipeline::HDLGenerator;

my $root = abs_path("$FindBin::Bin/../../..");
chdir $root or die "chdir repository: $!";
my $base = 'docs/audits/publication-regression-repairs-20261025';
my $output = "$base/shared-dto-qualified.json";
my $json = JSON::PP->new->canonical->pretty;
my $inputs = $json->decode(read_file("$base/shared-dto-inputs.json"));

sub metadata {
    my ($value) = @_;
    return [map { metadata($_) } @$value] if ref($value) eq 'ARRAY';
    return {map { $_ => metadata($value->{$_}) }
        grep { $_ ne 'intent_hir' && $_ ne 'lowered_rtl_ir' && $_ ne 'structural_rtl_ir' }
        sort keys %$value} if ref($value) eq 'HASH';
    return $value;
}

sub read_file {
    open my $fh, '<:raw', $_[0] or die "read $_[0]: $!";
    local $/;
    my $raw = <$fh>;
    close $fh or die "close $_[0]: $!";
    return $raw;
}

if (@ARGV == 1 && $ARGV[0] eq '--capture') {
    die "RAM guard required\n" unless ($ENV{FSMGEN_RAM_GUARD_ACTIVE} // '') eq '1';
    die "retained DTO inspection already exists\n" if -e $output;
    my $dir = tempdir(CLEANUP => 1);
    my $record = {owner => $inputs->{owner}, inputs => $inputs,
        recipe => read_file(__FILE__), observations => {}};
    my $ok = eval {
        for my $kind (sort keys %{$inputs->{cases}}) {
            my $case = $inputs->{cases}{$kind};
            die "fixture identity\n" unless sha256_hex($case->{source}) eq $case->{source_sha256};
            my $path = File::Spec->catfile($dir, $case->{filename});
            open my $fh, '>:raw', $path or die "write fixture: $!";
            print {$fh} $case->{source} or die "write fixture bytes: $!";
            close $fh or die "close fixture: $!";
            my $pipeline = FSM::Pipeline::HDLGenerator->new(
                target_language => 'systemverilog', debug_level => 0, quiet => 1);
            my $result = $pipeline->generate_hdl_from_file($path);
            $record->{observations}{$kind} = {
                candidates => metadata($result->{module_info}{composition_shared_datapath_candidates}),
                children => [map { +{instance_name => $_->instance_name,
                    output_drive_families => metadata($_->module_info->{output_drive_families})} }
                    @{$result->{composition_plan}->instances}],
            };
        }
        1;
    };
    my $error = $@;
    $record->{error} = $error if !$ok;
    $record->{recipe_sha256} = sha256_hex($record->{recipe});
    my $raw = $json->encode($record);
    $raw =~ s/\Q$root\E/<repository>/g;
    open my $fh, '>:raw', $output or die "write inspection: $!";
    print {$fh} $raw or die "write inspection bytes: $!";
    close $fh or die "close inspection: $!";
    die $error unless $ok;
} elsif (@ARGV) {
    die "usage: perl inspect_shared_dto.pl [--capture]\n";
}

my $record = $json->decode(read_file($output));
die "capture programme changed\n" unless $record->{recipe} eq read_file(__FILE__)
    && sha256_hex($record->{recipe}) eq $record->{recipe_sha256};
die "incomplete actual inspection\n" if $record->{error}
    || join(',', sort keys %{$record->{observations}}) ne 'candidate,drive_intent';
for my $kind (sort keys %{$record->{observations}}) {
    my $actual = $record->{observations}{$kind};
    die "expected shared candidate\n" unless @{$actual->{candidates}} == 1 && @{$actual->{children}} == 2;
    for my $family ((map { @{$_->{output_drive_families}} } @{$actual->{children}}),
                    (map { $_->{output_drive_family} } @{$actual->{candidates}[0]{contributors}})) {
        die "nullable family delay missing/wrong\n"
            unless exists($family->{pulse_delay_cycles}) && !defined($family->{pulse_delay_cycles});
    }
    for my $contributor (@{$actual->{candidates}[0]{contributors}}) {
        die "unadvertised drive-intent field\n" if exists $contributor->{drive_intent}{pulse_delay_cycles};
    }
}
print "Complete tested DTO metadata retains nullable delay and unchanged drive-intent shape\n";
