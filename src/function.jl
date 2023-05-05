# --------------------------------------------------------------------------------------------------
function BoundaryConstraint(f::Function; variable_dependence::Symbol=__fun_variable_dependence())
    @check(variable_dependence)
    return BoundaryConstraint{variable_dependence}(f)
end

function (F::BoundaryConstraint{:v_indep})(x0::State, xf::State)::ctVector
    return F.f(x0, xf)
end

function (F::BoundaryConstraint{:v_indep})(x0::State, xf::State, v::EmptyVariable)::ctVector
    return F.f(x0, xf)
end

function (F::BoundaryConstraint{:v_dep})(x0::State, xf::State, v::Variable)::ctVector
    return F.f(x0, xf, v)
end

# --------------------------------------------------------------------------------------------------
function Mayer(f::Function; variable_dependence::Symbol=__fun_variable_dependence())
    @check(variable_dependence)
    return Mayer{variable_dependence}(f)
end

function (F::Mayer{:v_indep})(x0::State, xf::State)::ctNumber
    return F.f(x0, xf)
end

function (F::Mayer{:v_indep})(x0::State, xf::State, v::EmptyVariable)::ctNumber
    return F.f(x0, xf)
end

function (F::Mayer{:v_dep})(x0::State, xf::State, v::Variable)::ctNumber
    return F.f(x0, xf, v)
end

# --------------------------------------------------------------------------------------------------
function Hamiltonian(f::Function; 
    time_dependence::Symbol=__fun_time_dependence(),
    variable_dependence::Symbol=__fun_variable_dependence())
    @check(time_dependence)
    @check(variable_dependence)
    return Hamiltonian{time_dependence, variable_dependence}(f)
end

function (F::Hamiltonian{:t_indep, :v_indep})(x::State, p::Costate)::ctNumber
    return F.f(x, p)
end

function (F::Hamiltonian{:t_indep, :v_indep})(t::Time, x::State, p::Costate, v::EmptyVariable)::ctNumber
    return F.f(x, p)
end

function (F::Hamiltonian{:t_indep, :v_dep})(x::State, p::Costate, v::Variable)::ctNumber
    return F.f(x, p, v)
end

function (F::Hamiltonian{:t_indep, :v_dep})(t::Time, x::State, p::Costate, v::Variable)::ctNumber
    return F.f(x, p, v)
end

function (F::Hamiltonian{:t_dep, :v_indep})(t::Time, x::State, p::Costate)::ctNumber
    return F.f(t, x, p)
end

function (F::Hamiltonian{:t_dep, :v_indep})(t::Time, x::State, p::Costate, v::EmptyVariable)::ctNumber
    return F.f(t, x, p)
end

function (F::Hamiltonian{:t_dep, :v_dep})(t::Time, x::State, p::Costate, v::Variable)::ctNumber
    return F.f(t, x, p, v)
end

# --------------------------------------------------------------------------------------------------
function HamiltonianVectorField(f::Function; 
    time_dependence::Symbol=__fun_time_dependence(),
    variable_dependence::Symbol=__fun_variable_dependence())
    @check(time_dependence)
    @check(variable_dependence)
    return HamiltonianVectorField{time_dependence, variable_dependence}(f)
end

function (F::HamiltonianVectorField{:t_indep, :v_indep})(x::State, p::Costate)::ctVector
    return F.f(x, p)
end

function (F::HamiltonianVectorField{:t_indep, :v_indep})(t::Time, x::State, p::Costate, v::EmptyVariable)::ctVector
    return F.f(x, p)
end

function (F::HamiltonianVectorField{:t_indep, :v_dep})(x::State, p::Costate, v::Variable)::ctVector
    return F.f(x, p, v)
end

function (F::HamiltonianVectorField{:t_indep, :v_dep})(t::Time, x::State, p::Costate, v::Variable)::ctVector
    return F.f(x, p, v)
end

function (F::HamiltonianVectorField{:t_dep, :v_indep})(t::Time, x::State, p::Costate)::ctVector
    return F.f(t, x, p)
end

function (F::HamiltonianVectorField{:t_dep, :v_indep})(t::Time, x::State, p::Costate, v::EmptyVariable)::ctVector
    return F.f(t, x, p)
end

