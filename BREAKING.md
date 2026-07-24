<!-- markdownlint-disable MD024 -->
# Breaking Changes

This document outlines all breaking changes introduced in CTBase v0.18.0-beta compared to v0.17.4. Use this guide to migrate your code and understand the impact of these changes.

## Non-breaking note (0.28.5-beta)

- **`Data`: new `PseudoHamiltonianVectorField` / `AbstractPseudoHamiltonianVectorField`
  data type.** Purely additive: two new exported symbols in `CTBase.Data`
  (`AbstractPseudoHamiltonianVectorField`, `PseudoHamiltonianVectorField`),
  no changes to any existing type, signature, or exported symbol. **No
  breaking change**: existing code is entirely unaffected. No migration
  required.

## Non-breaking note (0.28.4-beta)

- **`Strategies`: Tip line in `show` now displays the parameterized type
  name.** The `Base.show(io, MIME"text/plain", strategy)` method previously
  used `type_name` (`nameof(T)`) in the Tip message, causing parameterized
  instances like `DifferentiationInterface{GPU}()` to show
  `describe(DifferentiationInterface)` instead of
  `describe(DifferentiationInterface{GPU})`. The fix replaces `type_name`
  with `display_name`, which already includes the parameter. **No breaking
  change**: purely a display fix with no API or behavior change beyond the
  corrected Tip text. No migration required.

## Non-breaking note (0.28.3-beta)

- **`Differentiation`: `build_ad_backend` removed from the public API.**
  The function was a trivial wrapper around `DifferentiationInterface(;
  kwargs...)` with identical semantics. **No breaking change in practice**:
  the method was not used anywhere in the ecosystem (CTBase, CTFlows, etc.).
  Callers replace `build_ad_backend(; kwargs...)` →
  `DifferentiationInterface(; kwargs...)`. The internal no-arg
  `__ad_backend()` is also removed (not exported, not used outside
  `default.jl`); the parameterized `__ad_backend(::Type{CPU})` and
  `__ad_backend(::Type{GPU})` variants are retained.
  - **No migration required** for code that already uses
    `DifferentiationInterface()` directly.

## Non-breaking note (0.28.2-beta)

- **`Differentiation`: GPU default `:ad_backend` changed from `AutoZygote()`
  to `AutoMooncake()`** (roadmap-v4 §5 phase 4e, measured on an H200 — see
  `CHANGELOG.md`). The option name, override mechanism, and `computed=true`
  flag are all unchanged; only the *computed default value* on the opt-in
  `GPU` parameter changes. **No breaking change**: any caller already
  overriding `:ad_backend` explicitly — including to `AutoZygote()` — is
  unaffected, and the change is invisible to every CPU (default) caller. No
  new dependency (`ADTypes.AutoMooncake()` is a marker type from `ADTypes`,
  already a hard dep, same as `AutoZygote()` before it).

## Non-breaking note (0.28.1-beta)

- **`Differentiation`: `DifferentiationInterface` parameterized on the
  execution device.** The struct gains a leading device parameter
  `DifferentiationInterface{P<:Union{CPU,GPU},O}`, along the
  `Exa`/`MadNLP`/`SciML{P}` pattern (phase 1b of the CTFlows GPU roadmap).
  `DifferentiationInterface() ≡ DifferentiationInterface{CPU}`, so **every
  current caller is unaffected**. `parameter` extracts `P` (overriding the
  `AbstractADBackend` family default of `nothing`); `default_parameter = CPU`.
  Per-device `metadata` defaults derive `:ad_backend` from `P` via
  `__ad_backend(P)` (`CPU → AutoForwardDiff()`, `GPU → AutoZygote()`) and are
  flagged `computed=true`. No new dependency (`ADTypes.AutoZygote()` is a
  marker type from `ADTypes`, already a hard dep).
  - **No breaking changes**: purely additive parameterization with a
    default-preserving bare constructor. No migration required.

## Breaking changes (0.28.0-beta)

