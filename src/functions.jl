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
function Hamiltonian(f::Function; autonomous::Bool = true, variable::Bool = false)
    TD = autonomous ? Autonomous : NonAutonomous
    VD = variable ? NonFixed : Fixed
    return Hamiltonian{typeof(f), TD, VD}(f)
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
Hamiltonian(f::Function, TD::Type{<:TimeDependence}, VD::Type{<:VariableDependence}) = Hamiltonian{typeof(f), TD, VD}(f)

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
function (F::Hamiltonian{<:Function, Autonomous, Fixed})(x::State, p::Costate)::ctNumber
    return F.f(x, p)
end

function (F::Hamiltonian{<:Function, Autonomous, Fixed})(t::Time, x::State, p::Costate, v::Variable)::ctNumber
    return F.f(x, p)
end

function (F::Hamiltonian{<:Function, Autonomous, NonFixed})(x::State, p::Costate, v::Variable)::ctNumber
    return F.f(x, p, v)
end

function (F::Hamiltonian{<:Function, Autonomous, NonFixed})(
    t::Time,
    x::State,
    p::Costate,
    v::Variable,
)::ctNumber
    return F.f(x, p, v)
end

function (F::Hamiltonian{<:Function, NonAutonomous, Fixed})(t::Time, x::State, p::Costate)::ctNumber
    return F.f(t, x, p)
end

function (F::Hamiltonian{<:Function, NonAutonomous, Fixed})(
    t::Time,
    x::State,
    p::Costate,
    v::Variable,
)::ctNumber
    return F.f(t, x, p)
end

