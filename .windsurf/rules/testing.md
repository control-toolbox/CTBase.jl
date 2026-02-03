---
trigger: always_on
globs: **/*.jl
---

# Julia Testing Standards

## 🤖 **Agent Directive**

**When applying this rule, explicitly state**: "🧪 **Applying Testing Rule**: [specific testing principle being applied]"

This ensures transparency about which testing standard is being used and why.

---

This document defines the testing standards for the Control Toolbox project. All Julia code modifications must be accompanied by appropriate tests following these guidelines.

## Core Principles

1. **Contract-First Testing**: Test behavior through public API contracts, not implementation details
2. **Orthogonality**: Tests are independent from source code structure (test organization ≠ src organization)
3. **Isolation**: Unit tests use mocks/fakes to isolate components; integration tests verify interactions
4. **Determinism**: Tests must be reproducible and not depend on external state
5. **Clarity**: Test intent must be immediately obvious from test names and structure

## Test Organization

### Directory Structure

Tests are organized under `test/suite/` by **functionality**, not by source file structure:

- `suite/docp/`: Discretized Optimal Control Problem tests
- `suite/exceptions/`: Exception system tests
- `suite/initial_guess/`: Initial guess and initialization tests
- `suite/integration/`: End-to-end integration tests
- `suite/meta/`: Meta tests (Aqua.jl quality checks, exports verification)
- `suite/modelers/`: Modelers (ADNLPModeler, ExaModeler) tests
- `suite/ocp/`: Optimal Control Problem components tests
- `suite/optimization/`: Optimization module tests
- `suite/options/`: Options system tests
- `suite/orchestration/`: Orchestration layer tests
- `suite/strategies/`: Strategies framework tests
- `suite/types/`: Core type definitions tests
- `suite/utils/`: Utility functions tests
- `suite/validation/`: Validation logic tests

### File and Function Naming

**Required pattern:**

- File name: `test_<name>.jl`
- Entry function: `test_<name>()` (matching the filename exactly)

**Example:**

```julia
# File: test/suite/ocp/test_dynamics.jl
module TestDynamics

using Test
using CTModels
using Main.TestOptions: VERBOSE, SHOWTIMING

function test_dynamics()
    @testset "Dynamics Tests" verbose=VERBOSE showtiming=SHOWTIMING begin
        # Tests here
    end
end

end # module

# CRITICAL: Redefine in outer scope for TestRunner
test_dynamics() = TestDynamics.test_dynamics()
```

## Test Structure

### Module Isolation

Every test file must:

1. Define a module for namespace isolation
2. Define all helper types/functions at **top-level** (never inside test functions)
3. Export the test function to the outer scope

### Unit vs Integration Tests

**Clearly separate** unit and integration tests with section comments:

```julia
function test_optimization()
    @testset "Optimization Module" verbose=VERBOSE showtiming=SHOWTIMING begin
        
        # ====================================================================
        # UNIT TESTS - Abstract Types
        # ====================================================================
        
        @testset "Abstract Types" begin
            # Pure unit tests here
        end
        
        # ====================================================================
        # UNIT TESTS - Contract Implementation
        # ====================================================================
        
        @testset "Contract Implementation" begin
            # Contract tests with fakes
        end
        
        # ====================================================================
        # INTEGRATION TESTS
        # ====================================================================
        
        @testset "Integration Tests" begin
            # Multi-component interaction tests
        end
    end
end
```

### Test Categories

#### 1. Unit Tests

**Purpose**: Test single functions/components in isolation

**Characteristics:**

- Pure logic, deterministic
- Use fake structs to isolate behavior
- No file I/O, network, or external dependencies
- Fast execution (<1ms per test)

**Example:**

```julia
@testset "UNIT TESTS - Builder Types" begin
    @testset "ADNLPModelBuilder construction" begin
        builder = Optimization.ADNLPModelBuilder(x -> ADNLPModel(z -> sum(z.^2), x))
        @test builder isa Optimization.ADNLPModelBuilder
        @test builder isa AbstractModelBuilder
    end
end
```

#### 2. Integration Tests

**Purpose**: Test interaction between multiple components

**Characteristics:**

- Exercise complete workflows
- May use temporary directories (`mktempdir`)
- Test component integration
- Slower execution (acceptable up to 1s per test)

**Example:**

```julia
@testset "INTEGRATION TESTS" begin
    @testset "Complete DOCP workflow - ADNLP" begin
        # Create OCP
        ocp = FakeOCP("integration_test")
        
        # Create builders
        adnlp_builder = Optimization.ADNLPModelBuilder(...)
        
        # Create DOCP
        docp = DiscretizedOptimalControlProblem(ocp, adnlp_builder, ...)
        
        # Build NLP model
        nlp = nlp_model(docp, x0, modeler)
        @test nlp isa ADNLPModels.ADNLPModel
        
        # Build solution
        sol = ocp_solution(docp, stats, modeler)
        @test sol.objective ≈ expected_value
    end
end
```

#### 3. Contract Tests

**Purpose**: Verify API contracts using fake implementations

**Characteristics:**

- Define minimal fake types at top-level
- Implement only required contract methods
- Test routing, defaults, and error paths
- Verify Liskov Substitution Principle

**Example:**

```julia
# TOP-LEVEL: Fake type for contract testing
struct FakeOptimizationProblem <: AbstractOptimizationProblem
    adnlp_builder::Optimization.ADNLPModelBuilder
end

# Implement contract
Optimization.get_adnlp_model_builder(prob::FakeOptimizationProblem) = prob.adnlp_builder

# Test contract
@testset "Contract Implementation" begin
    prob = FakeOptimizationProblem(builder)
    retrieved = get_adnlp_model_builder(prob)
    @test retrieved === builder
end
```

#### 4. Error Tests

**Purpose**: Verify error handling and exception quality

**Characteristics:**

- Test `NotImplemented` errors for unimplemented contracts
- Verify exception types and messages
- Test edge cases and invalid inputs
- Ensure graceful failure

**Example:**

```julia
@testset "Error Cases" begin
    @testset "NotImplemented Errors" begin
        prob = MinimalProblem()  # Doesn't implement contract
        @test_throws CTModels.Exceptions.NotImplemented get_adnlp_model_builder(prob)
    end
    
    @testset "Invalid Arguments" begin
        @test_throws CTModels.Exceptions.IncorrectArgument invalid_function(bad_input)
    end
end
```

## Critical Rules

### 1. Struct Definitions at Top-Level

**NEVER define `struct`s inside test functions.** All helper types, mocks, and fakes must be defined at the **module top-level**.

**❌ Wrong:**

```julia
function test_something()
    @testset "Test" begin
        struct FakeType end  # WRONG! Causes world-age issues
        # ...
    end
end
```

**✅ Correct:**

```julia
module TestSomething

# TOP-LEVEL: Define all structs here
struct FakeType end

function test_something()
    @testset "Test" begin
        obj = FakeType()  # Correct
        # ...
    end
end

end # module
```

### 2. Method Qualification

**Always qualify method calls** even if exported, to make explicit what is being tested:

**✅ Correct:**
```julia
@test CTModels.state_dimension(ocp) == 2
@test CTModels.Optimization.get_adnlp_model_builder(prob) isa Builder
```

**Why:** Explicit qualification avoids ambiguity and makes test intent clear.

### 3. Export Verification

Add dedicated tests to verify exports when necessary:

```julia
@testset "Exports Verification" begin
    @test isdefined(CTModels, :state_dimension)
    @test isdefined(CTModels, :control_dimension)
    @test isdefined(CTModels.Optimization, :AbstractOptimizationProblem)
end
```

### 4. Test Independence

Each test must be independent and not rely on execution order:

**✅ Correct:**
```julia
@testset "Test A" begin
    ocp = create_ocp()  # Create fresh instance
    # Test A logic
end

@testset "Test B" begin
    ocp = create_ocp()  # Create fresh instance
    # Test B logic
end
```

## Test Quality Standards

### Assertion Quality

**Use specific assertions:**

**✅ Good:**
```julia
@test result ≈ 1.23 atol=1e-10
@test obj isa ADNLPModels.ADNLPModel
@test length(components) == 2
@test status == :first_order
```

**❌ Poor:**
```julia
@test result > 0  # Too vague
@test obj != nothing  # Use @test !isnothing(obj)
@test true  # Meaningless
```

### Test Naming

Test names should describe **what** is being tested, not **how**:

**✅ Good:**
```julia
@testset "ADNLPModelBuilder construction"
@testset "Contract Implementation - NotImplemented errors"
@testset "Complete workflow - Rosenbrock ADNLP"
```

**❌ Poor:**
```julia
@testset "Test 1"
@testset "Builder"
@testset "Check stuff"
```

### Documentation

Document complex test setups and non-obvious test logic:

```julia
"""
Fake optimization problem for testing the contract interface.

This minimal implementation only provides the required contract methods
to test routing and default behavior without full OCP complexity.
"""
struct FakeOptimizationProblem <: AbstractOptimizationProblem
    adnlp_builder::Optimization.ADNLPModelBuilder
end
```

## Test Coverage Requirements

### What to Test

**Must test:**

- ✅ Public API functions and types
- ✅ Contract implementations
- ✅ Error paths and exception handling
- ✅ Edge cases (empty inputs, boundary values, special cases)
- ✅ Type stability (for performance-critical code)
- ✅ Integration between components

**Should test:**

- ⚠️ Internal functions with complex logic
- ⚠️ Validation logic
- ⚠️ Conversion and transformation functions

**Don't test:**

- ❌ Trivial getters/setters without logic
- ❌ External library behavior
- ❌ Generated code (unless custom logic added)

### Performance and Type Stability Tests

For performance-critical code, add type stability and allocation tests.

**See also:** `.windsurf/rules/type-stability.md` for comprehensive type stability standards.

#### Type Stability Tests

Type stability is crucial for Julia performance. Test critical functions with `@inferred`:

```julia
@testset "Type Stability" begin
    ocp = create_test_ocp()
    
    # Test type stability of critical functions
    @test_nowarn @inferred CTModels.state_dimension(ocp)
    @test_nowarn @inferred CTModels.control_dimension(ocp)
    @test_nowarn @inferred CTModels.variable_dimension(ocp)
    
    # Test with different input types
    @test_nowarn @inferred process_constraint(ocp, :initial)
    @test_nowarn @inferred process_constraint(ocp, :final)
end
```

**Important:** `@inferred` only works on **function calls**, not direct field access:

```julia
# ❌ WRONG: @inferred on field access
@inferred ocp.state_dimension  # ERROR!

# ✅ CORRECT: Wrap in a function
function get_state_dim(ocp)
    return ocp.state_dimension
end
@inferred get_state_dim(ocp)  # ✅ Works
```

#### Allocation Tests

Test that performance-critical operations don't allocate unnecessarily:

```julia
@testset "Allocations" begin
    ocp = create_test_ocp()
    
    # Test allocation-free operations
    allocs = @allocated CTModels.state_dimension(ocp)
    @test allocs == 0
    
    # Test bounded allocations
    allocs = @allocated CTModels.build_model(ocp)
    @test allocs < 1000  # bytes
end
```

#### When to Test Type Stability

**Must test:**
- Inner loops and hot paths
- Numerical computations
- Solver internals
- Performance-critical API functions

**Optional:**
- One-time setup code
- User-facing convenience functions
- Error handling paths

#### Debugging Type Instabilities

If `@inferred` fails, use `@code_warntype` to debug:

```julia
julia> @code_warntype CTModels.problematic_function(args...)
# Look for red "Any" or yellow warnings
```

## Verification Before Code Changes

### Pre-Implementation Checklist

Before modifying code, verify:

1. **Contract understanding**: What is the expected behavior?
2. **Existing tests**: What tests already exist for this code?
3. **Test coverage**: Are there gaps in current coverage?
4. **Error cases**: What can go wrong?

### Test-First Approach

For new features or bug fixes:

1. **Write failing test** that demonstrates the issue/requirement
2. **Implement fix** to make test pass
3. **Verify** no regressions in existing tests
4. **Refactor** if needed while keeping tests green

**Example workflow:**
```julia
# Step 1: Write failing test
@testset "New feature X" begin
    @test_broken new_function(args) == expected  # Currently fails
end

# Step 2: Implement new_function in src/

# Step 3: Update test
@testset "New feature X" begin
    @test new_function(args) == expected  # Now passes
end
```

## Anti-Patterns to Avoid

### ❌ Don't: Test implementation details

```julia
# BAD: Testing internal field names
@test obj._internal_cache == something
```

### ❌ Don't: Write tests just to pass

```julia
# BAD: Meaningless test
@testset "Function works" begin
    result = some_function()
    @test result == result  # Always true!
end
```

### ❌ Don't: Modify code to make bad tests pass

If tests fail, **fix the root cause**, not the test:

**Wrong approach:**
1. Test fails
2. Change test to pass without understanding why
3. Ship broken code

**Correct approach:**
1. Test fails
2. Understand why (bug in code or test?)
3. Fix the actual issue
4. Verify test now passes for the right reason

### ❌ Don't: Use global mutable state

```julia
# BAD: Global state between tests
const GLOBAL_COUNTER = Ref(0)

@testset "Test A" begin
    GLOBAL_COUNTER[] += 1  # Affects other tests!
end
```

### ❌ Don't: Depend on test execution order

```julia
# BAD: Test B depends on Test A running first
@testset "Test A" begin
    global shared_data = compute_something()
end

@testset "Test B" begin
    @test shared_data > 0  # Breaks if A doesn't run first!
end
```

## Running Tests

### Run all tests

```bash
julia --project=@. -e 'using Pkg; Pkg.test()'
```

### Run specific test group

```bash
julia --project=@. -e 'using Pkg; Pkg.test(; test_args=["ocp"])'
```

### Run with coverage

```bash
julia --project=@. -e 'using Pkg; Pkg.test("CTModels"; coverage=true); include("test/coverage.jl")'
```

## Quality Checklist

Before finalizing tests, verify:

- [ ] All structs defined at module top-level
- [ ] Unit and integration tests clearly separated
- [ ] Method calls are qualified (e.g., `CTModels.function_name`)
- [ ] Test names describe what is being tested
- [ ] Each test is independent and deterministic
- [ ] Error cases are tested with `@test_throws`
- [ ] No file I/O or external dependencies in unit tests
- [ ] Fake types implement minimal contracts
- [ ] Tests document non-obvious logic
- [ ] No global mutable state
- [ ] Tests pass locally before committing

## References

- Test README: `test/README.md`
- Test workflows: `@/test-julia`, `@/test-julia-debug`
- Shared test problems: `test/problems/TestProblems.jl`
- Test runner: Uses `CTBase.TestRunner` extension
