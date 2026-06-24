module TestHamiltonian

import Test
import CTBase.Data
import CTBase.Traits
import CTBase.Exceptions

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

function test_hamiltonian()
    Test.@testset "Hamiltonian Tests" verbose=VERBOSE showtiming=SHOWTIMING begin

        # ====================================================================
        # UNIT TESTS - Construction with all trait combinations
        # ====================================================================

        Test.@testset "Unit: Construction with all trait combinations" begin
            # Autonomous, Fixed
            h_aut_fixed = Data.Hamiltonian((x, p) -> x + p; is_autonomous=true, is_variable=false)
            Test.@test h_aut_fixed isa Data.Hamiltonian
            Test.@test Traits.time_dependence(h_aut_fixed) == Traits.Autonomous
            Test.@test Traits.variable_dependence(h_aut_fixed) == Traits.Fixed

            # NonAutonomous, Fixed
            h_nonaut_fixed = Data.Hamiltonian((t, x, p) -> t + x + p; is_autonomous=false, is_variable=false)
            Test.@test h_nonaut_fixed isa Data.Hamiltonian
            Test.@test Traits.time_dependence(h_nonaut_fixed) == Traits.NonAutonomous
            Test.@test Traits.variable_dependence(h_nonaut_fixed) == Traits.Fixed

            # Autonomous, NonFixed
            h_aut_nonfixed = Data.Hamiltonian((x, p, v) -> x + p + v; is_autonomous=true, is_variable=true)
            Test.@test h_aut_nonfixed isa Data.Hamiltonian
            Test.@test Traits.time_dependence(h_aut_nonfixed) == Traits.Autonomous
            Test.@test Traits.variable_dependence(h_aut_nonfixed) == Traits.NonFixed

            # NonAutonomous, NonFixed
            h_nonaut_nonfixed = Data.Hamiltonian((t, x, p, v) -> t + x + p + v; is_autonomous=false, is_variable=true)
            Test.@test h_nonaut_nonfixed isa Data.Hamiltonian
            Test.@test Traits.time_dependence(h_nonaut_nonfixed) == Traits.NonAutonomous
            Test.@test Traits.variable_dependence(h_nonaut_nonfixed) == Traits.NonFixed
        end

        # ====================================================================
        # UNIT TESTS - Natural call signatures
        # ====================================================================

        Test.@testset "Unit: Natural call signatures" begin
            # (x, p) for Autonomous, Fixed
            h1 = Data.Hamiltonian((x, p) -> x .+ p; is_autonomous=true, is_variable=false)
            result = h1([1.0, 2.0], [3.0, 4.0])
            Test.@test result == [4.0, 6.0]

            # (t, x, p) for NonAutonomous, Fixed
            h2 = Data.Hamiltonian((t, x, p) -> x .+ p; is_autonomous=false, is_variable=false)
            result = h2(2.0, [1.0, 2.0], [3.0, 4.0])
            Test.@test result == [4.0, 6.0]

            # (x, p, v) for Autonomous, NonFixed
            h3 = Data.Hamiltonian((x, p, v) -> x .+ p .+ v; is_autonomous=true, is_variable=true)
            result = h3([1.0, 2.0], [3.0, 4.0], 2.0)
            Test.@test result == [6.0, 8.0]

            # (t, x, p, v) for NonAutonomous, NonFixed
            h4 = Data.Hamiltonian((t, x, p, v) -> x .+ p .+ v; is_autonomous=false, is_variable=true)
            result = h4(2.0, [1.0, 2.0], [3.0, 4.0], 2.0)
            Test.@test result == [6.0, 8.0]
        end

        # ====================================================================
        # UNIT TESTS - Uniform call signature
        # ====================================================================

        Test.@testset "Unit: Uniform call signature (t, x, p, v)" begin
            # Autonomous Fixed - ignores t and v
            h1 = Data.Hamiltonian((x, p) -> x .+ p; is_autonomous=true, is_variable=false)
            result = h1(0.0, [1.0, 2.0], [3.0, 4.0], nothing)
            Test.@test result == [4.0, 6.0]

            # NonAutonomous Fixed - ignores v
            h2 = Data.Hamiltonian((t, x, p) -> x .+ p; is_autonomous=false, is_variable=false)
            result = h2(2.0, [1.0, 2.0], [3.0, 4.0], nothing)
            Test.@test result == [4.0, 6.0]

            # Autonomous NonFixed - ignores t
            h3 = Data.Hamiltonian((x, p, v) -> x .+ p .+ v; is_autonomous=true, is_variable=true)
            result = h3(0.0, [1.0, 2.0], [3.0, 4.0], 2.0)
            Test.@test result == [6.0, 8.0]

            # NonAutonomous NonFixed - uses all
            h4 = Data.Hamiltonian((t, x, p, v) -> x .+ p .+ v; is_autonomous=false, is_variable=true)
            result = h4(2.0, [1.0, 2.0], [3.0, 4.0], 2.0)
            Test.@test result == [6.0, 8.0]
        end

        # ====================================================================
        # UNIT TESTS - Type stability
        # ====================================================================

        Test.@testset "Unit: Type stability" begin
            # Uniform call type stability
            h = Data.Hamiltonian((x, p) -> x .+ p; is_autonomous=true, is_variable=false)
            Test.@test Test.@inferred(h(0.0, [1.0, 2.0], [3.0, 4.0], nothing)) == [4.0, 6.0]
        end

        # ====================================================================
        # UNIT TESTS - Show Methods
        # ====================================================================

        Test.@testset "Show Methods" begin
            h = Data.Hamiltonian((x, p) -> x .+ p; is_autonomous=true, is_variable=false)

            Test.@testset "Base.show (compact)" begin
                io = IOBuffer()
                show(io, h)
                str = String(take!(io))
                Test.@test occursin("Hamiltonian", str)
                Test.@test occursin("autonomous", str)
                Test.@test occursin("fixed (no variable)", str)
                Test.@test occursin("natural call", str)
                Test.@test occursin("uniform call", str)
            end

            Test.@testset "Base.show (text/plain)" begin
                io = IOBuffer()
                show(io, MIME("text/plain"), h)
                str = String(take!(io))
                Test.@test occursin("Hamiltonian", str)
                Test.@test occursin("autonomous", str)
                Test.@test occursin("fixed (no variable)", str)
            end
        end

        # ====================================================================
        # UNIT TESTS - Typed constructor (trait types passed positionally)
        # ====================================================================

        Test.@testset "Typed constructor" begin
            h = Data.Hamiltonian((x, p) -> x .+ p, Traits.Autonomous, Traits.Fixed)
            Test.@test h isa Data.Hamiltonian
            Test.@test Traits.time_dependence(h) === Traits.Autonomous
            Test.@test Traits.variable_dependence(h) === Traits.Fixed
            Test.@test h([1.0, 2.0], [3.0, 4.0]) == [4.0, 6.0]
        end

        # ====================================================================
        # UNIT TESTS - Subtyping
        # ====================================================================

        Test.@testset "Subtyping" begin
            Test.@testset "Hamiltonian is an AbstractHamiltonian" begin
                h = Data.Hamiltonian((x, p) -> x .+ p; is_autonomous=true, is_variable=false)
                Test.@test h isa Data.AbstractHamiltonian
            end
        end

        # ====================================================================
        # EXPORTS TESTS
        # ====================================================================

        Test.@testset "Exports" begin
            Test.@testset "Hamiltonian is exported" begin
                Test.@test isdefined(Data, :Hamiltonian)
            end
        end
    end
end

end # module TestHamiltonian

test_hamiltonian() = TestHamiltonian.test_hamiltonian()