- **`Strategies`: `get_parameter_type` removed; `parameter` contract method added;
  `_default_parameter` renamed to `default_parameter`.**

  The `get_parameter_type` function was a `@generated` function that extracted
  the type parameter from a strategy type by inspecting `T.parameters` —
  fragile, assumption-heavy, and leaky. It has been replaced by an explicit
  contract method.

  **What changed:**

  - `get_parameter_type(::Type{T})` is **removed** from the public API and is
    no longer exported.
  - A new `parameter(::Type{<:S})` contract method is added to
    `AbstractStrategy`. Every concrete strategy **must** implement it:
    - Non-parameterized: `Strategies.parameter(::Type{<:MyStrategy}) = nothing`
    - Parameterized:
      `Strategies.parameter(::Type{<:MyStrategy{P}}) where {P<:Strategies.AbstractStrategyParameter} = P`
    - The default stub throws `Exceptions.NotImplemented` so any strategy
      that forgets to implement it fails loudly at load time.
  - `_default_parameter` is **renamed** to `default_parameter` (public API,
    now exported).
  - `parameter` and `default_parameter` are now exported from
    `CTBase.Strategies`.
  - `AbstractADBackend` (and all concrete AD backends) now implement
    `parameter(::Type{<:AbstractADBackend}) = nothing` explicitly.

  **Migration:**

  ```julia
  # Before — no explicit parameter method required
  Strategies._default_parameter(::Type{<:MadNLP}) = Strategies.CPU

  # After — implement parameter + rename default_parameter
  Strategies.parameter(::Type{<:MadNLP{P}}) where {P<:Strategies.AbstractStrategyParameter} = P
  Strategies.default_parameter(::Type{<:MadNLP}) = Strategies.CPU
  ```

  For non-parameterized strategies, add:

  ```julia
  Strategies.parameter(::Type{<:MyStrategy}) = nothing
  ```

## Non-breaking note (0.27.7-beta)

- **Performance tooling pass**: `JET.jl` and `BenchmarkTools.jl` added as
  test-only dependencies (not runtime dependencies). `JET.test_package` is
  now enabled for real in the test suite (previously commented out), and a
  new `test/suite/meta/test_performance.jl` asserts allocation invariants
  on the hot path. Two latent bugs the JET scan found are fixed:
  `_strategy_type_name(::UnionAll)` (`Strategies`) no longer calls the
  non-existent `nameof(::TypeVar)`, and `OptionValue`'s constructor no
  longer goes through a `Val`-dispatch pattern that was both a JET
  analysis blind spot and a genuine type instability whenever `source`
  wasn't a literal — both are internal implementation details with
  identical external behavior (same values constructible, same error
  messages). New `docs/src/guide/performance.md` guide.
  - **No breaking changes**: purely additive tooling, tests, and
    documentation; two internal bug fixes with no observable behavior
    change for valid usage. No migration required.
- **Plotting**: added docstrings for previously-undocumented private show
  helpers (`_SHOW_LIMIT`, `_show_axes`, `_show_node`). No API or behavior
  change.

## Non-breaking note (0.27.6-beta)

- **`Data`: `Hamiltonian`, `PseudoHamiltonian`, `ControlLaw`, `PathConstraint`,
  `Multiplier`, `ControlledVectorField` now formally satisfy `Struct <:
  AbstractParent`** (e.g. `Hamiltonian <: AbstractHamiltonian`), which was
  `false` before this release even though it should always have held. No
  valid CTBase usage is affected — every value that could be constructed
  before still constructs identically, since the bound was already enforced
  dynamically via the supertype check.

  **Action for downstream packages** (e.g. CTFlows.jl): if you dispatch on
  any of these 6 types (or `VectorField`/`HamiltonianVectorField`, whose
  bound was already correct) with your **own** `where {...}` clause that
  leaves `TD`, `VD` (or `FB`, `K`) unbounded — e.g.
  `f(h::Data.Hamiltonian{F,TD,VD}) where {F<:Function,TD,VD}` — that
  `where`-clause's ground truth has changed: `TD,VD` are now genuinely
  bounded on `Hamiltonian` itself, so leaving them unbounded downstream is no
  longer "matching what CTBase declares", it is *wider* than what CTBase
  declares. This can silently mis-rank method specificity or throw
  `MethodError: ... is ambiguous` if you have a second, more generic method
  competing on the same call — the same failure mode described in
  `CTBase/.reports/2026-07-12_alias-where-bounds-audit.md` and
  `CTFlows.jl/.reports/2026-07-11_alias-where-bounds-audit.md`. Re-run the two
  greps from the Handbook (`philosophy/types-traits-interfaces.md`) against
  your package and restate the now-correct bound in any such `where` clause.

