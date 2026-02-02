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

**Run all tests in the `core` directory:**

```bash
julia --project -e 'using Pkg; Pkg.test("CTBase"; test_args=["suite/core/*"])'
```

**Run specific test files:**

```bash
julia --project -e 'using Pkg; Pkg.test("CTBase"; test_args=["suite/core/test_default", "suite/unicode/test_utils"])'
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

- **File Name:** Must follow the pattern `test_<name>.jl` (e.g., `test_default.jl`).
- **Entry Function:** The file **MUST** contain a function named `test_<name>()` (matching the filename) that serves as the entry point.

**Example (`test/suite/core/test_default.jl`):**

```julia
module TestCore

using Test
using CTBase
using Main.TestOptions # Access shared test options

function test_default()
    @testset "Core Tests" verbose = VERBOSE showtiming = SHOWTIMING begin
        # Your tests here
    end
end

end # module

# CRITICAL: Redefine the function in the outer scope so TestRunner can find it
test_default() = TestCore.test_default()
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
- **Qualification of methods**: always **qualify the method call** even if a method is exported (e.g., `CTBase.ctindice(...)`). This makes it explicit what is being tested and avoids any ambiguity.
- **Verification of exports**: dedicated tests should be added to verify that methods are correctly exported when necessary (e.g., using `isdefined(CTBase, :...)`).

### Directory Structure

All test files are organized under `test/suite/` to maintain orthogonal relationship with the source code structure. Place your test file in the appropriate subdirectory based on functionality:

- `suite/core/`: Core module tests (ctNumber, __display, internal utilities)
- `suite/unicode/`: Unicode module tests (ctindice, ctindices, ctupperscript, ctupperscripts)
- `suite/descriptions/`: Descriptions module tests (add, complete, remove, integration)
- `suite/exceptions/`: Exceptions module tests (exception types, display, configuration)
- `suite/extensions/`: Extensions module tests (TestRunner, DocumenterReference, CoveragePostprocessing)
- `suite/meta/`: Meta tests (Aqua.jl quality checks, code quality)

### Module Testing Pattern

Each test file should follow the modular pattern:

```julia
module Test<ModuleName>

using Test
using CTBase
using Main.TestOptions

# Define all structs and helpers at top-level
struct DummyTag <: CTBase.Extensions.Abstract<Extension>Tag end

function test_<module_name>()
    @testset "<Module Name> Tests" verbose = VERBOSE showtiming = SHOWTIMING begin
        # Test public API
        @test CTBase.<function_name>(args) == expected
        
        # Test internal functions with qualification
        @test CTBase.<SubModule>.<internal_function>(args) == expected
        
        # Test error cases
        @test_throws CTBase.<ExceptionType> CTBase.<function_name>(invalid_args)
    end
end

end # module

# Export to outer scope
test_<module_name>() = Test<ModuleName>.test_<module_name>()
```

## 5. Test Organization Principles

### Orthogonal Structure

The test structure mirrors the source code structure:

```
src/
├── Core/Core.jl              → test/suite/core/test_default.jl
├── Unicode/Unicode.jl        → test/suite/unicode/test_utils.jl
├── Descriptions/Descriptions.jl → test/suite/descriptions/test_description.jl
├── Extensions/Extensions.jl  → test/suite/extensions/test_*.jl
└── Exceptions/               → test/suite/exceptions/test_*.jl
```

### Internal vs Public API Testing

- **Public API**: Test functions accessible via `CTBase.f`
- **Internal Functions**: Test via qualification `CTBase.SubModule.f`
- **Extension Tags**: Test via qualification `CTBase.Extensions.TagType`

This ensures tests validate both the user-facing API and internal implementation details.
