# --------------------------------------------------------------------------------------------------
function BoundaryConstraint(f::Function; variable_dependence::DataType = __fun_variable_dependence())
    @__check(variable_dependence)
    return BoundaryConstraint{variable_dependence}(f)
end

function (F::BoundaryConstraint{NonVariable})(x0::State, xf::State)::ctVector
    return F.f(x0, xf)
end

function (F::BoundaryConstraint{NonVariable})(x0::State, xf::State, v::EmptyDecisionVariable)::ctVector
    return F.f(x0, xf)
end

function (F::BoundaryConstraint{Variable})(x0::State, xf::State, v::DecisionVariable)::ctVector
    return F.f(x0, xf, v)
end

# --------------------------------------------------------------------------------------------------
function Mayer(f::Function; variable_dependence::DataType = __fun_variable_dependence())
    @__check(variable_dependence)
    return Mayer{variable_dependence}(f)
end

function (F::Mayer{NonVariable})(x0::State, xf::State)::ctNumber
    return F.f(x0, xf)
end

function (F::Mayer{NonVariable})(x0::State, xf::State, v::EmptyDecisionVariable)::ctNumber
    return F.f(x0, xf)
end

function (F::Mayer{Variable})(x0::State, xf::State, v::DecisionVariable)::ctNumber
    return F.f(x0, xf, v)
end

# --------------------------------------------------------------------------------------------------
function Hamiltonian(f::Function; 
    time_dependence::DataType=__fun_time_dependence(),
    variable_dependence::DataType=__fun_variable_dependence())
    @__check(time_dependence)
    @__check(variable_dependence)
    return Hamiltonian{time_dependence, variable_dependence}(f)
end

function (F::Hamiltonian{Autonomous, NonVariable})(x::State, p::Costate)::ctNumber
    return F.f(x, p)
end

function (F::Hamiltonian{Autonomous, NonVariable})(t::Time, x::State, p::Costate, v::EmptyDecisionVariable)::ctNumber
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

function (F::Hamiltonian{NonAutonomous, NonVariable})(t::Time, x::State, p::Costate, v::EmptyDecisionVariable)::ctNumber
    return F.f(t, x, p)
end

function (F::Hamiltonian{NonAutonomous, Variable})(t::Time, x::State, p::Costate, v::DecisionVariable)::ctNumber
    return F.f(t, x, p, v)
end

# --------------------------------------------------------------------------------------------------
function HamiltonianVectorField(f::Function; 
    time_dependence::DataType=__fun_time_dependence(),
    variable_dependence::DataType=__fun_variable_dependence())
    @__check(time_dependence)
    @__check(variable_dependence)
    return HamiltonianVectorField{time_dependence, variable_dependence}(f)
end

function (F::HamiltonianVectorField{Autonomous, NonVariable})(x::State, p::Costate)::ctVector
    return F.f(x, p)
end

function (F::HamiltonianVectorField{Autonomous, NonVariable})(t::Time, x::State, p::Costate, v::EmptyDecisionVariable)::ctVector
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

function (F::HamiltonianVectorField{NonAutonomous, NonVariable})(t::Time, x::State, p::Costate, v::EmptyDecisionVariable)::ctVector
    return F.f(t, x, p)
end

function (F::HamiltonianVectorField{NonAutonomous, Variable})(t::Time, x::State, p::Costate, v::DecisionVariable)::ctVector
    return F.f(t, x, p, v)
end

# --------------------------------------------------------------------------------------------------
function VectorField(f::Function; 
    time_dependence::DataType=__fun_time_dependence(),
    variable_dependence::DataType=__fun_variable_dependence())
    @__check(time_dependence)
    @__check(variable_dependence)
    return VectorField{time_dependence, variable_dependence}(f)
end

function (F::VectorField{Autonomous, NonVariable})(x::State)::ctVector
    return F.f(x)
end

