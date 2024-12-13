# --------------------------------------------------------------------------------------------------
"""

$(TYPEDSIGNATURES)

Return a ```BoundaryConstraint``` of a function.
Dependencies are specified with a boolean, variable, false by default.

```@example
julia> B = BoundaryConstraint((x0, xf) -> [xf[2]-x0[1], 2xf[1]+x0[2]^2])
julia> B = BoundaryConstraint((x0, xf, v) -> [v[3]+xf[2]-x0[1], v[1]-v[2]+2xf[1]+x0[2]^2], variable=true)
```

"""
function BoundaryConstraint(f::Function; variable::Bool=false)
    VD = variable ? NonFixed : Fixed
    return BoundaryConstraint{typeof(f),VD}(f)
end

function BoundaryConstraint!(f!::Function; variable::Bool=false)
    VD = variable ? NonFixed : Fixed
    return BoundaryConstraint!{typeof(f!),VD}(f!)
end

"""

$(TYPEDSIGNATURES)

Return a ```BoundaryConstraint``` of a function.
Dependencies are specified with a DataType, NonFixed/Fixed, Fixed by default.

```@example
julia> B = BoundaryConstraint((x0, xf) -> [xf[2]-x0[1], 2xf[1]+x0[2]^2])
julia> B = BoundaryConstraint((x0, xf, v) -> [v[3]+xf[2]-x0[1], v[1]-v[2]+2xf[1]+x0[2]^2], NonFixed)
```

"""
BoundaryConstraint(f::Function, VD::Type{<:VariableDependence}) =
    BoundaryConstraint{typeof(f),VD}(f)
function BoundaryConstraint!(f!::Function, VD::Type{<:VariableDependence})
    return BoundaryConstraint!{typeof(f!),VD}(f!)
end

"""

$(TYPEDSIGNATURES)

Return the evaluation of the BoundaryConstraint.

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
function (F::BoundaryConstraint{<:Function,Fixed})(x0::State, xf::State)::ctVector
    return F.f(x0, xf)
end

function (F::BoundaryConstraint{<:Function,Fixed})(
    x0::State, xf::State, v::Variable
)::ctVector
    return F.f(x0, xf)
end

function (F::BoundaryConstraint{<:Function,NonFixed})(
    x0::State, xf::State, v::Variable
)::ctVector
    return F.f(x0, xf, v)
end

function (F::BoundaryConstraint!{<:Function,Fixed})(
    r::ctVector, x0::State, xf::State
)::Nothing
    return F.f!(r, x0, xf)
end

function (F::BoundaryConstraint!{<:Function,Fixed})(
    r::ctVector, x0::State, xf::State, v::Variable
)::Nothing
    return F.f!(r, x0, xf)
end

function (F::BoundaryConstraint!{<:Function,NonFixed})(
    r::ctVector, x0::State, xf::State, v::Variable
)::Nothing
    return F.f!(r, x0, xf, v)
end

# --------------------------------------------------------------------------------------------------
"""

$(TYPEDSIGNATURES)

Return a ```Mayer``` cost of a function.
Dependencies are specified with a boolean, variable, false by default.

```@example
julia> G = Mayer((x0, xf) -> xf[2]-x0[1])
julia> G = Mayer((x0, xf, v) -> v[3]+xf[2]-x0[1], variable=true)
```

"""
function Mayer(f::Function; variable::Bool=false)
    VD = variable ? NonFixed : Fixed
    return Mayer{typeof(f),VD}(f)
end

function Mayer!(f!::Function; variable::Bool=false)
    VD = variable ? NonFixed : Fixed
    return Mayer!{typeof(f!),VD}(f!)
end

"""

$(TYPEDSIGNATURES)

Return a ```Mayer``` cost of a function.
Dependencies are specified with a DataType, NonFixed/Fixed, Fixed by default.

```@example
julia> G = Mayer((x0, xf) -> xf[2]-x0[1])
julia> G = Mayer((x0, xf, v) -> v[3]+xf[2]-x0[1], NonFixed)
```

"""
Mayer(f::Function, VD::Type{<:VariableDependence}) = Mayer{typeof(f),VD}(f)
Mayer!(f!::Function, VD::Type{<:VariableDependence}) = Mayer!{typeof(f!),VD}(f!)

"""

$(TYPEDSIGNATURES)

Return the evaluation of the Mayer cost.

```@example
julia> G = Mayer((x0, xf) -> xf[2]-x0[1])
julia> G([0, 0], [1, 1])
1
julia> G = Mayer((x0, xf) -> xf[2]-x0[1])
julia> G([0, 0], [1, 1], Real[])
1
julia> G = Mayer((x0, xf, v) -> v[3]+xf[2]-x0[1], variable=true)
julia> G([0, 0], [1, 1], [1, 2, 3])
4
```
"""
function (F::Mayer{<:Function,Fixed})(x0::State, xf::State)::ctNumber
    return F.f(x0, xf)
end

function (F::Mayer{<:Function,Fixed})(x0::State, xf::State, v::Variable)::ctNumber
    return F.f(x0, xf)
end

function (F::Mayer{<:Function,NonFixed})(x0::State, xf::State, v::Variable)::ctNumber
    return F.f(x0, xf, v)
end

function (F::Mayer!{<:Function,Fixed})(r::ctVector, x0::State, xf::State)::Nothing
    return F.f!(r, x0, xf)
end

function (F::Mayer!{<:Function,Fixed})(
    r::ctVector, x0::State, xf::State, v::Variable
)::Nothing
    return F.f!(r, x0, xf)
end

function (F::Mayer!{<:Function,NonFixed})(
    r::ctVector, x0::State, xf::State, v::Variable
)::Nothing
    return F.f!(r, x0, xf, v)
end

# --------------------------------------------------------------------------------------------------
# Hamiltonian
"""

$(TYPEDSIGNATURES)

Return an ```Hamiltonian``` of a function.
Dependencies are specified with a boolean, variable, false by default, autonomous, true by default.

```@example
julia> H = Hamiltonian((x, p) -> x[1]^2+2p[2])
julia> H = Hamiltonian((t, x, p, v) -> [t+x[1]^2+2p[2]+v[3]], autonomous=false, variable=true)
```
"""
function Hamiltonian(f::Function; autonomous::Bool=true, variable::Bool=false)
    TD = autonomous ? Autonomous : NonAutonomous
    VD = variable ? NonFixed : Fixed
    return Hamiltonian{typeof(f),TD,VD}(f)
end

"""

$(TYPEDSIGNATURES)

Return an ```Hamiltonian``` of a function.
Dependencies are specified with DataType, Autonomous, NonAutonomous and Fixed, NonFixed.

