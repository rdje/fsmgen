#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;
use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::ExtensionContract qw(build_extension_contract);

{
    package Test::AutoloadOnlyExtension;

    use strict;
    use warnings;

    our @AUTOLOAD_CALLS;
    our $AUTOLOAD;

    sub new {
        return bless {}, shift;
    }

    sub AUTOLOAD {
        my ($self, @args) = @_;
        push @AUTOLOAD_CALLS, $AUTOLOAD;
    }

    sub DESTROY {}
}

{
    package Test::LyingCanAutoloadExtension;

    use strict;
    use warnings;

    our @AUTOLOAD_CALLS;
    our @CAN_CALLS;
    our $AUTOLOAD;

    sub new {
        return bless {}, shift;
    }

    sub can {
        my ($self, $method_name) = @_;
        push @CAN_CALLS, $method_name;
        return sub { } if $method_name =~ /\Aafter_(?:parse_source|generate_result)\z/;
        return $self->SUPER::can($method_name);
    }

    sub AUTOLOAD {
        my ($self, @args) = @_;
        push @AUTOLOAD_CALLS, $AUTOLOAD;
    }

    sub DESTROY {}
}

{
    package Test::ExplicitAutoloadBoundaryExtension;

    use strict;
    use warnings;

    sub new {
        return bless {
            stages => [],
        }, shift;
    }

    sub after_parse_source {
        my ($self, $context) = @_;
        push @{$self->{stages}}, $context->stage;
        $self->{parse_kind} = $context->source_info->{kind};
    }

    sub after_generate_result {
        my ($self, $context) = @_;
        push @{$self->{stages}}, $context->stage;
        push @{$context->result->{autoload_boundary_explicit_markers}}, {
            parse_kind => $self->{parse_kind},
            result_kind => $context->source_info->{kind},
            stages => [@{$self->{stages}}],
        };
    }
}

{
    package Test::InheritedAutoloadBoundaryExtensionBase;

    use strict;
    use warnings;

    sub after_generate_result {
        my ($self, $context) = @_;
        $context->result->{autoload_boundary_inherited_marker} = {
            source_kind => $context->source_info->{kind},
            module_name => $context->result->{module_info}{module_name},
        };
    }
}

{
    package Test::InheritedAutoloadBoundaryExtension;

    use strict;
    use warnings;
    our @ISA = qw(Test::InheritedAutoloadBoundaryExtensionBase);

    sub new {
        return bless {}, shift;
    }
}

my $source_path = make_direct_fixture();

subtest 'typed-extension contract keeps AUTOLOAD dispatch outside the public boundary' => sub {
    my @views = (
        {
            label => 'direct typed-extension contract',
            contract => build_extension_contract(),
        },
        {
            label => 'in-process capability manifest typed-extension contract',
            contract => build_capability_manifest()->{embedding}{typed_extensions},
        },
    );

    for my $view (@views) {
        my $contract = $view->{contract};
        my $label = $view->{label};

        ok(
            !$contract->{extension_object_contract}{autoload_hook_dispatch},
            "$label does not advertise AUTOLOAD hook dispatch",
        );
        ok(
            $contract->{extension_object_contract}{must_provide_supported_hook_method},
            "$label requires a real supported hook method on extension objects",
        );
        is(
            $contract->{extension_object_contract}{supported_hook_method_policy},
            'extension objects must provide at least one real supported hook method discoverable by UNIVERSAL::can',
            "$label records the supported-hook method policy",
        );
        ok(
            !$contract->{extension_object_contract}{automatic_directory_discovery},
            "$label does not advertise implicit extension discovery",
        );
    }
};

subtest 'AUTOLOAD-only extensions fail closed before hook dispatch' => sub {
    local @Test::AutoloadOnlyExtension::AUTOLOAD_CALLS = ();
    my $error = capture_exception(sub {
        run_pipeline(
            extensions => [Test::AutoloadOnlyExtension->new()],
        );
    });

    like(
        $error,
        qr/FSM::Pipeline::HDLGenerator expects each object in 'extensions' to provide at least one supported typed-extension hook method: after_parse_source, after_generate_result/s,
        'AUTOLOAD-only extension is rejected as a hookless direct extension object',
    );
    is_deeply(
        \@Test::AutoloadOnlyExtension::AUTOLOAD_CALLS,
        [],
        'AUTOLOAD-only extension is not called while rejecting the constructor value',
    );
};

subtest 'extensions cannot opt into hooks by lying through can() plus AUTOLOAD' => sub {
    local @Test::LyingCanAutoloadExtension::AUTOLOAD_CALLS = ();
    local @Test::LyingCanAutoloadExtension::CAN_CALLS = ();

    my $error = capture_exception(sub {
        run_pipeline(
            extensions => [Test::LyingCanAutoloadExtension->new()],
        );
    });

    like(
        $error,
        qr/FSM::Pipeline::HDLGenerator expects each object in 'extensions' to provide at least one supported typed-extension hook method: after_parse_source, after_generate_result/s,
        'can-overriding AUTOLOAD extension is rejected before it can opt into hooks',
    );
    is_deeply(
        \@Test::LyingCanAutoloadExtension::CAN_CALLS,
        [],
        'registry does not ask extension-provided can() whether a typed hook exists',
    );
    is_deeply(
        \@Test::LyingCanAutoloadExtension::AUTOLOAD_CALLS,
        [],
        'can-overriding AUTOLOAD extension is not called while rejecting the constructor value',
    );
};

subtest 'explicit and inherited hook methods still dispatch normally' => sub {
    my $result = run_pipeline(
        extensions => [
            Test::ExplicitAutoloadBoundaryExtension->new(),
            Test::InheritedAutoloadBoundaryExtension->new(),
        ],
    );

    is_deeply(
        $result->{autoload_boundary_explicit_markers},
        [
            {
                parse_kind => 'fsm',
                result_kind => 'fsm',
                stages => [qw(after_parse_source after_generate_result)],
            },
        ],
        'explicit hook methods still dispatch in order',
    );
    is_deeply(
        $result->{autoload_boundary_inherited_marker},
        {
            source_kind => 'fsm',
            module_name => 'autoload_boundary_root',
        },
        'inherited real hook methods still dispatch',
    );
};

done_testing();

sub run_pipeline {
    my (%extra_args) = @_;
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        strict_mode => 1,
        quiet => 1,
        %extra_args,
    );

    return $pipeline->generate_hdl_from_file($source_path);
}

sub make_direct_fixture {
    my $tempdir = tempdir(CLEANUP => 1);
    my $path = File::Spec->catfile($tempdir, 'autoload_boundary_root.fsm');

    write_file(
        $path,
        <<'FSM'
(?fsm:autoload_boundary_root
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

    return $path;
}

sub write_file {
    my ($path, $contents) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $contents or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}

sub capture_exception {
    my ($code) = @_;
    my $ok = eval {
        $code->();
        1;
    };

    return '' if $ok;
    return $@ || 'unknown error';
}
