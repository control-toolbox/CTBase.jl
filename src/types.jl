"""
$(TYPEDEF)
"""
abstract type AbstractOptimalControlModel end

"""
$(TYPEDEF)
"""
abstract type TimeDependence end

"""
$(TYPEDEF)
"""
abstract type Autonomous <: TimeDependence end

"""
$(TYPEDEF)
"""
abstract type NonAutonomous <: TimeDependence end

"""
$(TYPEDEF)
"""
abstract type VariableDependence end

"""
$(TYPEDEF)
"""
abstract type NonFixed <: VariableDependence end

"""
$(TYPEDEF)
"""
abstract type Fixed <: VariableDependence end

# --------------------------------------------------------------------------------------------------
# Callable types

"""
$(TYPEDEF)

**Fields**

$(TYPEDFIELDS)

The default value for `variable_dependence` is `Fixed`.

## Constructor

The constructor ```BoundaryConstraint``` returns a ```BoundaryConstraint``` of a function.
The function must take 2 or 3 arguments `(x0, xf)` or `(x0, xf, v)`, if the function is variable, it must be specified. 
Dependencies are specified with a boolean, `variable`, `false` by default or with a `DataType`, `NonFixed/Fixed`, `Fixed` by default.

## *Examples*

```@example
julia> B = BoundaryConstraint((x0, xf) -> [xf[2]-x0[1], 2xf[1]+x0[2]^2])
julia> B = BoundaryConstraint((x0, xf, v) -> [v[3]+xf[2]-x0[1], v[1]-v[2]+2xf[1]+x0[2]^2], variable=true)
julia> B = BoundaryConstraint((x0, xf, v) -> [v[3]+xf[2]-x0[1], v[1]-v[2]+2xf[1]+x0[2]^2], NonFixed)
```
!!! warning

    When the state is of dimension 1, consider `x0` and `xf` as a scalar. When the constraint is dimension 1, return a scalar.

## Call

The call returns the evaluation of the `BoundaryConstraint` for given values.
If a variable is given for a non variable dependent boundary constraint, it will be ignored.

## *Examples*

```@example
julia> B = BoundaryConstraint((x0, xf) -> [xf[2]-x0[1], 2xf[1]+x0[2]^2])
julia> B([0, 0], [1, 1])
[1, 2]
julia> B = BoundaryConstraint((x0, xf) -> [xf[2]-x0[1], 2xf[1]+x0[2]^2])
julia> B([0, 0], [1, 1],Real[])
[1, 2]
julia> B = BoundaryConstraint((x0, xf, v) -> [v[3]+xf[2]-x0[1], v[1]-v[2]+2xf[1]+x0[2]^2], variable=true)
julia> B([0, 0], [1, 1], [1, 2, 3])
[4, 1]
```
"""
struct BoundaryConstraint{TF<:Function,VD<:VariableDependence}
    f::TF
end

struct BoundaryConstraint!{TF<:Function,VD<:VariableDependence}
    f!::TF
end

"""
$(TYPEDEF)

**Fields**

$(TYPEDFIELDS)

The default value for `variable_dependence` is `Fixed`.

## Constructor

The constructor ```Mayer``` returns a ```Mayer``` cost of a function.
The function must take 2 or 3 arguments `(x0, xf)` or `(x0, xf, v)`, if the function is variable, it must be specified. 
Dependencies are specified with a boolean, `variable`, `false` by default or with a `DataType`, `NonFixed/Fixed`, `Fixed` by default.

## *Examples*

```@example
julia> G = Mayer((x0, xf) -> xf[2]-x0[1])
julia> G = Mayer((x0, xf, v) -> v[3]+xf[2]-x0[1], variable=true)
julia> G = Mayer((x0, xf, v) -> v[3]+xf[2]-x0[1], NonFixed)
```

!!! warning

    When the state is of dimension 1, consider `x0` and `xf` as a scalar.

## Call

The call returns the evaluation of the `Mayer` cost for given values.
If a variable is given for a non variable dependent Mayer cost, it will be ignored.

## *Examples*

```@example
julia> G = Mayer((x0, xf) -> xf[2]-x0[1])
julia> G([0, 0], [1, 1])
1
julia> G = Mayer((x0, xf) -> xf[2]-x0[1])
julia> G([0, 0], [1, 1],Real[])
1
julia> G = Mayer((x0, xf, v) -> v[3]+xf[2]-x0[1], variable=true)
julia> G([0, 0], [1, 1], [1, 2, 3])
4
```
"""
struct Mayer{TF<:Function,VD<:VariableDependence}
    f::TF
end

struct Mayer!{TF<:Function,VD<:VariableDependence}
    f!::TF
end

"""
$(TYPEDEF)

Abstract type for hamiltonians.
"""
abstract type AbstractHamiltonian{TD<:TimeDependence,VD<:VariableDependence} end

"""
$(TYPEDEF)

Abstract type for vector fields.
"""
abstract type AbstractVectorField{TD<:TimeDependence,VD<:VariableDependence} end