## Breaking changes (0.27.5-beta)

- **`Interpolation`: `LinearInterpolant` and `ConstantInterpolant` aliases removed.**
  The type aliases `LinearInterpolant = Interpolant{Linear}` and
  `ConstantInterpolant = Interpolant{Constant}` have been deleted from
  `CTBase.Interpolation` and are no longer exported.

  **Migration:** replace `LinearInterpolant` → `Interpolant{Linear}` and
  `ConstantInterpolant` → `Interpolant{Constant}`.

  ```julia
  # before
  interp = CTBase.Interpolation.ctinterpolate(x, f)
  interp isa CTBase.Interpolation.LinearInterpolant

  # after
  interp = CTBase.Interpolation.ctinterpolate(x, f)
  interp isa CTBase.Interpolation.Interpolant{CTBase.Interpolation.Linear}
  ```

## Breaking changes (0.25.0-beta)

- **`NotProvided` / `NotProvidedType` removed from `CTBase.Options`.** They now live and are
  exported **only** in `CTBase.Core`. `CTBase.Options.NotProvided` and
  `CTBase.Options.NotProvidedType` no longer exist, and `using CTBase.Options` no longer
  brings these names into scope.

  **Migration:** replace `Options.NotProvided` → `Core.NotProvided` and
  `Options.NotProvidedType` → `Core.NotProvidedType` (fully qualified: `CTBase.Core.NotProvided`).

  ```julia
  # before
  using CTBase.Options
  OptionDefinition(name=:x, type=Int, default=NotProvided)

  # after
  import CTBase.Core
  using CTBase.Options
  OptionDefinition(name=:x, type=Int, default=Core.NotProvided)
  ```

- `NotStored` / `NotStoredType` are unchanged and remain extraction-internal to
  `CTBase.Options` (the defining file was renamed `not_provided.jl` → `not_stored.jl`).

## Non-breaking note (0.26.3-beta)

- **Data**: New `ControlledVectorField` and `ComposedVectorField` data types added
  - **ControlledVectorField**: controlled vector field `fc(t, x, u[, v])` with an explicit control argument; `AbstractControlledVectorField` supertype and `ControlledVectorField` concrete struct; state-space analogue of `PseudoHamiltonian`; always out-of-place (no mutability trait); `dynamics_trait = StateDynamics`
  - **ComposedVectorField**: vector field `g(t, x, v) = fc(t, x, u(...), v)` composing a `ControlledVectorField` with an `OpenLoop` or `ClosedLoop` control law; subtypes `AbstractVectorField` with `OutOfPlace` mutability; state-space analogue of `ComposedHamiltonian`
  - **Trait joins**: composed time/variable dependences are the join of the two inputs (`NonAutonomous`/`NonFixed` win), computed at construction time
  - **Functor**: natural and uniform `(t, x, v)` call signatures
  - **Getters**: `controlled_vector_field(g)` and `control_law(g)`
  - **Constructor rejects `DynClosedLoop` laws**: that is the Hamiltonian path (`ComposedHamiltonian`)
  - **No breaking changes**: Purely additive. Existing data types unchanged.

## Non-breaking note (0.26.2-beta)

- **Data**: New `ComposedHamiltonian` data type added
  - **ComposedHamiltonian**: Hamiltonian `H(t, x, p, v) = H̃(t, x, p, u(t, x, p, v), v)` obtained by composing a `PseudoHamiltonian` with a `DynClosedLoop` control law; subtypes `AbstractHamiltonian`
  - **Trait joins**: composed time/variable dependences are the join of the two inputs (`NonAutonomous`/`NonFixed` win), computed at construction time
  - **Functor**: natural and uniform `(t, x, p, v)` call signatures
  - **Getters**: `pseudo_hamiltonian(H)` and `control_law(H)`
  - **No breaking changes**: Purely additive. Existing data types unchanged.
- **Differentiation**: New `pseudo_variable_gradient` method added
  - `pseudo_variable_gradient(backend, h̃, t, x, p, u, v) → ∂H̃/∂v`: partial derivative with control `u` held constant
  - **No breaking changes**: Purely additive. Existing gradient methods unchanged.

