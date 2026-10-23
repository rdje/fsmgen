#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use JSON::PP ();
use Storable qw(dclone);
use FindBin;
use lib "$FindBin::Bin/../perl";
use FSM::Support::SemanticIntrospectionMCPAdapter;

my $json = JSON::PP->new->canonical->allow_nonref;
my $commands = 0;
my $adapter = FSM::Support::SemanticIntrospectionMCPAdapter->new(
    repo_root => '.', workspace_root => '.', runner => sub {
        ++$commands;
        return {marker => 'source-kind-regression'};
    });
my $hardware = 'ppif/axi_aw_valid_ready.ppif';
my %vial = (1 => 'vial/ahb_subordinate_base_output_arbitration.vial',
            2 => 'vial/ahb_subordinate_base_output_arbitration_lifecycle_v2.vial');
my @source_tools = qw(fsmgen_check fsmgen_semantic_introspect fsmgen_schedule_preview);
my @vial_tools = qw(fsmgen_check fsmgen_semantic_introspect fsmgen_vial_inspect);

sub request {
    my ($name, $args, $field, $literal) = @_;
    my %arguments = %$args;
    $arguments{$field} = '__KIND_LITERAL__' if defined $field;
    my $raw = $json->encode({jsonrpc => '2.0', id => 1, method => 'tools/call',
        params => {name => $name, arguments => \%arguments}});
    if (defined $field) {
        $raw =~ s/"__KIND_LITERAL__"/$literal/ or die 'missing literal slot';
    }
    return $raw;
}

sub exercise {
    my ($raw, $invalid, $label) = @_;
    my $input = $json->decode($raw);
    my $before = $json->encode($input);
    my $copy_before = $json->encode(dclone($input));
    my $previous_commands = $commands;
    my $response = $adapter->handle_jsonrpc_request($input);
    is($json->encode($input), $before, "$label caller unchanged");
    is($json->encode(dclone($input)), $copy_before, "$label later caller copy unchanged");
    if ($invalid) {
        is($response->{error}{code}, -32602, "$label invalid parameter");
        ok(!exists $response->{result}, "$label has no tool result");
        is($commands, $previous_commands, "$label never calls hardware runner");
    } else {
        ok(exists $response->{result}, "$label is admitted");
        my $result = $response->{result} || {};
        is($json->encode($result->{isError}), 'false', "$label succeeds");
        is($json->encode($json->decode($result->{content}[0]{text} // 'null')),
            $json->encode($result->{structuredContent}), "$label complete text/structured parity");
    }
    return $response;
}

subtest 'every supplied source selector has string kind before length or resolution' => sub {
    for my $name (@source_tools) {
        for my $field (qw(source_id source_path)) {
            my $other = $field eq 'source_id' ? 'source_path' : 'source_id';
            for my $literal ('0', '1', '1.5', '1e30', 'false', 'true', 'null', '[]', '{}', '""') {
                for my $args ({}, {$other => $hardware}) {
                    exercise(request($name, $args, $field, $literal), 1,
                        "$name $field=$literal" . (keys(%$args) ? ' with other selector' : ''));
                }
            }
        }
        # A quoted numeric string is a string, including in an unused selector.
        # Path precedence keeps this independent of a file named 0 existing.
        my $response = exercise(request($name, {source_path => $hardware}, 'source_id', '"0"'),
            0, "$name unused numeric-looking string");
        is($response->{result}{structuredContent}{source_id}, $hardware, 'source_path precedence retained');
    }
};

subtest 'VIAL tool versions are numeric integers, independently of URI spelling' => sub {
    for my $name (@vial_tools) {
        for my $literal ('"1"', '"2"', 'true', 'false', 'null', '[]', '{}', '1.5', '0', '3', '1e30') {
            exercise(request($name, {source_id => $vial{2}}, 'language_version', $literal),
                1, "$name version=$literal");
        }
        for my $version (1, 2) {
            for my $literal ("$version", "$version.0", "${version}e0") {
                my $response = exercise(request($name, {source_id => $vial{$version}}, 'language_version', $literal),
                    0, "$name integral version=$literal");
                is($response->{result}{structuredContent}{adapter_provenance}{language_version}, $version,
                    'selected version is preserved');
            }
        }
        exercise(request($name, {source_id => $vial{1}}), 0, "$name omitted version selects v1");
    }
};

subtest 'direct call_tool refusals also preserve fresh argument copies' => sub {
    for my $name (@source_tools) {
        for my $field (qw(source_id source_path)) {
            my $args = $json->decode('{"' . $field . '":0}');
            my $before = $json->encode($args);
            my $copy_before = $json->encode(dclone($args));
            my $ok = eval {$adapter->call_tool($name, $args); 1};
            my $error = $@;
            ok(!$ok, "$name direct numeric $field refused");
            like($error, qr/\AFSMGEN_JSONRPC_INVALID_PARAMS: source identity must be a nonempty string/,
                'direct source refusal uses the typed parameter channel');
            is($json->encode($args), $before, 'direct caller values unchanged');
            is($json->encode(dclone($args)), $copy_before, 'direct caller later copy unchanged');
        }
    }
    for my $name (@vial_tools) {
        my $args = $json->decode($json->encode({source_id => $vial{2}, language_version => '2'}));
        my $before = $json->encode(dclone($args));
        my $ok = eval {$adapter->call_tool($name, $args); 1};
        ok(!$ok, "$name direct quoted version refused");
        like($@, qr/\AFSMGEN_JSONRPC_INVALID_PARAMS: VIAL language_version/, 'direct version refusal is typed');
        is($json->encode(dclone($args)), $before, 'direct version caller copy unchanged');
    }
};

subtest 'versioned and unversioned resource text remains a valid independent route' => sub {
    for my $version (1, 2) {
        my $cap = $adapter->read_resource("fsmgen://vial/$version/capabilities");
        ok(ref($json->decode($cap->{contents}[0]{text})) eq 'HASH', "version $version capability URI remains textual");
        for my $pair (['check', 'fsmgen_check'], ['semantic', 'fsmgen_semantic_introspect'],
                      ['inspection', 'fsmgen_vial_inspect']) {
            my ($kind, $tool) = @$pair;
            my $uri = "fsmgen://vial/$version/source/$vial{$version}/$kind";
            my $resource = $json->decode($adapter->read_resource($uri)->{contents}[0]{text});
            my $result = $adapter->call_tool($tool, {source_id => $vial{$version}, language_version => $version});
            is($json->encode($resource), $json->encode($result->{structuredContent}),
                "$version $kind complete tool/resource parity");
            if ($version == 1 && $kind ne 'inspection') {
                my $unversioned = $json->decode($adapter->read_resource("fsmgen://source/$vial{1}/$kind")->{contents}[0]{text});
                is($json->encode($unversioned), $json->encode($resource), 'unversioned resource keeps v1 default');
            }
        }
    }
};
done_testing();