"""
$(TYPEDEF)

**Fields**

$(TYPEDFIELDS)

The default values for `time_dependence` and `variable_dependence` are `Autonomous` and `Fixed` respectively.

## Constructor

The constructor ```Hamiltonian``` returns a ```Hamiltonian``` of a function.
The function must take 2 to 4 arguments, `(x, p)` to `(t, x, p, v)`, if the function is variable or non autonomous, it must be specified. 
Dependencies are specified either with :
 - booleans, `autonomous` and `variable`, respectively `true` and `false` by default 
 - `DataType`, `Autonomous`/`NonAutonomous` and `NonFixed`/`Fixed`, respectively `Autonomous` and `Fixed` by default.

## *Examples*

```@example
julia> Hamiltonian((x, p) -> x + p, Int64)
IncorrectArgument 
julia> Hamiltonian((x, p) -> x + p, Int64)
IncorrectArgument
julia> H = Hamiltonian((x, p) -> x[1]^2+2p[2])
julia> H = Hamiltonian((t, x, p, v) -> [t+x[1]^2+2p[2]+v[3]], autonomous=false, variable=true)
julia> H = Hamiltonian((t, x, p, v) -> [t+x[1]^2+2p[2]+v[3]], NonAutonomous, NonFixed)
```

!!! warning

    When the state and costate are of dimension 1, consider `x` and `p` as scalars.

## Call

The call returns the evaluation of the `Hamiltonian` for given values.

## *Examples*

```@example
julia> H = Hamiltonian((x, p) -> [x[1]^2+2p[2]]) # autonomous=true, variable=false
julia> H([1, 0], [0, 1])
MethodError # H must return a scalar
julia> H = Hamiltonian((x, p) -> x[1]^2+2p[2])
julia> H([1, 0], [0, 1])
3
julia> t = 1
julia> v = Real[]
julia> H(t, [1, 0], [0, 1])
MethodError
julia> H([1, 0], [0, 1], v)
MethodError 
julia> H(t, [1, 0], [0, 1], v)
3
julia> H = Hamiltonian((x, p, v) -> x[1]^2+2p[2]+v[3], variable=true)
julia> H([1, 0], [0, 1], [1, 2, 3])
6
julia> H(t, [1, 0], [0, 1], [1, 2, 3])
6
julia> H = Hamiltonian((t, x, p) -> t+x[1]^2+2p[2], autonomous=false)
julia> H(1, [1, 0], [0, 1])
4
julia> H(1, [1, 0], [0, 1], v)
4
julia> H = Hamiltonian((t, x, p, v) -> t+x[1]^2+2p[2]+v[3], autonomous=false, variable=true)
julia> H(1, [1, 0], [0, 1], [1, 2, 3])
7
```
"""
struct Hamiltonian{TF<:Function,TD<:TimeDependence,VD<:VariableDependence} <:
       AbstractHamiltonian{TD,VD}
    f::TF
end

"""
$(TYPEDEF)

**Fields**

$(TYPEDFIELDS)

The default values for `time_dependence` and `variable_dependence` are `Autonomous` and `Fixed` respectively.

## Constructor

The constructor ```VectorField``` returns a ```VectorField``` of a function.
The function must take 1 to 3 arguments, `x` to `(t, x, v)`, if the function is variable or non autonomous, it must be specified. 
Dependencies are specified either with :
- booleans, `autonomous` and `variable`, respectively `true` and `false` by default 
- `DataType`, `Autonomous`/`NonAutonomous` and `NonFixed`/`Fixed`, respectively `Autonomous` and `Fixed` by default.

## *Examples*

```@example
julia> VectorField(x -> [x[1]^2, 2x[2]], Int64)
IncorrectArgument
julia> VectorField(x -> [x[1]^2, 2x[2]], Int64)
IncorrectArgument
julia> V = VectorField(x -> [x[1]^2, 2x[2]]) # autonomous=true, variable=false
julia> V = VectorField((x, v) -> [x[1]^2, 2x[2]+v[3]], variable=true)
julia> V = VectorField((t, x) -> [t+x[1]^2, 2x[2]], autonomous=false)
julia> V = VectorField((t, x, v) -> [t+x[1]^2, 2x[2]+v[3]], autonomous=false, variable=true)
julia> V = VectorField((x, v) -> [x[1]^2, 2x[2]+v[3]], NonFixed)
julia> V = VectorField((t, x) -> [t+x[1]^2, 2x[2]], NonAutonomous)
julia> V = VectorField((t, x, v) -> [t+x[1]^2, 2x[2]+v[3]], NonAutonomous, NonFixed)
```

!!! warning

    When the state is of dimension 1, consider `x` as a scalar.

## Call

The call returns the evaluation of the `VectorField` for given values.

## *Examples*

```@example
julia> V = VectorField(x -> [x[1]^2, 2x[2]]) # autonomous=true, variable=false
julia> V([1, -1])
[1, -2]
julia> t = 1
julia> v = Real[]
julia> V(t, [1, -1])
MethodError
julia> V([1, -1], v)
MethodError
julia> V(t, [1, -1], v)
[1, -2]
julia> V = VectorField((x, v) -> [x[1]^2, 2x[2]+v[3]], variable=true)
julia> V([1, -1], [1, 2, 3])
[1, 1]
julia> V(t, [1, -1], [1, 2, 3])
[1, 1]
julia> V = VectorField((t, x) -> [t+x[1]^2, 2x[2]], autonomous=false)
julia> V(1, [1, -1])
[2, -2]
julia> V(1, [1, -1], v)
[2, -2]
julia> V = VectorField((t, x, v) -> [t+x[1]^2, 2x[2]+v[3]], autonomous=false, variable=true)
julia> V(1, [1, -1], [1, 2, 3])
[2, 1]
```
"""
struct VectorField{TF<:Function,TD<:TimeDependence,VD<:VariableDependence} <:
       AbstractVectorField{TD,VD}
    f::TF
end

