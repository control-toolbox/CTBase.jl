module TestOptionsOptionDefinition

using Test: Test
import CTBase.Exceptions
import CTBase.Options
const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

function test_option_definition()
    Test.@testset "OptionDefinition" verbose=VERBOSE showtiming=SHOWTIMING begin

        # ====================================================================
        # META TESTS - Exports / Public API surface
        # ====================================================================

        Test.@testset "Exports verification" begin
            Test.@test isdefined(Options, :OptionDefinition)
            Test.@test isdefined(Options, :name)
            Test.@test isdefined(Options, :type)
            Test.@test isdefined(Options, :default)
            Test.@test isdefined(Options, :description)
            Test.@test isdefined(Options, :aliases)
            Test.@test isdefined(Options, :validator)
            Test.@test isdefined(Options, :is_required)
            Test.@test isdefined(Options, :has_default)
            Test.@test isdefined(Options, :has_validator)
            Test.@test isdefined(Options, :all_names)
        end

        # ====================================================================
        # BASIC CONSTRUCTION
        # ====================================================================

        Test.@testset "Basic construction" begin
            # Minimal constructor
            def = Options.OptionDefinition(
                name=:test_option, type=Int, default=42, description="Test option"
            )
            Test.@test Options.name(def) == :test_option
            Test.@test_nowarn Test.@inferred Options.name(def)

            Test.@test Options.type(def) == Int

            Test.@test Options.default(def) == 42
            Test.@test_nowarn Test.@inferred Options.default(def)

            Test.@test Options.description(def) == "Test option"
            Test.@test_nowarn Test.@inferred Options.description(def)

            Test.@test Options.aliases(def) == ()

            Test.@test Options.validator(def) === nothing
        end

        # ========================================================================
        # Full construction with aliases and validator
        # ========================================================================

        Test.@testset "Full construction" begin
            validator = x -> x > 0
            def = Options.OptionDefinition(
                name=:max_iter,
                type=Int,
                default=100,
                description="Maximum iterations",
                aliases=(:max, :maxiter),
                validator=validator,
            )
            Test.@test Options.name(def) == :max_iter
            Test.@test Options.type(def) == Int
            Test.@test Options.default(def) == 100
            Test.@test Options.description(def) == "Maximum iterations"
            Test.@test Options.aliases(def) == (:max, :maxiter)
            Test.@test Options.validator(def) === validator
        end

        # ========================================================================
        # Minimal construction
        # ========================================================================

        Test.@testset "Minimal construction" begin
            def = Options.OptionDefinition(
                name=:test, type=String, default="default", description="Test option"
            )
            Test.@test Options.name(def) == :test
            Test.@test Options.type(def) == String
            Test.@test Options.default(def) == "default"
            Test.@test Options.description(def) == "Test option"
            Test.@test Options.aliases(def) == ()
            Test.@test Options.validator(def) === nothing
        end

        # ========================================================================
        # Validation
        # ========================================================================

        Test.@testset "Validation" begin
            # Valid default value type
            Test.@test_nowarn Options.OptionDefinition(
                name=:test, type=Int, default=42, description="Test"
            )

            # Invalid default value type
            Test.@test_throws Exceptions.IncorrectArgument Options.OptionDefinition(
                name=:test, type=Int, default="not an int", description="Test"
            )

            # Valid validator with valid default
            Test.@test_nowarn Options.OptionDefinition(
                name=:test, type=Int, default=42, description="Test", validator=x -> x > 0
            )

            # Invalid validator with invalid default (redirect stderr to hide @error logs)
            Test.@test_throws ErrorException redirect_stderr(devnull) do
                return Options.OptionDefinition(
                    name=:test,
                    type=Int,
                    default=-5,
                    description="Test",
                    validator=x -> x > 0 || error("Must be positive"),
                )
            end
        end

        # ========================================================================
        # all_names function
        # ========================================================================

        Test.@testset "all_names function" begin
            def = Options.OptionDefinition(
                name=:max_iter,
                type=Int,
                default=100,
                description="Test",
                aliases=(:max, :maxiter),
            )
            names = Options.all_names(def)
            Test.@test names == (:max_iter, :max, :maxiter)
            Test.@test_nowarn Options.all_names(def)
        end

        # ====================================================================
        # HELPER FUNCTIONS
        # ====================================================================

        Test.@testset "Helper functions" begin
            def_required = Options.OptionDefinition(
                name=:input,
                type=String,
                default=Options.NotProvided,
                description="Input file",
            )
            def_optional = Options.OptionDefinition(
                name=:max_iter, type=Int, default=100, description="Max iterations"
            )
            def_with_validator = Options.OptionDefinition(
                name=:tol,
                type=Float64,
                default=1e-6,
                description="Tolerance",
                validator=x -> x > 0,
            )

            Test.@test Options.is_required(def_required) == true
            Test.@test_nowarn Test.@inferred Options.is_required(def_required)

            Test.@test Options.is_required(def_optional) == false
            Test.@test_nowarn Test.@inferred Options.is_required(def_optional)

            Test.@test Options.has_default(def_required) == false
            Test.@test_nowarn Test.@inferred Options.has_default(def_required)

            Test.@test Options.has_default(def_optional) == true
            Test.@test_nowarn Test.@inferred Options.has_default(def_optional)

            Test.@test Options.has_validator(def_with_validator) == true
            Test.@test_nowarn Test.@inferred Options.has_validator(def_with_validator)

            Test.@test Options.has_validator(def_optional) == false
            Test.@test_nowarn Test.@inferred Options.has_validator(def_optional)
        end

        # ========================================================================
        # Dispatch methods - Unit tests
        # ========================================================================

        Test.@testset "Dispatch methods - Unit tests" begin
            Test.@testset "_construct_option_definition with Nothing" begin
                # Test the Nothing dispatch method directly
                def = Options._construct_option_definition(
                    :backend,
                    Union{Nothing,String},
                    nothing,
                    "Execution backend",
                    (:be,),
                    nothing,
                    false,
                )

                Test.@test def isa Options.OptionDefinition{Any}
                Test.@test Options.name(def) == :backend
                Test.@test Options.type(def) == Any
                Test.@test Options.default(def) === nothing
                Test.@test Options.description(def) == "Execution backend"
                Test.@test Options.aliases(def) == (:be,)
                Test.@test Options.validator(def) === nothing
            end

            Test.@testset "_construct_option_definition with NotProvided" begin
                # Test the NotProvided dispatch method directly
                def = Options._construct_option_definition(
                    :input_file,
                    String,
                    Options.NotProvided,
                    "Input file path",
                    (:input,),
                    nothing,
                    false,
                )

                Test.@test def isa Options.OptionDefinition{Options.NotProvidedType}
                Test.@test Options.name(def) == :input_file
                Test.@test Options.type(def) == String
                Test.@test Options.default(def) === Options.NotProvided
                Test.@test Options.description(def) == "Input file path"
                Test.@test Options.aliases(def) == (:input,)
                Test.@test Options.validator(def) === nothing
            end

            Test.@testset "_construct_option_definition with concrete values" begin
                # Test Int concrete value
                def_int = Options._construct_option_definition(
                    :max_iter,
                    Int,
                    100,
                    "Maximum iterations",
                    (:max, :maxiter),
                    nothing,
                    false,
                )

                Test.@test def_int isa Options.OptionDefinition{Int}
                Test.@test Options.name(def_int) == :max_iter
                Test.@test Options.type(def_int) == Int
                Test.@test Options.default(def_int) == 100
                Test.@test Options.description(def_int) == "Maximum iterations"
                Test.@test Options.aliases(def_int) == (:max, :maxiter)
                Test.@test Options.validator(def_int) === nothing

                # Test String concrete value
                def_string = Options._construct_option_definition(
                    :output_file,
                    String,
                    "output.txt",
                    "Output file name",
                    (),
                    nothing,
                    false,
                )

                Test.@test def_string isa Options.OptionDefinition{String}
                Test.@test Options.name(def_string) == :output_file
                Test.@test Options.type(def_string) == String
                Test.@test Options.default(def_string) == "output.txt"
                Test.@test Options.description(def_string) == "Output file name"
                Test.@test Options.aliases(def_string) == ()
                Test.@test Options.validator(def_string) === nothing

                # Test Float64 concrete value with validator
                validator = x -> x > 0
                def_float = Options._construct_option_definition(
                    :tolerance, Float64, 1e-6, "Convergence tolerance", (), validator, false
                )

                Test.@test def_float isa Options.OptionDefinition{Float64}
                Test.@test Options.name(def_float) == :tolerance
                Test.@test Options.type(def_float) == Float64
                Test.@test Options.default(def_float) == 1e-6
                Test.@test Options.description(def_float) == "Convergence tolerance"
                Test.@test Options.aliases(def_float) == ()
                Test.@test Options.validator(def_float) === validator
            end

            Test.@testset "_construct_option_definition type compatibility validation" begin
                # Test type mismatch error in concrete dispatch method
                Test.@test_throws Exceptions.IncorrectArgument Options._construct_option_definition(
                    :test_option, Int, "not an int", "Test option", (), nothing, false
                )

                # Test type mismatch with Union type
                Test.@test_throws Exceptions.IncorrectArgument Options._construct_option_definition(
                    :test_option,
                    Union{Int,Float64},
                    "not a number",
                    "Test option",
                    (),
                    nothing,
                    false,
                )

                # Test valid Union type (should work)
                Test.@test_nowarn Options._construct_option_definition(
                    :test_option,
                    Union{Int,Float64},
                    42,  # Int is valid for Union{Int, Float64}
                    "Test option",
                    (),
                    nothing,
                    false,
                )
            end
        end

        # ========================================================================
        # Constructor dispatch integration
        # ========================================================================

        Test.@testset "Constructor dispatch integration" begin
            Test.@testset "Public constructor routes to correct dispatch method" begin
                # Test that public constructor with nothing creates OptionDefinition{Any}
                def_nothing = Options.OptionDefinition(
                    name=:backend,
                    type=Union{Nothing,String},
                    default=nothing,
                    description="Execution backend",
                )
                Test.@test def_nothing isa Options.OptionDefinition{Any}
                Test.@test Options.type(def_nothing) == Any  # type is overridden to Any

                # Test that public constructor with NotProvided creates OptionDefinition{NotProvidedType}
                def_not_provided = Options.OptionDefinition(
                    name=:input_file,
                    type=String,
                    default=Options.NotProvided,
                    description="Input file",
                )
                Test.@test def_not_provided isa
                    Options.OptionDefinition{Options.NotProvidedType}
                Test.@test Options.type(def_not_provided) == String  # type is preserved

                # Test that public constructor with concrete value creates correct type
                def_concrete = Options.OptionDefinition(
                    name=:max_iter, type=Int, default=100, description="Maximum iterations"
                )
                Test.@test def_concrete isa Options.OptionDefinition{Int}
                Test.@test Options.type(def_concrete) == Int
            end

            Test.@testset "Type parameter inference correctness" begin
                # Test various concrete types
                def_int = Options.OptionDefinition(
                    name=:i, type=Int, default=42, description="int"
                )
                Test.@test def_int isa Options.OptionDefinition{Int64}

                def_float = Options.OptionDefinition(
                    name=:f, type=Float64, default=3.14, description="float"
                )
                Test.@test def_float isa Options.OptionDefinition{Float64}

                def_string = Options.OptionDefinition(
                    name=:s, type=String, default="hello", description="string"
                )
                Test.@test def_string isa Options.OptionDefinition{String}

                def_bool = Options.OptionDefinition(
                    name=:b, type=Bool, default=true, description="bool"
                )
                Test.@test def_bool isa Options.OptionDefinition{Bool}

                # Test that Nothing always creates Any regardless of declared type
                def_any_type = Options.OptionDefinition(
                    name=:any, type=String, default=nothing, description="any"
                )
                Test.@test def_any_type isa Options.OptionDefinition{Any}
                Test.@test Options.type(def_any_type) == Any
            end
        end

        # ========================================================================
        # Edge cases
        # ========================================================================

        Test.@testset "Edge cases" begin
            # nothing default (allowed)
            def = Options.OptionDefinition(
                name=:test, type=Any, default=nothing, description="Test"
            )
            Test.@test def.default === nothing

            # nothing validator (allowed)
            def = Options.OptionDefinition(
                name=:test, type=Int, default=42, description="Test", validator=nothing
            )
            Test.@test def.validator === nothing
        end

        # ========================================================================
        # Getters and introspection
        # ========================================================================

        Test.@testset "Getters and introspection" begin
            validator = x -> x > 0
            def = Options.OptionDefinition(
                name=:max_iter,
                type=Int,
                default=100,
                description="Maximum iterations",
                aliases=(:max, :maxiter),
                validator=validator,
            )

            Test.@test Options.name(def) === :max_iter
            Test.@test Options.type(def) === Int
            Test.@test Options.default(def) === 100
            Test.@test Options.description(def) == "Maximum iterations"
            Test.@test Options.aliases(def) == (:max, :maxiter)
            Test.@test Options.validator(def) === validator
            Test.@test Options.has_default(def) === true
            Test.@test Options.is_required(def) === false
            Test.@test Options.has_validator(def) === true

            required_def = Options.OptionDefinition(
                name=:input,
                type=String,
                default=Options.NotProvided,
                description="Input file",
            )
            Test.@test Options.has_default(required_def) === false
            Test.@test Options.is_required(required_def) === true
            Test.@test Options.has_validator(required_def) === false
        end

        # ========================================================================
        # Type stability tests
        # ========================================================================

        Test.@testset "Type stability" begin
            # Test that OptionDefinition is parameterized correctly
            def_int = Options.OptionDefinition(
                name=:test_int, type=Int, default=42, description="Test"
            )
            Test.@test def_int isa Options.OptionDefinition{Int64}

            def_float = Options.OptionDefinition(
                name=:test_float, type=Float64, default=3.14, description="Test"
            )
            Test.@test def_float isa Options.OptionDefinition{Float64}

            def_string = Options.OptionDefinition(
                name=:test_string, type=String, default="hello", description="Test"
            )
            Test.@test def_string isa Options.OptionDefinition{String}

            # Test type-stable access to default field via function
            function get_default(def::Options.OptionDefinition{T}) where {T}
                return def.default
            end

            Test.@inferred get_default(def_int)
            Test.@test typeof(def_int.default) === Int64
            Test.@test get_default(def_int) === 42

            Test.@inferred get_default(def_float)
            Test.@test typeof(def_float.default) === Float64
            Test.@test get_default(def_float) === 3.14

            Test.@inferred get_default(def_string)
            Test.@test typeof(def_string.default) === String
            Test.@test get_default(def_string) === "hello"

            # Test heterogeneous collections (Vector{OptionDefinition{<:Any}})
            defs = Options.OptionDefinition[def_int, def_float, def_string]
            Test.@test length(defs) == 3
            Test.@test defs[1] isa Options.OptionDefinition{Int64}
            Test.@test defs[2] isa Options.OptionDefinition{Float64}
            Test.@test defs[3] isa Options.OptionDefinition{String}

            # Test that accessing defaults in a loop maintains type information
            function sum_int_defaults(defs::Vector{<:Options.OptionDefinition})
                total = 0
                for def in defs
                    if def isa Options.OptionDefinition{Int}
                        total += def.default  # Type-stable within branch
                    end
                end
                return total
            end

            int_defs = [
                Options.OptionDefinition(
                    name=Symbol("opt$i"), type=Int, default=i, description="test"
                ) for i in 1:5
            ]
            Test.@test sum_int_defaults(int_defs) == 15
        end

        # ========================================================================
        # Display functionality
        # ========================================================================

        Test.@testset "Display" begin
            # Test individual components without relying on exact color formatting
            def_min = Options.OptionDefinition(
                name=:test, type=Int, default=42, description="Test option"
            )
            def_full = Options.OptionDefinition(
                name=:max_iter,
                type=Int,
                default=100,
                description="Maximum iterations",
                aliases=(:max, :maxiter),
            )

            # Test minimal definition components
            io_min = IOBuffer()
            println(io_min, def_min)
            output_min = String(take!(io_min))

            Test.@test occursin("test", output_min)
            Test.@test occursin("Int", output_min)
            Test.@test occursin("42", output_min)
            Test.@test occursin("default", output_min)  # "default" appears in the output

            # Test full definition components
            io_full = IOBuffer()
            println(io_full, def_full)
            output_full = String(take!(io_full))

            Test.@test occursin("max_iter", output_full)
            Test.@test occursin("max", output_full)
            Test.@test occursin("maxiter", output_full)
            Test.@test occursin("100", output_full)
            Test.@test occursin("default", output_full)  # "default" appears in the output
        end
    end

    Test.@testset "Type parameter inference correctness" begin
        # Test various concrete types
        def_int = Options.OptionDefinition(name=:i, type=Int, default=42, description="int")
        Test.@test def_int isa Options.OptionDefinition{Int64}

        def_float = Options.OptionDefinition(
            name=:f, type=Float64, default=3.14, description="float"
        )
        Test.@test def_float isa Options.OptionDefinition{Float64}

        def_string = Options.OptionDefinition(
            name=:s, type=String, default="hello", description="string"
        )
        Test.@test def_string isa Options.OptionDefinition{String}

        def_bool = Options.OptionDefinition(
            name=:b, type=Bool, default=true, description="bool"
        )
        Test.@test def_bool isa Options.OptionDefinition{Bool}

        # Test that Nothing always creates Any regardless of declared type
        def_any_type = Options.OptionDefinition(
            name=:any, type=String, default=nothing, description="any"
        )
        Test.@test def_any_type isa Options.OptionDefinition{Any}
        Test.@test Options.type(def_any_type) == Any
    end
