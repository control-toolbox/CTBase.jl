# --------------------------------------------------------------------------------------------------
function BoundaryConstraint(f::Function; variable::Bool = false)
    variable_dependence = variable ? Variable : NonVariable
    return BoundaryConstraint{variable_dependence}(f)
end

function BoundaryConstraint(f::Function, dependences::DataType...)
    @__check(dependences)
    variable_dependence = Variable ∈ dependences ? Variable : NonVariable
    return BoundaryConstraint{variable_dependence}(f)
end

function (F::BoundaryConstraint{NonVariable})(x0::State, xf::State)::ctVector
    return F.f(x0, xf)
end

function (F::BoundaryConstraint{NonVariable})(x0::State, xf::State, v::DecisionVariable)::ctVector
    return F.f(x0, xf)
end

function (F::BoundaryConstraint{Variable})(x0::State, xf::State, v::DecisionVariable)::ctVector
    return F.f(x0, xf, v)
end

# --------------------------------------------------------------------------------------------------
function Mayer(f::Function; variable::Bool = false)
    variable_dependence = variable ? Variable : NonVariable
    return Mayer{variable_dependence}(f)
end

function Mayer(f::Function, dependences::DataType...)
    @__check(dependences)
    variable_dependence = Variable ∈ dependences ? Variable : NonVariable
    return Mayer{variable_dependence}(f)
end

function (F::Mayer{NonVariable})(x0::State, xf::State)::ctNumber
    return F.f(x0, xf)
end

function (F::Mayer{NonVariable})(x0::State, xf::State, v::DecisionVariable)::ctNumber
    return F.f(x0, xf)
end

function (F::Mayer{Variable})(x0::State, xf::State, v::DecisionVariable)::ctNumber
    return F.f(x0, xf, v)
end

# --------------------------------------------------------------------------------------------------
function Hamiltonian(f::Function; 
    autonomous::Bool=true, variable::Bool=false)
    time_dependence = autonomous ? Autonomous : NonAutonomous
    variable_dependence = variable ? Variable : NonVariable
    return Hamiltonian{time_dependence, variable_dependence}(f)
end

function Hamiltonian(f::Function, dependences::DataType...)
    @__check(dependences)
    time_dependence = NonAutonomous ∈ dependences ? NonAutonomous : Autonomous
    variable_dependence = Variable ∈ dependences ? Variable : NonVariable
    return Hamiltonian{time_dependence, variable_dependence}(f)
end

function (F::Hamiltonian{Autonomous, NonVariable})(x::State, p::Costate)::ctNumber
    return F.f(x, p)
end

function (F::Hamiltonian{Autonomous, NonVariable})(t::Time, x::State, p::Costate, v::DecisionVariable)::ctNumber
    return F.f(x, p)
end

function (F::Hamiltonian{Autonomous, Variable})(x::State, p::Costate, v::DecisionVariable)::ctNumber
    return F.f(x, p, v)
end

function (F::Hamiltonian{Autonomous, Variable})(t::Time, x::State, p::Costate, v::DecisionVariable)::ctNumber
    return F.f(x, p, v)
end

function (F::Hamiltonian{NonAutonomous, NonVariable})(t::Time, x::State, p::Costate)::ctNumber
    return F.f(t, x, p)
end

function (F::Hamiltonian{NonAutonomous, NonVariable})(t::Time, x::State, p::Costate, v::DecisionVariable)::ctNumber
    return F.f(t, x, p)
end

function (F::Hamiltonian{NonAutonomous, Variable})(t::Time, x::State, p::Costate, v::DecisionVariable)::ctNumber
    return F.f(t, x, p, v)
end

# --------------------------------------------------------------------------------------------------
function HamiltonianVectorField(f::Function; 
    autonomous::Bool=true, variable::Bool=false)
    time_dependence = autonomous ? Autonomous : NonAutonomous
    variable_dependence = variable ? Variable : NonVariable
    return HamiltonianVectorField{time_dependence, variable_dependence}(f)
end

function HamiltonianVectorField(f::Function, dependences::DataType...)
    @__check(dependences)
    time_dependence = NonAutonomous ∈ dependences ? NonAutonomous : Autonomous
    variable_dependence = Variable ∈ dependences ? Variable : NonVariable
    return HamiltonianVectorField{time_dependence, variable_dependence}(f)
