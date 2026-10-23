#!/usr/bin/env perl
use v5.20;
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use File::Find qw(find);
use JSON::PP;
use Pod::Simple::Checker 3.42;
use Pod::Simple::HTMLBatch 3.42;
use FSMGen::PodHTML;

binmode STDERR, ':encoding(UTF-8)';
my $json = JSON::PP->new->ascii->canonical->pretty;
if (@ARGV == 1 && $ARGV[0] eq '--versions') {
    print $json->encode({perl => "$^V", pod_simple => $Pod::Simple::HTMLBatch::VERSION});
    exit 0;
}
die "Usage: pod_api_render.pl INPUT_DIR OUTPUT_DIR ENTRYPOINTS_JSON\n" unless @ARGV == 3;
my ($input, $output, $entrypoints) = @ARGV;
open my $config, '<:raw', $entrypoints or die "$entrypoints: $!";
{
    local $/;
    %FSMGen::PodHTML::ENTRYPOINTS = %{decode_json(<$config>)};
}
my @paths;
find({no_chdir => 1, wanted => sub {
    die "Unsafe source $_\n" if -l $_;
    push @paths, $_ if -f $_ && /\.pm\z/;
}}, $input);
my @rows;
for my $path (sort @paths) {
    (my $relative = $path) =~ s{\A\Q$input\E/}{};
    die "Invalid module source path: $relative\n"
        unless $relative =~ m{\AFSM/(?:[A-Za-z_]\w*/)*[A-Za-z_]\w*\.pm\z};
    (my $module = $relative) =~ s{\.pm\z}{};
    $module =~ s{/}{::}g;
    my $checker = Pod::Simple::Checker->new;
    my $diagnostics = '';
    $checker->output_string(\$diagnostics);
    open my $source, '<:raw', $path or die "$relative: $!";
    my $text = do { local $/; <$source> };
    $checker->parse_string_document($text);
    # Checker 3.42 can emit errors but clear its errata flag while formatting.
    die "Malformed POD in perl/$relative:\n$diagnostics\n"
        if $checker->any_errata_seen || $diagnostics =~ /\S/;
    my $provided = $checker->content_seen ? JSON::PP::true : JSON::PP::false;
    $FSMGen::PodHTML::MODULES{$module} = 1;
    $FSMGen::PodHTML::PROVIDED{$module} = $provided;
    push @rows, {module => $module, pod => $provided};
}
my $batch = Pod::Simple::HTMLBatch->new;
$batch->verbose(0);
$batch->css_flurry(0);
$batch->javascript_flurry(0);
$batch->no_contents_links(1);
$batch->html_render_class('FSMGen::PodHTML');
$batch->contents_page_start('<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>FSMGen Perl API reference</title><link rel="stylesheet" href="reference.css"></head><body><nav aria-label="Reference navigation"><a href="../11-extensions-and-embedding.html">FSMGen manual</a><a href="coverage.html">POD coverage</a></nav><main><h1>FSMGen Perl API reference</h1><p class="boundary">POD describes Perl bindings and implementation details. Supported behavior and stability remain governed by the published contracts in the manual. Missing POD is listed explicitly in the coverage report.</p><h2>Selected entry points</h2><ul>' . join('', map { (my $path = $_) =~ s{::}{/}g; qq{<li><a href="$path.html">$_</a></li>} } sort keys %FSMGen::PodHTML::ENTRYPOINTS) . '</ul><h2>Available module POD</h2>');
$batch->contents_page_end('</main><footer>Generated from repository POD with Pod::Simple::HTMLBatch.</footer></body></html>');
$batch->batch_convert([$input], $output);
print $json->encode(\@rows);