"""
$(TYPEDEF)

**Fields**

$(TYPEDFIELDS)

The default values for `time_dependence` and `variable_dependence` are `Autonomous` and `Fixed` respectively.

## Constructor

The constructor ```HamiltonianVectorField``` returns a ```HamiltonianVectorField``` of a function.
The function must take 2 to 4 arguments, `(x, p)` to `(t, x, p, v)`, if the function is variable or non autonomous, it must be specified. 
Dependencies are specified either with :
- booleans, `autonomous` and `variable`, respectively `true` and `false` by default 
- `DataType`, `Autonomous`/`NonAutonomous` and `NonFixed`/`Fixed`, respectively `Autonomous` and `Fixed` by default.

## *Examples*

```@example
julia> HamiltonianVectorField((x, p) -> [x[1]^2+2p[2], x[2]-3p[2]^2], Int64)
IncorrectArgument
julia> HamiltonianVectorField((x, p) -> [x[1]^2+2p[2], x[2]-3p[2]^2], Int64)
IncorrectArgument
julia> Hv = HamiltonianVectorField((x, p) -> [x[1]^2+2p[2], x[2]-3p[2]^2]) # autonomous=true, variable=false
julia> Hv = HamiltonianVectorField((x, p, v) -> [x[1]^2+2p[2]+v[3], x[2]-3p[2]^2+v[4]], variable=true)
julia> Hv = HamiltonianVectorField((t, x, p) -> [t+x[1]^2+2p[2], x[2]-3p[2]^2], autonomous=false)
julia> Hv = HamiltonianVectorField((t, x, p, v) -> [t+x[1]^2+2p[2]+v[3], x[2]-3p[2]^2+v[4]], autonomous=false, variable=true)
julia> Hv = HamiltonianVectorField((x, p, v) -> [x[1]^2+2p[2]+v[3], x[2]-3p[2]^2+v[4]], NonFixed)
julia> Hv = HamiltonianVectorField((t, x, p) -> [t+x[1]^2+2p[2], x[2]-3p[2]^2], NonAutonomous)
julia> Hv = HamiltonianVectorField((t, x, p, v) -> [t+x[1]^2+2p[2]+v[3], x[2]-3p[2]^2+v[4]], NonAutonomous, NonFixed)
```

!!! warning

    When the state and costate are of dimension 1, consider `x` and `p` as scalars.

## Call

The call returns the evaluation of the `HamiltonianVectorField` for given values.

## *Examples*

```@example
julia> Hv = HamiltonianVectorField((x, p) -> [x[1]^2+2p[2], x[2]-3p[2]^2]) # autonomous=true, variable=false
julia> Hv([1, 0], [0, 1])
[3, -3]
julia> t = 1
julia> v = Real[]
julia> Hv(t, [1, 0], [0, 1])
MethodError
julia> Hv([1, 0], [0, 1], v)
MethodError
julia> Hv(t, [1, 0], [0, 1], v)
[3, -3]
julia> Hv = HamiltonianVectorField((x, p, v) -> [x[1]^2+2p[2]+v[3], x[2]-3p[2]^2+v[4]], variable=true)
julia> Hv([1, 0], [0, 1], [1, 2, 3, 4])
[6, -3]
julia> Hv(t, [1, 0], [0, 1], [1, 2, 3, 4])
[6, -3]
julia> Hv = HamiltonianVectorField((t, x, p) -> [t+x[1]^2+2p[2], x[2]-3p[2]^2], autonomous=false)
julia> Hv(1, [1, 0], [0, 1])
[4, -3]
julia> Hv(1, [1, 0], [0, 1], v)
[4, -3]
julia> Hv = HamiltonianVectorField((t, x, p, v) -> [t+x[1]^2+2p[2]+v[3], x[2]-3p[2]^2+v[4]], autonomous=false, variable=true)
julia> Hv(1, [1, 0], [0, 1], [1, 2, 3, 4])
[7, -3]
```
"""
struct HamiltonianVectorField{TF<:Function,TD<:TimeDependence,VD<:VariableDependence} <:
       AbstractVectorField{TD,VD}
    f::TF
end

"""
$(TYPEDEF)

**Lifts**

$(TYPEDFIELDS)

The values for `time_dependence` and `variable_dependence` are deternimed by the values of those for the VectorField.

## Constructor

The constructor ```HamiltonianLift``` returns a ```HamiltonianLift``` of a `VectorField`.

## *Examples*

```@example
julia> H = HamiltonianLift(VectorField(x -> [x[1]^2, 2x[2]]))
julia> H = HamiltonianLift(VectorField((x, v) -> [x[1]^2, 2x[2]+v[3]], variable=true))
julia> H = HamiltonianLift(VectorField((t, x) -> [t+x[1]^2, 2x[2]], autonomous=false))
julia> H = HamiltonianLift(VectorField((t, x, v) -> [t+x[1]^2, 2x[2]+v[3]], autonomous=false, variable=true))
julia> H = HamiltonianLift(VectorField(x -> [x[1]^2, 2x[2]]))
julia> H = HamiltonianLift(VectorField((x, v) -> [x[1]^2, 2x[2]+v[3]], NonFixed))
julia> H = HamiltonianLift(VectorField((t, x) -> [t+x[1]^2, 2x[2]], NonAutonomous))
julia> H = HamiltonianLift(VectorField((t, x, v) -> [t+x[1]^2, 2x[2]+v[3]], NonAutonomous, NonFixed))
```

!!! warning

    When the state and costate are of dimension 1, consider `x` and `p` as scalars.

## Call

The call returns the evaluation of the `HamiltonianLift` for given values.

## *Examples*

```@example
julia> H = HamiltonianLift(VectorField(x -> [x[1]^2, 2x[2]]))
julia> H([1, 2], [1, 1])
5
julia> t = 1
julia> v = Real[]
julia> H(t, [1, 0], [0, 1])
MethodError
julia> H([1, 0], [0, 1], v)
MethodError 
julia> H(t, [1, 0], [0, 1], v)
5
julia> H = HamiltonianLift(VectorField((x, v) -> [x[1]^2, 2x[2]+v[3]], variable=true))
julia> H([1, 0], [0, 1], [1, 2, 3])
3
julia> H(t, [1, 0], [0, 1], [1, 2, 3])
3
julia> H = HamiltonianLift(VectorField((t, x) -> [t+x[1]^2, 2x[2]], autonomous=false))
julia> H(1, [1, 2], [1, 1])
6
julia> H(1, [1, 0], [0, 1], v)
6
julia> H = HamiltonianLift(VectorField((t, x, v) -> [t+x[1]^2, 2x[2]+v[3]], autonomous=false, variable=true))
julia> H(1, [1, 0], [0, 1], [1, 2, 3])
3
```

Alternatively, it is possible to construct the `HamiltonianLift` from a `Function` being the `VectorField`.

```@example
julia> HL1 = HamiltonianLift((x, v) -> [x[1]^2,x[2]^2+v], autonomous=true, variable=true)
julia> HL2 = HamiltonianLift(VectorField((x, v) -> [x[1]^2,x[2]^2+v], autonomous=true, variable=true))
julia> HL1([1, 0], [0, 1], 1) == HL2([1, 0], [0, 1], 1)
true
```

"""
struct HamiltonianLift{TV<:VectorField,TD<:TimeDependence,VD<:VariableDependence} <:
       AbstractHamiltonian{TD,VD}
    X::TV
    function HamiltonianLift(
        X::VectorField{<:Function,TD,VD}
    ) where {TD<:TimeDependence,VD<:VariableDependence}
        return new{typeof(X),TD,VD}(X)
    end