end

function (F::HamiltonianVectorField{Autonomous, NonVariable})(x::State, p::Costate)::ctVector
    return F.f(x, p)
end

function (F::HamiltonianVectorField{Autonomous, NonVariable})(t::Time, x::State, p::Costate, v::DecisionVariable)::ctVector
    return F.f(x, p)
end

function (F::HamiltonianVectorField{Autonomous, Variable})(x::State, p::Costate, v::DecisionVariable)::ctVector
    return F.f(x, p, v)
end

function (F::HamiltonianVectorField{Autonomous, Variable})(t::Time, x::State, p::Costate, v::DecisionVariable)::ctVector
    return F.f(x, p, v)
end

function (F::HamiltonianVectorField{NonAutonomous, NonVariable})(t::Time, x::State, p::Costate)::ctVector
    return F.f(t, x, p)
end

function (F::HamiltonianVectorField{NonAutonomous, NonVariable})(t::Time, x::State, p::Costate, v::DecisionVariable)::ctVector
    return F.f(t, x, p)
end

function (F::HamiltonianVectorField{NonAutonomous, Variable})(t::Time, x::State, p::Costate, v::DecisionVariable)::ctVector
    return F.f(t, x, p, v)
end

# --------------------------------------------------------------------------------------------------
function VectorField(f::Function; 
    autonomous::Bool=true, variable::Bool=false)
    time_dependence = autonomous ? Autonomous : NonAutonomous
    variable_dependence = variable ? Variable : NonVariable
    return VectorField{time_dependence, variable_dependence}(f)
end

function VectorField(f::Function, dependences::DataType...)
    @__check(dependences)
    time_dependence = NonAutonomous ∈ dependences ? NonAutonomous : Autonomous
    variable_dependence = Variable ∈ dependences ? Variable : NonVariable
    return VectorField{time_dependence, variable_dependence}(f)
end

function (F::VectorField{Autonomous, NonVariable})(x::State)::ctVector
    return F.f(x)
end

function (F::VectorField{Autonomous, NonVariable})(t::Time, x::State, v::DecisionVariable)::ctVector
    return F.f(x)
end

function (F::VectorField{Autonomous, Variable})(x::State, v::DecisionVariable)::ctVector
    return F.f(x, v)
end

function (F::VectorField{Autonomous, Variable})(t::Time, x::State, v::DecisionVariable)::ctVector
    return F.f(x, v)
end

function (F::VectorField{NonAutonomous, NonVariable})(t::Time, x::State)::ctVector
    return F.f(t, x)
end

function (F::VectorField{NonAutonomous, NonVariable})(t::Time, x::State, v::DecisionVariable)::ctVector
    return F.f(t, x)
end

function (F::VectorField{NonAutonomous, Variable})(t::Time, x::State, v::DecisionVariable)::ctVector
    return F.f(t, x, v)
end

# --------------------------------------------------------------------------------------------------
function Lagrange(f::Function; 
    autonomous::Bool=true, variable::Bool=false)
    time_dependence = autonomous ? Autonomous : NonAutonomous
    variable_dependence = variable ? Variable : NonVariable
    return Lagrange{time_dependence, variable_dependence}(f)
end

function Lagrange(f::Function, dependences::DataType...)
    @__check(dependences)
    time_dependence = NonAutonomous ∈ dependences ? NonAutonomous : Autonomous
    variable_dependence = Variable ∈ dependences ? Variable : NonVariable
    return Lagrange{time_dependence, variable_dependence}(f)
end

function (F::Lagrange{Autonomous, NonVariable})(x::State, u::Control)::ctNumber
    return F.f(x, u)
end

function (F::Lagrange{Autonomous, NonVariable})(t::Time, x::State, u::Control, v::DecisionVariable)::ctNumber
    return F.f(x, u)
end

function (F::Lagrange{Autonomous, Variable})(x::State, u::Control, v::DecisionVariable)::ctNumber
    return F.f(x, u, v)
end

function (F::Lagrange{Autonomous, Variable})(t::Time, x::State, u::Control, v::DecisionVariable)::ctNumber
    return F.f(x, u, v)
end

function (F::Lagrange{NonAutonomous, NonVariable})(t::Time, x::State, u::Control)::ctNumber
    return F.f(t, x, u)