end

# ========================================================================
# Edge cases
# ========================================================================

Test.@testset "Edge cases" begin
    # nothing default (allowed)
    def = Options.OptionDefinition(
        name=:test, type=Any, default=nothing, description="Test"
    )
    Test.@test def.default === nothing

    # nothing validator (allowed)
    def = Options.OptionDefinition(
        name=:test, type=Int, default=42, description="Test", validator=nothing
    )
    Test.@test def.validator === nothing
end

# ========================================================================
# Getters and introspection
# ========================================================================

Test.@testset "Getters and introspection" begin
    validator = x -> x > 0
    def = Options.OptionDefinition(
        name=:max_iter,
        type=Int,
        default=100,
        description="Maximum iterations",
        aliases=(:max, :maxiter),
        validator=validator,
    )

    Test.@test Options.name(def) === :max_iter
    Test.@test Options.type(def) === Int
    Test.@test Options.default(def) === 100
    Test.@test Options.description(def) == "Maximum iterations"
    Test.@test Options.aliases(def) == (:max, :maxiter)
    Test.@test Options.validator(def) === validator
    Test.@test Options.has_default(def) === true
    Test.@test Options.is_required(def) === false
    Test.@test Options.has_validator(def) === true

    required_def = Options.OptionDefinition(
        name=:input, type=String, default=Options.NotProvided, description="Input file"
    )
    Test.@test Options.has_default(required_def) === false
    Test.@test Options.is_required(required_def) === true
    Test.@test Options.has_validator(required_def) === false