end

"""
$(TYPEDEF)

**Fields**

$(TYPEDFIELDS)

The default value for `time_dependence` and `variable_dependence` are `Autonomous` and `Fixed` respectively.

## Constructor

The constructor ```Lagrange``` returns a ```Lagrange``` cost of a function.
The function must take 2 to 4 arguments, `(x, u)` to `(t, x, u, v)`, if the function is variable or non autonomous, it must be specified. 
Dependencies are specified either with :
- booleans, `autonomous` and `variable`, respectively `true` and `false` by default 
- `DataType`, `Autonomous`/`NonAutonomous` and `NonFixed`/`Fixed`, respectively `Autonomous` and `Fixed` by default.

## *Examples*

```@example
julia> Lagrange((x, u) -> 2x[2]-u[1]^2, Int64)
IncorrectArgument
julia> Lagrange((x, u) -> 2x[2]-u[1]^2, Int64)
IncorrectArgument
julia> L = Lagrange((x, u) -> [2x[2]-u[1]^2], autonomous=true, variable=false)
julia> L = Lagrange((x, u) -> 2x[2]-u[1]^2, autonomous=true, variable=false)
julia> L = Lagrange((x, u, v) -> 2x[2]-u[1]^2+v[3], autonomous=true, variable=true)
julia> L = Lagrange((t, x, u) -> t+2x[2]-u[1]^2, autonomous=false, variable=false)
julia> L = Lagrange((t, x, u, v) -> t+2x[2]-u[1]^2+v[3], autonomous=false, variable=true)
julia> L = Lagrange((x, u) -> [2x[2]-u[1]^2], Autonomous, Fixed)
julia> L = Lagrange((x, u) -> 2x[2]-u[1]^2, Autonomous, Fixed)
julia> L = Lagrange((x, u, v) -> 2x[2]-u[1]^2+v[3], Autonomous, NonFixed)
julia> L = Lagrange((t, x, u) -> t+2x[2]-u[1]^2, autonomous=false, Fixed)
julia> L = Lagrange((t, x, u, v) -> t+2x[2]-u[1]^2+v[3], autonomous=false, NonFixed)
```

!!! warning

    When the state is of dimension 1, consider `x` as a scalar. Same for the control.

## Call

The call returns the evaluation of the `Lagrange` cost for given values.

## *Examples*

```@example
julia> L = Lagrange((x, u) -> [2x[2]-u[1]^2], autonomous=true, variable=false)
julia> L([1, 0], [1])
MethodError
julia> L = Lagrange((x, u) -> 2x[2]-u[1]^2, autonomous=true, variable=false)
julia> L([1, 0], [1])
-1
julia> t = 1
julia> v = Real[]
julia> L(t, [1, 0], [1])
MethodError
julia> L([1, 0], [1], v)
MethodError
julia> L(t, [1, 0], [1], v)
-1
julia> L = Lagrange((x, u, v) -> 2x[2]-u[1]^2+v[3], autonomous=true, variable=true)
julia> L([1, 0], [1], [1, 2, 3])
2
julia> L(t, [1, 0], [1], [1, 2, 3])
2
julia> L = Lagrange((t, x, u) -> t+2x[2]-u[1]^2, autonomous=false, variable=false)
julia> L(1, [1, 0], [1])
0
julia> L(1, [1, 0], [1], v)
0
julia> L = Lagrange((t, x, u, v) -> t+2x[2]-u[1]^2+v[3], autonomous=false, variable=true)
julia> L(1, [1, 0], [1], [1, 2, 3])
3
```
"""
struct Lagrange{TF<:Function,TD<:TimeDependence,VD<:VariableDependence}
    f::TF
end

struct Lagrange!{TF<:Function,TD<:TimeDependence,VD<:VariableDependence}
    f!::TF
end

"""
$(TYPEDEF)

**Fields**

$(TYPEDFIELDS)

The default value for `time_dependence` and `variable_dependence` are `Autonomous` and `Fixed` respectively.

## Constructor

The constructor ```Dynamics``` returns a ```Dynamics``` of a function.
The function must take 2 to 4 arguments, `(x, u)` to `(t, x, u, v)`, if the function is variable or non autonomous, it must be specified. 
Dependencies are specified either with :
- booleans, `autonomous` and `variable`, respectively `true` and `false` by default 
- `DataType`, `Autonomous`/`NonAutonomous` and `NonFixed`/`Fixed`, respectively `Autonomous` and `Fixed` by default.

## *Examples*

```@example
julia> Dynamics((x, u) -> [2x[2]-u^2, x[1]], Int64)
IncorrectArgument
julia> Dynamics((x, u) -> [2x[2]-u^2, x[1]], Int64)
IncorrectArgument
julia> D = Dynamics((x, u) -> [2x[2]-u^2, x[1]], Autonomous, Fixed)
julia> D = Dynamics((x, u, v) -> [2x[2]-u^2+v[3], x[1]], Autonomous, NonFixed)
julia> D = Dynamics((t, x, u) -> [t+2x[2]-u^2, x[1]], NonAutonomous, Fixed)
julia> D = Dynamics((t, x, u, v) -> [t+2x[2]-u^2+v[3], x[1]], NonAutonomous, NonFixed)
julia> D = Dynamics((x, u) -> [2x[2]-u^2, x[1]], autonomous=true, variable=false)
julia> D = Dynamics((x, u, v) -> [2x[2]-u^2+v[3], x[1]], autonomous=true, variable=true)
julia> D = Dynamics((t, x, u) -> [t+2x[2]-u^2, x[1]], autonomous=false, variable=false)
julia> D = Dynamics((t, x, u, v) -> [t+2x[2]-u^2+v[3], x[1]], autonomous=false, variable=true)
```

!!! warning

    When the state is of dimension 1, consider `x` as a scalar. Same for the control.

## Call

The call returns the evaluation of the `Dynamics` for given values.

## *Examples*

```@example
julia> D = Dynamics((x, u) -> [2x[2]-u^2, x[1]], autonomous=true, variable=false)
julia> D([1, 0], 1)
[-1, 1]
julia> t = 1
julia> v = Real[]
julia> D(t, [1, 0], 1, v)
[-1, 1]
julia> D = Dynamics((x, u, v) -> [2x[2]-u^2+v[3], x[1]], autonomous=true, variable=true)
julia> D([1, 0], 1, [1, 2, 3])
[2, 1]
julia> D(t, [1, 0], 1, [1, 2, 3])
[2, 1]
julia> D = Dynamics((t, x, u) -> [t+2x[2]-u^2, x[1]], autonomous=false, variable=false)
julia> D(1, [1, 0], 1)
[0, 1]
julia> D(1, [1, 0], 1, v)
[0, 1]
julia> D = Dynamics((t, x, u, v) -> [t+2x[2]-u^2+v[3], x[1]], autonomous=false, variable=true)
julia> D(1, [1, 0], 1, [1, 2, 3])
[3, 1]
```

"""
struct Dynamics{TF<:Function,TD<:TimeDependence,VD<:VariableDependence}
    f::TF