```@example
julia> H = Hamiltonian((x, p) -> x[1]^2+2p[2])
julia> H = Hamiltonian((t, x, p, v) -> [t+x[1]^2+2p[2]+v[3]], NonAutonomous, NonFixed)
```

"""
Hamiltonian(f::Function, TD::Type{<:TimeDependence}, VD::Type{<:VariableDependence}) =
    Hamiltonian{typeof(f),TD,VD}(f)

"""

$(TYPEDSIGNATURES)

Return the value of the Hamiltonian.

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
function (F::Hamiltonian{<:Function,Autonomous,Fixed})(x::State, p::Costate)::ctNumber
    return F.f(x, p)
end

function (F::Hamiltonian{<:Function,Autonomous,Fixed})(
    t::Time, x::State, p::Costate, v::Variable
)::ctNumber
    return F.f(x, p)
end

function (F::Hamiltonian{<:Function,Autonomous,NonFixed})(
    x::State, p::Costate, v::Variable
)::ctNumber
    return F.f(x, p, v)
end

function (F::Hamiltonian{<:Function,Autonomous,NonFixed})(
    t::Time, x::State, p::Costate, v::Variable
)::ctNumber
    return F.f(x, p, v)
end

function (F::Hamiltonian{<:Function,NonAutonomous,Fixed})(
    t::Time, x::State, p::Costate
)::ctNumber
    return F.f(t, x, p)
end

function (F::Hamiltonian{<:Function,NonAutonomous,Fixed})(
    t::Time, x::State, p::Costate, v::Variable
)::ctNumber
    return F.f(t, x, p)
end

function (F::Hamiltonian{<:Function,NonAutonomous,NonFixed})(
    t::Time, x::State, p::Costate, v::Variable
)::ctNumber
    return F.f(t, x, p, v)
end

# ---------------------------------------------------------------------------
# HamiltonianLift
"""

$(TYPEDSIGNATURES)

Return an ```HamiltonianLift``` of a function.
Dependencies are specified with a boolean, variable, false by default, autonomous, true by default.

```@example
julia> HL = HamiltonianLift(x -> [x[1]^2,x[2]^2], autonomous=true, variable=false)
julia> HL = HamiltonianLift((x, v) -> [x[1]^2,x[2]^2+v], autonomous=true, variable=true)
julia> HL = HamiltonianLift((t, x) -> [t+x[1]^2,x[2]^2], autonomous=false, variable=false)
julia> HL = HamiltonianLift((t, x, v) -> [t+x[1]^2,x[2]^2+v], autonomous=false, variable=true)
```
"""
function HamiltonianLift(f::Function; autonomous::Bool=true, variable::Bool=false)
    TD = autonomous ? Autonomous : NonAutonomous
    VD = variable ? NonFixed : Fixed
    return HamiltonianLift(VectorField(f, TD, VD))
end

"""

$(TYPEDSIGNATURES)

Return an ```HamiltonianLift``` of a function.
Dependencies are specified with DataType, Autonomous, NonAutonomous and Fixed, NonFixed.

```@example
julia> HL = HamiltonianLift(x -> [x[1]^2,x[2]^2], Autonomous, Fixed)
julia> HL = HamiltonianLift((x, v) -> [x[1]^2,x[2]^2+v], Autonomous, NonFixed)
julia> HL = HamiltonianLift((t, x) -> [t+x[1]^2,x[2]^2], NonAutonomous, Fixed)
julia> HL = HamiltonianLift((t, x, v) -> [t+x[1]^2,x[2]^2+v], NonAutonomous, NonFixed)
```
"""
HamiltonianLift(f::Function, TD::Type{<:TimeDependence}, VD::Type{<:VariableDependence}) =
    HamiltonianLift(VectorField(f, TD, VD))

"""

$(TYPEDSIGNATURES)

Return the value of the HamiltonianLift.

## Examples

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
"""
function (H::HamiltonianLift{<:VectorField,Autonomous,Fixed})(
    x::State, p::Costate
)::ctNumber
    return p' * H.X(x)
end

function (H::HamiltonianLift{<:VectorField,Autonomous,Fixed})(
    t::Time, x::State, p::Costate, v::Variable
)::ctNumber
    return p' * H.X(x)
end

function (H::HamiltonianLift{<:VectorField,Autonomous,NonFixed})(
    x::State, p::Costate, v::Variable
)::ctNumber
    return p' * H.X(x, v)
end

function (H::HamiltonianLift{<:VectorField,Autonomous,NonFixed})(
    t::Time, x::State, p::Costate, v::Variable
)::ctNumber
    return p' * H.X(x, v)
end

function (H::HamiltonianLift{<:VectorField,NonAutonomous,Fixed})(
    t::Time, x::State, p::Costate
)::ctNumber
    return p' * H.X(t, x)
end

function (H::HamiltonianLift{<:VectorField,NonAutonomous,Fixed})(
    t::Time, x::State, p::Costate, v::Variable
)::ctNumber
    return p' * H.X(t, x)
end

function (H::HamiltonianLift{<:VectorField,NonAutonomous,NonFixed})(
    t::Time, x::State, p::Costate, v::Variable
)::ctNumber
    return p' * H.X(t, x, v)
end

# --------------------------------------------------------------------------------------------------
"""

$(TYPEDSIGNATURES)

Return an ```HamiltonianVectorField``` of a function.
Dependencies are specified with a boolean, variable, false by default, autonomous, true by default.

```@example
julia> Hv = HamiltonianVectorField((x, p) -> [x[1]^2+2p[2], x[2]-3p[2]^2]) # autonomous=true, variable=false
julia> Hv = HamiltonianVectorField((x, p, v) -> [x[1]^2+2p[2]+v[3], x[2]-3p[2]^2+v[4]], variable=true)
julia> Hv = HamiltonianVectorField((t, x, p) -> [t+x[1]^2+2p[2], x[2]-3p[2]^2], autonomous=false)
julia> Hv = HamiltonianVectorField((t, x, p, v) -> [t+x[1]^2+2p[2]+v[3], x[2]-3p[2]^2+v[4]], autonomous=false, variable=true)
```

"""
function HamiltonianVectorField(f::Function; autonomous::Bool=true, variable::Bool=false)
    TD = autonomous ? Autonomous : NonAutonomous
    VD = variable ? NonFixed : Fixed
    return HamiltonianVectorField{typeof(f),TD,VD}(f)
end