function (F::HamiltonianVectorField{:t_dep, :v_dep})(t::Time, x::State, p::Costate, v::Variable)::ctVector
    return F.f(t, x, p, v)
end

# --------------------------------------------------------------------------------------------------
function VectorField(f::Function; 
    time_dependence::Symbol=__fun_time_dependence(),
    variable_dependence::Symbol=__fun_variable_dependence())
    @check(time_dependence)
    @check(variable_dependence)
    return VectorField{time_dependence, variable_dependence}(f)
end

function (F::VectorField{:t_indep, :v_indep})(x::State)::ctVector
    return F.f(x)
end

function (F::VectorField{:t_indep, :v_indep})(t::Time, x::State, v::EmptyVariable)::ctVector
    return F.f(x)
end

function (F::VectorField{:t_indep, :v_dep})(x::State, v::Variable)::ctVector
    return F.f(x, v)
end

function (F::VectorField{:t_indep, :v_dep})(t::Time, x::State, v::Variable)::ctVector
    return F.f(x, v)
end

function (F::VectorField{:t_dep, :v_indep})(t::Time, x::State)::ctVector
    return F.f(t, x)
end

function (F::VectorField{:t_dep, :v_indep})(t::Time, x::State, v::EmptyVariable)::ctVector
    return F.f(t, x)
end

function (F::VectorField{:t_dep, :v_dep})(t::Time, x::State, v::Variable)::ctVector
    return F.f(t, x, v)
end

# --------------------------------------------------------------------------------------------------
function Lagrange(f::Function; 
    time_dependence::Symbol=__fun_time_dependence(),
    variable_dependence::Symbol=__fun_variable_dependence())
    @check(time_dependence)
    @check(variable_dependence)
    return Lagrange{time_dependence, variable_dependence}(f)
end

function (F::Lagrange{:t_indep, :v_indep})(x::State, u::Control)::ctNumber
    return F.f(x, u)
end

function (F::Lagrange{:t_indep, :v_indep})(t::Time, x::State, u::Control, v::EmptyVariable)::ctNumber
    return F.f(x, u)
end

function (F::Lagrange{:t_indep, :v_dep})(x::State, u::Control, v::Variable)::ctNumber
    return F.f(x, u, v)
end

function (F::Lagrange{:t_indep, :v_dep})(t::Time, x::State, u::Control, v::Variable)::ctNumber
    return F.f(x, u, v)
end

function (F::Lagrange{:t_dep, :v_indep})(t::Time, x::State, u::Control)::ctNumber
    return F.f(t, x, u)
end

function (F::Lagrange{:t_dep, :v_indep})(t::Time, x::State, u::Control, v::EmptyVariable)::ctNumber
    return F.f(t, x, u)
end

function (F::Lagrange{:t_dep, :v_dep})(t::Time, x::State, u::Control, v::Variable)::ctNumber
    return F.f(t, x, u, v)
end

# --------------------------------------------------------------------------------------------------
function Dynamics(f::Function; 
    time_dependence::Symbol=__fun_time_dependence(),
    variable_dependence::Symbol=__fun_variable_dependence())
    @check(time_dependence)
    @check(variable_dependence)
    return Dynamics{time_dependence, variable_dependence}(f)
end

function (F::Dynamics{:t_indep, :v_indep})(x::State, u::Control)::ctVector
    return F.f(x, u)
end

function (F::Dynamics{:t_indep, :v_indep})(t::Time, x::State, u::Control, v::EmptyVariable)::ctVector
    return F.f(x, u)
end

function (F::Dynamics{:t_indep, :v_dep})(x::State, u::Control, v::Variable)::ctVector
    return F.f(x, u, v)
end

function (F::Dynamics{:t_indep, :v_dep})(t::Time, x::State, u::Control, v::Variable)::ctVector
    return F.f(x, u, v)
end

function (F::Dynamics{:t_dep, :v_indep})(t::Time, x::State, u::Control)::ctVector
    return F.f(t, x, u)
end

function (F::Dynamics{:t_dep, :v_indep})(t::Time, x::State, u::Control, v::EmptyVariable)::ctVector
    return F.f(t, x, u)
end

