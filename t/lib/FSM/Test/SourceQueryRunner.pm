package FSM::Test::SourceQueryRunner;

use strict;
use warnings;
use Cwd qw(abs_path getcwd);
use Digest::SHA ();
use Exporter 'import';
use IO::Select;
use IPC::Open3 qw(open3);
use JSON::PP ();
use Scalar::Util qw(blessed);
use Symbol qw(gensym);
use FSM::Support::SemanticIntrospectionMCPAdapter;
use FSM::VIAL::Tool qw(check_vial_source_file inspect_vial_source_file);

our @EXPORT_OK = qw(run_source_query normalize_repository_paths);
my $json = JSON::PP->new->canonical;
my %tool = (check => 'fsmgen_check', semantic => 'fsmgen_semantic_introspect',
    schedule => 'fsmgen_schedule_preview', inspection => 'fsmgen_vial_inspect');

# This test-side runner consumes qualified cohort rows. It deliberately has no
# injected producer: all transports reach the shipped public implementation.
sub run_source_query {
    my ($args) = @_;
    die "source query requires one closed options hash\n"
        unless @_ == 1 && ref($args) eq 'HASH' && !blessed($args)
            && !grep { !/\A(?:repository_root|row|query_kind)\z/ } keys %$args;
    my $root = abs_path($args->{repository_root} // '');
    die "source queries must run from their repository root\n"
        unless defined($root) && $root ne '/' && getcwd() eq $root
            && -f "$root/bin/fsmgen" && -f "$root/bin/fsmgen-mcp";
    my $row = $args->{row};
    die "source query requires a qualified cohort row\n" unless ref($row) eq 'HASH';
    my $source = $row->{source_id};
    die "source query requires a safe relative source identity\n"
        unless defined($source) && !ref($source)
            && $source =~ /\A[A-Za-z0-9_][A-Za-z0-9_.\/-]*\z/
            && !grep { $_ eq '' || $_ eq '.' || $_ eq '..' } split m{/}, $source, -1;
    my $resolved = abs_path("$root/$source");
    die "source query requires an existing repository source\n"
        unless defined($resolved) && index($resolved, "$root/") == 0 && -f $resolved;
    my $kind = $args->{query_kind};
    die "source query kind is not accounted by this cohort row\n"
        unless defined($kind) && !ref($kind) && exists($tool{$kind})
            && ref($row->{query_kinds}) eq 'ARRAY' && grep { $_ eq $kind } @{$row->{query_kinds}};
    die "source-query search paths need an explicit public MCP contract\n"
        unless ref($row->{search_path_relpaths}) eq 'ARRAY' && !@{$row->{search_path_relpaths}};
    my $vial = $source =~ /\.vial\z/;
    my $version = $row->{language_version};
    die "source query has inconsistent version or strict admission\n"
        unless $vial ? (defined($version) && !ref($version) && $version =~ /\A[12]\z/
            && !$row->{strict} && $kind ne 'schedule')
        : (!defined($version) && $row->{strict} && $kind ne 'inspection');

    my @native = ($^X, "$root/bin/fsmgen");
    if ($vial) {
        push @native, 'vial', ($kind eq 'inspection' ? 'inspect' : 'check'),
            '--json', '--language-version', $version, $source;
    } else {
        my %flags = (check => [qw(--strict --check --json)],
            semantic => [qw(--strict --emit-semantic-json)], schedule => ['--emit-schedule-json']);
        push @native, @{$flags{$kind}}, $resolved;
    }
    my $arguments = {source_id => $source, ($vial ? (language_version => $version) : ())};
    my $request = {jsonrpc => '2.0', id => 1, method => 'tools/call',
        params => {name => $tool{$kind}, arguments => $arguments}};
    my $before = _producers($root);
    my $source_before = _digest($resolved);
    local %ENV = %ENV;
    delete @ENV{qw(PERL5LIB PERL5OPT)};
    my $native = _capture(\@native, '');
    $native->{report} = _object($native->{stdout}, 'native source query');
    my $adapter = FSM::Support::SemanticIntrospectionMCPAdapter->new(
        repo_root => $root, workspace_root => $root);
    my $api = $adapter->call_tool($tool{$kind}, $arguments);
    my $vial_api;
    if ($vial) {
        my $api_args = {workspace_root => $root, source_id => $source, language_version => $version};
        $vial_api = $kind eq 'inspection' ? inspect_vial_source_file($api_args) : check_vial_source_file($api_args);
    }
    my $stdio = _capture([$^X, "$root/bin/fsmgen-mcp", '--workspace-root', $root], $json->encode($request)."\n");
    $stdio->{response} = _object($stdio->{stdout}, 'newline MCP source query');
    return {
        source_id => $source, query_kind => $kind,
        native => $native, adapter_result => $api, stdio => $stdio, vial_api_report => $vial_api,
        source_sha256_before => $source_before, source_sha256_after => _digest($resolved),
        producer_sha256_before => $before, producer_sha256_after => _producers($root),
    };
}

# Normalize only this repository's exact prefix, including embedded diagnostics.
# Do not remove fields, reorder arrays, redact other paths or reinterpret values.
sub normalize_repository_paths {
    my ($value, $root) = @_;
    die "normalization needs an absolute non-root repository path\n"
        unless defined($root) && !ref($root) && $root =~ m{\A/.+[^/]\z};
    return {map {$_ => normalize_repository_paths($value->{$_}, $root)} keys %$value}
        if ref($value) eq 'HASH';
    return [map {normalize_repository_paths($_, $root)} @$value] if ref($value) eq 'ARRAY';
    return $value if !defined($value) || ref($value);
    my $text = "$value";
    return $value unless index($text, $root) >= 0;
    return '.' if $text eq $root;
    $text =~ s{\Q$root\E/}{}g;
    return $text;
}

sub _producers {
    my ($root) = @_;
    my @paths = qw(bin/fsmgen bin/fsmgen-mcp);
    for my $module (qw(FSM/Support/SemanticIntrospectionMCPAdapter.pm FSM/VIAL/Tool.pm)) {
        my $actual = abs_path($INC{$module} // '');
        die "source-query public API loaded outside the repository: $module\n"
            unless defined($actual) && $actual eq "$root/perl/$module";
        push @paths, "perl/$module";
    }
    return {map {$_ => _digest("$root/$_")} @paths};
}

sub _object {
    my ($text, $label) = @_;
    my $value = eval {JSON::PP->new->utf8->decode($text)};
    die "$label did not return one JSON object\n" if $@ || ref($value) ne 'HASH';
    return $value;
}

sub _digest {
    open my $fh, '<:raw', $_[0] or die "read source-query input: $!\n";
    my $sha = Digest::SHA->new(256)->addfile($fh)->hexdigest;
    close $fh or die "close source-query input: $!\n";
    return $sha;
}

# Requests are small and written before capture. Drain both child output pipes
# together so a large diagnostic stream cannot deadlock a large report.
sub _capture {
    my ($argv, $input) = @_;
    die "source-query request exceeds the small stdin envelope\n" if length($input) > 4096;
    my ($in, $out, $err) = (undef, undef, gensym());
    my $pid = open3($in, $out, $err, @$argv);
    my ($stdout, $stderr) = ('', '');
    my $ok = eval {
        local $SIG{PIPE} = 'IGNORE';
        print {$in} $input or die "write source-query stdin: $!\n" if length $input;
        close $in or die "close source-query stdin: $!\n";
        my $select = IO::Select->new($out, $err);
        my $out_fd = fileno($out);
        while ($select->count) {
            for my $fh ($select->can_read) {
                my $count = sysread($fh, my $buffer, 65536);
                if (!defined $count) { next if $!{EINTR}; die "read source-query output: $!\n" }
                if (!$count) { $select->remove($fh); close $fh; next }
                if (fileno($fh) == $out_fd) { $stdout .= $buffer } else { $stderr .= $buffer }
            }
        }
        1;
    };
    my $error = $@;
    kill 'KILL', $pid unless $ok;
    waitpid($pid, 0) == $pid or die "reap source-query process: $!\n";
    my $status = $?;
    die $error unless $ok;
    return {stdout => $stdout, stderr => $stderr, exit_code => $status >> 8, signal => $status & 127};
}

1;
