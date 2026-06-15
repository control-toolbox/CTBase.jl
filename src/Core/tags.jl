"""
    AbstractTag

Abstract type for tag dispatch pattern used to handle extension-dependent implementations.

This type is used for multiple dispatch in validation functions and other contexts
where behavior depends on loaded extensions (e.g., Enzyme, Zygote, CUDA).

# Example
```julia
struct MyTag <: AbstractTag end

function validate_backend(tag::MyTag, backend::Symbol)
    # Tag-specific validation logic
end
```

See also: Extension-based validation patterns in extension modules
"""
abstract type AbstractTag end
