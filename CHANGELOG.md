# Changelog

All notable changes to this project will be documented in this file.

## Unreleased (0.25.0-beta)

### Added

- **Traits**: New `ControlDependence` trait family for encoding control presence in optimal control problems
  - Tags: `ControlFree` (no control) and `WithControl` (with control input)
  - Opt-in contract: implement `has_control_dependence_trait` and `control_dependence`
  - Derived predicates: `is_control_free` and `has_control`
  - Enables downstream dispatch in CTFlows and CTModels for control-problem routing

### Changed

- **Traits**: Refactored strict-contract machinery to eliminate duplication
  - New internal helpers: `_throw_missing_trait` and `_throw_trait_not_implemented`
  - Generalised `_caller_function_name` stacktrace filter for any `has_<family>_trait` predicate
  - All strictfamilies (time-dependence, variable-dependence, mutability, control-dependence) now share the same error handling
  - Collapsed `has_variable` duplicate to direct alias of `is_variable`

- **Documentation**: Updated Traits guide to document the two trait templates (strict opt-in vs default-valued capability)

### Fixed

- **Traits**: API reference now includes `control_dependence.jl` in auto-generated documentation

---

## Previous versions

See git history and release notes for earlier versions.
