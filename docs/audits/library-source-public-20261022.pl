use strict;
use warnings;
use lib 'perl', 't/lib';
use Cwd qw(abs_path);
use Digest::SHA qw(sha256_hex);
use JSON::PP;
use FSM::Test::ProjectDataLocality;
use FSM::Test::SourceQueryRunner qw(normalize_repository_paths);
use FSM::Support::SemanticIntrospectionMCPAdapter;

# The Python qualifier supplies already captured native reports. No native
# workload is replayed here; the real API and newline transports are compared
# transitively with those exact before/after-conserved reports.
my $json = JSON::PP->new->canonical;
my $expected = $json->decode(do {local $/; <STDIN>});
my $root = abs_path('.');
my $api = FSM::Support::SemanticIntrospectionMCPAdapter->new(repo_root => $root, workspace_root => $root);
my %tools = (check => 'fsmgen_check', semantic => 'fsmgen_semantic_introspect', schedule => 'fsmgen_schedule_preview');
for my $name (qw(alias nested defaults)) {
    my $path = ".artifacts/library-source-retention-qualified-20261022/$name.isf";
    my $before = digest($path);
    for my $kind (qw(check semantic schedule)) {
        my $request = {jsonrpc => '2.0', id => 1, method => 'tools/call', params => {
            name => $tools{$kind}, arguments => {source_id => $path}}};
        my $response = $api->handle_jsonrpc_request($request);
        my $wire = FSM::Test::SourceQueryRunner::_capture(
            [$^X, 'bin/fsmgen-mcp', '--workspace-root', '.'], $json->encode($request) . "\n");
        my $record = {name => $name, kind => $kind, request => $request, api => $response, wire => $wire,
            source_sha256_before => $before, source_sha256_after => digest($path)};
        # Publish complete original products before any oracle can refuse.
        print $json->encode(normalize_repository_paths($record, $root)), "\n" or die $!;
        die "API refused $name $kind\n" if $response->{error} || $response->{result}{isError};
        my $report = normalize_repository_paths($response->{result}{structuredContent}{report}, $root);
        my $native = normalize_repository_paths($expected->{$name}{$kind}, $root);
        die "native/API report mismatch $name $kind\n" unless $json->encode($report) eq $json->encode($native);
        die "text/structured mismatch $name $kind\n" unless $json->encode($json->decode($response->{result}{content}[0]{text}))
            eq $json->encode($response->{result}{structuredContent});
        die "newline refused $name $kind\n" unless $wire->{exit_code} == 0 && $wire->{stderr} eq ''
            && $wire->{stdout} =~ /\A[^\n]+\n\z/;
        die "API/newline response mismatch $name $kind\n" unless $json->encode($json->decode($wire->{stdout})) eq $json->encode($response);
        die "source changed $name $kind\n" unless $record->{source_sha256_before} eq $record->{source_sha256_after};
    }
}

sub digest {
    open my $f, '<:raw', $_[0] or die $!;
    my $bytes = do {local $/; <$f>};
    close $f or die $!;
    return sha256_hex($bytes);
}
