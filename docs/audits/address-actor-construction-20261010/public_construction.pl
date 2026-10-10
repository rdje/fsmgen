use strict;
use warnings;
use lib 'perl';
use JSON::PP;
use Scalar::Util qw(blessed refaddr);
use FSM::Adapter::ISF;

# Fresh own-source instrumentation through the public facade. This is not an
# original native capture. Observer-held old clauses are marked separately.
my $json = JSON::PP->new->canonical;
my $request = do { local $/; $json->decode(<STDIN>) };
die 'two complete source inputs and reached own pass order required'
    unless ref($request) eq 'HASH' && @{$request->{sources} || []} == 2
        && @{$request->{passes} || []};
my %allowed = map { $_ => 1 } qw(
    FSM::Adapter::ISF FSM::Adapter::ISF::Parser FSM::Adapter::ISF::LispishAdapter
);

sub graph {
    my ($value, $seen, $classes, $path) = @_;
    return $value unless ref($value);
    my $class = blessed($value);
    die 'non-own object outside construction checkpoint' if $class && !$allowed{$class};
    my $kind = $class ? 'HASH' : ref($value);
    die 'non-plain construction checkpoint node' unless $kind eq 'HASH' || $kind eq 'ARRAY';
    my $address = refaddr($value);
    return ['reference', $seen->{$address}] if exists $seen->{$address};
    $seen->{$address} = $path;
    $classes->{$path} = $class if $class;
    if ($kind eq 'HASH') {
        my %out;
        for my $key (sort keys %$value) {
            my $escaped = $key;
            $escaped =~ s/~/~0/g;
            $escaped =~ s{/}{~1}g;
            $out{$key} = graph($value->{$key}, $seen, $classes, "$path/$escaped");
        }
        return ['hash', \%out];
    }
    return ['array', [map { graph($value->[$_], $seen, $classes, "$path/$_") } 0 .. $#$value]];
}

sub checkpoint {
    my ($items) = @_;
    my %classes;
    return {graph => graph($items, {}, \%classes, ''), classes => \%classes};
}

my $facade = FSM::Adapter::ISF->new;
my @cases;
for my $position (0 .. $#{$request->{sources}}) {
    my ($ast, $actor, $final);
    my (@events, @type_checks);
    my $build = FSM::Adapter::ISF::Parser->can('_build_actor');
    my $aggregate = FSM::Adapter::ISF::Parser->can('_is_aggregate_type_spec');
    my $require = FSM::Support::ISFRecordPortContexts->can('_require');
    no warnings 'redefine';
    local *FSM::Adapter::ISF::Parser::_build_actor = sub {
        $ast = $_[1];
        return $build->(@_);
    };
    local *FSM::Adapter::ISF::Parser::_is_aggregate_type_spec = sub {
        my $spec = $_[0];
        my $observation = checkpoint([$facade, $ast, $actor, $spec]);
        push @type_checks, $observation;
        if (ref($spec) eq 'HASH' && ($spec->{kind} || '') eq 'list') {
            die 'duplicate failed admission checkpoint' if $final;
            $final = {point => 'aggregate_admission_guard', %$observation};
        }
        return $aggregate->(@_);
    };
    local *FSM::Support::ISFRecordPortContexts::_require = sub {
        if (!$_[0] && defined($_[1]) && $_[1] =~ /record output field writes are not yet admitted/) {
            die 'duplicate failed record checkpoint' if $final;
            $final = {point => 'record_context_guard', %{checkpoint([$facade, $ast, $actor])}};
        }
        return $require->(@_);
    };
    my $install;
    $install = sub {
        my ($index) = @_;
        if ($index == @{$request->{passes}}) {
            my $accepted = eval { $facade->parse_source($request->{sources}[$position], 'still-refused.isf'); 1 };
            my $error = $@;
            die 'expected original source refusal' if $accepted || !length($error);
            die 'complete refusal checkpoint required' unless $final;
            push @cases, {parse_index => $position + 2, source => $request->{sources}[$position],
                primary => (split(/\n/, $error))[0], events => \@events,
                type_checks => \@type_checks, final => $final};
            return;
        }
        my $name = $request->{passes}[$index];
        die 'own top-level pass identifier required' unless $name =~ /\A_(?:expand|finalize|validate)_[a-z_]+\z/;
        my $operation = FSM::Adapter::ISF::Parser->can($name);
        die "missing own pass $name" unless $operation;
        no strict 'refs';
        local *{"FSM::Adapter::ISF::Parser::$name"} = sub {
            $actor = $_[1];
            my $old = $actor->{transactions}[0]{clauses};
            push @events, {pass => $name, boundary => 'entry', %{checkpoint([$facade, $ast, $actor])}};
            my $result = $operation->(@_);
            push @events, {pass => $name, boundary => 'return',
                %{checkpoint([$facade, $ast, $actor, $old, $actor->{transactions}[0]{clauses}])}};
            return $result;
        };
        return $install->($index + 1);
    };
    $install->(0);
    undef $install; # Release the observer's recursive installation closure.
}
my @own_modules = sort grep { m{\Aperl/FSM/.*\.pm\z} } values %INC;
print $json->encode({cases => \@cases, own_loaded_modules => \@own_modules,
    scope => 'Fresh own-source construction checkpoints. Only the primary refusal line is emitted; original native identity/payload/flags and stack capture remain unmeasured. Observer retention of old clauses is not an original source holder.'}), "\n";