end

struct Dynamics!{TF<:Function,TD<:TimeDependence,VD<:VariableDependence}
    f!::TF
end

"""
$(TYPEDEF)

**Fields**

$(TYPEDFIELDS)

Similar to `VectorField` in the usage, but the dimension of the output of the function `f` is arbitrary.

The default values for `time_dependence` and `variable_dependence` are `Autonomous` and `Fixed` respectively.

## Constructor

The constructor ```StateConstraint``` returns a ```StateConstraint``` of a function.
The function must take 1 to 3 arguments, `x` to `(t, x, v)`, if the function is variable or non autonomous, it must be specified. 
Dependencies are specified either with :
- booleans, `autonomous` and `variable`, respectively `true` and `false` by default 
- `DataType`, `Autonomous`/`NonAutonomous` and `NonFixed`/`Fixed`, respectively `Autonomous` and `Fixed` by default.

## *Examples*

```@example
julia> StateConstraint(x -> [x[1]^2, 2x[2]], Int64)
IncorrectArgument
julia> StateConstraint(x -> [x[1]^2, 2x[2]], Int64)
IncorrectArgument
julia> S = StateConstraint(x -> [x[1]^2, 2x[2]], Autonomous, Fixed)
julia> S = StateConstraint((x, v) -> [x[1]^2, 2x[2]+v[3]], Autonomous, NonFixed)
julia> S = StateConstraint((t, x) -> [t+x[1]^2, 2x[2]], NonAutonomous, Fixed)
julia> S = StateConstraint((t, x, v) -> [t+x[1]^2, 2x[2]+v[3]], NonAutonomous, NonFixed)
julia> S = StateConstraint(x -> [x[1]^2, 2x[2]], autonomous=true, variable=false)
julia> S = StateConstraint((x, v) -> [x[1]^2, 2x[2]+v[3]], autonomous=true, variable=true)
julia> S = StateConstraint((t, x) -> [t+x[1]^2, 2x[2]], autonomous=false, variable=false)
julia> S = StateConstraint((t, x, v) -> [t+x[1]^2, 2x[2]+v[3]], autonomous=false, variable=true)
```

!!! warning

    When the state is of dimension 1, consider `x` as a scalar.

## Call

The call returns the evaluation of the `StateConstraint` for given values.

## *Examples*

```@example
julia> StateConstraint(x -> [x[1]^2, 2x[2]], Int64)
IncorrectArgument
julia> StateConstraint(x -> [x[1]^2, 2x[2]], Int64)
IncorrectArgument
julia> S = StateConstraint(x -> [x[1]^2, 2x[2]], autonomous=true, variable=false)
julia> S([1, -1])
[1, -2]
julia> t = 1
julia> v = Real[]
julia> S(t, [1, -1], v)
[1, -2]
julia> S = StateConstraint((x, v) -> [x[1]^2, 2x[2]+v[3]], autonomous=true, variable=true)
julia> S([1, -1], [1, 2, 3])
[1, 1]
julia> S(t, [1, -1], [1, 2, 3])
[1, 1]
julia> S = StateConstraint((t, x) -> [t+x[1]^2, 2x[2]], autonomous=false, variable=false)
julia>  S(1, [1, -1])
[2, -2]
julia>  S(1, [1, -1], v)
[2, -2]
julia> S = StateConstraint((t, x, v) -> [t+x[1]^2, 2x[2]+v[3]], autonomous=false, variable=true)
julia>  S(1, [1, -1], [1, 2, 3])
[2, 1]
```

"""
struct StateConstraint{TF<:Function,TD<:TimeDependence,VD<:VariableDependence}
    f::TF
end

struct StateConstraint!{TF<:Function,TD<:TimeDependence,VD<:VariableDependence}
    f!::TF
end

