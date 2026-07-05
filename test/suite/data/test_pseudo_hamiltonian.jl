module TestPseudoHamiltonian

using Test: Test
import CTBase.Data: Data, PseudoHamiltonian
import CTBase.Traits

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

function test_pseudo_hamiltonian()
    Test.@testset "PseudoHamiltonian Tests" verbose=VERBOSE showtiming=SHOWTIMING begin

        # ====================================================================
        # UNIT TESTS - Construction with all trait combinations
        # ====================================================================

        Test.@testset "Unit: Construction with all trait combinations" begin
            # Autonomous, Fixed
            ph1 = PseudoHamiltonian((x, p, u) -> sum(x .* p) + u^2)
            Test.@test ph1 isa Data.PseudoHamiltonian
            Test.@test Traits.time_dependence(ph1) == Traits.Autonomous
            Test.@test Traits.variable_dependence(ph1) == Traits.Fixed

            # NonAutonomous, Fixed
            ph2 = PseudoHamiltonian(
                (t, x, p, u) -> t * sum(x .* p) + u^2; is_autonomous=false
            )
            Test.@test ph2 isa Data.PseudoHamiltonian
            Test.@test Traits.time_dependence(ph2) == Traits.NonAutonomous
            Test.@test Traits.variable_dependence(ph2) == Traits.Fixed

            # Autonomous, NonFixed
            ph3 = PseudoHamiltonian((x, p, u, v) -> sum(x .* p) + u^2 + v; is_variable=true)
            Test.@test ph3 isa Data.PseudoHamiltonian
            Test.@test Traits.time_dependence(ph3) == Traits.Autonomous
            Test.@test Traits.variable_dependence(ph3) == Traits.NonFixed

            # NonAutonomous, NonFixed
            ph4 = PseudoHamiltonian(
                (t, x, p, u, v) -> t * sum(x .* p) + u^2 + v;
                is_autonomous=false,
                is_variable=true,
            )
            Test.@test ph4 isa Data.PseudoHamiltonian
            Test.@test Traits.time_dependence(ph4) == Traits.NonAutonomous
            Test.@test Traits.variable_dependence(ph4) == Traits.NonFixed
        end

        # ====================================================================
        # UNIT TESTS - Natural call signatures
        # ====================================================================

        Test.@testset "Unit: Natural call signatures" begin
            # Autonomous, Fixed: h̃(x, p, u)
            ph1 = PseudoHamiltonian((x, p, u) -> sum(x .* p) + u^2)
            Test.@test ph1([1.0, 2.0], [3.0, 4.0], 5.0) == 3.0 + 8.0 + 25.0

            # NonAutonomous, Fixed: h̃(t, x, p, u)
            ph2 = PseudoHamiltonian(
                (t, x, p, u) -> t + sum(x .* p) + u^2; is_autonomous=false
            )
            Test.@test ph2(1.0, [2.0, 3.0], [4.0, 5.0], 6.0) == 1.0 + 8.0 + 15.0 + 36.0

            # Autonomous, NonFixed: h̃(x, p, u, v)
            ph3 = PseudoHamiltonian((x, p, u, v) -> sum(x .* p) + u^2 + v; is_variable=true)
            Test.@test ph3([1.0, 2.0], [3.0, 4.0], 5.0, 6.0) == 3.0 + 8.0 + 25.0 + 6.0

            # NonAutonomous, NonFixed: h̃(t, x, p, u, v)
            ph4 = PseudoHamiltonian(
                (t, x, p, u, v) -> t + sum(x .* p) + u^2 + v;
                is_autonomous=false,
                is_variable=true,
            )
            Test.@test ph4(1.0, [2.0, 3.0], [4.0, 5.0], 6.0, 7.0) ==
                1.0 + 8.0 + 15.0 + 36.0 + 7.0
        end

        # ====================================================================
        # UNIT TESTS - Uniform call signature
        # ====================================================================

        Test.@testset "Unit: Uniform call signature (t, x, p, u, v)" begin
            # Autonomous, Fixed — ignores t, v
            ph1 = PseudoHamiltonian((x, p, u) -> sum(x .* p) + u^2)
            Test.@test ph1(0.0, [1.0, 2.0], [3.0, 4.0], 5.0, 6.0) == 3.0 + 8.0 + 25.0

            # NonAutonomous, Fixed — ignores v
            ph2 = PseudoHamiltonian(
                (t, x, p, u) -> t + sum(x .* p) + u^2; is_autonomous=false
            )
            Test.@test ph2(1.0, [2.0, 3.0], [4.0, 5.0], 6.0, 7.0) == 1.0 + 8.0 + 15.0 + 36.0

            # Autonomous, NonFixed — ignores t
            ph3 = PseudoHamiltonian((x, p, u, v) -> sum(x .* p) + u^2 + v; is_variable=true)
            Test.@test ph3(0.0, [1.0, 2.0], [3.0, 4.0], 5.0, 6.0) == 3.0 + 8.0 + 25.0 + 6.0

            # NonAutonomous, NonFixed — uses all
            ph4 = PseudoHamiltonian(
                (t, x, p, u, v) -> t + sum(x .* p) + u^2 + v;
                is_autonomous=false,
                is_variable=true,
            )
            Test.@test ph4(1.0, [2.0, 3.0], [4.0, 5.0], 6.0, 7.0) ==
                1.0 + 8.0 + 15.0 + 36.0 + 7.0
        end

        # ====================================================================
        # UNIT TESTS - Typed constructor
        # ====================================================================

        Test.@testset "Unit: Typed constructor" begin
            ph = PseudoHamiltonian(
                (x, p, u) -> sum(x .* p) + u^2, Traits.Autonomous, Traits.Fixed
            )
            Test.@test ph isa Data.PseudoHamiltonian
            Test.@test Traits.time_dependence(ph) === Traits.Autonomous
            Test.@test Traits.variable_dependence(ph) === Traits.Fixed
            Test.@test ph([1.0, 2.0], [3.0, 4.0], 5.0) == 3.0 + 8.0 + 25.0
        end

        # ====================================================================
        # UNIT TESTS - Trait accessors
        # ====================================================================

        Test.@testset "Unit: Trait accessors" begin
            ph = PseudoHamiltonian((x, p, u) -> sum(x .* p) + u^2)
            Test.@test Traits.dynamics_trait(ph) == Traits.HamiltonianDynamics
            Test.@test Traits.has_time_dependence_trait(ph)
            Test.@test Traits.has_variable_dependence_trait(ph)
        end

        # ====================================================================
        # UNIT TESTS - Show Methods
        # ====================================================================

        Test.@testset "Show Methods" begin
            ph = PseudoHamiltonian((x, p, u) -> sum(x .* p) + u^2)

            Test.@testset "Base.show (compact)" begin
                io = IOBuffer()
                show(io, ph)
                str = String(take!(io))
                Test.@test occursin("PseudoHamiltonian", str)
                Test.@test occursin("autonomous", str)
                Test.@test occursin("fixed", str)
                Test.@test occursin("natural call", str)
                Test.@test occursin("uniform call", str)
            end

            Test.@testset "Base.show (text/plain)" begin
                io = IOBuffer()
                show(io, MIME("text/plain"), ph)
                str = String(take!(io))
                Test.@test occursin("PseudoHamiltonian", str)
            end

            Test.@testset "Show: NonAutonomous, NonFixed" begin
                ph2 = PseudoHamiltonian(
                    (t, x, p, u, v) -> t + sum(x .* p) + u^2 + v;
                    is_autonomous=false,
                    is_variable=true,
                )
                io = IOBuffer()
                show(io, ph2)
                str = String(take!(io))
                Test.@test occursin("non-autonomous", str)
                Test.@test occursin("variable", str)
            end
        end

        # ====================================================================
        # UNIT TESTS - Subtyping
        # ====================================================================

        Test.@testset "Subtyping" begin
            ph = PseudoHamiltonian((x, p, u) -> sum(x .* p) + u^2)
            Test.@test ph isa Data.AbstractPseudoHamiltonian
        end

        # ====================================================================
        # EXPORTS TESTS
        # ====================================================================

        Test.@testset "Exports" begin
            for sym in (:AbstractPseudoHamiltonian, :PseudoHamiltonian)
                Test.@test isdefined(Data, sym)
            end
        end
    end
end

end # module TestPseudoHamiltonian

test_pseudo_hamiltonian() = TestPseudoHamiltonian.test_pseudo_hamiltonian()
