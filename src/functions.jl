"""
$(TYPEDEF)

**Fields**

$(TYPEDFIELDS)

Used to define typed methods to make specific calls.

"""
struct _Time
    value::Time
    function _Time(value::Time)
        return new(value)
    end
end
#_Time(times::Times) = _Time.(times)
#_Time(times::StepRangeLen) = _Time.(times)
Base.:(+)(t1::_Time, t2::_Time)::_Time = _Time(t1.value + t2.value)
Base.:(-)(t1::_Time, t2::_Time)::_Time = _Time(t1.value - t2.value)
Base.:(*)(t1::_Time, t2::_Time)::_Time = _Time(t1.value * t2.value)
Base.:(/)(t1::_Time, t2::_Time)::_Time = _Time(t1.value / t2.value)
Base.:(+)(t1::_Time, t2::ctNumber)::_Time = _Time(t1.value + t2)
Base.:(+)(t1::ctNumber, t2::_Time)::_Time = _Time(t1 + t2.value)
Base.:(-)(t1::_Time, t2::ctNumber)::_Time = _Time(t1.value - t2)
Base.:(-)(t1::ctNumber, t2::_Time)::_Time = _Time(t1 - t2.value)
Base.:(*)(t1::_Time, t2::ctNumber)::_Time = _Time(t1.value * t2)
Base.:(*)(t1::ctNumber, t2::_Time)::_Time = _Time(t1 * t2.value)
Base.:(/)(t1::_Time, t2::ctNumber)::_Time = _Time(t1.value / t2)
Base.:(/)(t1::ctNumber, t2::_Time)::_Time = _Time(t1 / t2.value)
Base.:(^)(t::_Time, n::ctNumber)::_Time = _Time(t.value^n)
Base.:(-)(t::_Time) = _Time(-(t.value))
Base.show(io::IO, t::_Time) = print(io, t.value)
Base.show(io::IO, ::MIME"text/plain", t::_Time) = print(io, t.value)
Base.show(io::IO, ::MIME"text/latex", t::_Time) = print(io, t.value)
Base.show(io::IO, ::MIME"text/html", t::_Time) = print(io, t.value)
Base.show(io::IO, ::MIME"text/markdown", t::_Time) = print(io, t.value)
Base.isless(t1::_Time, t2::_Time) = isless(t1.value, t2.value)
Base.isless(t1::_Time, t2::ctNumber) = isless(t1.value, t2)
Base.isless(t1::ctNumber, t2::_Time) = isless(t1, t2.value)
Base.isequal(t1::_Time, t2::_Time) = isequal(t1.value, t2.value)
Base.isequal(t1::_Time, t2::ctNumber) = isequal(t1.value, t2)
Base.isequal(t1::ctNumber, t2::_Time) = isequal(t1, t2.value)

# -------------------------------------------------------------------------------------------
"""
$(TYPEDEF)

Abstract type for functions.
"""
abstract type AbstractCTFunction <: Function end

# -------------------------------------------------------------------------------------------
# pre-condition: f returns a scalar if the output is of dimension 1
"""
$(TYPEDEF)

**Fields**

$(TYPEDFIELDS)

!!! warning

    When the state is of dimension 1, consider `x0` and `xf` as a scalar. When the constraint is dimension 1, return a scalar.

## Classical calls

- state dimension: 1
- constraint dimension: 1

```@example
julia> B = BoundaryConstraint((x0, xf) -> xf - x0)
julia> B(0, 1)
1
julia> B([0], [1])
1-element Vector{Int64}:
 1
```

- state dimension: 1
- constraint dimension: 2

```@example
julia> B = BoundaryConstraint((x0, xf) -> [xf - x0, x0 + xf])
julia> B(0, 1)
2-element Vector{Int64}:
  1
  1
julia> B([0], [1])
ERROR: MethodError: Cannot `convert` an object of type 
  Vector{Any} to an object of type 
  Union{Real, AbstractVector{<:Real}}
```

- state dimension: 2
- constraint dimension: 1
    
```@example
julia> B = BoundaryConstraint((x0, xf) -> xf[1] - x0[1])
julia> B([1, 0], [0, 1])
1
```

- state dimension: 2
- constraint dimension: 2

```@example
julia> B = BoundaryConstraint((x0, xf) -> [x0[1] + xf[2], xf[1] - x0[2]])
julia> B([1, 0], [1, 0])
2-element Vector{Int64}:
 1
 1
```

## Specific calls

When giving a _Time for `t0` and `tf`, the function takes a vector as input for `x0` and
`xf` and returns a vector as output.

!!! warning

    To use the specific call, you must construct the function with the keywords `state_dimension` and `constraint_dimension`.

- state dimension: 1
- constraint dimension: 1

```@example
julia> B = BoundaryConstraint((x0, xf) -> xf - x0, 
    state_dimension=1, constraint_dimension=1)
julia> B(_Time(0), 0, _Time(1), 1)
ERROR: MethodError: no method matching (::BoundaryConstraint{1, 1})(::_Time, ::Int64, 
::_Time, ::Int64)
julia> B(_Time(0), [0], _Time(1), [1])
1-element Vector{Int64}:
 1
```

- state dimension: 1
- constraint dimension: 2

```@example
julia> B = BoundaryConstraint(x0, xf) -> [xf - x0, x0 + xf], 
    state_dimension=1, constraint_dimension=2)
```

- state dimension: 2
- constraint dimension: 1

```@example
julia> B = BoundaryConstraint((x0, xf) -> xf[1] - x0[1], 
    state_dimension=2, constraint_dimension=1)
```

- state dimension: 2
- constraint dimension: 2

```@example
julia> B = BoundaryConstraint((x0, xf) -> [xf[2], xf[1] - x0[2]], 
    state_dimension=2, constraint_dimension=2)
julia> B([1, 0], [1, 0])
2-element Vector{Int64}:
 1
 1
```
"""
struct BoundaryConstraint{state_dimension, constraint_dimension}
    f::Function
    function BoundaryConstraint(f::Function; 
        state_dimension::Union{Symbol,Dimension}=__state_dimension(), 
        constraint_dimension::Union{Symbol,Dimension}=__constraint_dimension())
        new{state_dimension, constraint_dimension}(f)   # in the case of one dimension is 0, the user must be coherent
                                                        # that is one dimensional input or output must be scalar
    end
end

# classical call
function (F::BoundaryConstraint{N, K})(x0::Union{ctNumber, State}, 
        xf::Union{ctNumber, State}, args...; kwargs...)::Union{ctNumber, ctVector} where {N, K}
    return F.f(x0, xf, args...; kwargs...)