## Non-breaking note (0.26.1-beta)

- **Traits**: New `Feedback` trait family added for encoding how a control law closes the loop
  - **New trait family**: `AbstractFeedback` with tags `OpenLoopFeedback`, `ClosedLoopFeedback`, `DynClosedLoopFeedback`
  - **Type-parameter-only contract**: trait value read from a type parameter by the `feedback` accessor; no `has_feedback_trait` guard
  - **Derived predicates**: `is_open_loop(obj)`, `is_closed_loop(obj)`, `is_dyn_closed_loop(obj)`
  - **No breaking changes**: Purely additive. Existing code unaffected.
- **Data**: New `PseudoHamiltonian` and `ControlLaw` data types added
  - **PseudoHamiltonian**: scalar function `H̃(t, x, p, u[, v]) → ℝ` with explicit control argument; `AbstractPseudoHamiltonian` supertype and `PseudoHamiltonian` concrete struct
  - **ControlLaw**: control law function `u(⋯) → 𝒰` with feedback trait; `AbstractControlLaw` supertype, `ControlLaw` concrete struct, and `OpenLoop`/`ClosedLoop`/`DynClosedLoop` user-facing constructors
  - **No breaking changes**: Purely additive. Existing data types unchanged.
- **Differentiation**: New pseudo-Hamiltonian gradient methods added
  - `pseudo_hamiltonian_gradient(backend, h̃, t, x, p, u, v) → (∂H̃/∂x, ∂H̃/∂p)`
  - `pseudo_hamiltonian_control_gradient(backend, h̃, t, x, p, u, v) → ∂H̃/∂u`
  - **No breaking changes**: Purely additive. Existing gradient methods unchanged.

## Non-breaking note (0.26.0-beta)

- **Traits**: New `ControlDependence` family added for encoding control presence in optimal control problems
  - **New trait family**: `ControlDependence` with tags `ControlFree` and `WithControl`
  - **Opt-in contract**: types implement `has_control_dependence_trait` and `control_dependence`
  - **Derived predicates**: `is_control_free(obj)` and `has_control(obj)`
  - **Internal refactoring**: shared helpers for strict-contract error handling reduce duplication; error messages and behaviour are unchanged
  - **No breaking changes**: Purely additive. Existing code unaffected. New trait enables dispatch in downstream packages (CTModels, CTFlows).

## Non-breaking note (0.24.0-beta)

- **Differentiation module**: Added comprehensive AD backend infrastructure for computing gradients
  - **AbstractADBackend**: Abstract contract for AD backends with trait-based dispatch
  - **DifferentiationInterface strategy**: Concrete strategy wrapping DifferentiationInterface.jl backends (e.g., `AutoForwardDiff()`)
  - **Hamiltonian gradient computation**: `hamiltonian_gradient(backend, h, t, x, p, v)` → (∂H/∂x, ∂H/∂p)
  - **Variable gradient computation**: `variable_gradient(backend, h, t, x, p, v)` → ∂H/∂v
  - **Generic differentiation methods**: `gradient`, `derivative`, `differentiate`, `pushforward` for flexible AD operations
  - **ADTypes integration**: Hard dependency on ADTypes.jl with `AutoForwardDiff` as default backend
  - **DifferentiationInterface extension**: CTBaseDifferentiationInterface extension for gradient computation
  - **Construction defaults**: `__ad_backend` for trait-based backend selection
  - **Full test coverage**: Comprehensive test suite for Differentiation module
  - **Documentation**: Complete Differentiation module guide in `docs/src/guide/differentiation.md`
  - **Migration from CTFlows**: AD backend strategies moved from CTFlows to CTBase for ecosystem-wide sharing
  - **Self-contained module**: CTBase.Differentiation depends on CTBase.Data, CTBase.Strategies, CTBase.Exceptions, and ADTypes
  - **No breaking changes**: Purely additive feature with backward-compatible API. No migration required.
- **Dependencies**: Added ADTypes.jl as hard dependency and DifferentiationInterface.jl as weak dependency with extension
- **No breaking changes**: Purely additive feature with new dependencies. No migration required.

## Non-breaking note (0.23.0-beta)

