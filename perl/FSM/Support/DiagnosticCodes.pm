package FSM::Support::DiagnosticCodes;

use strict;
use warnings;

use Exporter 'import';

our @EXPORT_OK = qw(
    diagnostic_code_ids
    diagnostic_code_metadata
    diagnostic_code_registry
    known_diagnostic_code
);

my %DIAGNOSTIC_CODES = (
    FSMGEN_STRICT_LEGACY_FSM_ROOT => {
        severity => 'error',
        stability => 'stable',
        family => 'strict_mode',
        summary => 'Strict mode rejected a legacy +fsm root.',
    },
    FSMGEN_STRICT_EMPTY_SIZE_SECTION => {
        severity => 'error',
        stability => 'stable',
        family => 'strict_mode',
        summary => 'Strict mode rejected an empty legacy +size section.',
    },
    FSMGEN_STRICT_MISLEADING_ARESET_RSTN => {
        severity => 'error',
        stability => 'stable',
        family => 'strict_mode',
        summary => 'Strict mode rejected misleading asynchronous reset spelling.',
    },
    FSMGEN_STRICT_MISLEADING_SRESET_RSTN => {
        severity => 'error',
        stability => 'stable',
        family => 'strict_mode',
        summary => 'Strict mode rejected misleading synchronous reset spelling.',
    },
    FSMGEN_STRICT_COMPACT_INIT_DIRECTIVE => {
        severity => 'error',
        stability => 'stable',
        family => 'strict_mode',
        summary => 'Strict mode rejected compact init/default assignment syntax.',
    },
    FSMGEN_STRICT_INFIX_ASSIGNMENT => {
        severity => 'error',
        stability => 'stable',
        family => 'strict_mode',
        summary => 'Strict mode rejected legacy infix assignment syntax.',
    },
    FSMGEN_STRICT_LEGACY_LTEPLUS_ASSIGNMENT => {
        severity => 'error',
        stability => 'stable',
        family => 'strict_mode',
        summary => 'Strict mode rejected the legacy <=+ assignment alias.',
    },
    FSMGEN_STRICT_FSMC_LEGACY_ROOT => {
        severity => 'error',
        stability => 'stable',
        family => 'strict_mode',
        summary => 'Strict mode rejected a legacy +fsm child source under ?fsmc.',
    },
    FSMGEN_STRICT_DTC_CHILD_ROOT => {
        severity => 'error',
        stability => 'stable',
        family => 'strict_mode',
        summary => 'Strict mode rejected an incompatible child source under ?dtc.',
    },
    FSMGEN_LANGUAGE_BAD_SIZE_ENTRY => {
        severity => 'error',
        stability => 'stable',
        family => 'language_contract',
        summary => 'A +size entry did not match the supported shape.',
    },
    FSMGEN_LANGUAGE_NON_POSITIVE_SIZE => {
        severity => 'error',
        stability => 'stable',
        family => 'language_contract',
        summary => 'A width expression resolved to a non-positive integer.',
    },
    FSMGEN_LANGUAGE_UNKNOWN_SIZE_SYMBOL => {
        severity => 'error',
        stability => 'stable',
        family => 'language_contract',
        summary => 'A width expression referenced an unknown scalar symbol.',
    },
    FSMGEN_LANGUAGE_AGGREGATE_SIZE_SYMBOL => {
        severity => 'error',
        stability => 'stable',
        family => 'language_contract',
        summary => 'A width expression referenced an aggregate where a scalar was required.',
    },
    FSMGEN_LANGUAGE_SIZE_DIVIDE_BY_ZERO => {
        severity => 'error',
        stability => 'stable',
        family => 'language_contract',
        summary => 'A width expression attempted integer division by zero.',
    },
    FSMGEN_LANGUAGE_SIZE_MODULO_BY_ZERO => {
        severity => 'error',
        stability => 'stable',
        family => 'language_contract',
        summary => 'A width expression attempted integer modulo by zero.',
    },
    FSMGEN_LANGUAGE_UNSUPPORTED_SIZE_OPERATOR => {
        severity => 'error',
        stability => 'stable',
        family => 'language_contract',
        summary => 'A width expression used an unsupported operator.',
    },
    FSMGEN_LANGUAGE_SIZE_OPERATOR_ARITY => {
        severity => 'error',
        stability => 'stable',
        family => 'language_contract',
        summary => 'A width expression operator received an unsupported operand count.',
    },
    FSMGEN_LANGUAGE_LHS_DECONSTRUCT_WIDTH => {
        severity => 'error',
        stability => 'stable',
        family => 'language_contract',
        summary => 'A deconstructing LHS did not match the RHS width.',
    },
    FSMGEN_LANGUAGE_UNSUPPORTED_TOP_LEVEL_SOURCE => {
        severity => 'error',
        stability => 'stable',
        family => 'language_contract',
        summary => 'A top-level source root is outside the active source contract.',
    },
    FSMGEN_LANGUAGE_UNSUPPORTED_TOP_LEVEL_DIRECTIVE => {
        severity => 'error',
        stability => 'stable',
        family => 'language_contract',
        summary => 'A top-level directive is outside the active source contract.',
    },
    FSMGEN_LANGUAGE_GENERIC_PLACEHOLDER_SELECTOR => {
        severity => 'error',
        stability => 'stable',
        family => 'language_contract',
        summary => 'A legacy generic/template placeholder selector is unsupported.',
    },
    FSMGEN_LANGUAGE_GENERIC_REPEAT_ACTION => {
        severity => 'error',
        stability => 'stable',
        family => 'language_contract',
        summary => 'A legacy generic/template repeat action is unsupported.',
    },
    FSMGEN_LANGUAGE_GENERIC_PLACEHOLDER_TOKEN => {
        severity => 'error',
        stability => 'stable',
        family => 'language_contract',
        summary => 'A legacy generic/template placeholder token is unsupported.',
    },
    FSMGEN_LANGUAGE_BARE_CONDITION_SUFFIX => {
        severity => 'error',
        stability => 'stable',
        family => 'language_contract',
        summary => 'A bare condition suffix was used where an explicit guard is required.',
    },
    FSMGEN_LANGUAGE_MALFORMED_SOURCE_ROOT => {
        severity => 'error',
        stability => 'stable',
        family => 'language_contract',
        summary => 'A top-level source root did not match the supported source shape.',
    },
    FSMGEN_LANGUAGE_UNSUPPORTED_ACTION_FORM => {
        severity => 'error',
        stability => 'stable',
        family => 'language_contract',
        summary => 'An action form did not match any supported action shape.',
    },
    FSMGEN_LANGUAGE_MALFORMED_GUARDED_BLOCK => {
        severity => 'error',
        stability => 'stable',
        family => 'language_contract',
        summary => 'A guarded block omitted its required body.',
    },
    FSMGEN_LANGUAGE_MALFORMED_TEST_BRANCH => {
        severity => 'error',
        stability => 'stable',
        family => 'language_contract',
        summary => 'A test branch omitted its required body.',
    },
    FSMGEN_LANGUAGE_MALFORMED_TEST_SELECTOR => {
        severity => 'error',
        stability => 'stable',
        family => 'language_contract',
        summary => 'A test selector used an unsupported bare selector shape.',
    },
    FSMGEN_LANGUAGE_INCOMPLETE_SYSTEM_SECTION => {
        severity => 'error',
        stability => 'stable',
        family => 'language_contract',
        summary => 'A +system section omitted required clock or reset metadata.',
    },
    FSMGEN_LANGUAGE_DUPLICATE_SYSTEM_ENTRY => {
        severity => 'error',
        stability => 'stable',
        family => 'language_contract',
        summary => 'A +system section repeated a singleton system entry.',
    },
    FSMGEN_LANGUAGE_DUPLICATE_SYSTEM_RESET => {
        severity => 'error',
        stability => 'stable',
        family => 'language_contract',
        summary => 'A +system section declared more than one reset policy.',
    },
    FSMGEN_LANGUAGE_MALFORMED_SYSTEM_ENTRY => {
        severity => 'error',
        stability => 'stable',
        family => 'language_contract',
        summary => 'A +system section entry did not match the supported shape.',
    },
    FSMGEN_LANGUAGE_BAD_SYSTEM_CLOCK_NAME => {
        severity => 'error',
        stability => 'stable',
        family => 'language_contract',
        summary => 'A +system clock identifier was malformed.',
    },
    FSMGEN_LANGUAGE_BAD_SYSTEM_RESET_NAME => {
        severity => 'error',
        stability => 'stable',
        family => 'language_contract',
        summary => 'A +system reset identifier was malformed.',
    },
    FSMGEN_LANGUAGE_MALFORMED_FSM_SOURCE_NAME => {
        severity => 'error',
        stability => 'stable',
        family => 'language_contract',
        summary => 'A top-level FSM source name was malformed.',
    },
    FSMGEN_LANGUAGE_MALFORMED_FSM_ROOT_BODY => {
        severity => 'error',
        stability => 'stable',
        family => 'language_contract',
        summary => 'A structured ?fsm root had no valid body.',
    },
    FSMGEN_LANGUAGE_MALFORMED_FSM_ROOT_BODY_ITEM => {
        severity => 'error',
        stability => 'stable',
        family => 'language_contract',
        summary => 'A structured ?fsm root had a malformed top-level body item.',
    },
    FSMGEN_LANGUAGE_MALFORMED_TOP_SOURCE_NAME => {
        severity => 'error',
        stability => 'stable',
        family => 'language_contract',
        summary => 'A composition top source name was malformed.',
    },
    FSMGEN_LANGUAGE_MALFORMED_STATE_NAME => {
        severity => 'error',
        stability => 'stable',
        family => 'language_contract',
        summary => 'A state or standalone-DT name was malformed.',
    },
    FSMGEN_LANGUAGE_MALFORMED_STATE_DT_BLOCK => {
        severity => 'error',
        stability => 'stable',
        family => 'language_contract',
        summary => 'A state or standalone-DT block had no valid body.',
    },
    FSMGEN_LANGUAGE_MALFORMED_TRANSITION_TARGET => {
        severity => 'error',
        stability => 'stable',
        family => 'language_contract',
        summary => 'A transition target name was malformed.',
    },
    FSMGEN_LANGUAGE_UNKNOWN_TRANSITION_TARGET => {
        severity => 'error',
        stability => 'stable',
        family => 'language_contract',
        summary => 'A transition target referenced no declared state.',
    },
    FSMGEN_LANGUAGE_UNSUPPORTED_RHS_EXPRESSION_OPERATOR => {
        severity => 'error',
        stability => 'stable',
        family => 'language_contract',
        summary => 'An RHS expression used an unsupported operator.',
    },
    FSMGEN_LANGUAGE_MALFORMED_RHS_EXPRESSION_ARITY => {
        severity => 'error',
        stability => 'stable',
        family => 'language_contract',
        summary => 'An RHS expression operator used an unsupported operand count.',
    },
    FSMGEN_LANGUAGE_UNSUPPORTED_RHS_EXPRESSION_TOKEN => {
        severity => 'error',
        stability => 'stable',
        family => 'language_contract',
        summary => 'An RHS expression used a token that is not valid in value position.',
    },
    FSMGEN_LANGUAGE_MALFORMED_GUARD_CONDITION_PAYLOAD => {
        severity => 'error',
        stability => 'stable',
        family => 'language_contract',
        summary => 'A guard shorthand condition payload was malformed.',
    },
    FSMGEN_LANGUAGE_MALFORMED_INLINE_COMPARISON_EXPRESSION => {
        severity => 'error',
        stability => 'stable',
        family => 'language_contract',
        summary => 'An inline comparison expression token was malformed.',
    },
    FSMGEN_LANGUAGE_DELAYED_PULSE_RHS => {
        severity => 'error',
        stability => 'stable',
        family => 'language_contract',
        summary => 'A delayed-pulse assignment used an unsupported RHS value.',
    },
    FSMGEN_LANGUAGE_MIXED_ASSIGNMENT_FAMILIES => {
        severity => 'error',
        stability => 'stable',
        family => 'language_contract',
        summary => 'A signal mixed combinational and sequential assignment families.',
    },
    FSMGEN_LANGUAGE_MIXED_PULSE_ASSIGNMENT_FAMILY => {
        severity => 'error',
        stability => 'stable',
        family => 'language_contract',
        summary => 'A signal mixed pulse-delayed and non-pulse sequential assignment families.',
    },
    FSMGEN_LANGUAGE_MULTIPLE_PULSE_DELAYS => {
        severity => 'error',
        stability => 'stable',
        family => 'language_contract',
        summary => 'A signal used more than one delayed-pulse latency.',
    },
    FSMGEN_LANGUAGE_COMBINATIONAL_SELF_DEPENDENCY => {
        severity => 'error',
        stability => 'stable',
        family => 'language_contract',
        summary => 'A combinational assignment depended on its own LHS value.',
    },
    FSMGEN_LANGUAGE_D_INPUT_SELF_DEPENDENCY => {
        severity => 'error',
        stability => 'stable',
        family => 'language_contract',
        summary => 'A D-input assignment depended on its own D-input LHS value.',
    },
    FSMGEN_LANGUAGE_UNSUPPORTED_ASSIGNMENT_OPERATOR => {
        severity => 'error',
        stability => 'stable',
        family => 'language_contract',
        summary => 'An assignment used an unsupported operator.',
    },
    FSMGEN_LANGUAGE_UNSUPPORTED_INIT_RESET_VALUE => {
        severity => 'error',
        stability => 'stable',
        family => 'language_contract',
        summary => 'An init directive used an unsupported reset value.',
    },
    FSMGEN_LANGUAGE_MALFORMED_INIT_DIRECTIVE_PAYLOAD => {
        severity => 'error',
        stability => 'stable',
        family => 'language_contract',
        summary => 'An init directive payload did not match the supported shape.',
    },
    FSMGEN_LANGUAGE_UNSUPPORTED_INIT_DIRECTIVE => {
        severity => 'error',
        stability => 'stable',
        family => 'language_contract',
        summary => 'A compact init directive did not match the supported signal=value form.',
    },
    FSMGEN_LANGUAGE_EMPTY_CONSTANTS_SECTION => {
        severity => 'error',
        stability => 'stable',
        family => 'language_contract',
        summary => 'A +constants section had no entries.',
    },
    FSMGEN_LANGUAGE_EMPTY_DEFINE_DIRECTIVE => {
        severity => 'error',
        stability => 'stable',
        family => 'language_contract',
        summary => 'A +define directive had no entries.',
    },
    FSMGEN_LANGUAGE_EMPTY_PARAMS_SECTION => {
        severity => 'error',
        stability => 'stable',
        family => 'language_contract',
        summary => 'A +params section had no entries.',
    },
    FSMGEN_LANGUAGE_EMPTY_ENUMS_SECTION => {
        severity => 'error',
        stability => 'stable',
        family => 'language_contract',
        summary => 'A +enums section had no entries.',
    },
    FSMGEN_LANGUAGE_MALFORMED_CONSTANTS_ENTRY => {
        severity => 'error',
        stability => 'stable',
        family => 'language_contract',
        summary => 'A +constants entry did not match the supported shape.',
    },
    FSMGEN_LANGUAGE_MALFORMED_DEFINE_ENTRY => {
        severity => 'error',
        stability => 'stable',
        family => 'language_contract',
        summary => 'A +define entry did not match the supported shape.',
    },
    FSMGEN_LANGUAGE_MALFORMED_PARAMS_ENTRY => {
        severity => 'error',
        stability => 'stable',
        family => 'language_contract',
        summary => 'A +params entry did not match the supported shape.',
    },
    FSMGEN_LANGUAGE_MALFORMED_ENUMS_MEMBER => {
        severity => 'error',
        stability => 'stable',
        family => 'language_contract',
        summary => 'A +enums member did not match the supported shape.',
    },
    FSMGEN_LANGUAGE_MALFORMED_TEST_SIGNAL => {
        severity => 'error',
        stability => 'stable',
        family => 'language_contract',
        summary => 'A plain test node used a malformed signal name.',
    },
    FSMGEN_LANGUAGE_MALFORMED_COMPUTED_TEST_SELECTOR => {
        severity => 'error',
        stability => 'stable',
        family => 'language_contract',
        summary => 'A computed test selector omitted its expression or branches.',
    },
    FSMGEN_LANGUAGE_MALFORMED_INLINE_MODIFIER => {
        severity => 'error',
        stability => 'stable',
        family => 'language_contract',
        summary => 'An inline compound modifier used an unsupported payload shape.',
    },
    FSMGEN_LANGUAGE_DUPLICATE_INLINE_MODIFIER => {
        severity => 'error',
        stability => 'stable',
        family => 'language_contract',
        summary => 'An assignment used more than one inline compound modifier.',
    },
    FSMGEN_LANGUAGE_MALFORMED_UPDATE_SHORTHAND_TARGET => {
        severity => 'error',
        stability => 'stable',
        family => 'language_contract',
        summary => 'An update shorthand used a malformed target.',
    },
    FSMGEN_LANGUAGE_MALFORMED_UPDATE_SHORTHAND_TAIL => {
        severity => 'error',
        stability => 'stable',
        family => 'language_contract',
        summary => 'An update shorthand used unsupported positional tail tokens.',
    },
    FSMGEN_DIRECT_RHS_WIDTH_MISMATCH => {
        severity => 'error',
        stability => 'stable',
        family => 'direct_generation_contract',
        summary => 'A direct assignment RHS width was incompatible with the LHS width.',
    },
    FSMGEN_DIRECT_AGGREGATE_CONTRACT_MISMATCH => {
        severity => 'error',
        stability => 'stable',
        family => 'direct_generation_contract',
        summary => 'A direct aggregate assignment used an incompatible source contract.',
    },
    FSMGEN_COMPOSITION_MISSING_RTLIF => {
        severity => 'error',
        stability => 'stable',
        family => 'composition_contract',
        summary => 'An external RTL child was missing its interface metadata.',
    },
    FSMGEN_COMPOSITION_MISSING_FSM_CHILD => {
        severity => 'error',
        stability => 'stable',
        family => 'composition_contract',
        summary => 'A generated FSM child source could not be resolved.',
    },
    FSMGEN_COMPOSITION_MISSING_DT_CHILD => {
        severity => 'error',
        stability => 'stable',
        family => 'composition_contract',
        summary => 'A generated DT child source could not be resolved.',
    },
    FSMGEN_RTLIF_SYSTEM_PORT_DIRECTION => {
        severity => 'error',
        stability => 'stable',
        family => 'composition_contract',
        summary => 'RTL interface metadata declared a system port with an invalid direction.',
    },
    FSMGEN_RTLIF_DUPLICATE_PORT => {
        severity => 'error',
        stability => 'stable',
        family => 'composition_contract',
        summary => 'RTL interface metadata repeated a port declaration.',
    },
    FSMGEN_RTLIF_UNSUPPORTED_PORT_TYPE => {
        severity => 'error',
        stability => 'stable',
        family => 'composition_contract',
        summary => 'RTL interface metadata used an unsupported port type.',
    },
    FSMGEN_RTLIF_INVALID_PORT_TOKEN => {
        severity => 'error',
        stability => 'stable',
        family => 'composition_contract',
        summary => 'RTL interface metadata used an invalid port token.',
    },
    FSMGEN_RTLIF_NON_POSITIVE_PORT_WIDTH => {
        severity => 'error',
        stability => 'stable',
        family => 'composition_contract',
        summary => 'RTL interface metadata declared a non-positive port width.',
    },
    FSMGEN_RTLIF_MISSING_ROOT => {
        severity => 'error',
        stability => 'stable',
        family => 'composition_contract',
        summary => 'RTL interface metadata did not contain the required ?rtlif root.',
    },
    FSMGEN_RTLIF_EMPTY_PORTS => {
        severity => 'error',
        stability => 'stable',
        family => 'composition_contract',
        summary => 'RTL interface metadata declared no ports.',
    },
    FSMGEN_RTLIF_NESTED_STRUCTURE => {
        severity => 'error',
        stability => 'stable',
        family => 'composition_contract',
        summary => 'RTL interface metadata contained nested structure where a flat port list was required.',
    },
    FSMGEN_RTLIF_DUPLICATE_EMBEDDED_ROOT => {
        severity => 'error',
        stability => 'stable',
        family => 'composition_contract',
        summary => 'A source declared duplicate embedded RTL interface metadata roots.',
    },
);

sub diagnostic_code_ids {
    my @codes = sort keys %DIAGNOSTIC_CODES;
    return @codes;
}

sub diagnostic_code_registry {
    return {
        map {
            my %copy = %{ $DIAGNOSTIC_CODES{$_} };
            $_ => \%copy;
        } diagnostic_code_ids()
    };
}

sub diagnostic_code_metadata {
    my ($code) = @_;

    return undef unless defined $code && exists $DIAGNOSTIC_CODES{$code};

    my %copy = %{ $DIAGNOSTIC_CODES{$code} };
    return \%copy;
}

sub known_diagnostic_code {
    my ($code) = @_;
    return defined $code && exists $DIAGNOSTIC_CODES{$code};
}

1;
