#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use Getopt::Long qw(GetOptions);
use JSON::PP ();
use Storable qw(dclone);
use FSM::Support::SemanticIntrospectionMCPAdapter;

my ($mode, $root, $case_name) = ('api', '.', 'callback_plain');
GetOptions('mode=s' => \$mode, 'root=s' => \$root, 'case=s' => \$case_name) or die "bad probe options\n";
my $json = JSON::PP->new->canonical->ascii->allow_nonref;
my $callback_message = '';
my $adapter = FSM::Support::SemanticIntrospectionMCPAdapter->new(
    repo_root => $root, workspace_root => $root, runner => sub {die $callback_message});
my $fixture = 'fsm/ahb_lite_subordinate.fsm';
my @cases = (
    {name => 'missing_source', method => 'tools/call', params => {name => 'fsmgen_check', arguments => {}},
     code => -32602, expected => 'Invalid params: source_path or source_id is required'},
    {name => 'quoted_version', method => 'tools/call', params => {name => 'fsmgen_vial_inspect',
        arguments => {source_id => 'vial/missing.vial', language_version => '2'}},
     code => -32602, expected => 'Invalid params: VIAL language_version must be a JSON integer'},
    {name => 'unknown_tool', method => 'tools/call', params => {name => 'fsmgen_no_such_tool', arguments => {}},
     code => -32000, expected => 'Unsupported MCP tool: fsmgen_no_such_tool'},
    {name => 'unknown_method', method => 'widgets/missing', params => {},
     code => -32601, expected => 'Unsupported JSON-RPC method: widgets/missing'},
    {name => 'callback_plain', message => "Callback rejected operator '/'", code => -32000,
     expected => "Callback rejected operator '/'"},
    {name => 'callback_authored_location', message => "Authored diagnostic at design.isf line 17.\n", code => -32000,
     expected => 'Authored diagnostic at design.isf line 17.'},
    {name => 'callback_authored_plus_native', message => 'Authored diagnostic at design.isf line 17.', code => -32000,
     expected => 'Authored diagnostic at design.isf line 17.'},
    {name => 'callback_fake_suffix', message => "Reason at design.isf line 17, <pretend> line 9; operator '/' rejected", code => -32000,
     expected => "Reason at design.isf line 17, <pretend> line 9; operator '/' rejected"},
    {name => 'callback_quotes', message => "Unsupported expression operator '/' at 'design.isf:17'\n", code => -32000,
     expected => "Unsupported expression operator '/' at 'design.isf:17'"},
    {name => 'callback_external_path', message => "Operator '/' while opening '/outside/private dir/source.fsm'\n", code => -32000,
     expected => "Operator '/' while opening '[absolute-path-redacted]'"},
    {name => 'callback_long_ascii', message => ('x' x 2200), code => -32000,
     expected => ('x' x (2048 - length(' [truncated]'))) . ' [truncated]'},
    {name => 'callback_long_unicode', message => ('é' x 2200), code => -32000,
     expected => ('é' x (2048 - length(' [truncated]'))) . ' [truncated]'},
    {name => 'ping', method => 'ping', params => {}, expected_result => {}},
);
my %cases = map {$_->{name} => $_} @cases;
# Optional stdio-only controls leave the historical API population unchanged.
$cases{callback_zero} = {message => "0\n"};
$cases{callback_empty} = {message => "\n"};
$cases{callback_control_only} = {message => "\x00\n"};

sub request_for {
    my ($case, $id) = @_;
    return {jsonrpc => '2.0', id => $id, method => $case->{method} // 'tools/call',
        params => $case->{params} // {name => 'fsmgen_check', arguments => {source_id => $fixture}}};
}

sub run_api_cases {
    my ($context) = @_;
    my @rows;
    for my $case (@cases) {
        $callback_message = $case->{message} // '';
        my $request = $json->decode($json->encode(request_for($case, "$context:$case->{name}")));
        my $before = $json->encode($request);
        my $copy_before = $json->encode(dclone($request));
        my @events;
        local $SIG{__DIE__} = sub {
            my (undef, $file, $line) = caller;
            push @events, {exception => "$_[0]", origin_file_label => $file, origin_line => $line,
                input_record => defined($.) ? 0 + $. : undef};
        };
        my $response = $adapter->handle_jsonrpc_request($request);
        push @rows, {case => $case->{name}, context => $context, request_before_json => $before,
            request_before_clone_json => $copy_before, request_after_json => $json->encode($request),
            request_after_clone_json => $json->encode(dclone($request)), response => $response,
            native_events => \@events};
    }
    return \@rows;
}

if ($mode eq 'api') {
    my @groups;
    push @groups, {context => 'no_input_record', rows => run_api_cases('no_input_record')};
    for my $context ('line_record', 'chunk_record') {
        my $input = "first record\nsecond record\n";
        open my $record_input, '<', \$input or die $!;
        local $/ = $context eq 'chunk_record' ? undef : "\n";
        my $read = <$record_input>;
        push @groups, {context => $context, read_value => $read, rows => run_api_cases($context)};
        close $record_input or die $!;
    }
    print $json->pretty->encode({cases => \@cases, groups => \@groups,
        native_file_labels => [sort grep {defined($_) && !ref($_)} (values(%INC), $0)],
        adapter_file_label => $INC{'FSM/Support/SemanticIntrospectionMCPAdapter.pm'},
        runtime => {perl => "$^V", json_pp => $JSON::PP::VERSION, storable => $Storable::VERSION}});
} elsif ($mode eq 'stdio') {
    die "unknown callback fixture\n" unless exists $cases{$case_name};
    $callback_message = $cases{$case_name}{message} // '';
    my @events;
    local $SIG{__DIE__} = sub {
        my (undef, $file, $line) = caller;
        push @events, {exception => "$_[0]", origin_file_label => $file, origin_line => $line,
            input_record => defined($.) ? 0 + $. : undef};
    };
    open my $custom_input, '<&', \*STDIN or die $!;
    open my $custom_output, '>&', \*STDOUT or die $!;
    $adapter->run_stdio(in => $custom_input, out => $custom_output);
    close $custom_input or die $!;
    close $custom_output or die $!;
    print STDERR $json->encode({probe_native_events => \@events}) . "\n";
} else {
    die "unknown probe mode\n";
}