"""
$(TYPEDEF)

**Fields**

$(TYPEDFIELDS)

Similar to `VectorField` in the usage, but the dimension of the output of the function `f` is arbitrary.

The default values for `time_dependence` and `variable_dependence` are `Autonomous` and `Fixed` respectively.

## Constructor

The constructor ```ControlConstraint``` returns a ```ControlConstraint``` of a function.
The function must take 1 to 3 arguments, `u` to `(t, u, v)`, if the function is variable or non autonomous, it must be specified. 
Dependencies are specified either with :
- booleans, `autonomous` and `variable`, respectively `true` and `false` by default 
- `DataType`, `Autonomous`/`NonAutonomous` and `NonFixed`/`Fixed`, respectively `Autonomous` and `Fixed` by default.

## *Examples*

```@example
julia> IncorrectArgument ControlConstraint(u -> [u[1]^2, 2u[2]], Int64)
julia> IncorrectArgument ControlConstraint(u -> [u[1]^2, 2u[2]], Int64)
julia> C = ControlConstraint(u -> [u[1]^2, 2u[2]], Autonomous, Fixed)
julia> C = ControlConstraint((u, v) -> [u[1]^2, 2u[2]+v[3]], Autonomous, NonFixed)
julia> C = ControlConstraint((t, u) -> [t+u[1]^2, 2u[2]], NonAutonomous, Fixed)
julia> C = ControlConstraint((t, u, v) -> [t+u[1]^2, 2u[2]+v[3]], NonAutonomous, NonFixed)
julia> C = ControlConstraint(u -> [u[1]^2, 2u[2]], autonomous=true, variable=false)
julia> C = ControlConstraint((u, v) -> [u[1]^2, 2u[2]+v[3]], autonomous=true, variable=true)
julia> C = ControlConstraint((t, u) -> [t+u[1]^2, 2u[2]], autonomous=false, variable=false)
julia> C = ControlConstraint((t, u, v) -> [t+u[1]^2, 2u[2]+v[3]], autonomous=false, variable=true)
```

!!! warning

    When the control is of dimension 1, consider `u` as a scalar.

## Call

The call returns the evaluation of the `ControlConstraint` for given values.

## *Examples*

```@example
julia> C = ControlConstraint(u -> [u[1]^2, 2u[2]], autonomous=true, variable=false)
julia> C([1, -1])
[1, -2]
julia> t = 1
julia> v = Real[]
julia> C(t, [1, -1], v)
[1, -2]
julia> C = ControlConstraint((u, v) -> [u[1]^2, 2u[2]+v[3]], autonomous=true, variable=true)
julia> C([1, -1], [1, 2, 3])
[1, 1]
julia> C(t, [1, -1], [1, 2, 3])
[1, 1]
julia> C = ControlConstraint((t, u) -> [t+u[1]^2, 2u[2]], autonomous=false, variable=false)
julia> C(1, [1, -1])
[2, -2]
julia> C(1, [1, -1], v)
[2, -2]
julia> C = ControlConstraint((t, u, v) -> [t+u[1]^2, 2u[2]+v[3]], autonomous=false, variable=true)
julia> C(1, [1, -1], [1, 2, 3])
[2, 1]
```

"""
struct ControlConstraint{TF<:Function,TD<:TimeDependence,VD<:VariableDependence}
    f::TF
end

struct ControlConstraint!{TF<:Function,TD<:TimeDependence,VD<:VariableDependence}
    f!::TF
end

"""
$(TYPEDEF)

**Fields**

$(TYPEDFIELDS)

Similar to `Lagrange` in the usage, but the dimension of the output of the function `f` is arbitrary.

The default value for `time_dependence` and `variable_dependence` are `Autonomous` and `Fixed` respectively.

## Constructor

The constructor ```MixedConstraint``` returns a ```MixedConstraint``` of a function.
The function must take 2 to 4 arguments, `(x, u)` to `(t, x, u, v)`, if the function is variable or non autonomous, it must be specified. 
Dependencies are specified either with :
- booleans, `autonomous` and `variable`, respectively `true` and `false` by default 
- `DataType`, `Autonomous`/`NonAutonomous` and `NonFixed`/`Fixed`, respectively `Autonomous` and `Fixed` by default.

## *Examples*

```@example
julia> MixedConstraint((x, u) -> [2x[2]-u^2, x[1]], Int64)
IncorrectArgument
julia> MixedConstraint((x, u) -> [2x[2]-u^2, x[1]], Int64)
IncorrectArgument
julia> M = MixedConstraint((x, u) -> [2x[2]-u^2, x[1]], Autonomous, Fixed)
julia> M = MixedConstraint((x, u, v) -> [2x[2]-u^2+v[3], x[1]], Autonomous, NonFixed)
julia> M = MixedConstraint((t, x, u) -> [t+2x[2]-u^2, x[1]], NonAutonomous, Fixed)
julia> M = MixedConstraint((t, x, u, v) -> [t+2x[2]-u^2+v[3], x[1]], NonAutonomous, NonFixed)
julia> M = MixedConstraint((x, u) -> [2x[2]-u^2, x[1]], autonomous=true, variable=false)
julia> M = MixedConstraint((x, u, v) -> [2x[2]-u^2+v[3], x[1]], autonomous=true, variable=true)
julia> M = MixedConstraint((t, x, u) -> [t+2x[2]-u^2, x[1]], autonomous=false, variable=false)
julia> M = MixedConstraint((t, x, u, v) -> [t+2x[2]-u^2+v[3], x[1]], autonomous=false, variable=true)
```

!!! warning

    When the state is of dimension 1, consider `x` as a scalar. Same for the control.

## Call

The call returns the evaluation of the `MixedConstraint` for given values.

## *Examples*

```@example
julia> MixedConstraint((x, u) -> [2x[2]-u^2, x[1]], Int64)
IncorrectArgument
julia> MixedConstraint((x, u) -> [2x[2]-u^2, x[1]], Int64)
IncorrectArgument
julia> M = MixedConstraint((x, u) -> [2x[2]-u^2, x[1]], autonomous=true, variable=false)
julia> M([1, 0], 1)
[-1, 1]
julia> t = 1
julia> v = Real[]
julia> MethodError M(t, [1, 0], 1)
julia> MethodError M([1, 0], 1, v)
julia> M(t, [1, 0], 1, v)
[-1, 1]
julia> M = MixedConstraint((x, u, v) -> [2x[2]-u^2+v[3], x[1]], autonomous=true, variable=true)
julia> M([1, 0], 1, [1, 2, 3])
[2, 1]
julia> M(t, [1, 0], 1, [1, 2, 3])
[2, 1]
julia> M = MixedConstraint((t, x, u) -> [t+2x[2]-u^2, x[1]], autonomous=false, variable=false)
julia> M(1, [1, 0], 1)
[0, 1]
julia> M(1, [1, 0], 1, v)
[0, 1]
julia> M = MixedConstraint((t, x, u, v) -> [t+2x[2]-u^2+v[3], x[1]], autonomous=false, variable=true)
julia> M(1, [1, 0], 1, [1, 2, 3])
[3, 1]
```

"""
struct MixedConstraint{TF<:Function,TD<:TimeDependence,VD<:VariableDependence}
    f::TF
end

struct MixedConstraint!{TF<:Function,TD<:TimeDependence,VD<:VariableDependence}
    f!::TF
end

