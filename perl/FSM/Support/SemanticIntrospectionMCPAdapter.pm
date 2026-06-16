package FSM::Support::SemanticIntrospectionMCPAdapter;

use strict;
use warnings;

use Exporter 'import';
use Cwd qw(abs_path getcwd);
use File::Basename qw(dirname);
use File::Spec;
use IPC::Cmd qw(run);
use JSON::PP ();

use FSM::Support::CapabilityManifest qw(build_capability_manifest);

our @EXPORT_OK = qw(semantic_introspection_mcp_adapter_contract_source);

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
        json_compact => JSON::PP->new->ascii->canonical,
    }, $class;
}

sub initialize_result {
    my ($self, $params) = @_;
    $params ||= {};

    my $manifest = $self->_manifest;
    my $producer = $manifest->{producer} || {};

    return {
        protocolVersion => $params->{protocolVersion} || '2025-06-18',
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
            version => $producer->{version} || '0.0-dev',
        },
        instructions => 'Read-only FSMGen semantic introspection over capability, check, semantic, schedule, diagnostic, support-accounting, and example surfaces.',
    };
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
                    section => { type => 'string', description => 'Optional section name: all, semantic_introspection, contracts, diagnostics, support_accounting, examples, embedding, backend_validation, language_surface.' },
                },
            ),
            _tool_descriptor(
                'fsmgen_check',
                'Run read-only strict check JSON for a workspace-contained source path.',
                _source_tool_properties(),
            ),
            _tool_descriptor(
                'fsmgen_semantic_introspect',
                'Run read-only normalized semantic JSON for a workspace-contained source path.',
                _source_tool_properties(),
            ),
            _tool_descriptor(
                'fsmgen_schedule_preview',
                'Run read-only schedule JSON for a workspace-contained .isf or .ppif source path.',
                _source_tool_properties(),
            ),
            _tool_descriptor(
                'fsmgen_find_examples',
                'Find repo-relative documentation and corpus examples from the manifest/support catalog.',
                {
                    query => { type => 'string', description => 'Optional case-insensitive substring matched against ids and repo-relative paths.' },
                    limit => { type => 'integer', description => 'Maximum number of catalog examples to return; default 25.' },
                },
            ),
            _tool_descriptor(
                'fsmgen_explain_diagnostic',
                'Explain a stable FSMGen diagnostic code from the manifest registry.',
                {
                    code => { type => 'string', description => 'Stable diagnostic code to explain.' },
                },
                ['code'],
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
    } elsif ($name eq 'fsmgen_schedule_preview') {
        $payload = $self->_source_query_payload('schedule', $arguments);
    } elsif ($name eq 'fsmgen_find_examples') {
        $payload = $self->_examples_payload($arguments);
    } elsif ($name eq 'fsmgen_explain_diagnostic') {
        $payload = $self->_diagnostic_payload($arguments);
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
        isError => JSON::PP::false,
    };
}

sub handle_jsonrpc_request {
    my ($self, $request) = @_;
    die "JSON-RPC request must be a hash" unless ref($request) eq 'HASH';

    my $id = $request->{id};
    my $method = $request->{method};
    return undef unless defined $id;

    my $result;
    eval {
        die "JSON-RPC method is required" unless defined($method) && length($method);
        if ($method eq 'initialize') {
            $result = $self->initialize_result($request->{params});
        } elsif ($method eq 'resources/list') {
            $result = $self->list_resources();
        } elsif ($method eq 'resources/templates/list') {
            $result = $self->list_resource_templates();
        } elsif ($method eq 'resources/read') {
            my $params = $request->{params} || {};
            $result = $self->read_resource($params->{uri});
        } elsif ($method eq 'tools/list') {
            $result = $self->list_tools();
        } elsif ($method eq 'tools/call') {
            my $params = $request->{params} || {};
            $result = $self->call_tool($params->{name}, $params->{arguments} || {});
        } elsif ($method eq 'ping') {
            $result = {};
        } else {
            die "Unsupported JSON-RPC method: $method";
        }
        1;
    } or do {
        my $error = "$@";
        chomp $error;
        return {
            jsonrpc => '2.0',
            id => $id,
            error => {
                code => -32000,
                message => $error || 'FSMGen MCP adapter error',
            },
        };
    };

    return {
        jsonrpc => '2.0',
        id => $id,
        result => $result,
    };
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
            my $request = JSON::PP->new->decode($line);
            $response = $self->handle_jsonrpc_request($request);
            1;
        } or do {
            my $error = "$@";
            chomp $error;
            $response = {
                jsonrpc => '2.0',
                id => undef,
                error => {
                    code => -32700,
                    message => $error || 'Invalid JSON-RPC request',
                },
            };
        };

        print {$out} $self->_encode_compact($response), "\n" if $response;
    }
}

sub _capability_query_payload {
    my ($self, $arguments) = @_;
    my $section = $arguments->{section} || 'semantic_introspection';
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

    my $report = $self->_sanitize_public_payload($self->_run_fsmgen_json(\@command));
    return {
        source_id => $source_id,
        source_path => $source_id,
        query_kind => $kind,
        path_sanitization => {
            machine_local_absolute_paths => 'workspace_or_repo_absolute_paths_return_relative_else_redacted',
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
        catalog_entries => \@entries,
    };
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

sub _run_fsmgen_json {
    my ($self, $command) = @_;

    if ($self->{runner}) {
        return $self->{runner}->($command);
    }

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => $command,
    );

    my $stdout = join('', @{$stdout_buf || []});
    my $stderr = join('', @{$stderr_buf || []});
    die "FSMGen command failed: $stderr$error_message"
        unless $success;

    my $decoded = eval { JSON::PP->new->decode($stdout) };
    die "FSMGen command did not emit JSON: $@"
        if $@;
    return $decoded;
}

sub _manifest {
    my ($self) = @_;
    return $self->{manifest_builder}->();
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
    return $value unless File::Spec->file_name_is_absolute($value);

    my $path = abs_path($value) || File::Spec->canonpath($value);
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
    my ($name, $description, $properties, $required) = @_;
    return {
        name => $name,
        description => $description,
        inputSchema => {
            type => 'object',
            properties => $properties || {},
            required => $required || [],
            additionalProperties => JSON::PP::false,
        },
    };
}

sub _source_tool_properties {
    return {
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
    $value =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;
    return $value;
}

1;