function (F::Dynamics{:t_dep, :v_dep})(t::Time, x::State, u::Control, v::Variable)::ctVector
    return F.f(t, x, u, v)
end

# --------------------------------------------------------------------------------------------------
function StateConstraint(f::Function; 
    time_dependence::Union{Nothing,Symbol}=__fun_time_dependence(),
    variable_dependence::Union{Nothing,Symbol}=__fun_variable_dependence())
    @check(time_dependence)
    @check(variable_dependence)
    return StateConstraint{time_dependence, variable_dependence}(f)
end

function (F::StateConstraint{:t_indep, :v_indep})(x::State)::ctVector
    return F.f(x)
end

function (F::StateConstraint{:t_indep, :v_indep})(t::Time, x::State, v::EmptyVariable)::ctVector
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

function (F::StateConstraint{:t_dep, :v_indep})(t::Time, x::State, v::EmptyVariable)::ctVector
    return F.f(t, x)
end

function (F::StateConstraint{:t_dep, :v_dep})(t::Time, x::State, v::Variable)::ctVector
    return F.f(t, x, v)
end

# --------------------------------------------------------------------------------------------------
function ControlConstraint(f::Function; 
    time_dependence::Union{Nothing,Symbol}=__fun_time_dependence(),
    variable_dependence::Union{Nothing,Symbol}=__fun_variable_dependence())
    @check(time_dependence)
    @check(variable_dependence)
    return ControlConstraint{time_dependence, variable_dependence}(f)
end

function (F::ControlConstraint{:t_indep, :v_indep})(u::Control)::ctVector
    return F.f(u)
end

function (F::ControlConstraint{:t_indep, :v_indep})(t::Time, u::Control, v::EmptyVariable)::ctVector
    return F.f(u)
end

function (F::ControlConstraint{:t_indep, :v_dep})(u::Control, v::Variable)::ctVector
    return F.f(u, v)
end

function (F::ControlConstraint{:t_indep, :v_dep})(t::Time, u::Control, v::Variable)::ctVector
    return F.f(u, v)
end

function (F::ControlConstraint{:t_dep, :v_indep})(t::Time, u::Control)::ctVector
    return F.f(t, u)
end

function (F::ControlConstraint{:t_dep, :v_indep})(t::Time, u::Control, v::EmptyVariable)::ctVector
    return F.f(t, u)
end

function (F::ControlConstraint{:t_dep, :v_dep})(t::Time, u::Control, v::Variable)::ctVector
    return F.f(t, u, v)
end

# --------------------------------------------------------------------------------------------------
function MixedConstraint(f::Function; 
    time_dependence::Union{Nothing,Symbol}=__fun_time_dependence(),
    variable_dependence::Union{Nothing,Symbol}=__fun_variable_dependence())
    @check(time_dependence)
    @check(variable_dependence)
    return MixedConstraint{time_dependence, variable_dependence}(f)
end

function (F::MixedConstraint{:t_indep, :v_indep})(x::State, u::Control)::ctVector
    return F.f(x, u)
end

function (F::MixedConstraint{:t_indep, :v_indep})(t::Time, x::State, u::Control, v::EmptyVariable)::ctVector
    return F.f(x, u)
end

function (F::MixedConstraint{:t_indep, :v_dep})(x::State, u::Control, v::Variable)::ctVector
    return F.f(x, u, v)
end

function (F::MixedConstraint{:t_indep, :v_dep})(t::Time, x::State, u::Control, v::Variable)::ctVector
    return F.f(x, u, v)
end

function (F::MixedConstraint{:t_dep, :v_indep})(t::Time, x::State, u::Control)::ctVector
    return F.f(t, x, u)
end

function (F::MixedConstraint{:t_dep, :v_indep})(t::Time, x::State, u::Control, v::EmptyVariable)::ctVector
    return F.f(t, x, u)
end

function (F::MixedConstraint{:t_dep, :v_dep})(t::Time, x::State, u::Control, v::Variable)::ctVector
    return F.f(t, x, u, v)
end

# --------------------------------------------------------------------------------------------------
function (F::VariableConstraint)(v::Variable)::ctVector
    return F.f(v)
end

