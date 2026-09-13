package NativeProxyPopulatedCompileInventory;
use strict;
use warnings;
use Cwd qw(abs_path);
use Digest::SHA qw(sha256_hex);
use JSON::PP ();

# Loaded only by `perl -c -MCompileInventory worker.pl`. CHECK runs after the
# complete source has compiled, without entering the worker's runtime body.
CHECK {
    my $root = abs_path('.');
    my $worker = 'docs/audits/native-proxy-populated-worker-protocol-20260913/worker.pl';
    die "compile inventory must run at the repository root\n" unless defined($root)
        && -f "$root/README.md" && abs_path($0) eq "$root/$worker";
    my (@project, @installed);
    my %paths = map { abs_path($_) => 1 } values %INC;
    $paths{"$root/$worker"} = 1;
    for my $path (sort keys %paths) {
        die "compile inventory cannot resolve a source path\n" unless defined($path) && length($path);
        open(my $handle, '<', $path) or die "cannot read compiled source: $!\n";
        binmode($handle);
        my @before = stat($handle);
        my $bytes = do { local $/; <$handle> };
        my @after = stat($handle);
        close($handle) or die "cannot close compiled source: $!\n";
        die "compiled source changed during read\n" unless defined($bytes)
            && length($bytes) == $before[7] && join(',', @before[0,1,7,9,10]) eq join(',', @after[0,1,7,9,10]);
        my $row = {size_bytes => length($bytes), sha256 => sha256_hex($bytes)};
        if (index($path, "$root/") == 0) {
            die "project source is on another volume\n" unless $before[0] == (stat($root))[0];
            $row->{path} = substr($path, length($root) + 1);
            push @project, $row;
        } else {
            # Required interpreter modules are explicit read-only toolchain
            # inputs, not project stores or a claim of complete native closure.
            $row->{installed_path} = $path;
            $row->{device} = $before[0];
            $row->{read_only_toolchain_input} = 1;
            push @installed, $row;
        }
    }
    print JSON::PP->new->canonical->ascii->pretty->encode({
        schema => 'fsmgen.inactive_populated_compile_inventory.v1',
        worker => $worker, compile_only => 1, worker_runtime_entered => 0,
        inventory_only_module => 'docs/audits/native-proxy-populated-final-admission-20260913/CompileInventory.pm',
        project_sources => \@project, installed_modules => \@installed,
        complete_installed_native_dependency_closure => 0});
}

1;
