# Developers Guide

This guide explains how to set up an advanced testing and coverage infrastructure for Julia packages. This setup is designed to be friendly both for human developers and AI agents, enabling granular test execution and feedback-driven development.

## Architecture Overview

A robust testing architecture typically involves:

1. **Test Runner**: A `runtests.jl` file that allows running specific test groups via command-line arguments.
2. **Coverage Post-processing**: A `coverage.jl` script that generates human-readable and machine-parseable coverage reports.
3. **Test Suite Structure**: Modular test files, each containing a main entry point function.
4. **Agent Workflow**: A standardized workflow definition (e.g., for LLM agents) to autonomously run tests and analyze coverage.

### Recommended Directory Structure

We recommend placing your tests in a `suite` subdirectory to keep the top-level `test/` folder clean.

```text
MyPackage.jl/
├── .agent/
│   └── workflows/
│       └── test-julia.md    # Agent workflow definition
├── src/
│   └── ...
├── test/
│   ├── coverage.jl          # Coverage post-processing script
│   ├── runtests.jl          # Main test runner
│   └── suite/               # Directory containing test files
│       ├── test_utils.jl
│       ├── test_core.jl
│       └── ...
└── ...
```

## Setting up `runtests.jl`

The `runtests.jl` file is the entry point for your test suite. By using `CTBase.run_tests`, you enable a powerful mechanism to filter and execute specific tests using command-line arguments. This is crucial for fast iteration cycles.

### Example `test/runtests.jl`

```julia
# ==============================================================================
# MyPackage Test Runner
# ==============================================================================
#
# This test runner uses the CTBase TestRunner extension (triggered by `using Test`)
# to execute tests with configurable file/function name builders and optional
# test selection via command-line arguments.
#
# ## Running Tests
#
# ### Default (all available tests)
#
#   julia --project -e 'using Pkg; Pkg.test("MyPackage")'
#
# ### Run a specific test group
#
#   julia --project -e 'using Pkg; Pkg.test("MyPackage"; test_args=["utils"])'
#   julia --project -e 'using Pkg; Pkg.test("MyPackage"; test_args=["core", "utils"])'
#
# Note: 
# - Passing `-a` or `--all` is equivalent to running without arguments.
# - Passing `--dry-run` will print the list of tests that would be run, but not execute them.
#
# ## Coverage Mode
#
# Run tests with code coverage instrumentation:
#
#   julia --project -e '
#       using Pkg; 
#       Pkg.test("MyPackage"; coverage=true); 
#       include("test/coverage.jl")
#   '
#
# This produces:
#   - coverage/lcov.info      — LCOV format for CI integration
#   - coverage/cov_report.md  — Human-readable summary with uncovered lines
#   - coverage/cov/           — Archived .cov files
#
# ## Test Groups
#
# Each test group corresponds to a file `test/suite/test_<name>.jl` that defines
# a function `test_<name>()`. The `available_tests` list below controls
# which groups are valid; requests for unlisted groups will error.
# ==============================================================================

# Load dependencies
using Test
using CTBase # Provides run_tests
using MyPackage # Your package

# Define where your tests are located
const TEST_DIR = @__DIR__

# Run tests using the CTBase test runner
CTBase.run_tests(;
    args=String.(ARGS),                 # Pass command line arguments
    testset_name="MyPackage Tests",     # Name of the main testset
    available_tests=[                   # List of available test groups/files
        "suite/*"                       # Use glob pattern to include all tests in suite/
    ],
    # Function to map a test name in ARGS (like "utils") to a filename
    filename_builder = name -> "test_$(name).jl",
    # Function to map a test name in ARGS to the function to call inside that file
    funcname_builder = name -> "test_$(name)",
    test_dir=TEST_DIR,                  # Directory containing test files
    verbose=true,                       # Show verbose output
    showtiming=true,                    # Show timing information
)

# If running with coverage enabled, remind the user to run the post-processing script
if Base.JLOptions().code_coverage != 0
    println(
        """
        ================================================================================
        Coverage files generated. To process them, please run:

            julia --project -e '
                using Pkg; 
                Pkg.test("MyPackage"; coverage=true); 
                include("test/coverage.jl")'
            '
        ================================================================================
        """
    )
end
```

## Writing Test Files

To support the modular execution model, each test file should define a function (typically matching the filename) that contains the tests. This avoids scope pollution and makes the tests easy to invoke programmatically.

### Example `test/suite/test_utils.jl`

```julia
# The function name matches the `funcname_builder` logic in runtests.jl
function test_utils()
    @testset "Utilities" begin
        @test MyPackage.add(1, 1) == 2
        @test MyPackage.sub(2, 1) == 1
    end
end
```

## Setting up Coverage

To generate actionable coverage reports, we use a dedicated `coverage.jl` script. This script processes the raw `.cov` files generated by Julia and produces summaries that are easy for an agent to read.

### Example `test/coverage.jl`

```julia
# Add the test directory to the load path so Julia can find dependencies from 
# test/Project.toml. This is necessary because this script is included from the 
# main project context, not from the test project context. Without this, Julia 
# won't find Coverage and other test-only dependencies.
pushfirst!(LOAD_PATH, @__DIR__)

using Pkg
using CTBase # Provides postprocess_coverage
using Coverage

# This function:
# 1. Aggregates coverage data.
# 2. Generates an LCOV file (coverage/lcov.info).
# 3. Generates a markdown summary (coverage/cov_report.md).
# 4. Archives used .cov files to keep the directory clean.
CTBase.postprocess_coverage(; 
    root_dir=dirname(@__DIR__) # Point to the package root
)
```

### Running with Coverage

To run tests and generate the report:

```bash
julia --project -e '
    using Pkg; 
    Pkg.test("MyPackage"; coverage=true); 
    include("test/coverage.jl")
'
```

The resulting `coverage/cov_report.md` will contain a list of files with their coverage percentages and, crucially, a list of uncovered lines. This allows an agent to identify exactly which parts of the code need more tests.

## Agent Workflow Integration

To leverage LLM agents for testing, you can define a workflow that orchestrates these tools. The agent can:

1. Run the full suite or specific tests.
2. Read the coverage report.
3. Write new tests to improve coverage.
4. Repeat.

Create a file at `.agent/workflows/improve-coverage.md` (or similar path) to describe this process.

### Example Workflow Snippet

```markdown
---
description: Test and improve code coverage by analyzing coverage reports and writing targeted tests in Julia
---

# Julia Test & Coverage Workflow

## Context
- **Run all tests**: `julia --project -e 'using Pkg; Pkg.test("MyPackage")'`
- **Run specific test**: `julia --project -e 'using Pkg; Pkg.test("MyPackage"; test_args=["core"])'`
- **Generate Coverage**: `julia --project -e 'using Pkg; Pkg.test("MyPackage"; coverage=true); include("test/coverage.jl")'`

## Workflow Steps

1. **Analyze**: Check current coverage by running the coverage command.
2. **Read Report**: Read `coverage/cov_report.md` to find files with low coverage.
3. **Plan**: Select a file to improve.
4. **Implement**:
   * Read the corresponding test file (e.g., `test/suite/test_core.jl`).
   * Add new test cases to the `test_core()` function.
5. **Verify**:
   * Run only the modified test group: `julia --project -e 'using Pkg; Pkg.test("MyPackage"; test_args=["core"])'`
   * Ensure tests pass.
6. **Loop**: Re-run coverage to confirm improvement.
```

This setup provides a closed-loop system where the agent has all the necessary tools to autonomously improve code quality.
