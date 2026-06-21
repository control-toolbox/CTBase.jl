module TestOptions

using Test: Test
import CTBase.Exceptions
using CTBase: CTBase
import CTBase.Options
using CTBase.Options  # For testing exported symbols

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true
const CurrentModule = TestOptions

"""
    test_options()

Tests for Options module.

This function tests the complete Options module including:
- Option value tracking with provenance
- Option schema definition with validation and aliases
- Option extraction with alias support
- Type validation and helpful error messages
"""
function test_options()
    Test.@testset "Options Module" verbose=VERBOSE showtiming=SHOWTIMING begin

        # ====================================================================
        # META TESTS - Exports / Public API surface
        # ====================================================================

        Test.@testset "Exports verification" begin
            # Test that Options module is available
            Test.@testset "Options Module" begin
                Test.@test isdefined(CTBase, :Options)
                Test.@test CTBase.Options isa Module
            end

            # Test exported types
            Test.@testset "Exported Types" begin
                for T in (NotProvidedType, OptionValue, OptionDefinition)
                    Test.@testset "$(nameof(T))" begin
                        Test.@test isdefined(Options, nameof(T))
                        Test.@test isdefined(CurrentModule, nameof(T))
                        Test.@test T isa DataType || T isa UnionAll
                    end
                end
            end

            # Test exported constants
            Test.@testset "Exported Constants" begin
                for c in (:NotProvided,)
                    Test.@testset "$c" begin
                        Test.@test isdefined(Options, c)
                        Test.@test isdefined(CurrentModule, c)
                    end
                end
            end

            # Test exported functions
            Test.@testset "Exported Functions" begin
                for f in (
                    :extract_option,
                    :extract_options,
                    :extract_raw_options,
                    :all_names,
                    :aliases,
                    :is_required,
                    :has_default,
                    :has_validator,
                    :name,
                    :type,
                    :default,
                    :description,
                    :validator,
                    :value,
                    :source,
                    :is_user,
                    :is_default,
                    :is_computed,
                )
                    Test.@testset "$f" begin
                        Test.@test isdefined(Options, f)
                        Test.@test isdefined(CurrentModule, f)
                        Test.@test getfield(CurrentModule, f) isa Function
                    end
                end
            end
        end

        # ====================================================================
        # UNIT TESTS - NotProvided and NotStored
        # ====================================================================

        Test.@testset "NotProvided and NotStored" begin
            Test.@testset "NotProvided display" begin
                buf = IOBuffer()
                show(buf, Options.NotProvided)
                Test.@test String(take!(buf)) == "NotProvided"
            end

            Test.@testset "NotStored display" begin
                buf = IOBuffer()
                show(buf, Options.NotStored)
                Test.@test String(take!(buf)) == "NotStored"
            end

            Test.@testset "NotStored type" begin
                Test.@test Options.NotStored isa Options.NotStoredType
                Test.@test typeof(Options.NotStored) == Options.NotStoredType
            end
        end

        # ====================================================================
        # UNIT TESTS - OptionValue construction and helpers
        # ====================================================================

        Test.@testset "OptionValue" begin
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

            Test.@testset "OptionValue validation" begin
                # Test invalid sources
                Test.@test_throws Exceptions.IncorrectArgument Options.OptionValue(
                    42, :invalid
                )
                Test.@test_throws Exceptions.IncorrectArgument Options.OptionValue(
                    42, :wrong
                )
                Test.@test_throws Exceptions.IncorrectArgument Options.OptionValue(
                    42, :DEFAULT
                )  # case sensitive
            end

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

        # ====================================================================
        # UNIT TESTS - OptionDefinition
        # ====================================================================

        Test.@testset "OptionDefinition" begin
            Test.@testset "Basic construction" begin
                opt_def = Options.OptionDefinition(
                    name=:test_option, type=Int, default=42, description="Test option"
                )

                Test.@test Options.name(opt_def) == :test_option
                Test.@test Options.type(opt_def) == Int
                Test.@test Options.default(opt_def) == 42
                Test.@test Options.description(opt_def) == "Test option"
                Test.@test Options.aliases(opt_def) == ()
                Test.@test Options.validator(opt_def) === nothing
            end

            Test.@testset "With aliases" begin
                opt_def = Options.OptionDefinition(
                    name=:test_option,
                    type=Int,
                    default=42,
                    description="Test option",
                    aliases=(:test_opt, :alias2),
                )

                Test.@test Options.aliases(opt_def) == (:test_opt, :alias2)
                Test.@test Options.all_names(opt_def) == (:test_option, :test_opt, :alias2)
            end

            Test.@testset "With validator" begin
                validator = x -> x > 0
                opt_def = Options.OptionDefinition(
                    name=:test_option,
                    type=Int,
                    default=42,
                    description="Test option",
                    validator=validator,
                )

                Test.@test Options.validator(opt_def) === validator
                Test.@test Options.has_validator(opt_def) == true
            end

            Test.@testset "Helper functions" begin
                opt_def_with_default = Options.OptionDefinition(
                    name=:test_option, type=Int, default=42, description="Test option"
                )
                opt_def_no_default = Options.OptionDefinition(
                    name=:required_option,
                    type=Int,
                    default=Options.NotProvided,
                    description="Required option",
                )

                Test.@test Options.has_default(opt_def_with_default) == true
                Test.@test Options.has_default(opt_def_no_default) == false
                Test.@test Options.is_required(opt_def_no_default) == true
                Test.@test Options.is_required(opt_def_with_default) == false
            end
        end

        # ====================================================================
        # UNIT TESTS - Option extraction
        # ====================================================================

        Test.@testset "Option extraction" begin
            Test.@testset "extract_option" begin
                opt_def = Options.OptionDefinition(
                    name=:test_option,
                    type=Int,
                    default=42,
                    description="Test option",
                    aliases=(:alias1, :alias2),
                )

                # Test extraction by primary name
                options = (test_option=100,)
                opt_value, remaining = Options.extract_option(options, opt_def)
                Test.@test opt_value isa Options.OptionValue
                Test.@test opt_value.value == 100
                Test.@test opt_value.source == :user
                Test.@test remaining isa NamedTuple

                # Test extraction by alias
                options = (alias1=200,)
                opt_value, remaining = Options.extract_option(options, opt_def)
                Test.@test opt_value isa Options.OptionValue
                Test.@test opt_value.value == 200
                Test.@test opt_value.source == :user
                Test.@test remaining isa NamedTuple

                # Test default when not provided
                options = NamedTuple()
                opt_value, remaining = Options.extract_option(options, opt_def)
                Test.@test opt_value isa Options.OptionValue
                Test.@test opt_value.value == 42
                Test.@test opt_value.source == :default
                Test.@test remaining isa NamedTuple

                # Test NotProvided when no default
                opt_def_no_default = Options.OptionDefinition(
                    name=:required_option,
                    type=Int,
                    default=Options.NotProvided,
                    description="Required option",
                )
                options = NamedTuple()
                opt_value, remaining = Options.extract_option(options, opt_def_no_default)
                Test.@test opt_value isa Options.NotStoredType
                Test.@test remaining isa NamedTuple
            end

            Test.@testset "extract_options" begin
                opt_defs = [
                    Options.OptionDefinition(
                        name=:option1, type=Int, default=1, description="First option"
                    ),
                    Options.OptionDefinition(
                        name=:option2,
                        type=String,
                        default="default",
                        description="Second option",
                    ),
                    Options.OptionDefinition(
                        name=:option3,
                        type=Float64,
                        default=Options.NotProvided,
                        description="Third option (required)",
                    ),
                ]

                # Test with all options provided
                options = (option1=10, option2="custom", option3=3.14)
                extracted, remaining = Options.extract_options(options, opt_defs)
                Test.@test extracted[:option1] isa Options.OptionValue
                Test.@test extracted[:option1].value == 10
                Test.@test extracted[:option2] isa Options.OptionValue
                Test.@test extracted[:option2].value == "custom"
                Test.@test extracted[:option3] isa Options.OptionValue
                Test.@test extracted[:option3].value == 3.14
                Test.@test remaining isa NamedTuple

                # Test with some defaults
                options = (option3=2.71,)
                extracted, remaining = Options.extract_options(options, opt_defs)
                Test.@test extracted[:option1].value == 1  # default
                Test.@test extracted[:option2].value == "default"  # default
                Test.@test extracted[:option3].value == 2.71  # provided
                Test.@test remaining isa NamedTuple
            end
        end
    end
end

end # module

test_options() = TestOptions.test_options()
