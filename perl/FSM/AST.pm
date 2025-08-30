package FSM::AST;

use v5.20;
use strict;
use warnings;
use feature qw(signatures postderef);
no warnings qw(experimental::signatures experimental::postderef);

use Carp;
use Exporter 'import';

our $VERSION = '2.0';

# Base Node class for all AST elements
package FSM::AST::Node;
use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings qw(experimental::signatures);
use Carp;

sub new($class, %args) {
    my $self = {
        type => $args{type} // 'node',
        name => $args{name} // '',
        attributes => $args{attributes} // {},
        children => $args{children} // [],
    };
    return bless $self, $class;
}

sub type($self) { return $self->{type} }
sub name($self) { return $self->{name} }
sub attributes($self) { return $self->{attributes} }
sub children($self) { return $self->{children} }

sub add_child($self, $child) {
    push $self->{children}->@*, $child;
}

sub get_attribute($self, $key) {
    return $self->{attributes}{$key};
}

sub set_attribute($self, $key, $value) {
    $self->{attributes}{$key} = $value;
}

# Module represents a complete FSM module
package FSM::AST::Module;
use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings qw(experimental::signatures);
use Carp;
our @ISA = qw(FSM::AST::Node);

sub new($class, %args) {
    my $self = $class->SUPER::new(
        type => 'module',
        name => $args{name} // 'unnamed_fsm',
        %args
    );
    
    $self->{ports} = $args{ports} // [];
    $self->{signals} = $args{signals} // [];
    $self->{states} = $args{states} // [];
    $self->{system} = $args{system} // {};
    $self->{generics} = $args{generics} // {};
    
    return $self;
}

sub ports($self) { return $self->{ports} }
sub signals($self) { return $self->{signals} }
sub states($self) { return $self->{states} }
sub system($self) { return $self->{system} }
sub generics($self) { return $self->{generics} }

sub add_port($self, $port) {
    push $self->{ports}->@*, $port;
}

sub add_signal($self, $signal) {
    push $self->{signals}->@*, $signal;
}

sub add_state($self, $state) {
    push $self->{states}->@*, $state;
}

# Port represents input/output ports
package FSM::AST::Port;
use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings qw(experimental::signatures);
use Carp;
our @ISA = qw(FSM::AST::Node);

sub new($class, %args) {
    my $self = $class->SUPER::new(
        type => 'port',
        name => $args{name} // croak("Port name required"),
        %args
    );
    
    $self->{direction} = $args{direction} // 'in';
    $self->{width} = $args{width} // 1;
    $self->{port_type} = $args{port_type} // 'std_logic';
    
    return $self;
}

sub direction($self) { return $self->{direction} }
sub width($self) { return $self->{width} }
sub port_type($self) { return $self->{port_type} }

sub is_input($self) { return $self->{direction} eq 'in' }
sub is_output($self) { return $self->{direction} eq 'out' }
sub is_vector($self) { return $self->{width} > 1 }

# Signal represents internal signals
package FSM::AST::Signal;
use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings qw(experimental::signatures);
use Carp;
our @ISA = qw(FSM::AST::Node);

sub new($class, %args) {
    my $self = $class->SUPER::new(
        type => 'signal',
        name => $args{name} // croak("Signal name required"),
        %args
    );
    
    $self->{width} = $args{width} // 1;
    $self->{signal_type} = $args{signal_type} // 'std_logic';
    $self->{initial_value} = $args{initial_value};
    
    return $self;
}

sub width($self) { return $self->{width} }
sub signal_type($self) { return $self->{signal_type} }
sub initial_value($self) { return $self->{initial_value} }

sub is_vector($self) { return $self->{width} > 1 }

# State represents FSM states
package FSM::AST::State;
use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings qw(experimental::signatures);
use Carp;
our @ISA = qw(FSM::AST::Node);

sub new($class, %args) {
    my $self = $class->SUPER::new(
        type => 'state',
        name => $args{name} // croak("State name required"),
        %args
    );
    
    $self->{assignments} = $args{assignments} // [];
    $self->{transitions} = $args{transitions} // [];
    $self->{is_reset_state} = $args{is_reset_state} // 0;
    
    return $self;
}

sub assignments($self) { return $self->{assignments} }
sub transitions($self) { return $self->{transitions} }
sub is_reset_state($self) { return $self->{is_reset_state} }

sub add_assignment($self, $assignment) {
    push $self->{assignments}->@*, $assignment;
}

sub add_transition($self, $transition) {
    push $self->{transitions}->@*, $transition;
}

# Assignment represents signal assignments within states
package FSM::AST::Assignment;
use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings qw(experimental::signatures);
use Carp;
our @ISA = qw(FSM::AST::Node);

sub new($class, %args) {
    my $self = $class->SUPER::new(
        type => 'assignment',
        %args
    );
    
    $self->{target} = $args{target} // croak("Assignment target required");
    $self->{expression} = $args{expression} // croak("Assignment expression required");
    $self->{condition} = $args{condition};
    $self->{assignment_type} = $args{assignment_type} // 'combinatorial';
    
    return $self;
}

sub target($self) { return $self->{target} }
sub expression($self) { return $self->{expression} }
sub condition($self) { return $self->{condition} }
sub assignment_type($self) { return $self->{assignment_type} }

sub is_conditional($self) { return defined $self->{condition} }

# Transition represents state transitions
package FSM::AST::Transition;
use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings qw(experimental::signatures);
use Carp;
our @ISA = qw(FSM::AST::Node);

sub new($class, %args) {
    my $self = $class->SUPER::new(
        type => 'transition',
        %args
    );
    
    $self->{target_state} = $args{target_state} // croak("Transition target state required");
    $self->{condition} = $args{condition};
    $self->{priority} = $args{priority} // 0;
    
    return $self;
}

sub target_state($self) { return $self->{target_state} }
sub condition($self) { return $self->{condition} }
sub priority($self) { return $self->{priority} }

sub is_conditional($self) { return defined $self->{condition} }

1;