- **Data module**: Added comprehensive data structures for vector fields and Hamiltonian systems
  - **VectorField**: Encapsulates vector-field functions with time-dependence and variable-dependence traits
  - **AbstractVectorField**: Abstract base type for vector fields
  - **Hamiltonian**: Hamiltonian function representation with traits
  - **AbstractHamiltonian**: Abstract base type for Hamiltonians
  - **HamiltonianVectorField**: Hamiltonian vector field combining Hamiltonian and vector field concepts
  - **AbstractHamiltonianVectorField**: Abstract base type for Hamiltonian vector fields
  - **Construction defaults**: `__is_autonomous`, `__is_variable`, `__is_inplace` for trait-based construction
  - **Helper functions**: Utilities for working with vector fields and Hamiltonians
  - **Full test coverage**: Comprehensive test suite for Data module
  - **Documentation**: Complete Data module guide in `docs/src/guide/data.md`
  - **Migration from CTFlows**: Vector fields and Hamiltonian structures moved from CTFlows to CTBase for ecosystem-wide sharing
  - **Self-contained module**: CTBase.Data depends only on CTBase.Traits and CTBase.Exceptions
  - **No breaking changes**: Purely additive feature with backward-compatible API. No migration required.
- **Documentation improvements**: Reordered Core Concepts sidebar by conceptual layers
- **Test runner improvements**: Renamed TestOptions to TestData for clarity
- **No breaking changes**: Purely documentation and test improvements. No migration required.

## Non-breaking note (0.22.0-beta)

- **Traits module**: Added comprehensive trait system for type-level dispatch across control-toolbox ecosystem
  - **Time dependence traits**: `TimeDependence`, `Autonomous`, `NonAutonomous` for distinguishing autonomous vs non-autonomous systems
  - **Variable dependence traits**: `VariableDependence`, `Fixed`, `NonFixed` for systems with/without variable parameters
  - **Mutability traits**: `AbstractMutabilityTrait`, `InPlace`, `OutOfPlace` for in-place vs out-of-place evaluation
  - **Mode traits**: `AbstractModeTrait`, `EndPointMode`, `TrajectoryMode` for point-to-point vs trajectory integration
  - **Dynamics traits**: `AbstractDynamicsTrait`, `StateDynamics`, `HamiltonianDynamics`, `AugmentedHamiltonianDynamics` for dynamics type specification
  - **AD traits**: `AbstractADTrait`, `WithAD`, `WithoutAD` for automatic differentiation capability
  - **Variable costate traits**: `AbstractVariableCostateCapability`, `SupportsVariableCostate`, `NoVariableCostate` for costate variable support
  - **Abstract trait base**: `AbstractTrait` as root of trait hierarchy
  - **Helper functions**: Boolean predicates (`is_autonomous`, `is_variable`, `is_inplace`, etc.) and trait query functions
  - **Full test coverage**: 1138+ tests across all trait modules
  - **Documentation**: Complete trait system guide in `docs/src/guide/traits.md`
  - **Migration from CTFlows**: Traits moved from CTFlows to CTBase for ecosystem-wide sharing
  - **No breaking changes**: Purely additive feature with backward-compatible API. No migration required.
- **Docstring compliance**: Fixed all docstring cross-references in Traits and Strategies modules
  - Added full module paths to all internal `@ref` references
  - Changed `@extref` to `@ref` for internal symbols
  - Removed CTFlows references from trait docstrings
  - **No breaking changes**: Purely documentation improvements. No migration required.

## Non-breaking note (0.21.1-beta)

- **Module renamed**: `CTBase.Extensions` → `CTBase.DevTools`
  - The submodule previously named `Extensions` is now named `DevTools` to better reflect its purpose (internal developer tools, not a general extension system)
  - All tag types and functions are unchanged: `run_tests`, `postprocess_coverage`, `automatic_reference_documentation`, `AbstractTestRunnerTag`, `TestRunnerTag`, `AbstractDocumenterReferenceTag`, `DocumenterReferenceTag`, `AbstractCoveragePostprocessingTag`, `CoveragePostprocessingTag`
  - **Migration**: replace `CTBase.Extensions` with `CTBase.DevTools` and `import CTBase.Extensions` with `import CTBase.DevTools` at all call sites