# --------------------------------------------------------------------------------------------------
function FeedbackControl(f::Function; 
    time_dependence::Union{Nothing,Symbol}=__fun_time_dependence(),
    variable_dependence::Union{Nothing,Symbol}=__fun_variable_dependence())
    @check(time_dependence)
    @check(variable_dependence)
    return FeedbackControl{time_dependence, variable_dependence}(f)
end

function (F::FeedbackControl{:t_indep, :v_indep})(x::State)::ctVector
    return F.f(x)
end

function (F::FeedbackControl{:t_indep, :v_indep})(t::Time, x::State, v::EmptyVariable)::ctVector
    return F.f(x)
end

function (F::FeedbackControl{:t_indep, :v_dep})(x::State, v::Variable)::ctVector
    return F.f(x, v)
end

function (F::FeedbackControl{:t_indep, :v_dep})(t::Time, x::State, v::Variable)::ctVector
    return F.f(x, v)
end

function (F::FeedbackControl{:t_dep, :v_indep})(t::Time, x::State)::ctVector
    return F.f(t, x)
end

function (F::FeedbackControl{:t_dep, :v_indep})(t::Time, x::State, v::EmptyVariable)::ctVector
    return F.f(t, x)
end

function (F::FeedbackControl{:t_dep, :v_dep})(t::Time, x::State, v::Variable)::ctVector
    return F.f(t, x, v)
end

# --------------------------------------------------------------------------------------------------
function ControlLaw(f::Function; 
    time_dependence::Union{Nothing,Symbol}=__fun_time_dependence(),
    variable_dependence::Union{Nothing,Symbol}=__fun_variable_dependence())
    @check(time_dependence)
    @check(variable_dependence)
    return ControlLaw{time_dependence, variable_dependence}(f)
end

function (F::ControlLaw{:t_indep, :v_indep})(x::State, p::Costate)::ctVector
    return F.f(x, p)
end

function (F::ControlLaw{:t_indep, :v_indep})(t::Time, x::State, p::Costate, v::EmptyVariable)::ctVector
    return F.f(x, p)
end

function (F::ControlLaw{:t_indep, :v_dep})(x::State, p::Costate, v::Variable)::ctVector
    return F.f(x, p, v)
end

function (F::ControlLaw{:t_indep, :v_dep})(t::Time, x::State, p::Costate, v::Variable)::ctVector
    return F.f(x, p, v)
end

function (F::ControlLaw{:t_dep, :v_indep})(t::Time, x::State, p::Costate)::ctVector
    return F.f(t, x, p)
end

function (F::ControlLaw{:t_dep, :v_indep})(t::Time, x::State, p::Costate, v::EmptyVariable)::ctVector
    return F.f(t, x, p)
end

function (F::ControlLaw{:t_dep, :v_dep})(t::Time, x::State, p::Costate, v::Variable)::ctVector
    return F.f(t, x, p, v)
end

# --------------------------------------------------------------------------------------------------
function Multiplier(f::Function; 
    time_dependence::Union{Nothing,Symbol}=__fun_time_dependence(),
    variable_dependence::Union{Nothing,Symbol}=__fun_variable_dependence())
    @check(time_dependence)
    @check(variable_dependence)
    return Multiplier{time_dependence, variable_dependence}(f)
end

function (F::Multiplier{:t_indep, :v_indep})(x::State, p::Costate)::ctVector
    return F.f(x, p)
end

function (F::Multiplier{:t_indep, :v_indep})(t::Time, x::State, p::Costate, v::EmptyVariable)::ctVector
    return F.f(x, p)
end

function (F::Multiplier{:t_indep, :v_dep})(x::State, p::Costate, v::Variable)::ctVector
    return F.f(x, p, v)
end

function (F::Multiplier{:t_indep, :v_dep})(t::Time, x::State, p::Costate, v::Variable)::ctVector
    return F.f(x, p, v)
end

function (F::Multiplier{:t_dep, :v_indep})(t::Time, x::State, p::Costate)::ctVector
    return F.f(t, x, p)
end

function (F::Multiplier{:t_dep, :v_indep})(t::Time, x::State, p::Costate, v::EmptyVariable)::ctVector
    return F.f(t, x, p)
end

function (F::Multiplier{:t_dep, :v_dep})(t::Time, x::State, p::Costate, v::Variable)::ctVector
    return F.f(t, x, p, v)
end
