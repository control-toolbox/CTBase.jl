# --------------------------------------------------------------------------------------------------
function BoundaryConstraint(f::Function; variable::Bool = false)
    variable_dependence = variable ? NonFixed : Fixed
    return BoundaryConstraint{variable_dependence}(f)
end

function BoundaryConstraint(f::Function, dependencies::DataType...)
    __check_dependencies(dependencies)
    variable_dependence = NonFixed ∈ dependencies ? NonFixed : Fixed
    return BoundaryConstraint{variable_dependence}(f)
end

function (F::BoundaryConstraint{Fixed})(x0::State, xf::State)::ctVector
    return F.f(x0, xf)
end

function (F::BoundaryConstraint{Fixed})(x0::State, xf::State, v::Variable)::ctVector
    return F.f(x0, xf)
end

function (F::BoundaryConstraint{NonFixed})(x0::State, xf::State, v::Variable)::ctVector
    return F.f(x0, xf, v)
end

# --------------------------------------------------------------------------------------------------
function Mayer(f::Function; variable::Bool = false)
    variable_dependence = variable ? NonFixed : Fixed
    return Mayer{variable_dependence}(f)
end

function Mayer(f::Function, dependencies::DataType...)
    __check_dependencies(dependencies)
    variable_dependence = NonFixed ∈ dependencies ? NonFixed : Fixed
    return Mayer{variable_dependence}(f)
end

function (F::Mayer{Fixed})(x0::State, xf::State)::ctNumber
    return F.f(x0, xf)
end

function (F::Mayer{Fixed})(x0::State, xf::State, v::Variable)::ctNumber
    return F.f(x0, xf)
end

function (F::Mayer{NonFixed})(x0::State, xf::State, v::Variable)::ctNumber
    return F.f(x0, xf, v)
end

# --------------------------------------------------------------------------------------------------
# Hamiltonian
function Hamiltonian(f::Function; 
    autonomous::Bool=true, variable::Bool=false)
    time_dependence = autonomous ? Autonomous : NonAutonomous
    variable_dependence = variable ? NonFixed : Fixed
    return Hamiltonian{time_dependence, variable_dependence}(f)
end

function Hamiltonian(f::Function, dependencies::DataType...)
    __check_dependencies(dependencies)
    time_dependence = NonAutonomous ∈ dependencies ? NonAutonomous : Autonomous
    variable_dependence = NonFixed ∈ dependencies ? NonFixed : Fixed
    return Hamiltonian{time_dependence, variable_dependence}(f)
end

function (F::Hamiltonian{Autonomous, Fixed})(x::State, p::Costate)::ctNumber
    return F.f(x, p)
end
function (F::Hamiltonian{Autonomous, Fixed})(t::Time, x::State, p::Costate, v::Variable)::ctNumber
    return F.f(x, p)
end
function (F::Hamiltonian{Autonomous, NonFixed})(x::State, p::Costate, v::Variable)::ctNumber
    return F.f(x, p, v)
end
function (F::Hamiltonian{Autonomous, NonFixed})(t::Time, x::State, p::Costate, v::Variable)::ctNumber
    return F.f(x, p, v)
end
function (F::Hamiltonian{NonAutonomous, Fixed})(t::Time, x::State, p::Costate)::ctNumber
    return F.f(t, x, p)
end
function (F::Hamiltonian{NonAutonomous, Fixed})(t::Time, x::State, p::Costate, v::Variable)::ctNumber
    return F.f(t, x, p)
end
function (F::Hamiltonian{NonAutonomous, NonFixed})(t::Time, x::State, p::Costate, v::Variable)::ctNumber
    return F.f(t, x, p, v)
end

# ---------------------------------------------------------------------------
# HamiltonianLift
function HamiltonianLift(f::Function; 
    autonomous::Bool=true, variable::Bool=false)
    time_dependence = autonomous ? Autonomous : NonAutonomous
    variable_dependence = variable ? NonFixed : Fixed
    return HamiltonianLift{time_dependence, variable_dependence}(f)
end

function HamiltonianLift(f::Function, dependences::DataType...)
    __check_dependencies(dependences)
    time_dependence = NonAutonomous ∈ dependences ? NonAutonomous : Autonomous
    variable_dependence = NonFixed ∈ dependences ? NonFixed : Fixed
    return HamiltonianLift{time_dependence, variable_dependence}(f)
end

function (H::HamiltonianLift{Autonomous, Fixed})(x::State, p::Costate)::ctNumber
    return p'*H.X(x)
end
function (H::HamiltonianLift{Autonomous, Fixed})(t::Time, x::State, p::Costate, v::Variable)::ctNumber
    return p'*H.X(x)
