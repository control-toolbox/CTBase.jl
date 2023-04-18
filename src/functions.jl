struct _Time
    value::Time
    function _Time(value::Time)
        return new(value)
    end
end
#_Time(times::Times) = _Time.(times)
#_Time(times::StepRangeLen) = _Time.(times)
+(t1::_Time, t2::_Time)::_Time = _Time(t1.value + t2.value)
-(t1::_Time, t2::_Time)::_Time = _Time(t1.value - t2.value)
*(t1::_Time, t2::_Time)::_Time = _Time(t1.value * t2.value)
/(t1::_Time, t2::_Time)::_Time = _Time(t1.value / t2.value)
+(t1::_Time, t2::ctNumber)::_Time = _Time(t1.value + t2)
+(t1::ctNumber, t2::_Time)::_Time = _Time(t1 + t2.value)
-(t1::_Time, t2::ctNumber)::_Time = _Time(t1.value - t2)
-(t1::ctNumber, t2::_Time)::_Time = _Time(t1 - t2.value)
*(t1::_Time, t2::ctNumber)::_Time = _Time(t1.value * t2)
*(t1::ctNumber, t2::_Time)::_Time = _Time(t1 * t2.value)
/(t1::_Time, t2::ctNumber)::_Time = _Time(t1.value / t2)
/(t1::ctNumber, t2::_Time)::_Time = _Time(t1 / t2.value)
^(t::_Time, n::ctNumber)::_Time = _Time(t.value^n)
-(t::_Time) = _Time(-(t.value))
Base.show(io::IO, t::_Time) = print(io, t.value)
Base.show(io::IO, ::MIME"text/plain", t::_Time) = print(io, t.value)
Base.show(io::IO, ::MIME"text/latex", t::_Time) = print(io, t.value)
Base.show(io::IO, ::MIME"text/html", t::_Time) = print(io, t.value)
Base.show(io::IO, ::MIME"text/markdown", t::_Time) = print(io, t.value)
isless(t1::_Time, t2::_Time) = isless(t1.value, t2.value)
isless(t1::_Time, t2::ctNumber) = isless(t1.value, t2)
isless(t1::ctNumber, t2::_Time) = isless(t1, t2.value)
isequal(t1::_Time, t2::_Time) = isequal(t1.value, t2.value)
isequal(t1::_Time, t2::ctNumber) = isequal(t1.value, t2)
isequal(t1::ctNumber, t2::_Time) = isequal(t1, t2.value)

# -------------------------------------------------------------------------------------------
"""
$(TYPEDEF)

Abstract type for functions.
"""
abstract type AbstractCTFunction <: Function end

#
const abstract_heritance=:AbstractCTFunction

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
julia> B = BoundaryConstraint((t0, x0, tf, xf) -> xf - x0)
julia> B(0, 0, 1, 1)
1
julia> B(0, [0], 1, [1])
1-element Vector{Int64}:
 1
```

- state dimension: 1
- constraint dimension: 2

```@example
julia> B = BoundaryConstraint((t0, x0, tf, xf) -> [xf - x0, t0 - tf])
julia> B(0, 0, 1, 1)
2-element Vector{Int64}:
  1
 -1
julia> B(0, [0], 1, [1])
ERROR: MethodError: Cannot `convert` an object of type 
  Vector{Any} to an object of type 
  Union{Real, AbstractVector{<:Real}}