"""

$(TYPEDSIGNATURES)

Return an ```HamiltonianVectorField``` of a function.
Dependencies are specified with DataType, Autonomous, NonAutonomous and Fixed, NonFixed.

```@example
julia> Hv = HamiltonianVectorField((x, p) -> [x[1]^2+2p[2], x[2]-3p[2]^2]) # autonomous=true, variable=false
julia> Hv = HamiltonianVectorField((x, p, v) -> [x[1]^2+2p[2]+v[3], x[2]-3p[2]^2+v[4]], NonFixed)
julia> Hv = HamiltonianVectorField((t, x, p) -> [t+x[1]^2+2p[2], x[2]-3p[2]^2], NonAutonomous)
julia> Hv = HamiltonianVectorField((t, x, p, v) -> [t+x[1]^2+2p[2]+v[3], x[2]-3p[2]^2+v[4]], NonAutonomous, NonFixed)
```

"""
HamiltonianVectorField(
    f::Function, TD::Type{<:TimeDependence}, VD::Type{<:VariableDependence}
) = HamiltonianVectorField{typeof(f),TD,VD}(f)

"""

$(TYPEDSIGNATURES)

Return the value of the HamiltonianVectorField.

## Examples

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
function (F::HamiltonianVectorField{<:Function,Autonomous,Fixed})(
    x::State, p::Costate
)::Tuple{DState,DCostate}
    return F.f(x, p)
end

function (F::HamiltonianVectorField{<:Function,Autonomous,Fixed})(
    t::Time, x::State, p::Costate, v::Variable
)::Tuple{DState,DCostate}
    return F.f(x, p)
end

function (F::HamiltonianVectorField{<:Function,Autonomous,NonFixed})(
    x::State, p::Costate, v::Variable
)::Tuple{DState,DCostate}
    return F.f(x, p, v)
end

function (F::HamiltonianVectorField{<:Function,Autonomous,NonFixed})(
    t::Time, x::State, p::Costate, v::Variable
)::Tuple{DState,DCostate}
    return F.f(x, p, v)
end

function (F::HamiltonianVectorField{<:Function,NonAutonomous,Fixed})(
    t::Time, x::State, p::Costate
)::Tuple{DState,DCostate}
    return F.f(t, x, p)
end

function (F::HamiltonianVectorField{<:Function,NonAutonomous,Fixed})(
    t::Time, x::State, p::Costate, v::Variable
)::Tuple{DState,DCostate}
    return F.f(t, x, p)
end

function (F::HamiltonianVectorField{<:Function,NonAutonomous,NonFixed})(
    t::Time, x::State, p::Costate, v::Variable
)::Tuple{DState,DCostate}
    return F.f(t, x, p, v)
end

# --------------------------------------------------------------------------------------------------
"""

$(TYPEDSIGNATURES)

Return a ```VectorField``` of a function.
Dependencies are specified with a boolean, variable, false by default, autonomous, true by default.

```@example
julia> V = VectorField(x -> [x[1]^2, 2x[2]]) # autonomous=true, variable=false
julia> V = VectorField((x, v) -> [x[1]^2, 2x[2]+v[3]], variable=true)
julia> V = VectorField((t, x) -> [t+x[1]^2, 2x[2]], autonomous=false)
julia> V = VectorField((t, x, v) -> [t+x[1]^2, 2x[2]+v[3]], autonomous=false, variable=true)
```

"""
function VectorField(f::Function; autonomous::Bool=true, variable::Bool=false)
    TD = autonomous ? Autonomous : NonAutonomous
    VD = variable ? NonFixed : Fixed
    return VectorField{typeof(f),TD,VD}(f)
end

"""

$(TYPEDSIGNATURES)

Return a ```VectorField``` of a function.
Dependencies are specified with DataType, Autonomous, NonAutonomous and Fixed, NonFixed.

```@example
julia> V = VectorField(x -> [x[1]^2, 2x[2]]) # autonomous=true, variable=false
julia> V = VectorField((x, v) -> [x[1]^2, 2x[2]+v[3]], NonFixed)
julia> V = VectorField((t, x) -> [t+x[1]^2, 2x[2]], NonAutonomous)
julia> V = VectorField((t, x, v) -> [t+x[1]^2, 2x[2]+v[3]], NonAutonomous, NonFixed)
```

"""
VectorField(f::Function, TD::Type{<:TimeDependence}, VD::Type{<:VariableDependence}) =
    VectorField{typeof(f),TD,VD}(f)

"""

$(TYPEDSIGNATURES)

Return the value of the VectorField.

## Examples

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
function (F::VectorField{<:Function,Autonomous,Fixed})(x::State)::ctVector
    return F.f(x)
end

function (F::VectorField{<:Function,Autonomous,Fixed})(
    t::Time, x::State, v::Variable
)::ctVector
    return F.f(x)
end

function (F::VectorField{<:Function,Autonomous,NonFixed})(x::State, v::Variable)::ctVector
    return F.f(x, v)
end

function (F::VectorField{<:Function,Autonomous,NonFixed})(
    t::Time, x::State, v::Variable
)::ctVector
    return F.f(x, v)
end

function (F::VectorField{<:Function,NonAutonomous,Fixed})(t::Time, x::State)::ctVector
    return F.f(t, x)
end

function (F::VectorField{<:Function,NonAutonomous,Fixed})(
    t::Time, x::State, v::Variable
)::ctVector
    return F.f(t, x)
end

function (F::VectorField{<:Function,NonAutonomous,NonFixed})(
    t::Time, x::State, v::Variable
)::ctVector
    return F.f(t, x, v)
end

# --------------------------------------------------------------------------------------------------
"""

$(TYPEDSIGNATURES)

Return a ```Lagrange``` cost of a function.
Dependencies are specified with a boolean, variable, false by default, autonomous, true by default.

```@example
julia> L = Lagrange((x, u) -> [2x[2]-u[1]^2], autonomous=true, variable=false)
julia> L = Lagrange((x, u) -> 2x[2]-u[1]^2, autonomous=true, variable=false)
julia> L = Lagrange((x, u, v) -> 2x[2]-u[1]^2+v[3], autonomous=true, variable=true)
julia> L = Lagrange((t, x, u) -> t+2x[2]-u[1]^2, autonomous=false, variable=false)
julia> L = Lagrange((t, x, u, v) -> t+2x[2]-u[1]^2+v[3], autonomous=false, variable=true)

```

"""
function Lagrange(f::Function; autonomous::Bool=true, variable::Bool=false)
    TD = autonomous ? Autonomous : NonAutonomous
    VD = variable ? NonFixed : Fixed
    return Lagrange{typeof(f),TD,VD}(f)
end

function Lagrange!(f!::Function; autonomous::Bool=true, variable::Bool=false)
    TD = autonomous ? Autonomous : NonAutonomous
    VD = variable ? NonFixed : Fixed
    return Lagrange!{typeof(f!),TD,VD}(f!)
end

