# Changelog

All notable changes to CTBase will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### 🧹 Maintenance

#### **Git Configuration**
- Cleaned up gitignore to exclude IDE directories (`.windsurf/`, `.cursor/`)
- Removed IDE configuration files from git tracking while preserving them locally
- Improved repository hygiene and reduced noise in version control

#### **Documentation Generation Improvements**
- **Simplified title system**: Consistent 'Public API' and 'Private API' titles across documentation
- **Customization parameters**: Added configurable page titles and descriptions for API documentation
- **Enhanced testing**: Comprehensive tests for customization parameters and title consistency

## [0.18.3-beta] - 2026-02-19

### 🛠 Enhancements

- **TestRunner**: Full-resolution progress bar up to 50 tests with cumulative coloring (green/yellow/red), brackets reflect max severity; compressed mode retains uniform bar.
- **Progress demo**: Added `test/extras/progress/real_bar.jl` for realistic bar simulation with history (skips/failures).
- **Documentation**: Module docstrings now appear on public API pages only.

### 🧪 Testing

- Updated progress display tests for new 50-width threshold and cumulative bar rendering.

## [0.18.2-beta] - 2026-02-16

### 🧹 Maintenance

- Version bump only; no functional changes recorded.

## [0.18.1-beta] - 2026-02-16

### 🧠 Documentation

- Public API pages now include module docstrings (private pages unaffected).

### 🧹 Maintenance

- Removed `.vscode/` artefacts from version control (gitignore hygiene).

## [0.18.0-beta] - 2025-02-04

### 🚀 Major Features

#### **Modular Architecture Overhaul**
- **Complete reorganization** of the codebase into thematic modules:

```text
src/
├── Core/           # Fundamental types and utilities
├── Exceptions/     # Enhanced error handling system
├── Unicode/        # Unicode character utilities
├── Descriptions/   # Description management
└── Extensions/     # Extension system with tag-based dispatch
```

- **Improved maintainability** through clear separation of concerns
- **Better testability** with isolated module boundaries

#### **Enhanced Exception System**

- **New exception types** with rich context:
  - `PreconditionError`: Replaces `UnauthorizedCall` for state-related errors
  - `ParsingError`: For syntax and structure validation errors
  - `AmbiguousDescription`: Enhanced with diagnostic capabilities
  - `ExtensionError`: Improved with feature and context information
- **Rich error messages** with optional fields for suggestions, context, and diagnostics
- **User-friendly display** with emojis and structured formatting
- **Better debugging experience** with detailed error context

#### **Professional Extension System**

- **Tag-based dispatch** for extension points:
  - `AbstractDocumenterReferenceTag` / `DocumenterReferenceTag`
  - `AbstractCoveragePostprocessingTag` / `CoveragePostprocessingTag`  
  - `AbstractTestRunnerTag` / `TestRunnerTag`
- **Three core extensions**:
  - `DocumenterReference`: API documentation generation
  - `CoveragePostprocessing`: Test coverage analysis and reporting
  - `TestRunner`: Advanced test execution with glob patterns
- **Clean separation** between extension points and implementations

#### **Advanced Test Runner**

- **Glob pattern support** for test selection
- **Configurable filename/function name builders**
- **Dry run mode** for test planning
- **Recursive test discovery** in subdirectories
- **Integration with Julia's test ecosystem**

### 📈 Enhancements

#### **Documentation Improvements**

- **Complete documentation rewrite** with modular tutorials
- **API reference generation** with automatic categorization
- **Enhanced coverage reporting** with visual summaries
- **Professional documentation guides** for developers

#### **Testing Infrastructure**

- **Modular test organization** by functionality (not source structure)
- **Comprehensive test coverage** with quality metrics
- **Automated code quality checks** with Aqua.jl
- **Performance and type stability testing**

#### **Developer Experience**

- **Improved error messages** with actionable suggestions
- **Better Unicode support** for mathematical notation
- **Enhanced description management** with intelligent completion
- **Professional project structure** following Julia best practices

### 🔧 Internal Changes

#### **Code Quality**

- **Strict adherence** to Julia style guidelines
- **Comprehensive type annotations** for better performance
- **Memory allocation optimization** for critical paths
- **Extensive documentation** for all public APIs

