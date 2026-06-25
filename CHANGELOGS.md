# Changelog

All notable changes to CTBase will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.24.0-beta] - 2026-06-25

### ✨ New Features

#### **Differentiation Module**

- **Automatic differentiation backend strategies**: Added comprehensive AD backend infrastructure for computing gradients
  - **AbstractADBackend**: Abstract contract for AD backends with trait-based dispatch
  - **DifferentiationInterface strategy**: Concrete strategy wrapping DifferentiationInterface.jl backends (e.g., `AutoForwardDiff()`)
  - **Hamiltonian gradient computation**: `hamiltonian_gradient(backend, h, t, x, p, v)` → (∂H/∂x, ∂H/∂p)
  - **Variable gradient computation**: `variable_gradient(backend, h, t, x, p, v)` → ∂H/∂v
  - **Generic differentiation methods**: `gradient`, `derivative`, `differentiate`, `pushforward` for flexible AD operations
  - **ADTypes integration**: Hard dependency on ADTypes.jl with `AutoForwardDiff` as default backend
  - **DifferentiationInterface extension**: CTBaseDifferentiationInterface extension for gradient computation
  - **Construction defaults**: `__ad_backend` for trait-based backend selection
- **Full test coverage**: Added comprehensive test suite for Differentiation module
- **Documentation**: Added `docs/src/guide/differentiation.md` with complete Differentiation module guide
- **Migration from CTFlows**: AD backend strategies moved from CTFlows to CTBase.Differentiation for ecosystem-wide sharing
- **Self-contained module**: CTBase.Differentiation depends on CTBase.Data, CTBase.Strategies, CTBase.Exceptions, and ADTypes
- **No breaking changes**: Purely additive feature with backward-compatible API. No migration required.

### 🔄 Dependencies

- **ADTypes.jl**: Added as hard dependency for AD backend type definitions
- **DifferentiationInterface.jl**: Added as weak dependency with extension support

### 🏗️ Architecture

- **Shared AD infrastructure**: Moved AD backend strategies from CTFlows to CTBase.Differentiation
  - Enables automatic differentiation across control-toolbox packages without duplication
  - Provides abstract contract for AD backends with trait-based dispatch
  - Supports multiple AD backends through strategy pattern
  - Integrates with CTBase.Strategies for solver configuration

### 🧹 Maintenance

- **Documentation refinement**: Refined Differentiation docstrings and guide synchronization
- **Test coverage**: Added gradient/derivative tests for DifferentiationInterface extension
- **Version bump**: Bumped to 0.24.0-beta for Differentiation module addition.

## [0.23.0-beta] - 2026-06-25

### ✨ New Features

#### **Data Module**

- **Vector fields and Hamiltonian structures**: Added comprehensive data structures for vector fields and Hamiltonian systems
  - **VectorField**: Encapsulates vector-field functions with time-dependence and variable-dependence traits
  - **AbstractVectorField**: Abstract base type for vector fields
  - **Hamiltonian**: Hamiltonian function representation with traits
  - **AbstractHamiltonian**: Abstract base type for Hamiltonians
  - **HamiltonianVectorField**: Hamiltonian vector field combining Hamiltonian and vector field concepts
  - **AbstractHamiltonianVectorField**: Abstract base type for Hamiltonian vector fields
  - **Construction defaults**: `__is_autonomous`, `__is_variable`, `__is_inplace` for trait-based construction
  - **Helper functions**: Utilities for working with vector fields and Hamiltonians
- **Full test coverage**: Added comprehensive test suite for Data module
- **Documentation**: Added `docs/src/guide/data.md` with complete Data module guide
- **Migration from CTFlows**: Vector fields and Hamiltonian structures moved from CTFlows to CTBase.Data for ecosystem-wide sharing
- **Self-contained module**: CTBase.Data depends only on CTBase.Traits and CTBase.Exceptions
- **No breaking changes**: Purely additive feature with backward-compatible API. No migration required.

### 🏗️ Architecture