"""

$(TYPEDSIGNATURES)

Return a ```Lagrange``` cost of a function.
Dependencies are specified with DataType, Autonomous, NonAutonomous and Fixed, NonFixed.

```@example
julia> L = Lagrange((x, u) -> [2x[2]-u[1]^2], autonomous=true, variable=false)
julia> L = Lagrange((x, u) -> 2x[2]-u[1]^2, autonomous=true, variable=false)
julia> L = Lagrange((x, u, v) -> 2x[2]-u[1]^2+v[3], autonomous=true, variable=true)
julia> L = Lagrange((t, x, u) -> t+2x[2]-u[1]^2, autonomous=false, variable=false)
julia> L = Lagrange((t, x, u, v) -> t+2x[2]-u[1]^2+v[3], autonomous=false, variable=true)

```

"""
Lagrange(f::Function, TD::Type{<:TimeDependence}, VD::Type{<:VariableDependence}) =
    Lagrange{typeof(f),TD,VD}(f)
function Lagrange!(f!::Function, TD::Type{<:TimeDependence}, VD::Type{<:VariableDependence})
    return Lagrange!{typeof(f!),TD,VD}(f!)
end

"""

$(TYPEDSIGNATURES)

Return the value of the Lagrange function.

## Examples

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
function (F::Lagrange{<:Function,Autonomous,Fixed})(x::State, u::Control)::ctNumber
    return F.f(x, u)
end

function (F::Lagrange{<:Function,Autonomous,Fixed})(
    t::Time, x::State, u::Control, v::Variable
)::ctNumber
    return F.f(x, u)
end

function (F::Lagrange{<:Function,Autonomous,NonFixed})(
    x::State, u::Control, v::Variable
)::ctNumber
    return F.f(x, u, v)
end

function (F::Lagrange{<:Function,Autonomous,NonFixed})(
    t::Time, x::State, u::Control, v::Variable
)::ctNumber
    return F.f(x, u, v)
end

function (F::Lagrange{<:Function,NonAutonomous,Fixed})(
    t::Time, x::State, u::Control
)::ctNumber
    return F.f(t, x, u)
end

function (F::Lagrange{<:Function,NonAutonomous,Fixed})(
    t::Time, x::State, u::Control, v::Variable
)::ctNumber
    return F.f(t, x, u)
end

function (F::Lagrange{<:Function,NonAutonomous,NonFixed})(
    t::Time, x::State, u::Control, v::Variable
)::ctNumber
    return F.f(t, x, u, v)
end

function (F::Lagrange!{<:Function,Autonomous,Fixed})(
    r::ctVector, x::State, u::Control
)::Nothing
    return F.f!(r, x, u)
end

function (F::Lagrange!{<:Function,Autonomous,Fixed})(
    r::ctVector, t::Time, x::State, u::Control, v::Variable
)::Nothing
    return F.f!(r, x, u)
end

function (F::Lagrange!{<:Function,Autonomous,NonFixed})(
    r::ctVector, x::State, u::Control, v::Variable
)::Nothing
    return F.f!(r, x, u, v)
end

function (F::Lagrange!{<:Function,Autonomous,NonFixed})(
    r::ctVector, t::Time, x::State, u::Control, v::Variable
)::Nothing
    return F.f!(r, x, u, v)
end

function (F::Lagrange!{<:Function,NonAutonomous,Fixed})(
    r::ctVector, t::Time, x::State, u::Control
)::Nothing
    return F.f!(r, t, x, u)
end

function (F::Lagrange!{<:Function,NonAutonomous,Fixed})(
    r::ctVector, t::Time, x::State, u::Control, v::Variable
)::Nothing
    return F.f!(r, t, x, u)
end

function (F::Lagrange!{<:Function,NonAutonomous,NonFixed})(
    r::ctVector, t::Time, x::State, u::Control, v::Variable
)::Nothing
    return F.f!(r, t, x, u, v)
end

# --------------------------------------------------------------------------------------------------
"""

$(TYPEDSIGNATURES)

Return the ```Dynamics``` of a function.
Dependencies are specified with a boolean, variable, false by default, autonomous, true by default.

```@example
julia> D = Dynamics((x, u) -> [2x[2]-u^2, x[1]], autonomous=true, variable=false)
julia> D = Dynamics((x, u, v) -> [2x[2]-u^2+v[3], x[1]], autonomous=true, variable=true)
julia> D = Dynamics((t, x, u) -> [t+2x[2]-u^2, x[1]], autonomous=false, variable=false)
julia> D = Dynamics((t, x, u, v) -> [t+2x[2]-u^2+v[3], x[1]], autonomous=false, variable=true)
```
"""
function Dynamics(f::Function; autonomous::Bool=true, variable::Bool=false)
    TD = autonomous ? Autonomous : NonAutonomous
    VD = variable ? NonFixed : Fixed
    return Dynamics{typeof(f),TD,VD}(f)
end

function Dynamics!(f!::Function; autonomous::Bool=true, variable::Bool=false)
    TD = autonomous ? Autonomous : NonAutonomous
    VD = variable ? NonFixed : Fixed
    return Dynamics!{typeof(f!),TD,VD}(f!)
end

"""

$(TYPEDSIGNATURES)

Return the ```Dynamics``` of a function.
Dependencies are specified with DataType, Autonomous, NonAutonomous and Fixed, NonFixed.

```@example
julia> D = Dynamics((x, u) -> [2x[2]-u^2, x[1]], Autonomous, Fixed)
julia> D = Dynamics((x, u, v) -> [2x[2]-u^2+v[3], x[1]], Autonomous, NonFixed)
julia> D = Dynamics((t, x, u) -> [t+2x[2]-u^2, x[1]], NonAutonomous, Fixed)
julia> D = Dynamics((t, x, u, v) -> [t+2x[2]-u^2+v[3], x[1]], NonAutonomous, NonFixed)
```
"""
Dynamics(f::Function, TD::Type{<:TimeDependence}, VD::Type{<:VariableDependence}) =
    Dynamics{typeof(f),TD,VD}(f)
function Dynamics!(f!::Function, TD::Type{<:TimeDependence}, VD::Type{<:VariableDependence})
    return Dynamics!{typeof(f!),TD,VD}(f!)
end

"""

$(TYPEDSIGNATURES)

Return the value of the Dynamics function.

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
function (F::Dynamics{<:Function,Autonomous,Fixed})(x::State, u::Control)::ctVector
    return F.f(x, u)
end

function (F::Dynamics{<:Function,Autonomous,Fixed})(
    t::Time, x::State, u::Control, v::Variable
)::ctVector
    return F.f(x, u)
end

function (F::Dynamics{<:Function,Autonomous,NonFixed})(
    x::State, u::Control, v::Variable
)::ctVector
    return F.f(x, u, v)
end