end

# specific calls: inputs and outputs are vectors, except times
function (F::BoundaryConstraint{1, 1})(x0::State, xf::State, args...; kwargs...)::ctVector
    return [F.f(x0[1], xf[1], args...; kwargs...)]
end
function (F::BoundaryConstraint{1, K})(x0::State, xf::State, args...; kwargs...)::ctVector where K
    return F.f(x0[1], xf[1], args...; kwargs...)
end
function (F::BoundaryConstraint{N, 1})(x0::State, xf::State, args...; kwargs...)::ctVector where N
    return [F.f(x0, xf, args...; kwargs...)]
end
function (F::BoundaryConstraint{N, K})(x0::State, xf::State, args...; kwargs...)::ctVector where {N, K}
    return F.f(x0, xf, args...; kwargs...)
end

# -------------------------------------------------------------------------------------------
# pre-condition: f returns a scalar
"""
$(TYPEDEF)

**Fields**

$(TYPEDFIELDS)

!!! warning

    When the state is of dimension 1, consider `x0` and `xf` as a scalar.

## Classical calls

- state dimension: 1

```@example
julia> G = Mayer((x0, xf) -> xf - x0)
julia> G(0, 1)
1
```

- state dimension: 2

```@example
julia> G = Mayer((x0, xf) -> xf[1] - x0[2])
julia> G([1, 0], [0, 1])
1
```

## Specific calls

When giving a _Time for `t0` and `tf`, the function takes a vector as input for `x0` and
`xf`.

!!! warning

    To use the specific call, you must construct the function with the keyword `state_dimension`.

- state dimension: 1

```@example
julia> G = Mayer((x0, xf) -> xf - x0, state_dimension=1)
1
```

- state dimension: 2

```@example
julia> G = Mayer((x0, xf) -> xf[1] - x0[1], state_dimension=2)
julia> G[1, 0], [0, 1])
-1
```
"""
struct Mayer{state_dimension}
    f::Function
    function Mayer(f::Function; 
        state_dimension::Union{Symbol,Dimension}=__state_dimension())
        new{state_dimension}(f)
    end
end

# classical call
function (F::Mayer{N})(x0::Union{ctNumber, State}, 
    xf::Union{ctNumber, State}, args...; kwargs...)::ctNumber where {N}
    return F.f(x0, xf, args...; kwargs...)
end

# specific calls: inputs are vectors, except times
function (F::Mayer{1})(x0::State, xf::State, args...; kwargs...)::ctNumber
    return F.f(x0[1], xf[1], args...; kwargs...)
end
function (F::Mayer{N})(x0::State, xf::State, args...; kwargs...)::ctNumber where N
    return F.f(x0, xf, args...; kwargs...)
end

# -------------------------------------------------------------------------------------------
# pre-condition: f returns a scalar
"""

$(TYPEDEF)

**Fields**

$(TYPEDFIELDS)

The default value for `time_dependence` is `:t_indep`.

!!! warning

    When the state and adjoint are of dimension 1, consider `x` and `p` as scalars.

## Classical calls

- state dimension: 1
- time dependence: autonomous

```@example
julia> H = Hamiltonian((x, p) -> x + p)
julia> H(1, 1)
2
julia> H([1], [1])
ERROR: MethodError: Cannot `convert` an object of type Vector{Int64} to an object of type Real
julia> H = Hamiltonian((x, p) -> x + p, time_dependence=:t_indep)
julia> H(1, 1)
2
julia> H([1], [1])
ERROR: MethodError: Cannot `convert` an object of type Vector{Int64} to an object of type Real
```

- state dimension: 1
- time dependence: nonautonomous

```@example
julia> H = Hamiltonian((t, x, p) -> x + p, time_dependence=:t_dep)
julia> H(1, 1, 1)
2
julia> H(1, [1], [1])
ERROR: MethodError: Cannot `convert` an object of type Vector{Int64} to an object of type Real
```

- state dimension: 2
- time dependence: autonomous

```@example
julia> H = Hamiltonian((x, p) -> x[1]^2 + p[2]^2) # or time_dependence=:t_indep
julia> H([1, 0], [0, 1])
2
```

- state dimension: 2
- time dependence: nonautonomous

```@example
julia> H = Hamiltonian((t, x, p) -> t + x[1]^2 + p[2]^2, time_dependence=:t_dep)
julia> H(1, [1, 0], [0, 1])
3
```

## Specific calls

When giving a _Time for `t`, the function takes a vector as input for `x` and `p`.

- state dimension: 1
- time dependence: autonomous

```@example
julia> H = Hamiltonian((x, p) -> x + p, state_dimension=1)
julia> H(_Time(0), 1, 1)
ERROR: MethodError: no method matching (::Hamiltonian{:t_indep, 1})(::CTBase._Time, ::Int64, ::Int64)
julia> H(_Time(0), [1], [1])
2
```

- state dimension: 1
- time dependence: nonautonomous

```@example
julia> H = Hamiltonian((t, x, p) -> t + x + p, state_dimension=1, time_dependence=:t_dep)
julia> H(_Time(1), 1, 1)
ERROR: MethodError: no method matching (::Hamiltonian{:t_dep, 1})(::CTBase._Time, ::Int64, ::Int64)
julia> H(_Time(1), [1], [1])
3
```

- state dimension: 2
- time dependence: autonomous

```@example
julia> H = Hamiltonian((x, p) -> x[1]^2 + p[2]^2, state_dimension=2)
julia> H(_Time(0), [1, 0], [0, 1])
2
```

- state dimension: 2
- time dependence: nonautonomous

```@example
julia> H = Hamiltonian((t, x, p) -> t + x[1]^2 + p[2]^2, state_dimension=2, time_dependence=:t_dep)
julia> H(_Time(1), [1, 0], [0, 1])
3
```
"""
struct Hamiltonian{time_dependence, state_dimension}
    f::Function
    function Hamiltonian(f::Function; 
        state_dimension::Union{Symbol,Dimension}=__state_dimension(), 
        time_dependence::Union{Nothing,Symbol}=__fun_time_dependence())
        if time_dependence ∉ [:t_indep, :t_dep]
            throw(InconsistentArgument("time_dependence must be either :t_indep or :t_dep"))
        end
        new{time_dependence, state_dimension}(f)
    end
end