- **Shared data infrastructure**: Moved vector fields and Hamiltonian structures from CTFlows to CTBase.Data
  - Enables vector field and Hamiltonian representation across control-toolbox packages without duplication
  - Provides common abstractions for dynamical systems with trait-based dispatch
  - Supports type-safe handling of time-dependence and variable-dependence traits

### 🧹 Maintenance

- **Documentation improvements**: Reordered Core Concepts sidebar by conceptual layers
- **Test runner improvements**: Renamed TestOptions to TestData for clarity
- **Version bump**: Bumped to 0.23.0-beta for Data module addition.

## [0.22.0-beta] - 2026-06-23

### ✨ New Features

#### **Traits Module**

- **Comprehensive trait system**: Added full trait infrastructure for type-level dispatch across control-toolbox ecosystem
  - **Time dependence traits**: `TimeDependence`, `Autonomous`, `NonAutonomous` for distinguishing autonomous vs non-autonomous systems
  - **Variable dependence traits**: `VariableDependence`, `Fixed`, `NonFixed` for systems with/without variable parameters
  - **Mutability traits**: `AbstractMutabilityTrait`, `InPlace`, `OutOfPlace` for in-place vs out-of-place evaluation
  - **Mode traits**: `AbstractModeTrait`, `EndPointMode`, `TrajectoryMode` for point-to-point vs trajectory integration
  - **Dynamics traits**: `AbstractDynamicsTrait`, `StateDynamics`, `HamiltonianDynamics`, `AugmentedHamiltonianDynamics` for dynamics type specification
  - **AD traits**: `AbstractADTrait`, `WithAD`, `WithoutAD` for automatic differentiation capability
  - **Variable costate traits**: `AbstractVariableCostateCapability`, `SupportsVariableCostate`, `NoVariableCostate` for costate variable support
  - **Abstract trait base**: `AbstractTrait` as root of trait hierarchy
  - **Helper functions**: Boolean predicates (`is_autonomous`, `is_variable`, `is_inplace`, etc.) and trait query functions
- **Full test coverage**: Added comprehensive test suites for all trait modules (1138+ tests total)
- **Documentation**: Added `docs/src/guide/traits.md` with complete trait system guide
- **Migration from CTFlows**: Traits moved from CTFlows to CTBase for ecosystem-wide sharing
- **No breaking changes**: Purely additive feature with backward-compatible API. No migration required.

### 🏗️ Architecture

- **Shared trait infrastructure**: Moved trait types from CTFlows to CTBase.Traits
  - Enables trait-based dispatch across control-toolbox packages without duplication
  - Provides type-level abstractions for system properties (time dependence, mutability, dynamics, etc.)
  - Supports compile-time optimizations through trait-based dispatch

### 🧹 Maintenance

- **Docstring compliance**: Fixed all docstring cross-references in Traits and Strategies modules
  - Added full module paths to all internal `@ref` references
  - Changed `@extref` to `@ref` for internal symbols
  - Removed CTFlows references from trait docstrings
- **Version bump**: Bumped to 0.22.0-beta for Traits module addition.

## [0.21.1-beta] - 2026-06-23

### 🔄 Breaking Changes

#### **Module Rename: Extensions → DevTools**

- **Renamed submodule**: `CTBase.Extensions` → `CTBase.DevTools` to better reflect its purpose (internal developer tools, not a general extension system)
- **Unchanged API**: All tag types and functions remain unchanged:
  - `run_tests`
  - `postprocess_coverage`
  - `automatic_reference_documentation`
  - `AbstractTestRunnerTag`, `TestRunnerTag`
  - `AbstractDocumenterReferenceTag`, `DocumenterReferenceTag`
  - `AbstractCoveragePostprocessingTag`, `CoveragePostprocessingTag`
- **Migration**: Replace `CTBase.Extensions` with `CTBase.DevTools` and `import CTBase.Extensions` with `import CTBase.DevTools` at all call sites

### ✨ New Features

#### **Core Utilities**