function (F::Dynamics{<:Function,Autonomous,NonFixed})(
    t::Time, x::State, u::Control, v::Variable
)::ctVector
    return F.f(x, u, v)
end

function (F::Dynamics{<:Function,NonAutonomous,Fixed})(
    t::Time, x::State, u::Control
)::ctVector
    return F.f(t, x, u)
end

function (F::Dynamics{<:Function,NonAutonomous,Fixed})(
    t::Time, x::State, u::Control, v::Variable
)::ctVector
    return F.f(t, x, u)
end

function (F::Dynamics{<:Function,NonAutonomous,NonFixed})(
    t::Time, x::State, u::Control, v::Variable
)::ctVector
    return F.f(t, x, u, v)
end

function (F::Dynamics!{<:Function,Autonomous,Fixed})(
    r::ctVector, x::State, u::Control
)::Nothing
    return F.f!(r, x, u)
end

function (F::Dynamics!{<:Function,Autonomous,Fixed})(
    r::ctVector, t::Time, x::State, u::Control, v::Variable
)::Nothing
    return F.f!(r, x, u)
end

function (F::Dynamics!{<:Function,Autonomous,NonFixed})(
    r::ctVector, x::State, u::Control, v::Variable
)::Nothing
    return F.f!(r, x, u, v)
end

function (F::Dynamics!{<:Function,Autonomous,NonFixed})(
    r::ctVector, t::Time, x::State, u::Control, v::Variable
)::Nothing
    return F.f!(r, x, u, v)
end

function (F::Dynamics!{<:Function,NonAutonomous,Fixed})(
    r::ctVector, t::Time, x::State, u::Control
)::Nothing
    return F.f!(r, t, x, u)
end

function (F::Dynamics!{<:Function,NonAutonomous,Fixed})(
    r::ctVector, t::Time, x::State, u::Control, v::Variable
)::Nothing
    return F.f!(r, t, x, u)
end

function (F::Dynamics!{<:Function,NonAutonomous,NonFixed})(
    r::ctVector, t::Time, x::State, u::Control, v::Variable
)::Nothing
    return F.f!(r, t, x, u, v)
end

# --------------------------------------------------------------------------------------------------
"""

$(TYPEDSIGNATURES)

Return the ```StateConstraint``` of a function.
Dependencies are specified with a boolean, variable, false by default, autonomous, true by default.

```@example
julia> S = StateConstraint(x -> [x[1]^2, 2x[2]], autonomous=true, variable=false)
julia> S = StateConstraint((x, v) -> [x[1]^2, 2x[2]+v[3]], autonomous=true, variable=true)
julia> S = StateConstraint((t, x) -> [t+x[1]^2, 2x[2]], autonomous=false, variable=false)
julia> S = StateConstraint((t, x, v) -> [t+x[1]^2, 2x[2]+v[3]], autonomous=false, variable=true)
```
"""
function StateConstraint(f::Function; autonomous::Bool=true, variable::Bool=false)
    TD = autonomous ? Autonomous : NonAutonomous
    VD = variable ? NonFixed : Fixed
    return StateConstraint{typeof(f),TD,VD}(f)
end

function StateConstraint!(f!::Function; autonomous::Bool=true, variable::Bool=false)
    TD = autonomous ? Autonomous : NonAutonomous
    VD = variable ? NonFixed : Fixed
    return StateConstraint!{typeof(f!),TD,VD}(f!)
end

"""

$(TYPEDSIGNATURES)

Return the ```StateConstraint``` of a function.
Dependencies are specified with DataType, Autonomous, NonAutonomous and Fixed, NonFixed.

```@example
julia> S = StateConstraint(x -> [x[1]^2, 2x[2]], Autonomous, Fixed)
julia> S = StateConstraint((x, v) -> [x[1]^2, 2x[2]+v[3]], Autonomous, NonFixed)
julia> S = StateConstraint((t, x) -> [t+x[1]^2, 2x[2]], NonAutonomous, Fixed)
julia> S = StateConstraint((t, x, v) -> [t+x[1]^2, 2x[2]+v[3]], NonAutonomous, NonFixed)
```
"""
StateConstraint(f::Function, TD::Type{<:TimeDependence}, VD::Type{<:VariableDependence}) =
    StateConstraint{typeof(f),TD,VD}(f)
function StateConstraint!(
    f!::Function, TD::Type{<:TimeDependence}, VD::Type{<:VariableDependence}
)
    return StateConstraint!{typeof(f!),TD,VD}(f!)
end

"""

$(TYPEDSIGNATURES)

Return the value of the StateConstraint function.

```@example
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
function (F::StateConstraint{<:Function,Autonomous,Fixed})(x::State)::ctVector
    return F.f(x)
end

function (F::StateConstraint{<:Function,Autonomous,Fixed})(
    t::Time, x::State, v::Variable
)::ctVector
    return F.f(x)
end

function (F::StateConstraint{<:Function,Autonomous,NonFixed})(
    x::State, v::Variable
)::ctVector
    return F.f(x, v)
end

function (F::StateConstraint{<:Function,Autonomous,NonFixed})(
    t::Time, x::State, v::Variable
)::ctVector
    return F.f(x, v)
end

function (F::StateConstraint{<:Function,NonAutonomous,Fixed})(t::Time, x::State)::ctVector
    return F.f(t, x)
end

function (F::StateConstraint{<:Function,NonAutonomous,Fixed})(
    t::Time, x::State, v::Variable
)::ctVector
    return F.f(t, x)
end

function (F::StateConstraint{<:Function,NonAutonomous,NonFixed})(
    t::Time, x::State, v::Variable
)::ctVector
    return F.f(t, x, v)
end

function (F::StateConstraint!{<:Function,Autonomous,Fixed})(r::ctVector, x::State)::Nothing
    return F.f!(r, x)
end

function (F::StateConstraint!{<:Function,Autonomous,Fixed})(
    r::ctVector, t::Time, x::State, v::Variable
)::Nothing
    return F.f!(r, x)
end

function (F::StateConstraint!{<:Function,Autonomous,NonFixed})(
    r::ctVector, x::State, v::Variable
)::Nothing
    return F.f!(r, x, v)
end

function (F::StateConstraint!{<:Function,Autonomous,NonFixed})(
    r::ctVector, t::Time, x::State, v::Variable
)::Nothing
    return F.f!(r, x, v)
end

function (F::StateConstraint!{<:Function,NonAutonomous,Fixed})(
    r::ctVector, t::Time, x::State
)::Nothing
    return F.f!(r, t, x)
end

function (F::StateConstraint!{<:Function,NonAutonomous,Fixed})(
    r::ctVector, t::Time, x::State, v::Variable
)::Nothing
    return F.f!(r, t, x)
end

function (F::StateConstraint!{<:Function,NonAutonomous,NonFixed})(
    r::ctVector, t::Time, x::State, v::Variable
)::Nothing
    return F.f!(r, t, x, v)
end

# --------------------------------------------------------------------------------------------------

"""