# classical calls
function (F::Hamiltonian{:t_dep, N})(t::Time, x::Union{ctNumber, State}, 
        p::Union{ctNumber, Adjoint}, args...; kwargs...)::ctNumber where {N}
    return F.f(t, x, p, args...; kwargs...)
end
function (F::Hamiltonian{:t_indep, N})(x::Union{ctNumber, State}, 
        p::Union{ctNumber, Adjoint}, args...; kwargs...)::ctNumber where {N}
    return F.f(x, p, args...; kwargs...)
end

# specific calls: inputs are vectors, except times
# state dimension: 1
function (F::Hamiltonian{:t_dep, 1})(t::_Time, x::State, p::Adjoint, args...; kwargs...)::ctNumber
    return F.f(t.value, x[1], p[1], args...; kwargs...)
end
function (F::Hamiltonian{:t_indep, 1})(t::_Time, x::State, p::Adjoint, args...; kwargs...)::ctNumber
    return F.f(x[1], p[1], args...; kwargs...)
end
# state dimension: N>1
function (F::Hamiltonian{:t_dep, N})(t::_Time, x::State, p::Adjoint, args...; kwargs...)::ctNumber where {N}
    return F.f(t.value, x, p, args...; kwargs...)
end
function (F::Hamiltonian{:t_indep, N})(t::_Time, x::State, p::Adjoint, args...; kwargs...)::ctNumber where {N}
    return F.f(x, p, args...; kwargs...)
end


#-------------------------------------------------------------------------------------------
# pre-condition: no
"""

$(TYPEDEF)

**Fields**

$(TYPEDFIELDS)

The default value for `time_dependence` is `:t_indep`.

!!! warning

    When the state and adjoint are of dimension 1, consider `x` and `p` as scalars.

## Classical calls

- state dimension: 1
- time dependence: autonomous

```@example
julia> Hv = HamiltonianVectorField((x, p) -> [x + p, x - p])
julia> Hv(1, 1)
2-element Vector{Int64}:
 2
 0
julia> Hv([1], [1])
ERROR: MethodError: Cannot `convert` an object of type 
  Vector{Vector{Int64}} to an object of type 
  AbstractVector{<:Real}
julia> Hv = HamiltonianVectorField((x, p) -> [x + p, x - p], time_dependence=:t_indep)
julia> Hv(1, 1)
2-element Vector{Int64}:
 2
 0
julia> Hv([1], [1])
ERROR: MethodError: Cannot `convert` an object of type 
  Vector{Vector{Int64}} to an object of type 
  AbstractVector{<:Real}
```

- state dimension: 1
- time dependence: nonautonomous

```@example
julia> Hv = HamiltonianVectorField((t, x, p) -> [x + p, x - p], time_dependence=:t_dep)
julia> Hv(1, 1, 1)
2-element Vector{Int64}:
 2
 0
julia> Hv(1, [1], [1])
ERROR: MethodError: Cannot `convert` an object of type 
  Vector{Vector{Int64}} to an object of type 
  AbstractVector{<:Real}
```

- state dimension: 2
- time dependence: autonomous

```@example
julia> Hv = HamiltonianVectorField((x, p) -> [x[1]^2 + p[2]^2, x[2]^2 - p[1]^2]) # or time_dependence=:t_indep
julia> Hv([1, 0], [0, 1])
2-element Vector{Int64}:
 2
 0
```

- state dimension: 2
- time dependence: nonautonomous

```@example
julia> Hv = HamiltonianVectorField((t, x, p) -> [t + x[1]^2 + p[2]^2, x[2]^2 - p[1]^2], time_dependence=:t_dep)
julia> Hv(1, [1, 0], [0, 1])
2-element Vector{Int64}:
 3
 0
```

## Specific calls

When giving a _Time for `t`, the function takes a vector as input for `x` and `p`.

- state dimension: 1
- time dependence: autonomous

```@example
julia> Hv = HamiltonianVectorField((x, p) -> [x + p, x - p], state_dimension=1)
julia> Hv(_Time(0), 1, 1)
ERROR: MethodError: no method matching (::HamiltonianVectorField{:t_indep, 1})(::CTBase._Time, ::Int64, ::Int64)
julia> Hv(_Time(0), [1], [1])
2-element Vector{Int64}:
 2
 0
```

- state dimension: 1
- time dependence: nonautonomous

```@example
julia> Hv = HamiltonianVectorField((t, x, p) -> [t + x + p, x - p], state_dimension=1, time_dependence=:t_dep)
julia> Hv(_Time(1), 1, 1)
ERROR: MethodError: no method matching (::HamiltonianVectorField{:t_dep, 1})(::CTBase._Time, ::Int64, ::Int64)
julia> Hv(_Time(1), [1], [1])
2-element Vector{Int64}:
 3
 0
```

- state dimension: 2
- time dependence: autonomous

```@example
julia> Hv = HamiltonianVectorField((x, p) -> [x[1]^2 + p[2]^2, x[2]^2 - p[1]^2], state_dimension=2)
julia> Hv(_Time(0), [1, 0], [0, 1])
2-element Vector{Int64}:
 2
 0
```

- state dimension: 2
- time dependence: nonautonomous

```@example
julia> Hv = HamiltonianVectorField((t, x, p) -> [t + x[1]^2 + p[2]^2, x[2]^2 - p[1]^2], state_dimension=2, time_dependence=:t_dep)
julia> Hv(_Time(1), [1, 0], [0, 1])
2-element Vector{Int64}:
 3
 0
```
"""
struct HamiltonianVectorField{time_dependence, state_dimension}
    f::Function
    function HamiltonianVectorField(f::Function; 
        state_dimension::Union{Symbol,Dimension}=__state_dimension(), 
        time_dependence::Union{Nothing,Symbol}=__fun_time_dependence())
        if time_dependence ∉ [:t_indep, :t_dep]
            throw(InconsistentArgument("time_dependence must be either :t_indep or :t_dep"))
        end
        new{time_dependence, state_dimension}(f)
    end
end

# classical calls
function (F::HamiltonianVectorField{:t_dep, N})(t::Time, x::Union{ctNumber, State}, 
        p::Union{ctNumber, Adjoint}, args...; kwargs...)::ctVector where {N}
    return F.f(t, x, p, args...; kwargs...)
end
function (F::HamiltonianVectorField{:t_indep, N})(x::Union{ctNumber, State}, 
        p::Union{ctNumber, Adjoint}, args...; kwargs...)::ctVector where {N}
    return F.f(x, p, args...; kwargs...)
end

