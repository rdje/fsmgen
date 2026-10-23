#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use lib 'perl';
use JSON::PP ();
use Storable qw(dclone);
use FSM::Support::SemanticIntrospectionMCPAdapter;

my $input = shift @ARGV or die "case file required\n";
die "unexpected arguments\n" if @ARGV;
open my $fh, '<:raw', $input or die "cannot open case file: $!\n";
my $bytes = '';
while (1) {
    my $count = sysread($fh, my $part, 65536);
    die "cannot read case file: $!\n" unless defined $count;
    last unless $count;
    $bytes .= $part;
    die "case file exceeds audit bound\n" if length($bytes) > 4 * 1024 * 1024;
}
close $fh or die "cannot close case file: $!\n";
my $wire = JSON::PP->new->utf8->canonical;
my $text = JSON::PP->new->canonical->allow_nonref;
my $cases = $wire->decode($bytes);
my $adapter = FSM::Support::SemanticIntrospectionMCPAdapter->new(repo_root => '.', workspace_root => '.');
my @kind_probes;
for my $literal ('null', 'true', 'false', '0', '1', '1.0', '1e0', '1e30', '1.5', '"1"', '"é"', '[]', '{}') {
    my $container = $text->decode('{"value":' . $literal . '}');
    my $before = $text->encode(dclone($container));
    # Prototype the established canonical-JSON technique on a detached scalar.
    # Unlike the backend's bounded canonical integer fields, MCP integers also
    # include integral exponent spellings. This is an audit, not production code.
    my $copy = $container->{value};
    my $kind;
    if (!defined $copy) { $kind = 'null' }
    elsif (JSON::PP::is_bool($copy)) { $kind = 'boolean' }
    elsif (ref($copy)) { $kind = ref($copy) eq 'ARRAY' ? 'array' : 'object' }
    else {
        my $encoded = $text->encode($copy);
        $kind = $encoded =~ /\A"/ ? 'string'
            : $copy == int($copy) ? 'integer' : 'number';
    }
    push @kind_probes, {input_literal => $literal, kind => $kind,
        before_clone_json => $before, after_clone_json => $text->encode(dclone($container))};
}
my @rows;
for my $case (@$cases) {
    my $request = $text->decode($case->{request_utf8});
    my $before = $text->encode($request);
    my $before_clone = $text->encode(dclone($request));
    my $response = $adapter->handle_jsonrpc_request($request);
    push @rows, {
        label => $case->{label}, request_before_json => $before,
        request_before_clone_json => $before_clone,
        request_after_json => $text->encode($request),
        request_after_clone_json => $text->encode(dclone($request)),
        response => $response,
    };
}
my @text_controls;
for my $operation ('length', 'lc') {
    my $direct = $text->decode('{"value":0}');
    my $detached = $text->decode('{"value":0}');
    my $before = $text->encode(dclone($direct));
    my $copy = $detached->{value};
    if ($operation eq 'length') {
        my $ignored_direct = length($direct->{value});
        my $ignored_copy = length($copy);
    } else {
        my $ignored_direct = lc($direct->{value});
        my $ignored_copy = lc($copy);
    }
    push @text_controls, {operation => $operation, before_clone_json => $before,
        direct_after_clone_json => $text->encode(dclone($direct)),
        detached_after_clone_json => $text->encode(dclone($detached))};
}
print $wire->pretty->encode({rows => \@rows, kind_probes => \@kind_probes,
    text_inspection_controls => \@text_controls, perl_version => "$^V",
    json_pp_version => "$JSON::PP::VERSION", storable_version => "$Storable::VERSION"});