- **AbstractCache**: Added abstract base type for computation caches in `Core/caches.jl`
  - Generic type for storing pre-allocated buffers and prepared plans (e.g. AD plans)
  - Concrete cache subtypes defined by packages/extensions providing specific backends
  - Exported from `CTBase.Core` for reuse across control-toolbox ecosystem
- **make_coerce**: Added shape-matching coercion helper in `Core/function_utils.jl`
  - Returns `only` for scalars to extract single element from 1-element vectors
  - Returns `identity` for arrays (`AbstractVector`, `AbstractMatrix`) as no-op
  - Used to map uniform vector-valued results back to natural input shape
  - Exported from `CTBase.Core` for reuse across control-toolbox ecosystem

### 🏗️ Architecture

- **Shared infrastructure**: Moved generic, dependency-free building blocks from CTFlows to CTBase.Core
  - Enables sharing across control-toolbox packages without duplication
  - `AbstractCache` provides common interface for computation caches
  - `make_coerce` provides uniform shape coercion strategy

### 🧹 Maintenance

- **Version bump**: Bumped to 0.21.1-beta for module rename and core utilities.

## [0.21.0-beta] - 2026-06-22

### ✨ New Features

#### **Configurable Color Palette System**

- **Flexible color management**: Added `Style` and `Palette` types for ANSI color management in `Core/palette.jl`
- **Built-in palettes**: Three pre-configured palettes for different use cases
  - `DEFAULT`: Standard colors for general use
  - `MONOCHROME`: Grayscale palette for monochrome terminals
  - `HIGH_CONTRAST`: Accessibility-focused palette with high contrast colors
- **Runtime switching**: `set_palette!(palette)` to switch palettes at runtime, `reset_palette!()` to restore defaults
- **Fine-grained customization**: `set_color!(role, color)` to customize specific semantic roles (success, error, warning, info, etc.)
- **Visual preview**: `show_palette()` displays current palette configuration with color samples
- **Integration**: Updated all display paths (Core, Exceptions, TestRunner) to use active palette
- **Documentation**: Comprehensive guide in `docs/src/guide/color-system.md`

#### **CTSolvers Infrastructure**

- **Strategies module**: Moved CTSolvers core infrastructure to CTBase
  - Options system for solver configuration
  - Orchestration layer for solver selection
  - Strategy abstractions for extensible solver implementations
- **Foundational infrastructure**: Provides shared infrastructure for solver selection and configuration across control-toolbox packages

### 📚 Documentation

#### **Documentation Structure Refactor**

- **Handbook migration**: Moved `dev/` directory to control-toolbox/Handbook repository
  - Philosophy, rules, and planning templates now maintained in centralized Handbook
- **Agent guides**: Rewrote `AGENTS.md` and `CLAUDE.md` to redirect Developer Resources to Handbook
- **Directory READMEs**: Added `README.md` in `src/`, `ext/`, `test/`, `docs/` with package-specific context
  - All READMEs point to control-toolbox Handbook for conventions
- **README update**: Updated main README with latest ABOUT.md, INSTALL.md, CONTRIBUTING.md and badges

### 🧪 Testing

- **Color palette tests**: Added comprehensive test suite in `test/suite/core/test_palette.jl` (259 tests)
  - Palette construction and validation
  - Color role mapping and customization
  - Runtime palette switching
  - Visual preview generation
  - Integration with display paths
- **TestRunner progress tests**: Updated progress display tests for palette integration (25 new assertions)
- **Core display tests**: Updated existing display tests for palette system (27 assertions modified)

### 🧹 Maintenance

- **Typos configuration**: Added `_typos.toml` for spell checking across the codebase
- **Version bump**: Bumped to 0.21.0-beta for feature release.

## [0.20.0-beta] - 2026-06-15

### 🐛 Bug Fixes

- **ANSI color detection**: Fixed `get_format_codes` bug where color detection was disabled (`supports_color = true` → `get(io, :color, false)`)

### ♻️ Refactoring