# specific calls: inputs are vectors, except times
# state dimension: 1
function (F::HamiltonianVectorField{:t_dep, 1})(t::_Time, x::State, p::Adjoint, args...; kwargs...)::ctVector
    return F.f(t.value, x[1], p[1], args...; kwargs...)
end
function (F::HamiltonianVectorField{:t_indep, 1})(t::_Time, x::State, p::Adjoint, args...; kwargs...)::ctVector
    return F.f(x[1], p[1], args...; kwargs...)
end
# state dimension: N>1
function (F::HamiltonianVectorField{:t_dep, N})(t::_Time, x::State, p::Adjoint, args...; kwargs...)::ctVector where {N}
    return F.f(t.value, x, p, args...; kwargs...)
end
function (F::HamiltonianVectorField{:t_indep, N})(t::_Time, x::State, p::Adjoint, args...; kwargs...)::ctVector where {N}
    return F.f(x, p, args...; kwargs...)
end

# -------------------------------------------------------------------------------------------
# pre-condition: f returns a scalar if x is a scalar
# we authorize Matrix to be returned if x is a matrix, to integrate ode systems on matrices
"""

$(TYPEDEF)

**Fields**

$(TYPEDFIELDS)

The default value for `time_dependence` is `:t_indep`.

!!! warning

    When the state is of dimension 1, consider `x` as a scalar.

## Classical calls

- state dimension: 1
- time dependence: autonomous

```@example
julia> V = VectorField(x -> 2x) # or time_dependence=:t_indep
julia> V(1)
2
julia> V([1])
1-element Vector{Int64}:
 2
```

- state dimension: 1
- time dependence: nonautonomous

```@example
julia> V = VectorField((t, x) -> t+2x, time_dependence=:t_dep)
julia> V(1, 1)
3
```

- state dimension: 2
-  time dependence: autonomous

```@example
julia> V = VectorField(x -> [x[1]^2, x[2]^2]) # or time_dependence=:t_indep
julia> V([1, 0])
2-element Vector{Int64}:
 1
 0
```

- state dimension: 2
- time dependence: nonautonomous

```@example
julia> V = VectorField((t, x) -> [t + x[1]^2, x[2]^2], time_dependence=:t_dep)
julia> V(1, [1, 0])
2-element Vector{Int64}:
 2
 0
```

## Specific calls

- state dimension: 1
- time dependence: autonomous

```@example
julia> V = VectorField(x -> 2x, state_dimension=1) # or time_dependence=:t_indep
julia> V(_Time(0), 1)
ERROR: MethodError: no method matching (::VectorField{:t_indep, 1})(::CTBase._Time, ::Int64)
julia> V(_Time(0), [1])
1-element Vector{Int64}:
 2
```

- state dimension: 1
- time dependence: nonautonomous

```@example
julia> V = VectorField((t, x) -> t+2x, state_dimension=1, time_dependence=:t_dep)
julia> V(_Time(0), 1)
ERROR: MethodError: no method matching (::VectorField{:t_dep, 1})(::CTBase._Time, ::Int64)
julia> V(_Time(1), [1])
1-element Vector{Int64}:
 3
```

- state dimension: N>1
- time dependence: autonomous

```@example
julia> V = VectorField(x -> [x[1]^2, -x[2]^2], state_dimension=2) # or time_dependence=:t_indep
julia> V(_Time(0), [1, 2])
2-element Vector{Int64}:
  1
 -4
```

- state dimension: N>1
- time dependence: nonautonomous

```@example
julia> V = VectorField((t, x) -> [t + x[1]^2, -x[2]^2], state_dimension=2, time_dependence=:t_dep)
julia> V(_Time(1), [1, 2])
2-element Vector{Int64}:
  2
 -4
```
"""
struct VectorField{time_dependence, state_dimension}
    f::Function
    function VectorField(f::Function; 
        state_dimension::Union{Symbol,Dimension}=__state_dimension(), 
        time_dependence::Union{Nothing,Symbol}=__fun_time_dependence())
        if time_dependence ∉ [:t_indep, :t_dep]
            throw(InconsistentArgument("time_dependence must be either :t_indep or :t_dep"))
        end
        new{time_dependence, state_dimension}(f)
    end
end

# classical calls
function (F::VectorField{:t_dep, N})(t::Time, x::Union{ctNumber, State, Matrix{<:ctNumber}}, 
    args...; kwargs...)::Union{ctNumber, ctVector, Matrix{<:ctNumber}} where {N}
    return F.f(t, x, args...; kwargs...)
end
function (F::VectorField{:t_indep, N})(x::Union{ctNumber, State, Matrix{<:ctNumber}}, 
    args...; kwargs...)::Union{ctNumber, ctVector, Matrix{<:ctNumber}} where {N}
    return F.f(x, args...; kwargs...)
end

# specific calls: inputs are vectors, except times
# state dimension: 1
function (F::VectorField{:t_dep, 1})(t::_Time, x::State, args...; kwargs...)::ctVector
    return [F.f(t.value, x[1], args...; kwargs...)]
end
function (F::VectorField{:t_indep, 1})(t::_Time, x::State, args...; kwargs...)::ctVector
    return [F.f(x[1], args...; kwargs...)]
end
# state dimension: N>1
function (F::VectorField{:t_dep, N})(t::_Time, x::State, args...; kwargs...)::ctVector where {N}
    return F.f(t.value, x, args...; kwargs...)
end
function (F::VectorField{:t_indep, N})(t::_Time, x::State, args...; kwargs...)::ctVector where {N}
    return F.f(x, args...; kwargs...)
end