#### **Testing Standards**

- **Contract-first testing** methodology
- **Unit and integration test separation**
- **Mock and fake implementations** for isolated testing
- **Deterministic and reproducible tests**

#### **Performance**

- **Type stability improvements** throughout the codebase
- **Reduced memory allocations** in hot paths
- **Optimized Unicode operations**
- **Efficient description matching algorithms**

### 📦 Dependencies

#### **New Dependencies**

- `Aqua = "0.8"`: Code quality and consistency checks
- `OrderedCollections = "1"`: Ordered data structures for testing

#### **Updated Compatibility**

- Julia `1.10+` (increased from `1.8+`)
- Updated all package compatibility bounds

### 🏗️ Project Structure

#### **New Directory Organization**

```text
src/
├── Core/           # Fundamental types and utilities
├── Exceptions/     # Enhanced error handling system
├── Unicode/        # Unicode character utilities
├── Descriptions/   # Description management
└── Extensions/     # Extension system

test/
├── suite/          # Modular test suites by functionality
├── extras/         # Example tests and diagnostics
└── src/           # Source-level integration tests

docs/
└── src/           # Modular documentation tutorials
```

#### **Extension System**

```text
ext/
├── CoveragePostprocessing.jl  # Coverage analysis
├── DocumenterReference.jl    # API documentation
└── TestRunner.jl             # Advanced test execution
```

### 🎯 Breaking Changes

See [BREAKINGS.md](BREAKINGS.md) for detailed migration guide.

### 🙏 Acknowledgments

This major release represents a significant investment in code quality, developer experience, and long-term maintainability. The modular architecture provides a solid foundation for future enhancements while maintaining backward compatibility where possible.

---

## [0.18.0-beta.1] - 2025-02-09

### 🚀 TestRunner Enhancements

#### **Advanced Progress Bar System**
- **Adaptive bar width**: Width equals total for ≤20 tests, fixed at 20 for >20 tests
- **Visual consistency**: Uses `█` (filled) and `░` (empty) characters without gaps
- **Smart failure detection**: Correctly detects both exceptions and `@test` assertion failures
- **Zero-padded indices**: Aligned test numbers for better readability

#### **Robust Failure Detection**
- **Before/after results scanning**: Compares testset results before and after eval
- **Recursive failure detection**: Scans nested testsets for `Test.Fail` and `Test.Error`
- **More reliable than `anynonpass`**: Works regardless of testset completion timing

#### **Enhanced User Experience**
- **Path prefix stripping**: Users can write `test/suite` or `suite` interchangeably
- **Guard against conflicts**: Prevents `test/` subdirectory in test directory
- **Comprehensive callbacks**: `on_test_start` and `on_test_done` with `TestRunInfo` context
- **Configurable progress**: Built-in progress bar with option for custom callbacks

#### **Professional Documentation**
- **Complete docstring overhaul**: All functions follow project documentation standards
- **Safe, runnable examples**: All examples use `julia-repl` with proper imports
- **Cross-reference resolution**: Fully qualified `@ref` links to prevent header conflicts
- **API reference reorganization**: Clean separation in `src/api/` without prefixes

### 📈 Documentation Improvements

#### **Better Organization**
- **User guides in `src/guide/`**: Clear separation from API reference
- **API reference in `src/api/`**: Auto-generated with clean filenames
- **Updated navigation**: Changed "Tutorials" to "User Guides" for clarity
- **Fixed cleanup**: Generated API files properly removed after build

### 🔧 Technical Improvements

#### **Code Quality**
- **Fixed `@ref` conflicts**: All TestRunner references now use fully qualified names
- **Enhanced error handling**: Better detection and reporting of test failures
- **Improved type safety**: Comprehensive type annotations throughout
- **Memory optimization**: Efficient progress bar rendering and failure detection

---

## [0.18.0-beta] - 2025-02-04

### 🚀 Major Features

#### **Modular Architecture Overhaul**
- **Complete reorganization** of the codebase into thematic modules:

```text
src/
├── Core/           # Fundamental types and utilities
├── Exceptions/     # Enhanced error handling system
├── Unicode/        # Unicode character utilities
├── Descriptions/   # Description management
└── Extensions/     # Extension system with tag-based dispatch
```

