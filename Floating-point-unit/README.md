# Floating Point Unit (FPU)

A 32-bit IEEE 754 single-precision floating-point arithmetic unit implemented in Verilog, supporting addition and subtraction operations with configurable rounding modes.

## Architecture Overview

The FPU is designed as a 4-stage pipelined processor:

1. **Stage 0-1**: Input capture and subnormal detection
2. **Stage 1-2**: Prenormalization and exponent alignment
3. **Stage 2-3**: Arithmetic operations (addition/subtraction)
4. **Stage 3-4**: Postnormalization and output formatting

## Module Structure

```
FPU (top-level)
├── subnormal_detection.v (2 instances)
├── prenormalization.v
└── postnormalization.v
```

## Features

### Supported Operations
- **Addition**: IEEE 754 single-precision floating-point addition
- **Subtraction**: IEEE 754 single-precision floating-point subtraction
- **Input format**: 32-bit IEEE 754 single-precision (1 sign + 8 exponent + 23 mantissa)

### Rounding Modes
- `00`: Round to nearest even
- `01`: Round towards zero (truncation)
- `10`: Round towards positive infinity
- `11`: Round towards negative infinity

### Special Case Handling
- Zero operands
- Subnormal number detection and processing
- Sign bit handling for all operation combinations

## Interface

### Inputs
- `FP_in1[31:0]`: First floating-point operand
- `FP_in2[31:0]`: Second floating-point operand  
- `calc_mode`: Operation selector (0 = addition, 1 = subtraction)
- `round_mode[1:0]`: Rounding mode selection
- `clk`: Clock signal
- `reset`: Reset signal

### Outputs
- `FP_result[31:0]`: 32-bit IEEE 754 result
- `res1`, `res2`: Status outputs (purpose unclear)
- `optype[2:0]`: Operation type indicator

## Implementation Analysis

### Strengths
- Modular design with clear separation of concerns
- Pipelined architecture for improved throughput
- Handles multiple special cases (zero, subnormal numbers)
- Supports all standard IEEE 754 rounding modes
- Comprehensive sign bit logic for addition/subtraction combinations

### Issues and Limitations

#### Critical Problems
1. **Undefined signals**: The main FPU module references `S_01_FP_in1` and `S_01_FP_in2` in the prenormalization instantiation, but these signals are not defined at that point in the pipeline
2. **Clock dependency in subnormal detection**: The `subnormal_detection` module expects a clock input, but it's not provided in the instantiation
3. **Inconsistent bit widths**: Some operations mix 24-bit and 25-bit arithmetic without clear justification
4. **Missing reset logic**: The reset input is declared but never used

#### Design Concerns
1. **Postnormalization complexity**: The shift amount calculation uses a priority encoder that could be simplified
2. **Rounding implementation**: The rounding logic appears incomplete and may not fully comply with IEEE 754 standards
3. **Pipeline hazards**: No apparent handling of data dependencies between pipeline stages
4. **Unused outputs**: `res1` and `res2` outputs are declared but never assigned meaningful values

#### Code Quality Issues
1. **Commented code**: Large sections of code are commented out without explanation
2. **Inconsistent naming**: Mix of different naming conventions throughout
3. **Magic numbers**: Hard-coded bit widths and shift amounts without clear documentation
4. **Missing edge cases**: No apparent handling for infinity, NaN, or overflow conditions

## Testing Recommendations

To validate this implementation, comprehensive testing should include:

1. **Basic arithmetic**: Simple addition/subtraction cases
2. **Edge cases**: Zero operands, very small/large numbers, equal magnitude operands
3. **Rounding verification**: Test all rounding modes with appropriate test vectors
4. **Subnormal handling**: Verify correct processing of denormalized numbers
5. **Pipeline testing**: Multi-cycle operations to verify pipeline integrity
6. **IEEE 754 compliance**: Comparison against reference implementation

## Usage Notes

⚠️ **Warning**: This implementation contains several bugs and incomplete features that would prevent it from working correctly as-is. Significant debugging and completion work is required before use in any production environment.

## Required Fixes

1. Fix signal naming and pipeline stage connectivity
2. Add clock input to subnormal detection modules
3. Implement proper reset functionality
4. Complete rounding mode implementations
5. Add overflow/underflow handling
6. Verify IEEE 754 compliance for all operations
7. Add comprehensive error checking and special case handling

## File Structure
```
Floating-point-unit/
├── FPU.v                    # Top-level FPU module
├── prenormalization.v       # Input alignment and preprocessing
├── postnormalization.v      # Output formatting and rounding
└── subnormal_detection.v    # Subnormal number detection
```

---

*This implementation appears to be a work-in-progress or educational project rather than a production-ready floating-point unit. Use with caution and expect significant debugging effort.*
