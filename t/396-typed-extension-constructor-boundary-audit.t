#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP qw(decode_json);
use Scalar::Util qw(blessed);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Extension::Loader;
use FSM::Pipeline::HDLGenerator;
use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::ExtensionContract qw(build_extension_contract);

my $repo_root = File::Spec->rel2abs(File::Spec->catdir($FindBin::Bin, '..'));
my $fsmgen_bin = File::Spec->catfile($repo_root, 'bin', 'fsmgen');
my $tempdir = tempdir(CLEANUP => 1);
my $extension_lib = File::Spec->catdir($tempdir, 'lib');
my $source_path = File::Spec->catfile($tempdir, 'constructor_boundary_root.fsm');
my $lying_cli_output = File::Spec->catfile($tempdir, 'lying_can_constructor.sv');
my $inherited_cli_output = File::Spec->catfile($tempdir, 'inherited_constructor.sv');

my $base_module = 'FSM::BoundaryAudit::ConstructorProbe::Base';
my $explicit_module = 'FSM::BoundaryAudit::ConstructorProbe::Explicit';
my $inherited_module = 'FSM::BoundaryAudit::ConstructorProbe::Inherited';
my $lying_can_module = 'FSM::BoundaryAudit::ConstructorProbe::LyingCanAutoload';
my $autoload_only_module = 'FSM::BoundaryAudit::ConstructorProbe::AutoloadOnly';
my $unblessed_module = 'FSM::BoundaryAudit::ConstructorProbe::UnblessedNew';

write_constructor_modules($extension_lib);
write_direct_fixture($source_path);
unshift @INC, $extension_lib;

subtest 'typed-extension manifests advertise real new() construction' => sub {
    my @views = (
        {
            label => 'direct typed-extension contract',
            contract => build_extension_contract(),
        },
        {
            label => 'in-process capability manifest typed-extension contract',
            contract => build_capability_manifest()->{embedding}{typed_extensions},
        },
        {
            label => 'CLI capability manifest typed-extension contract',
            contract => run_capability_manifest('--capability-manifest')->{embedding}{typed_extensions},
        },
        {
            label => 'CLI alias capability manifest typed-extension contract',
            contract => run_capability_manifest('--emit-capability-manifest')->{embedding}{typed_extensions},
        },
    );

    for my $view (@views) {
        my $object_contract = $view->{contract}{extension_object_contract} || {};
        is(
            $object_contract->{constructor_for_module_loading},
            'new()',
            "$view->{label} advertises new() module construction",
        );
        ok(
            $object_contract->{must_be_blessed_object},
            "$view->{label} requires loaded modules to return blessed objects",
        );
        ok(
            !$object_contract->{autoload_hook_dispatch},
            "$view->{label} keeps AUTOLOAD hook dispatch disabled",
        );
    }
};

subtest 'loader accepts explicit and inherited real new() constructors' => sub {
    my $loader = FSM::Extension::Loader->new();
    my $extensions = $loader->load_modules([$explicit_module, $inherited_module]);

    is(ref($extensions), 'ARRAY', 'loader returns an extension array');
    is(scalar(@{$extensions || []}), 2, 'loader returns one object per real constructor module');
    isa_ok($extensions->[0], $explicit_module);
    isa_ok($extensions->[1], $inherited_module);
    ok(blessed($extensions->[0]), 'explicit constructor result is blessed');
    ok(blessed($extensions->[1]), 'inherited constructor result is blessed');
};

subtest 'loader rejects fake or invalid constructor boundaries' => sub {
    my $loader = FSM::Extension::Loader->new();

    assert_loader_rejects(
        $loader,
        $lying_can_module,
        qr/Extension module:\s+'\Q$lying_can_module\E'.*must provide new\(\)/s,
        'loader ignores extension-provided can() and AUTOLOAD for new()',
    );
    assert_loader_rejects(
        $loader,
        $autoload_only_module,
        qr/Extension module:\s+'\Q$autoload_only_module\E'.*must provide new\(\)/s,
        'loader rejects AUTOLOAD-only constructor discovery',
    );
    assert_loader_rejects(
        $loader,
        $unblessed_module,
        qr/Extension module:\s+'\Q$unblessed_module\E'.*did not return a blessed object from new\(\)/s,
        'loader rejects real new() constructors that return unblessed values',
    );
};