function (F::VectorField{Autonomous, NonVariable})(t::Time, x::State, v::EmptyDecisionVariable)::ctVector
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

function (F::VectorField{NonAutonomous, NonVariable})(t::Time, x::State, v::EmptyDecisionVariable)::ctVector
    return F.f(t, x)
end

function (F::VectorField{NonAutonomous, Variable})(t::Time, x::State, v::DecisionVariable)::ctVector
    return F.f(t, x, v)
end

# --------------------------------------------------------------------------------------------------
function Lagrange(f::Function; 
    time_dependence::DataType=__fun_time_dependence(),
    variable_dependence::DataType=__fun_variable_dependence())
    @__check(time_dependence)
    @__check(variable_dependence)
    return Lagrange{time_dependence, variable_dependence}(f)
end

function (F::Lagrange{Autonomous, NonVariable})(x::State, u::Control)::ctNumber
    return F.f(x, u)
end

function (F::Lagrange{Autonomous, NonVariable})(t::Time, x::State, u::Control, v::EmptyDecisionVariable)::ctNumber
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

function (F::Lagrange{NonAutonomous, NonVariable})(t::Time, x::State, u::Control, v::EmptyDecisionVariable)::ctNumber
    return F.f(t, x, u)
end

function (F::Lagrange{NonAutonomous, Variable})(t::Time, x::State, u::Control, v::DecisionVariable)::ctNumber
    return F.f(t, x, u, v)
end

# --------------------------------------------------------------------------------------------------
function Dynamics(f::Function; 
    time_dependence::DataType=__fun_time_dependence(),
    variable_dependence::DataType=__fun_variable_dependence())
    @__check(time_dependence)
    @__check(variable_dependence)
    return Dynamics{time_dependence, variable_dependence}(f)
end

function (F::Dynamics{Autonomous, NonVariable})(x::State, u::Control)::ctVector
    return F.f(x, u)
end

function (F::Dynamics{Autonomous, NonVariable})(t::Time, x::State, u::Control, v::EmptyDecisionVariable)::ctVector
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

function (F::Dynamics{NonAutonomous, NonVariable})(t::Time, x::State, u::Control, v::EmptyDecisionVariable)::ctVector
    return F.f(t, x, u)
end

function (F::Dynamics{NonAutonomous, Variable})(t::Time, x::State, u::Control, v::DecisionVariable)::ctVector
    return F.f(t, x, u, v)
end

# --------------------------------------------------------------------------------------------------
function StateConstraint(f::Function; 
    time_dependence::DataType=__fun_time_dependence(),
    variable_dependence::DataType=__fun_variable_dependence())
    @__check(time_dependence)
    @__check(variable_dependence)
    return StateConstraint{time_dependence, variable_dependence}(f)
end

function (F::StateConstraint{Autonomous, NonVariable})(x::State)::ctVector
    return F.f(x)
end

function (F::StateConstraint{Autonomous, NonVariable})(t::Time, x::State, v::EmptyDecisionVariable)::ctVector
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

function (F::StateConstraint{NonAutonomous, NonVariable})(t::Time, x::State, v::EmptyDecisionVariable)::ctVector
    return F.f(t, x)
end

function (F::StateConstraint{NonAutonomous, Variable})(t::Time, x::State, v::DecisionVariable)::ctVector
    return F.f(t, x, v)
end

# --------------------------------------------------------------------------------------------------
function ControlConstraint(f::Function; 
    time_dependence::DataType=__fun_time_dependence(),
    variable_dependence::DataType=__fun_variable_dependence())
    @__check(time_dependence)
    @__check(variable_dependence)
    return ControlConstraint{time_dependence, variable_dependence}(f)
end

function (F::ControlConstraint{Autonomous, NonVariable})(u::Control)::ctVector
    return F.f(u)
end

function (F::ControlConstraint{Autonomous, NonVariable})(t::Time, u::Control, v::EmptyDecisionVariable)::ctVector
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