- **Core utilities**: Added generic building blocks to CTBase.Core for sharing across control-toolbox ecosystem
  - `AbstractCache`: abstract base type for computation caches (e.g. prepared AD plans), exported from Core
  - `make_coerce`: shape-matching coercion helper (`only` for scalars, `identity` for arrays), exported from Core
  - Both moved from CTFlows to CTBase for reuse across packages
  - No breaking changes; purely additive public API. No migration required.

## Non-breaking note (0.21.0-beta)

- **Configurable color palette system**: Added flexible color palette system for terminal output customization
  - New `Style` and `Palette` types for ANSI color management in `Core/palette.jl`
  - Three built-in palettes: `DEFAULT` (standard colors), `MONOCHROME` (grayscale), `HIGH_CONTRAST` (accessibility-focused)
  - Runtime palette switching via `set_palette!(palette)` and `reset_palette!()`
  - Fine-grained color customization with `set_color!(role, color)` for specific semantic roles
  - Visual palette preview with `show_palette()` to display current palette configuration
  - Updated all display paths (Core, Exceptions, TestRunner) to use active palette
  - Comprehensive test coverage in `test/suite/core/test_palette.jl` (259 tests)
  - Documentation guide in `docs/src/guide/color-system.md`
  - No breaking changes; purely additive feature with backward-compatible defaults. No migration required.
- **CTSolvers infrastructure**: Moved CTSolvers core infrastructure to CTBase
  - Added `Strategies` module with options, orchestration, and strategy abstractions
  - Provides foundational infrastructure for solver selection and configuration
  - No breaking changes; purely internal addition. No migration required.
- **Documentation structure refactor**: Moved `dev/` directory to control-toolbox/Handbook repository
  - `AGENTS.md` and `CLAUDE.md` rewritten to redirect Developer Resources to Handbook
  - Added `README.md` in `src/`, `ext/`, `test/`, `docs/` with package-specific context
  - All READMEs point to control-toolbox Handbook for conventions
  - No breaking changes; purely documentation reorganization. No migration required.
- **README update**: Updated README with latest ABOUT.md, INSTALL.md, CONTRIBUTING.md and badges
  - No breaking changes; purely documentation improvement. No migration required.
- **Typos configuration**: Added `_typos.toml` for spell checking
  - No breaking changes; purely development tooling addition. No migration required.

## Non-breaking note (0.20.0-beta)

- **ANSI display unification**: Centralized all ANSI formatting utilities in `Core/display.jl` to provide a single source of truth for terminal color support
  - Added `_apply_ansi(s, code, io::IO)` base function with color detection
  - Added semantic wrappers: `_dim`, `_bold`, `_red`, `_yellow`, `_green`
  - Fixed `get_format_codes` bug: `supports_color = true` → `get(io, :color, false)` (detection was commented out)
  - All ANSI functions remain private (underscore prefix, not exported)
- **AbstractTag organization**: Moved `AbstractTag` from `Core/display.jl` to dedicated `Core/tags.jl` for better module organization
- **Module load order**: Changed `CTBase.jl` to load Core before Exceptions (was stale comment "must load first")
- **Qualified imports**: `Exceptions/display.jl` now uses qualified calls (`Core._dim`, `Core._bold`, etc.) instead of local definitions
- **Testing**: Added `test_core_display.jl` with comprehensive tests for ANSI functions (52 assertions)
- **No breaking changes**: All ANSI functions remain private and unexported; behavior unchanged; purely internal refactoring with bug fix. No migration required.

## Non-breaking note (0.19.0-beta)

- **Interpolation module**: Added new `Interpolation` module with interpolation utilities migrated from CTModels.Utils
  - `ctinterpolate`: linear interpolation with flat extrapolation
  - `ctinterpolate_constant`: piecewise-constant (steppost) interpolation
  - `Interpolant{Linear}` and `Interpolant{Constant}` parametric types with type-stable call methods
  - Custom `show` methods for interpolant display
- **Core utilities**: Extended `Core` module with utilities from CTModels.Utils
  - `matrix2vec`: public utility for matrix-to-vector conversion
  - `to_out_of_place`: private utility for out-of-place function transformation
  - `@ensure`: private macro for argument validation
- **Documentation**: Updated `docs/api_reference.jl` to include new Interpolation module and Core utilities
- **Tests**: Added comprehensive test suites for interpolation (56 tests), function_utils (18 tests), macros (14 tests), and matrix_utils (26 tests)
- **No breaking changes**: All additions are new public API; existing CTBase API unchanged. No migration required.