function (F::Hamiltonian{<:Function, NonAutonomous, NonFixed})(
    t::Time,
    x::State,
    p::Costate,
    v::Variable,
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
function HamiltonianLift(f::Function; autonomous::Bool = true, variable::Bool = false)
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
HamiltonianLift(f::Function, TD::Type{<:TimeDependence}, VD::Type{<:VariableDependence}) = HamiltonianLift(VectorField(f, TD, VD))

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
function (H::HamiltonianLift{<:VectorField, Autonomous, Fixed})(x::State, p::Costate)::ctNumber
    return p' * H.X(x)
end

function (H::HamiltonianLift{<:VectorField, Autonomous, Fixed})(
    t::Time,
    x::State,
    p::Costate,
    v::Variable,
)::ctNumber
    return p' * H.X(x)
end

function (H::HamiltonianLift{<:VectorField, Autonomous, NonFixed})(x::State, p::Costate, v::Variable)::ctNumber
    return p' * H.X(x, v)
end

function (H::HamiltonianLift{<:VectorField, Autonomous, NonFixed})(
    t::Time,
    x::State,
    p::Costate,
    v::Variable,
)::ctNumber
    return p' * H.X(x, v)
end

function (H::HamiltonianLift{<:VectorField, NonAutonomous, Fixed})(t::Time, x::State, p::Costate)::ctNumber
    return p' * H.X(t, x)
end

function (H::HamiltonianLift{<:VectorField, NonAutonomous, Fixed})(
    t::Time,
    x::State,
    p::Costate,
    v::Variable,
)::ctNumber
    return p' * H.X(t, x)
end

function (H::HamiltonianLift{<:VectorField, NonAutonomous, NonFixed})(
    t::Time,
    x::State,
    p::Costate,
    v::Variable,
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
function HamiltonianVectorField(f::Function; autonomous::Bool = true, variable::Bool = false)
    TD = autonomous ? Autonomous : NonAutonomous
    VD = variable ? NonFixed : Fixed
    return HamiltonianVectorField{typeof(f), TD, VD}(f)
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
HamiltonianVectorField(f::Function, TD::Type{<:TimeDependence}, VD::Type{<:VariableDependence}) = HamiltonianVectorField{typeof(f), TD, VD}(f)

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
function (F::HamiltonianVectorField{<:Function, Autonomous, Fixed})(
    x::State,
    p::Costate,
)::Tuple{DState, DCostate}
    return F.f(x, p)
end

function (F::HamiltonianVectorField{<:Function, Autonomous, Fixed})(
    t::Time,
    x::State,
    p::Costate,
    v::Variable,
)::Tuple{DState, DCostate}
    return F.f(x, p)
end

function (F::HamiltonianVectorField{<:Function, Autonomous, NonFixed})(
    x::State,
    p::Costate,
    v::Variable,
)::Tuple{DState, DCostate}
    return F.f(x, p, v)
end

function (F::HamiltonianVectorField{<:Function, Autonomous, NonFixed})(
    t::Time,
    x::State,
    p::Costate,
    v::Variable,
)::Tuple{DState, DCostate}
    return F.f(x, p, v)
end

function (F::HamiltonianVectorField{<:Function, NonAutonomous, Fixed})(
    t::Time,
    x::State,
    p::Costate,
)::Tuple{DState, DCostate}
    return F.f(t, x, p)
end

function (F::HamiltonianVectorField{<:Function, NonAutonomous, Fixed})(
    t::Time,
    x::State,
    p::Costate,
    v::Variable,
)::Tuple{DState, DCostate}
    return F.f(t, x, p)
end

function (F::HamiltonianVectorField{<:Function, NonAutonomous, NonFixed})(
    t::Time,
    x::State,
    p::Costate,
    v::Variable,
)::Tuple{DState, DCostate}
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
function VectorField(f::Function; autonomous::Bool = true, variable::Bool = false)
    TD = autonomous ? Autonomous : NonAutonomous
    VD = variable ? NonFixed : Fixed
    return VectorField{typeof(f), TD, VD}(f)
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
VectorField(f::Function, TD::Type{<:TimeDependence}, VD::Type{<:VariableDependence}) = VectorField{typeof(f), TD, VD}(f)

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
function (F::VectorField{<:Function, Autonomous, Fixed})(x::State)::ctVector
    return F.f(x)
end

function (F::VectorField{<:Function, Autonomous, Fixed})(t::Time, x::State, v::Variable)::ctVector
    return F.f(x)
end

function (F::VectorField{<:Function, Autonomous, NonFixed})(x::State, v::Variable)::ctVector
    return F.f(x, v)
end

function (F::VectorField{<:Function, Autonomous, NonFixed})(t::Time, x::State, v::Variable)::ctVector
    return F.f(x, v)
end

function (F::VectorField{<:Function, NonAutonomous, Fixed})(t::Time, x::State)::ctVector
    return F.f(t, x)
end

function (F::VectorField{<:Function, NonAutonomous, Fixed})(t::Time, x::State, v::Variable)::ctVector
    return F.f(t, x)
end

function (F::VectorField{<:Function, NonAutonomous, NonFixed})(t::Time, x::State, v::Variable)::ctVector
    return F.f(t, x, v)
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
function FeedbackControl(f::Function; autonomous::Bool = true, variable::Bool = false)
    TD = autonomous ? Autonomous : NonAutonomous
    VD = variable ? NonFixed : Fixed
    return FeedbackControl{typeof(f), TD, VD}(f)
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
FeedbackControl(f::Function, TD::Type{<:TimeDependence}, VD::Type{<:VariableDependence}) = FeedbackControl{typeof(f), TD, VD}(f)

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
function (F::FeedbackControl{<:Function, Autonomous, Fixed})(x::State)::ctVector
    return F.f(x)
end

function (F::FeedbackControl{<:Function, Autonomous, Fixed})(t::Time, x::State, v::Variable)::ctVector
    return F.f(x)
end

function (F::FeedbackControl{<:Function, Autonomous, NonFixed})(x::State, v::Variable)::ctVector
    return F.f(x, v)
end

function (F::FeedbackControl{<:Function, Autonomous, NonFixed})(t::Time, x::State, v::Variable)::ctVector
    return F.f(x, v)
end

function (F::FeedbackControl{<:Function, NonAutonomous, Fixed})(t::Time, x::State)::ctVector
    return F.f(t, x)
end

function (F::FeedbackControl{<:Function, NonAutonomous, Fixed})(t::Time, x::State, v::Variable)::ctVector
    return F.f(t, x)
end

function (F::FeedbackControl{<:Function, NonAutonomous, NonFixed})(t::Time, x::State, v::Variable)::ctVector
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
function ControlLaw(f::Function; autonomous::Bool = true, variable::Bool = false)
    TD = autonomous ? Autonomous : NonAutonomous
    VD = variable ? NonFixed : Fixed
    return ControlLaw{typeof(f), TD, VD}(f)
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
ControlLaw(f::Function, TD::Type{<:TimeDependence}, VD::Type{<:VariableDependence}) = ControlLaw{typeof(f), TD, VD}(f)

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
function (F::ControlLaw{<:Function, Autonomous, Fixed})(x::State, p::Costate)::ctVector
    return F.f(x, p)
end

function (F::ControlLaw{<:Function, Autonomous, Fixed})(t::Time, x::State, p::Costate, v::Variable)::ctVector
    return F.f(x, p)
end

function (F::ControlLaw{<:Function, Autonomous, NonFixed})(x::State, p::Costate, v::Variable)::ctVector
    return F.f(x, p, v)
end

function (F::ControlLaw{<:Function, Autonomous, NonFixed})(t::Time, x::State, p::Costate, v::Variable)::ctVector
    return F.f(x, p, v)
end

function (F::ControlLaw{<:Function, NonAutonomous, Fixed})(t::Time, x::State, p::Costate)::ctVector
    return F.f(t, x, p)
end

function (F::ControlLaw{<:Function, NonAutonomous, Fixed})(t::Time, x::State, p::Costate, v::Variable)::ctVector
    return F.f(t, x, p)
end

function (F::ControlLaw{<:Function, NonAutonomous, NonFixed})(
    t::Time,
    x::State,
    p::Costate,
    v::Variable,
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
function Multiplier(f::Function; autonomous::Bool = true, variable::Bool = false)
    TD = autonomous ? Autonomous : NonAutonomous
    VD = variable ? NonFixed : Fixed
    return Multiplier{typeof(f), TD, VD}(f)
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
Multiplier(f::Function, TD::Type{<:TimeDependence}, VD::Type{<:VariableDependence}) = Multiplier{typeof(f), TD, VD}(f)

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
function (F::Multiplier{<:Function, Autonomous, Fixed})(x::State, p::Costate)::ctVector
    return F.f(x, p)
end

function (F::Multiplier{<:Function, Autonomous, Fixed})(t::Time, x::State, p::Costate, v::Variable)::ctVector
    return F.f(x, p)
end

function (F::Multiplier{<:Function, Autonomous, NonFixed})(x::State, p::Costate, v::Variable)::ctVector
    return F.f(x, p, v)
end

function (F::Multiplier{<:Function, Autonomous, NonFixed})(t::Time, x::State, p::Costate, v::Variable)::ctVector
    return F.f(x, p, v)
end

function (F::Multiplier{<:Function, NonAutonomous, Fixed})(t::Time, x::State, p::Costate)::ctVector
    return F.f(t, x, p)
end

function (F::Multiplier{<:Function, NonAutonomous, Fixed})(t::Time, x::State, p::Costate, v::Variable)::ctVector
    return F.f(t, x, p)
end

function (F::Multiplier{<:Function, NonAutonomous, NonFixed})(
    t::Time,
    x::State,
    p::Costate,
    v::Variable,
)::ctVector
    return F.f(t, x, p, v)
end
