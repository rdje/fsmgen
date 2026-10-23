#!/usr/bin/env perl
use strict;
use warnings;
use lib 'perl';
use JSON::PP ();
use Digest::SHA qw(sha256_hex);
use FSM::Support::SemanticIntrospectionMCPAdapter;
use FSM::Support::CapabilityManifest qw(build_capability_manifest);

my $json = JSON::PP->new->canonical;
my $manifest = build_capability_manifest();
my $code = 'FSMGEN_COMPOSITION_CHILD_ITEM_LIST_SHAPE';
my @entries = @{$manifest->{support_accounting}{catalog_entries}}[0 .. 120];
# A deliberate counterfactual catalog isolates bounds that the real catalog's
# small per-code populations cannot distinguish. No support claim is inferred.
my $fixture = {%$manifest, support_accounting => {
    %{$manifest->{support_accounting}}, catalog_entries => [
        map { +{%$_, diagnostic_code => $code} } @entries
    ],
}};
my $adapter = FSM::Support::SemanticIntrospectionMCPAdapter->new(
    repo_root => '.', workspace_root => '.', manifest_builder => sub { $fixture });
my @cases;
for my $literal ('null', '0', '1', '10', '100', '101', '-1', '1e30') {
    my $arguments = {code => $code};
    $arguments->{limit_examples} = $json->decode($literal) unless $literal eq 'null';
    my $request = {jsonrpc => '2.0', id => scalar(@cases), method => 'tools/call',
        params => {name => 'fsmgen_explain_diagnostic', arguments => $arguments}};
    my $response = $adapter->handle_jsonrpc_request($request);
    push @cases, {input_literal => $literal, request => $request, response => $response};
}
my %hashes;
for my $path ('perl/FSM/Support/SemanticIntrospectionMCPAdapter.pm', $0) {
    open my $fh, '<:raw', $path or die "$path: $!";
    local $/;
    $hashes{$path} = sha256_hex(<$fh>);
}
print $json->pretty->encode({fixture_kind => 'counterfactual_catalog',
    catalog_entries => $fixture->{support_accounting}{catalog_entries},
    tools => $adapter->list_tools(), source_sha256 => \%hashes, cases => \@cases});