"""
$(TYPEDEF)

**Fields**

$(TYPEDFIELDS)

The default values for `time_dependence` and `variable_dependence` are `Autonomous` and `Fixed` respectively.

## Constructor

The constructor ```VariableConstraint``` returns a ```VariableConstraint``` of a function.
The function must take 1 argument, `v`.

## *Examples*

```@example
julia> V = VariableConstraint(v -> [v[1]^2, 2v[2]])
```

!!! warning

    When the variable is of dimension 1, consider `v` as a scalar.

## Call

The call returns the evaluation of the `VariableConstraint` for given values.

## *Examples*

```@example
julia> V = VariableConstraint(v -> [v[1]^2, 2v[2]])
julia> V([1, -1])
[1, -2]
```

"""
struct VariableConstraint{TF<:Function}
    f::TF
end

struct VariableConstraint!{TF<:Function}
    f!::TF
end

"""
$(TYPEDEF)

**Fields**

$(TYPEDFIELDS)

Similar to `VectorField` in the usage, but the dimension of the output of the function `f` is arbitrary.

The default values for `time_dependence` and `variable_dependence` are `Autonomous` and `Fixed` respectively.

## Constructor

The constructor ```FeedbackControl``` returns a ```FeedbackControl``` of a function.
The function must take 1 to 3 arguments, `x` to `(t, x, v)`, if the function is variable or non autonomous, it must be specified. 
Dependencies are specified either with :
- booleans, `autonomous` and `variable`, respectively `true` and `false` by default 
- `DataType`, `Autonomous`/`NonAutonomous` and `NonFixed`/`Fixed`, respectively `Autonomous` and `Fixed` by default.

## *Examples*

```@example
julia> FeedbackControl(x -> x[1]^2+2x[2], Int64)
IncorrectArgument
julia> FeedbackControl(x -> x[1]^2+2x[2], Int64)
IncorrectArgument
julia> u = FeedbackControl(x -> x[1]^2+2x[2], Autonomous, Fixed)
julia> u = FeedbackControl((x, v) -> x[1]^2+2x[2]+v[3], Autonomous, NonFixed)
julia> u = FeedbackControl((t, x) -> t+x[1]^2+2x[2], NonAutonomous, Fixed)
julia> u = FeedbackControl((t, x, v) -> t+x[1]^2+2x[2]+v[3], NonAutonomous, NonFixed)
julia> u = FeedbackControl(x -> x[1]^2+2x[2], autonomous=true, variable=false)
julia> u = FeedbackControl((x, v) -> x[1]^2+2x[2]+v[3], autonomous=true, variable=true)
julia> u = FeedbackControl((t, x) -> t+x[1]^2+2x[2], autonomous=false, variable=false)
julia> u = FeedbackControl((t, x, v) -> t+x[1]^2+2x[2]+v[3], autonomous=false, variable=true)
```

!!! warning

    When the state is of dimension 1, consider `x` as a scalar.

## Call

The call returns the evaluation of the `FeedbackControl` for given values.

## *Examples*

```@example
julia> u = FeedbackControl(x -> x[1]^2+2x[2], autonomous=true, variable=false)
julia> u([1, 0])
1
julia> t = 1
julia> v = Real[]
julia> u(t, [1, 0])
MethodError
julia> u([1, 0], v)
MethodError
julia> u(t, [1, 0], v)
1
julia> u = FeedbackControl((x, v) -> x[1]^2+2x[2]+v[3], autonomous=true, variable=true)
julia> u([1, 0], [1, 2, 3])
4
julia> u(t, [1, 0], [1, 2, 3])
4
julia> u = FeedbackControl((t, x) -> t+x[1]^2+2x[2], autonomous=false, variable=false)
julia> u(1, [1, 0])
2
julia> u(1, [1, 0], v)
2
julia> u = FeedbackControl((t, x, v) -> t+x[1]^2+2x[2]+v[3], autonomous=false, variable=true)
julia> u(1, [1, 0], [1, 2, 3])
5
```

"""
struct FeedbackControl{TF<:Function,TD<:TimeDependence,VD<:VariableDependence}
    f::TF
end

"""
$(TYPEDEF)

**Fields**

$(TYPEDFIELDS)

Similar to `Hamiltonian` in the usage, but the dimension of the output of the function `f` is arbitrary.

The default values for `time_dependence` and `variable_dependence` are `Autonomous` and `Fixed` respectively.

## Constructor

The constructor ```ControlLaw``` returns a ```ControlLaw``` of a function.
The function must take 2 to 4 arguments, `(x, p)` to `(t, x, p, v)`, if the function is variable or non autonomous, it must be specified. 
Dependencies are specified either with :
- booleans, `autonomous` and `variable`, respectively `true` and `false` by default 
- `DataType`, `Autonomous`/`NonAutonomous` and `NonFixed`/`Fixed`, respectively `Autonomous` and `Fixed` by default.

## *Examples*

```@example
julia> ControlLaw((x, p) -> x[1]^2+2p[2], Int64)
IncorrectArgument
julia> ControlLaw((x, p) -> x[1]^2+2p[2], Int64)
IncorrectArgument
julia> u = ControlLaw((x, p) -> x[1]^2+2p[2], Autonomous, Fixed)
julia> u = ControlLaw((x, p, v) -> x[1]^2+2p[2]+v[3], Autonomous, NonFixed)
julia> u = ControlLaw((t, x, p) -> t+x[1]^2+2p[2], NonAutonomous, Fixed)
julia> u = ControlLaw((t, x, p, v) -> t+x[1]^2+2p[2]+v[3], NonAutonomous, NonFixed)
julia> u = ControlLaw((x, p) -> x[1]^2+2p[2], autonomous=true, variable=false)
julia> u = ControlLaw((x, p, v) -> x[1]^2+2p[2]+v[3], autonomous=true, variable=true)
julia> u = ControlLaw((t, x, p) -> t+x[1]^2+2p[2], autonomous=false, variable=false)
julia> u = ControlLaw((t, x, p, v) -> t+x[1]^2+2p[2]+v[3], autonomous=false, variable=true)
```

!!! warning

    When the state and costate are of dimension 1, consider `x` and `p` as scalars.

## Call

The call returns the evaluation of the `ControlLaw` for given values.

## *Examples*

```@example
julia> u = ControlLaw((x, p) -> x[1]^2+2p[2], autonomous=true, variable=false)
julia> u([1, 0], [0, 1])
3
julia> t = 1
julia> v = Real[]
julia> u(t, [1, 0], [0, 1])
MethodError
julia> u([1, 0], [0, 1], v)
MethodError
julia> u(t, [1, 0], [0, 1], v)
3
julia> u = ControlLaw((x, p, v) -> x[1]^2+2p[2]+v[3], autonomous=true, variable=true)
julia> u([1, 0], [0, 1], [1, 2, 3])
6
julia> u(t, [1, 0], [0, 1], [1, 2, 3])
6
julia> u = ControlLaw((t, x, p) -> t+x[1]^2+2p[2], autonomous=false, variable=false)
julia> u(1, [1, 0], [0, 1])
4
julia> u(1, [1, 0], [0, 1], v)
4
julia> u = ControlLaw((t, x, p, v) -> t+x[1]^2+2p[2]+v[3], autonomous=false, variable=true)
julia> u(1, [1, 0], [0, 1], [1, 2, 3])
7
```

"""
struct ControlLaw{TF<:Function,TD<:TimeDependence,VD<:VariableDependence}
    f::TF