end
function (H::HamiltonianLift{Autonomous, NonFixed})(x::State, p::Costate, v::Variable)::ctNumber
    return p'*H.X(x, v)
end
function (H::HamiltonianLift{Autonomous, NonFixed})(t::Time, x::State, p::Costate, v::Variable)::ctNumber
    return p'*H.X(x, v)
end
function (H::HamiltonianLift{NonAutonomous, Fixed})(t::Time, x::State, p::Costate)::ctNumber
    return p'*H.X(t, x)
end
function (H::HamiltonianLift{NonAutonomous, Fixed})(t::Time, x::State, p::Costate, v::Variable)::ctNumber
    return p'*H.X(t, x)
end
function (H::HamiltonianLift{NonAutonomous, NonFixed})(t::Time, x::State, p::Costate, v::Variable)::ctNumber
    return p'*H.X(t, x, v)
end

# --------------------------------------------------------------------------------------------------
function HamiltonianVectorField(f::Function; 
    autonomous::Bool=true, variable::Bool=false)
    time_dependence = autonomous ? Autonomous : NonAutonomous
    variable_dependence = variable ? NonFixed : Fixed
    return HamiltonianVectorField{time_dependence, variable_dependence}(f)
end

function HamiltonianVectorField(f::Function, dependencies::DataType...)
    __check_dependencies(dependencies)
    time_dependence = NonAutonomous ∈ dependencies ? NonAutonomous : Autonomous
    variable_dependence = NonFixed ∈ dependencies ? NonFixed : Fixed
    return HamiltonianVectorField{time_dependence, variable_dependence}(f)
end

function (F::HamiltonianVectorField{Autonomous, Fixed})(x::State, p::Costate)::ctVector
    return F.f(x, p)
end

function (F::HamiltonianVectorField{Autonomous, Fixed})(t::Time, x::State, p::Costate, v::Variable)::ctVector
    return F.f(x, p)
end

function (F::HamiltonianVectorField{Autonomous, NonFixed})(x::State, p::Costate, v::Variable)::ctVector
    return F.f(x, p, v)
end

function (F::HamiltonianVectorField{Autonomous, NonFixed})(t::Time, x::State, p::Costate, v::Variable)::ctVector
    return F.f(x, p, v)
end

function (F::HamiltonianVectorField{NonAutonomous, Fixed})(t::Time, x::State, p::Costate)::ctVector
    return F.f(t, x, p)
end

function (F::HamiltonianVectorField{NonAutonomous, Fixed})(t::Time, x::State, p::Costate, v::Variable)::ctVector
    return F.f(t, x, p)
end

function (F::HamiltonianVectorField{NonAutonomous, NonFixed})(t::Time, x::State, p::Costate, v::Variable)::ctVector
    return F.f(t, x, p, v)
end

# --------------------------------------------------------------------------------------------------
function VectorField(f::Function; 
    autonomous::Bool=true, variable::Bool=false)
    time_dependence = autonomous ? Autonomous : NonAutonomous
    variable_dependence = variable ? NonFixed : Fixed
    return VectorField{time_dependence, variable_dependence}(f)
end

function VectorField(f::Function, dependencies::DataType...)
    __check_dependencies(dependencies)
    time_dependence = NonAutonomous ∈ dependencies ? NonAutonomous : Autonomous
    variable_dependence = NonFixed ∈ dependencies ? NonFixed : Fixed
    return VectorField{time_dependence, variable_dependence}(f)
end

function (F::VectorField{Autonomous, Fixed})(x::State)::ctVector
    return F.f(x)
end

function (F::VectorField{Autonomous, Fixed})(t::Time, x::State, v::Variable)::ctVector
    return F.f(x)
end

function (F::VectorField{Autonomous, NonFixed})(x::State, v::Variable)::ctVector
    return F.f(x, v)
end

function (F::VectorField{Autonomous, NonFixed})(t::Time, x::State, v::Variable)::ctVector
    return F.f(x, v)
end

function (F::VectorField{NonAutonomous, Fixed})(t::Time, x::State)::ctVector
    return F.f(t, x)
end

function (F::VectorField{NonAutonomous, Fixed})(t::Time, x::State, v::Variable)::ctVector
    return F.f(t, x)
end

function (F::VectorField{NonAutonomous, NonFixed})(t::Time, x::State, v::Variable)::ctVector
    return F.f(t, x, v)
end

# --------------------------------------------------------------------------------------------------
function Lagrange(f::Function; 
    autonomous::Bool=true, variable::Bool=false)
    time_dependence = autonomous ? Autonomous : NonAutonomous
    variable_dependence = variable ? NonFixed : Fixed
    return Lagrange{time_dependence, variable_dependence}(f)