subtest 'pipeline dispatches only objects built through real constructors' => sub {
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        strict_mode => 1,
        quiet => 1,
        extension_modules => [$explicit_module, $inherited_module],
    );
    my $result = $pipeline->generate_hdl_from_file($source_path);

    is(
        $result->{module_info}{module_name},
        'constructor_boundary_root',
        'pipeline still generates the source module',
    );
    assert_constructor_markers(
        $result->{constructor_boundary_markers},
        [$explicit_module, $inherited_module],
        'pipeline records both real constructor modules',
    );
    like(
        $result->{hdl_code},
        qr{// constructor boundary marker: \Q$explicit_module\E}s,
        'pipeline output includes explicit constructor extension marker',
    );
    like(
        $result->{hdl_code},
        qr{// constructor boundary marker: \Q$inherited_module\E}s,
        'pipeline output includes inherited constructor extension marker',
    );

    my $error = eval {
        FSM::Pipeline::HDLGenerator->new(
            debug_level => 0,
            target_language => 'systemverilog',
            strict_mode => 1,
            quiet => 1,
            extension_modules => [$lying_can_module],
        );
        undef;
    };
    $error = $@ if !$error;
    like(
        $error,
        qr/Extension module:\s+'\Q$lying_can_module\E'.*must provide new\(\)/s,
        'pipeline rejects fake can()/AUTOLOAD constructor modules before dispatch',
    );
};

subtest 'CLI rejects fake constructor discovery but accepts inherited real new()' => sub {
    my ($lying_success, $lying_error, $lying_full, $lying_stdout, $lying_stderr) =
        run_cli_module($lying_can_module, $lying_cli_output);

    ok(!$lying_success, 'CLI rejects a module with only fake can()/AUTOLOAD new()');
    ok(!-e $lying_cli_output, 'CLI does not emit HDL for fake constructor modules');
    my $lying_output = join(
        '',
        @{$lying_stdout || []},
        @{$lying_stderr || []},
        ($lying_error || ''),
    );
    like(
        $lying_output,
        qr/Extension module:\s+'\Q$lying_can_module\E'.*must provide new\(\)/s,
        'CLI reports the real-constructor boundary with module context',
    );

    my ($inherited_success, $inherited_error, $inherited_full, $inherited_stdout, $inherited_stderr) =
        run_cli_module($inherited_module, $inherited_cli_output);

    ok($inherited_success, 'CLI accepts inherited real new() constructors');
    is(join('', @{$inherited_stderr || []}), '', 'CLI inherited-constructor run keeps stderr clean');
    ok(-e $inherited_cli_output, 'CLI emits HDL for inherited real constructors');
    my $hdl = slurp($inherited_cli_output);
    like(
        $hdl,
        qr{// constructor boundary marker: \Q$inherited_module\E}s,
        'CLI output carries the inherited constructor extension marker',
    );
};

done_testing();

sub assert_loader_rejects {
    my ($loader, $module_name, $pattern, $label) = @_;
    my $error = eval {
        $loader->load_modules([$module_name]);
        undef;
    };
    $error = $@ if !$error;

    like($error, $pattern, $label);
}

sub assert_constructor_markers {
    my ($markers, $expected_modules, $label) = @_;
    is(ref($markers), 'ARRAY', "$label returns constructor marker array");
    is(scalar(@{$markers || []}), scalar(@{$expected_modules || []}), "$label marker count matches modules");

    my @actual_modules = map { $_->{module_name} } @{$markers || []};
    is_deeply(\@actual_modules, $expected_modules, "$label marker order matches module load order");

    for my $marker (@{$markers || []}) {
        is($marker->{source_kind}, 'fsm', "$label marker records fsm source kind");
        is($marker->{target_language}, 'systemverilog', "$label marker records target language");
    }
}

sub run_cli_module {
    my ($module_name, $output_path) = @_;
    return run(
        command => [
            $^X,
            '-I', $extension_lib,
            $fsmgen_bin,
            '--extension-module', $module_name,
            '-o', $output_path,
            '--quiet',
            $source_path,
        ],
    );
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

sub write_constructor_modules {
    my ($lib_root) = @_;
    my $module_dir = File::Spec->catdir($lib_root, qw(FSM BoundaryAudit ConstructorProbe));
    make_path($module_dir);

    write_file(
        File::Spec->catfile($module_dir, 'Base.pm'),
        <<'PERL'
package FSM::BoundaryAudit::ConstructorProbe::Base;

use strict;
use warnings;

sub new {
    my ($class) = @_;
    return bless {
        constructed_class => $class,
    }, $class;
}

sub after_generate_result {
    my ($self, $context) = @_;
    push @{$context->result->{constructor_boundary_markers}}, {
        module_name => ref($self),
        constructed_class => $self->{constructed_class},
        source_kind => $context->source_info->{kind},
        target_language => $context->target_language,
    };
    $context->result->{hdl_code} .= "\n// constructor boundary marker: " . ref($self) . "\n";
}

1;
PERL
    );

    write_file(
        File::Spec->catfile($module_dir, 'Explicit.pm'),
        <<'PERL'
package FSM::BoundaryAudit::ConstructorProbe::Explicit;

use strict;
use warnings;
use parent 'FSM::BoundaryAudit::ConstructorProbe::Base';

sub new {
    my ($class) = @_;
    return bless {
        constructed_class => $class,
    }, $class;
}

1;
PERL
    );

    write_file(
        File::Spec->catfile($module_dir, 'Inherited.pm'),
        <<'PERL'
package FSM::BoundaryAudit::ConstructorProbe::Inherited;

use strict;
use warnings;
use parent 'FSM::BoundaryAudit::ConstructorProbe::Base';

1;
PERL
    );

    write_file(
        File::Spec->catfile($module_dir, 'LyingCanAutoload.pm'),
        <<'PERL'
package FSM::BoundaryAudit::ConstructorProbe::LyingCanAutoload;

use strict;
use warnings;

our $AUTOLOAD;

sub can {
    my ($class, $method_name) = @_;
    return sub { return bless {}, $class } if $method_name eq 'new';
    return $class->SUPER::can($method_name);
}

sub AUTOLOAD {
    my ($class) = @_;
    return bless {}, $class if $AUTOLOAD =~ /::new\z/;
    die "Unexpected AUTOLOAD dispatch for $AUTOLOAD";
}

sub DESTROY {}

1;
PERL
    );

    write_file(
        File::Spec->catfile($module_dir, 'AutoloadOnly.pm'),
        <<'PERL'
package FSM::BoundaryAudit::ConstructorProbe::AutoloadOnly;

use strict;
use warnings;

our $AUTOLOAD;

sub AUTOLOAD {
    my ($class) = @_;
    return bless {}, $class if $AUTOLOAD =~ /::new\z/;
    die "Unexpected AUTOLOAD dispatch for $AUTOLOAD";
}

sub DESTROY {}

1;
PERL
    );

    write_file(
        File::Spec->catfile($module_dir, 'UnblessedNew.pm'),
        <<'PERL'
package FSM::BoundaryAudit::ConstructorProbe::UnblessedNew;

use strict;
use warnings;

sub new {
    return {};
}

1;
PERL
    );
}

sub write_direct_fixture {
    my ($path) = @_;
    write_file(
        $path,
        <<'FSM'
(?fsm:constructor_boundary_root
  (+system
    (clock clk)
    (sreset rst)
  )
  (+size
    (OUT 1)
  )
  (idle
    (= (OUT 1))
  )
)
FSM
    );
}

sub write_file {
    my ($path, $contents) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $contents or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}

sub slurp {
    my ($path) = @_;
    open my $fh, '<', $path or die "Cannot open $path: $!";
    local $/ = undef;
    my $contents = <$fh>;
    close $fh or die "Cannot close $path: $!";
    return $contents;
}
