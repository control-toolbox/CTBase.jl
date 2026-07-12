module TestControlLaw

using Test: Test
import CTBase.Data: Data, OpenLoop, ClosedLoop, DynClosedLoop
import CTBase.Traits

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

function test_control_law()
    Test.@testset "ControlLaw Tests" verbose=VERBOSE showtiming=SHOWTIMING begin

        # ====================================================================
        # UNIT TESTS - Construction with all trait combinations
        # ====================================================================

        Test.@testset "Unit: Construction with all trait combinations" begin
            # OpenLoop, Autonomous, Fixed
            cl1 = OpenLoop(() -> 1.0; is_autonomous=true, is_variable=false)
            Test.@test cl1 isa Data.ControlLaw
            Test.@test Traits.feedback(cl1) == Traits.OpenLoopFeedback
            Test.@test Traits.time_dependence(cl1) == Traits.Autonomous
            Test.@test Traits.variable_dependence(cl1) == Traits.Fixed

            # OpenLoop, NonAutonomous, Fixed
            cl2 = OpenLoop((t) -> t; is_autonomous=false, is_variable=false)
            Test.@test cl2 isa Data.ControlLaw
            Test.@test Traits.feedback(cl2) == Traits.OpenLoopFeedback
            Test.@test Traits.time_dependence(cl2) == Traits.NonAutonomous
            Test.@test Traits.variable_dependence(cl2) == Traits.Fixed

            # OpenLoop, Autonomous, NonFixed
            cl3 = OpenLoop((v) -> v; is_autonomous=true, is_variable=true)
            Test.@test cl3 isa Data.ControlLaw
            Test.@test Traits.feedback(cl3) == Traits.OpenLoopFeedback
            Test.@test Traits.time_dependence(cl3) == Traits.Autonomous
            Test.@test Traits.variable_dependence(cl3) == Traits.NonFixed

            # OpenLoop, NonAutonomous, NonFixed
            cl4 = OpenLoop((t, v) -> t + v; is_autonomous=false, is_variable=true)
            Test.@test cl4 isa Data.ControlLaw
            Test.@test Traits.feedback(cl4) == Traits.OpenLoopFeedback
            Test.@test Traits.time_dependence(cl4) == Traits.NonAutonomous
            Test.@test Traits.variable_dependence(cl4) == Traits.NonFixed

            # ClosedLoop, Autonomous, Fixed
            cl5 = ClosedLoop((x) -> x; is_autonomous=true, is_variable=false)
            Test.@test cl5 isa Data.ControlLaw
            Test.@test Traits.feedback(cl5) == Traits.ClosedLoopFeedback
            Test.@test Traits.time_dependence(cl5) == Traits.Autonomous
            Test.@test Traits.variable_dependence(cl5) == Traits.Fixed

            # ClosedLoop, NonAutonomous, Fixed
            cl6 = ClosedLoop((t, x) -> t + x; is_autonomous=false, is_variable=false)
            Test.@test cl6 isa Data.ControlLaw
            Test.@test Traits.feedback(cl6) == Traits.ClosedLoopFeedback
            Test.@test Traits.time_dependence(cl6) == Traits.NonAutonomous
            Test.@test Traits.variable_dependence(cl6) == Traits.Fixed

            # ClosedLoop, Autonomous, NonFixed
            cl7 = ClosedLoop((x, v) -> x + v; is_autonomous=true, is_variable=true)
            Test.@test cl7 isa Data.ControlLaw
            Test.@test Traits.feedback(cl7) == Traits.ClosedLoopFeedback
            Test.@test Traits.time_dependence(cl7) == Traits.Autonomous
            Test.@test Traits.variable_dependence(cl7) == Traits.NonFixed

            # ClosedLoop, NonAutonomous, NonFixed
            cl8 = ClosedLoop((t, x, v) -> t + x + v; is_autonomous=false, is_variable=true)
            Test.@test cl8 isa Data.ControlLaw
            Test.@test Traits.feedback(cl8) == Traits.ClosedLoopFeedback
            Test.@test Traits.time_dependence(cl8) == Traits.NonAutonomous
            Test.@test Traits.variable_dependence(cl8) == Traits.NonFixed

            # DynClosedLoop, Autonomous, Fixed
            cl9 = DynClosedLoop((x, p) -> x + p; is_autonomous=true, is_variable=false)
            Test.@test cl9 isa Data.ControlLaw
            Test.@test Traits.feedback(cl9) == Traits.DynClosedLoopFeedback
            Test.@test Traits.time_dependence(cl9) == Traits.Autonomous
            Test.@test Traits.variable_dependence(cl9) == Traits.Fixed

            # DynClosedLoop, NonAutonomous, Fixed
            cl10 = DynClosedLoop(
                (t, x, p) -> t + x + p; is_autonomous=false, is_variable=false
            )
            Test.@test cl10 isa Data.ControlLaw
            Test.@test Traits.feedback(cl10) == Traits.DynClosedLoopFeedback
            Test.@test Traits.time_dependence(cl10) == Traits.NonAutonomous
            Test.@test Traits.variable_dependence(cl10) == Traits.Fixed

            # DynClosedLoop, Autonomous, NonFixed
            cl11 = DynClosedLoop(
                (x, p, v) -> x + p + v; is_autonomous=true, is_variable=true
            )
            Test.@test cl11 isa Data.ControlLaw
            Test.@test Traits.feedback(cl11) == Traits.DynClosedLoopFeedback
            Test.@test Traits.time_dependence(cl11) == Traits.Autonomous
            Test.@test Traits.variable_dependence(cl11) == Traits.NonFixed

            # DynClosedLoop, NonAutonomous, NonFixed
            cl12 = DynClosedLoop(
                (t, x, p, v) -> t + x + p + v; is_autonomous=false, is_variable=true
            )
            Test.@test cl12 isa Data.ControlLaw
            Test.@test Traits.feedback(cl12) == Traits.DynClosedLoopFeedback
            Test.@test Traits.time_dependence(cl12) == Traits.NonAutonomous
            Test.@test Traits.variable_dependence(cl12) == Traits.NonFixed
        end

        # ====================================================================
        # UNIT TESTS - Natural call signatures
        # ====================================================================

        Test.@testset "Unit: Natural call signatures" begin
            # OpenLoop
            cl1 = OpenLoop(() -> 1.0)
            Test.@test cl1() == 1.0

            cl2 = OpenLoop((t) -> 2t; is_autonomous=false)
            Test.@test cl2(3.0) == 6.0

            cl3 = OpenLoop((v) -> 3v; is_variable=true)
            Test.@test cl3(2.0) == 6.0

            cl4 = OpenLoop((t, v) -> t + v; is_autonomous=false, is_variable=true)
            Test.@test cl4(1.0, 2.0) == 3.0

            # ClosedLoop
            cl5 = ClosedLoop((x) -> 2 .* x)
            Test.@test cl5([1.0, 2.0]) == [2.0, 4.0]

            cl6 = ClosedLoop((t, x) -> t .+ x; is_autonomous=false)
            Test.@test cl6(1.0, [2.0, 3.0]) == [3.0, 4.0]

            cl7 = ClosedLoop((x, v) -> x .+ v; is_variable=true)
            Test.@test cl7([1.0, 2.0], 3.0) == [4.0, 5.0]

            cl8 = ClosedLoop(
                (t, x, v) -> t .+ x .+ v; is_autonomous=false, is_variable=true
            )
            Test.@test cl8(1.0, [2.0, 3.0], 4.0) == [7.0, 8.0]

            # DynClosedLoop
            cl9 = DynClosedLoop((x, p) -> x .+ p)
            Test.@test cl9([1.0, 2.0], [3.0, 4.0]) == [4.0, 6.0]

            cl10 = DynClosedLoop((t, x, p) -> t .+ x .+ p; is_autonomous=false)
            Test.@test cl10(1.0, [2.0, 3.0], [4.0, 5.0]) == [7.0, 9.0]

            cl11 = DynClosedLoop((x, p, v) -> x .+ p .+ v; is_variable=true)
            Test.@test cl11([1.0, 2.0], [3.0, 4.0], 5.0) == [9.0, 11.0]

            cl12 = DynClosedLoop(
                (t, x, p, v) -> t .+ x .+ p .+ v; is_autonomous=false, is_variable=true
            )
            Test.@test cl12(1.0, [2.0, 3.0], [4.0, 5.0], 6.0) == [13.0, 15.0]
        end

        # ====================================================================
        # UNIT TESTS - Uniform call signature
        # ====================================================================

        Test.@testset "Unit: Uniform call signature" begin
            # OpenLoop — uniform (t, v), no state
            cl1 = OpenLoop(() -> 1.0)
            Test.@test cl1(0.0, 3.0) == 1.0

            cl2 = OpenLoop((t) -> 2t; is_autonomous=false)
            Test.@test cl2(3.0, 4.0) == 6.0

            cl3 = OpenLoop((v) -> 3v; is_variable=true)
            Test.@test cl3(0.0, 2.0) == 6.0

            cl4 = OpenLoop((t, v) -> t + v; is_autonomous=false, is_variable=true)
            Test.@test cl4(1.0, 4.0) == 5.0

            # ClosedLoop — uniform (t, x, v)
            cl5 = ClosedLoop((x) -> 2 .* x)
            Test.@test cl5(0.0, [1.0, 2.0], 4.0) == [2.0, 4.0]

            cl6 = ClosedLoop((t, x) -> t .+ x; is_autonomous=false)
            Test.@test cl6(1.0, [2.0, 3.0], 5.0) == [3.0, 4.0]

            cl7 = ClosedLoop((x, v) -> x .+ v; is_variable=true)
            Test.@test cl7(0.0, [1.0, 2.0], 4.0) == [5.0, 6.0]

            cl8 = ClosedLoop(
                (t, x, v) -> t .+ x .+ v; is_autonomous=false, is_variable=true
            )
            Test.@test cl8(1.0, [2.0, 3.0], 5.0) == [8.0, 9.0]

            # DynClosedLoop — uniform (t, x, p, v)
            cl9 = DynClosedLoop((x, p) -> x .+ p)
            Test.@test cl9(0.0, [1.0, 2.0], [3.0, 4.0], 5.0) == [4.0, 6.0]

            cl10 = DynClosedLoop((t, x, p) -> t .+ x .+ p; is_autonomous=false)
            Test.@test cl10(1.0, [2.0, 3.0], [4.0, 5.0], 6.0) == [7.0, 9.0]

            cl11 = DynClosedLoop((x, p, v) -> x .+ p .+ v; is_variable=true)
            Test.@test cl11(0.0, [1.0, 2.0], [3.0, 4.0], 5.0) == [9.0, 11.0]

            cl12 = DynClosedLoop(
                (t, x, p, v) -> t .+ x .+ p .+ v; is_autonomous=false, is_variable=true
            )
            Test.@test cl12(1.0, [2.0, 3.0], [4.0, 5.0], 6.0) == [13.0, 15.0]
        end

        # ====================================================================
        # UNIT TESTS - Typed constructor
        # ====================================================================

        Test.@testset "Unit: Typed constructor" begin
            cl = Data.ControlLaw(
                (x, p) -> x .+ p,
                Traits.DynClosedLoopFeedback,
                Traits.Autonomous,
                Traits.Fixed,
            )
            # also test via the typed constructor with OpenLoopFeedback
            Test.@test cl isa Data.ControlLaw
            Test.@test Traits.feedback(cl) === Traits.DynClosedLoopFeedback
            Test.@test Traits.time_dependence(cl) === Traits.Autonomous
            Test.@test Traits.variable_dependence(cl) === Traits.Fixed
            Test.@test cl([1.0, 2.0], [3.0, 4.0]) == [4.0, 6.0]
        end

        # ====================================================================
        # UNIT TESTS - Trait accessors
        # ====================================================================

        Test.@testset "Unit: Trait accessors" begin
            # dynamics_trait
            ol = OpenLoop(() -> 1.0)
            Test.@test Traits.dynamics_trait(ol) == Traits.StateDynamics

            cl_ = ClosedLoop((x) -> x)
            Test.@test Traits.dynamics_trait(cl_) == Traits.StateDynamics

            dcl = DynClosedLoop((x, p) -> x .+ p)
            Test.@test Traits.dynamics_trait(dcl) == Traits.HamiltonianDynamics

            # Predicates
            Test.@test Traits.is_open_loop(ol)
            Test.@test !Traits.is_closed_loop(ol)
            Test.@test !Traits.is_dyn_closed_loop(ol)

            Test.@test !Traits.is_open_loop(cl_)
            Test.@test Traits.is_closed_loop(cl_)
            Test.@test !Traits.is_dyn_closed_loop(cl_)

            Test.@test !Traits.is_open_loop(dcl)
            Test.@test !Traits.is_closed_loop(dcl)
            Test.@test Traits.is_dyn_closed_loop(dcl)
        end

        # ====================================================================
        # UNIT TESTS - Show Methods
        # ====================================================================

        Test.@testset "Show Methods" begin
            cl = OpenLoop(() -> 1.0)

            Test.@testset "Base.show (compact)" begin
                io = IOBuffer()
                show(io, cl)
                str = String(take!(io))
                Test.@test occursin("ControlLaw", str)
                Test.@test occursin("open-loop", str)
                Test.@test occursin("autonomous", str)
                Test.@test occursin("fixed", str)
                Test.@test occursin("natural call", str)
                Test.@test occursin("uniform call", str)
            end

            Test.@testset "Base.show (text/plain)" begin
                io = IOBuffer()
                show(io, MIME("text/plain"), cl)
                str = String(take!(io))
                Test.@test occursin("ControlLaw", str)
                Test.@test occursin("open-loop", str)
            end

            Test.@testset "Show: DynClosedLoop" begin
                dcl = DynClosedLoop((x, p) -> x .+ p)
                io = IOBuffer()
                show(io, dcl)
                str = String(take!(io))
                Test.@test occursin("dyn-closed-loop", str)
                Test.@test occursin("u(x, p)", str)
            end
        end

        # ====================================================================
        # UNIT TESTS - Subtyping
        # ====================================================================

        Test.@testset "Subtyping" begin
            Test.@testset "ControlLaw is an AbstractControlLaw" begin
                cl = OpenLoop(() -> 1.0)
                Test.@test cl isa Data.AbstractControlLaw
            end

            Test.@testset "ClosedLoop is an AbstractControlLaw" begin
                cl = ClosedLoop((x) -> x)
                Test.@test cl isa Data.AbstractControlLaw
            end

            Test.@testset "DynClosedLoop is an AbstractControlLaw" begin
                cl = DynClosedLoop((x, p) -> x .+ p)
                Test.@test cl isa Data.AbstractControlLaw
            end
        end

        # ====================================================================
        # EXPORTS TESTS
        # ====================================================================

        Test.@testset "Exports" begin
            for sym in
                (:AbstractControlLaw, :ControlLaw, :OpenLoop, :ClosedLoop, :DynClosedLoop)
                Test.@test isdefined(Data, sym)
            end
        end

        Test.@testset "Type stability" begin
            cl = Data.ControlLaw(
                (x, p) -> x .+ p,
                Traits.DynClosedLoopFeedback,
                Traits.Autonomous,
                Traits.Fixed,
            )
            Test.@inferred cl([1.0, 2.0], [3.0, 4.0])
            Test.@inferred Traits.feedback(cl)
        end
    end
end

end # module TestControlLaw

test_control_law() = TestControlLaw.test_control_law()