- **ANSI display unification**: Centralized all ANSI formatting utilities in `Core/display.jl` to provide a single source of truth
  - Added `_apply_ansi(s, code, io::IO)` base function with color detection
  - Added semantic wrappers: `_dim`, `_bold`, `_red`, `_yellow`, `_green`
  - All ANSI functions remain private (underscore prefix, not exported)
- **AbstractTag organization**: Moved `AbstractTag` from `Core/display.jl` to dedicated `Core/tags.jl` for better module organization
- **Module load order**: Changed `CTBase.jl` to load Core before Exceptions (was stale comment "must load first")
- **Qualified imports**: `Exceptions/display.jl` now uses qualified calls (`Core._dim`, `Core._bold`, etc.) instead of local definitions

### 🧪 Testing

- **Core display tests**: Added `test_core_display.jl` with comprehensive tests for ANSI functions (52 assertions)
  - Tests color detection (with/without color)
  - Tests all ANSI wrappers
  - Tests `get_format_codes` NamedTuple structure

## [0.19.0-beta] - 2026-06-11

### ✨ New Features

#### **Interpolation Module**

- **New module**: Added `Interpolation` module with interpolation utilities migrated from CTModels.Utils (issue #445)
- **Linear interpolation**: `ctinterpolate(x, f)` creates a linear interpolant with flat extrapolation beyond bounds
- **Constant interpolation**: `ctinterpolate_constant(x, f)` creates a right-continuous piecewise-constant (steppost) interpolant
- **Typed interpolants**: `Interpolant{Linear}` and `Interpolant{Constant}` parametric types with type-stable call methods
- **Custom display**: Added `show` methods for interpolants showing method type and node count
- **Optimal control support**: Constant interpolation implements standard steppost behavior for control applications

#### **Core Utilities**

- **Matrix utilities**: Extended `Core` module with `matrix2vec` for matrix-to-vector conversion (public)
- **Function utilities**: Added `to_out_of_place` for out-of-place function transformation (private)
- **Validation macro**: Added `@ensure` macro for argument validation (private)

### 📚 Documentation

- **API reference**: Updated `docs/api_reference.jl` to include new Interpolation module with public and private documentation
- **Core documentation**: Extended Core API reference to include matrix_utils, function_utils, and macros
- **Docstrings**: Comprehensive docstrings with `$(TYPEDSIGNATURES)` and julia-repl examples

### 🧪 Testing

- **Interpolation tests**: 56 tests covering linear/constant interpolation, extrapolation, non-uniform grids, vector values, type stability, and display
- **Function utils tests**: 18 tests for `to_out_of_place` function transformation
- **Macro tests**: 14 tests for `@ensure` validation macro
- **Matrix utils tests**: 26 tests for `matrix2vec` and related utilities
- **All tests pass**: 1237/1237 tests pass (45.9s)

### 🏗️ Architecture

- **Modular design**: Split utilities by responsibility (Interpolation module + Core extensions) rather than monolithic Utils module
- **Qualified imports**: All new code follows CTBase convention of qualified imports without top-level exports
- **Type stability**: Interpolant call methods are type-stable with `@inferred` tests

### 🧹 Maintenance

- **Version bump**: Bumped to 0.19.0-beta for feature release.

## [0.18.15-beta] - 2026-06-06

### 📚 Documentation

#### **Philosophy Documentation**

- **Added philosophy documentation**: Added comprehensive code philosophy documentation in `dev/philosophy/`
  - `modules.md`: Submodule organization, imports/qualification, DAG, exports
  - `types-traits-interfaces.md`: Types vs traits, interfaces/contracts, SOLID/DRY/YAGNI, type stability
  - `exceptions.md`: The 7 exceptions and the choice rule
  - `docstrings.md`: Docstring templates, cross-references, example safety
  - `testing.md`: Categories, fakes/stubs, module + callable function template
  - `documentation.md`: API generation, guides, draft workflow
- **Added agent guides**: Added `AGENTS.md` (agent navigation guide) and `CLAUDE.md` (Claude project context)
- **Added planning template**: Added `dev/PLAN.md` for implementation plans
- **Added operational rules**: Added `dev/RULES.md` for MCP, doc build, git, and output capture procedures

#### **Documentation Build Improvements**

- **Faster builds**: Changed `docs/make.jl` from `Pkg.activate/instantiate` to `pushfirst!(LOAD_PATH, ...)` for faster builds
- **Fixed cross-references**: Fixed unresolved `@ref` links for extension tags (AbstractCoveragePostprocessingTag, TestRunnerTag, AbstractTestRunnerTag)
- **Added examples**: Added example code blocks for extension tags in docstrings
- **Refactored docstrings**: Rewrote ExtensionError and SolverFailure docstrings with `$(TYPEDEF)`, standardized sections, and cross-references

### 🐛 Bug Fixes

#### **TestRunner Auto-Discovery**

- **Fixed non-recursive discovery**: Fixed test discovery in auto-discovery mode to use `_collect_test_files_recursive` instead of flat `readdir`
- **Impact**: Tests in subdirectories were silently ignored in auto-discovery mode; now properly collected recursively

#### **Typed Exceptions (Tenet 6)**

- **Replaced untyped errors**: Replaced all `error()` and `ArgumentError` with structured CTBase exceptions across `ext/` files
  - `ext/TestRunner.jl`: 7 replacements (IncorrectArgument, PreconditionError)
  - `ext/CoveragePostprocessing.jl`: 4 replacements (PreconditionError)
  - `ext/DocumenterReference.jl`: 2 replacements (IncorrectArgument)
- **Fixed invalid Julia syntax**: Fixed 2 occurrences of `catch e::CTBase.Exceptions.CTException` → `catch e` + `e isa ... || rethrow()`
- **Fixed docstring output**: Corrected incorrect output in `_progress_bar` docstring (width=20 → 10 blocks)
- **Updated tests**: Updated 7 test files to reflect new exception types

### 🧹 Code Quality

#### **Import Qualification**

- **Qualified imports**: Changed `using DocStringExtensions` to `import DocStringExtensions: TYPEDEF, TYPEDSIGNATURES` in all submodules
- **Qualified Coverage import**: Changed `using Coverage` to `using Coverage: Coverage` in CoveragePostprocessing
- **Removed circular import**: Removed `using CTBase` from src/Exceptions/Exceptions.jl
- **Removed redundant imports**: Removed redundant `using DocStringExtensions` from src/Descriptions/types.jl

#### **Code Cleanup**

- **Removed dead ternary branches**: Simplified `_normalize_selections` and `_builder_to_string` in TestRunner
- **Fixed byte-indexing**: Changed path slicing from byte-indexing to `relpath()` in CoveragePostprocessing
- **Fixed collision risk**: Normalized flat names in cov file flattening to prevent collisions

### 🧪 Testing

- **All tests pass**: 1161/1161 tests pass
- **Documentation builds**: Documentation builds successfully with no extension errors

### 🧹 Maintenance

- **Version bump**: Bumped to 0.18.15-beta for development.

## [0.18.14-beta] - 2026-05-30

### ✨ New Features

#### **TestRunner Progress Display Refactoring**

- **Parameter rename**: Renamed `progress` to `show_progress_line` for clearer semantics
- **Granular control**: Added `show_progress_bar` parameter to control only the graphical bar `[█░░░...]`
- **Minimal display**: Users can now set `show_progress_line=true, show_progress_bar=false` to display `✓ [01/76] suite/test.jl (0.2s)` without the graphical bar
- **Parameter rename**: Renamed `full_bar_threshold` to `progress_bar_threshold` for consistency with new naming scheme
- **Documentation updated**: TestRunner guide updated with new parameter names and examples
- **Tests updated**: Added tests for `show_progress_bar=false` behavior

### 🧹 Maintenance

- **Version bump**: Bumped to 0.18.14-beta for development.

## [0.18.13-beta] - 2026-05-30

### ✨ New Features

#### **TestRunner Cursor-Style Progress Bar**

- **Cursor-style display**: Progress bar now uses cursor-style where only the current test position is filled for successes
- **Persistent error markers**: Failures and skips remain visible at their original positions while successes are ephemeral
- **Lighter visual**: Creates a cleaner, less cluttered display that's easier to scan
- **Compressed mode**: Single cursor block advances without repetition in compressed mode
- **Documentation updated**: TestRunner guide updated with cursor-style examples

### 🧹 Maintenance

- **Version bump**: Bumped to 0.18.13-beta for development.

## [0.18.12-beta] - 2026-05-30

### ✨ New Features

#### **TestRunner Progress Bar Customization**

- **Configurable threshold**: Added `full_bar_threshold` parameter to `CTBase.Extensions.run_tests` (default: 50)
- **Flexible display**: Users can now customize the maximum number of tests for full-resolution progress bar
- **Terminal adaptation**: Smaller thresholds for narrow terminals, larger for wide displays
- **Internal propagation**: Parameter propagated to `_make_default_on_test_done`, `_format_progress_line`, and `_bar_width`
- **Documentation updated**: TestRunner guide updated with examples and threshold explanation
- **Test coverage**: Added 14 unit tests for custom threshold behavior

### 🧹 Maintenance

- **Version bump**: Bumped to 0.18.12-beta for development.

## [0.18.11-beta] - 2026-05-17

### 🐛 Bug Fixes

#### **Coverage Report Filtering**

- **Fixed file filtering**: Coverage reports now only include files with actual .cov data
- **Removed spurious 0% entries**: Files without coverage data no longer appear in reports
- **Helper function added**: `_get_pid_suffix` extracts PID suffix from .cov file paths for matching
- **Improved accuracy**: Global coverage percentages now reflect only tested files

### 🧹 Maintenance

- **Version bump**: Bumped to 0.18.11-beta for development.

## [0.18.10-beta] - 2026-05-17

### 🧹 Maintenance

- **Version bump**: Bumped to 0.18.10-beta for development. No functional changes.

## [0.18.9-beta] - 2026-05-17

### ✨ New Features

#### **Coverage Post-Processing Options**

- **Configurable report limits**: Added `worst_n_files::Int=20` and `max_uncovered_lines::Int=200` keyword arguments to `postprocess_coverage`
- **Backward compatibility**: Default values maintain existing behavior
- **Input validation**: Throws `IncorrectArgument` for invalid values (≤ 0)
- **Configurable constants**: Added `WORST_N_FILES` and `MAX_UNCOVERED_LINES` constants in `test/coverage.jl` for easy customization

### 🧪 Testing

- **Comprehensive test coverage**: Added tests for coverage post-processing options
  - Default behavior tests (verifies 20/200 limits)
  - Custom `worst_n_files` tests (verifies limit enforcement)
  - Custom `max_uncovered_lines` tests (verifies limit enforcement)
  - Invalid option tests (verifies `IncorrectArgument` for 0 and negative values)
- **All tests passing**: 1141 tests pass including 6 new tests for coverage options

### 📦 API Changes

- **Extensions module**: Extended `postprocess_coverage` signature with new keyword arguments
- **CoveragePostprocessing extension**: Updated backend implementation to use configurable limits

## [0.18.8] - 2026-05-04

### ✨ New Features

#### **SolverFailure Exception**

- **New exception type**: Added `SolverFailure` exception for reporting solver/integrator failures across the toolbox
- **Generic retcode support**: Accommodates different solver types (SciML integrators, NLP solvers, linear solvers)
  - SciML: `:Unstable`, `:DtLessThanMin`, `:MaxIters`
  - NLP: `:Infeasible`, `:MaxIterations`, `:Stalled`
  - Linear: condition number indicators, singular matrix flags
- **Enriched context**: Fields for `retcode`, `suggestion`, and `context` to provide actionable error information
- **User-friendly display**: Emoji-based display with 🔧 for return codes
- **Cross-package utility**: Suitable for use across CTFlows, CTDirect, and other control-toolbox packages

#### **Documentation Updates**

- **Exception guide**: Added comprehensive `SolverFailure` section to `docs/src/guide/exceptions.md`
- **Hierarchy update**: Updated exception hierarchy diagram to include `SolverFailure`
- **Quick reference**: Added `SolverFailure` to decision table for exception selection
- **Usage examples**: Provided examples for ODE integration, optimization, and linear solver failures

### 🧪 Testing

- **Comprehensive test coverage**: Added tests for `SolverFailure` in all test suites
  - `test_types.jl`: Hierarchy and construction tests
  - `test_display.jl`: Display tests (minimal, full fields, edge cases)
  - `test_exceptions.jl`: Exception throwing and output tests
- **All tests passing**: 315 tests pass including 15 new tests for `SolverFailure`

### 📦 API Changes

- **Exception module**: Exported `SolverFailure` from `CTBase.Exceptions`
- **Display module**: Added display logic in `format_user_friendly_error` and `Base.showerror`

## [0.18.7] - 2026-03-31

### 🧹 Maintenance

#### **Version Stabilization**

- **Stable release**: Bumped from 0.18.6-beta to 0.18.7 for stable release
- **No functional changes**: Version promotion only, all features from 0.18.6-beta preserved

#### **Code Quality**

- **Code formatting**: Applied JuliaFormatter across the codebase for consistent style
- **Standardized formatting**: Improved readability and maintainability

#### **Infrastructure**

- **CI improvements**: Enhanced CompatHelper workflow with subdirs input
- **Better dependency management**: More robust compatibility checking

## [0.18.6-beta] - 2026-03-17

### 🛠 Enhancements

#### **Documenter Color Compatibility**

- **ANSI escape sequence support**: Added ANSI color formatting for exception display in generated documentation
- **Replaced printstyled calls**: Migrated from `printstyled()` to raw ANSI escape sequences in `src/Exceptions/display.jl`
- **Automatic CSS conversion**: Documenter now automatically converts ANSI sequences to CSS classes for web display
- **Helper functions**: Added `_ansi_color()`, `_ansi_reset()`, and `_print_ansi_styled()` for consistent color formatting
- **Type support**: Extended color formatting to support `String`, `Symbol`, and `Type` inputs

#### **Testing Updates**

- Updated exception display tests to verify ANSI output format
- All tests pass with new ANSI color implementation (106/106)

### 🧹 Maintenance

- Version bump to 0.18.6-beta for feature enhancement

## [0.18.5] - 2026-03-09

### 🧹 Maintenance

#### **Documentation Reference Fixes**

- Fixed cross-reference syntax in docstrings by removing unnecessary `@ref` macros
- Updated references in `src/Exceptions/types.jl` for cleaner documentation links
- Updated references in `src/Descriptions/` module files for consistency
- Updated references in extension files (`ext/TestRunner.jl`, `ext/DocumenterReference.jl`, `ext/CoveragePostprocessing.jl`)
- Improved documentation rendering and link consistency across the codebase

#### **Version Update**

- Bumped version to 0.18.5 for maintenance release

## [0.18.4] - 2026-03-02

### 🧹 Maintenance & Documentation

#### **Test Artifacts Cleanup**

- Removed `test/extras/` directory containing progress bar demos and example scripts
- Removed `test/src/` temporary artifacts from Documenter testing
- Updated `.gitignore` to exclude `test/_test_*/` pattern for temporary test artifacts
- Improved repository hygiene by removing 2286 lines of test artifacts

### 📚 Documentation

#### **TestRunner Internal Documentation**

- Added comprehensive docstrings for internal TestRunner helper functions
- Documented `_FULL_BAR_THRESHOLD` constant and its purpose for progress bar resolution
- Added detailed documentation for severity mapping functions (`_severity`, `_color_for_severity`, `_block_char_for_severity`)
- Documented backward compatibility shim `_default_on_test_done` with usage guidance

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

## [0.17.4] - Previous Release

### 📝 Previous Changes

- Stable version with basic exception handling
- Simple description management
- Basic Unicode utilities
- Foundation for Control Toolbox ecosystem

---

*For older versions, please refer to the git commit history.*