# -------------------------------------------------------------------------------------------
# pre-condition: f returns a scalar
"""

$(TYPEDEF)

**Fields**

$(TYPEDFIELDS)

The default value for `time_dependence` is `:t_indep`.

!!! warning

    When the state is of dimension 1, consider `x` as a scalar. Same for the control.

## Classical calls

- state dimension: 1
- control dimension: 1
- time dependence: autonomous

```@example
julia> L = Lagrange((x, u) -> x + u) # or time_dependence=:t_indep
julia> L(1, 1)
2
julia> L([1], [1])
ERROR: MethodError: Cannot `convert` an object of type Vector{Int64} to an object of type Real
```

- state dimension: 1
- control dimension: 1
- time dependence: nonautonomous

```@example
julia> L = Lagrange((t, x, u) -> x + u, time_dependence=:t_dep)
julia> L(1, 1, 1)
2
julia> L(1, [1], [1])
ERROR: MethodError: Cannot `convert` an object of type Vector{Int64} to an object of type Real
```

- state dimension: 2
- control dimension: 1
- time dependence: autonomous

```@example
julia> L = Lagrange((x, u) -> x[1]^2 + u^2) # or time_dependence=:t_indep
julia> L([1, 2], 1)
2
```

- state dimension: 2
- control dimension: 1
- time dependence: nonautonomous

```@example
julia> L = Lagrange((t, x, u) -> x[1]^2 + u^2, time_dependence=:t_dep)
julia> L(1, [1, 2], 1)
2
```

- state dimension: 1
- control dimension: 2
- time dependence: autonomous

```@example
julia> L = Lagrange((x, u) -> x^2 + u[2]^2) # or time_dependence=:t_indep
julia> L(1, [1, 2])
5
```

- state dimension: 1
- control dimension: 2
- time dependence: nonautonomous

```@example
julia> L = Lagrange((t, x, u) -> t + x^2 + u[2]^2, time_dependence=:t_dep)
julia> L(1, 1, [1, 2])
6
```

- state dimension: 2
- control dimension: 2
- time dependence: autonomous

```@example
julia> L = Lagrange((x, u) -> x[1]^2 + u[2]^2) # or time_dependence=:t_indep
julia> L([1, 2], [1, 2])
5
```

- state dimension: 2
- control dimension: 2
- time dependence: nonautonomous

```@example
julia> L = Lagrange((t, x, u) -> t + x[1]^2 + u[2]^2, time_dependence=:t_dep)
julia> L(1, [1, 2], [1, 2])
6
```

## Specific calls

- state dimension: 1
- control dimension: 1
- time dependence: autonomous

```@example
julia> L = Lagrange((x, u) -> x + u, state_dimension=1, control_dimension=1) # or time_dependence=:t_indep
julia> L(_Time(1), 1, 1)
ERROR: MethodError: no method matching (::Lagrange{:t_indep, 0, 0})(::CTBase._Time, ::Int64, ::Int64)
julia> L(_Time(1), [1], [1])
2
```

- state dimension: 1
- control dimension: 1
- time dependence: nonautonomous

```@example
julia> L = Lagrange((t, x, u) -> t + x + u, state_dimension=1, control_dimension=1, time_dependence=:t_dep)
julia> L(_Time(1), 1, 1)
ERROR: MethodError: no method matching (::Lagrange{:t_dep, 0, 0})(::CTBase._Time, ::Int64, ::Int64)
julia> L(_Time(1), [1], [1])
3
```

- state dimension: 2
- control dimension: 1
- time dependence: autonomous

```@example
julia> L = Lagrange((x, u) -> x[1]^2 + u^2, state_dimension=2, control_dimension=1) # or time_dependence=:t_indep
julia> L(_Time(1), [1, 2], 1)
ERROR: MethodError: no method matching (::Lagrange{:t_indep, 0, 0})(::CTBase._Time, ::Vector{Int64}, ::Int64)
julia> L(_Time(1), [1, 2], [1])
2
```

- state dimension: 2
- control dimension: 1
- time dependence: nonautonomous

```@example
julia> L = Lagrange((t, x, u) -> t + x[1]^2 + u^2, state_dimension=2, control_dimension=1, time_dependence=:t_dep)
julia> L(_Time(1), [1, 2], 1)
ERROR: MethodError: no method matching (::Lagrange{:t_dep, 0, 0})(::CTBase._Time, ::Vector{Int64}, ::Int64)
julia> L(_Time(1), [1, 2], [1])
3
```

- state dimension: 1
- control dimension: 2
- time dependence: autonomous

```@example
julia> L = Lagrange((x, u) -> x^2 + u[2]^2, state_dimension=1, control_dimension=2) # or time_dependence=:t_indep
julia> L(_Time(1), 1, [1, 2])
ERROR: MethodError: no method matching (::Lagrange{:t_indep, 0, 0})(::CTBase._Time, ::Int64, ::Vector{Int64})
julia> L(_Time(1), [1], [1, 2])
5
```

- state dimension: 1
- control dimension: 2
- time dependence: nonautonomous

```@example
julia> L = Lagrange((t, x, u) -> t + x^2 + u[2]^2, state_dimension=1, control_dimension=2, time_dependence=:t_dep)
julia> L(_Time(1), 1, [1, 2])
ERROR: MethodError: no method matching (::Lagrange{:t_dep, 0, 0})(::CTBase._Time, ::Int64, ::Vector{Int64})
julia> L(_Time(1), [1], [1, 2])
6
```

- state dimension: 2
- control dimension: 2
- time dependence: autonomous

```@example
julia> L = Lagrange((x, u) -> x[1]^2 + u[2]^2, state_dimension=2, control_dimension=2) # or time_dependence=:t_indep
julia> L(_Time(1), [1, 2], [1, 2])
5
```
"""
struct Lagrange{time_dependence, state_dimension, control_dimension}
    f::Function
    function Lagrange(f::Function; 
        state_dimension::Union{Symbol,Dimension}=__state_dimension(),
        control_dimension::Union{Symbol,Dimension}=__control_dimension(),
        time_dependence::Union{Nothing,Symbol}=__fun_time_dependence())
        if time_dependence ∉ [:t_indep, :t_dep]
            throw(InconsistentArgument("time_dependence must be either :t_indep or :t_dep"))
        end
        new{time_dependence, state_dimension, control_dimension}(f)
    end
end

# classical calls
function (F::Lagrange{:t_dep, N, M})(t::Time, x::Union{ctNumber, State}, 
    u::Union{ctNumber, Control}, args...; kwargs...)::ctNumber where {N, M}
    return F.f(t, x, u, args...; kwargs...)
end
function (F::Lagrange{:t_indep, N, M})(x::Union{ctNumber, State}, 
    u::Union{ctNumber, Control}, args...; kwargs...)::ctNumber where {N, M}
    return F.f(x, u, args...; kwargs...)
end

# specific calls: inputs are vectors, except times
# state dimension: 1
# control dimension: 1
function (F::Lagrange{:t_dep, 1, 1})(t::_Time, x::State, u::Control, args...; kwargs...)::ctNumber
    return F.f(t.value, x[1], u[1], args...; kwargs...)
end
function (F::Lagrange{:t_indep, 1, 1})(t::_Time, x::State, u::Control, args...; kwargs...)::ctNumber
    return F.f(x[1], u[1], args...; kwargs...)