function (F::ControlConstraint{NonAutonomous, NonVariable})(t::Time, u::Control, v::EmptyDecisionVariable)::ctVector
    return F.f(t, u)
end

function (F::ControlConstraint{NonAutonomous, Variable})(t::Time, u::Control, v::DecisionVariable)::ctVector
    return F.f(t, u, v)
end

# --------------------------------------------------------------------------------------------------
function MixedConstraint(f::Function; 
    time_dependence::DataType=__fun_time_dependence(),
    variable_dependence::DataType=__fun_variable_dependence())
    @__check(time_dependence)
    @__check(variable_dependence)
    return MixedConstraint{time_dependence, variable_dependence}(f)
end

function (F::MixedConstraint{Autonomous, NonVariable})(x::State, u::Control)::ctVector
    return F.f(x, u)
end

function (F::MixedConstraint{Autonomous, NonVariable})(t::Time, x::State, u::Control, v::EmptyDecisionVariable)::ctVector
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

function (F::MixedConstraint{NonAutonomous, NonVariable})(t::Time, x::State, u::Control, v::EmptyDecisionVariable)::ctVector
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
    time_dependence::DataType=__fun_time_dependence(),
    variable_dependence::DataType=__fun_variable_dependence())
    @__check(time_dependence)
    @__check(variable_dependence)
    return FeedbackControl{time_dependence, variable_dependence}(f)
end

function (F::FeedbackControl{Autonomous, NonVariable})(x::State)::ctVector
    return F.f(x)
end

function (F::FeedbackControl{Autonomous, NonVariable})(t::Time, x::State, v::EmptyDecisionVariable)::ctVector
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

function (F::FeedbackControl{NonAutonomous, NonVariable})(t::Time, x::State, v::EmptyDecisionVariable)::ctVector
    return F.f(t, x)
end

function (F::FeedbackControl{NonAutonomous, Variable})(t::Time, x::State, v::DecisionVariable)::ctVector
    return F.f(t, x, v)
end

# --------------------------------------------------------------------------------------------------
function ControlLaw(f::Function; 
    time_dependence::DataType=__fun_time_dependence(),
    variable_dependence::DataType=__fun_variable_dependence())
    @__check(time_dependence)
    @__check(variable_dependence)
    return ControlLaw{time_dependence, variable_dependence}(f)
end

function (F::ControlLaw{Autonomous, NonVariable})(x::State, p::Costate)::ctVector
    return F.f(x, p)
end

function (F::ControlLaw{Autonomous, NonVariable})(t::Time, x::State, p::Costate, v::EmptyDecisionVariable)::ctVector
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

function (F::ControlLaw{NonAutonomous, NonVariable})(t::Time, x::State, p::Costate, v::EmptyDecisionVariable)::ctVector
    return F.f(t, x, p)
end

function (F::ControlLaw{NonAutonomous, Variable})(t::Time, x::State, p::Costate, v::DecisionVariable)::ctVector
    return F.f(t, x, p, v)
end

# --------------------------------------------------------------------------------------------------
function Multiplier(f::Function; 
    time_dependence::DataType=__fun_time_dependence(),
    variable_dependence::DataType=__fun_variable_dependence())
    @__check(time_dependence)
    @__check(variable_dependence)
    return Multiplier{time_dependence, variable_dependence}(f)
end

function (F::Multiplier{Autonomous, NonVariable})(x::State, p::Costate)::ctVector
    return F.f(x, p)
end

function (F::Multiplier{Autonomous, NonVariable})(t::Time, x::State, p::Costate, v::EmptyDecisionVariable)::ctVector
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

function (F::Multiplier{NonAutonomous, NonVariable})(t::Time, x::State, p::Costate, v::EmptyDecisionVariable)::ctVector
    return F.f(t, x, p)
end

function (F::Multiplier{NonAutonomous, Variable})(t::Time, x::State, p::Costate, v::DecisionVariable)::ctVector
    return F.f(t, x, p, v)
end