end

function (F::Lagrange{NonAutonomous, NonVariable})(t::Time, x::State, u::Control, v::DecisionVariable)::ctNumber
    return F.f(t, x, u)
end

function (F::Lagrange{NonAutonomous, Variable})(t::Time, x::State, u::Control, v::DecisionVariable)::ctNumber
    return F.f(t, x, u, v)
end

# --------------------------------------------------------------------------------------------------
function Dynamics(f::Function; 
    autonomous::Bool=true, variable::Bool=false)
    time_dependence = autonomous ? Autonomous : NonAutonomous
    variable_dependence = variable ? Variable : NonVariable
    return Dynamics{time_dependence, variable_dependence}(f)
end

function Dynamics(f::Function, dependences::DataType...)
    @__check(dependences)
    time_dependence = NonAutonomous ∈ dependences ? NonAutonomous : Autonomous
    variable_dependence = Variable ∈ dependences ? Variable : NonVariable
    return Dynamics{time_dependence, variable_dependence}(f)
end

function (F::Dynamics{Autonomous, NonVariable})(x::State, u::Control)::ctVector
    return F.f(x, u)
end

function (F::Dynamics{Autonomous, NonVariable})(t::Time, x::State, u::Control, v::DecisionVariable)::ctVector
    return F.f(x, u)
end

function (F::Dynamics{Autonomous, Variable})(x::State, u::Control, v::DecisionVariable)::ctVector
    return F.f(x, u, v)
end

function (F::Dynamics{Autonomous, Variable})(t::Time, x::State, u::Control, v::DecisionVariable)::ctVector
    return F.f(x, u, v)
end

function (F::Dynamics{NonAutonomous, NonVariable})(t::Time, x::State, u::Control)::ctVector
    return F.f(t, x, u)
end

function (F::Dynamics{NonAutonomous, NonVariable})(t::Time, x::State, u::Control, v::DecisionVariable)::ctVector
    return F.f(t, x, u)
end

function (F::Dynamics{NonAutonomous, Variable})(t::Time, x::State, u::Control, v::DecisionVariable)::ctVector
    return F.f(t, x, u, v)
end

# --------------------------------------------------------------------------------------------------
function StateConstraint(f::Function; 
    autonomous::Bool=true, variable::Bool=false)
    time_dependence = autonomous ? Autonomous : NonAutonomous
    variable_dependence = variable ? Variable : NonVariable
    return StateConstraint{time_dependence, variable_dependence}(f)
end

function StateConstraint(f::Function, dependences::DataType...)
    @__check(dependences)
    time_dependence = NonAutonomous ∈ dependences ? NonAutonomous : Autonomous
    variable_dependence = Variable ∈ dependences ? Variable : NonVariable
    return StateConstraint{time_dependence, variable_dependence}(f)
end

function (F::StateConstraint{Autonomous, NonVariable})(x::State)::ctVector
    return F.f(x)
end

function (F::StateConstraint{Autonomous, NonVariable})(t::Time, x::State, v::DecisionVariable)::ctVector
    return F.f(x)
end

function (F::StateConstraint{Autonomous, Variable})(x::State, v::DecisionVariable)::ctVector
    return F.f(x, v)
end

function (F::StateConstraint{Autonomous, Variable})(t::Time, x::State, v::DecisionVariable)::ctVector
    return F.f(x, v)
end

function (F::StateConstraint{NonAutonomous, NonVariable})(t::Time, x::State)::ctVector
    return F.f(t, x)
end

function (F::StateConstraint{NonAutonomous, NonVariable})(t::Time, x::State, v::DecisionVariable)::ctVector
    return F.f(t, x)
end

function (F::StateConstraint{NonAutonomous, Variable})(t::Time, x::State, v::DecisionVariable)::ctVector
    return F.f(t, x, v)
end

# --------------------------------------------------------------------------------------------------
function ControlConstraint(f::Function; 
    autonomous::Bool=true, variable::Bool=false)
    time_dependence = autonomous ? Autonomous : NonAutonomous
    variable_dependence = variable ? Variable : NonVariable
    return ControlConstraint{time_dependence, variable_dependence}(f)
end

