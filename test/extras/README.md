# Exception Examples - CTBase Enriched Exception System

This directory contains comprehensive examples demonstrating the enriched exception system in CTBase.

## 📁 Files Overview

### Exception Type Examples

- **`test_incorrect_argument_examples.jl`** - `IncorrectArgument` exceptions
  - Invalid mathematical operations (sqrt of negative, division by zero)
  - Array bounds checking
  - Input validation scenarios

- **`test_ambiguous_description_examples.jl`** - `AmbiguousDescription` exceptions  
  - Configuration management
  - Description completion with smart suggestions
  - Catalog lookup failures

- **`test_unauthorized_call_examples.jl`** - `UnauthorizedCall` exceptions
  - User permission systems
  - Security checks and access control
  - Role-based authorization

- **`test_not_implemented_examples.jl`** - `NotImplemented` exceptions
  - Feature development status
  - API placeholder methods
  - Future functionality indicators

- **`test_parsing_error_examples.jl`** - `ParsingError` exceptions
  - Configuration file parsing
  - Data format validation
  - Syntax error reporting

- **`test_extension_error_examples.jl`** - `ExtensionError` exceptions
  - Missing package dependencies
  - Plugin system integration
  - Optional feature requirements

### Demo Runner

- **`run_all_examples.jl`** - Complete demonstration script
  - Runs all exception examples in sequence
  - Shows both stacktrace and user-friendly modes
  - Provides comprehensive overview

## 🚀 Usage

### Run Individual Examples

```julia
# Include and run specific example
include("test_incorrect_argument_examples.jl")
test_incorrect_argument_examples()
```

### Run Complete Demo

```julia
# Run all examples
include("run_all_examples.jl")
run_all_exception_examples()
```

### Command Line Usage

```bash
# From CTBase directory
julia --project=. test/extras/run_all_examples.jl
```

## 🎯 Key Features Demonstrated

### 1. **Rich Error Messages**
- Detailed problem descriptions
- Contextual information
- Specific error locations

### 2. **Smart Suggestions**
- Helpful guidance for resolution
- Alternative approaches
- Best practice recommendations

### 3. **Configurable Display**
- Full Julia stacktraces (development mode)
- User-friendly format (production mode)
- Easy switching between modes

### 4. **Consistent Formatting**
- Unified error structure
- Clear visual hierarchy
- Emoji indicators for quick scanning

### 5. **Real-World Scenarios**
- Practical usage examples
- Industry-relevant error cases
- Comprehensive coverage

## 🔧 Configuration Control

```julia
# Show full stacktraces (default for development)
CTBase.set_show_full_stacktrace!(true)

# User-friendly display only (production mode)
CTBase.set_show_full_stacktrace!(false)

# Check current setting
current_mode = CTBase.get_show_full_stacktrace()
```

## 📋 Exception Types Reference

| Exception Type | Use Case | Key Fields |
|---------------|----------|------------|
| `IncorrectArgument` | Invalid input parameters | `got`, `expected`, `suggestion`, `context` |
| `AmbiguousDescription` | Description completion failures | `candidates`, `suggestion`, `context` |
| `UnauthorizedCall` | Permission/access denied | `user`, `reason`, `context` |
| `NotImplemented` | Unimplemented features | `type_info`, `location`, `context` |
| `ParsingError` | Data parsing failures | `input`, `position`, `context` |
| `ExtensionError` | Missing dependencies | `weakdeps`, `feature`, `context` |

## 🎨 Display Modes

### Stacktrace Mode (Development)
```
IncorrectArgument: cannot compute square root of negative number
Stacktrace:
 [1] sqrt_positive at DemoCalculator.jl:15
 [2] top-level scope at REPL[1]:1
```

### User-Friendly Mode (Production)
```
❌ Incorrect Argument
📝 Problem: cannot compute square root of negative number
🔍 Details: Got: -4, Expected: a non-negative number (x ≥ 0)
💡 Suggestion: use sqrt(abs(x)) for absolute value, or check your input
📍 Context: square root calculation
💬 Note: For full Julia stacktrace, run: CTBase.set_show_full_stacktrace!(true)
```

## 🏆 Best Practices

1. **Use specific exception types** for different error categories
2. **Provide rich context** in exception fields
3. **Include helpful suggestions** for error resolution
4. **Configure display mode** appropriately for your environment
5. **Test exception handling** with both display modes

## 📚 Additional Resources

- [CTBase Documentation](../../docs/src/)
- [Exception System Source Code](../../src/Exceptions/)
- [Testing Guidelines](../README.md)
