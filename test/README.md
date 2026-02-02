# Testing Guide for CTBase

This directory contains the test suite for `CTBase.jl`. It follows the testing conventions and infrastructure provided by [CTBase.jl](https://github.com/control-toolbox/CTBase.jl).

For detailed guidelines on testing and coverage, please refer to:

- [CTBase Test Coverage Guide](https://control-toolbox.org/CTBase.jl/stable/test-coverage-guide.html)
- [CTBase TestRunner Extension](https://github.com/control-toolbox/CTBase.jl/blob/main/ext/TestRunner.jl)
- [CTBase CoveragePostprocessing](https://github.com/control-toolbox/CTBase.jl/blob/main/ext/CoveragePostprocessing.jl)

---

## 1. Running Tests

Tests are executed using the standard Julia Test interface, enhanced by `CTBase.TestRunner`.

### Default Run (All Enabled Tests)

Runs all tests enabled by default in `test/runtests.jl`.

```bash
julia --project -e 'using Pkg; Pkg.test("CTBase")'
```

### Running Specific Test Groups

You can run specific test files or groups using the `test_args` argument. The argument supports glob-style patterns.

**Run all tests in the `ocp` directory:**

```bash
julia --project -e 'using Pkg; Pkg.test("CTBase"; test_args=["suite/ocp/*"])'
```

**Run specific test files:**

```bash
julia --project -e 'using Pkg; Pkg.test("CTBase"; test_args=["suite/ocp/test_constraints", "suite/ocp/test_dynamics"])'
```

### Running All Tests (Including Optional/Long Tests)

To run absolutely every test available (including those potentially marked as optional or skipped by default):

```bash
julia --project -e 'using Pkg; Pkg.test("CTBase"; test_args=["-a"])'
```

## 2. Coverage

To generate a coverage report, you must run the tests with `coverage=true` and then execute the coverage post-processing script.

**Command:**

```bash
julia --project=@. -e 'using Pkg; Pkg.test("CTBase"; coverage=true); include("test/coverage.jl")'
```

**Outputs:**

- `coverage/lcov.info`: LCOV format file (useful for CI integration like Codecov).
- `coverage/cov_report.md`: Human-readable summary of coverage gaps.
- `coverage/cov/`: detailed `.cov` files.

## 3. Adding New Tests

### File and Function Naming

- **File Name:** Must follow the pattern `test_<name>.jl` (e.g., `test_dynamics.jl`).
- **Entry Function:** The file **MUST** contain a function named `test_<name>()` (matching the filename) that serves as the entry point.

**Example (`test/suite/ocp/test_dynamics.jl`):**

```julia
module TestDynamics # namespace isolation

using Test
using CTBase
using Main.TestProblems # Access shared test helpers

# Define structs at top-level (crucial!)
struct MyDummyModel end

function test_dynamics()
    @testset "Dynamics Tests" begin
        # Your tests here
    end
end

end # module

# CRITICAL: Redefine the function in the outer scope so TestRunner can find it
test_dynamics() = TestDynamics.test_dynamics()
```

### Registering the Test

All test files in `test/suite/*/` are automatically discovered by the pattern `"suite/*/test_*"` in `test/runtests.jl`. Simply place your test file in the appropriate subdirectory under `test/suite/`.

## 4. Best Practices & Rules

### ⚠️ Crucial: Struct Definitions

**NEVER define `struct`s inside the test function.**
All helper methods, mocks, and structs must be defined at the **top-level** of the file (or module). Defining structs inside the function causes world-age issues and invalidates precompilation.

### Test Structure

- **Unit vs. Integration:** Clearly separate unit tests (testing single functions/components in isolation) from integration tests (testing the interaction between components).
- **Mocks and Fakes:** Use mock objects or fake implementations to isolate the code under test.
- **Qualification of methods**: always **qualify the method call** even if a method is exported (e.g., `CTBase.solve(...)`). This makes it explicit what is being tested and avoids any ambiguity.
- **Verification of exports**: dedicated tests should be added to verify that methods are correctly exported when necessary (e.g., using `isdefined(CTBase, :...)`).

### Directory Structure

All test files are organized under `test/suite/`. Place your test file in the appropriate subdirectory based on functionality:

- `suite/docp/`: DOCP (Discretized Optimal Control Problem) module tests
- `suite/init/`: Initial guess and initialization tests
- `suite/integration/`: End-to-end integration tests
- `suite/io/`: Import/Export functionality tests
- `suite/meta/`: Meta tests (Aqua.jl quality checks, etc.)
- `suite/modelers/`: Modelers (ADNLPModeler, ExaModeler) tests
- `suite/ocp/`: Optimal Control Problem definitions and components
- `suite/optimization/`: Optimization module (builders, contracts, etc.)
- `suite/options/`: Options system tests
- `suite/orchestration/`: Orchestration layer tests
- `suite/plot/`: Plotting functionality tests
- `suite/strategies/`: Strategies framework tests
- `suite/types/`: Core type definitions tests
- `suite/utils/`: Utility functions tests