end
# state dimension: N>1
# control dimension: 1
function (F::Lagrange{:t_dep, N, 1})(t::_Time, x::State, u::Control, args...; kwargs...)::ctNumber where {N}
    return F.f(t.value, x, u[1], args...; kwargs...)
end
function (F::Lagrange{:t_indep, N, 1})(t::_Time, x::State, u::Control, args...; kwargs...)::ctNumber where {N}
    return F.f(x, u[1], args...; kwargs...)
end
# state dimension: 1
# control dimension: M>1
function (F::Lagrange{:t_dep, 1, M})(t::_Time, x::State, u::Control, args...; kwargs...)::ctNumber where {M}
    return F.f(t.value, x[1], u, args...; kwargs...)
end
function (F::Lagrange{:t_indep, 1, M})(t::_Time, x::State, u::Control, args...; kwargs...)::ctNumber where {M}
    return F.f(x[1], u, args...; kwargs...)
end
# state dimension: N>1
# control dimension: M>1
function (F::Lagrange{:t_dep, N, M})(t::_Time, x::State, u::Control, args...; kwargs...)::ctNumber where {N, M}
    return F.f(t.value, x, u, args...; kwargs...)
end
function (F::Lagrange{:t_indep, N, M})(t::_Time, x::State, u::Control, args...; kwargs...)::ctNumber where {N, M}
    return F.f(x, u, args...; kwargs...)
end

# -------------------------------------------------------------------------------------------
# pre-condition: f returns a scalar if x is scalar
"""

$(TYPEDEF)

**Fields**

$(TYPEDFIELDS)

Similar to `Lagrange`, but the function `f` is assumed to return a vector of the same dimension as the state `x`.

"""
struct Dynamics{time_dependence, state_dimension, control_dimension}
    f::Function
    function Dynamics(f::Function; 
        state_dimension::Union{Symbol,Dimension}=__state_dimension(),
        control_dimension::Union{Symbol,Dimension}=__control_dimension(),
        time_dependence::Union{Nothing,Symbol}=__fun_time_dependence())
        if time_dependence ∉ [:t_indep, :t_dep]
            throw(InconsistentArgument("time_dependence must be either :t_indep or :t_dep"))
        end
        new{time_dependence, state_dimension, control_dimension}(f)
    end
end

# classical calls
function (F::Dynamics{:t_dep, N, M})(t::Time, x::Union{ctNumber, State}, 
    u::Union{ctNumber, Control}, args...; kwargs...)::Union{ctNumber, ctVector} where {N, M}
    return F.f(t, x, u, args...; kwargs...)
end
function (F::Dynamics{:t_indep, N, M})(x::Union{ctNumber, State}, 
    u::Union{ctNumber, Control}, args...; kwargs...)::Union{ctNumber, ctVector} where {N, M}
    return F.f(x, u, args...; kwargs...)
end

# specific calls: inputs are vectors, except times. output is a vector
# state dimension: 1
# control dimension: 1
function (F::Dynamics{:t_dep, 1, 1})(t::_Time, x::State, u::Control, args...; kwargs...)::ctVector
    return [F.f(t.value, x[1], u[1], args...; kwargs...)]
end
function (F::Dynamics{:t_indep, 1, 1})(t::_Time, x::State, u::Control, args...; kwargs...)::ctVector
    return [F.f(x[1], u[1], args...; kwargs...)]
end
# state dimension: N>1
# control dimension: 1
function (F::Dynamics{:t_dep, N, 1})(t::_Time, x::State, u::Control, args...; kwargs...)::ctVector where {N}
    return F.f(t.value, x, u[1], args...; kwargs...)
end
function (F::Dynamics{:t_indep, N, 1})(t::_Time, x::State, u::Control, args...; kwargs...)::ctVector where {N}
    return F.f(x, u[1], args...; kwargs...)
end
# state dimension: 1
# control dimension: M>1
function (F::Dynamics{:t_dep, 1, M})(t::_Time, x::State, u::Control, args...; kwargs...)::ctVector where {M}
    return [F.f(t.value, x[1], u, args...; kwargs...)]
end
function (F::Dynamics{:t_indep, 1, M})(t::_Time, x::State, u::Control, args...; kwargs...)::ctVector where {M}
    return [F.f(x[1], u, args...; kwargs...)]
end
# state dimension: N>1
# control dimension: M>1
function (F::Dynamics{:t_dep, N, M})(t::_Time, x::State, u::Control, args...; kwargs...)::ctVector where {N, M}
    return F.f(t.value, x, u, args...; kwargs...)
end
function (F::Dynamics{:t_indep, N, M})(t::_Time, x::State, u::Control, args...; kwargs...)::ctVector where {N, M}
    return F.f(x, u, args...; kwargs...)
end

# -------------------------------------------------------------------------------------------
# pre-condition: f returns a scalar if the output is one dimensional
"""

$(TYPEDEF)

**Fields**

$(TYPEDFIELDS)

Similar to `VectorField` in the usage, but the dimension of the output of the function `f` is arbitrary.

"""
# todo: ctVector = Union{ctNumber, Vector{<:ctNumber}}
#       State = ctVector
#       ...
struct StateConstraint{time_dependence, variable_dependence}
    f::Function
    function StateConstraint(f::Function; 
        time_dependence::Union{Nothing,Symbol}=__fun_time_dependence(),
        variable_dependence::Union{Nothing,Symbol}=__fun_variable_dependence())
        @assert time_dependence ∉ [:t_indep, :t_dep]
        @assert variable_dependence ∉ [:v_indep, :v_dep]
        new{time_dependence, variable_dependence}(f)
    end
end

function (F::StateConstraint{:t_indep, :v_indep})(x::State)::ctVector
    return F.f(x)
end

function (F::StateConstraint{:t_indep, :v_indep})(t::Time, x::State, v::Variable)::ctVector
    return F.f(x)
end

function (F::StateConstraint{:t_indep, :v_dep})(x::State, v::Variable)::ctVector
    return F.f(x, v)
end

function (F::StateConstraint{:t_indep, :v_dep})(t::Time, x::State, v::Variable)::ctVector
    return F.f(x, v)
end

function (F::StateConstraint{:t_dep, :v_indep})(t::Time, x::State)::ctVector
    return F.f(t, x)
end

function (F::StateConstraint{:t_dep, :v_indep})(t::Time, x::State, v::Variable)::ctVector
    return F.f(t, x)
end

function (F::StateConstraint{:t_dep, :v_dep})(t::Time, x::State, v::Variable)::ctVector
    return F.f(t, x, v)
end

