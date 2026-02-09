# Breaking Changes

This document outlines all breaking changes introduced in CTBase v0.18.0-beta compared to v0.17.4. Use this guide to migrate your code and understand the impact of these changes.

## Table of Contents

- [Exception System Overhaul](#exception-system-overhaul)
- [Module Reorganization](#module-reorganization)  
- [Extension System Introduction](#extension-system-introduction)
- [TestRunner Enhancements](#testrunner-enhancements)
- [API Changes](#api-changes)
- [Dependency Updates](#dependency-updates)
- [Migration Guide](#migration-guide)

---

## Exception System Overhaul

### 🚨 Major Breaking Change

The entire exception system has been redesigned with enhanced types and richer context. While most existing exception types are preserved, their constructors and internal structure have changed.

#### Changed Exception Types

#### UnauthorizedCall → PreconditionError

```julia
# v0.17.4
throw(CTBase.UnauthorizedCall("message"))

# v0.18.0-beta  
throw(CTBase.PreconditionError("message"))
```

#### Enhanced Exception Constructors

All exceptions now support optional keyword arguments for enhanced context:

```julia
# v0.17.4
throw(CTBase.IncorrectArgument("message"))

# v0.18.0-beta (backward compatible)
throw(CTBase.IncorrectArgument("message"))

# v0.18.0-beta (enhanced version)
throw(CTBase.IncorrectArgument(
    "message";
    got="actual_value",
    expected="expected_value", 
    suggestion="how to fix",
    context="where it happened"
))
```

#### New Exception Fields

Exceptions now have additional fields that may affect code using reflection:

```julia
# v0.17.4
struct IncorrectArgument <: CTException
    var::String
end

# v0.18.0-beta
struct IncorrectArgument <: CTException
    msg::String
    got::Union{String, Nothing}
    expected::Union{String, Nothing}  
    suggestion::Union{String, Nothing}
    context::Union{String, Nothing}
end
```

#### Impact Assessment

- **Low Impact**: Most existing `throw` calls will continue to work
- **Medium Impact**: Code that inspects exception fields may need updates
- **High Impact**: Code that specifically catches `UnauthorizedCall` needs updates

---

## Module Reorganization

### 🚨 Structural Breaking Change

The monolithic source structure has been replaced with a modular architecture. This affects internal module organization but preserves the public API.

#### Before (v0.17.4)

```julia
# src/CTBase.jl
module CTBase
    # All code in single file or directly included
    include("exception.jl")
    include("description.jl") 
    include("default.jl")
    include("utils.jl")
end
```

#### After (v0.18.0-beta)

```julia
# src/CTBase.jl  
module CTBase
    # Modular organization
    include("Exceptions/Exceptions.jl")
    include("Core/Core.jl")
    include("Unicode/Unicode.jl") 
    include("Descriptions/Descriptions.jl")
    include("Extensions/Extensions.jl")
end
```

#### Internal Module Changes

**New Internal Modules:**

- `CTBase.Exceptions`: Enhanced exception system
- `CTBase.Core`: Fundamental types and utilities
- `CTBase.Unicode`: Unicode character utilities  
- `CTBase.Descriptions`: Description management
- `CTBase.Extensions`: Extension system

#### Impact Assessment - Module Reorganization

- **Low Impact**: Public API remains unchanged
- **Medium Impact**: Code accessing internal module structure may break
- **High Impact**: Code that used `using CTBase: InternalModule` patterns

---

## Extension System Introduction

### 🚨 New Extension Points

Several functions that previously had default implementations now require explicit extensions to be loaded.

#### Affected Functions

##### automatic_reference_documentation

```julia
# v0.17.4 - Had basic implementation
CTBase.automatic_reference_documentation()

# v0.18.0-beta - Requires extension
using CTBase.Extensions.DocumenterReference
CTBase.automatic_reference_documentation()
```

##### postprocess_coverage

```julia  
# v0.17.4 - Had basic implementation
CTBase.postprocess_coverage()

# v0.18.0-beta - Requires extension
using CTBase.Extensions.CoveragePostprocessing  
CTBase.postprocess_coverage()
```

##### run_tests

```julia
# v0.17.4 - Had basic implementation
CTBase.run_tests()

# v0.18.0-beta - Requires extension  
using CTBase.Extensions.TestRunner
CTBase.run_tests()
```

#### Extension Error Handling

Attempting to use these functions without loading extensions now throws `ExtensionError`:

```julia
julia> CTBase.automatic_reference_documentation()
ERROR: ExtensionError. Please make: julia> using Documenter, Markdown, MarkdownAST
```

#### Impact Assessment - Extension System

- **Medium Impact**: Code using these functions needs extension loading
- **Low Impact**: Clear error messages guide users to solution
- **Documentation**: All affected functions are well-documented

---

## API Changes

### 🚨 Public API Modifications

#### Exception Display Changes

Exception display formatting has changed significantly:

```julia
# v0.17.4
ERROR: IncorrectArgument: message

# v0.18.0-beta  
❌ IncorrectArgument: message
```

#### New Type Aliases

Some internal types have been formalized:

```julia
# v0.17.4 - Implicit usage
Tuple{Vararg{Symbol}}

# v0.18.0-beta - Explicit alias  
CTBase.DescVarArg
```

#### Unicode Module Organization

Unicode functions are now in a dedicated module:

```julia
# v0.17.4 - Direct access
CTBase.ctindice(1)

# v0.18.0-beta - Still works (re-exported)
CTBase.ctindice(1)

# v0.18.0-beta - Direct module access
CTBase.Unicode.ctindice(1)
```

---

## TestRunner Enhancements

### 🚨 New Extension Features

The TestRunner extension has been significantly enhanced with advanced capabilities for test execution and progress tracking.

#### Progress Bar System Changes

The progress bar implementation has been completely rewritten with adaptive width:

```julia
# v0.18.0-beta (basic progress)
[████████████░░░░░░░░░░] ✓ [08/19] suite/exceptions/test_display.jl (2.5s)

# v0.18.0-beta.1 (adaptive width)
[████████░░░░░░░░░░] ✓ [08/19] suite/exceptions/test_display.jl (2.5s)
[████████████████████] ✓ [19/19] suite/exceptions/test_exceptions.jl (0.6s)
```

#### Enhanced Failure Detection

The failure detection mechanism is now more robust and accurate:

```julia
# v0.18.0-beta (unreliable)
# @test failures sometimes showed as success

# v0.18.0-beta.1 (robust detection)
# Correctly detects both exceptions and @test assertion failures
```

#### Path Prefix Stripping

Users can now use `test/suite` and `suite` interchangeably:

```julia
# v0.18.0-beta (explicit paths required)
julia --project -e 'using Pkg; Pkg.test(; test_args=["suite/exceptions"])'

# v0.18.0-beta.1 (automatic stripping)
julia --project -e 'using Pkg; Pkg.test(; test_args=["test/suite"])'  # Same result
```

#### Callback System Overhaul

The callback system has been enhanced with rich context information:

```julia
# v0.18.0-beta (basic callbacks)
on_test_done = info -> println("Done: $(info.status)")

# v0.18.0-beta.1 (rich context)
on_test_done = info -> begin
    if info.status == :error || info.status == :test_failed
        println("❌ FAILED: $(info.spec)")
    else
        println("✓ Success: $(info.spec)")
    end
end
```

#### Directory Protection

The system now prevents ambiguous directory structures:

```julia
# v0.18.0-beta (allowed)
test/
├── test/  # This would cause ambiguity with prefix stripping

# v0.18.0-beta.1 (protected)
ERROR: A subdirectory "test" exists inside the test directory
```

### 📚 Documentation Improvements

#### Docstring Standards Compliance

All TestRunner functions now follow the project's documentation standards:

```julia
"""
$(TYPEDSIGNATURES)
Run tests with configurable file/function name builders...

# Arguments
- `args::AbstractVector{<:AbstractString}`: Command-line arguments...
```

#### Cross-Reference Resolution

All internal references now use fully qualified names to prevent header conflicts:

```julia
# v0.18.0-beta (conflicts)
See also: [`TestRunInfo`](@ref)  # Header conflicts

# v0.18.0-beta.1 (resolved)
See also: [`TestRunner.TestRunInfo`](@ref)
```

---

## Dependency Updates

### 🚨 Version Requirements

#### Julia Version Increase

```toml
# v0.17.4
julia = "1.8"

# v0.18.0-beta  
julia = "1.10"
```

#### New Test Dependencies

```toml
# v0.18.0-beta additions
Aqua = "0.8"
OrderedCollections = "1"
```

#### Impact Assessment - Dependencies

- **Medium Impact**: Projects on Julia < 1.10 cannot upgrade
- **Low Impact**: New dependencies are test-only
- **Justification**: Julia 1.10 provides better stability and performance

---

## Migration Guide

### 📋 Step-by-Step Migration

#### 1. Update Exception Handling

**Find and replace `UnauthorizedCall`:**

```bash
# In your codebase
find . -name "*.jl" -exec sed -i 's/UnauthorizedCall/PreconditionError/g' {} \;
```

**Update exception field access:**

```julia
# Before
catch e
    if e isa IncorrectArgument
        println(e.var)  # Direct field access
    end
end

# After  
catch e
    if e isa IncorrectArgument
        println(e.msg)  # Use new field name
    end
end
```

#### 2. Load Required Extensions

**Add extension loading to your code:**

```julia
# For documentation generation
using CTBase
using CTBase.Extensions.DocumenterReference

# For test coverage
using CTBase  
using CTBase.Extensions.CoveragePostprocessing

# For advanced testing
using CTBase
using CTBase.Extensions.TestRunner
```

#### 3. Update Julia Version

**Update your project's compat requirements:**

```toml
[compat]
julia = "1.10"
```

#### 4. Test Your Migration

**Run comprehensive tests:**

```julia
using CTBase
using CTBase.Extensions.TestRunner

# Test all functionality
CTBase.run_tests()
```

### 🧪 Testing Migration

#### Exception Compatibility Test

```julia
function test_exception_migration()
    # Test old-style constructors still work
    e1 = CTBase.IncorrectArgument("test message")
    @test e1.msg == "test message"
    
    # Test new enhanced constructors
    e2 = CTBase.IncorrectArgument("test"; got="bad", expected="good")
    @test e2.got == "bad"
    @test e2.expected == "good"
end
```

#### Extension Loading Test

```julia
function test_extension_loading()
    # Test that extensions work
    using CTBase.Extensions.TestRunner
    @test_nowarn CTBase.run_tests(dry_run=true)
end
```

### ⚠️ Common Migration Issues

#### Issue 1: Missing Extensions

**Problem:** `ExtensionError` when using documentation functions

**Solution:**

```julia
# Add this to your code
using CTBase.Extensions.DocumenterReference
```

#### Issue 2: Exception Field Changes  

**Problem:** Code accessing `e.var` on exceptions

**Solution:**

```julia
# Update field access
# Old: e.var  
# New: e.msg
```

#### Issue 3: Julia Version Compatibility

**Problem:** Project still on Julia 1.8/1.9

**Solution:**

```bash
# Update Julia
juliaup update 1.10
```

### 🔄 Backward Compatibility

#### What's Preserved

- **Public API**: All public function signatures remain the same
- **Exception Types**: All exception types still exist
- **Core Functionality**: Description management, Unicode helpers work unchanged
- **Re-exports**: Common functions remain available from `CTBase`

#### What's Changed

- **Exception Internals**: Field structure and constructors enhanced
- **Module Organization**: Internal structure modularized
- **Extension Points**: Some functions now require explicit extensions
- **Error Messages**: Enhanced formatting and context

---

## Need Help?

### 📚 Resources

- **Documentation**: Updated for v0.18.0-beta
- **Examples**: See `test/extras/` for migration examples  
- **Issues**: Report migration problems on GitHub
- **Discussions**: Ask questions in GitHub Discussions

### 🤝 Support

If you encounter migration issues:

1. **Check this guide** for common solutions
2. **Run the test suite** to identify specific problems
3. **Open an issue** with minimal reproduction
4. **Join discussions** for community support

---

*This breaking changes guide is comprehensive but not exhaustive. Test your migration thoroughly and report any undocumented issues.*