## Non-breaking note (0.18.15-beta)

- **Philosophy documentation**: Added comprehensive code philosophy documentation in `dev/philosophy/` covering modules, types/traits, exceptions, docstrings, testing, and documentation standards. No API changes; purely documentation additions.
- **Agent guides**: Added `AGENTS.md` and `CLAUDE.md` for agent navigation and project context. No API changes; purely documentation additions.
- **Documentation build improvements**: Changed `docs/make.jl` build method and fixed cross-references. No API changes; purely documentation improvements.
- **Typed exceptions**: Replaced untyped `error()` and `ArgumentError` with structured CTBase exceptions in `ext/` files. No API changes; internal error handling improvement.
- **Import qualification**: Qualified imports in submodules (`using DocStringExtensions` → `import DocStringExtensions: TYPEDEF, TYPEDSIGNATURES`). No API changes; internal code quality improvement.
- **Code cleanup**: Removed dead ternary branches, fixed byte-indexing, removed circular imports. No API changes; internal code quality improvement.
- **TestRunner auto-discovery fix**: Fixed non-recursive test discovery in auto-discovery mode. No API changes; bug fix.
- **Docstring refactoring**: Rewrote ExtensionError and SolverFailure docstrings with `$(TYPEDEF)` and standardized sections. No API changes; documentation improvement.
- **No migration required**: All changes are internal or documentation-only. No breaking changes.

## Non-breaking note (0.18.14-beta)

- **TestRunner progress display refactoring**: Renamed `progress` parameter to `show_progress_line` for clarity, and added new `show_progress_bar` parameter for granular control. Users with `progress=false` should change to `show_progress_line=false`. Users with `progress=true` (default) can keep using defaults or set `show_progress_line=true, show_progress_bar=false` for minimal display without the graphical bar. No breaking changes; purely parameter rename with backward-compatible defaults. Migration: replace `progress=` with `show_progress_line=`.
- **Parameter rename**: Renamed `full_bar_threshold` to `progress_bar_threshold` for clarity and consistency with new naming scheme. Users with `full_bar_threshold=` should change to `progress_bar_threshold=`. No breaking changes; purely parameter rename with backward-compatible defaults. Migration: replace `full_bar_threshold=` with `progress_bar_threshold=`.

## Non-breaking note (0.18.13-beta)

- **TestRunner cursor-style progress bar**: Changed progress bar display to use cursor-style where only the current test position is filled for successes, while failures and skips persist at their positions. This creates a lighter visual with ephemeral successes but persistent error markers. No API changes; purely visual improvement. No migration required.
- **Default threshold increased**: Changed default `full_bar_threshold` from 50 to 100 for better experience on modern wide displays. Users with narrow terminals can still customize via the parameter. No breaking changes; purely default value adjustment. No migration required.

## Non-breaking note (0.18.12-beta)

- **TestRunner progress bar threshold**: Added configurable `full_bar_threshold` parameter to `CTBase.Extensions.run_tests` (default: 50). Allows users to customize the maximum number of tests for full-resolution progress bar display. Propagated to internal functions `_make_default_on_test_done`, `_format_progress_line`, and `_bar_width`. Documentation and tests updated. No breaking changes; purely additive feature with backward-compatible default. No migration required.

## Non-breaking note (0.18.11-beta)

- **Coverage report filtering**: Fixed coverage post-processing to only include files with actual .cov data in reports. Previously, files without coverage data appeared with 0% coverage; now only tested files are shown. No API changes; purely report generation improvement. No migration required.

## Non-breaking note (0.18.10-beta)

- **Version bump**: Bumped to 0.18.10-beta for development. No functional changes; version increment only.

## Non-breaking note (0.18.9-beta)

- **Coverage post-processing options**: Added configurable report limits to `postprocess_coverage` with new keyword arguments `worst_n_files::Int=20` and `max_uncovered_lines::Int=200`. Defaults maintain backward compatibility. Validation throws `IncorrectArgument` for invalid values (≤ 0). No breaking changes; purely additive feature. No migration required.

## Table of Contents