$(TYPEDSIGNATURES)

Return the ```ControlConstraint``` of a function.
Dependencies are specified with a boolean, variable, false by default, autonomous, true by default.

```@example
julia> C = ControlConstraint(u -> [u[1]^2, 2u[2]], autonomous=true, variable=false)
julia> C = ControlConstraint((u, v) -> [u[1]^2, 2u[2]+v[3]], autonomous=true, variable=true)
julia> C = ControlConstraint((t, u) -> [t+u[1]^2, 2u[2]], autonomous=false, variable=false)
julia> C = ControlConstraint((t, u, v) -> [t+u[1]^2, 2u[2]+v[3]], autonomous=false, variable=true)
```
"""
function ControlConstraint(f::Function; autonomous::Bool=true, variable::Bool=false)
    TD = autonomous ? Autonomous : NonAutonomous
    VD = variable ? NonFixed : Fixed
    return ControlConstraint{typeof(f),TD,VD}(f)
end

function ControlConstraint!(f!::Function; autonomous::Bool=true, variable::Bool=false)
    TD = autonomous ? Autonomous : NonAutonomous
    VD = variable ? NonFixed : Fixed
    return ControlConstraint!{typeof(f!),TD,VD}(f!)
end

"""

$(TYPEDSIGNATURES)

Return the ```StateConstraint``` of a function.
Dependencies are specified with DataType, Autonomous, NonAutonomous and Fixed, NonFixed.

```@example
julia> C = ControlConstraint(u -> [u[1]^2, 2u[2]], Autonomous, Fixed)
julia> C = ControlConstraint((u, v) -> [u[1]^2, 2u[2]+v[3]], Autonomous, NonFixed)
julia> C = ControlConstraint((t, u) -> [t+u[1]^2, 2u[2]], NonAutonomous, Fixed)
julia> C = ControlConstraint((t, u, v) -> [t+u[1]^2, 2u[2]+v[3]], NonAutonomous, NonFixed)
```
"""
ControlConstraint(f::Function, TD::Type{<:TimeDependence}, VD::Type{<:VariableDependence}) =
    ControlConstraint{typeof(f),TD,VD}(f)
function ControlConstraint!(
    f!::Function, TD::Type{<:TimeDependence}, VD::Type{<:VariableDependence}
)
    return ControlConstraint!{typeof(f!),TD,VD}(f!)
end

"""

$(TYPEDSIGNATURES)

Return the value of the ControlConstraint function.

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
function (F::ControlConstraint{<:Function,Autonomous,Fixed})(u::Control)::ctVector
    return F.f(u)
end

function (F::ControlConstraint{<:Function,Autonomous,Fixed})(
    t::Time, u::Control, v::Variable
)::ctVector
    return F.f(u)
end

function (F::ControlConstraint{<:Function,Autonomous,NonFixed})(
    u::Control, v::Variable
)::ctVector
    return F.f(u, v)
end

function (F::ControlConstraint{<:Function,Autonomous,NonFixed})(
    t::Time, u::Control, v::Variable
)::ctVector
    return F.f(u, v)
end

function (F::ControlConstraint{<:Function,NonAutonomous,Fixed})(
    t::Time, u::Control
)::ctVector
    return F.f(t, u)
end

function (F::ControlConstraint{<:Function,NonAutonomous,Fixed})(
    t::Time, u::Control, v::Variable
)::ctVector
    return F.f(t, u)
end

function (F::ControlConstraint{<:Function,NonAutonomous,NonFixed})(
    t::Time, u::Control, v::Variable
)::ctVector
    return F.f(t, u, v)
end

function (F::ControlConstraint!{<:Function,Autonomous,Fixed})(
    r::ctVector, u::Control
)::Nothing
    return F.f!(r, u)
end

function (F::ControlConstraint!{<:Function,Autonomous,Fixed})(
    r::ctVector, t::Time, u::Control, v::Variable
)::Nothing
    return F.f!(r, u)
end

function (F::ControlConstraint!{<:Function,Autonomous,NonFixed})(
    r::ctVector, u::Control, v::Variable
)::Nothing
    return F.f!(r, u, v)
end

function (F::ControlConstraint!{<:Function,Autonomous,NonFixed})(
    r::ctVector, t::Time, u::Control, v::Variable
)::Nothing
    return F.f!(r, u, v)
end

function (F::ControlConstraint!{<:Function,NonAutonomous,Fixed})(
    r::ctVector, t::Time, u::Control
)::Nothing
    return F.f!(r, t, u)
end

function (F::ControlConstraint!{<:Function,NonAutonomous,Fixed})(
    r::ctVector, t::Time, u::Control, v::Variable
)::Nothing
    return F.f!(r, t, u)
end

function (F::ControlConstraint!{<:Function,NonAutonomous,NonFixed})(
    r::ctVector, t::Time, u::Control, v::Variable
)::Nothing
    return F.f!(r, t, u, v)
end

# --------------------------------------------------------------------------------------------------
"""

$(TYPEDSIGNATURES)

Return the ```MixedConstraint``` of a function.
Dependencies are specified with a boolean, variable, false by default, autonomous, true by default.

```@example
julia> M = MixedConstraint((x, u) -> [2x[2]-u^2, x[1]], autonomous=true, variable=false)
julia> M = MixedConstraint((x, u, v) -> [2x[2]-u^2+v[3], x[1]], autonomous=true, variable=true)
julia> M = MixedConstraint((t, x, u) -> [t+2x[2]-u^2, x[1]], autonomous=false, variable=false)
julia> M = MixedConstraint((t, x, u, v) -> [t+2x[2]-u^2+v[3], x[1]], autonomous=false, variable=true)
```
"""
function MixedConstraint(f::Function; autonomous::Bool=true, variable::Bool=false)
    TD = autonomous ? Autonomous : NonAutonomous
    VD = variable ? NonFixed : Fixed
    return MixedConstraint{typeof(f),TD,VD}(f)
end

function MixedConstraint!(f!::Function; autonomous::Bool=true, variable::Bool=false)
    TD = autonomous ? Autonomous : NonAutonomous
    VD = variable ? NonFixed : Fixed
    return MixedConstraint!{typeof(f!),TD,VD}(f!)
end

