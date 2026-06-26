module TestOptionsValue

using Test: Test
import CTBase.Exceptions
using CTBase: CTBase
import CTBase.Options
import CTBase.Core

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

function test_options_value()
    Test.@testset "Options module" verbose=VERBOSE showtiming=SHOWTIMING begin

        # ====================================================================
        # META TESTS - Exports / Public API surface
        # ====================================================================

        Test.@testset "Exports verification" begin
            Test.@test isdefined(CTBase, :Options)
            Test.@test isdefined(Options, :OptionValue)
            Test.@test isdefined(Options, :value)
            Test.@test isdefined(Options, :source)
            Test.@test isdefined(Options, :is_user)
            Test.@test isdefined(Options, :is_default)
            Test.@test isdefined(Options, :is_computed)
        end

        # ====================================================================
        # UNIT TESTS - OptionValue construction and helpers
        # ====================================================================
        Test.@testset "OptionValue construction" begin
            # Test with explicit source
            opt_user = Options.OptionValue(42, :user)
            Test.@test opt_user.value == 42
            Test.@test opt_user.source == :user
            Test.@test typeof(opt_user) == Options.OptionValue{Int}

            # Test with default source (note: default source is :user in current implementation)
            opt_default = Options.OptionValue(3.14)
            Test.@test opt_default.value == 3.14
            Test.@test opt_default.source == :user
            Test.@test typeof(opt_default) == Options.OptionValue{Float64}

            # Test with different types
            opt_str = Options.OptionValue("hello", :default)
            Test.@test opt_str.value == "hello"
            Test.@test opt_str.source == :default

            opt_bool = Options.OptionValue(true, :computed)
            Test.@test opt_bool.value == true
            Test.@test opt_bool.source == :computed
        end

        # Test OptionValue validation
        Test.@testset "OptionValue validation" begin
            # Test invalid sources
            Test.@test_throws Exceptions.IncorrectArgument Options.OptionValue(42, :invalid)
            Test.@test_throws Exceptions.IncorrectArgument Options.OptionValue(42, :wrong)
            Test.@test_throws Exceptions.IncorrectArgument Options.OptionValue(42, :DEFAULT)  # case sensitive
        end

        # Test OptionValue display
        Test.@testset "OptionValue display" begin
            opt = Options.OptionValue(100, :user)
            io = IOBuffer()
            Base.show(io, opt)
            Test.@test String(take!(io)) == "100 (user)"

            opt_default = Options.OptionValue(3.14, :default)
            io = IOBuffer()
            Base.show(io, opt_default)
            Test.@test String(take!(io)) == "3.14 (default)"
        end

        # Test OptionValue type stability
        Test.@testset "OptionValue type stability" begin
            opt_int = Options.OptionValue(42, :user)
            opt_float = Options.OptionValue(3.14, :user)

            # Test that types are preserved
            Test.@test typeof(opt_int.value) == Int
            Test.@test typeof(opt_float.value) == Float64

            # Test that the struct is parameterized correctly
            Test.@test typeof(opt_int) == Options.OptionValue{Int}
            Test.@test typeof(opt_float) == Options.OptionValue{Float64}
        end

        # ========================================================================
        # Getters and introspection
        # ========================================================================

        Test.@testset "Getters and introspection" begin
            opt_user = Options.OptionValue(42, :user)
            opt_default = Options.OptionValue(3.14, :default)
            opt_computed = Options.OptionValue(true, :computed)

            Test.@test Options.value(opt_user) === 42
            Test.@test Options.source(opt_user) === :user
            Test.@test_nowarn Test.@inferred Options.source(opt_user)

            Test.@test Options.is_user(opt_user) === true
            Test.@test_nowarn Test.@inferred Options.is_user(opt_user)

            Test.@test Options.is_default(opt_default) === true
            Test.@test_nowarn Test.@inferred Options.is_default(opt_default)

            Test.@test Options.is_computed(opt_computed) === true
            Test.@test_nowarn Test.@inferred Options.is_computed(opt_computed)
            Test.@test Options.is_default(opt_user) === false
            Test.@test Options.is_computed(opt_user) === false

            Test.@test Options.value(opt_default) === 3.14
            Test.@test Options.source(opt_default) === :default
            Test.@test Options.is_user(opt_default) === false
            Test.@test Options.is_default(opt_default) === true
            Test.@test Options.is_computed(opt_default) === false

            Test.@test Options.value(opt_computed) === true
            Test.@test Options.source(opt_computed) === :computed
            Test.@test Options.is_user(opt_computed) === false
            Test.@test Options.is_default(opt_computed) === false
            Test.@test Options.is_computed(opt_computed) === true
        end
    end
end

end # module

test_options_value() = TestOptionsValue.test_options_value()
