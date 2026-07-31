package FSM::VIAL::ToolCLI;

use strict;
use warnings;

use Cwd qw(abs_path);
use File::Spec;
use Getopt::Long qw(GetOptionsFromArray);
use JSON::PP ();
use Scalar::Util qw(blessed);

use FSM::VIAL::SourceProjection;
use FSM::VIAL::Tool qw(execute_vial_tool_request);

sub run {
    my ($class, $args) = @_;
    die "VIAL CLI requires one unblessed invocation hash\n"
        unless ref($args) eq 'HASH' && !blessed($args);
    my %allowed = map { $_ => 1 } qw(argv repo_root);
    my @unknown = sort grep { !$allowed{$_} } keys %{$args};
    die "VIAL CLI received unknown invocation key '$unknown[0]'\n" if @unknown;
    die "VIAL CLI argv must be an array\n" unless ref($args->{argv}) eq 'ARRAY';
    die "VIAL CLI repo_root must be scalar\n"
        unless defined($args->{repo_root}) && !ref($args->{repo_root});

    my @argv = @{$args->{argv}};
    my $action = shift(@argv) || '';
    if ($action eq '' || $action eq 'help' || $action eq '--help' || $action eq '-h') {
        print _usage();
        return $action eq '' ? 2 : 0;
    }
    return _emit_cli_error($action, 0, 'unknown VIAL action', "unknown action '$action'")
        unless $action =~ /\A(?:capabilities|check|format|plan|run)\z/;

    my ($json, $quiet, $style) = (0, 0, undef);
    my $parse_ok;
    {
        local $Getopt::Long::ignorecase = 0;
        local $Getopt::Long::autoabbrev = 0;
        local $SIG{__WARN__} = sub { };
        $parse_ok = GetOptionsFromArray(
            \@argv,
            'json' => \$json,
            'quiet|q' => \$quiet,
            'style=s' => \$style,
        );
    }
    return _emit_cli_error($action, $json, 'invalid command options', 'invalid or unknown option')
        unless $parse_ok;

    if ($action eq 'capabilities') {
        return _emit_cli_error($action, $json, 'capabilities arguments', 'capabilities accepts only --json or --quiet')
            if @argv || defined($style);
        my $request = _request(
            action => $action,
            source => undef,
            source_style => undef,
            output_style => undef,
            quiet => $quiet,
        );
        my $result = execute_vial_tool_request($request, {
            source_catalog => {},
            artifact_sink => [],
        });
        return _emit_result($result, $json, $quiet);
    }

    return _emit_cli_error($action, $json, 'unavailable action', "action '$action' is not available until its implementation child ships")
        if $action eq 'plan' || $action eq 'run';
    return _emit_cli_error($action, $json, 'source cardinality', "$action requires exactly one repository-relative SOURCE.vial")
        unless @argv == 1;
    return _emit_cli_error($action, $json, 'source style', "--style must be auto, normal, or terse for check")
        if $action eq 'check' && defined($style) && $style !~ /\A(?:auto|normal|terse)\z/;
    return _emit_cli_error($action, $json, 'format style', 'format requires --style normal or --style terse')
        if $action eq 'format' && (!defined($style) || $style !~ /\A(?:normal|terse)\z/);
    return _emit_cli_error($action, $json, 'format JSON', 'format writes source text to stdout and does not accept --json')
        if $action eq 'format' && $json;
    return _emit_cli_error($action, $json, 'format quiet', 'format writes source text to stdout and does not accept --quiet')
        if $action eq 'format' && $quiet;

    my $source_id = $argv[0];
    my ($text, $read_error) = _read_repo_source($args->{repo_root}, $source_id);
    return _emit_cli_error($action, $json, 'source read', $read_error) if defined $read_error;
    my $catalog = _load_import_catalog($args->{repo_root}, $source_id, $text);
    my $request = _request(
        action => $action,
        source => {
            source_id => $source_id,
            source_kind_hint => 'vial',
            text => $text,
            encoding => 'utf-8',
            origin => 'repository',
            display_name => $source_id,
            canonical_id => undef,
            relative_path => $source_id,
            metadata => {},
        },
        source_style => $action eq 'format' ? 'auto' : (defined($style) ? $style : 'auto'),
        output_style => $action eq 'format' ? $style : undef,
        quiet => $quiet,
    );
    my $result = execute_vial_tool_request($request, {
        source_catalog => $catalog,
        artifact_sink => [],
    });
    return _emit_result($result, $json, $quiet);
}

sub _request {
    my (%args) = @_;
    return {
        schema => 'fsmgen.vial_tool_request.v1',
        schema_version => 1,
        action => $args{action},
        vial_source => $args{source},
        hial_source => undef,
        options => {
            source_style => $args{source_style},
            output_style => $args{output_style},
            fixture_id => undef,
            scenario_ids => [],
            execution_profile => undef,
            backend_profile => undef,
            replay_manifest => undef,
            native_extension_catalogs => [],
            artifact_policy => undef,
            quiet => $args{quiet} ? JSON::PP::true : JSON::PP::false,
        },
    };
}

