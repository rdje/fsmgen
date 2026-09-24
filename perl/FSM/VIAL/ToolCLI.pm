package FSM::VIAL::ToolCLI;

use strict;
use warnings;

use bytes ();

use Cwd qw(abs_path);
use File::Spec;
use Getopt::Long qw(GetOptionsFromArray);
use JSON::PP ();
use Scalar::Util qw(blessed);

use FSM::VIAL::ArtifactTransaction;
use FSM::VIAL::SourceProjection;
use FSM::VIAL::Tool qw(execute_vial_tool_request check_vial_source_file inspect_vial_source_file);

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
    return _run_inspect(\@argv, $args->{repo_root}) if $action eq 'inspect';
    return _emit_cli_error($action, 0, 'unknown VIAL action', "unknown action '$action'")
        unless $action =~ /\A(?:capabilities|check|format|migrate|plan|run)\z/;

    my ($json, $quiet, $style, $dut, $fixture, $profile, $replay, $outdir, $backend)
        = (0, 0, undef, undef, undef, undef, undef, undef, undef);
    my $language_version = 1;
    my (@scenarios, @native_catalogs);
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
            'dut=s' => \$dut,
            'fixture=s' => \$fixture,
            'scenario=s@' => \@scenarios,
            'profile=s' => \$profile,
            'replay=s' => \$replay,
            'native-catalog=s@' => \@native_catalogs,
            'outdir=s' => \$outdir,
            'backend=s' => \$backend,
            'language-version=i' => \$language_version,
        );
    }
    return _emit_cli_error($action, $json, 'invalid command options', 'invalid or unknown option', $language_version)
        unless $parse_ok;
    return _emit_cli_error($action, $json, 'language version', '--language-version must be 1 or 2', $language_version)
        unless $language_version == 1 || $language_version == 2;

    if ($action eq 'capabilities') {
        return _emit_cli_error($action, $json, 'capabilities arguments', 'capabilities accepts only --language-version 1|2, --json, or --quiet', $language_version)
            if @argv || defined($style) || defined($dut) || defined($fixture)
                || @scenarios || defined($profile) || defined($replay)
                || @native_catalogs || defined($outdir) || defined($backend);
        my $request = _request(
            action => $action,
            source => undef,
            source_style => undef,
            output_style => undef,
            language_version => $language_version,
            quiet => $quiet,
        );
        my $result = execute_vial_tool_request($request, {
            source_catalog => {},
            artifact_sink => [],
            repository_root => $args->{repo_root},
        });
        return _emit_result($result, $json, $quiet);
    }

    return _emit_cli_error($action, $json, 'source cardinality', "$action requires exactly one repository-relative SOURCE.vial", $language_version)
        unless @argv == 1;
    return _emit_cli_error($action, $json, 'source style', "--style must be auto, normal, or terse for check", $language_version)
        if $action eq 'check' && defined($style) && $style !~ /\A(?:auto|normal|terse)\z/;
    return _emit_cli_error($action, $json, 'format style', 'format requires --style normal or --style terse', $language_version)
        if $action eq 'format' && (!defined($style) || $style !~ /\A(?:normal|terse)\z/);
    return _emit_cli_error($action, $json, 'migration style', 'migrate accepts no --style or --style normal|terse', $language_version)
        if $action eq 'migrate' && defined($style) && $style !~ /\A(?:normal|terse)\z/;
    return _emit_cli_error($action, $json, 'migration request version', 'migrate requires --language-version 2', $language_version)
        if $action eq 'migrate' && $language_version != 2;
    return _emit_cli_error($action, $json, 'format JSON', 'format writes source text to stdout and does not accept --json', $language_version)
        if $action eq 'format' && $json;
    return _emit_cli_error($action, $json, 'format quiet', 'format writes source text to stdout and does not accept --quiet', $language_version)
        if $action eq 'format' && $quiet;
    if ($action eq 'check' || $action eq 'format' || $action eq 'migrate') {
        return _emit_cli_error($action, $json, 'incompatible options', "$action does not accept planning options", $language_version)
            if defined($dut) || defined($fixture) || @scenarios || defined($profile)
                || defined($replay) || @native_catalogs || defined($outdir) || defined($backend);
    }
    if ($action eq 'plan' || $action eq 'run') {
        return _emit_cli_error($action, $json, 'source style', '--style must be auto, normal, or terse', $language_version)
            if defined($style) && $style !~ /\A(?:auto|normal|terse)\z/;
        return _emit_cli_error($action, $json, 'DUT source', "$action requires exactly one --dut repository-relative .fsm, .isf, or .ppif source", $language_version)
            unless defined($dut);
        my $expected_profile = "core_directed_single_clock_execution_v$language_version";
        return _emit_cli_error($action, $json, 'execution profile', "--profile must be $expected_profile", $language_version)
            if defined($profile) && $profile ne $expected_profile;
        return _emit_cli_error($action, $json, 'backend option', 'plan does not accept --backend', $language_version)
            if $action eq 'plan' && defined($backend);
        return _emit_cli_error($action, $json, 'backend option', 'run requires --backend BACKEND_PROFILE', $language_version)
            if $action eq 'run' && $language_version == 1 && !defined($backend);
    }

    my $source_id = $argv[0];
    if ($action eq 'check') {
        return _emit_result(check_vial_source_file({
            workspace_root => $args->{repo_root}, source_id => $source_id,
            language_version => $language_version, source_style => $style // 'auto',
        }), $json, $quiet);
    }
    my ($text, $read_error, $read_code) = _read_repo_source($args->{repo_root}, $source_id, 'vial');
    return _emit_cli_error($action, $json, 'source read', $read_error, $language_version, $read_code)
        if defined $read_error;
    my ($catalog, $catalog_error, $catalog_code) = _load_import_catalog(
        $args->{repo_root}, $source_id, $text,
        $action eq 'migrate' ? 1 : $language_version,
    );
    return _emit_cli_error($action, $json, 'source read', $catalog_error, $language_version, $catalog_code)
        if defined $catalog_error;
    my ($hial_source, $replay_manifest, @native_extension_catalogs);
    if ($action eq 'plan' || $action eq 'run') {
        my ($hial_text, $hial_error) = _read_repo_source($args->{repo_root}, $dut, 'hial');
        return _emit_cli_error($action, $json, 'source read', $hial_error, $language_version)
            if defined $hial_error;
        $hial_source = _source_envelope($dut, $hial_text, _hial_kind_hint($dut));
        if (defined $replay) {
            my ($decoded, $decode_error) = _read_repo_json($args->{repo_root}, $replay, 'replay manifest');
            return _emit_cli_error($action, $json, 'source read', $decode_error, $language_version)
                if defined $decode_error;
            return _emit_cli_error($action, $json, 'replay manifest', 'replay manifest must contain one JSON object', $language_version)
                unless ref($decoded) eq 'HASH' && !blessed($decoded);
            $replay_manifest = $decoded;
        }
        for my $native_path (@native_catalogs) {
            my ($decoded, $decode_error) = _read_repo_json($args->{repo_root}, $native_path, 'native catalog');
            return _emit_cli_error($action, $json, 'source read', $decode_error, $language_version)
                if defined $decode_error;
            return _emit_cli_error($action, $json, 'native catalog', "native catalog '$native_path' must contain one JSON array", $language_version)
                unless ref($decoded) eq 'ARRAY';
            push @native_extension_catalogs, @$decoded;
        }
    }
    my $request = _request(
        action => $action,
        language_version => $language_version,
        source => _source_envelope($source_id, $text, 'vial'),
        hial_source => $hial_source,
        source_style => ($action eq 'format' || $action eq 'migrate')
            ? 'auto' : (defined($style) ? $style : 'auto'),
        output_style => ($action eq 'format' || $action eq 'migrate')
            ? $style : undef,
        fixture_id => $fixture,
        scenario_ids => \@scenarios,
        execution_profile => ($action eq 'plan' || $action eq 'run')
            ? ($profile // "core_directed_single_clock_execution_v$language_version") : undef,
        backend_profile => $backend,
        replay_manifest => $replay_manifest,
        native_extension_catalogs => \@native_extension_catalogs,
        artifact_policy => ($action eq 'plan' || $action eq 'run')
            ? {mode => 'repository', artifact_root => $outdir} : undef,
        quiet => $quiet,
    );
    my $sink = [];
    my $result = execute_vial_tool_request($request, {
        source_catalog => $catalog,
        artifact_sink => $sink,
        repository_root => $args->{repo_root},
    });
    if (($action eq 'plan' || $action eq 'run') && $result->{success}) {
        my $published = FSM::VIAL::ArtifactTransaction->publish({
            repo_root => $args->{repo_root},
            artifact_root => $result->{tool_manifest}{artifact_root},
            operation_id => $result->{tool_manifest}{operation_id},
            artifacts => $sink,
        });
        if (!$published->{ok}) {
            $result = FSM::VIAL::Tool->_cli_artifact_error_result(
                $action, $published->{diagnostics}, $language_version,
            );
        }
        elsif ($published->{status} eq 'unchanged') {
            $result->{status} = 'unchanged';
        }
    }
    return _emit_result($result, $json, $quiet);
}

