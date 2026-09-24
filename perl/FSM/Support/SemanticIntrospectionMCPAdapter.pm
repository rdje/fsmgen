package FSM::Support::SemanticIntrospectionMCPAdapter;

use strict;
use warnings;

use Exporter 'import';
use Cwd qw(abs_path getcwd);
use File::Basename qw(dirname);
use File::Spec;
use IPC::Cmd qw(run);
use JSON::PP ();
use Scalar::Util qw(blessed);

use FSM::VIAL::Tool qw(check_vial_source_file vial_tool_capabilities vial_tool_capabilities_v2
    inspect_vial_source_file vial_source_inspection_capabilities);

use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::SemanticIntrospectionContract qw(semantic_introspection_source_query_kinds);

our @EXPORT_OK = qw(semantic_introspection_mcp_adapter_contract_source);

use constant MCP_PROTOCOL_VERSION => '2025-06-18';

sub semantic_introspection_mcp_adapter_contract_source {
    return 'FSM::Support::SemanticIntrospectionMCPAdapter';
}

sub new {
    my ($class, %args) = @_;

    my $repo_root = $args{repo_root} || _default_repo_root();
    my $workspace_root = $args{workspace_root} || getcwd();

    my $abs_repo_root = abs_path($repo_root)
        or die "FSMGen MCP adapter repo root does not exist: $repo_root";
    my $abs_workspace_root = abs_path($workspace_root)
        or die "FSMGen MCP adapter workspace root does not exist: $workspace_root";
    die "FSMGen MCP adapter workspace root is not a directory: $workspace_root"
        unless -d $abs_workspace_root;

    return bless {
        repo_root => $abs_repo_root,
        workspace_root => $abs_workspace_root,
        manifest_builder => $args{manifest_builder} || \&build_capability_manifest,
        runner => $args{runner},
        json => JSON::PP->new->ascii->canonical->pretty,
        # Wire JSON is UTF-8. ASCII-only encoding of the embedded report text
        # amplifies memory for large responses; the API text remains unchanged.
        json_compact => JSON::PP->new->utf8->canonical,
    }, $class;
}

sub initialize_result {
    my ($self, $params) = @_;
    $params ||= {};

    my $manifest = $self->_manifest;
    my $producer = $manifest->{producer} || {};

    return {
        protocolVersion => _negotiated_protocol_version($params->{protocolVersion}),
        capabilities => {
            resources => {
                listChanged => JSON::PP::false,
            },
            tools => {
                listChanged => JSON::PP::false,
            },
        },
        serverInfo => {
            name => 'fsmgen-semantic-introspection',
            title => 'FSMGen Semantic Introspection',
            version => $producer->{version} || '0.0-dev',
        },
        instructions => 'Read-only FSMGen semantic introspection over capability, check, semantic, typed VIAL inspection, schedule, diagnostic, support-accounting, and example surfaces.',
    };
}

sub _negotiated_protocol_version {
    my ($requested) = @_;
    return MCP_PROTOCOL_VERSION
        unless defined($requested) && $requested eq MCP_PROTOCOL_VERSION;
    return $requested;
}

sub list_resources {
    my ($self) = @_;

    return {
        resources => [
            $self->_resource_descriptor('fsmgen://capabilities', 'FSMGen capabilities', 'Full capability manifest, including semantic_introspection.'),
            $self->_resource_descriptor('fsmgen://contracts', 'FSMGen contracts', 'Manifest contract and semantic-introspection contract ownership.'),
            $self->_resource_descriptor('fsmgen://diagnostics', 'FSMGen diagnostics', 'Stable diagnostic code and check-JSON contract metadata.'),
            $self->_resource_descriptor('fsmgen://support-accounting', 'FSMGen support accounting', 'Corpus-backed support-accounting manifest section.'),
            $self->_resource_descriptor('fsmgen://examples', 'FSMGen examples', 'Repo-relative documentation and corpus example index.'),
            $self->_resource_descriptor('fsmgen://sources', 'FSMGen sources', 'Catalog-backed repo/workspace-relative source identity discovery.'),
        ],
    };
}

sub list_resource_templates {
    my ($self) = @_;

    my $manifest = $self->_manifest;
    my $resources = $manifest->{semantic_introspection}{mcp_resources} || [];
    my @templates = map {
        {
            uriTemplate => $_->{uri_template},
            name => $_->{query_domain},
            description => $_->{output_contract_source},
            mimeType => 'application/json',
        }
    } @$resources;

    return { resourceTemplates => \@templates };
}