sub _load_import_catalog {
    my ($repo_root, $root_id, $root_text) = @_;
    my %catalog = ($root_id => $root_text);
    my %queued = ($root_id => 1);
    my @queue = ([$root_id, $root_text]);
    while (@queue) {
        my ($source_id, $text) = @{shift @queue};
        my $imports = eval {
            FSM::VIAL::SourceProjection->import_source_names({
                text => $text,
                source_name => $source_id,
            });
        };
        next unless $imports;
        for my $import_id (@{$imports}) {
            next if $queued{$import_id}++;
            my ($import_text, $error) = _read_repo_source($repo_root, $import_id);
            next if defined $error;
            $catalog{$import_id} = $import_text;
            push @queue, [$import_id, $import_text];
        }
    }
    return \%catalog;
}

sub _read_repo_source {
    my ($repo_root, $source_id) = @_;
    return (undef, 'source path must be repository-relative, use / separators, and end in .vial')
        unless _safe_source_id($source_id);
    my $canonical_root = abs_path($repo_root);
    return (undef, 'repository root is not a readable directory')
        unless defined($canonical_root) && -d $canonical_root;
    my @root_stat = stat($canonical_root);
    return (undef, 'repository root filesystem identity is unavailable') unless @root_stat;

    my $path = $canonical_root;
    for my $segment (split m{/}, $source_id) {
        $path = File::Spec->catfile($path, $segment);
        my @component_stat = lstat($path);
        return (undef, "source '$source_id' must exist below the repository root")
            unless @component_stat;
        return (undef, "source '$source_id' must not traverse a symlink") if -l _;
    }
    return (undef, "source '$source_id' must be a regular non-symlink repository file")
        unless -f $path;
    my @source_stat = stat($path);
    return (undef, "source '$source_id' must remain on the repository filesystem volume")
        unless @source_stat && $source_stat[0] == $root_stat[0];
    open my $fh, '<:raw', $path
        or return (undef, "cannot read repository source '$source_id'");
    local $/;
    my $text = <$fh>;
    close $fh
        or return (undef, "cannot close repository source '$source_id' after reading");
    return ($text, undef);
}

sub _safe_source_id {
    my ($value) = @_;
    return defined($value) && !ref($value)
        && $value =~ /\A[A-Za-z0-9_][A-Za-z0-9_.\/-]*\.vial\z/
        && $value !~ m{(?:\A/|\A~|\A[A-Za-z]:|://|\\|\x00)}
        && !grep { $_ eq '' || $_ eq '.' || $_ eq '..' } split m{/}, $value, -1;
}

sub _emit_result {
    my ($result, $json, $quiet) = @_;
    if ($json) {
        print JSON::PP->new->ascii->canonical->pretty->encode($result);
    }
    elsif (!$result->{success}) {
        for my $diagnostic (@{$result->{diagnostics}}) {
            my $location = @{$diagnostic->{source_locations}}
                ? sprintf(
                    ' %s:%d:%d',
                    $diagnostic->{source_locations}[0]{source_name},
                    $diagnostic->{source_locations}[0]{start_line},
                    $diagnostic->{source_locations}[0]{start_column},
                )
                : '';
            print STDERR "Error [$diagnostic->{code}]$location $diagnostic->{semantic_path}: $diagnostic->{message}\n";
        }
    }
    elsif ($result->{action} eq 'format') {
        print $result->{formatted_source};
    }
    elsif (!$quiet && $result->{action} eq 'capabilities') {
        print "VIAL source tooling: capabilities, check, format\n";
        print "Source styles: normal_v1, terse_v1\n";
        print "Artifacts/backend/runtime: not shipped by this slice\n";
    }
    elsif (!$quiet) {
        print "VIAL check passed ($result->{source_style})\n";
    }
    return $result->{success} ? 0 : _exit_code($result);
}

sub _emit_cli_error {
    my ($action, $json, $label, $message) = @_;
    my $result = FSM::VIAL::Tool->_cli_error_result(
        $action,
        $label eq 'source read' ? 'VIAL_HOST_ERROR' : 'VIAL_TOOL_INVOCATION_ERROR',
        $message,
    );
    return _emit_result($result, $json, 0);
}

sub _exit_code {
    my ($result) = @_;
    my $code = $result->{diagnostics}[0]{code} || '';
    return 2 if $code eq 'VIAL_TOOL_INVOCATION_ERROR' || $code eq 'VIAL_HOST_ERROR';
    return 1;
}

sub _usage {
    return <<'USAGE';
FSMGen VIAL source tooling

Usage:
  ./bin/fsmgen vial capabilities [--json]
  ./bin/fsmgen vial check [--style auto|normal|terse] [--json] SOURCE.vial
  ./bin/fsmgen vial format --style normal|terse SOURCE.vial

Plan, backend emission, and run are implemented by later active children.
All source paths are repository-root-relative.
USAGE
}

1;
