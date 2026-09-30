#!/usr/bin/env perl
use strict;
use warnings;
use Cwd qw(abs_path);
use Digest::SHA qw(sha256_hex);
use FindBin;
use JSON::PP ();
use lib "$FindBin::Bin/../perl", "$FindBin::Bin/lib";

sub fixture_report {
    return {
        schema => 'encoding_fixture',
        values => [0, '0', 1.25, JSON::PP::true, JSON::PP::false, undef,
            "quote\" slash\\ tab\t newline\n nul\0", "caf\x{e9} \x{1f680} \x{2028}"],
        rows => [map {"row=$_ ".('x' x 512)} 0..11999],
    };
}
# A synthetic native JSON producer isolates wire encoding from compilation.
if (@ARGV && $ARGV[0] eq '--native-encoding-fixture') {
    print JSON::PP->new->ascii->canonical->encode(fixture_report());
    exit 0;
}
if (@ARGV && $ARGV[0] eq '--stdio-encoding-fixture') {
    # This fixture opens its owned request file; the capture caller supplies EOF.
    open STDIN,'<:raw',"$ARGV[1]/request.json" or die "request: $!";
    exec $^X,'bin/fsmgen-mcp','--repo-root',$ARGV[1],'--workspace-root',$ARGV[1];
    die "exec MCP: $!";
}

require Test::More;
Test::More->import;
require File::Temp;
require FSM::Test::SourceQueryRunner;
require FSM::Support::SemanticIntrospectionMCPAdapter;

my $root=abs_path("$FindBin::Bin/..");
chdir $root or die "chdir: $!";
my $fixture=File::Temp::tempdir('mcp-json-encoding-XXXXXXXX',DIR=>"$root/t",CLEANUP=>1);
mkdir "$fixture/bin" or die "mkdir: $!";
open my $source,'>:raw',"$fixture/input.isf" or die "source: $!";
print {$source} "encoding fixture\n";close $source or die $!;
open my $native,'>:raw',"$fixture/bin/fsmgen" or die "producer: $!";
print {$native} '#!'.$^X."\n";
print {$native} 'exec $^X, "t/1886-semantic-introspection-mcp-json-encoding.t", "--native-encoding-fixture"; die "exec fixture: $!";' . "\n";
close $native or die $!;chmod 0755,"$fixture/bin/fsmgen" or die $!;
my $json=JSON::PP->new->utf8->canonical;
my $request={jsonrpc=>'2.0',id=>"caf\x{e9}-\x{1f680}",method=>'tools/call',
    params=>{name=>'fsmgen_semantic_introspect',arguments=>{source_id=>'input.isf'}}};
open my $request_file,'>:raw',"$fixture/request.json" or die "request file: $!";
print {$request_file} $json->encode($request)."\n";
close $request_file or die $!;
my $adapter=FSM::Support::SemanticIntrospectionMCPAdapter->new(
    repo_root=>$fixture,workspace_root=>$fixture,runner=>sub {fixture_report()});
my $expected=$adapter->handle_jsonrpc_request($request);

subtest('literal and escaped Unicode use the same wire identity', sub {
    my $ping={jsonrpc=>'2.0',id=>"caf\x{e9}-\x{1f680}",method=>'ping'};
    for my $encoder (JSON::PP->new->utf8,JSON::PP->new->ascii) {
        my $input=$encoder->encode($ping)."\n";
        open my $in,'<',\$input or die $!;
        my $output='';open my $out,'>',\$output or die $!;
        $adapter->run_stdio(in=>$in,out=>$out);close $out;close $in;
        is($json->decode($output)->{id},$ping->{id},'Unicode request identity survives byte decoding');
        ok(!utf8::is_utf8($output),'wire output is bytes rather than a wide-character scalar');
    }
    my $invalid="{\"jsonrpc\":\"2.0\",\"id\":\"\xff\",\"method\":\"ping\"}\n";
    open my $in,'<',\$invalid or die $!;
    my $output='';open my $out,'>',\$output or die $!;
    $adapter->run_stdio(in=>$in,out=>$out);close $out;close $in;
    is($json->decode($output)->{error}{code},-32700,'invalid UTF-8 is a parse failure');
});

for my $mode (qw(stdio one_shot)) {
    subtest("$mode retains complete large JSON and UTF-8 values within the resource guard", sub {
        my @argv=('scripts/run_with_ram_guard.sh','--process-max-rss-mb',768,
            '--poll-seconds',0.05,'--',$^X);
        push @argv, $mode eq 'stdio'
            ? ('t/1886-semantic-introspection-mcp-json-encoding.t','--stdio-encoding-fixture',$fixture)
            : ('bin/fsmgen-mcp','--repo-root',$fixture,'--workspace-root',$fixture,'--request-json',$json->encode($request));
        my $capture=FSM::Test::SourceQueryRunner::_capture(\@argv,'');
        is($capture->{exit_code},0,'large complete response stays within the guarded budget');
        is($capture->{signal},0,'wire process has no terminating signal');
        unlike($capture->{stderr},qr/(?:reached cutoff|Wide character|Malformed UTF|uninitialized)/,
            'no resource trip, encoding warning or lost-value warning');
        my $response=eval {$json->decode($capture->{stdout})};
        ok($response && !$@,'wire response is valid complete UTF-8 JSON') or do {diag($@);return};
        is($response->{id},$request->{id},'literal UTF-8 request identity round-trips');
        is(sha256_hex($json->encode(FSM::Test::SourceQueryRunner::_object($capture->{stdout},'wire fixture'))),
            sha256_hex($json->encode($response)),'cohort runner decodes UTF-8 wire bytes without changing values');
        is(sha256_hex($json->encode($response)),sha256_hex($json->encode($expected)),
            'complete typed wire result equals the public API result');
        is(sha256_hex($json->encode($response->{result}{structuredContent}{report})),sha256_hex($json->encode(fixture_report())),
            'every authored report row and scalar type survives');
        is(sha256_hex($json->encode(JSON::PP->new->decode($response->{result}{content}[0]{text}))),
            sha256_hex($json->encode($response->{result}{structuredContent})),
            'embedded text and structured result have identical complete values');
        like($capture->{stdout},qr/\A[^\n]+\n\z/,'stdio remains one compact newline message') if $mode eq 'stdio';
    });
}
Test::More::done_testing();