end

function Lagrange(f::Function, dependencies::DataType...)
    __check_dependencies(dependencies)
    time_dependence = NonAutonomous ∈ dependencies ? NonAutonomous : Autonomous
    variable_dependence = NonFixed ∈ dependencies ? NonFixed : Fixed
    return Lagrange{time_dependence, variable_dependence}(f)
end

function (F::Lagrange{Autonomous, Fixed})(x::State, u::Control)::ctNumber
    return F.f(x, u)
end

function (F::Lagrange{Autonomous, Fixed})(t::Time, x::State, u::Control, v::Variable)::ctNumber
    return F.f(x, u)
end

function (F::Lagrange{Autonomous, NonFixed})(x::State, u::Control, v::Variable)::ctNumber
    return F.f(x, u, v)
end

function (F::Lagrange{Autonomous, NonFixed})(t::Time, x::State, u::Control, v::Variable)::ctNumber
    return F.f(x, u, v)
end

function (F::Lagrange{NonAutonomous, Fixed})(t::Time, x::State, u::Control)::ctNumber
    return F.f(t, x, u)
end

function (F::Lagrange{NonAutonomous, Fixed})(t::Time, x::State, u::Control, v::Variable)::ctNumber
    return F.f(t, x, u)
end

function (F::Lagrange{NonAutonomous, NonFixed})(t::Time, x::State, u::Control, v::Variable)::ctNumber
    return F.f(t, x, u, v)
end

# --------------------------------------------------------------------------------------------------
function Dynamics(f::Function; 
    autonomous::Bool=true, variable::Bool=false)
    time_dependence = autonomous ? Autonomous : NonAutonomous
    variable_dependence = variable ? NonFixed : Fixed
    return Dynamics{time_dependence, variable_dependence}(f)
end

function Dynamics(f::Function, dependencies::DataType...)
    __check_dependencies(dependencies)
    time_dependence = NonAutonomous ∈ dependencies ? NonAutonomous : Autonomous
    variable_dependence = NonFixed ∈ dependencies ? NonFixed : Fixed
    return Dynamics{time_dependence, variable_dependence}(f)
end

function (F::Dynamics{Autonomous, Fixed})(x::State, u::Control)::ctVector
    return F.f(x, u)
end

function (F::Dynamics{Autonomous, Fixed})(t::Time, x::State, u::Control, v::Variable)::ctVector
    return F.f(x, u)
end

function (F::Dynamics{Autonomous, NonFixed})(x::State, u::Control, v::Variable)::ctVector
    return F.f(x, u, v)
end

function (F::Dynamics{Autonomous, NonFixed})(t::Time, x::State, u::Control, v::Variable)::ctVector
    return F.f(x, u, v)
end

function (F::Dynamics{NonAutonomous, Fixed})(t::Time, x::State, u::Control)::ctVector
    return F.f(t, x, u)
end

function (F::Dynamics{NonAutonomous, Fixed})(t::Time, x::State, u::Control, v::Variable)::ctVector
    return F.f(t, x, u)
end

function (F::Dynamics{NonAutonomous, NonFixed})(t::Time, x::State, u::Control, v::Variable)::ctVector
    return F.f(t, x, u, v)
end

# --------------------------------------------------------------------------------------------------
function StateConstraint(f::Function; 
    autonomous::Bool=true, variable::Bool=false)
    time_dependence = autonomous ? Autonomous : NonAutonomous
    variable_dependence = variable ? NonFixed : Fixed
    return StateConstraint{time_dependence, variable_dependence}(f)
end

function StateConstraint(f::Function, dependencies::DataType...)
    __check_dependencies(dependencies)
    time_dependence = NonAutonomous ∈ dependencies ? NonAutonomous : Autonomous
    variable_dependence = NonFixed ∈ dependencies ? NonFixed : Fixed
    return StateConstraint{time_dependence, variable_dependence}(f)
end

function (F::StateConstraint{Autonomous, Fixed})(x::State)::ctVector
    return F.f(x)
end

function (F::StateConstraint{Autonomous, Fixed})(t::Time, x::State, v::Variable)::ctVector
    return F.f(x)
end

function (F::StateConstraint{Autonomous, NonFixed})(x::State, v::Variable)::ctVector
    return F.f(x, v)
end

function (F::StateConstraint{Autonomous, NonFixed})(t::Time, x::State, v::Variable)::ctVector
    return F.f(x, v)
end

function (F::StateConstraint{NonAutonomous, Fixed})(t::Time, x::State)::ctVector
    return F.f(t, x)