# -------------------------------------------------------------------------------------------
# pre-condition: f returns a scalar if the output is one dimensional
"""

$(TYPEDEF)

**Fields**

$(TYPEDFIELDS)

Similar to `VectorField` in the usage, but the dimension of the output of the function `f` is arbitrary.

"""
struct ControlConstraint{time_dependence, control_dimension, constraint_dimension}
    f::Function
    function ControlConstraint(f::Function; 
        control_dimension::Union{Symbol,Dimension}=__control_dimension(),
        constraint_dimension::Union{Symbol,Dimension}=__constraint_dimension(),
        time_dependence::Union{Nothing,Symbol}=__fun_time_dependence())
        if time_dependence ∉ [:t_indep, :t_dep]
            throw(InconsistentArgument("time_dependence must be either :t_indep or :t_dep"))
        end
        new{time_dependence, control_dimension, constraint_dimension}(f)
    end
end

# classical calls
function (F::ControlConstraint{:t_dep, M, K})(t::Time, u::Union{ctNumber, Control}, 
    args...; kwargs...)::Union{ctNumber, ctVector} where {M, K}
    return F.f(t, u, args...; kwargs...)
end
function (F::ControlConstraint{:t_indep, M, K})(u::Union{ctNumber, Control}, 
    args...; kwargs...)::Union{ctNumber, ctVector} where {M, K}
    return F.f(u, args...; kwargs...)
end

# specific calls: inputs are vectors, except times

# control dimension: 1
# constraint dimension: 1
function (F::ControlConstraint{:t_dep, 1, 1})(t::_Time, u::Control, args...; kwargs...)::ctVector
    return [F.f(t.value, u[1], args...; kwargs...)]
end
function (F::ControlConstraint{:t_indep, 1, 1})(t::_Time, u::Control, args...; kwargs...)::ctVector
    return [F.f(u[1], args...; kwargs...)]
end

# control dimension: M>1
# constraint dimension: 1
function (F::ControlConstraint{:t_dep, M, 1})(t::_Time, u::Control, args...; kwargs...)::ctVector where {M}
    return [F.f(t.value, u, args...; kwargs...)]
end
function (F::ControlConstraint{:t_indep, M, 1})(t::_Time, u::Control, args...; kwargs...)::ctVector where {M}
    return [F.f(u, args...; kwargs...)]
end

# control dimension: 1
# constraint dimension: K>1
function (F::ControlConstraint{:t_dep, 1, K})(t::_Time, u::Control, args...; kwargs...)::ctVector where {K}
    return F.f(t.value, u[1], args...; kwargs...)
end
function (F::ControlConstraint{:t_indep, 1, K})(t::_Time, u::Control, args...; kwargs...)::ctVector where {K}
    return F.f(u[1], args...; kwargs...)
end

# control dimension: M>1
# constraint dimension: K>1
function (F::ControlConstraint{:t_dep, M, K})(t::_Time, u::Control, args...; kwargs...)::ctVector where {M, K}
    return F.f(t.value, u, args...; kwargs...)
end
function (F::ControlConstraint{:t_indep, M, K})(t::_Time, u::Control, args...; kwargs...)::ctVector where {M, K}
    return F.f(u, args...; kwargs...)
end

# -------------------------------------------------------------------------------------------
# pre-condition: f returns a scalar if the output is one dimensional
"""

$(TYPEDEF)

**Fields**

$(TYPEDFIELDS)

Similar to `Lagrange` in the usage, but the dimension of the output of the function `f` is arbitrary.

"""
struct MixedConstraint{time_dependence, state_dimension, control_dimension, constraint_dimension}
    f::Function
    function MixedConstraint(f::Function; 
        state_dimension::Union{Symbol,Dimension}=__state_dimension(),
        control_dimension::Union{Symbol,Dimension}=__control_dimension(),
        constraint_dimension::Union{Symbol,Dimension}=__constraint_dimension(),
        time_dependence::Union{Nothing,Symbol}=__fun_time_dependence())
        if time_dependence ∉ [:t_indep, :t_dep]
            throw(InconsistentArgument("time_dependence must be either :t_indep or :t_dep"))
        end
        new{time_dependence, state_dimension, control_dimension, constraint_dimension}(f)
    end
end

# classical calls
function (F::MixedConstraint{:t_dep, N, M, K})(t::Time, x::Union{ctNumber, State},
    u::Union{ctNumber, Control}, args...; kwargs...)::Union{ctNumber, ctVector} where {N, M, K}
    return F.f(t, x, u, args...; kwargs...)
end
function (F::MixedConstraint{:t_indep, N, M, K})(x::Union{ctNumber, State},
    u::Union{ctNumber, Control}, args...; kwargs...)::Union{ctNumber, ctVector} where {N, M, K}
    return F.f(x, u, args...; kwargs...)
end

# specific calls: inputs are vectors, except times

# state dimension: 1
# control dimension: 1
# constraint dimension: 1
function (F::MixedConstraint{:t_dep, 1, 1, 1})(t::_Time, x::State, u::Control, args...; kwargs...)::ctVector
    return [F.f(t.value, x[1], u[1], args...; kwargs...)]
end
function (F::MixedConstraint{:t_indep, 1, 1, 1})(t::_Time, x::State, u::Control, args...; kwargs...)::ctVector
    return [F.f(x[1], u[1], args...; kwargs...)]
end

# state dimension: N>1
# control dimension: 1
# constraint dimension: 1
function (F::MixedConstraint{:t_dep, N, 1, 1})(t::_Time, x::State, u::Control, args...; kwargs...)::ctVector where {N}
    return [F.f(t.value, x, u[1], args...; kwargs...)]
end
function (F::MixedConstraint{:t_indep, N, 1, 1})(t::_Time, x::State, u::Control, args...; kwargs...)::ctVector where {N}
    return [F.f(x, u[1], args...; kwargs...)]
end

# state dimension: 1
# control dimension: M>1
# constraint dimension: 1
function (F::MixedConstraint{:t_dep, 1, M, 1})(t::_Time, x::State, u::Control, args...; kwargs...)::ctVector where {M}
    return [F.f(t.value, x[1], u, args...; kwargs...)]
end
function (F::MixedConstraint{:t_indep, 1, M, 1})(t::_Time, x::State, u::Control, args...; kwargs...)::ctVector where {M}
    return [F.f(x[1], u, args...; kwargs...)]
end

# state dimension: N>1
# control dimension: M>1
# constraint dimension: 1
function (F::MixedConstraint{:t_dep, N, M, 1})(t::_Time, x::State, u::Control, args...; kwargs...)::ctVector where {N, M}
    return [F.f(t.value, x, u, args...; kwargs...)]
