# How to Generate RTL File from FSM

## Generator Script Location
**Script:** `generate_fsm_hdl.pl`  
**Location:** `/Users/richarddje/Downloads/AFX/fsm/afx/cursor/fx/perl/`

## Current Test FSM File
**FSM File:** `lte_dif_pmaster.fsm`  
**Location:** `/Users/richarddje/Downloads/AFX/fsm/afx/cursor/fx/fsm/`

## Basic Command to Generate RTL

### Standard Generation (SystemVerilog)
```bash
cd /Users/richarddje/Downloads/AFX/fsm/afx/cursor/fx/perl
perl generate_fsm_hdl.pl /Users/richarddje/Downloads/AFX/fsm/afx/cursor/fx/fsm/lte_dif_pmaster.fsm -o lte_dif_pmaster.sv
```

### With Debug Mode
```bash
cd /Users/richarddje/Downloads/AFX/fsm/afx/cursor/fx/perl
perl generate_fsm_hdl.pl --debug /Users/richarddje/Downloads/AFX/fsm/afx/cursor/fx/fsm/lte_dif_pmaster.fsm -o lte_dif_pmaster.sv
```

## Full Usage Information

```
FSM HDL Generator - Generate HDL code (SystemVerilog, Verilog, VHDL) from FSM specifications

Usage: perl generate_fsm_hdl.pl [OPTIONS] <fsm_file>

Arguments:
  fsm_file        Path to the .fsm file to process (required)

Options:
  -d, --debug     Enable full debug mode (default: disabled)
  -q, --quiet     Suppress informational messages
  -l, --language  Target HDL language: systemverilog|sv|verilog|v|vhdl (default: systemverilog)
  -o, --output    Specify output file (default: <fsm_name>_generated.<ext>)
  -h, --help      Show this help message

Supported Languages:
  - SystemVerilog (systemverilog, sv) - generates .sv files
  - Verilog       (verilog, v)        - generates .v files  
  - VHDL          (vhdl)              - generates .vhd files

Examples:
  # Generate SystemVerilog RTL from FSM file
  perl generate_fsm_hdl.pl my_fsm.fsm
  
  # Generate Verilog RTL with debug tracing
  perl generate_fsm_hdl.pl --language verilog --debug lte_dif_pmaster.fsm
  
  # Generate VHDL RTL quietly to specific file
  perl generate_fsm_hdl.pl --language vhdl --quiet --output my_output.vhd my_fsm.fsm
  
  # Debug SystemVerilog with custom output
  perl generate_fsm_hdl.pl -l sv -d -o debug_output.sv my_fsm.fsm
```

## Output Files
- **Generated RTL:** `lte_dif_pmaster.sv` (in the perl directory)
- **Generated with fixed pwdata assignments after the bug fix**

## Quick Copy-Paste Commands

**Generate RTL:**
```bash
cd /Users/richarddje/Downloads/AFX/fsm/afx/cursor/fx/perl && perl generate_fsm_hdl.pl /Users/richarddje/Downloads/AFX/fsm/afx/cursor/fx/fsm/lte_dif_pmaster.fsm -o lte_dif_pmaster.sv
```

**Generate RTL with Debug:**
```bash
cd /Users/richarddje/Downloads/AFX/fsm/afx/cursor/fx/perl && perl generate_fsm_hdl.pl --debug /Users/richarddje/Downloads/AFX/fsm/afx/cursor/fx/fsm/lte_dif_pmaster.fsm -o lte_dif_pmaster.sv
```