- [Exception System Overhaul](#exception-system-overhaul)
- [Module Reorganization](#module-reorganization)  
- [Extension System Introduction](#extension-system-introduction)
- [Documentation Generation Changes](#documentation-generation-changes)
- [TestRunner Enhancements](#testrunner-enhancements)
- [API Changes](#api-changes)
- [Dependency Updates](#dependency-updates)
- [Migration Guide](#migration-guide)

---

## Non-breaking note (0.18.8)

- **New exception type**: Added `SolverFailure` exception for reporting solver/integrator failures (ODE integration, optimization NLP, linear systems). Includes fields for `retcode`, `suggestion`, and `context`. No breaking changes; purely additive feature. No migration required.

## Non-breaking note (0.18.7)

- **Version stabilization**: Bumped from 0.18.6-beta to 0.18.7 for stable release. No functional changes; version promotion only.
- **Code formatting**: Applied JuliaFormatter to ensure consistent code style across the codebase. No functional changes; formatting only.
- **CI improvements**: Enhanced CompatHelper workflow with subdirs input for better dependency management. No functional changes; CI infrastructure only.
- No breaking changes. No migration required.

## Non-breaking note (0.18.6-beta)

- **Documenter Color Support**: Added ANSI escape sequence support for exception display colors in generated documentation. Replaced `printstyled` calls with ANSI equivalents to enable automatic conversion to CSS classes by Documenter. No API changes; purely internal implementation improvement. No migration required.
- Version bump to 0.18.6-beta for feature enhancement. No breaking changes. No migration required.

## Non-breaking note (0.18.5)

- Documentation reference fixes: removed unnecessary `@ref` macros from cross-references in docstrings across multiple modules and extensions. No API changes; purely documentation improvement. No migration required.
- Version bump to 0.18.5 for maintenance release. No functional changes. No migration required.

## Non-breaking note (0.18.4)

- Test artifacts cleanup: removed `test/extras/` and `test/src/` directories containing demo scripts and temporary build artifacts. No API changes; purely repository hygiene. No migration required.
- Enhanced TestRunner internal documentation with comprehensive docstrings for helper functions. No functional changes; documentation only. No migration required.

## Non-breaking note (0.18.3-beta)

- TestRunner progress bar now keeps full resolution up to 50 tests (previously 20) with cumulative coloring; compressed mode beyond 50 retains uniform bar. No breaking API change; purely visual behavior. No migration required.

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
CTBase.Extensions.run_tests()

# v0.18.0-beta - Requires extension  
using CTBase.Extensions.TestRunner
CTBase.Extensions.run_tests()
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

## Documentation Generation Changes

### 🚨 Enhanced API Documentation System

The DocumenterReference extension has been significantly enhanced with new customization capabilities.

#### Title System Simplification

The API documentation title system has been standardized:

```julia
# v0.18.0-beta (variable titles)
# Different pages had inconsistent title patterns

# v0.18.0-beta.1 (standardized)
# All API pages consistently use:
# - "Public API" for exported functions
# - "Private API" for internal functions
```

#### New Customization Parameters

API documentation generation now supports customizable titles and descriptions:

```julia
# v0.18.0-beta (fixed titles)
automatic_reference_documentation()  # Used default titles

# v0.18.0-beta.1 (customizable)
automatic_reference_documentation(;
    public_title="Custom Public API",
    private_title="Internal Functions",
    public_description="Custom description for public API",
    private_description="Custom description for private API"
)
```

#### Impact Assessment - Documentation Changes

- **Low Impact**: Existing code continues to work with defaults
- **Medium Impact**: Code relying on specific title patterns may need updates
- **Enhancement**: New customization provides better documentation control

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

#### Test Path Handling Changes

Path prefix stripping behavior has been standardized:

```julia
# v0.18.0-beta (explicit paths required)
julia --project -e 'using Pkg; Pkg.test(; test_args=["suite/exceptions"])'

# v0.18.0-beta.1 (automatic stripping)
julia --project -e 'using Pkg; Pkg.test(; test_args=["test/suite"])'  # Same result
```

**Note**: The `test/` prefix is now automatically stripped, making both forms equivalent.

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
See also: `TestRunInfo`  # Header conflicts

# v0.18.0-beta.1 (resolved)
See also: `TestRunner.TestRunInfo`
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
CTBase.Extensions.run_tests()
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
    @test_nowarn CTBase.Extensions.run_tests(dry_run=true)
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