- **Improved maintainability** through clear separation of concerns
- **Better testability** with isolated module boundaries

#### **Enhanced Exception System**

- **New exception types** with rich context:
  - `PreconditionError`: Replaces `UnauthorizedCall` for state-related errors
  - `ParsingError`: For syntax and structure validation errors
  - `AmbiguousDescription`: Enhanced with diagnostic capabilities
  - `ExtensionError`: Improved with feature and context information
- **Rich error messages** with optional fields for suggestions, context, and diagnostics
- **User-friendly display** with emojis and structured formatting
- **Better debugging experience** with detailed error context

#### **Professional Extension System**

- **Tag-based dispatch** for extension points:
  - `AbstractDocumenterReferenceTag` / `DocumenterReferenceTag`
  - `AbstractCoveragePostprocessingTag` / `CoveragePostprocessingTag`  
  - `AbstractTestRunnerTag` / `TestRunnerTag`
- **Three core extensions**:
  - `DocumenterReference`: API documentation generation
  - `CoveragePostprocessing`: Test coverage analysis and reporting
  - `TestRunner`: Advanced test execution with glob patterns
- **Clean separation** between extension points and implementations

#### **Advanced Test Runner**

- **Glob pattern support** for test selection
- **Configurable filename/function name builders**
- **Dry run mode** for test planning
- **Recursive test discovery** in subdirectories
- **Integration with Julia's test ecosystem**

### 📈 Enhancements

#### **Documentation Improvements**

- **Complete documentation rewrite** with modular tutorials
- **API reference generation** with automatic categorization
- **Enhanced coverage reporting** with visual summaries
- **Professional documentation guides** for developers

#### **Testing Infrastructure**

- **Modular test organization** by functionality (not source structure)
- **Comprehensive test coverage** with quality metrics
- **Automated code quality checks** with Aqua.jl
- **Performance and type stability testing**

#### **Developer Experience**

- **Improved error messages** with actionable suggestions
- **Better Unicode support** for mathematical notation
- **Enhanced description management** with intelligent completion
- **Professional project structure** following Julia best practices

### 🔧 Internal Changes

#### **Code Quality**

- **Strict adherence** to Julia style guidelines
- **Comprehensive type annotations** for better performance
- **Memory allocation optimization** for critical paths
- **Extensive documentation** for all public APIs

#### **Testing Standards**

- **Contract-first testing** methodology
- **Unit and integration test separation**
- **Mock and fake implementations** for isolated testing
- **Deterministic and reproducible tests**

#### **Performance**

- **Type stability improvements** throughout the codebase
- **Reduced memory allocations** in hot paths
- **Optimized Unicode operations**
- **Efficient description matching algorithms**

### 📦 Dependencies

#### **New Dependencies**

- `Aqua = "0.8"`: Code quality and consistency checks
- `OrderedCollections = "1"`: Ordered data structures for testing

#### **Updated Compatibility**

- Julia `1.10+` (increased from `1.8+`)
- Updated all package compatibility bounds

### 🏗️ Project Structure

#### **New Directory Organization**

```text
src/
├── Core/           # Fundamental types and utilities
├── Exceptions/     # Enhanced error handling system
├── Unicode/        # Unicode character utilities
├── Descriptions/   # Description management
└── Extensions/     # Extension system

test/
├── suite/          # Modular test suites by functionality
├── extras/         # Example tests and diagnostics
└── src/           # Source-level integration tests

docs/
└── src/           # Modular documentation tutorials
```

#### **Extension System**

```text
ext/
├── CoveragePostprocessing.jl  # Coverage analysis
├── DocumenterReference.jl    # API documentation
└── TestRunner.jl             # Advanced test execution
```

### 🎯 Breaking Changes

See [BREAKINGS.md](BREAKINGS.md) for detailed migration guide.

### 🙏 Acknowledgments

This major release represents a significant investment in code quality, developer experience, and long-term maintainability. The modular architecture provides a solid foundation for future enhancements while maintaining backward compatibility where possible.

---

## [0.17.4] - Previous Release

### 📝 Previous Changes
- Stable version with basic exception handling
- Simple description management
- Basic Unicode utilities
- Foundation for Control Toolbox ecosystem

---

*For older versions, please refer to the git commit history.*
