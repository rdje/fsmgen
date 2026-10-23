package FSM::Support::SemanticIntrospectionMCPAdapter;

use strict;
use warnings;

use Exporter 'import';
use Cwd qw(abs_path getcwd);
use File::Basename qw(dirname);
use File::Spec;
use IPC::Cmd qw(run);
use IO::Handle ();
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
            _source_query_tool_descriptor(
                'fsmgen_check',
                'Check a workspace-contained hardware or VIAL source through its public report contract.',
                1,
            ),
            _source_query_tool_descriptor(
                'fsmgen_semantic_introspect',
                'Inspect hardware normalized semantics or the complete public VIAL check result and semantic_report.',
                1,
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
            _source_query_tool_descriptor(
                'fsmgen_schedule_preview',
                'Run read-only schedule JSON for a workspace-contained ISF, PPIF or supported protocol-alias source.',
            ),
            _tool_descriptor(
                'fsmgen_discover_sources',
                'Discover catalog-backed repo/workspace-relative source identities without workspace traversal.',
                {
                    query => { type => 'string', description => 'Optional case-insensitive substring matched against public catalog identity and support fields.' },
                    limit => { type => 'integer', description => 'Maximum sources: omitted or negative selects 25; zero returns none; positive values cap at 100.' },
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
                    limit => { type => 'integer', description => 'Maximum catalog examples: omitted, zero or negative selects 25; positive values have no numeric cap.' },
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
                    limit_examples => { type => 'integer', description => 'Sample limit: omitted, zero or negative selects 10; positive values cap at 100.' },
                },
                ['code'],
                _diagnostic_output_schema(),
                _read_only_closed_world_tool_annotations(),
            ),
            _tool_descriptor(
                'fsmgen_support_summary',
                'Return a bounded support-accounting summary with optional example samples.',
                {
                    limit_examples => { type => 'integer', description => 'Maximum samples: omitted or negative selects 10; zero returns none; positive values cap at 100.' },
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
    die "FSMGEN_JSONRPC_INVALID_PARAMS: tool name must be a string"
        unless _is_json_string($name);
    die "MCP tool name is required" unless defined($name) && length($name);
    # An omitted/undef hash remains the embedded Perl method's default. The
    # JSON-RPC boundary separately rejects an explicitly supplied JSON null.
    $arguments = {} unless defined $arguments;
    die "FSMGEN_JSONRPC_INVALID_PARAMS: tool arguments must be an object"
        unless ref($arguments) eq 'HASH' && !blessed($arguments);

    my $payload;
    if ($name eq 'fsmgen_capability_query') {
        $self->_validate_metadata_arguments($name, $arguments);
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
        $self->_validate_metadata_arguments($name, $arguments);
        $payload = $self->_examples_payload($arguments);
    } elsif ($name eq 'fsmgen_discover_sources') {
        $self->_validate_metadata_arguments($name, $arguments);
        $payload = $self->_sources_payload($arguments);
    } elsif ($name eq 'fsmgen_explain_diagnostic') {
        $self->_validate_metadata_arguments($name, $arguments);
        $payload = $self->_diagnostic_payload($arguments);
    } elsif ($name eq 'fsmgen_support_summary') {
        $self->_validate_metadata_arguments($name, $arguments);
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

sub _is_json_string {
    my ($value) = @_;
    return 0 unless defined($value) && !ref($value);
    # Inspect only this detached scalar. Text/numeric reads of the caller's
    # scalar can change its JSON kind in a subsequent Storable copy.
    return JSON::PP->new->allow_nonref->canonical->encode($value) =~ /\A"/;
}

sub _is_json_integer {
    my ($value) = @_;
    return 0 unless defined($value) && !ref($value);
    my $literal = JSON::PP->new->allow_nonref->canonical->encode($value);
    return 0 unless $literal =~ /\A-?(?:0|[1-9]\d*)(?:\.\d+)?(?:[eE][+-]?\d+)?\z/;
    return $value == int($value);
}

sub _validate_metadata_arguments {
    my ($self, $name, $arguments) = @_;
    my ($tool) = grep { $_->{name} eq $name } @{$self->list_tools->{tools}};
    my $schema = $tool ? $tool->{inputSchema} : undef;
    # This is deliberately the primitive metadata vocabulary, not a general
    # JSON Schema evaluator. Refuse producer drift rather than ignore a newly
    # advertised constraint. Source-query schemas have a separate admission path.
    die "Unsupported metadata input schema"
        unless ref($schema) eq 'HASH'
            && join(',', sort keys %$schema) eq 'additionalProperties,properties,required,type'
            && $schema->{type} eq 'object'
            && ref($schema->{properties}) eq 'HASH'
            && ref($schema->{required}) eq 'ARRAY'
            && JSON::PP::is_bool($schema->{additionalProperties})
            && !$schema->{additionalProperties};
    my $properties = $schema->{properties};
    for my $property (values %$properties) {
        die "Unsupported metadata input schema"
            unless ref($property) eq 'HASH'
                && !grep { $_ ne 'type' && $_ ne 'description' } keys %$property;
        die "Unsupported metadata input schema"
            unless defined($property->{type})
                && ($property->{type} eq 'string' || $property->{type} eq 'integer');
    }
    for my $required (@{$schema->{required}}) {
        die "Unsupported metadata input schema"
            unless _is_json_string($required) && exists $properties->{$required};
        die "FSMGEN_JSONRPC_INVALID_PARAMS: $name requires argument '$required'"
            unless exists $arguments->{$required};
    }
    for my $key (sort keys %$arguments) {
        die "FSMGEN_JSONRPC_INVALID_PARAMS: unsupported argument '$key' for $name"
            unless exists $properties->{$key};
        my $type = $properties->{$key}{type};
        my $valid = $type eq 'string'
            ? _is_json_string($arguments->{$key}) : _is_json_integer($arguments->{$key});
        die "FSMGEN_JSONRPC_INVALID_PARAMS: $name argument '$key' must be a JSON $type"
            unless $valid;
    }
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
            my $params = $request->{params};
            die "FSMGEN_JSONRPC_INVALID_PARAMS: tools/call params must be an object"
                unless ref($params) eq 'HASH' && !blessed($params);
            die "FSMGEN_JSONRPC_INVALID_PARAMS: tool arguments must be an object"
                if exists($params->{arguments})
                    && (ref($params->{arguments}) ne 'HASH' || blessed($params->{arguments}));
            $result = $self->call_tool($params->{name}, $params->{arguments});
        } elsif ($method eq 'ping') {
            $result = {};
        } else {
            die "FSMGEN_JSONRPC_METHOD_NOT_FOUND: $method";
        }
        1;
    } or do {
        my $error = "$@";
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

        if ($response) {
            print {$out} $self->_encode_compact($response), "\n"
                or die "FSMGen MCP adapter cannot write response: $!";
            # A persistent client waits for this reply before sending its next
            # request. Flush the actual output handle without changing its mode
            # or Perl's globally selected handle.
            $out->flush or die "FSMGen MCP adapter cannot flush response: $!";
        }
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
        next unless exists $arguments->{$key};
        my $identity = $arguments->{$key};
        die "FSMGEN_JSONRPC_INVALID_PARAMS: source identity must be a nonempty string"
            unless _is_json_string($identity) && length($identity);
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

sub _vial_argument_version {
    my ($arguments) = @_;
    my $version = exists($arguments->{language_version}) ? $arguments->{language_version} : 1;
    die "FSMGEN_JSONRPC_INVALID_PARAMS: VIAL language_version must be a JSON integer"
        unless _is_json_integer($version);
    # URI components are textual and use _vial_language_version directly.
    # Bound resource payloads already carry the numeric version it produces.
    return _vial_language_version($version);
}

sub _vial_source_query_payload {
    my ($self, $kind, $source, $arguments) = @_;
    my $version = _vial_argument_version($arguments);
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
    my $version = _vial_argument_version($arguments);
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
    $limit = 25 unless _is_json_integer($limit) && $limit > 0;

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
    return $default unless _is_json_integer($value) && $value >= 0;
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
    my $version = $report->{$version_key};
    return 0 unless defined($version) && !ref($version) && $version eq '1';
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
    my $version = $report->{schema_version};
    return 0 unless ($report->{schema} // '') eq 'fsmgen.vial_source_inspection.v1'
        && defined($version) && !ref($version) && $version eq '1'
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
    if (defined($value) && !ref($value)) {
        # String inspection can change a decoded number's private scalar flags.
        # Preserve the untouched value when no textual path substitution occurs.
        my $original = $value;
        my $public = $self->_sanitize_public_string($value);
        return $public eq $value ? $original : $public;
    }
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
        {$self->_sanitize_quoted_public_path($1, $2, substr($value, 0, $-[0]))}gex;
    $value =~ s{
        \b[A-Za-z][A-Za-z0-9+.-]*://[^\s"'<>(),;{}\[\]]+(*SKIP)(*F)
        | (?<![\w./\\-])((?:/(?![/*])|[A-Za-z]:[\\/]|\\\\)[^\s"'<>(),;{}\[\]]+)
    }{$self->_sanitize_public_path($1)}gex;
    return $value;
}

sub _sanitize_quoted_public_path {
    my ($self, $quote, $path, $prefix) = @_;

    # A quoted division token in an operator diagnostic is not a filesystem
    # root. Keep this exception contextual: ordinary quoted roots and longer
    # paths still go through the same containment/redaction policy.
    my $operator_context = $prefix =~ /\boperator\s*\z/
        || $prefix =~ /\boperators(?:\s+currently)?\s+include\s+(?:(['"])[^'"\r\n]+\1,\s*)*\z/;
    my $public = $path eq '/' && $operator_context
        ? $path : $self->_sanitize_public_path($path);
    return $quote . $public . $quote;
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

sub _source_query_tool_descriptor {
    my ($name, $description, $with_vial_version) = @_;
    my $descriptor = _tool_descriptor(
        $name, $description, _source_tool_properties($with_vial_version), [],
        _source_query_output_schema(), _read_only_closed_world_tool_annotations(),
    );
    # Either selector is sufficient, and the runtime also accepts both.
    $descriptor->{inputSchema}{anyOf} = [
        { required => ['source_path'] },
        { required => ['source_id'] },
    ];
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
            minLength => 1,
            description => 'Workspace-root-contained source path.',
        },
        source_id => {
            type => 'string',
            minLength => 1,
            description => 'Alias for source_path, usually a repo-relative path.',
        },
    };
}

sub _capability_query_output_schema {
    return _object_schema(
        {
            section => { type => 'string' },
            payload => { anyOf => [_open_object_schema(), { type => 'integer' }] },
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
    # Perl appends LF regardless of the caller's input record separator.
    # Normalize exactly that final LF, including for newline-authored errors.
    $message =~ s/\n\z//;

    # A source diagnostic may itself end in "at design.isf line 17.". Only
    # recognize frames naming loaded code or the entry script. Compare literal
    # filenames: spaces and regexp metacharacters are ordinary filename bytes.
    # Of the matching frames, remove only the rightmost complete final suffix.
    my $frame_start = -1;
    my %seen;
    for my $file (__FILE__, $0, values %INC) {
        next unless defined($file) && !ref($file) && length($file);
        next if $seen{$file}++;
        my $prefix = " at $file line ";
        my $start = rindex($message, $prefix);
        next if $start < 0;
        my $tail = substr($message, $start + length($prefix));
        next unless $tail =~ /\A[0-9]+(?:, <[^\r\n]*> (?:line|chunk) [0-9]+)?\.\z/;
        $frame_start = $start if $start > $frame_start;
    }
    $message = substr($message, 0, $frame_start) if $frame_start >= 0;
    return $message;
}

1;

__END__

=encoding utf8

=head1 NAME

FSM::Support::SemanticIntrospectionMCPAdapter - Read-only local MCP binding

=head1 SYNOPSIS

    use FSM::Support::SemanticIntrospectionMCPAdapter;
    use JSON::PP;
    my $server = FSM::Support::SemanticIntrospectionMCPAdapter->new(
        repo_root => '.', workspace_root => '.',
    );
    my $response = $server->handle_jsonrpc_request({
        jsonrpc => '2.0', id => 1, method => 'tools/list', params => {},
    });
    print JSON::PP->new->canonical->pretty->encode($response);

Run examples from the repository root with C<perl -Iperl>. For a complete
stdio server use C<bin/fsmgen-mcp>.

=head1 METHODS

=head2 new(repo_root =E<gt> $repository, workspace_root =E<gt> $workspace)

Returns an adapter object. Roots must exist; the workspace must be a directory.
The repository defaults to the implementation's repository, and the workspace
defaults to the current directory. Absolute roots are derived internally;
public source identities are workspace-relative. C<manifest_builder> and
C<runner> are internal injection seams, not additional frozen public options.

=head2 initialize_result($params)

Returns the MCP initialization result hash: protocol version, server identity,
bounded resource/tool capabilities and read-only instructions. The adapter's
current protocol version is C<2025-06-18>. This method does not return a JSON-RPC
envelope; C<handle_jsonrpc_request> supplies one.

=head2 list_resources()

Returns C<< { resources => [...] } >> for the bounded static resource set.

=head2 list_resource_templates()

Returns C<< { resourceTemplates => [...] } >> derived from the semantic
introspection manifest contract.

=head2 read_resource($uri)

Reads a supported resource URI and returns the MCP C<contents> result, with
JSON text payloads. Unsupported/missing URIs or invalid query parameters throw.
Discover concrete URI templates through C<list_resource_templates>.

=head2 list_tools()

Returns C<< { tools => [...] } >>, including each tool's current input/output
schemas and annotations. Discover names and schemas here rather than assuming
that every CLI action is exposed as a tool.

=head2 call_tool($name, $arguments)

Returns a tool result with C<content>, C<structuredContent> and C<isError>.
The embedded Perl method defaults an omitted or C<undef> C<$arguments> to an
empty hash; any supplied defined value must be an unblessed hash. This optional
Perl default does not admit explicit JSON null at the JSON-RPC boundary.
Expected source-check/inspection refusals set C<isError> while retaining their
structured report. Unsupported tools and invalid invocations can throw; the
JSON-RPC dispatcher translates those exceptions. Source queries are constrained
by the configured workspace and supported source/query applicability.

=head2 handle_jsonrpc_request($request)

Accepts a decoded single request hash and returns a JSON-RPC response hash, or
C<undef> for notifications. Batch arrays are unsupported. Handles initialization,
ping, resource discovery/reads and tool discovery/calls. Invalid envelopes,
unsupported methods, invalid parameters and adapter failures produce the
corresponding JSON-RPC error responses. No list pagination is implemented.

=head2 run_stdio(in =E<gt> $input_handle, out =E<gt> $output_handle)

Runs the server until input EOF; the default handles are STDIN and STDOUT.
Transport is one UTF-8 JSON object per line. Responses are compact JSON lines;
each response is flushed to the supplied output handle before reading the next
request, so clients keep stdin open across exchanges. Flushing does not change
the selected handle or its buffering mode. Notifications produce no response.
An output write/flush failure throws. This is a blocking loop, not a background
service. It does not implement HTTP or Content-Length framing.

=head1 SOURCE QUERY SELECTORS

C<fsmgen_check>, C<fsmgen_semantic_introspect> and
C<fsmgen_schedule_preview> require C<source_id> or C<source_path>. Their
C<inputSchema> uses C<anyOf>, so both selectors are permitted. Each supplied
selector must be a nonempty JSON string, even when the other selects the source.
When both are supplied, C<source_path> takes precedence. Prefer workspace-relative
identities; absolute paths are accepted only when the configured workspace
and the source format's public filesystem rules admit them.

Schema admission does not establish file existence, workspace containment or
source/query applicability. Check and semantic queries accept the optional
C<language_version> selector only for VIAL; omission selects version 1.
Schedule preview has no version selector and does not accept VIAL sources.
The separate C<fsmgen_vial_inspect> tool requires a relative C<source_id> and
has no C<source_path> alias. Discover current applicability and schemas before
selecting a query.

=head1 CURRENT ARGUMENT ADMISSION

Follow each tool's C<inputSchema>. Arguments are JSON objects; quoted numbers,
numbers and Booleans have distinct kinds. Omitting C<arguments> and explicitly
supplying JSON null are different requests. C<tools/call> requires object
C<params> with a string C<name>; C<arguments> may be omitted but must be an
object when present. Malformed parameter/name/argument kinds return JSON-RPC
C<-32602>. Outer parameter metadata such as C<_meta> is not a tool argument.

The metadata tools C<fsmgen_capability_query>, C<fsmgen_discover_sources>,
C<fsmgen_find_examples>, C<fsmgen_explain_diagnostic> and
C<fsmgen_support_summary> enforce their declared required fields, primitive
types and closed argument objects. For example, diagnostic C<code> must be
present and string-valued; an unknown string code still produces the semantic
lookup error, while a missing code or numeric code is an invalid parameter.
String fields accept strings that look numeric; integer fields reject quoted
numbers, Booleans and fractional numbers. Integral number spellings such as
C<1.0> and C<1e0> are integers. Each operation has its own sample-limit policy;
see L</DIAGNOSTIC SAMPLE LIMITS>.
Metadata admission preserves the caller's request values and kinds through
later copies. Resource reads and capability aliases keep their own contracts.

VIAL tool C<language_version> fields must be JSON integers C<1> or C<2>;
omission selects C<1>. Quoted versions are invalid parameters. Integral decimal
or exponent spellings select the corresponding version. Version components
inside resource URIs are textual C<1> or C<2> path components, parsed separately
from tool arguments; their existing versioned and unversioned defaults remain.

Source and metadata argument validation preserves supplied values and their
JSON kinds in subsequent copies. It does not coerce invalid numeric identities
to strings or quoted versions to numbers. Source existence, containment and
query applicability remain separate checks after structural admission.

=head1 CAPABILITY QUERY PAYLOADS

C<fsmgen_capability_query> always returns an object in C<structuredContent>.
For a selected manifest section, that object normally contains C<section> and
C<payload>. The payload can currently be an object or an integer:
C<manifest_schema_version> preserves the integer from the full manifest.
Do not coerce it to a Boolean or require every payload to be an object.

The C<all>, C<contracts> and C<examples> selectors return their corresponding
objects directly, rather than a uniform C<payload> wrapper. Versioned VIAL
tooling and VIAL inspection capability selectors use wrapped object payloads.
Consult the selected section's public contract for its complete field meaning;
the tool's envelope schema does not freeze every nested capability record.

=head1 DIAGNOSTIC SAMPLE LIMITS

C<fsmgen_explain_diagnostic> requires the stable diagnostic C<code> string.
It returns that registry entry and compact C<support_examples> whose catalog
C<diagnostic_code> matches it. Unknown or missing codes are refused. This is a
metadata lookup; it does not execute those examples or diagnose a source.

The optional integer C<limit_examples> selects the maximum sample count.
Omission, zero or a negative value selects the default of 10. Positive limits
are capped at 100, including large integral numbers such as C<1e30>.

The metadata operations deliberately have different policies:

=over 4

=item C<fsmgen_explain_diagnostic.limit_examples>

Omitted, zero or negative selects 10; positive values cap at 100.

=item C<fsmgen_support_summary.limit_examples>

Omitted or negative selects 10; zero returns no samples; positive values cap at 100.

=item C<fsmgen_discover_sources.limit>

Omitted or negative selects 25; zero returns no sources; positive values cap at 100.

=item C<fsmgen_find_examples.limit>

Omitted, zero or negative selects 25. Positive values have no numeric cap;
a sufficiently large value returns all matching catalog entries.

=back

All supplied limits must be JSON integers, including mathematically integral
decimal or exponent spellings. Quoted numbers, Booleans, null and fractions are
invalid parameters. Limits count catalog records, preserve catalog order and
do not change full-population aggregates. Discovery and example results expose
the effective C<limit> and actual C<returned_count>; diagnostic and support
results expose their sample arrays. Resource reads use their default limits;
select a limit through the corresponding tool's arguments.

Actual samples can be fewer than the selected maximum, including an empty
array when no catalog entry matches the code. Samples follow catalog order;
neither their number nor their presence proves a fresh source check. Their
complete compact field dictionary follows below.

=head1 CATALOG SAMPLE RESULTS

The compact catalog records in C<fsmgen_support_summary>'s
C<sample_catalog_entries> and C<fsmgen_explain_diagnostic>'s
C<support_examples> share these fields:

=over 4

=item C<id>

The catalog entry identifier. Correlate examples by this identifier rather
than their position in a sample; it is not a JSON-RPC request ID.

=item C<relpath>

The repository-relative catalog path. Before passing it as a source identity,
ensure that the source exists under the configured workspace. Catalog samples
do not discover arbitrary files in that workspace.

=item C<family>

The catalog's feature/protocol grouping, used by support-accounting aggregates.

=item C<classification>

The catalog's support classification. For example, C<supported_smoke> and
C<expected_failure> describe different kinds of maintained examples; a refusal
fixture must not be interpreted as a supported successful design.

=item C<coverage>

The catalog's named coverage bucket. This is a category, not a percentage or
proof that all cases in that category have been qualified.

=item C<source_kind>

The catalog's source-kind label. Use source discovery's
C<available_query_kinds> to select applicable operations; this label alone
does not establish that every query accepts the source.

=item C<strict_supported>

A Boolean copied from the public catalog's strict-support declaration. Reading
this field does not execute a fresh strict check or a regression test.

=item C<diagnostic_code> (optional)

Included only when the selected catalog entry declares a diagnostic code.
It describes that example's expected diagnostic, not an error raised by this
catalog query. Absence of this field is valid; do not require it on every entry.

=back

The common fields are retained for every compact record; C<diagnostic_code>
depends on the selected entry. Samples preserve catalog order, which is not
a stable choice of first example. These records intentionally omit other
catalog metadata. C<fsmgen_find_examples>'s C<catalog_entries>, the full
C<fsmgen://support-accounting> resource and the capability section retain the
larger public support-accounting catalog contract. The examples query's
embedded C<support_summary> has an empty C<sample_catalog_entries> array;
its top-level C<catalog_entries> carry the selected full records. Do not
confuse those records with compact samples.

=head1 ERROR MESSAGES

C<handle_jsonrpc_request> returns adapter failures as JSON-RPC errors with
C<code> and C<message>; it does not include C<error.data>, raw commands or stderr.
Invalid tool parameters use C<-32602>, unsupported methods use C<-32601>, and
other adapter failures use C<-32000>. A valid source-query result can instead
carry C<isError: true> and its structured diagnostic report. Use that report's
fields to interpret source failures rather than parsing the adapter message.

Message formatting removes a recognized final Perl location naming a loaded
module or the entry script, including spaced filenames and optional input
C<line> or C<chunk> annotations. It normalizes one terminal LF independently
of the caller's input record separator. Authored source references such as
C<Authored diagnostic at design.isf line 17.> remain meaningful message text;
fake location fragments and quotes/operators are not general removal patterns.

This is bounded string recognition: deliberately authored text identical to a
loaded-code frame cannot be distinguished from Perl's automatic suffix. Other
stack-trace grammars and C<#line> filename remappings are not promised by this
formatter. Structured source reports retain their separate diagnostic contract.

Messages then follow path redaction and control-character filtering, with a
maximum of 2048 Perl characters including the C< [truncated]> marker when
truncated. That limit is not a UTF-8 byte limit. Multi-line public reasons keep
their internal newlines. The current capitalized C<Operator '/'> context still
has a separately owned redaction discrepancy; lowercase operator context and
ordinary filesystem-root/path redaction retain their established behavior.
An authored zero-valued reason currently selects the generic fallback message;
its nonempty-string preservation repair is separately owned.

=head1 FUNCTIONS

=head2 semantic_introspection_mcp_adapter_contract_source()

Optional explicit export returning this module's contract-owner name.

=head1 EFFECTS AND STABILITY

The adapter reads sources/metadata and may invoke the bounded native check,
semantic or schedule commands. VIAL tools provide check and typed source
inspection. It does not expose authoring, arbitrary shell access or simulation
execution. The wider VIAL plan/run lifecycle is a separate API boundary.

The language-neutral semantic-introspection contract and the manual's MCP
compatibility matrix govern supported resources, tools, failures and transport.
This module is their Perl adapter, not a second semantic authority. See
L<FSM::Support::CapabilityManifest> and L<FSM::VIAL::Tool>.

=cut