end
function (F::MixedConstraint{:t_indep, N, M, 1})(t::_Time, x::State, u::Control, args...; kwargs...)::ctVector where {N, M}
    return [F.f(x, u, args...; kwargs...)]
end

# state dimension: 1
# control dimension: 1
# constraint dimension: K>1
function (F::MixedConstraint{:t_dep, 1, 1, K})(t::_Time, x::State, u::Control, args...; kwargs...)::ctVector where {K}
    return F.f(t.value, x[1], u[1], args...; kwargs...)
end
function (F::MixedConstraint{:t_indep, 1, 1, K})(t::_Time, x::State, u::Control, args...; kwargs...)::ctVector where {K}
    return F.f(x[1], u[1], args...; kwargs...)
end

# state dimension: N>1
# control dimension: 1
# constraint dimension: K>1
function (F::MixedConstraint{:t_dep, N, 1, K})(t::_Time, x::State, u::Control, args...; kwargs...)::ctVector where {N, K}
    return F.f(t.value, x, u[1], args...; kwargs...)
end
function (F::MixedConstraint{:t_indep, N, 1, K})(t::_Time, x::State, u::Control, args...; kwargs...)::ctVector where {N, K}
    return F.f(x, u[1], args...; kwargs...)
end

# state dimension: 1
# control dimension: M>1
# constraint dimension: K>1
function (F::MixedConstraint{:t_dep, 1, M, K})(t::_Time, x::State, u::Control, args...; kwargs...)::ctVector where {M, K}
    return F.f(t.value, x[1], u, args...; kwargs...)
end
function (F::MixedConstraint{:t_indep, 1, M, K})(t::_Time, x::State, u::Control, args...; kwargs...)::ctVector where {M, K}
    return F.f(x[1], u, args...; kwargs...)
end

# state dimension: N>1
# control dimension: M>1
# constraint dimension: K>1
function (F::MixedConstraint{:t_dep, N, M, K})(t::_Time, x::State, u::Control, args...; kwargs...)::ctVector where {N, M, K}
    return F.f(t.value, x, u, args...; kwargs...)
end
function (F::MixedConstraint{:t_indep, N, M, K})(t::_Time, x::State, u::Control, args...; kwargs...)::ctVector where {N, M, K}
    return F.f(x, u, args...; kwargs...)
end

# -------------------------------------------------------------------------------------------
struct VariableConstraint
    f::Function
    function VariableConstraint(f::Function)
        new(f)
    end
end

function (F::VariableConstraint)(v::Union{ctNumber, Variable}, args...; kwargs...)
    return F.f(v, args...; kwargs...)
end

# -------------------------------------------------------------------------------------------
# pre-condition: f returns a scalar if the output is one dimensional
"""

$(TYPEDEF)

**Fields**

$(TYPEDFIELDS)

The function `f` must be of the form `f(t, x, args...; kwargs...)` or `f(x, args...; kwargs...)` depending on 
the time dependence of the optimal control problem.

!!! note

    Only classical usage.

"""
struct FeedbackControl{time_dependence}
    f::Function
    function FeedbackControl(f::Function; 
        time_dependence::Union{Nothing,Symbol}=__fun_time_dependence())
        if time_dependence ∉ [:t_indep, :t_dep]
            throw(InconsistentArgument("time_dependence must be either :t_indep or :t_dep"))
        end
        new{time_dependence}(f)
    end
end

# classical calls
function (F::FeedbackControl{:t_dep})(t::Time, x::Union{ctNumber, State}, args...; kwargs...)::Union{ctNumber, ctVector}
    return F.f(t, x, args...; kwargs...)
end
function (F::FeedbackControl{:t_indep})(x::Union{ctNumber, State}, args...; kwargs...)::Union{ctNumber, ctVector}
    return F.f(x, args...; kwargs...)
end

# -------------------------------------------------------------------------------------------
# pre-condition: f returns a scalar if the output is one dimensional
"""

$(TYPEDEF)

**Fields**

$(TYPEDFIELDS)

The function `f` must be of the form `f(t, x, p, args...; kwargs...)` or `f(x, p, args...; kwargs...)` depending on 
the time dependence of the optimal control problem.

!!! note

    Only classical usage.

"""
struct ControlLaw{time_dependence}
    f::Function
    function ControlLaw(f::Function; 
        time_dependence::Union{Nothing,Symbol}=__fun_time_dependence())
        if time_dependence ∉ [:t_indep, :t_dep]
            throw(InconsistentArgument("time_dependence must be either :t_indep or :t_dep"))
        end
        new{time_dependence}(f)
    end
end

# classical calls
function (F::ControlLaw{:t_dep})(t::Time, x::Union{ctNumber, State},
    p::Union{ctNumber, Adjoint}, args...; kwargs...)::Union{ctNumber, ctVector}
    return F.f(t, x, p, args...; kwargs...)
end
function (F::ControlLaw{:t_indep})(x::Union{ctNumber, State},
    p::Union{ctNumber, Adjoint}, args...; kwargs...)::Union{ctNumber, ctVector}
    return F.f(x, p, args...; kwargs...)
end

# -------------------------------------------------------------------------------------------
# pre-condition: f returns a scalar if the output is one dimensional
"""

$(TYPEDEF)

**Fields**

$(TYPEDFIELDS)

The function `f` must be of the form `f(t, x, p, args...; kwargs...)` or `f(x, p, args...; kwargs...)` depending on 
the time dependence of the optimal control problem.

!!! note

    Only classical usage.

"""
struct Multiplier{time_dependence}
    f::Function
    function Multiplier(f::Function; 
        time_dependence::Union{Nothing,Symbol}=__fun_time_dependence())
        if time_dependence ∉ [:t_indep, :t_dep]
            throw(InconsistentArgument("time_dependence must be either :t_indep or :t_dep"))
        end
        new{time_dependence}(f)
    end
end

# classical calls
function (F::Multiplier{:t_dep})(t::Time, x::Union{ctNumber, State},
    p::Union{ctNumber, Adjoint}, args...; kwargs...)::Union{ctNumber, ctVector}
    return F.f(t, x, p, args...; kwargs...)
end
function (F::Multiplier{:t_indep})(x::Union{ctNumber, State},
    p::Union{ctNumber, Adjoint}, args...; kwargs...)::Union{ctNumber, ctVector}
    return F.f(x, p, args...; kwargs...)
end
