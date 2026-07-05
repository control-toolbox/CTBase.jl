module TestComposedHamiltonian

using Test: Test
import CTBase.Data: Data
import CTBase.Traits: Traits

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

function test_composed_hamiltonian()
    Test.@testset "ComposedHamiltonian Tests" verbose=VERBOSE showtiming=SHOWTIMING begin

        # ====================================================================
        # UNIT — composition value + natural/uniform calls
        # ====================================================================

        Test.@testset "Unit: composition value (Auton/Fixed)" begin
            # H̃(x,p,u) = p*(-x+u) + 0.5u² ; law u(x,p) = -p
            # ⇒ H(x,p) = p*(-x-p) + 0.5p² = -px - 0.5p²
            h̃ = Data.PseudoHamiltonian((x, p, u) -> p * (-x + u) + 0.5 * u^2)
            law = Data.DynClosedLoop((x, p) -> -p)
            H = Data.ComposedHamiltonian(h̃, law)

            expected = -3.0 * 2.0 - 0.5 * 3.0^2   # x=2, p=3
            Test.@test H(2.0, 3.0) ≈ expected atol = 1e-12                 # natural (x,p)
            Test.@test H(0.0, 2.0, 3.0, nothing) ≈ expected atol = 1e-12   # uniform (t,x,p,v)
        end

        Test.@testset "Unit: natural call NonAutonomous/NonFixed" begin
            # H̃(t,x,p,u,v) = t*p*u + v ; law u(t,x,p,v) = -p ⇒ H(t,x,p,v) = -t*p² + v
            h̃ = Data.PseudoHamiltonian(
                (t, x, p, u, v) -> t * p * u + v; is_autonomous=false, is_variable=true
            )
            law = Data.DynClosedLoop(
                (t, x, p, v) -> -p; is_autonomous=false, is_variable=true
            )
            H = Data.ComposedHamiltonian(h̃, law)
            Test.@test H(2.0, 1.0, 3.0, 5.0) ≈ -2.0 * 3.0^2 + 5.0 atol = 1e-12
        end

        Test.@testset "Unit: getters pseudo_hamiltonian / control_law" begin
            h̃ = Data.PseudoHamiltonian((x, p, u) -> p * u)
            law = Data.DynClosedLoop((x, p) -> -p)
            H = Data.ComposedHamiltonian(h̃, law)
            Test.@test Data.pseudo_hamiltonian(H) === h̃
            Test.@test Data.control_law(H) === law
        end

        Test.@testset "Unit: Base.show" begin
            h̃ = Data.PseudoHamiltonian((x, p, u) -> p * u)
            law = Data.DynClosedLoop((x, p) -> -p)
            H = Data.ComposedHamiltonian(h̃, law)
            Test.@test occursin("ComposedHamiltonian", sprint(show, H))
        end

        # ====================================================================
        # UNIT — trait joins (NonAutonomous / NonFixed win)
        # ====================================================================

        Test.@testset "Unit: trait join — both autonomous/fixed ⇒ Autonomous/Fixed" begin
            H = Data.ComposedHamiltonian(
                Data.PseudoHamiltonian((x, p, u) -> p * u), Data.DynClosedLoop((x, p) -> -p)
            )
            Test.@test Traits.time_dependence(H) === Traits.Autonomous
            Test.@test Traits.variable_dependence(H) === Traits.Fixed
        end

        Test.@testset "Unit: trait join — autonomous h̃ + time-varying law ⇒ NonAutonomous" begin
            h̃ = Data.PseudoHamiltonian((x, p, u) -> p * u)                    # Autonomous
            law = Data.DynClosedLoop((t, x, p) -> -p * t; is_autonomous=false) # NonAutonomous
            H = Data.ComposedHamiltonian(h̃, law)
            Test.@test Traits.time_dependence(H) === Traits.NonAutonomous
            Test.@test Traits.variable_dependence(H) === Traits.Fixed
        end

        Test.@testset "Unit: trait join — fixed h̃ + variable law ⇒ NonFixed" begin
            h̃ = Data.PseudoHamiltonian((x, p, u) -> p * u)                     # Fixed
            law = Data.DynClosedLoop((x, p, v) -> -p + v; is_variable=true)     # NonFixed
            H = Data.ComposedHamiltonian(h̃, law)
            Test.@test Traits.time_dependence(H) === Traits.Autonomous
            Test.@test Traits.variable_dependence(H) === Traits.NonFixed
            # H(x,p,v) = h̃(x,p,-p+v) = p*(-p+v)
            Test.@test H(2.0, 3.0, 5.0) ≈ 3.0 * (-3.0 + 5.0) atol = 1e-12
        end

        # ====================================================================
        # CONTRACT — honours the AbstractHamiltonian interface (LSP)
        # ====================================================================

        Test.@testset "Contract: is an AbstractHamiltonian with Hamiltonian dynamics" begin
            H = Data.ComposedHamiltonian(
                Data.PseudoHamiltonian((x, p, u) -> p * u), Data.DynClosedLoop((x, p) -> -p)
            )
            Test.@test H isa Data.ComposedHamiltonian
            Test.@test H isa Data.AbstractHamiltonian
            Test.@test Traits.dynamics_trait(H) === Traits.HamiltonianDynamics
            Test.@test Traits.has_time_dependence_trait(H) === true
            Test.@test Traits.has_variable_dependence_trait(H) === true
        end

        Test.@testset "Contract: uniform (t,x,p,v) call available for every law-trait combo" begin
            # H̃(t,x,p,u,v) = p*u ; each law returns -p but with a different natural arity.
            h̃ = Data.PseudoHamiltonian(
                (t, x, p, u, v) -> p * u; is_autonomous=false, is_variable=true
            )
            laws = (
                Data.DynClosedLoop((x, p) -> -p),                                       # Auton/Fixed
                Data.DynClosedLoop((t, x, p) -> -p; is_autonomous=false),               # NonAuton/Fixed
                Data.DynClosedLoop((x, p, v) -> -p; is_variable=true),                  # Auton/NonFixed
                Data.DynClosedLoop(
                    (t, x, p, v) -> -p; is_autonomous=false, is_variable=true
                ), # NonAuton/NonFixed
            )
            for law in laws
                H = Data.ComposedHamiltonian(h̃, law)
                Test.@test H(0.0, 2.0, 3.0, 4.0) ≈ 3.0 * (-3.0) atol = 1e-12  # uniform call
            end
        end

        # ====================================================================
        # UNIT — type stability of the hot-path call
        # ====================================================================

        Test.@testset "Unit: functor call is type-stable" begin
            H = Data.ComposedHamiltonian(
                Data.PseudoHamiltonian((x, p, u) -> p * (-x + u) + 0.5 * u^2),
                Data.DynClosedLoop((x, p) -> -p),
            )
            Test.@test_nowarn Test.@inferred H(2.0, 3.0)
        end

        # ====================================================================
        # ERROR — constructor rejects a non-DynClosedLoop control law
        # ====================================================================

        Test.@testset "Error: OpenLoop / ClosedLoop laws are rejected" begin
            h̃ = Data.PseudoHamiltonian((x, p, u) -> p * u)
            Test.@test_throws MethodError Data.ComposedHamiltonian(
                h̃, Data.OpenLoop(() -> 1.0)
            )
            Test.@test_throws MethodError Data.ComposedHamiltonian(
                h̃, Data.ClosedLoop(x -> -x)
            )
        end
    end
end

end # module TestComposedHamiltonian

test_composed_hamiltonian() = TestComposedHamiltonian.test_composed_hamiltonian()