"""

$(TYPEDSIGNATURES)

Return the ```MixedConstraint``` of a function.
Dependencies are specified with DataType, Autonomous, NonAutonomous and Fixed, NonFixed.

```@example
julia> M = MixedConstraint((x, u) -> [2x[2]-u^2, x[1]], Autonomous, Fixed)
julia> M = MixedConstraint((x, u, v) -> [2x[2]-u^2+v[3], x[1]], Autonomous, NonFixed)
julia> M = MixedConstraint((t, x, u) -> [t+2x[2]-u^2, x[1]], NonAutonomous, Fixed)
julia> M = MixedConstraint((t, x, u, v) -> [t+2x[2]-u^2+v[3], x[1]], NonAutonomous, NonFixed)
```
"""
MixedConstraint(f::Function, TD::Type{<:TimeDependence}, VD::Type{<:VariableDependence}) =
    MixedConstraint{typeof(f),TD,VD}(f)
function MixedConstraint!(
    f!::Function, TD::Type{<:TimeDependence}, VD::Type{<:VariableDependence}
)
    return MixedConstraint!{typeof(f!),TD,VD}(f!)
end

"""

$(TYPEDSIGNATURES)

Return the value of the MixedConstraint function.

```@example
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
function (F::MixedConstraint{<:Function,Autonomous,Fixed})(x::State, u::Control)::ctVector
    return F.f(x, u)
end

function (F::MixedConstraint{<:Function,Autonomous,Fixed})(
    t::Time, x::State, u::Control, v::Variable
)::ctVector
    return F.f(x, u)
end

function (F::MixedConstraint{<:Function,Autonomous,NonFixed})(
    x::State, u::Control, v::Variable
)::ctVector
    return F.f(x, u, v)
end

function (F::MixedConstraint{<:Function,Autonomous,NonFixed})(
    t::Time, x::State, u::Control, v::Variable
)::ctVector
    return F.f(x, u, v)
end

function (F::MixedConstraint{<:Function,NonAutonomous,Fixed})(
    t::Time, x::State, u::Control
)::ctVector
    return F.f(t, x, u)
end

function (F::MixedConstraint{<:Function,NonAutonomous,Fixed})(
    t::Time, x::State, u::Control, v::Variable
)::ctVector
    return F.f(t, x, u)
end

function (F::MixedConstraint{<:Function,NonAutonomous,NonFixed})(
    t::Time, x::State, u::Control, v::Variable
)::ctVector
    return F.f(t, x, u, v)
end

function (F::MixedConstraint!{<:Function,Autonomous,Fixed})(
    r::ctVector, x::State, u::Control
)::Nothing
    return F.f!(r, x, u)
end

function (F::MixedConstraint!{<:Function,Autonomous,Fixed})(
    r::ctVector, t::Time, x::State, u::Control, v::Variable
)::Nothing
    return F.f!(r, x, u)
end

function (F::MixedConstraint!{<:Function,Autonomous,NonFixed})(
    r::ctVector, x::State, u::Control, v::Variable
)::Nothing
    return F.f!(r, x, u, v)
end

function (F::MixedConstraint!{<:Function,Autonomous,NonFixed})(
    r::ctVector, t::Time, x::State, u::Control, v::Variable
)::Nothing
    return F.f!(r, x, u, v)
end

function (F::MixedConstraint!{<:Function,NonAutonomous,Fixed})(
    r::ctVector, t::Time, x::State, u::Control
)::Nothing
    return F.f!(r, t, x, u)
end

function (F::MixedConstraint!{<:Function,NonAutonomous,Fixed})(
    r::ctVector, t::Time, x::State, u::Control, v::Variable
)::Nothing
    return F.f!(r, t, x, u)
end

function (F::MixedConstraint!{<:Function,NonAutonomous,NonFixed})(
    r::ctVector, t::Time, x::State, u::Control, v::Variable
)::Nothing
    return F.f!(r, t, x, u, v)
end

# --------------------------------------------------------------------------------------------------
"""

$(TYPEDSIGNATURES)

Return the value of the VariableConstraint function.

```@example
julia> V = VariableConstraint(v -> [v[1]^2, 2v[2]])
julia> V([1, -1])
[1, -2]
```
"""
function (F::VariableConstraint)(v::Variable)::ctVector
    return F.f(v)
end

function (F::VariableConstraint!)(r::ctVector, v::Variable)::Nothing
    return F.f!(r, v)
end

# --------------------------------------------------------------------------------------------------
"""

$(TYPEDSIGNATURES)

Return the ```FeedbackControl``` of a function.
Dependencies are specified with a boolean, variable, false by default, autonomous, true by default.

```@example
julia> u = FeedbackControl(x -> x[1]^2+2x[2], autonomous=true, variable=false)
julia> u = FeedbackControl((x, v) -> x[1]^2+2x[2]+v[3], autonomous=true, variable=true)
julia> u = FeedbackControl((t, x) -> t+x[1]^2+2x[2], autonomous=false, variable=false)
julia> u = FeedbackControl((t, x, v) -> t+x[1]^2+2x[2]+v[3], autonomous=false, variable=true)
```
"""
function FeedbackControl(f::Function; autonomous::Bool=true, variable::Bool=false)
    TD = autonomous ? Autonomous : NonAutonomous
    VD = variable ? NonFixed : Fixed
    return FeedbackControl{typeof(f),TD,VD}(f)
end

"""

$(TYPEDSIGNATURES)

Return the ```FeedbackControl``` of a function.
Dependencies are specified with DataType, Autonomous, NonAutonomous and Fixed, NonFixed.

```@example
julia> u = FeedbackControl(x -> x[1]^2+2x[2], Autonomous, Fixed)
julia> u = FeedbackControl((x, v) -> x[1]^2+2x[2]+v[3], Autonomous, NonFixed)
julia> u = FeedbackControl((t, x) -> t+x[1]^2+2x[2], NonAutonomous, Fixed)
julia> u = FeedbackControl((t, x, v) -> t+x[1]^2+2x[2]+v[3], NonAutonomous, NonFixed)
```
"""
FeedbackControl(f::Function, TD::Type{<:TimeDependence}, VD::Type{<:VariableDependence}) =
    FeedbackControl{typeof(f),TD,VD}(f)

"""

$(TYPEDSIGNATURES)

Return the value of the FeedbackControl function.

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
function (F::FeedbackControl{<:Function,Autonomous,Fixed})(x::State)::ctVector
    return F.f(x)
end

function (F::FeedbackControl{<:Function,Autonomous,Fixed})(
    t::Time, x::State, v::Variable
)::ctVector
    return F.f(x)
end

function (F::FeedbackControl{<:Function,Autonomous,NonFixed})(
    x::State, v::Variable
)::ctVector
    return F.f(x, v)
end

function (F::FeedbackControl{<:Function,Autonomous,NonFixed})(
    t::Time, x::State, v::Variable
)::ctVector
    return F.f(x, v)
end

function (F::FeedbackControl{<:Function,NonAutonomous,Fixed})(t::Time, x::State)::ctVector
    return F.f(t, x)