```

- state dimension: 2
- constraint dimension: 1
    
```@example
julia> B = BoundaryConstraint((t0, x0, tf, xf) -> tf - t0)
julia> B(0, [1, 0], 1, [0, 1])
1
```

- state dimension: 2
- constraint dimension: 2

```@example
julia> B = BoundaryConstraint((t0, x0, tf, xf) -> [tf - t0, xf[1] - x0[2]])
julia> B(0, [1, 0], 1, [1, 0])
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
julia> B = BoundaryConstraint((t0, x0, tf, xf) -> xf - x0, 
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
julia> B = BoundaryConstraint((t0, x0, tf, xf) -> [xf - x0, t0 - tf], 
    state_dimension=1, constraint_dimension=2)
julia> B(_Time(0), 0, _Time(1), 1)
ERROR: MethodError: no method matching (::BoundaryConstraint{1, 2})(::_Time, ::Int64, 
::_Time, ::Int64)
julia> B(_Time(0), [0], _Time(1), [1])
2-element Vector{Int64}:
  1
 -1
```

- state dimension: 2
- constraint dimension: 1

```@example
julia> B = BoundaryConstraint((t0, x0, tf, xf) -> tf - t0, 
    state_dimension=2, constraint_dimension=1)
julia> B(_Time(0), [1, 0], _Time(1), [0, 1])
1-element Vector{Int64}:
 1
```

- state dimension: 2
- constraint dimension: 2

```@example
julia> B = BoundaryConstraint((t0, x0, tf, xf) -> [tf - t0, xf[1] - x0[2]], 
    state_dimension=2, constraint_dimension=2)
julia> B(_Time(0), [1, 0], _Time(1), [1, 0])
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
function (F::BoundaryConstraint{N, K})(t0::Time, x0::Union{ctNumber, State}, 
        tf::Time, xf::Union{ctNumber, State}, args...; kwargs...)::Union{ctNumber, ctVector} where {N, K}
    return F.f(t0, x0, tf, xf, args...; kwargs...)
end

# specific calls: inputs and outputs are vectors, except times
function (F::BoundaryConstraint{1, 1})(t0::_Time, x0::State, tf::_Time, xf::State, args...; kwargs...)::ctVector
    return [F.f(t0.value, x0[1], tf.value, xf[1], args...; kwargs...)]
end
function (F::BoundaryConstraint{1, K})(t0::_Time, x0::State, tf::_Time, xf::State, args...; kwargs...)::ctVector where K
    return F.f(t0.value, x0[1], tf.value, xf[1], args...; kwargs...)
end
function (F::BoundaryConstraint{N, 1})(t0::_Time, x0::State, tf::_Time, xf::State, args...; kwargs...)::ctVector where N
    return [F.f(t0.value, x0, tf.value, xf, args...; kwargs...)]
end
function (F::BoundaryConstraint{N, K})(t0::_Time, x0::State, tf::_Time, xf::State, args...; kwargs...)::ctVector where {N, K}
    return F.f(t0.value, x0, tf.value, xf, args...; kwargs...)
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
julia> G = Mayer((t0, x0, tf, xf) -> xf - x0)
julia> G(0, 0, 1, 1)
1
julia> G(0, [0], 1, [1])
ERROR: MethodError: Cannot `convert` an object of type Vector{Int64} to an object of type Real
```

- state dimension: 2

```@example
julia> G = Mayer((t0, x0, tf, xf) -> tf - t0)
julia> G(0, [1, 0], 1, [0, 1])
1
```

## Specific calls

When giving a _Time for `t0` and `tf`, the function takes a vector as input for `x0` and
`xf`.

!!! warning

    To use the specific call, you must construct the function with the keyword `state_dimension`.

- state dimension: 1

```@example
julia> G = Mayer((t0, x0, tf, xf) -> xf - x0, state_dimension=1)
julia> G(_Time(0), 0, _Time(1), 1)
ERROR: MethodError: no method matching (:Mayer{1})(::CTBase._Time, ::Int64, ::CTBase._Time, ::Int64)
julia> G(_Time(0), [0], _Time(1), [1])
1
```

- state dimension: 2

```@example
julia> G = Mayer((t0, x0, tf, xf) -> tf - t0, state_dimension=2)
julia> G(_Time(0), [1, 0], _Time(1), [0, 1])
1
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
function (F::Mayer{N})(t0::Time, x0::Union{ctNumber, State}, 
    tf::Time, xf::Union{ctNumber, State}, args...; kwargs...)::ctNumber where {N}
    return F.f(t0, x0, tf, xf, args...; kwargs...)
end

# specific calls: inputs are vectors, except times
function (F::Mayer{1})(t0::_Time, x0::State, tf::_Time, xf::State, args...; kwargs...)::ctNumber
    return F.f(t0.value, x0[1], tf.value, xf[1], args...; kwargs...)
end
function (F::Mayer{N})(t0::_Time, x0::State, tf::_Time, xf::State, args...; kwargs...)::ctNumber where N
    return F.f(t0.value, x0, tf.value, xf, args...; kwargs...)
end

# -------------------------------------------------------------------------------------------
# pre-condition: f returns a scalar
"""

$(TYPEDEF)

**Fields**

$(TYPEDFIELDS)

The default value for `time_dependence` is `:autonomous`.

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
julia> H = Hamiltonian((x, p) -> x + p, time_dependence=:autonomous)
julia> H(1, 1)
2
julia> H([1], [1])
ERROR: MethodError: Cannot `convert` an object of type Vector{Int64} to an object of type Real
```

- state dimension: 1
- time dependence: nonautonomous

```@example
julia> H = Hamiltonian((t, x, p) -> x + p, time_dependence=:nonautonomous)
julia> H(1, 1, 1)
2
julia> H(1, [1], [1])
ERROR: MethodError: Cannot `convert` an object of type Vector{Int64} to an object of type Real
```

- state dimension: 2
- time dependence: autonomous

```@example
julia> H = Hamiltonian((x, p) -> x[1]^2 + p[2]^2) # or time_dependence=:autonomous
julia> H([1, 0], [0, 1])
2
```

- state dimension: 2
- time dependence: nonautonomous

```@example
julia> H = Hamiltonian((t, x, p) -> t + x[1]^2 + p[2]^2, time_dependence=:nonautonomous)
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
ERROR: MethodError: no method matching (::Hamiltonian{:autonomous, 1})(::CTBase._Time, ::Int64, ::Int64)
julia> H(_Time(0), [1], [1])
2
```

- state dimension: 1
- time dependence: nonautonomous

```@example
julia> H = Hamiltonian((t, x, p) -> t + x + p, state_dimension=1, time_dependence=:nonautonomous)
julia> H(_Time(1), 1, 1)
ERROR: MethodError: no method matching (::Hamiltonian{:nonautonomous, 1})(::CTBase._Time, ::Int64, ::Int64)
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
julia> H = Hamiltonian((t, x, p) -> t + x[1]^2 + p[2]^2, state_dimension=2, time_dependence=:nonautonomous)
julia> H(_Time(1), [1, 0], [0, 1])
3
```
"""
struct Hamiltonian{time_dependence, state_dimension}
    f::Function
    function Hamiltonian(f::Function; 
        state_dimension::Union{Symbol,Dimension}=__state_dimension(), 
        time_dependence::Union{Nothing,Symbol}=__fun_time_dependence())
        if !(time_dependence ∈ [:autonomous, :nonautonomous]) 
            error("usage: Hamiltonian(fun; time_dependence=:autonomous, state_dimension=:N) " *
            "with time_dependence ∈ [:autonomous, :nonautonomous]")
        end
        new{time_dependence, state_dimension}(f)
    end
end

# classical calls
function (F::Hamiltonian{:nonautonomous, N})(t::Time, x::Union{ctNumber, State}, 
        p::Union{ctNumber, Adjoint}, args...; kwargs...)::ctNumber where {N}
    return F.f(t, x, p, args...; kwargs...)
end
function (F::Hamiltonian{:autonomous, N})(x::Union{ctNumber, State}, 
        p::Union{ctNumber, Adjoint}, args...; kwargs...)::ctNumber where {N}
    return F.f(x, p, args...; kwargs...)
end

# specific calls: inputs are vectors, except times
# state dimension: 1
function (F::Hamiltonian{:nonautonomous, 1})(t::_Time, x::State, p::Adjoint, args...; kwargs...)::ctNumber
    return F.f(t.value, x[1], p[1], args...; kwargs...)
end
function (F::Hamiltonian{:autonomous, 1})(t::_Time, x::State, p::Adjoint, args...; kwargs...)::ctNumber
    return F.f(x[1], p[1], args...; kwargs...)
end
# state dimension: N>1
function (F::Hamiltonian{:nonautonomous, N})(t::_Time, x::State, p::Adjoint, args...; kwargs...)::ctNumber where {N}
    return F.f(t.value, x, p, args...; kwargs...)
end
function (F::Hamiltonian{:autonomous, N})(t::_Time, x::State, p::Adjoint, args...; kwargs...)::ctNumber where {N}
    return F.f(x, p, args...; kwargs...)
end


#-------------------------------------------------------------------------------------------
# pre-condition: no
"""

$(TYPEDEF)

**Fields**

$(TYPEDFIELDS)

The default value for `time_dependence` is `:autonomous`.

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
julia> Hv = HamiltonianVectorField((x, p) -> [x + p, x - p], time_dependence=:autonomous)
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
julia> Hv = HamiltonianVectorField((t, x, p) -> [x + p, x - p], time_dependence=:nonautonomous)
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
julia> Hv = HamiltonianVectorField((x, p) -> [x[1]^2 + p[2]^2, x[2]^2 - p[1]^2]) # or time_dependence=:autonomous
julia> Hv([1, 0], [0, 1])
2-element Vector{Int64}:
 2
 0
```

- state dimension: 2
- time dependence: nonautonomous

```@example
julia> Hv = HamiltonianVectorField((t, x, p) -> [t + x[1]^2 + p[2]^2, x[2]^2 - p[1]^2], time_dependence=:nonautonomous)
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
ERROR: MethodError: no method matching (::HamiltonianVectorField{:autonomous, 1})(::CTBase._Time, ::Int64, ::Int64)
julia> Hv(_Time(0), [1], [1])
2-element Vector{Int64}:
 2
 0
```

- state dimension: 1
- time dependence: nonautonomous

```@example
julia> Hv = HamiltonianVectorField((t, x, p) -> [t + x + p, x - p], state_dimension=1, time_dependence=:nonautonomous)
julia> Hv(_Time(1), 1, 1)
ERROR: MethodError: no method matching (::HamiltonianVectorField{:nonautonomous, 1})(::CTBase._Time, ::Int64, ::Int64)
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
julia> Hv = HamiltonianVectorField((t, x, p) -> [t + x[1]^2 + p[2]^2, x[2]^2 - p[1]^2], state_dimension=2, time_dependence=:nonautonomous)
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
        if !(time_dependence ∈ [:autonomous, :nonautonomous]) 
            error("usage: HamiltonianVectorField(fun; time_dependence=:autonomous, state_dimension=:N) " *
            "with time_dependence ∈ [:autonomous, :nonautonomous]")
        end
        new{time_dependence, state_dimension}(f)
    end
end

# classical calls
function (F::HamiltonianVectorField{:nonautonomous, N})(t::Time, x::Union{ctNumber, State}, 
        p::Union{ctNumber, Adjoint}, args...; kwargs...)::ctVector where {N}
    return F.f(t, x, p, args...; kwargs...)
end
function (F::HamiltonianVectorField{:autonomous, N})(x::Union{ctNumber, State}, 
        p::Union{ctNumber, Adjoint}, args...; kwargs...)::ctVector where {N}
    return F.f(x, p, args...; kwargs...)
end

# specific calls: inputs are vectors, except times
# state dimension: 1
function (F::HamiltonianVectorField{:nonautonomous, 1})(t::_Time, x::State, p::Adjoint, args...; kwargs...)::ctVector
    return F.f(t.value, x[1], p[1], args...; kwargs...)
end
function (F::HamiltonianVectorField{:autonomous, 1})(t::_Time, x::State, p::Adjoint, args...; kwargs...)::ctVector
    return F.f(x[1], p[1], args...; kwargs...)
end
# state dimension: N>1
function (F::HamiltonianVectorField{:nonautonomous, N})(t::_Time, x::State, p::Adjoint, args...; kwargs...)::ctVector where {N}
    return F.f(t.value, x, p, args...; kwargs...)
end
function (F::HamiltonianVectorField{:autonomous, N})(t::_Time, x::State, p::Adjoint, args...; kwargs...)::ctVector where {N}
    return F.f(x, p, args...; kwargs...)
end

# -------------------------------------------------------------------------------------------
# pre-condition: f returns a scalar if x is a scalar
# we authorize Matrix to be returned if x is a matrix, to integrate ode systems on matrices
"""

$(TYPEDEF)

**Fields**

$(TYPEDFIELDS)

The default value for `time_dependence` is `:autonomous`.

!!! warning

    When the state is of dimension 1, consider `x` as a scalar.

## Classical calls

- state dimension: 1
- time dependence: autonomous

```@example
julia> V = VectorField(x -> 2x) # or time_dependence=:autonomous
julia> V(1)
2
julia> V([1])
1-element Vector{Int64}:
 2
```

- state dimension: 1
- time dependence: nonautonomous

```@example
julia> V = VectorField((t, x) -> t+2x, time_dependence=:nonautonomous)
julia> V(1, 1)
3
```

- state dimension: 2
-  time dependence: autonomous

```@example
julia> V = VectorField(x -> [x[1]^2, x[2]^2]) # or time_dependence=:autonomous
julia> V([1, 0])
2-element Vector{Int64}:
 1
 0
```

- state dimension: 2
- time dependence: nonautonomous

```@example
julia> V = VectorField((t, x) -> [t + x[1]^2, x[2]^2], time_dependence=:nonautonomous)
julia> V(1, [1, 0])
2-element Vector{Int64}:
 2
 0
```

## Specific calls

- state dimension: 1
- time dependence: autonomous

```@example
julia> V = VectorField(x -> 2x, state_dimension=1) # or time_dependence=:autonomous
julia> V(_Time(0), 1)
ERROR: MethodError: no method matching (::VectorField{:autonomous, 1})(::CTBase._Time, ::Int64)
julia> V(_Time(0), [1])
1-element Vector{Int64}:
 2
```

- state dimension: 1
- time dependence: nonautonomous

```@example
julia> V = VectorField((t, x) -> t+2x, state_dimension=1, time_dependence=:nonautonomous)
julia> V(_Time(0), 1)
ERROR: MethodError: no method matching (::VectorField{:nonautonomous, 1})(::CTBase._Time, ::Int64)
julia> V(_Time(1), [1])
1-element Vector{Int64}:
 3
```

- state dimension: N>1
- time dependence: autonomous

```@example
julia> V = VectorField(x -> [x[1]^2, -x[2]^2], state_dimension=2) # or time_dependence=:autonomous
julia> V(_Time(0), [1, 2])
2-element Vector{Int64}:
  1
 -4
```

- state dimension: N>1
- time dependence: nonautonomous

```@example
julia> V = VectorField((t, x) -> [t + x[1]^2, -x[2]^2], state_dimension=2, time_dependence=:nonautonomous)
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
        if !(time_dependence ∈ [:autonomous, :nonautonomous]) 
            error("usage: VectorField(fun; time_dependence=:autonomous, state_dimension=:N) " *
            "with time_dependence ∈ [:autonomous, :nonautonomous]")
        end
        new{time_dependence, state_dimension}(f)
    end
end

# classical calls
function (F::VectorField{:nonautonomous, N})(t::Time, x::Union{ctNumber, State, Matrix{<:ctNumber}}, 
    args...; kwargs...)::Union{ctNumber, ctVector, Matrix{<:ctNumber}} where {N}
    return F.f(t, x, args...; kwargs...)
end
function (F::VectorField{:autonomous, N})(x::Union{ctNumber, State, Matrix{<:ctNumber}}, 
    args...; kwargs...)::Union{ctNumber, ctVector, Matrix{<:ctNumber}} where {N}
    return F.f(x, args...; kwargs...)
end

# specific calls: inputs are vectors, except times
# state dimension: 1
function (F::VectorField{:nonautonomous, 1})(t::_Time, x::State, args...; kwargs...)::ctVector
    return [F.f(t.value, x[1], args...; kwargs...)]
end
function (F::VectorField{:autonomous, 1})(t::_Time, x::State, args...; kwargs...)::ctVector
    return [F.f(x[1], args...; kwargs...)]
end
# state dimension: N>1
function (F::VectorField{:nonautonomous, N})(t::_Time, x::State, args...; kwargs...)::ctVector where {N}
    return F.f(t.value, x, args...; kwargs...)
end
function (F::VectorField{:autonomous, N})(t::_Time, x::State, args...; kwargs...)::ctVector where {N}
    return F.f(x, args...; kwargs...)
end

# -------------------------------------------------------------------------------------------
# pre-condition: f returns a scalar
"""

$(TYPEDEF)

**Fields**

$(TYPEDFIELDS)

The default value for `time_dependence` is `:autonomous`.

!!! warning

    When the state is of dimension 1, consider `x` as a scalar. Same for the control.

## Classical calls

- state dimension: 1
- control dimension: 1
- time dependence: autonomous

```@example
julia> L = Lagrange((x, u) -> x + u) # or time_dependence=:autonomous
julia> L(1, 1)
2
julia> L([1], [1])
ERROR: MethodError: Cannot `convert` an object of type Vector{Int64} to an object of type Real
```

- state dimension: 1
- control dimension: 1
- time dependence: nonautonomous

```@example
julia> L = Lagrange((t, x, u) -> x + u, time_dependence=:nonautonomous)
julia> L(1, 1, 1)
2
julia> L(1, [1], [1])
ERROR: MethodError: Cannot `convert` an object of type Vector{Int64} to an object of type Real
```

- state dimension: 2
- control dimension: 1
- time dependence: autonomous

```@example
julia> L = Lagrange((x, u) -> x[1]^2 + u^2) # or time_dependence=:autonomous
julia> L([1, 2], 1)
2
```

- state dimension: 2
- control dimension: 1
- time dependence: nonautonomous

```@example
julia> L = Lagrange((t, x, u) -> x[1]^2 + u^2, time_dependence=:nonautonomous)
julia> L(1, [1, 2], 1)
2
```

- state dimension: 1
- control dimension: 2
- time dependence: autonomous

```@example
julia> L = Lagrange((x, u) -> x^2 + u[2]^2) # or time_dependence=:autonomous
julia> L(1, [1, 2])
5
```

- state dimension: 1
- control dimension: 2
- time dependence: nonautonomous

```@example
julia> L = Lagrange((t, x, u) -> t + x^2 + u[2]^2, time_dependence=:nonautonomous)
julia> L(1, 1, [1, 2])
6
```

- state dimension: 2
- control dimension: 2
- time dependence: autonomous

```@example
julia> L = Lagrange((x, u) -> x[1]^2 + u[2]^2) # or time_dependence=:autonomous
julia> L([1, 2], [1, 2])
5
```

- state dimension: 2
- control dimension: 2
- time dependence: nonautonomous

```@example
julia> L = Lagrange((t, x, u) -> t + x[1]^2 + u[2]^2, time_dependence=:nonautonomous)
julia> L(1, [1, 2], [1, 2])
6
```

## Specific calls

- state dimension: 1
- control dimension: 1
- time dependence: autonomous

```@example
julia> L = Lagrange((x, u) -> x + u, state_dimension=1, control_dimension=1) # or time_dependence=:autonomous
julia> L(_Time(1), 1, 1)
ERROR: MethodError: no method matching (::Lagrange{:autonomous, 0, 0})(::CTBase._Time, ::Int64, ::Int64)
julia> L(_Time(1), [1], [1])
2
```

- state dimension: 1
- control dimension: 1
- time dependence: nonautonomous

```@example
julia> L = Lagrange((t, x, u) -> t + x + u, state_dimension=1, control_dimension=1, time_dependence=:nonautonomous)
julia> L(_Time(1), 1, 1)
ERROR: MethodError: no method matching (::Lagrange{:nonautonomous, 0, 0})(::CTBase._Time, ::Int64, ::Int64)
julia> L(_Time(1), [1], [1])
3
```

- state dimension: 2
- control dimension: 1
- time dependence: autonomous

```@example
julia> L = Lagrange((x, u) -> x[1]^2 + u^2, state_dimension=2, control_dimension=1) # or time_dependence=:autonomous
julia> L(_Time(1), [1, 2], 1)
ERROR: MethodError: no method matching (::Lagrange{:autonomous, 0, 0})(::CTBase._Time, ::Vector{Int64}, ::Int64)
julia> L(_Time(1), [1, 2], [1])
2
```

- state dimension: 2
- control dimension: 1
- time dependence: nonautonomous

```@example
julia> L = Lagrange((t, x, u) -> t + x[1]^2 + u^2, state_dimension=2, control_dimension=1, time_dependence=:nonautonomous)
julia> L(_Time(1), [1, 2], 1)
ERROR: MethodError: no method matching (::Lagrange{:nonautonomous, 0, 0})(::CTBase._Time, ::Vector{Int64}, ::Int64)
julia> L(_Time(1), [1, 2], [1])
3
```

- state dimension: 1
- control dimension: 2
- time dependence: autonomous

```@example
julia> L = Lagrange((x, u) -> x^2 + u[2]^2, state_dimension=1, control_dimension=2) # or time_dependence=:autonomous
julia> L(_Time(1), 1, [1, 2])
ERROR: MethodError: no method matching (::Lagrange{:autonomous, 0, 0})(::CTBase._Time, ::Int64, ::Vector{Int64})
julia> L(_Time(1), [1], [1, 2])
5
```

- state dimension: 1
- control dimension: 2
- time dependence: nonautonomous

```@example
julia> L = Lagrange((t, x, u) -> t + x^2 + u[2]^2, state_dimension=1, control_dimension=2, time_dependence=:nonautonomous)
julia> L(_Time(1), 1, [1, 2])
ERROR: MethodError: no method matching (::Lagrange{:nonautonomous, 0, 0})(::CTBase._Time, ::Int64, ::Vector{Int64})
julia> L(_Time(1), [1], [1, 2])
6
```

- state dimension: 2
- control dimension: 2
- time dependence: autonomous

```@example
julia> L = Lagrange((x, u) -> x[1]^2 + u[2]^2, state_dimension=2, control_dimension=2) # or time_dependence=:autonomous
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
        if !(time_dependence ∈ [:autonomous, :nonautonomous]) 
            error("usage: Lagrange(fun; time_dependence=:autonomous, state_dimension=:N, control_dimension=:M) " *
            "with time_dependence ∈ [:autonomous, :nonautonomous]")
        end
        new{time_dependence, state_dimension, control_dimension}(f)
    end
end

# classical calls
function (F::Lagrange{:nonautonomous, N, M})(t::Time, x::Union{ctNumber, State}, 
    u::Union{ctNumber, Control}, args...; kwargs...)::ctNumber where {N, M}
    return F.f(t, x, u, args...; kwargs...)
end
function (F::Lagrange{:autonomous, N, M})(x::Union{ctNumber, State}, 
    u::Union{ctNumber, Control}, args...; kwargs...)::ctNumber where {N, M}
    return F.f(x, u, args...; kwargs...)
end

# specific calls: inputs are vectors, except times
# state dimension: 1
# control dimension: 1
function (F::Lagrange{:nonautonomous, 1, 1})(t::_Time, x::State, u::Control, args...; kwargs...)::ctNumber
    return F.f(t.value, x[1], u[1], args...; kwargs...)
end
function (F::Lagrange{:autonomous, 1, 1})(t::_Time, x::State, u::Control, args...; kwargs...)::ctNumber
    return F.f(x[1], u[1], args...; kwargs...)
end
# state dimension: N>1
# control dimension: 1
function (F::Lagrange{:nonautonomous, N, 1})(t::_Time, x::State, u::Control, args...; kwargs...)::ctNumber where {N}
    return F.f(t.value, x, u[1], args...; kwargs...)
end
function (F::Lagrange{:autonomous, N, 1})(t::_Time, x::State, u::Control, args...; kwargs...)::ctNumber where {N}
    return F.f(x, u[1], args...; kwargs...)
end
# state dimension: 1
# control dimension: M>1
function (F::Lagrange{:nonautonomous, 1, M})(t::_Time, x::State, u::Control, args...; kwargs...)::ctNumber where {M}
    return F.f(t.value, x[1], u, args...; kwargs...)
end
function (F::Lagrange{:autonomous, 1, M})(t::_Time, x::State, u::Control, args...; kwargs...)::ctNumber where {M}
    return F.f(x[1], u, args...; kwargs...)
end
# state dimension: N>1
# control dimension: M>1
function (F::Lagrange{:nonautonomous, N, M})(t::_Time, x::State, u::Control, args...; kwargs...)::ctNumber where {N, M}
    return F.f(t.value, x, u, args...; kwargs...)
end
function (F::Lagrange{:autonomous, N, M})(t::_Time, x::State, u::Control, args...; kwargs...)::ctNumber where {N, M}
    return F.f(x, u, args...; kwargs...)
end

# -------------------------------------------------------------------------------------------
# pre-condition: f returns a scalar if x is scalar
struct Dynamics{time_dependence, state_dimension, control_dimension}
    f::Function
    function Dynamics(f::Function; 
        state_dimension::Union{Symbol,Dimension}=__state_dimension(),
        control_dimension::Union{Symbol,Dimension}=__control_dimension(),
        time_dependence::Union{Nothing,Symbol}=__fun_time_dependence())
        if !(time_dependence ∈ [:autonomous, :nonautonomous]) 
            error("usage: Dynamics(fun; time_dependence=:autonomous, state_dimension=:N, control_dimension=:M) " *
            "with time_dependence ∈ [:autonomous, :nonautonomous]")
        end
        new{time_dependence, state_dimension, control_dimension}(f)
    end
end

# classical calls
function (F::Dynamics{:nonautonomous, N, M})(t::Time, x::Union{ctNumber, State}, 
    u::Union{ctNumber, Control}, args...; kwargs...)::Union{ctNumber, ctVector} where {N, M}
    return F.f(t, x, u, args...; kwargs...)
end
function (F::Dynamics{:autonomous, N, M})(x::Union{ctNumber, State}, 
    u::Union{ctNumber, Control}, args...; kwargs...)::Union{ctNumber, ctVector} where {N, M}
    return F.f(x, u, args...; kwargs...)
end

# specific calls: inputs are vectors, except times. output is a vector
# state dimension: 1
# control dimension: 1
function (F::Dynamics{:nonautonomous, 1, 1})(t::_Time, x::State, u::Control, args...; kwargs...)::ctVector
    return [F.f(t.value, x[1], u[1], args...; kwargs...)]
end
function (F::Dynamics{:autonomous, 1, 1})(t::_Time, x::State, u::Control, args...; kwargs...)::ctVector
    return [F.f(x[1], u[1], args...; kwargs...)]
end
# state dimension: N>1
# control dimension: 1
function (F::Dynamics{:nonautonomous, N, 1})(t::_Time, x::State, u::Control, args...; kwargs...)::ctVector where {N}
    return F.f(t.value, x, u[1], args...; kwargs...)
end
function (F::Dynamics{:autonomous, N, 1})(t::_Time, x::State, u::Control, args...; kwargs...)::ctVector where {N}
    return F.f(x, u[1], args...; kwargs...)
end
# state dimension: 1
# control dimension: M>1
function (F::Dynamics{:nonautonomous, 1, M})(t::_Time, x::State, u::Control, args...; kwargs...)::ctVector where {M}
    return [F.f(t.value, x[1], u, args...; kwargs...)]
end
function (F::Dynamics{:autonomous, 1, M})(t::_Time, x::State, u::Control, args...; kwargs...)::ctVector where {M}
    return [F.f(x[1], u, args...; kwargs...)]
end
# state dimension: N>1
# control dimension: M>1
function (F::Dynamics{:nonautonomous, N, M})(t::_Time, x::State, u::Control, args...; kwargs...)::ctVector where {N, M}
    return F.f(t.value, x, u, args...; kwargs...)
end
function (F::Dynamics{:autonomous, N, M})(t::_Time, x::State, u::Control, args...; kwargs...)::ctVector where {N, M}
    return F.f(x, u, args...; kwargs...)
end

# -------------------------------------------------------------------------------------------
# pre-condition: f returns a scalar if the output is one dimensional
struct StateConstraint{time_dependence, state_dimension, constraint_dimension}
    f::Function
    function StateConstraint(f::Function; 
        state_dimension::Union{Symbol,Dimension}=__state_dimension(),
        constraint_dimension::Union{Symbol,Dimension}=__constraint_dimension(),
        time_dependence::Union{Nothing,Symbol}=__fun_time_dependence())
        if !(time_dependence ∈ [:autonomous, :nonautonomous]) 
            error("usage: StateConstraint(fun; time_dependence=:autonomous, state_dimension=:N, constraint_dimension=:K) " *
            "with time_dependence ∈ [:autonomous, :nonautonomous]")
        end
        new{time_dependence, state_dimension, constraint_dimension}(f)
    end
end

# classical calls
function (F::StateConstraint{:nonautonomous, N, K})(t::Time, x::Union{ctNumber, State}, 
    args...; kwargs...)::Union{ctNumber, ctVector} where {N, K}
    return F.f(t, x, args...; kwargs...)
end
function (F::StateConstraint{:autonomous, N, K})(x::Union{ctNumber, State}, 
    args...; kwargs...)::Union{ctNumber, ctVector} where {N, K}
    return F.f(x, args...; kwargs...)
end

# specific calls: inputs are vectors, except times

# state dimension: 1
# constraint dimension: 1
function (F::StateConstraint{:nonautonomous, 1, 1})(t::_Time, x::State, args...; kwargs...)::ctVector
    return [F.f(t.value, x[1], args...; kwargs...)]
end
function (F::StateConstraint{:autonomous, 1, 1})(t::_Time, x::State, args...; kwargs...)::ctVector
    return [F.f(x[1], args...; kwargs...)]
end

# state dimension: N>1
# constraint dimension: 1
function (F::StateConstraint{:nonautonomous, N, 1})(t::_Time, x::State, args...; kwargs...)::ctVector where {N}
    return [F.f(t.value, x, args...; kwargs...)]
end
function (F::StateConstraint{:autonomous, N, 1})(t::_Time, x::State, args...; kwargs...)::ctVector where {N}
    return [F.f(x, args...; kwargs...)]
end

# state dimension: 1
# constraint dimension: K>1
function (F::StateConstraint{:nonautonomous, 1, K})(t::_Time, x::State, args...; kwargs...)::ctVector where {K}
    return F.f(t.value, x[1], args...; kwargs...)
end
function (F::StateConstraint{:autonomous, 1, K})(t::_Time, x::State, args...; kwargs...)::ctVector where {K}
    return F.f(x[1], args...; kwargs...)
end

# state dimension: N>1
# constraint dimension: K>1
function (F::StateConstraint{:nonautonomous, N, K})(t::_Time, x::State, args...; kwargs...)::ctVector where {N, K}
    return F.f(t.value, x, args...; kwargs...)
end
function (F::StateConstraint{:autonomous, N, K})(t::_Time, x::State, args...; kwargs...)::ctVector where {N, K}
    return F.f(x, args...; kwargs...)
end

# -------------------------------------------------------------------------------------------
# pre-condition: f returns a scalar if the output is one dimensional
struct ControlConstraint{time_dependence, control_dimension, constraint_dimension}
    f::Function
    function ControlConstraint(f::Function; 
        control_dimension::Union{Symbol,Dimension}=__control_dimension(),
        constraint_dimension::Union{Symbol,Dimension}=__constraint_dimension(),
        time_dependence::Union{Nothing,Symbol}=__fun_time_dependence())
        if !(time_dependence ∈ [:autonomous, :nonautonomous]) 
            error("usage: ControlConstraint(fun; time_dependence=:autonomous, control_dimension=:M, constraint_dimension=:K) " *
            "with time_dependence ∈ [:autonomous, :nonautonomous]")
        end
        new{time_dependence, control_dimension, constraint_dimension}(f)
    end
end

# classical calls
function (F::ControlConstraint{:nonautonomous, M, K})(t::Time, u::Union{ctNumber, Control}, 
    args...; kwargs...)::Union{ctNumber, ctVector} where {M, K}
    return F.f(t, u, args...; kwargs...)
end
function (F::ControlConstraint{:autonomous, M, K})(u::Union{ctNumber, Control}, 
    args...; kwargs...)::Union{ctNumber, ctVector} where {M, K}
    return F.f(u, args...; kwargs...)
end

# specific calls: inputs are vectors, except times

# control dimension: 1
# constraint dimension: 1
function (F::ControlConstraint{:nonautonomous, 1, 1})(t::_Time, u::Control, args...; kwargs...)::ctVector
    return [F.f(t.value, u[1], args...; kwargs...)]
end
function (F::ControlConstraint{:autonomous, 1, 1})(t::_Time, u::Control, args...; kwargs...)::ctVector
    return [F.f(u[1], args...; kwargs...)]
end

# control dimension: M>1
# constraint dimension: 1
function (F::ControlConstraint{:nonautonomous, M, 1})(t::_Time, u::Control, args...; kwargs...)::ctVector where {M}
    return [F.f(t.value, u, args...; kwargs...)]
end
function (F::ControlConstraint{:autonomous, M, 1})(t::_Time, u::Control, args...; kwargs...)::ctVector where {M}
    return [F.f(u, args...; kwargs...)]
end

# control dimension: 1
# constraint dimension: K>1
function (F::ControlConstraint{:nonautonomous, 1, K})(t::_Time, u::Control, args...; kwargs...)::ctVector where {K}
    return F.f(t.value, u[1], args...; kwargs...)
end
function (F::ControlConstraint{:autonomous, 1, K})(t::_Time, u::Control, args...; kwargs...)::ctVector where {K}
    return F.f(u[1], args...; kwargs...)
end

# control dimension: M>1
# constraint dimension: K>1
function (F::ControlConstraint{:nonautonomous, M, K})(t::_Time, u::Control, args...; kwargs...)::ctVector where {M, K}
    return F.f(t.value, u, args...; kwargs...)
end
function (F::ControlConstraint{:autonomous, M, K})(t::_Time, u::Control, args...; kwargs...)::ctVector where {M, K}
    return F.f(u, args...; kwargs...)
end

# -------------------------------------------------------------------------------------------
# pre-condition: f returns a scalar if the output is one dimensional
struct MixedConstraint{time_dependence, state_dimension, control_dimension, constraint_dimension}
    f::Function
    function MixedConstraint(f::Function; 
        state_dimension::Union{Symbol,Dimension}=__state_dimension(),
        control_dimension::Union{Symbol,Dimension}=__control_dimension(),
        constraint_dimension::Union{Symbol,Dimension}=__constraint_dimension(),
        time_dependence::Union{Nothing,Symbol}=__fun_time_dependence())
        if !(time_dependence ∈ [:autonomous, :nonautonomous]) 
            error("usage: MixedConstraint(fun; time_dependence=:autonomous, " * 
            "state_dimension=:N, control_dimension=:M, constraint_dimension=:K) " *
            "with time_dependence ∈ [:autonomous, :nonautonomous]")
        end
        new{time_dependence, state_dimension, control_dimension, constraint_dimension}(f)
    end
end

# classical calls
function (F::MixedConstraint{:nonautonomous, N, M, K})(t::Time, x::Union{ctNumber, State},
    u::Union{ctNumber, Control}, args...; kwargs...)::Union{ctNumber, ctVector} where {N, M, K}
    return F.f(t, x, u, args...; kwargs...)
end
function (F::MixedConstraint{:autonomous, N, M, K})(x::Union{ctNumber, State},
    u::Union{ctNumber, Control}, args...; kwargs...)::Union{ctNumber, ctVector} where {N, M, K}
    return F.f(x, u, args...; kwargs...)
end

# specific calls: inputs are vectors, except times

# state dimension: 1
# control dimension: 1
# constraint dimension: 1
function (F::MixedConstraint{:nonautonomous, 1, 1, 1})(t::_Time, x::State, u::Control, args...; kwargs...)::ctVector
    return [F.f(t.value, x[1], u[1], args...; kwargs...)]
end
function (F::MixedConstraint{:autonomous, 1, 1, 1})(t::_Time, x::State, u::Control, args...; kwargs...)::ctVector
    return [F.f(x[1], u[1], args...; kwargs...)]
end

# state dimension: N>1
# control dimension: 1
# constraint dimension: 1
function (F::MixedConstraint{:nonautonomous, N, 1, 1})(t::_Time, x::State, u::Control, args...; kwargs...)::ctVector where {N}
    return [F.f(t.value, x, u[1], args...; kwargs...)]
end
function (F::MixedConstraint{:autonomous, N, 1, 1})(t::_Time, x::State, u::Control, args...; kwargs...)::ctVector where {N}
    return [F.f(x, u[1], args...; kwargs...)]
end

# state dimension: 1
# control dimension: M>1
# constraint dimension: 1
function (F::MixedConstraint{:nonautonomous, 1, M, 1})(t::_Time, x::State, u::Control, args...; kwargs...)::ctVector where {M}
    return [F.f(t.value, x[1], u, args...; kwargs...)]
end
function (F::MixedConstraint{:autonomous, 1, M, 1})(t::_Time, x::State, u::Control, args...; kwargs...)::ctVector where {M}
    return [F.f(x[1], u, args...; kwargs...)]
end

# state dimension: N>1
# control dimension: M>1
# constraint dimension: 1
function (F::MixedConstraint{:nonautonomous, N, M, 1})(t::_Time, x::State, u::Control, args...; kwargs...)::ctVector where {N, M}
    return [F.f(t.value, x, u, args...; kwargs...)]
end
function (F::MixedConstraint{:autonomous, N, M, 1})(t::_Time, x::State, u::Control, args...; kwargs...)::ctVector where {N, M}
    return [F.f(x, u, args...; kwargs...)]
end

# state dimension: 1
# control dimension: 1
# constraint dimension: K>1
function (F::MixedConstraint{:nonautonomous, 1, 1, K})(t::_Time, x::State, u::Control, args...; kwargs...)::ctVector where {K}
    return F.f(t.value, x[1], u[1], args...; kwargs...)
end
function (F::MixedConstraint{:autonomous, 1, 1, K})(t::_Time, x::State, u::Control, args...; kwargs...)::ctVector where {K}
    return F.f(x[1], u[1], args...; kwargs...)
end

# state dimension: N>1
# control dimension: 1
# constraint dimension: K>1
function (F::MixedConstraint{:nonautonomous, N, 1, K})(t::_Time, x::State, u::Control, args...; kwargs...)::ctVector where {N, K}
    return F.f(t.value, x, u[1], args...; kwargs...)
end
function (F::MixedConstraint{:autonomous, N, 1, K})(t::_Time, x::State, u::Control, args...; kwargs...)::ctVector where {N, K}
    return F.f(x, u[1], args...; kwargs...)
end

# state dimension: 1
# control dimension: M>1
# constraint dimension: K>1
function (F::MixedConstraint{:nonautonomous, 1, M, K})(t::_Time, x::State, u::Control, args...; kwargs...)::ctVector where {M, K}
    return F.f(t.value, x[1], u, args...; kwargs...)
end
function (F::MixedConstraint{:autonomous, 1, M, K})(t::_Time, x::State, u::Control, args...; kwargs...)::ctVector where {M, K}
    return F.f(x[1], u, args...; kwargs...)
end

# state dimension: N>1
# control dimension: M>1
# constraint dimension: K>1
function (F::MixedConstraint{:nonautonomous, N, M, K})(t::_Time, x::State, u::Control, args...; kwargs...)::ctVector where {N, M, K}
    return F.f(t.value, x, u, args...; kwargs...)
end
function (F::MixedConstraint{:autonomous, N, M, K})(t::_Time, x::State, u::Control, args...; kwargs...)::ctVector where {N, M, K}
    return F.f(x, u, args...; kwargs...)
end

# -------------------------------------------------------------------------------------------
# pre-condition: f returns a scalar if the output is one dimensional
struct FeedbackControl{time_dependence}
    f::Function
    function FeedbackControl(f::Function; 
        time_dependence::Union{Nothing,Symbol}=__fun_time_dependence())
        if !(time_dependence ∈ [:autonomous, :nonautonomous]) 
            error("usage: FeedbackControl(fun; time_dependence=:autonomous) " *
            "with time_dependence ∈ [:autonomous, :nonautonomous]")
        end
        new{time_dependence}(f)
    end
end

# classical calls
function (F::FeedbackControl{:nonautonomous})(t::Time, x::Union{ctNumber, State}, args...; kwargs...)::Union{ctNumber, ctVector}
    return F.f(t, x, args...; kwargs...)
end
function (F::FeedbackControl{:autonomous})(x::Union{ctNumber, State}, args...; kwargs...)::Union{ctNumber, ctVector}
    return F.f(x, args...; kwargs...)
end

# -------------------------------------------------------------------------------------------
# pre-condition: f returns a scalar if the output is one dimensional
struct ControlLaw{time_dependence}
    f::Function
    function ControlLaw(f::Function; 
        time_dependence::Union{Nothing,Symbol}=__fun_time_dependence())
        if !(time_dependence ∈ [:autonomous, :nonautonomous]) 
            error("usage: ControlLaw(fun; time_dependence=:autonomous) " *
            "with time_dependence ∈ [:autonomous, :nonautonomous]")
        end
        new{time_dependence}(f)
    end
end

# classical calls
function (F::ControlLaw{:nonautonomous})(t::Time, x::Union{ctNumber, State},
    p::Union{ctNumber, Adjoint}, args...; kwargs...)::Union{ctNumber, ctVector}
    return F.f(t, x, p, args...; kwargs...)
end
function (F::ControlLaw{:autonomous})(x::Union{ctNumber, State},
    p::Union{ctNumber, Adjoint}, args...; kwargs...)::Union{ctNumber, ctVector}
    return F.f(x, p, args...; kwargs...)
end

# -------------------------------------------------------------------------------------------
# pre-condition: f returns a scalar if the output is one dimensional
struct Multiplier{time_dependence}
    f::Function
    function Multiplier(f::Function; 
        time_dependence::Union{Nothing,Symbol}=__fun_time_dependence())
        if !(time_dependence ∈ [:autonomous, :nonautonomous]) 
            error("usage: Multiplier(fun; time_dependence=:autonomous) " *
            "with time_dependence ∈ [:autonomous, :nonautonomous]")
        end
        new{time_dependence}(f)
    end
end

# classical calls
function (F::Multiplier{:nonautonomous})(t::Time, x::Union{ctNumber, State},
    p::Union{ctNumber, Adjoint}, args...; kwargs...)::Union{ctNumber, ctVector}
    return F.f(t, x, p, args...; kwargs...)
end
function (F::Multiplier{:autonomous})(x::Union{ctNumber, State},
    p::Union{ctNumber, Adjoint}, args...; kwargs...)::Union{ctNumber, ctVector}
    return F.f(x, p, args...; kwargs...)
end