function ControlConstraint(f::Function, dependences::DataType...)
    @__check(dependences)
    time_dependence = NonAutonomous ∈ dependences ? NonAutonomous : Autonomous
    variable_dependence = Variable ∈ dependences ? Variable : NonVariable
    return ControlConstraint{time_dependence, variable_dependence}(f)
end

function (F::ControlConstraint{Autonomous, NonVariable})(u::Control)::ctVector
    return F.f(u)
end

function (F::ControlConstraint{Autonomous, NonVariable})(t::Time, u::Control, v::DecisionVariable)::ctVector
    return F.f(u)
end

function (F::ControlConstraint{Autonomous, Variable})(u::Control, v::DecisionVariable)::ctVector
    return F.f(u, v)
end

function (F::ControlConstraint{Autonomous, Variable})(t::Time, u::Control, v::DecisionVariable)::ctVector
    return F.f(u, v)
end

function (F::ControlConstraint{NonAutonomous, NonVariable})(t::Time, u::Control)::ctVector
    return F.f(t, u)
end

function (F::ControlConstraint{NonAutonomous, NonVariable})(t::Time, u::Control, v::DecisionVariable)::ctVector
    return F.f(t, u)
end

function (F::ControlConstraint{NonAutonomous, Variable})(t::Time, u::Control, v::DecisionVariable)::ctVector
    return F.f(t, u, v)
end

# --------------------------------------------------------------------------------------------------
function MixedConstraint(f::Function; 
    autonomous::Bool=true, variable::Bool=false)
    time_dependence = autonomous ? Autonomous : NonAutonomous
    variable_dependence = variable ? Variable : NonVariable
    return MixedConstraint{time_dependence, variable_dependence}(f)
end

function MixedConstraint(f::Function, dependences::DataType...)
    @__check(dependences)
    time_dependence = NonAutonomous ∈ dependences ? NonAutonomous : Autonomous
    variable_dependence = Variable ∈ dependences ? Variable : NonVariable
    return MixedConstraint{time_dependence, variable_dependence}(f)
end

function (F::MixedConstraint{Autonomous, NonVariable})(x::State, u::Control)::ctVector
    return F.f(x, u)
end

function (F::MixedConstraint{Autonomous, NonVariable})(t::Time, x::State, u::Control, v::DecisionVariable)::ctVector
    return F.f(x, u)
end

function (F::MixedConstraint{Autonomous, Variable})(x::State, u::Control, v::DecisionVariable)::ctVector
    return F.f(x, u, v)
end

function (F::MixedConstraint{Autonomous, Variable})(t::Time, x::State, u::Control, v::DecisionVariable)::ctVector
    return F.f(x, u, v)
end

function (F::MixedConstraint{NonAutonomous, NonVariable})(t::Time, x::State, u::Control)::ctVector
    return F.f(t, x, u)
end

function (F::MixedConstraint{NonAutonomous, NonVariable})(t::Time, x::State, u::Control, v::DecisionVariable)::ctVector
    return F.f(t, x, u)
end

function (F::MixedConstraint{NonAutonomous, Variable})(t::Time, x::State, u::Control, v::DecisionVariable)::ctVector
    return F.f(t, x, u, v)
end

# --------------------------------------------------------------------------------------------------
function (F::VariableConstraint)(v::DecisionVariable)::ctVector
    return F.f(v)
end

# --------------------------------------------------------------------------------------------------
function FeedbackControl(f::Function; 
    autonomous::Bool=true, variable::Bool=false)
    time_dependence = autonomous ? Autonomous : NonAutonomous
    variable_dependence = variable ? Variable : NonVariable
    return FeedbackControl{time_dependence, variable_dependence}(f)
end

function FeedbackControl(f::Function, dependences::DataType...)
    @__check(dependences)
    time_dependence = NonAutonomous ∈ dependences ? NonAutonomous : Autonomous
    variable_dependence = Variable ∈ dependences ? Variable : NonVariable
    return FeedbackControl{time_dependence, variable_dependence}(f)
end

function (F::FeedbackControl{Autonomous, NonVariable})(x::State)::ctVector
    return F.f(x)
end

function (F::FeedbackControl{Autonomous, NonVariable})(t::Time, x::State, v::DecisionVariable)::ctVector
    return F.f(x)
end

function (F::FeedbackControl{Autonomous, Variable})(x::State, v::DecisionVariable)::ctVector
    return F.f(x, v)