end

function (F::StateConstraint{NonAutonomous, Fixed})(t::Time, x::State, v::Variable)::ctVector
    return F.f(t, x)
end

function (F::StateConstraint{NonAutonomous, NonFixed})(t::Time, x::State, v::Variable)::ctVector
    return F.f(t, x, v)
end

# --------------------------------------------------------------------------------------------------
function ControlConstraint(f::Function; 
    autonomous::Bool=true, variable::Bool=false)
    time_dependence = autonomous ? Autonomous : NonAutonomous
    variable_dependence = variable ? NonFixed : Fixed
    return ControlConstraint{time_dependence, variable_dependence}(f)
end

function ControlConstraint(f::Function, dependencies::DataType...)
    __check_dependencies(dependencies)
    time_dependence = NonAutonomous ∈ dependencies ? NonAutonomous : Autonomous
    variable_dependence = NonFixed ∈ dependencies ? NonFixed : Fixed
    return ControlConstraint{time_dependence, variable_dependence}(f)
end

function (F::ControlConstraint{Autonomous, Fixed})(u::Control)::ctVector
    return F.f(u)
end

function (F::ControlConstraint{Autonomous, Fixed})(t::Time, u::Control, v::Variable)::ctVector
    return F.f(u)
end

function (F::ControlConstraint{Autonomous, NonFixed})(u::Control, v::Variable)::ctVector
    return F.f(u, v)
end

function (F::ControlConstraint{Autonomous, NonFixed})(t::Time, u::Control, v::Variable)::ctVector
    return F.f(u, v)
end

function (F::ControlConstraint{NonAutonomous, Fixed})(t::Time, u::Control)::ctVector
    return F.f(t, u)
end

function (F::ControlConstraint{NonAutonomous, Fixed})(t::Time, u::Control, v::Variable)::ctVector
    return F.f(t, u)
end

function (F::ControlConstraint{NonAutonomous, NonFixed})(t::Time, u::Control, v::Variable)::ctVector
    return F.f(t, u, v)
end

# --------------------------------------------------------------------------------------------------
function MixedConstraint(f::Function; 
    autonomous::Bool=true, variable::Bool=false)
    time_dependence = autonomous ? Autonomous : NonAutonomous
    variable_dependence = variable ? NonFixed : Fixed
    return MixedConstraint{time_dependence, variable_dependence}(f)
end

function MixedConstraint(f::Function, dependencies::DataType...)
    __check_dependencies(dependencies)
    time_dependence = NonAutonomous ∈ dependencies ? NonAutonomous : Autonomous
    variable_dependence = NonFixed ∈ dependencies ? NonFixed : Fixed
    return MixedConstraint{time_dependence, variable_dependence}(f)
end

function (F::MixedConstraint{Autonomous, Fixed})(x::State, u::Control)::ctVector
    return F.f(x, u)
end

function (F::MixedConstraint{Autonomous, Fixed})(t::Time, x::State, u::Control, v::Variable)::ctVector
    return F.f(x, u)
end

function (F::MixedConstraint{Autonomous, NonFixed})(x::State, u::Control, v::Variable)::ctVector
    return F.f(x, u, v)
end

function (F::MixedConstraint{Autonomous, NonFixed})(t::Time, x::State, u::Control, v::Variable)::ctVector
    return F.f(x, u, v)
end

function (F::MixedConstraint{NonAutonomous, Fixed})(t::Time, x::State, u::Control)::ctVector
    return F.f(t, x, u)
end

function (F::MixedConstraint{NonAutonomous, Fixed})(t::Time, x::State, u::Control, v::Variable)::ctVector
    return F.f(t, x, u)
end

function (F::MixedConstraint{NonAutonomous, NonFixed})(t::Time, x::State, u::Control, v::Variable)::ctVector
    return F.f(t, x, u, v)
end

# --------------------------------------------------------------------------------------------------
function (F::VariableConstraint)(v::Variable)::ctVector
    return F.f(v)
end

# --------------------------------------------------------------------------------------------------
function FeedbackControl(f::Function; 
    autonomous::Bool=true, variable::Bool=false)
    time_dependence = autonomous ? Autonomous : NonAutonomous
    variable_dependence = variable ? NonFixed : Fixed
    return FeedbackControl{time_dependence, variable_dependence}(f)
end

function FeedbackControl(f::Function, dependencies::DataType...)
    __check_dependencies(dependencies)
    time_dependence = NonAutonomous ∈ dependencies ? NonAutonomous : Autonomous
    variable_dependence = NonFixed ∈ dependencies ? NonFixed : Fixed
    return FeedbackControl{time_dependence, variable_dependence}(f)
