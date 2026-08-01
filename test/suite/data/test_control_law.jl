module TestControlLaw

using Test: Test
using CTBase: Data
using CTBase: Exceptions
using CTBase: Traits

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

function test_control_law()
    Test.@testset "ControlLaw Tests" verbose=VERBOSE showtiming=SHOWTIMING begin

        # ====================================================================
        # UNIT TESTS - Construction with all trait combinations
        # ====================================================================

        Test.@testset "Unit: Construction with all trait combinations" begin
            # OpenLoop is unconditionally NonAutonomous — is_autonomous is not
            # a real axis, only Fixed/NonFixed remain.
            # OpenLoop, Fixed
            cl1 = Data.OpenLoop(t -> t; is_variable=false)
            Test.@test cl1 isa Data.ControlLaw
            Test.@test Traits.feedback(cl1) == Traits.OpenLoopFeedback
            Test.@test Traits.time_dependence(cl1) == Traits.NonAutonomous
            Test.@test Traits.variable_dependence(cl1) == Traits.Fixed

            # OpenLoop, NonFixed
            cl2 = Data.OpenLoop((t, v) -> t + v; is_variable=true)
            Test.@test cl2 isa Data.ControlLaw
            Test.@test Traits.feedback(cl2) == Traits.OpenLoopFeedback
            Test.@test Traits.time_dependence(cl2) == Traits.NonAutonomous
            Test.@test Traits.variable_dependence(cl2) == Traits.NonFixed

            # ClosedLoop, Autonomous, Fixed
            cl5 = Data.ClosedLoop((x) -> x; is_autonomous=true, is_variable=false)
            Test.@test cl5 isa Data.ControlLaw
            Test.@test Traits.feedback(cl5) == Traits.ClosedLoopFeedback
            Test.@test Traits.time_dependence(cl5) == Traits.Autonomous
            Test.@test Traits.variable_dependence(cl5) == Traits.Fixed

            # ClosedLoop, NonAutonomous, Fixed
            cl6 = Data.ClosedLoop((t, x) -> t + x; is_autonomous=false, is_variable=false)
            Test.@test cl6 isa Data.ControlLaw
            Test.@test Traits.feedback(cl6) == Traits.ClosedLoopFeedback
            Test.@test Traits.time_dependence(cl6) == Traits.NonAutonomous
            Test.@test Traits.variable_dependence(cl6) == Traits.Fixed

            # ClosedLoop, Autonomous, NonFixed
            cl7 = Data.ClosedLoop((x, v) -> x + v; is_autonomous=true, is_variable=true)
            Test.@test cl7 isa Data.ControlLaw
            Test.@test Traits.feedback(cl7) == Traits.ClosedLoopFeedback
            Test.@test Traits.time_dependence(cl7) == Traits.Autonomous
            Test.@test Traits.variable_dependence(cl7) == Traits.NonFixed

            # ClosedLoop, NonAutonomous, NonFixed
            cl8 = Data.ClosedLoop(
                (t, x, v) -> t + x + v; is_autonomous=false, is_variable=true
            )
            Test.@test cl8 isa Data.ControlLaw
            Test.@test Traits.feedback(cl8) == Traits.ClosedLoopFeedback
            Test.@test Traits.time_dependence(cl8) == Traits.NonAutonomous
            Test.@test Traits.variable_dependence(cl8) == Traits.NonFixed

            # DynClosedLoop, Autonomous, Fixed
            cl9 = Data.DynClosedLoop((x, p) -> x + p; is_autonomous=true, is_variable=false)
            Test.@test cl9 isa Data.ControlLaw
            Test.@test Traits.feedback(cl9) == Traits.DynClosedLoopFeedback
            Test.@test Traits.time_dependence(cl9) == Traits.Autonomous
            Test.@test Traits.variable_dependence(cl9) == Traits.Fixed

            # DynClosedLoop, NonAutonomous, Fixed
            cl10 = Data.DynClosedLoop(
                (t, x, p) -> t + x + p; is_autonomous=false, is_variable=false
            )
            Test.@test cl10 isa Data.ControlLaw
            Test.@test Traits.feedback(cl10) == Traits.DynClosedLoopFeedback
            Test.@test Traits.time_dependence(cl10) == Traits.NonAutonomous
            Test.@test Traits.variable_dependence(cl10) == Traits.Fixed

            # DynClosedLoop, Autonomous, NonFixed
            cl11 = Data.DynClosedLoop(
                (x, p, v) -> x + p + v; is_autonomous=true, is_variable=true
            )
            Test.@test cl11 isa Data.ControlLaw
            Test.@test Traits.feedback(cl11) == Traits.DynClosedLoopFeedback
            Test.@test Traits.time_dependence(cl11) == Traits.Autonomous
            Test.@test Traits.variable_dependence(cl11) == Traits.NonFixed

            # DynClosedLoop, NonAutonomous, NonFixed
            cl12 = Data.DynClosedLoop(
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
            # OpenLoop — always u(t) or u(t, v), never zero-argument
            cl1 = Data.OpenLoop(t -> 1.0)
            Test.@test cl1(0.0) == 1.0

            cl2 = Data.OpenLoop(t -> 2t)
            Test.@test cl2(3.0) == 6.0

            cl3 = Data.OpenLoop((t, v) -> 3v; is_variable=true)
            Test.@test cl3(0.0, 2.0) == 6.0

            cl4 = Data.OpenLoop((t, v) -> t + v; is_variable=true)
            Test.@test cl4(1.0, 2.0) == 3.0

            # ClosedLoop
            cl5 = Data.ClosedLoop((x) -> 2 .* x)
            Test.@test cl5([1.0, 2.0]) == [2.0, 4.0]

            cl6 = Data.ClosedLoop((t, x) -> t .+ x; is_autonomous=false)
            Test.@test cl6(1.0, [2.0, 3.0]) == [3.0, 4.0]

            cl7 = Data.ClosedLoop((x, v) -> x .+ v; is_variable=true)
            Test.@test cl7([1.0, 2.0], 3.0) == [4.0, 5.0]

            cl8 = Data.ClosedLoop(
                (t, x, v) -> t .+ x .+ v; is_autonomous=false, is_variable=true
            )
            Test.@test cl8(1.0, [2.0, 3.0], 4.0) == [7.0, 8.0]

            # DynClosedLoop
            cl9 = Data.DynClosedLoop((x, p) -> x .+ p)
            Test.@test cl9([1.0, 2.0], [3.0, 4.0]) == [4.0, 6.0]

            cl10 = Data.DynClosedLoop((t, x, p) -> t .+ x .+ p; is_autonomous=false)
            Test.@test cl10(1.0, [2.0, 3.0], [4.0, 5.0]) == [7.0, 9.0]

            cl11 = Data.DynClosedLoop((x, p, v) -> x .+ p .+ v; is_variable=true)
            Test.@test cl11([1.0, 2.0], [3.0, 4.0], 5.0) == [9.0, 11.0]

            cl12 = Data.DynClosedLoop(
                (t, x, p, v) -> t .+ x .+ p .+ v; is_autonomous=false, is_variable=true
            )
            Test.@test cl12(1.0, [2.0, 3.0], [4.0, 5.0], 6.0) == [13.0, 15.0]
        end

        # ====================================================================
        # UNIT TESTS - Uniform call signature
        # ====================================================================

        Test.@testset "Unit: Uniform call signature" begin
            # OpenLoop — uniform (t, v), no state
            cl1 = Data.OpenLoop(t -> 1.0)
            Test.@test cl1(0.0, 3.0) == 1.0

            cl2 = Data.OpenLoop(t -> 2t)
            Test.@test cl2(3.0, 4.0) == 6.0

            cl3 = Data.OpenLoop((t, v) -> 3v; is_variable=true)
            Test.@test cl3(0.0, 2.0) == 6.0

            cl4 = Data.OpenLoop((t, v) -> t + v; is_variable=true)
            Test.@test cl4(1.0, 4.0) == 5.0

            # ClosedLoop — uniform (t, x, v)
            cl5 = Data.ClosedLoop((x) -> 2 .* x)
            Test.@test cl5(0.0, [1.0, 2.0], 4.0) == [2.0, 4.0]

            cl6 = Data.ClosedLoop((t, x) -> t .+ x; is_autonomous=false)
            Test.@test cl6(1.0, [2.0, 3.0], 5.0) == [3.0, 4.0]

            cl7 = Data.ClosedLoop((x, v) -> x .+ v; is_variable=true)
            Test.@test cl7(0.0, [1.0, 2.0], 4.0) == [5.0, 6.0]

            cl8 = Data.ClosedLoop(
                (t, x, v) -> t .+ x .+ v; is_autonomous=false, is_variable=true
            )
            Test.@test cl8(1.0, [2.0, 3.0], 5.0) == [8.0, 9.0]

            # DynClosedLoop — uniform (t, x, p, v)
            cl9 = Data.DynClosedLoop((x, p) -> x .+ p)
            Test.@test cl9(0.0, [1.0, 2.0], [3.0, 4.0], 5.0) == [4.0, 6.0]

            cl10 = Data.DynClosedLoop((t, x, p) -> t .+ x .+ p; is_autonomous=false)
            Test.@test cl10(1.0, [2.0, 3.0], [4.0, 5.0], 6.0) == [7.0, 9.0]

            cl11 = Data.DynClosedLoop((x, p, v) -> x .+ p .+ v; is_variable=true)
            Test.@test cl11(0.0, [1.0, 2.0], [3.0, 4.0], 5.0) == [9.0, 11.0]

            cl12 = Data.DynClosedLoop(
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
            Test.@test cl isa Data.ControlLaw
            Test.@test Traits.feedback(cl) === Traits.DynClosedLoopFeedback
            Test.@test Traits.time_dependence(cl) === Traits.Autonomous
            Test.@test Traits.variable_dependence(cl) === Traits.Fixed
            Test.@test cl([1.0, 2.0], [3.0, 4.0]) == [4.0, 6.0]

            # OpenLoopFeedback + Autonomous is rejected: the combination has
            # no natural/uniform call methods, so construction itself fails
            # with a clear error instead of a MethodError at call time.
            Test.@test_throws Exceptions.IncorrectArgument Data.ControlLaw(
                t -> 1.0, Traits.OpenLoopFeedback, Traits.Autonomous, Traits.Fixed
            )
        end

        # ====================================================================
        # UNIT TESTS - is_autonomous misuse warning (OpenLoop)
        # ====================================================================

        Test.@testset "Unit: is_autonomous misuse warning" begin
            # Not provided at all: no warning, law works normally.
            Test.@test_logs begin
                cl = Data.OpenLoop(t -> 1.0)
                Test.@test cl(0.0) == 1.0
            end

            # Explicitly passed (true or false): warns, but still builds a
            # working u(t) law — the keyword has no effect on behavior.
            Test.@test_logs (:warn, r"is_autonomous.*no effect") begin
                cl = Data.OpenLoop(t -> 1.0; is_autonomous=true)
                Test.@test cl(0.0) == 1.0
            end
            Test.@test_logs (:warn, r"is_autonomous.*no effect") begin
                cl = Data.OpenLoop(t -> 1.0; is_autonomous=false)
                Test.@test cl(0.0) == 1.0
            end
        end

        # ====================================================================
        # UNIT TESTS - Trait accessors
        # ====================================================================

        Test.@testset "Unit: Trait accessors" begin
            # dynamics_trait
            ol = Data.OpenLoop(t -> 1.0)
            Test.@test Traits.dynamics_trait(ol) == Traits.StateDynamics
            Test.@test Traits.time_dependence(ol) == Traits.NonAutonomous
            Test.@test !Traits.is_autonomous(ol)

            cl_ = Data.ClosedLoop((x) -> x)
            Test.@test Traits.dynamics_trait(cl_) == Traits.StateDynamics

            dcl = Data.DynClosedLoop((x, p) -> x .+ p)
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
            cl = Data.OpenLoop(t -> 1.0)

            Test.@testset "Base.show (compact)" begin
                io = IOBuffer()
                show(io, cl)
                str = String(take!(io))
                Test.@test occursin("ControlLaw", str)
                Test.@test occursin("open-loop", str)
                Test.@test occursin("fixed", str)
                Test.@test occursin("natural call", str)
                Test.@test occursin("uniform call", str)
                Test.@test occursin("u(t)", str)
                # OpenLoop's TimeDependence is fixed, not a real choice, so
                # the header omits the "autonomous"/"non-autonomous" label.
                Test.@test !occursin("autonomous", str)
            end

            Test.@testset "Base.show (text/plain)" begin
                io = IOBuffer()
                show(io, MIME("text/plain"), cl)
                str = String(take!(io))
                Test.@test occursin("ControlLaw", str)
                Test.@test occursin("open-loop", str)
            end

            Test.@testset "Show: DynClosedLoop" begin
                dcl = Data.DynClosedLoop((x, p) -> x .+ p)
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
                cl = Data.OpenLoop(t -> 1.0)
                Test.@test cl isa Data.AbstractControlLaw
            end

            Test.@testset "ClosedLoop is an AbstractControlLaw" begin
                cl = Data.ClosedLoop((x) -> x)
                Test.@test cl isa Data.AbstractControlLaw
            end

            Test.@testset "DynClosedLoop is an AbstractControlLaw" begin
                cl = Data.DynClosedLoop((x, p) -> x .+ p)
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