sub read_resource {
    my ($self, $uri) = @_;
    die "MCP resource uri is required" unless defined($uri) && length($uri);

    my $payload;
    if ($uri eq 'fsmgen://capabilities') {
        $payload = $self->_manifest;
    } elsif ($uri eq 'fsmgen://contracts') {
        my $manifest = $self->_manifest;
        $payload = {
            manifest_contract => $manifest->{manifest_contract},
            semantic_introspection => $manifest->{semantic_introspection},
        };
    } elsif ($uri eq 'fsmgen://diagnostics') {
        $payload = $self->_manifest->{diagnostics};
    } elsif ($uri eq 'fsmgen://support-accounting') {
        $payload = $self->_manifest->{support_accounting};
    } elsif ($uri eq 'fsmgen://examples') {
        $payload = $self->_examples_payload({});
    } elsif ($uri eq 'fsmgen://sources') {
        $payload = $self->_sources_payload({});
    } elsif ($uri =~ m{\Afsmgen://vial/([^/]+)/capabilities\z}) {
        $payload = _vial_capabilities(_vial_language_version($1));
    } elsif ($uri =~ m{\Afsmgen://vial/([^/]+)/source/(.+)/(check|semantic|inspection)\z}) {
        my ($version, $source_id, $kind) = ($1, _uri_decode($2), $3);
        $version = _vial_language_version($version);
        die "FSMGEN_JSONRPC_INVALID_PARAMS: versioned VIAL resources require a .vial source"
            unless $source_id =~ /\.vial\z/i;
        my $arguments = {source_id => $source_id, language_version => $version};
        $payload = $kind eq 'inspection'
            ? $self->_vial_inspection_payload($arguments)
            : $self->_source_query_payload($kind, $arguments);
    } elsif ($uri =~ m{\Afsmgen://source/(.+)/(check|semantic|schedule)\z}) {
        my ($source_id, $kind) = (_uri_decode($1), $2);
        $payload = $self->_source_query_payload($kind, { source_id => $source_id });
    } else {
        die "Unsupported MCP resource uri: $uri";
    }

    return {
        contents => [
            {
                uri => $uri,
                mimeType => 'application/json',
                text => $self->_encode_pretty($payload),
            },
        ],
    };
}

sub list_tools {
    my ($self) = @_;

    return {
        tools => [
            _tool_descriptor(
                'fsmgen_capability_query',
                'Query the capability manifest, semantic-introspection contract, or a public manifest section.',
                {
                    section => { type => 'string', description => 'Optional section name: all, semantic_introspection, contracts, diagnostics, support_accounting, examples, embedding, backend_validation, language_surface, vial_tooling_v1, vial_tooling_v2, vial_inspection.' },
                },
                [],
                _capability_query_output_schema(),
                _read_only_closed_world_tool_annotations(),
            ),
            _tool_descriptor(
                'fsmgen_check',
                'Check a workspace-contained hardware or VIAL source through its public report contract.',
                _source_tool_properties(1),
                [],
                _source_query_output_schema(),
                _read_only_closed_world_tool_annotations(),
            ),
            _tool_descriptor(
                'fsmgen_semantic_introspect',
                'Inspect hardware normalized semantics or the complete public VIAL check result and semantic_report.',
                _source_tool_properties(1),
                [],
                _source_query_output_schema(),
                _read_only_closed_world_tool_annotations(),
            ),
            _tool_descriptor(
                'fsmgen_vial_inspect',
                'Inspect typed VIAL source bodies and lifecycle conditions through the public API without planning or execution.',
                {
                    source_id => {type => 'string', description => 'Workspace-relative VIAL source identity; absolute paths are rejected.'},
                    language_version => {type => 'integer', enum => [1, 2], description => 'Explicit VIAL version; omitted selects 1.'},
                    source_style => {type => 'string', enum => [qw(auto normal terse)], description => 'Source style selector; omitted selects auto.'},
                },
                ['source_id'],
                _vial_inspection_output_schema(),
                _read_only_closed_world_tool_annotations(),
            ),
            _tool_descriptor(
                'fsmgen_schedule_preview',
                'Run read-only schedule JSON for a workspace-contained ISF, PPIF or supported protocol-alias source.',
                _source_tool_properties(),
                [],
                _source_query_output_schema(),
                _read_only_closed_world_tool_annotations(),
            ),
            _tool_descriptor(
                'fsmgen_discover_sources',
                'Discover catalog-backed repo/workspace-relative source identities without workspace traversal.',
                {
                    query => { type => 'string', description => 'Optional case-insensitive substring matched against public catalog identity and support fields.' },
                    limit => { type => 'integer', description => 'Maximum number of sources to return; default 25.' },
                    file_kind => { type => 'string', description => 'Optional exact source file kind: fsm, isf, ppif, axi, apb, ahb or vial.' },
                    source_kind => { type => 'string', description => 'Optional exact support-catalog source_kind filter.' },
                    classification => { type => 'string', description => 'Optional exact support-catalog classification filter.' },
                },
                [],
                _sources_output_schema(),
                _read_only_closed_world_tool_annotations(),
            ),
            _tool_descriptor(
                'fsmgen_find_examples',
                'Find repo-relative documentation and corpus examples from the manifest/support catalog.',
                {
                    query => { type => 'string', description => 'Optional case-insensitive substring matched against ids and repo-relative paths.' },
                    limit => { type => 'integer', description => 'Maximum number of catalog examples to return; default 25.' },
                },
                [],
                _examples_output_schema(),
                _read_only_closed_world_tool_annotations(),
            ),
            _tool_descriptor(
                'fsmgen_explain_diagnostic',
                'Explain a stable FSMGen diagnostic code from the manifest registry.',
                {
                    code => { type => 'string', description => 'Stable diagnostic code to explain.' },
                },
                ['code'],
                _diagnostic_output_schema(),
                _read_only_closed_world_tool_annotations(),
            ),
            _tool_descriptor(
                'fsmgen_support_summary',
                'Return a bounded support-accounting summary with optional example samples.',
                {
                    limit_examples => { type => 'integer', description => 'Maximum number of sample catalog entries to include; default 10.' },
                },
                [],
                _support_summary_output_schema(),
                _read_only_closed_world_tool_annotations(),
            ),
        ],
    };
}

sub call_tool {
    my ($self, $name, $arguments) = @_;
    $arguments ||= {};
    die "MCP tool name is required" unless defined($name) && length($name);

    my $payload;
    if ($name eq 'fsmgen_capability_query') {
        $payload = $self->_capability_query_payload($arguments);
    } elsif ($name eq 'fsmgen_check') {
        $payload = $self->_source_query_payload('check', $arguments);
    } elsif ($name eq 'fsmgen_semantic_introspect') {
        $payload = $self->_source_query_payload('semantic', $arguments);
    } elsif ($name eq 'fsmgen_vial_inspect') {
        $payload = $self->_vial_inspection_payload($arguments);
    } elsif ($name eq 'fsmgen_schedule_preview') {
        $payload = $self->_source_query_payload('schedule', $arguments);
    } elsif ($name eq 'fsmgen_find_examples') {
        $payload = $self->_examples_payload($arguments);
    } elsif ($name eq 'fsmgen_discover_sources') {
        $payload = $self->_sources_payload($arguments);
    } elsif ($name eq 'fsmgen_explain_diagnostic') {
        $payload = $self->_diagnostic_payload($arguments);
    } elsif ($name eq 'fsmgen_support_summary') {
        $payload = $self->_support_summary_payload($arguments);
    } else {
        die "Unsupported MCP tool: $name";
    }

    return {
        content => [
            {
                type => 'text',
                text => $self->_encode_pretty($payload),
            },
        ],
        structuredContent => $payload,
        isError => (_is_source_failure_report($payload->{report}, $payload->{query_kind})
            || _is_vial_check_failure_report($payload->{report}, $payload->{query_kind})
            || _is_vial_inspection_failure_report($payload->{report}, $payload->{query_kind}))
            ? JSON::PP::true : JSON::PP::false,
    };
}

sub handle_jsonrpc_request {
    my ($self, $request) = @_;
    return _jsonrpc_error_response(
        undef,
        -32600,
        'JSON-RPC single request object is required; batch arrays and non-object envelopes are not supported',
    ) unless ref($request) eq 'HASH';

    my $id = $request->{id};
    my $method = $request->{method};
    return undef unless defined $id;

    if (exists $request->{jsonrpc} && defined($request->{jsonrpc}) && $request->{jsonrpc} ne '2.0') {
        return _jsonrpc_error_response($id, -32600, 'Invalid JSON-RPC version; expected 2.0');
    }
    return _jsonrpc_error_response($id, -32600, 'JSON-RPC method is required')
        unless defined($method) && length($method);

    my $result;
    eval {
        if ($method eq 'initialize') {
            $result = $self->initialize_result($request->{params});
        } elsif ($method eq 'resources/list') {
            _reject_unsupported_list_cursor($request->{params});
            $result = $self->list_resources();
        } elsif ($method eq 'resources/templates/list') {
            _reject_unsupported_list_cursor($request->{params});
            $result = $self->list_resource_templates();
        } elsif ($method eq 'resources/read') {
            my $params = $request->{params} || {};
            $result = $self->read_resource($params->{uri});
        } elsif ($method eq 'tools/list') {
            _reject_unsupported_list_cursor($request->{params});
            $result = $self->list_tools();
        } elsif ($method eq 'tools/call') {
            my $params = $request->{params} || {};
            $result = $self->call_tool($params->{name}, $params->{arguments} || {});
        } elsif ($method eq 'ping') {
            $result = {};
        } else {
            die "FSMGEN_JSONRPC_METHOD_NOT_FOUND: $method";
        }
        1;
    } or do {
        my $error = "$@";
        chomp $error;
        $error = $self->_public_error_message($error);
        if ($error =~ s/\AFSMGEN_JSONRPC_METHOD_NOT_FOUND: /Unsupported JSON-RPC method: /) {
            return _jsonrpc_error_response($id, -32601, $error);
        }
        if ($error =~ s/\AFSMGEN_JSONRPC_INVALID_PARAMS: /Invalid params: /) {
            return _jsonrpc_error_response($id, -32602, $error);
        }
        return _jsonrpc_error_response($id, -32000, $error || 'FSMGen MCP adapter error');
    };

    return {
        jsonrpc => '2.0',
        id => $id,
        result => $result,
    };
}

sub _reject_unsupported_list_cursor {
    my ($params) = @_;
    return unless ref($params) eq 'HASH' && exists $params->{cursor};

    die "FSMGEN_JSONRPC_INVALID_PARAMS: "
        . "cursor pagination is not supported by the bounded FSMGen MCP list profile";
}

sub run_stdio {
    my ($self, %args) = @_;
    my $in = $args{in} || \*STDIN;
    my $out = $args{out} || \*STDOUT;

    while (defined(my $line = <$in>)) {
        chomp $line;
        next unless $line =~ /\S/;

        my $response;
        eval {
            my $request = JSON::PP->new->utf8->decode($line);
            $response = $self->handle_jsonrpc_request($request);
            1;
        } or do {
            $response = {
                jsonrpc => '2.0',
                id => undef,
                error => {
                    code => -32700,
                    message => 'Invalid JSON-RPC request',
                },
            };
        };

        print {$out} $self->_encode_compact($response), "\n" if $response;
    }
}

sub _capability_query_payload {
    my ($self, $arguments) = @_;
    my $section = $arguments->{section} || 'semantic_introspection';
    return {section => $section, payload => _vial_capabilities($1)}
        if $section =~ /\Avial_tooling_v([12])\z/;
    return {section => $section, payload => vial_source_inspection_capabilities()}
        if $section eq 'vial_inspection';
    my $manifest = $self->_manifest;

    return $manifest if $section eq 'all';
    return {
        manifest_contract => $manifest->{manifest_contract},
        semantic_introspection => $manifest->{semantic_introspection},
    } if $section eq 'contracts';
    return $self->_examples_payload($arguments) if $section eq 'examples';

    die "Unknown capability section: $section"
        unless exists $manifest->{$section};

    return {
        section => $section,
        payload => $manifest->{$section},
    };
}

sub _source_query_payload {
    my ($self, $kind, $arguments) = @_;
    die "FSMGEN_JSONRPC_INVALID_PARAMS: source query arguments must be an object"
        unless ref($arguments) eq 'HASH' && !blessed($arguments);
    my %allowed = map { $_ => 1 } qw(source_path source_id language_version);
    die "FSMGEN_JSONRPC_INVALID_PARAMS: unknown source query argument"
        if grep { !$allowed{$_} } keys %$arguments;
    for my $key (qw(source_path source_id)) {
        die "FSMGEN_JSONRPC_INVALID_PARAMS: source identity must be a nonempty string"
            if exists($arguments->{$key}) && (!defined($arguments->{$key})
                || ref($arguments->{$key}) || !length($arguments->{$key}));
    }
    my $source = $arguments->{source_path} // $arguments->{source_id};
    die "FSMGEN_JSONRPC_INVALID_PARAMS: source_path or source_id is required"
        unless defined $source;
    if ($source =~ /\.vial\z/i) {
        die "FSMGEN_JSONRPC_INVALID_PARAMS: VIAL supports check and semantic queries only"
            unless $kind eq 'check' || $kind eq 'semantic';
        return $self->_vial_source_query_payload($kind, $source, $arguments);
    }
    die "FSMGEN_JSONRPC_INVALID_PARAMS: language_version applies only to VIAL source queries"
        if exists $arguments->{language_version};
    my ($source_path, $source_id) = $self->_resolve_source_argument($arguments);

    my @command;
    if ($kind eq 'check') {
        @command = ($self->_fsmgen_bin, '--strict', '--check', '--json', $source_path);
    } elsif ($kind eq 'semantic') {
        @command = ($self->_fsmgen_bin, '--strict', '--emit-semantic-json', $source_path);
    } elsif ($kind eq 'schedule') {
        @command = ($self->_fsmgen_bin, '--emit-schedule-json', $source_path);
    } else {
        die "Unsupported source query kind: $kind";
    }

    my $report = $self->_sanitize_public_payload($self->_run_fsmgen_json(\@command, $kind));
    return {
        source_id => $source_id,
        source_path => $source_id,
        query_kind => $kind,
        adapter_provenance => $self->_source_query_adapter_provenance($kind),
        path_sanitization => {
            machine_local_absolute_paths => 'workspace_or_repo_absolute_paths_return_relative_else_redacted',
        },
        report => $report,
    };
}

sub _vial_language_version {
    my ($version) = @_;
    die "FSMGEN_JSONRPC_INVALID_PARAMS: VIAL language_version must be 1 or 2"
        unless defined($version) && !ref($version) && $version =~ /\A[12]\z/;
    return 0 + $version;
}

sub _vial_capabilities {
    my ($version) = @_;
    return $version == 2 ? vial_tool_capabilities_v2() : vial_tool_capabilities();
}

sub _vial_source_query_payload {
    my ($self, $kind, $source, $arguments) = @_;
    my $version = _vial_language_version(
        exists($arguments->{language_version}) ? $arguments->{language_version} : 1);
    # Preserve original components: resolving symlinks here would defeat the
    # public filesystem facade's source and import authority checks.
    my $source_id = File::Spec->file_name_is_absolute($source)
        ? File::Spec->abs2rel($source, $self->{workspace_root}) : $source;
    my $report = check_vial_source_file({
        workspace_root => $self->{workspace_root}, source_id => $source_id,
        language_version => $version,
    });
    return {
        source_id => $source_id,
        source_path => $source_id,
        query_kind => $kind,
        adapter_provenance => {
            %{$self->_source_query_adapter_provenance($kind)},
            command_shape => undef,
            api_entrypoint => 'FSM::VIAL::Tool::check_vial_source_file',
            language_version => $version,
        },
        path_sanitization => {
            machine_local_absolute_paths => 'public_vial_relative_source_contract',
            semantic_paths => 'preserved_public_semantic_paths',
        },
        # VIAL already returns a public sanitized projection. Generic path
        # rewriting would corrupt its JSON-pointer-shaped semantic identities.
        report => $report,
    };
}

sub _vial_inspection_payload {
    my ($self, $arguments) = @_;
    die "FSMGEN_JSONRPC_INVALID_PARAMS: inspection arguments must be an object"
        unless ref($arguments) eq 'HASH' && !blessed($arguments);
    my %allowed = map { $_ => 1 } qw(source_id language_version source_style);
    die "FSMGEN_JSONRPC_INVALID_PARAMS: unknown inspection argument"
        if grep { !$allowed{$_} } keys %$arguments;
    my $source = $arguments->{source_id};
    die "FSMGEN_JSONRPC_INVALID_PARAMS: inspection requires a relative VIAL source_id"
        unless defined($source) && !ref($source) && $source =~ /\.vial\z/i
            && $source !~ m{(?:\A/|\A~|\A[A-Za-z]:|://|\\|\x00)};
    my $version = _vial_language_version(
        exists($arguments->{language_version}) ? $arguments->{language_version} : 1);
    my $style = exists($arguments->{source_style}) ? $arguments->{source_style} : 'auto';
    die "FSMGEN_JSONRPC_INVALID_PARAMS: source_style must be auto, normal, or terse"
        unless defined($style) && !ref($style) && $style =~ /\A(?:auto|normal|terse)\z/;
    # Preserve source components and semantic paths. The public filesystem API
    # alone owns source/import admission and constructs sanitized typed detail.
    my $report = inspect_vial_source_file({
        workspace_root => $self->{workspace_root}, source_id => $source,
        language_version => $version, source_style => $style,
    });
    return {
        source_id => $source, source_path => $source, query_kind => 'inspection',
        adapter_provenance => {
            %{$self->_source_query_adapter_provenance('inspection')},
            command_shape => undef,
            api_entrypoint => 'FSM::VIAL::Tool::inspect_vial_source_file',
            language_version => $version,
        },
        path_sanitization => {
            machine_local_absolute_paths => 'public_vial_relative_source_contract',
            semantic_paths => 'preserved_public_semantic_paths',
        },
        report => $report,
    };
}

sub _examples_payload {
    my ($self, $arguments) = @_;
    my $manifest = $self->_manifest;
    my $query = lc($arguments->{query} // '');
    my $limit = $arguments->{limit} || 25;
    $limit = 25 unless $limit =~ /\A\d+\z/ && $limit > 0;

    my @entries = @{$manifest->{support_accounting}{catalog_entries} || []};
    if (length $query) {
        @entries = grep {
            my $id = lc($_->{id} // '');
            my $relpath = lc($_->{relpath} // '');
            index($id, $query) >= 0 || index($relpath, $query) >= 0;
        } @entries;
    }
    splice @entries, $limit if @entries > $limit;

    return {
        documentation => $manifest->{documentation},
        query => $arguments->{query} // '',
        limit => $limit,
        support_summary => $self->_support_summary_payload({ limit_examples => 0 }),
        returned_count => scalar @entries,
        catalog_entries => \@entries,
    };
}

sub _sources_payload {
    my ($self, $arguments) = @_;
    $arguments ||= {};

    my $manifest = $self->_manifest;
    my $support = $manifest->{support_accounting} || {};
    my $query = lc($arguments->{query} // '');
    my $limit = _bounded_limit($arguments->{limit}, 25);
    my $file_kind_filter = lc($arguments->{file_kind} // '');
    my $source_kind_filter = lc($arguments->{source_kind} // '');
    my $classification_filter = lc($arguments->{classification} // '');

    my $query_kinds = semantic_introspection_source_query_kinds();
    my @sources = grep { defined $_ } map {
        _source_discovery_entry($_, $query_kinds)
    } @{$support->{catalog_entries} || []};

    if (length $query) {
        @sources = grep { _source_discovery_entry_matches_query($_, $query) } @sources;
    }
    if (length $file_kind_filter) {
        @sources = grep { lc($_->{file_kind} // '') eq $file_kind_filter } @sources;
    }
    if (length $source_kind_filter) {
        @sources = grep { lc($_->{source_kind} // '') eq $source_kind_filter } @sources;
    }
    if (length $classification_filter) {
        @sources = grep { lc($_->{support}{classification} // '') eq $classification_filter } @sources;
    }

    my $matched_count = scalar @sources;
    splice @sources, $limit if @sources > $limit;

    return {
        query_kind => 'source_discovery',
        source => $support->{source},
        query => $arguments->{query} // '',
        limit => $limit,
        filters => {
            file_kind => $arguments->{file_kind} // '',
            source_kind => $arguments->{source_kind} // '',
            classification => $arguments->{classification} // '',
        },
        path_policy => {
            discovery_authority => 'manifest_support_catalog_only',
            recursive_workspace_traversal => JSON::PP::false,
            hidden_paths => 'excluded',
            source_identity => 'repo_or_workspace_relative',
            machine_local_absolute_paths => 'not_returned',
        },
        total_catalog_count => scalar @{$support->{catalog_entries} || []},
        matched_count => $matched_count,
        returned_count => scalar @sources,
        sources => \@sources,
    };
}

sub _source_discovery_entry {
    my ($entry, $query_kinds) = @_;

    my $relpath = $entry->{relpath};
    return undef unless _public_catalog_relpath($relpath);

    my $file_kind = _source_file_kind($relpath, $query_kinds);
    return undef unless length $file_kind;

    my %support = map { $_ => $entry->{$_} } grep { exists $entry->{$_} } qw(
        id
        family
        classification
        coverage
        strict_supported
        diagnostic_code
        expected_module_name
        expected_top_name
        expected_lane
        has_expected_error_pattern
        has_expected_hint_pattern
    );
    $support{strict_supported} = $entry->{strict_supported} ? JSON::PP::true : JSON::PP::false
        if exists $entry->{strict_supported};

    return {
        source_id => $relpath,
        source_path => $relpath,
        relpath => $relpath,
        file_kind => $file_kind,
        source_kind => $entry->{source_kind} // '',
        available_query_kinds => [@{$query_kinds->{$file_kind}}],
        support => \%support,
    };
}

sub _public_catalog_relpath {
    my ($relpath) = @_;
    return 0 unless defined($relpath) && length($relpath);
    return 0 if File::Spec->file_name_is_absolute($relpath);
    return 0 if $relpath =~ m{\\};
    return 0 if $relpath =~ m{(?:\A|/)\.\.?(?:/|\z)};
    return 0 if $relpath =~ m{(?:\A|/)\.[^/]+};
    return 1;
}

sub _source_file_kind {
    my ($relpath, $query_kinds) = @_;
    return '' unless defined($relpath) && $relpath =~ /\.([A-Za-z0-9_]+)\z/;
    my $kind = lc($1);
    return exists($query_kinds->{$kind}) ? $kind : '';
}

sub _source_discovery_entry_matches_query {
    my ($source, $query) = @_;
    my @fields = (
        $source->{source_id},
        $source->{file_kind},
        $source->{source_kind},
        map { $source->{support}{$_} // '' } qw(id family classification coverage diagnostic_code),
    );

    for my $field (@fields) {
        return 1 if index(lc($field // ''), $query) >= 0;
    }
    return 0;
}

sub _diagnostic_payload {
    my ($self, $arguments) = @_;
    my $code = $arguments->{code};
    die "Diagnostic code argument is required" unless defined($code) && length($code);

    my $manifest = $self->_manifest;
    my @matches = grep { ($_->{code} // '') eq $code } @{$manifest->{diagnostics}{stable_codes} || []};
    die "Unknown FSMGen diagnostic code: $code" unless @matches;

    return {
        code => $code,
        diagnostic => $matches[0],
        registry_contract => $manifest->{diagnostics}{stable_code_registry},
        support_examples => _catalog_entry_sample(
            [grep { ($_->{diagnostic_code} // '') eq $code } @{$manifest->{support_accounting}{catalog_entries} || []}],
            $arguments->{limit_examples} || 10,
        ),
    };
}

sub _support_summary_payload {
    my ($self, $arguments) = @_;
    my $manifest = $self->_manifest;
    my $support = $manifest->{support_accounting} || {};
    my $limit = _bounded_limit($arguments->{limit_examples}, 10);

    return {
        query_kind => 'support_summary',
        source => $support->{source},
        entry_count => $support->{entry_count} || 0,
        classifications => $support->{classifications} || {},
        coverage_buckets => $support->{coverage_buckets} || {},
        families => $support->{families} || {},
        source_kinds => $support->{source_kinds} || {},
        id_counts => {
            supported_smoke_ids => scalar @{$support->{supported_smoke_ids} || []},
            strict_supported_ids => scalar @{$support->{strict_supported_ids} || []},
            expected_failure_ids => scalar @{$support->{expected_failure_ids} || []},
        },
        sample_catalog_entries => _catalog_entry_sample($support->{catalog_entries} || [], $limit),
    };
}

sub _resolve_source_argument {
    my ($self, $arguments) = @_;
    my $source = $arguments->{source_path} // $arguments->{source_id};
    die "source_path or source_id argument is required" unless defined($source) && length($source);

    my $candidate = File::Spec->file_name_is_absolute($source)
        ? $source
        : File::Spec->catfile($self->{workspace_root}, split m{/+}, $source);
    my $abs = abs_path($candidate)
        or die "Source path does not exist under workspace root: $source";
    die "Source path is not a regular file: $source" unless -f $abs;
    die "Source path escapes workspace root: $source"
        unless _path_is_under($abs, $self->{workspace_root});

    my $rel = File::Spec->abs2rel($abs, $self->{workspace_root});
    $rel =~ s{\\}{/}g;
    return ($abs, $rel);
}

sub _catalog_entry_sample {
    my ($entries, $limit) = @_;
    $limit = _bounded_limit($limit, 10);

    my @sample = @{$entries || []};
    splice @sample, $limit if @sample > $limit;

    return [
        map {
            {
                id => $_->{id},
                relpath => $_->{relpath},
                family => $_->{family},
                classification => $_->{classification},
                coverage => $_->{coverage},
                source_kind => $_->{source_kind},
                strict_supported => $_->{strict_supported},
                (exists $_->{diagnostic_code} ? (diagnostic_code => $_->{diagnostic_code}) : ()),
            }
        } @sample
    ];
}

sub _bounded_limit {
    my ($value, $default) = @_;
    $default = 10 unless defined($default);
    return $default unless defined($value) && $value =~ /\A\d+\z/;
    return 0 if $value == 0;
    return 100 if $value > 100;
    return $value;
}

sub _run_fsmgen_json {
    my ($self, $command, $kind) = @_;

    if ($self->{runner}) {
        return $self->{runner}->($command);
    }

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => $command,
    );

    my $stdout = join('', @{$stdout_buf || []});
    my $decoded = eval { JSON::PP->new->decode($stdout) };
    my $json_object = !$@ && ref($decoded) eq 'HASH';

    # Native check/semantic refusals intentionally emit a public report and
    # exit unsuccessfully. A JSON value alone is not evidence of that contract.
    if (!$success) {
        return $decoded if $json_object && _is_source_failure_report($decoded, $kind);
        die "FSMGen command failed without a matching public failure report";
    }
    die "FSMGen command did not emit a JSON object" unless $json_object;
    return $decoded;
}

sub _is_source_failure_report {
    my ($report, $kind) = @_;
    return 0 unless ref($report) eq 'HASH' && defined($kind);
    my %contracts = (
        check => ['check_schema_version', 'FSM::Support::CheckDiagnostics', 'check'],
        semantic => ['normalized_semantic_schema_version', 'FSM::Support::NormalizedSemanticReport', 'semantic_export'],
    );
    my $contract = $contracts{$kind} or return 0;
    my ($version_key, $producer, $mode) = @$contract;
    return 0 unless JSON::PP::is_bool($report->{success}) && !$report->{success};
    return 0 unless defined($report->{$version_key}) && !ref($report->{$version_key})
        && $report->{$version_key} eq '1';
    return 0 unless ref($report->{producer}) eq 'HASH'
        && ($report->{producer}{name} // '') eq 'FSMGen'
        && ($report->{producer}{report_source} // '') eq $producer;
    return 0 unless ref($report->{command}) eq 'HASH'
        && ($report->{command}{mode} // '') eq $mode;
    return 0 unless ref($report->{source}) eq 'HASH'
        && ref($report->{diagnostics}) eq 'ARRAY' && @{$report->{diagnostics}};
    return 0 if grep { ref($_) ne 'HASH' } @{$report->{diagnostics}};
    return 1;
}

sub _is_vial_check_failure_report {
    my ($report, $kind) = @_;
    return 0 unless ref($report) eq 'HASH' && defined($kind)
        && ($kind eq 'check' || $kind eq 'semantic');
    return 0 unless JSON::PP::is_bool($report->{success}) && !$report->{success};
    my $version = $report->{schema_version};
    return 0 unless defined($version) && !ref($version) && $version =~ /\A[12]\z/;
    return 0 unless ($report->{schema} // '') eq "fsmgen.vial_tool_result.v$version"
        && ($report->{action} // '') eq 'check'
        && ref($report->{implementation}) eq 'HASH'
        && ($report->{implementation}{component} // '') eq 'FSM::VIAL::Tool'
        && ref($report->{diagnostics}) eq 'ARRAY' && @{$report->{diagnostics}};
    return 0 if grep { ref($_) ne 'HASH' } @{$report->{diagnostics}};
    return 1;
}

sub _is_vial_inspection_failure_report {
    my ($report, $kind) = @_;
    return 0 unless defined($kind) && $kind eq 'inspection' && ref($report) eq 'HASH';
    return 0 unless ($report->{schema} // '') eq 'fsmgen.vial_source_inspection.v1'
        && ($report->{schema_version} // '') eq '1'
        && JSON::PP::is_bool($report->{success}) && !$report->{success}
        && !defined($report->{inspection}) && ref($report->{check_result}) eq 'HASH'
        && ref($report->{diagnostics}) eq 'ARRAY' && @{$report->{diagnostics}};
    return 0 if grep { ref($_) ne 'HASH' } @{$report->{diagnostics}};
    return 1;
}

sub _manifest {
    my ($self) = @_;
    return $self->{manifest_builder}->();
}

sub _source_query_adapter_provenance {
    my ($self, $kind) = @_;

    my %shape = (
        check => 'bin/fsmgen --strict --check --json <source>',
        semantic => 'bin/fsmgen --strict --emit-semantic-json <source>',
        schedule => 'bin/fsmgen --emit-schedule-json <source>',
    );

    return {
        contract_source => semantic_introspection_mcp_adapter_contract_source(),
        transport => 'jsonrpc_stdio',
        read_only => JSON::PP::true,
        shell_access => JSON::PP::false,
        workspace_root_policy => 'caller_configured_root_not_returned',
        source_identity => 'workspace_relative',
        command_shape => $shape{$kind} || 'unsupported',
    };
}

sub _sanitize_public_payload {
    my ($self, $value) = @_;

    if (ref($value) eq 'HASH') {
        return {
            map { $_ => $self->_sanitize_public_payload($value->{$_}) }
            keys %{$value}
        };
    }
    if (ref($value) eq 'ARRAY') {
        return [map { $self->_sanitize_public_payload($_) } @{$value}];
    }
    return $self->_sanitize_public_string($value)
        if defined($value) && !ref($value);
    return $value;
}

sub _sanitize_public_string {
    my ($self, $value) = @_;
    return $self->_sanitize_public_path($value)
        if File::Spec->file_name_is_absolute($value);

    # Keep relative references, URI schemes and HDL division expressions intact.
    # Quoted paths are handled first so spaces in source/workspace names remain
    # part of one path. Never expose file URIs as ambient filesystem authority.
    $value =~ s{\bfile://[^\s"'<>(),;{}\[\]]+}{[absolute-path-redacted]}gi;
    $value =~ s{(['"])((?:/|[A-Za-z]:[\\/]|\\\\)[^\r\n]*?)\1}
        {$1 . $self->_sanitize_public_path($2) . $1}gex;
    $value =~ s{
        \b[A-Za-z][A-Za-z0-9+.-]*://[^\s"'<>(),;{}\[\]]+(*SKIP)(*F)
        | (?<![\w./\\-])((?:/(?![/*])|[A-Za-z]:[\\/]|\\\\)[^\s"'<>(),;{}\[\]]+)
    }{$self->_sanitize_public_path($1)}gex;
    return $value;
}

sub _sanitize_public_path {
    my ($self, $value) = @_;
    return '[absolute-path-redacted]' if $value =~ m{\A(?:[A-Za-z]:[\\/]|\\\\)};

    my $path = abs_path($value);
    if (!defined $path) {
        # canonpath on Unix deliberately preserves '..'. Collapse it here so
        # a missing path cannot appear contained merely by its textual prefix.
        my @parts;
        for my $part (split m{/+}, $value) {
            next if $part eq '' || $part eq '.';
            if ($part eq '..') { pop @parts; }
            else { push @parts, $part; }
        }
        $path = '/' . join('/', @parts);
    }
    for my $root_key (qw(workspace_root repo_root)) {
        my $root = $self->{$root_key};
        next unless defined($root) && length($root);
        next unless _path_is_under($path, $root);

        my $rel = File::Spec->abs2rel($path, $root);
        $rel =~ s{\\}{/}g;
        return $rel;
    }
    return '[absolute-path-redacted]';
}

sub _public_error_message {
    my ($self, $message) = @_;
    $message = $self->_sanitize_public_string(_strip_perl_error_location($message));
    $message =~ s/[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]//g;
    my $marker = ' [truncated]';
    $message = substr($message, 0, 2048 - length($marker)) . $marker
        if length($message) > 2048;
    return $message;
}

sub _resource_descriptor {
    my ($self, $uri, $name, $description) = @_;
    return {
        uri => $uri,
        name => $name,
        description => $description,
        mimeType => 'application/json',
    };
}

sub _tool_descriptor {
    my ($name, $description, $properties, $required, $output_schema, $annotations) = @_;
    my $descriptor = {
        name => $name,
        description => $description,
        inputSchema => {
            type => 'object',
            properties => $properties || {},
            required => $required || [],
            additionalProperties => JSON::PP::false,
        },
    };
    $descriptor->{outputSchema} = $output_schema if $output_schema;
    $descriptor->{annotations} = $annotations if $annotations;
    return $descriptor;
}

sub _source_tool_properties {
    my ($with_vial_version) = @_;
    return {
        ($with_vial_version ? (language_version => {
            type => 'integer', enum => [1, 2],
            description => 'VIAL only: explicit language version; omitted selects 1. Rejected for hardware sources.',
        }) : ()),
        source_path => {
            type => 'string',
            description => 'Workspace-root-contained source path.',
        },
        source_id => {
            type => 'string',
            description => 'Alias for source_path, usually a repo-relative path.',
        },
    };
}

sub _capability_query_output_schema {
    return _object_schema(
        {
            section => { type => 'string' },
            payload => _open_object_schema(),
            manifest_contract => _open_object_schema(),
            semantic_introspection => _open_object_schema(),
        },
        [],
        JSON::PP::true,
    );
}

sub _source_query_output_schema {
    return _object_schema(
        {
            source_id => { type => 'string' },
            source_path => { type => 'string' },
            query_kind => { type => 'string' },
            adapter_provenance => _open_object_schema(),
            path_sanitization => _open_object_schema(),
            report => _open_object_schema(),
        },
        [qw(source_id source_path query_kind adapter_provenance path_sanitization report)],
        JSON::PP::false,
    );
}

sub _vial_inspection_output_schema {
    my $schema = _source_query_output_schema();
    $schema->{properties}{query_kind} = {type => 'string', const => 'inspection'};
    $schema->{properties}{report} = _object_schema({
        schema => {type => 'string', const => 'fsmgen.vial_source_inspection.v1'},
        schema_version => {type => 'integer', const => 1},
        success => {type => 'boolean'}, check_result => _open_object_schema(),
        inspection => {anyOf => [_open_object_schema(), {type => 'null'}]},
        diagnostics => {type => 'array', items => _open_object_schema()},
    }, [qw(schema schema_version success check_result inspection diagnostics)], JSON::PP::false);
    return $schema;
}

sub _examples_output_schema {
    return _object_schema(
        {
            documentation => { type => 'array', items => _open_object_schema() },
            query => { type => 'string' },
            limit => { type => 'integer' },
            support_summary => _open_object_schema(),
            returned_count => { type => 'integer' },
            catalog_entries => { type => 'array', items => _open_object_schema() },
        },
        [qw(documentation query limit support_summary returned_count catalog_entries)],
        JSON::PP::false,
    );
}

sub _sources_output_schema {
    return _object_schema(
        {
            query_kind => { type => 'string' },
            source => { type => 'string' },
            query => { type => 'string' },
            limit => { type => 'integer' },
            filters => _open_object_schema(),
            path_policy => _open_object_schema(),
            total_catalog_count => { type => 'integer' },
            matched_count => { type => 'integer' },
            returned_count => { type => 'integer' },
            sources => { type => 'array', items => _open_object_schema() },
        },
        [qw(query_kind source query limit filters path_policy total_catalog_count matched_count returned_count sources)],
        JSON::PP::false,
    );
}

sub _diagnostic_output_schema {
    return _object_schema(
        {
            code => { type => 'string' },
            diagnostic => _open_object_schema(),
            registry_contract => _open_object_schema(),
            support_examples => { type => 'array', items => _open_object_schema() },
        },
        [qw(code diagnostic registry_contract support_examples)],
        JSON::PP::false,
    );
}

sub _support_summary_output_schema {
    return _object_schema(
        {
            query_kind => { type => 'string' },
            source => { type => 'string' },
            entry_count => { type => 'integer' },
            classifications => _open_object_schema(),
            coverage_buckets => _open_object_schema(),
            families => _open_object_schema(),
            source_kinds => _open_object_schema(),
            id_counts => _open_object_schema(),
            sample_catalog_entries => { type => 'array', items => _open_object_schema() },
        },
        [
            qw(query_kind source entry_count classifications coverage_buckets
              families source_kinds id_counts sample_catalog_entries)
        ],
        JSON::PP::false,
    );
}

sub _object_schema {
    my ($properties, $required, $additional_properties) = @_;
    return {
        type => 'object',
        properties => $properties || {},
        required => $required || [],
        additionalProperties => $additional_properties,
    };
}

sub _open_object_schema {
    return {
        type => 'object',
        additionalProperties => JSON::PP::true,
    };
}

sub _read_only_closed_world_tool_annotations {
    return {
        readOnlyHint => JSON::PP::true,
        openWorldHint => JSON::PP::false,
    };
}

sub _fsmgen_bin {
    my ($self) = @_;
    return File::Spec->catfile($self->{repo_root}, 'bin', 'fsmgen');
}

sub _encode_pretty {
    my ($self, $payload) = @_;
    return $self->{json}->encode($payload);
}

sub _encode_compact {
    my ($self, $payload) = @_;
    return $self->{json_compact}->encode($payload);
}

sub _default_repo_root {
    my $dir = dirname(__FILE__);
    return File::Spec->rel2abs(File::Spec->catdir($dir, '..', '..', '..'));
}

sub _path_is_under {
    my ($path, $root) = @_;
    return 1 if $path eq $root;
    my $prefix = $root;
    $prefix .= '/' unless $prefix =~ m{/\z};
    return index($path, $prefix) == 0 ? 1 : 0;
}

sub _uri_decode {
    my ($value) = @_;
    die "Invalid percent encoding in MCP resource uri segment: $value"
        if $value =~ /%(?![0-9A-Fa-f]{2})/;
    $value =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;
    return $value;
}

sub _jsonrpc_error_response {
    my ($id, $code, $message) = @_;
    return {
        jsonrpc => '2.0',
        id => $id,
        error => {
            code => $code,
            message => $message,
        },
    };
}

sub _strip_perl_error_location {
    my ($message) = @_;
    $message =~ s/\s+at\s+\S+\s+line\s+\d+\.?\z//;
    return $message;
}

1;