end

function (F::FeedbackControl{Autonomous, Variable})(t::Time, x::State, v::DecisionVariable)::ctVector
    return F.f(x, v)
end

function (F::FeedbackControl{NonAutonomous, NonVariable})(t::Time, x::State)::ctVector
    return F.f(t, x)
end

function (F::FeedbackControl{NonAutonomous, NonVariable})(t::Time, x::State, v::DecisionVariable)::ctVector
    return F.f(t, x)
end

function (F::FeedbackControl{NonAutonomous, Variable})(t::Time, x::State, v::DecisionVariable)::ctVector
    return F.f(t, x, v)
end

# --------------------------------------------------------------------------------------------------
function ControlLaw(f::Function; 
    autonomous::Bool=true, variable::Bool=false)
    time_dependence = autonomous ? Autonomous : NonAutonomous
    variable_dependence = variable ? Variable : NonVariable
    return ControlLaw{time_dependence, variable_dependence}(f)
end

function ControlLaw(f::Function, dependences::DataType...)
    @__check(dependences)
    time_dependence = NonAutonomous ∈ dependences ? NonAutonomous : Autonomous
    variable_dependence = Variable ∈ dependences ? Variable : NonVariable
    return ControlLaw{time_dependence, variable_dependence}(f)
end

function (F::ControlLaw{Autonomous, NonVariable})(x::State, p::Costate)::ctVector
    return F.f(x, p)
end

function (F::ControlLaw{Autonomous, NonVariable})(t::Time, x::State, p::Costate, v::DecisionVariable)::ctVector
    return F.f(x, p)
end

function (F::ControlLaw{Autonomous, Variable})(x::State, p::Costate, v::DecisionVariable)::ctVector
    return F.f(x, p, v)
end

function (F::ControlLaw{Autonomous, Variable})(t::Time, x::State, p::Costate, v::DecisionVariable)::ctVector
    return F.f(x, p, v)
end

function (F::ControlLaw{NonAutonomous, NonVariable})(t::Time, x::State, p::Costate)::ctVector
    return F.f(t, x, p)
end

function (F::ControlLaw{NonAutonomous, NonVariable})(t::Time, x::State, p::Costate, v::DecisionVariable)::ctVector
    return F.f(t, x, p)
end

function (F::ControlLaw{NonAutonomous, Variable})(t::Time, x::State, p::Costate, v::DecisionVariable)::ctVector
    return F.f(t, x, p, v)
end

# --------------------------------------------------------------------------------------------------
function Multiplier(f::Function; 
    autonomous::Bool=true, variable::Bool=false)
    time_dependence = autonomous ? Autonomous : NonAutonomous
    variable_dependence = variable ? Variable : NonVariable
    return Multiplier{time_dependence, variable_dependence}(f)
end

function Multiplier(f::Function, dependences::DataType...)
    @__check(dependences)
    time_dependence = NonAutonomous ∈ dependences ? NonAutonomous : Autonomous
    variable_dependence = Variable ∈ dependences ? Variable : NonVariable
    return Multiplier{time_dependence, variable_dependence}(f)
end

function (F::Multiplier{Autonomous, NonVariable})(x::State, p::Costate)::ctVector
    return F.f(x, p)
end

function (F::Multiplier{Autonomous, NonVariable})(t::Time, x::State, p::Costate, v::DecisionVariable)::ctVector
    return F.f(x, p)
end

function (F::Multiplier{Autonomous, Variable})(x::State, p::Costate, v::DecisionVariable)::ctVector
    return F.f(x, p, v)
end

function (F::Multiplier{Autonomous, Variable})(t::Time, x::State, p::Costate, v::DecisionVariable)::ctVector
    return F.f(x, p, v)
end

function (F::Multiplier{NonAutonomous, NonVariable})(t::Time, x::State, p::Costate)::ctVector
    return F.f(t, x, p)
end

function (F::Multiplier{NonAutonomous, NonVariable})(t::Time, x::State, p::Costate, v::DecisionVariable)::ctVector
    return F.f(t, x, p)
end

function (F::Multiplier{NonAutonomous, Variable})(t::Time, x::State, p::Costate, v::DecisionVariable)::ctVector
    return F.f(t, x, p, v)
end