# Inspection has a closed JSON-only option surface, independent of the frozen
# check/format/plan/run CLI. No execution option reaches source loading here.
sub _run_inspect {
    my ($argv, $root) = @_;
    my ($json, $version, $style) = (0, '1', 'auto');
    my $parsed;
    {
        local $Getopt::Long::ignorecase = 0;
        local $Getopt::Long::autoabbrev = 0;
        local $SIG{__WARN__} = sub { };
        $parsed = GetOptionsFromArray($argv,
            'json' => \$json, 'language-version=s' => \$version, 'style=s' => \$style);
    }
    my $invalid = sub {
        my $checked = FSM::VIAL::Tool->_cli_error_result(
            'check', 'VIAL_TOOL_INVOCATION_ERROR', $_[0], $version eq '2' ? 2 : 1);
        return _emit_result(FSM::VIAL::Tool::_source_inspection_result($checked), $json, 0);
    };
    return $invalid->('inspect accepts only --json, --language-version and --style') unless $parsed;
    return $invalid->('inspect requires --json') unless $json;
    return $invalid->('--language-version must be 1 or 2') unless $version =~ /\A[12]\z/;
    return $invalid->('--style must be auto, normal, or terse') unless $style =~ /\A(?:auto|normal|terse)\z/;
    return $invalid->('inspect requires exactly one repository-relative SOURCE.vial') unless @$argv == 1;
    return _emit_result(inspect_vial_source_file({
        workspace_root => $root, source_id => $argv->[0],
        language_version => $version, source_style => $style,
    }), 1, 0);
}

