#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP qw(decode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::CapabilityManifest qw(build_capability_manifest);

my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my %require_cache;

subtest 'direct support contracts publish loadable module provenance' => sub {
    my $payload = build_direct_contract_payload();
    assert_module_provenance($payload, 'direct support contracts');
};

subtest 'capability manifest publishes loadable module provenance' => sub {
    my @views = (
        {
            label => 'in-process capability manifest',
            payload => build_capability_manifest(),
        },
        {
            label => 'CLI capability manifest',
            payload => run_capability_manifest('--capability-manifest'),
        },
        {
            label => 'CLI alias capability manifest',
            payload => run_capability_manifest('--emit-capability-manifest'),
        },
    );

    for my $view (@views) {
        assert_module_provenance($view->{payload}, $view->{label});
    }
};

done_testing();

sub build_direct_contract_payload {
    my $support_dir = File::Spec->catdir($repo_root, 'perl', 'FSM', 'Support');
    my @contract_files = sort glob(File::Spec->catfile($support_dir, '*Contract.pm'));
    my %contracts;

    ok(@contract_files, 'found support contract modules to inspect');

    for my $file (@contract_files) {
        my $module = module_name_from_file($file);
        require_ok($module);

        no strict 'refs';
        my @builders = grep { /^build_.*_contract$/ } @{"${module}::EXPORT_OK"};
        use strict 'refs';

        next unless @builders == 1;

        no strict 'refs';
        my $builder = \&{"${module}::$builders[0]"};
        use strict 'refs';

        $contracts{$module} = $builder->();
    }

    return \%contracts;
}

sub assert_module_provenance {
    my ($payload, $label) = @_;
    my @entries = collect_module_provenance_entries($payload, $label);

    ok(@entries, "$label publishes module provenance entries");

    for my $entry (@entries) {
        assert_module_reference($entry->{module}, $entry->{path});
    }
}

sub collect_module_provenance_entries {
    my ($value, $path) = @_;
    my @entries;

    return @entries unless ref($value);

    if (ref($value) eq 'HASH') {
        for my $key (sort keys %$value) {
            my $child = $value->{$key};
            my $child_path = "$path.$key";

            if ($key =~ /(?:^|_)contract_source\z/
                || $key =~ /\A(?:report_source|report_builder|registry_source)\z/) {
                push @entries, scalar_module_entry($child, $child_path);
                next;
            }

            if ($key =~ /(?:^|_)contract_source_map\z/) {
                push @entries, map_module_entries($child, $child_path);
                next;
            }

            if ($key =~ /\A(?:implementation_owners|report_sources)\z/) {
                push @entries, array_module_entries($child, $child_path);
                next;
            }

            push @entries, collect_module_provenance_entries($child, $child_path);
        }
        return @entries;
    }

    if (ref($value) eq 'ARRAY') {
        for my $index (0 .. $#$value) {
            push @entries, collect_module_provenance_entries($value->[$index], "$path\[$index]");
        }
        return @entries;
    }

    return @entries;
}

sub scalar_module_entry {
    my ($value, $path) = @_;
    ok(!ref($value), "$path is a scalar module name");
    return ref($value)
        ? ()
        : ({ path => $path, module => $value });
}

sub array_module_entries {
    my ($value, $path) = @_;
    ok(ref($value) eq 'ARRAY', "$path is an array of module names");
    return () unless ref($value) eq 'ARRAY';

    my @entries;
    for my $index (0 .. $#$value) {
        push @entries, scalar_module_entry($value->[$index], "$path\[$index]");
    }
    return @entries;
}

sub map_module_entries {
    my ($value, $path) = @_;
    ok(ref($value) eq 'HASH', "$path is a map of module names");
    return () unless ref($value) eq 'HASH';

    my @entries;
    for my $key (sort keys %$value) {
        push @entries, scalar_module_entry($value->{$key}, "$path.$key");
    }
    return @entries;
}

sub assert_module_reference {
    my ($module, $path) = @_;

    like(
        $module,
        qr/\AFSM(?:::[A-Za-z_]\w*)+\z/,
        "$path uses an FSM::* module name",
    );
    return unless defined($module) && $module =~ /\AFSM(?:::[A-Za-z_]\w*)+\z/;

    my $module_file = repo_module_file($module);
    ok(-f $module_file, "$path points at an existing project module file");
    ok(require_module_once($module), "$path module loads successfully");
}

sub require_module_once {
    my ($module) = @_;
    return $require_cache{$module}
        if exists $require_cache{$module};

    my $ok = eval "require $module; 1" ? 1 : 0;
    diag("Failed to load $module: $@") unless $ok;
    $require_cache{$module} = $ok;
    return $ok;
}

sub run_capability_manifest {
    my ($mode) = @_;
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', $mode],
    );

    ok($success, "$mode succeeds");
    is(join('', @{$stderr_buf || []}), '', "$mode keeps stderr clean");

    return decode_json(join('', @{$stdout_buf || []}));
}

sub repo_module_file {
    my ($module) = @_;
    my @parts = split /::/, $module;
    $parts[-1] .= '.pm';
    return File::Spec->catfile($repo_root, 'perl', @parts);
}

sub module_name_from_file {
    my ($file) = @_;
    my $base = File::Spec->abs2rel($file, File::Spec->catdir($repo_root, 'perl'));
    $base =~ s{\.pm$}{};
    $base =~ s{[/\\]}{::}g;
    return $base;
}