end

function (F::FeedbackControl{<:Function,NonAutonomous,Fixed})(
    t::Time, x::State, v::Variable
)::ctVector
    return F.f(t, x)
end

function (F::FeedbackControl{<:Function,NonAutonomous,NonFixed})(
    t::Time, x::State, v::Variable
)::ctVector
    return F.f(t, x, v)
end

# --------------------------------------------------------------------------------------------------
"""

$(TYPEDSIGNATURES)

Return the ```ControlLaw``` of a function.
Dependencies are specified with a boolean, variable, false by default, autonomous, true by default.

```@example
julia> u = ControlLaw((x, p) -> x[1]^2+2p[2], autonomous=true, variable=false)
julia> u = ControlLaw((x, p, v) -> x[1]^2+2p[2]+v[3], autonomous=true, variable=true)
julia> u = ControlLaw((t, x, p) -> t+x[1]^2+2p[2], autonomous=false, variable=false)
julia> u = ControlLaw((t, x, p, v) -> t+x[1]^2+2p[2]+v[3], autonomous=false, variable=true)
```
"""
function ControlLaw(f::Function; autonomous::Bool=true, variable::Bool=false)
    TD = autonomous ? Autonomous : NonAutonomous
    VD = variable ? NonFixed : Fixed
    return ControlLaw{typeof(f),TD,VD}(f)
end

"""

$(TYPEDSIGNATURES)

Return the ```ControlLaw``` of a function.
Dependencies are specified with DataType, Autonomous, NonAutonomous and Fixed, NonFixed.

```@example
julia> u = ControlLaw((x, p) -> x[1]^2+2p[2], Autonomous, Fixed)
julia> u = ControlLaw((x, p, v) -> x[1]^2+2p[2]+v[3], Autonomous, NonFixed)
julia> u = ControlLaw((t, x, p) -> t+x[1]^2+2p[2], NonAutonomous, Fixed)
julia> u = ControlLaw((t, x, p, v) -> t+x[1]^2+2p[2]+v[3], NonAutonomous, NonFixed)
```
"""
ControlLaw(f::Function, TD::Type{<:TimeDependence}, VD::Type{<:VariableDependence}) =
    ControlLaw{typeof(f),TD,VD}(f)

"""

$(TYPEDSIGNATURES)

Return the value of the ControlLaw function.

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
function (F::ControlLaw{<:Function,Autonomous,Fixed})(x::State, p::Costate)::ctVector
    return F.f(x, p)
end

function (F::ControlLaw{<:Function,Autonomous,Fixed})(
    t::Time, x::State, p::Costate, v::Variable
)::ctVector
    return F.f(x, p)
end

function (F::ControlLaw{<:Function,Autonomous,NonFixed})(
    x::State, p::Costate, v::Variable
)::ctVector
    return F.f(x, p, v)
end

function (F::ControlLaw{<:Function,Autonomous,NonFixed})(
    t::Time, x::State, p::Costate, v::Variable
)::ctVector
    return F.f(x, p, v)
end

function (F::ControlLaw{<:Function,NonAutonomous,Fixed})(
    t::Time, x::State, p::Costate
)::ctVector
    return F.f(t, x, p)
end

function (F::ControlLaw{<:Function,NonAutonomous,Fixed})(
    t::Time, x::State, p::Costate, v::Variable
)::ctVector
    return F.f(t, x, p)
end

function (F::ControlLaw{<:Function,NonAutonomous,NonFixed})(
    t::Time, x::State, p::Costate, v::Variable
)::ctVector
    return F.f(t, x, p, v)
end

# --------------------------------------------------------------------------------------------------
"""

$(TYPEDSIGNATURES)

Return the ```Multiplier``` of a function.
Dependencies are specified with a boolean, variable, false by default, autonomous, true by default.

```@example
julia> μ = Multiplier((x, p) -> x[1]^2+2p[2], autonomous=true, variable=false)
julia> μ = Multiplier((x, p, v) -> x[1]^2+2p[2]+v[3], autonomous=true, variable=true)
julia> μ = Multiplier((t, x, p) -> t+x[1]^2+2p[2], autonomous=false, variable=false)
julia> μ = Multiplier((t, x, p, v) -> t+x[1]^2+2p[2]+v[3], autonomous=false, variable=true)
```
"""
function Multiplier(f::Function; autonomous::Bool=true, variable::Bool=false)
    TD = autonomous ? Autonomous : NonAutonomous
    VD = variable ? NonFixed : Fixed
    return Multiplier{typeof(f),TD,VD}(f)
end

"""

$(TYPEDSIGNATURES)

Return the ```Multiplier``` of a function.
Dependencies are specified with DataType, Autonomous, NonAutonomous and Fixed, NonFixed.

```@example
julia> μ = Multiplier((x, p) -> x[1]^2+2p[2], Autonomous, Fixed)
julia> μ = Multiplier((x, p, v) -> x[1]^2+2p[2]+v[3], Autonomous, NonFixed)
julia> μ = Multiplier((t, x, p) -> t+x[1]^2+2p[2], NonAutonomous, Fixed)
julia> μ = Multiplier((t, x, p, v) -> t+x[1]^2+2p[2]+v[3], NonAutonomous, NonFixed)
```
"""
Multiplier(f::Function, TD::Type{<:TimeDependence}, VD::Type{<:VariableDependence}) =
    Multiplier{typeof(f),TD,VD}(f)

"""

$(TYPEDSIGNATURES)

Return the value of the Multiplier function.

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
function (F::Multiplier{<:Function,Autonomous,Fixed})(x::State, p::Costate)::ctVector
    return F.f(x, p)
end

function (F::Multiplier{<:Function,Autonomous,Fixed})(
    t::Time, x::State, p::Costate, v::Variable
)::ctVector
    return F.f(x, p)
end

function (F::Multiplier{<:Function,Autonomous,NonFixed})(
    x::State, p::Costate, v::Variable
)::ctVector
    return F.f(x, p, v)
end

function (F::Multiplier{<:Function,Autonomous,NonFixed})(
    t::Time, x::State, p::Costate, v::Variable
)::ctVector
    return F.f(x, p, v)
end

function (F::Multiplier{<:Function,NonAutonomous,Fixed})(
    t::Time, x::State, p::Costate
)::ctVector
    return F.f(t, x, p)
end

function (F::Multiplier{<:Function,NonAutonomous,Fixed})(
    t::Time, x::State, p::Costate, v::Variable
)::ctVector
    return F.f(t, x, p)
end

function (F::Multiplier{<:Function,NonAutonomous,NonFixed})(
    t::Time, x::State, p::Costate, v::Variable
)::ctVector
    return F.f(t, x, p, v)
end
