library ieee;
use ieee.std_logic_1164.all;

package base_output_arbitration_metadata_pkg is
  constant VIAL_PLAN_ID : string := "plan/038c968edbd7782d36f49af5092dd4301ca95989914eeba73250f9b609525574";
  constant VIAL_FIXTURE_ID : string := "ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration";
  constant VIAL_BRIDGE_MANIFEST_ID : string := "bridge/326606e2b4d02515173c4512d65f9ae6ae591bd5ccf0e8414226268234d039b3";
  constant VIAL_UNIT_ID : string := "unit/ahb_lite_subordinate";
  constant VIAL_DOMAIN_ID : string := "domain/ahb_bus";
  constant VIAL_ACTIVE_EDGE : string := "rising";
  constant VIAL_INACTIVE_EDGE : string := "falling";
  constant VIAL_RESET_KIND : string := "async";
  constant VIAL_RESET_POLARITY : string := "active_low";
end package base_output_arbitration_metadata_pkg;