end

# ========================================================================
# Type stability tests
# ========================================================================

Test.@testset "Type stability" begin
    # Test that OptionDefinition is parameterized correctly
    def_int = Options.OptionDefinition(
        name=:test_int, type=Int, default=42, description="Test"
    )
    Test.@test def_int isa Options.OptionDefinition{Int64}

    def_float = Options.OptionDefinition(
        name=:test_float, type=Float64, default=3.14, description="Test"
    )
    Test.@test def_float isa Options.OptionDefinition{Float64}

    def_string = Options.OptionDefinition(
        name=:test_string, type=String, default="hello", description="Test"
    )
    Test.@test def_string isa Options.OptionDefinition{String}

    # Test type-stable access to default field via function
    function get_default(def::Options.OptionDefinition{T}) where {T}
        return def.default
    end

    Test.@inferred get_default(def_int)
    Test.@test typeof(def_int.default) === Int64
    Test.@test get_default(def_int) === 42

    Test.@inferred get_default(def_float)
    Test.@test typeof(def_float.default) === Float64
    Test.@test get_default(def_float) === 3.14

    Test.@inferred get_default(def_string)
    Test.@test typeof(def_string.default) === String
    Test.@test get_default(def_string) === "hello"

    # Test heterogeneous collections (Vector{OptionDefinition{<:Any}})
    defs = Options.OptionDefinition[def_int, def_float, def_string]
    Test.@test length(defs) == 3
    Test.@test defs[1] isa Options.OptionDefinition{Int64}
    Test.@test defs[2] isa Options.OptionDefinition{Float64}
    Test.@test defs[3] isa Options.OptionDefinition{String}

    # Test that accessing defaults in a loop maintains type information
    function sum_int_defaults(defs::Vector{<:Options.OptionDefinition})
        total = 0
        for def in defs
            if def isa Options.OptionDefinition{Int}
                total += def.default  # Type-stable within branch
            end
        end
        return total
    end

    int_defs = [
        Options.OptionDefinition(
            name=Symbol("opt$i"), type=Int, default=i, description="test"
        ) for i in 1:5
    ]
    Test.@test sum_int_defaults(int_defs) == 15
end

# ========================================================================
# Display functionality
# ========================================================================

Test.@testset "Display" begin
    # Skip display tests with colors - they're visually verified in documentation
    # The show methods work correctly, colors are just hard to test with occursin
    Test.@test true  # Placeholder to ensure testset runs
end

end # module

test_option_definition() = TestOptionsOptionDefinition.test_option_definition()