sub _check_source_file_result {
    my ($class, @call) = @_;
    die "filesystem source adaptation is private to FSM::VIAL::Tool\n"
        unless caller eq 'FSM::VIAL::Tool';
    return _source_file_query('check', @call);
}

sub _inspect_source_file_result {
    my ($class, @call) = @_;
    die "filesystem source adaptation is private to FSM::VIAL::Tool\n"
        unless caller eq 'FSM::VIAL::Tool';
    return _source_file_query('inspect', @call);
}

sub _source_file_query {
    my ($operation, @call) = @_;
    my $finish_error = sub {
        return $operation eq 'inspect' ? FSM::VIAL::Tool::_source_inspection_result($_[0]) : $_[0];
    };
    my $args = $call[0];
    my $version = ref($args) eq 'HASH' && !blessed($args)
        && defined($args->{language_version}) && !ref($args->{language_version})
        && $args->{language_version} eq '2' ? 2 : 1;
    my $invalid = sub {
        return $finish_error->(FSM::VIAL::Tool->_cli_error_result('check', 'VIAL_TOOL_INVOCATION_ERROR', $_[0], $version));
    };
    return $invalid->('filesystem check requires exactly one unblessed invocation hash')
        unless @call == 1 && ref($args) eq 'HASH' && !blessed($args);
    my %allowed = map { $_ => 1 } qw(workspace_root source_id language_version source_style);
    return $invalid->('filesystem check received an unknown invocation key')
        if grep { !$allowed{$_} } keys %$args;
    for my $key (qw(workspace_root source_id)) {
        return $invalid->("filesystem check requires scalar '$key'")
            unless defined($args->{$key}) && !ref($args->{$key}) && length($args->{$key});
    }
    return $invalid->('language_version must be 1 or 2')
        if exists($args->{language_version}) && (!defined($args->{language_version})
            || ref($args->{language_version}) || $args->{language_version} !~ /\A[12]\z/);
    my $style = exists($args->{source_style}) ? $args->{source_style} : 'auto';
    return $invalid->('source_style must be auto, normal, or terse')
        unless defined($style) && !ref($style) && $style =~ /\A(?:auto|normal|terse)\z/;
    my ($root, $id) = @{$args}{qw(workspace_root source_id)};
    my ($text, $error, $code) = _read_repo_source($root, $id, 'vial');
    return $finish_error->(FSM::VIAL::Tool->_cli_error_result('check', $code // 'VIAL_HOST_ERROR', $error, $version))
        if defined $error;
    my ($catalog, $catalog_error, $catalog_code) = _load_import_catalog($root, $id, $text, $version);
    return $finish_error->(FSM::VIAL::Tool->_cli_error_result('check', $catalog_code, $catalog_error, $version))
        if defined $catalog_error;
    my $request = _request(
        action => 'check', language_version => $version,
        source => _source_envelope($id, $text, 'vial'), source_style => $style,
    );
    my $environment = {source_catalog => $catalog, artifact_sink => [], repository_root => $root};
    return $operation eq 'inspect'
        ? FSM::VIAL::Tool::_inspect_source_request($request, $environment)
        : execute_vial_tool_request($request, $environment);
}

sub _request {
    my (%args) = @_;
    my $version = $args{language_version} // 1;
    return {
        schema => "fsmgen.vial_tool_request.v$version",
        schema_version => $version,
        action => $args{action},
        vial_source => $args{source},
        hial_source => $args{hial_source},
        options => {
            source_style => $args{source_style},
            output_style => $args{output_style},
            fixture_id => $args{fixture_id},
            scenario_ids => $args{scenario_ids} || [],
            execution_profile => $args{execution_profile},
            backend_profile => $args{backend_profile},
            replay_manifest => $args{replay_manifest},
            native_extension_catalogs => $args{native_extension_catalogs} || [],
            artifact_policy => $args{artifact_policy},
            quiet => $args{quiet} ? JSON::PP::true : JSON::PP::false,
        },
    };
}

sub _load_import_catalog {
    my ($repo_root, $root_id, $root_text, $language_version) = @_;
    $language_version //= 1;
    my %catalog = ($root_id => $root_text);
    my %queued = ($root_id => 1);
    my @queue = ([$root_id, $root_text]);
    my $combined_bytes = bytes::length($root_text);
    my $loaded_imports = 0;
    while (@queue) {
        my ($source_id, $text) = @{shift @queue};
        my $imports = eval {
            my $method = $language_version == 2
                ? 'import_source_names_v2' : 'import_source_names';
            FSM::VIAL::SourceProjection->$method({
                text => $text, source_name => $source_id,
            });
        };
        next unless $imports;
        for my $import_id (@{$imports}) {
            next if $queued{$import_id}++;
            return (undef, 'filesystem imported source count exceeds the limit', 'VIAL_LIMIT_ERROR')
                if $loaded_imports >= FSM::VIAL::Parser::MAX_IMPORTS();
            my $remaining = FSM::VIAL::Parser::MAX_COMBINED_BYTES() - $combined_bytes;
            my ($import_text, $error, $code) = _read_repo_source($repo_root, $import_id, 'vial', $remaining);
            # Missing or unsafe imports retain the parser's original catalog
            # diagnostic. Resource admission must stop loading immediately.
            return (undef, $error, $code) if defined($code) && $code eq 'VIAL_LIMIT_ERROR';
            next if defined $error;
            $combined_bytes += bytes::length($import_text);
            ++$loaded_imports;
            $catalog{$import_id} = $import_text;
            push @queue, [$import_id, $import_text];
        }
    }
    return (\%catalog, undef, undef);
}

sub _read_repo_source {
    my ($repo_root, $source_id, $kind, $remaining_bytes) = @_;
    my $safe = $kind eq 'vial' ? _safe_source_id($source_id)
        : $kind eq 'hial' ? _safe_hial_source_id($source_id)
        : $kind eq 'json' ? _safe_json_id($source_id)
        : 0;
    return (undef, $kind eq 'vial'
        ? 'source path must be repository-relative, use / separators, and end in .vial'
        : $kind eq 'hial'
            ? 'DUT path must be repository-relative, use / separators, and end in .fsm, .isf, or .ppif'
            : 'JSON path must be repository-relative, use / separators, and end in .json')
        unless $safe;
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
    my ($byte_limit, $limit_message);
    if ($kind eq 'vial') {
        $byte_limit = FSM::VIAL::Parser::MAX_SOURCE_BYTES();
        $limit_message = "source '$source_id' exceeds the source byte limit";
        return (undef, $limit_message, 'VIAL_LIMIT_ERROR') if $source_stat[7] > $byte_limit;
        if (defined($remaining_bytes) && $remaining_bytes < $byte_limit) {
            $byte_limit = $remaining_bytes;
            $limit_message = "source '$source_id' exceeds the combined source byte limit";
        }
        return (undef, $limit_message, 'VIAL_LIMIT_ERROR') if $source_stat[7] > $byte_limit;
    }
    open my $fh, '<:raw', $path
        or return (undef, "cannot read repository source '$source_id'");
    my @opened_stat = stat($fh);
    if (!@opened_stat || !-f $fh || $opened_stat[0] != $source_stat[0] || $opened_stat[1] != $source_stat[1]) {
        close $fh;
        return (undef, "source '$source_id' changed filesystem identity before reading");
    }
    my $text = '';
    if (defined $byte_limit) {
        my $read_status;
        ($text, $read_status) = _read_bounded_source_bytes($fh, $byte_limit);
        if (defined $read_status) {
            close $fh;
            return (undef, $limit_message, 'VIAL_LIMIT_ERROR') if $read_status eq 'limit';
            return (undef, "cannot read repository source '$source_id'");
        }
    }
    else {
        local $/;
        $text = <$fh>;
    }
    close $fh
        or return (undef, "cannot close repository source '$source_id' after reading");
    return ($text, undef, undef);
}

# The stream guard also covers files that grow after filesystem admission.
# Its caller owns the handle and closes it on every outcome.
sub _read_bounded_source_bytes {
    my ($fh, $byte_limit) = @_;
    my $text = '';
    while (1) {
        my $request_bytes = $byte_limit + 1 - bytes::length($text);
        $request_bytes = 65_536 if $request_bytes > 65_536;
        my $count = read($fh, my $chunk, $request_bytes);
        return (undef, 'read') unless defined $count;
        last unless $count;
        $text .= $chunk;
        return (undef, 'limit') if bytes::length($text) > $byte_limit;
    }
    return ($text, undef);
}

sub _read_repo_json {
    my ($repo_root, $source_id, $label) = @_;
    my ($text, $error) = _read_repo_source($repo_root, $source_id, 'json');
    return (undef, $error) if defined $error;
    my $decoded = eval { JSON::PP->new->decode($text) };
    return (undef, "$label '$source_id' is not valid JSON") unless defined $decoded && !$@;
    return ($decoded, undef);
}

sub _source_envelope {
    my ($source_id, $text, $kind_hint) = @_;
    return {
        source_id => $source_id,
        source_kind_hint => $kind_hint,
        text => $text,
        encoding => 'utf-8',
        origin => 'repository',
        display_name => $source_id,
        canonical_id => undef,
        relative_path => $source_id,
        metadata => {},
    };
}

sub _hial_kind_hint {
    my ($source_id) = @_;
    return 'fsm' if $source_id =~ /\.fsm\z/i;
    return 'isf' if $source_id =~ /\.isf\z/i;
    return 'ppif';
}

sub _safe_source_id {
    my ($value) = @_;
    return defined($value) && !ref($value)
        && $value =~ /\A[A-Za-z0-9_][A-Za-z0-9_.\/-]*\.vial\z/
        && $value !~ m{(?:\A/|\A~|\A[A-Za-z]:|://|\\|\x00)}
        && !grep { $_ eq '' || $_ eq '.' || $_ eq '..' } split m{/}, $value, -1;
}

sub _safe_hial_source_id {
    my ($value) = @_;
    return defined($value) && !ref($value)
        && $value =~ /\A[A-Za-z0-9_][A-Za-z0-9_.\/-]*\.(?:fsm|isf|ppif)\z/i
        && $value !~ m{(?:\A/|\A~|\A[A-Za-z]:|://|\\|\x00)}
        && !grep { $_ eq '' || $_ eq '.' || $_ eq '..' } split m{/}, $value, -1;
}

sub _safe_json_id {
    my ($value) = @_;
    return defined($value) && !ref($value)
        && $value =~ /\A[A-Za-z0-9_.][A-Za-z0-9_.\/-]*\.json\z/i
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
            my $first_location = exists($diagnostic->{source_locations})
                && ref($diagnostic->{source_locations}) eq 'ARRAY'
                && @{$diagnostic->{source_locations}}
                    ? $diagnostic->{source_locations}[0]
                    : $diagnostic->{source_location};
            my $location = defined($first_location)
                ? sprintf(
                    ' %s:%d:%d',
                    $first_location->{source_name},
                    $first_location->{start_line},
                    $first_location->{start_column},
                )
                : '';
            print STDERR "Error [$diagnostic->{code}]$location $diagnostic->{semantic_path}: $diagnostic->{message}\n";
        }
    }
    elsif ($result->{action} eq 'format') {
        print $result->{formatted_source};
    }
    elsif (!$quiet && $result->{action} eq 'capabilities') {
        if ($result->{schema_version} == 2) {
            print "VIAL v2 tooling: capabilities, check, format, migrate, plan\n";
            print "Source styles: normal_v2, terse_v2\n";
            print "Planning artifacts: atomic repository-local or virtual\n";
            print "Backend/runtime/result/parity: unavailable for VIAL v2\n";
        }
        else {
            print "VIAL tooling: capabilities, check, format, plan, run\n";
            print "Source styles: normal_v1, terse_v1\n";
            print "Planning artifacts: atomic repository-local or virtual\n";
            print "Backend/runtime: sv_portable_verilator (Verilator 5.046)\n";
        }
    }
    elsif (!$quiet && $result->{action} eq 'migrate') {
        my $migration = $result->{source_migration};
        print "VIAL migration $result->{status} ($migration->{input_style} -> $migration->{output_style})\n";
        for my $source (@{$migration->{sources}}) {
            print "$source->{source_name} $source->{output_sha256}\n";
        }
    }
    elsif (!$quiet && $result->{action} eq 'plan') {
        print "VIAL plan $result->{status} ($result->{tool_manifest}{artifact_root})\n";
    }
    elsif (!$quiet && $result->{action} eq 'run') {
        print "VIAL run $result->{status} ($result->{tool_manifest}{artifact_root})\n";
    }
    elsif (!$quiet) {
        print "VIAL check passed ($result->{source_style})\n";
    }
    return $result->{success} ? 0 : _exit_code($result);
}

sub _emit_cli_error {
    my ($action, $json, $label, $message, $version, $code) = @_;
    my $result = FSM::VIAL::Tool->_cli_error_result(
        $action,
        $code // ($label eq 'source read' ? 'VIAL_HOST_ERROR' : 'VIAL_TOOL_INVOCATION_ERROR'),
        $message,
        $version,
    );
    return _emit_result($result, $json, 0);
}

sub _exit_code {
    my ($result) = @_;
    my $code = $result->{diagnostics}[0]{code} || '';
    return 2 if $code eq 'VIAL_TOOL_INVOCATION_ERROR'
        || $code eq 'VIAL_HOST_ERROR'
        || $code eq 'VIAL_ARTIFACT_PATH_ERROR';
    return 1;
}

sub _usage {
    return <<'USAGE';
FSMGen VIAL tooling

Usage:
  ./bin/fsmgen vial capabilities [--language-version 1|2] [--json]
  ./bin/fsmgen vial check [--language-version 1|2]
    [--style auto|normal|terse] [--json] SOURCE.vial
  ./bin/fsmgen vial inspect --json [--language-version 1|2]
    [--style auto|normal|terse] SOURCE.vial
  ./bin/fsmgen vial format [--language-version 1|2]
    --style normal|terse SOURCE.vial
  ./bin/fsmgen vial migrate --language-version 2
    [--style normal|terse] [--json] SOURCE.vial
  ./bin/fsmgen vial plan [--language-version 1|2]
    --dut SOURCE.fsm|SOURCE.isf|SOURCE.ppif
    [--fixture ID] [--scenario ID ...]
    [--profile core_directed_single_clock_execution_v1|core_directed_single_clock_execution_v2]
    [--replay REPLAY.json] [--native-catalog CATALOG.json ...]
    [--outdir RELDIR] [--json] SOURCE.vial
  ./bin/fsmgen vial run [--language-version 1|2]
    --dut SOURCE.fsm|SOURCE.isf|SOURCE.ppif
    --backend sv_portable_verilator
    [--fixture ID] [--scenario ID ...]
    [--profile core_directed_single_clock_execution_v1|core_directed_single_clock_execution_v2]
    [--replay REPLAY.json] [--native-catalog CATALOG.json ...]
    [--outdir RELDIR] [--json] SOURCE.vial

Planning and execution write one atomic repository-local artifact tree. Runtime
staging stays repository-local and is removed before publication. All persisted
paths are repository-root-relative. Version 2 exposes source tooling,
non-mutating v1-to-v2 migration, empty-family planning, and lifecycle-control
planning; its backend, run, complete-result, and parity routes are unavailable.
Inspection returns typed source meaning without planning, execution or writes.
Discover its separate contract through ./bin/fsmgen --capability-manifest at
semantic_introspection.contract_surface_map.vial_source_inspection.inspection_contract.
USAGE
}

1;