end

"""
$(TYPEDEF)

**Fields**

$(TYPEDFIELDS)

Similar to `ControlLaw` in the usage.

The default values for `time_dependence` and `variable_dependence` are `Autonomous` and `Fixed` respectively.

## Constructor

The constructor ```Multiplier``` returns a ```Multiplier``` of a function.
The function must take 2 to 4 arguments, `(x, p)` to `(t, x, p, v)`, if the function is variable or non autonomous, it must be specified. 
Dependencies are specified either with :
- booleans, `autonomous` and `variable`, respectively `true` and `false` by default 
- `DataType`, `Autonomous`/`NonAutonomous` and `NonFixed`/`Fixed`, respectively `Autonomous` and `Fixed` by default.

## *Examples*

```@example
julia> Multiplier((x, p) -> x[1]^2+2p[2], Int64)
IncorrectArgument
julia> Multiplier((x, p) -> x[1]^2+2p[2], Int64)
IncorrectArgument
julia> μ = Multiplier((x, p) -> x[1]^2+2p[2], Autonomous, Fixed)
julia> μ = Multiplier((x, p, v) -> x[1]^2+2p[2]+v[3], Autonomous, NonFixed)
julia> μ = Multiplier((t, x, p) -> t+x[1]^2+2p[2], NonAutonomous, Fixed)
julia> μ = Multiplier((t, x, p, v) -> t+x[1]^2+2p[2]+v[3], NonAutonomous, NonFixed)
julia> μ = Multiplier((x, p) -> x[1]^2+2p[2], autonomous=true, variable=false)
julia> μ = Multiplier((x, p, v) -> x[1]^2+2p[2]+v[3], autonomous=true, variable=true)
julia> μ = Multiplier((t, x, p) -> t+x[1]^2+2p[2], autonomous=false, variable=false)
julia> μ = Multiplier((t, x, p, v) -> t+x[1]^2+2p[2]+v[3], autonomous=false, variable=true)
```

!!! warning

    When the state and costate are of dimension 1, consider `x` and `p` as scalars.

## Call

The call returns the evaluation of the `Multiplier` for given values.

## *Examples*

```@example
julia> μ = Multiplier((x, p) -> x[1]^2+2p[2], autonomous=true, variable=false)
julia> μ([1, 0], [0, 1])
3
julia> t = 1
julia> v = Real[]
julia> μ(t, [1, 0], [0, 1])
MethodError
julia> μ([1, 0], [0, 1], v)
MethodError
julia> μ(t, [1, 0], [0, 1], v)
3
julia> μ = Multiplier((x, p, v) -> x[1]^2+2p[2]+v[3], autonomous=true, variable=true)
julia> μ([1, 0], [0, 1], [1, 2, 3])
6
julia> μ(t, [1, 0], [0, 1], [1, 2, 3])
6
julia> μ = Multiplier((t, x, p) -> t+x[1]^2+2p[2], autonomous=false, variable=false)
julia> μ(1, [1, 0], [0, 1])
4
julia> μ(1, [1, 0], [0, 1], v)
4
julia> μ = Multiplier((t, x, p, v) -> t+x[1]^2+2p[2]+v[3], autonomous=false, variable=true)
julia> μ(1, [1, 0], [0, 1], [1, 2, 3])
7
```

"""
struct Multiplier{TF<:Function,TD<:TimeDependence,VD<:VariableDependence}
    f::TF
end

# --------------------------------------------------------------------------------------------------
# model
#
"""
$(TYPEDEF)

**Fields**

$(TYPEDFIELDS)
"""
mutable struct Index
    val::Int
    Index(v::Int) = v ≥ 1 ? new(v) : error("index must be at least 1")
end
Base.:(==)(i::Index, j::Index) = i.val == j.val # needed, as this is not the default behaviour for composite types
Base.to_index(i::Index) = i.val
Base.isless(i::Index, j::Index) = i.val ≤ j.val
Base.isless(i::Index, j::Real) = i.val ≤ j
Base.isless(i::Real, j::Index) = i ≤ j.val
Base.length(i::Index) = 1
Base.iterate(i::Index, state=0) = state == 0 ? (i, 1) : nothing
Base.IteratorSize(::Type{Index}) = Base.HasLength()
Base.append!(v::Vector, i::Index) = Base.append!(v, i.val)
Base.getindex(x::AbstractArray, i::Index) = Base.getindex(x, i.val)
Base.getindex(x::Real, i::Index) = x[i.val]

# to suppress ambiguities
Base.getindex(x::SparseArrays.ReadOnly, i::CTBase.Index) = Base.getindex(x, i.val)
Base.getindex(x::StaticArrays.TrivialView, i::CTBase.Index) = Base.getindex(x, i.val)

"""
Type alias for an index or range.
"""
const RangeConstraint = Union{Index,OrdinalRange{<:Int}}