end

function (F::FeedbackControl{Autonomous, Fixed})(x::State)::ctVector
    return F.f(x)
end

function (F::FeedbackControl{Autonomous, Fixed})(t::Time, x::State, v::Variable)::ctVector
    return F.f(x)
end

function (F::FeedbackControl{Autonomous, NonFixed})(x::State, v::Variable)::ctVector
    return F.f(x, v)
end

function (F::FeedbackControl{Autonomous, NonFixed})(t::Time, x::State, v::Variable)::ctVector
    return F.f(x, v)
end

function (F::FeedbackControl{NonAutonomous, Fixed})(t::Time, x::State)::ctVector
    return F.f(t, x)
end

function (F::FeedbackControl{NonAutonomous, Fixed})(t::Time, x::State, v::Variable)::ctVector
    return F.f(t, x)
end

function (F::FeedbackControl{NonAutonomous, NonFixed})(t::Time, x::State, v::Variable)::ctVector
    return F.f(t, x, v)
end

# --------------------------------------------------------------------------------------------------
function ControlLaw(f::Function; 
    autonomous::Bool=true, variable::Bool=false)
    time_dependence = autonomous ? Autonomous : NonAutonomous
    variable_dependence = variable ? NonFixed : Fixed
    return ControlLaw{time_dependence, variable_dependence}(f)
end

function ControlLaw(f::Function, dependencies::DataType...)
    __check_dependencies(dependencies)
    time_dependence = NonAutonomous ∈ dependencies ? NonAutonomous : Autonomous
    variable_dependence = NonFixed ∈ dependencies ? NonFixed : Fixed
    return ControlLaw{time_dependence, variable_dependence}(f)
end

function (F::ControlLaw{Autonomous, Fixed})(x::State, p::Costate)::ctVector
    return F.f(x, p)
end

function (F::ControlLaw{Autonomous, Fixed})(t::Time, x::State, p::Costate, v::Variable)::ctVector
    return F.f(x, p)
end

function (F::ControlLaw{Autonomous, NonFixed})(x::State, p::Costate, v::Variable)::ctVector
    return F.f(x, p, v)
end

function (F::ControlLaw{Autonomous, NonFixed})(t::Time, x::State, p::Costate, v::Variable)::ctVector
    return F.f(x, p, v)
end

function (F::ControlLaw{NonAutonomous, Fixed})(t::Time, x::State, p::Costate)::ctVector
    return F.f(t, x, p)
end

function (F::ControlLaw{NonAutonomous, Fixed})(t::Time, x::State, p::Costate, v::Variable)::ctVector
    return F.f(t, x, p)
end

function (F::ControlLaw{NonAutonomous, NonFixed})(t::Time, x::State, p::Costate, v::Variable)::ctVector
    return F.f(t, x, p, v)
end

# --------------------------------------------------------------------------------------------------
function Multiplier(f::Function; 
    autonomous::Bool=true, variable::Bool=false)
    time_dependence = autonomous ? Autonomous : NonAutonomous
    variable_dependence = variable ? NonFixed : Fixed
    return Multiplier{time_dependence, variable_dependence}(f)
end

function Multiplier(f::Function, dependencies::DataType...)
    __check_dependencies(dependencies)
    time_dependence = NonAutonomous ∈ dependencies ? NonAutonomous : Autonomous
    variable_dependence = NonFixed ∈ dependencies ? NonFixed : Fixed
    return Multiplier{time_dependence, variable_dependence}(f)
end

function (F::Multiplier{Autonomous, Fixed})(x::State, p::Costate)::ctVector
    return F.f(x, p)
end

function (F::Multiplier{Autonomous, Fixed})(t::Time, x::State, p::Costate, v::Variable)::ctVector
    return F.f(x, p)
end

function (F::Multiplier{Autonomous, NonFixed})(x::State, p::Costate, v::Variable)::ctVector
    return F.f(x, p, v)
end

function (F::Multiplier{Autonomous, NonFixed})(t::Time, x::State, p::Costate, v::Variable)::ctVector
    return F.f(x, p, v)
end

function (F::Multiplier{NonAutonomous, Fixed})(t::Time, x::State, p::Costate)::ctVector
    return F.f(t, x, p)
end

function (F::Multiplier{NonAutonomous, Fixed})(t::Time, x::State, p::Costate, v::Variable)::ctVector
    return F.f(t, x, p)
end

function (F::Multiplier{NonAutonomous, NonFixed})(t::Time, x::State, p::Costate, v::Variable)::ctVector
    return F.f(t, x, p, v)
end
