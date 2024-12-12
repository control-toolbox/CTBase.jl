#
const __default_AD_backend = Ref(AutoForwardDiff())

function set_AD_backend(AD)
    global __default_AD_backend[] = AD
    nothing
end

"""
$(TYPEDSIGNATURES)

Used to set the default value of Automatic Differentiation backend.

The default value is `AutoForwardDiff()`, that is the `ForwardDiff` package is used by default.
"""
__get_AD_backend() = __default_AD_backend[] # default AD backend

"""
$(TYPEDSIGNATURES)

Used to set the default value of the stockage of elements in a matrix.
The default value is `1`.
"""
__matrix_dimension_stock() = 1

"""
$(TYPEDSIGNATURES)

Used to set the default value of the display argument.
The default value is `true`, which means that the output is printed during resolution.
"""
__display() = true

"""
$(TYPEDSIGNATURES)

Used to set the default interpolation function used for initialisation.
The default value is `Interpolations.linear_interpolation`, which means that the initial guess is linearly interpolated.
"""
function __init_interpolation()
    return (T, U) ->
        Interpolations.linear_interpolation(T, U, extrapolation_bc = Interpolations.Line())
end