#!/usr/bin/env perl
use strict;
use warnings;
use Cwd qw(abs_path);
use FindBin;
use JSON::PP qw(decode_json);
use Test::More;
use lib "$FindBin::Bin/../perl";
use FSM::ProjectDataLocality qw(create_project_tempdir);
use FSM::Support::SemanticIntrospectionMCPAdapter;
use FSM::VIAL::Parser;
use FSM::VIAL::SourceProjection;
use FSM::VIAL::Tool qw(execute_vial_tool_request check_vial_source_file);
use FSM::VIAL::ToolCLI;

my $repo = abs_path("$FindBin::Bin/..");
my $workspace = create_project_tempdir(purpose => 'vial-fault-target-identity');
my $source_id = 'fault_reference.vial';
my $package = 'ahb_subordinate_base_output_arbitration';
my $fixture_id = "$package\::fixture::base_output_arbitration";
my %base = map { $_ => read_file("$repo/vial/ahb_subordinate_base_output_arbitration"
    . ($_ == 2 ? '_v2' : '') . '.vial') } (1, 2);
my $adapter = FSM::Support::SemanticIntrospectionMCPAdapter->new(
    repo_root => $repo, workspace_root => $workspace);

sub execute {
    my ($version, $text, $action, $catalog) = @_;
    $action //= 'check';
    return execute_vial_tool_request({
        schema => "fsmgen.vial_tool_request.v$version", schema_version => $version,
        action => $action,
        vial_source => {source_id => $source_id, source_kind_hint => 'vial', text => $text,
            encoding => 'utf-8', origin => 'repository', display_name => $source_id,
            canonical_id => undef, relative_path => $source_id, metadata => {}},
        hial_source => undef,
        options => {source_style => 'auto', output_style => $action eq 'format' ? 'terse' : undef,
            fixture_id => undef, scenario_ids => [], execution_profile => undef,
            backend_profile => undef, replay_manifest => undef, native_extension_catalogs => [],
            artifact_policy => undef, quiet => JSON::PP::false},
    }, {source_catalog => $catalog // {}, artifact_sink => []});
}
sub authored {
    my ($version, $selected) = @_;
    my $text = $base{$version};
    $text =~ s/\(transaction write "transaction\/ahb_write" ahb_write\)/(transaction write "transaction\/ahb_write" ahb_write)\n            (transaction alternate "transaction\/alternate_write" ahb_write)/
        or die 'missing original binding';
    $text =~ s/\(target \(transaction write size\)\)/(target (transaction $selected size))/
        or die 'missing original fault';
    return $text;
}
sub fixture {
    my ($text, $catalog) = @_;
    my $ir = FSM::VIAL::Parser->parse_source({text => $text, source_name => $source_id,
        source_catalog => $catalog // {}});
    return (grep { $_->{semantic_id} eq $fixture_id }
        map { @{$_->{fixtures}} } @{$ir->as_hashref->{packages}})[0];
}
sub meaning { return $_[0]{capability_evidence}{semantic_projection_sha256}; }
sub public_parity {
    my ($version, $text, $catalog, $checked) = @_;
    write_file("$workspace/$source_id", $text);
    write_file("$workspace/$_", $catalog->{$_}) for sort keys %$catalog;
    my $file = check_vial_source_file({workspace_root => $workspace, source_id => $source_id,
        language_version => $version});
    is_deeply($file, $checked, 'filesystem API matches the complete portable report');
    my ($out, $err, $exit) = ('', '');
    {
        open my $stdout, '>', \$out or die $!;
        open my $stderr, '>', \$err or die $!;
        local *STDOUT = $stdout; local *STDERR = $stderr;
        $exit = FSM::VIAL::ToolCLI->run({repo_root => $workspace,
            argv => ['check', '--json', '--language-version', $version, $source_id]});
    }
    is($exit, 0, 'native CLI succeeds');
    is($err, '', 'native CLI emits no error');
    is_deeply(decode_json($out), $checked, 'native CLI preserves complete fault meaning report');
    my $mcp = $adapter->call_tool('fsmgen_semantic_introspect', {
        source_id => $source_id, language_version => $version});
    ok(!$mcp->{isError}, 'MCP succeeds');
    is_deeply($mcp->{structuredContent}{report}, $checked, 'MCP preserves complete native report');
    is_deeply(decode_json($mcp->{content}[0]{text}), $mcp->{structuredContent},
        'text and structured MCP content agree');
    is_deeply($checked->{artifacts}, [], 'source check publishes no artifact');
    ok(!defined($checked->{plan}), 'source check creates no execution plan');
    is(read_file("$workspace/$source_id"), $text, 'source remains unchanged');
    is(read_file("$workspace/$_"), $catalog->{$_}, 'import remains unchanged') for sort keys %$catalog;
}

for my $version (1, 2) {
    subtest "v$version exact target, style stability and public transport" => sub {
        my %digest;
        for my $selected (qw(write alternate)) {
            my $text = authored($version, $selected);
            my $checked = execute($version, $text);
            ok($checked->{success}, "$selected target is a legal source") or diag explain $checked;
            $digest{$selected} = meaning($checked);
            my $f = fixture($text);
            my $fault = $f->{faults}[0];
            is($fault->{transaction_id}, "$package\::transaction::ahb_write", 'declaration ID preserved');
            is($fault->{transaction_binding_id}, "$fixture_id\::transaction_binding::$selected",
                'fault records the independently authored binding identity');
            my %bindings = map { $_->{name} => $_ } @{$f->{dut}{transaction_bindings}};
            is($bindings{$selected}{bridge_ref}, $selected eq 'write'
                ? 'transaction/ahb_write' : 'transaction/alternate_write', 'selected bridge reference is distinct');
            is($fault->{field_name}, 'size', 'selected field remains exact');
            my $formatted = execute($version, $text, 'format');
            ok($formatted->{success}, 'terse formatting succeeds');
            my $terse = execute($version, $formatted->{formatted_source});
            ok($terse->{success}, 'terse source checks');
            is(meaning($terse), meaning($checked), 'normal and terse meanings agree');
            is(fixture($formatted->{formatted_source})->{faults}[0]{transaction_binding_id},
                $fault->{transaction_binding_id}, 'terse form retains chosen scope');
            public_parity($version, $text, {}, $checked);
        }
        isnt($digest{write}, $digest{alternate}, 'different fault targets have different meaning digests');
        my $base_fault = fixture($base{$version})->{faults}[0];
        ok(!exists($base_fault->{transaction_binding_id}), 'unambiguous legacy record has no redundant field');
        is($base_fault->{transaction_id}, "$package\::transaction::ahb_write", 'legacy declaration identity unchanged');
    };
}

subtest 'imported declarations retain local binding scope' => sub {
    for my $version (1, 2) {
        my $library = $base{$version};
        $library =~ s/package \Q$package\E/package library/ or die 'missing package';
        my $catalog = {'library.vial' => $library};
        my %digest;
        for my $selected (qw(write alternate)) {
            my $text = authored($version, $selected);
            $text =~ s/\(imports\)/(imports (import lib "library.vial"))/ or die 'missing imports';
            $text =~ s/" ahb_write\)/" lib.ahb_write)/g;
            $text =~ s/\(transaction ahb_write\)/(transaction lib.ahb_write)/g;
            $text =~ s/htrans_t\.nonseq/lib.htrans_t.nonseq/g;
            my $checked = execute($version, $text, 'check', $catalog);
            ok($checked->{success}, "v$version imported transaction checks") or diag explain $checked;
            my $fault = fixture($text, $catalog)->{faults}[0];
            is($fault->{transaction_id}, 'library::transaction::ahb_write', 'target declaration resolves through import');
            is($fault->{transaction_binding_id}, "$fixture_id\::transaction_binding::$selected",
                'import does not change fixture-local selected scope');
            $digest{$selected} = meaning($checked);
            public_parity($version, $text, $catalog, $checked);
        }
        isnt($digest{write}, $digest{alternate}, 'imported aliases remain distinct meanings');
    }
};

subtest 'migration preserves cross-version target meaning' => sub {
    my %digest;
    for my $selected (qw(write alternate)) {
        my $text = authored(1, $selected);
        my $result = execute(2, $text, 'migrate');
        ok($result->{success}, "$selected target migrates") or diag explain $result;
        my $promoted = $result->{source_migration}{sources}[0]{formatted_source};
        my @irs = map { FSM::VIAL::Parser->parse_source({text => $_, source_name => $source_id}) }
            ($text, $promoted);
        is(FSM::VIAL::SourceProjection->compatibility_projection_sha256($irs[0]),
            FSM::VIAL::SourceProjection->compatibility_projection_sha256($irs[1]),
            'migration preserves compatibility meaning');
        is(fixture($promoted)->{faults}[0]{transaction_binding_id},
            "$fixture_id\::transaction_binding::$selected", 'migrated fault retains selected binding');
        $digest{$selected} = $result->{source_migration}{compatibility_projection_sha256};
    }
    isnt($digest{write}, $digest{alternate}, 'compatibility identity distinguishes fault targets');
};

subtest 'unknown target binding or field fails precisely' => sub {
    for my $version (1, 2) {
        for my $case (['missing', 'size', 'binding'], ['write', 'missing', 'field']) {
            my $text = authored($version, $case->[0]);
            $text =~ s/\(target \(transaction \Q$case->[0]\E size\)\)/(target (transaction $case->[0] $case->[1]))/;
            my $result = execute($version, $text);
            ok(!$result->{success}, 'invalid target rejected');
            ok(!defined($result->{semantic_report}), 'no partial semantic report');
            is($result->{diagnostics}[0]{code}, 'VIAL_REFERENCE_ERROR', 'precise reference error');
            like($result->{diagnostics}[0]{message}, qr/unknown transaction $case->[2]/,
                'diagnostic identifies binding versus field');
        }
    }
};

done_testing();
sub read_file {
    open my $fh, '<:raw', $_[0] or die $!;
    local $/; my $text = <$fh>; close $fh or die $!; return $text;
}
sub write_file {
    open my $fh, '>:raw', $_[0] or die $!;
    print {$fh} $_[1] or die $!; close $fh or die $!;
}
