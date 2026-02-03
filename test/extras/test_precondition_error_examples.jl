"""
Demo module for realistic PreconditionError examples.

This module demonstrates how PreconditionError should be used for
precondition validation and order-of-operations errors, as opposed to
precondition validation and order-of-operations errors.
"""
module TestPreconditionErrorExamples

using Test
using CTBase

"""
Demo module for realistic PreconditionError examples.
"""
module DemoSystemBuilder
    using CTBase

    """
    State tracking for system initialization.
    """
    mutable struct SystemState
        initialized::Bool
        configured::Bool
        built::Bool
        finalized::Bool

        SystemState() = new(false, false, false, false)
    end

    """
    Initialize the system.
    """
    function initialize!(state::SystemState)
        if state.initialized
            throw(
                CTBase.PreconditionError(
                    "System already initialized";
                    reason="initialize! can only be called once",
                    suggestion="Create a new SystemState instance",
                    context="system initialization",
                ),
            )
        end
        state.initialized = true
        return println("🔧 System initialized")
    end

    """
    Configure the system (requires initialization first).
    """
    function configure!(state::SystemState, config::Dict)
        if !state.initialized
            throw(
                CTBase.PreconditionError(
                    "System must be initialized before configuration";
                    reason="initialize! not called yet",
                    suggestion="Call initialize!(state) before configure!",
                    context="system configuration",
                ),
            )
        end

        if state.configured
            throw(
                CTBase.PreconditionError(
                    "System already configured";
                    reason="configure! can only be called once",
                    suggestion="Create a new SystemState instance or reset configuration",
                    context="system configuration",
                ),
            )
        end

        state.configured = true
        return println("⚙️  System configured with $(length(config)) settings")
    end

    """
    Build the system (requires initialization and configuration).
    """
    function build!(state::SystemState, components::Vector{String})
        if !state.initialized
            throw(
                CTBase.PreconditionError(
                    "System must be initialized before building";
                    reason="initialize! not called yet",
                    suggestion="Call initialize!(state) before build!",
                    context="system building",
                ),
            )
        end

        if !state.configured
            throw(
                CTBase.PreconditionError(
                    "System must be configured before building";
                    reason="configure! not called yet",
                    suggestion="Call configure!(state, config) before build!",
                    context="system building",
                ),
            )
        end

        if state.built
            throw(
                CTBase.PreconditionError(
                    "System already built";
                    reason="build! can only be called once",
                    suggestion="Create a new SystemState instance or reset system",
                    context="system building",
                ),
            )
        end

        state.built = true
        return println("🏗️  System built with components: $(join(components, ", "))")
    end

    """
    Finalize the system (requires building first).
    """
    function finalize!(state::SystemState)
        if !state.built
            throw(
                CTBase.PreconditionError(
                    "System must be built before finalization";
                    reason="build! not called yet",
                    suggestion="Call build!(state, components) before finalize!",
                    context="system finalization",
                ),
            )
        end

        if state.finalized
            throw(
                CTBase.PreconditionError(
                    "System already finalized";
                    reason="finalize! can only be called once",
                    suggestion="Create a new SystemState instance",
                    context="system finalization",
                ),
            )
        end

        state.finalized = true
        return println("✅ System finalized successfully")
    end

    """
    Reset the system (can be called anytime).
    """
    function reset!(state::SystemState)
        state.initialized = false
        state.configured = false
        state.built = false
        state.finalized = false
        return println("🔄 System reset")
    end
end

"""
Demo module for mathematical computation with validation.
"""
module DemoMathProcessor
    using CTBase

    """
    Mathematical computation state.
    """
    mutable struct ComputationState
        data_loaded::Bool
        parameters_set::Bool
        validated::Bool
        computed::Bool

        ComputationState() = new(false, false, false, false)
    end

    """
    Load data (first step).
    """
    function load_data!(state::ComputationState, data::Vector{Float64})
        if state.data_loaded
            throw(
                CTBase.PreconditionError(
                    "Data already loaded";
                    reason="load_data! can only be called once per computation",
                    suggestion="Create new ComputationState or reset with reset!(state)",
                    context="data loading",
                ),
            )
        end

        if isempty(data)
            throw(
                CTBase.PreconditionError(
                    "Cannot load empty data";
                    reason="data vector is empty",
                    suggestion="Provide non-empty data vector",
                    context="data loading",
                ),
            )
        end

        state.data_loaded = true
        return println("📊 Loaded $(length(data)) data points")
    end

    """
    Set parameters (requires data loaded).
    """
    function set_parameters!(state::ComputationState, params::Dict{Symbol,Any})
        if !state.data_loaded
            throw(
                CTBase.PreconditionError(
                    "Data must be loaded before setting parameters";
                    reason="load_data! not called yet",
                    suggestion="Call load_data!(state, data) before set_parameters!",
                    context="parameter setting",
                ),
            )
        end

        if state.parameters_set
            throw(
                CTBase.PreconditionError(
                    "Parameters already set";
                    reason="set_parameters! can only be called once per computation",
                    suggestion="Create new ComputationState or reset with reset!(state)",
                    context="parameter setting",
                ),
            )
        end

        state.parameters_set = true
        return println("⚙️  Parameters set: $(join(keys(params), ", "))")
    end

    """
    Validate computation (requires data and parameters).
    """
    function validate!(state::ComputationState)
        if !state.data_loaded
            throw(
                CTBase.PreconditionError(
                    "Cannot validate without data";
                    reason="load_data! not called yet",
                    suggestion="Call load_data!(state, data) before validate!",
                    context="computation validation",
                ),
            )
        end

        if !state.parameters_set
            throw(
                CTBase.PreconditionError(
                    "Cannot validate without parameters";
                    reason="set_parameters! not called yet",
                    suggestion="Call set_parameters!(state, params) before validate!",
                    context="computation validation",
                ),
            )
        end

        if state.validated
            throw(
                CTBase.PreconditionError(
                    "Computation already validated";
                    reason="validate! can only be called once per computation",
                    suggestion="Create new ComputationState or reset with reset!(state)",
                    context="computation validation",
                ),
            )
        end

        state.validated = true
        return println("✅ Computation validated")
    end

    """
    Compute results (requires validation).
    """
    function compute!(state::ComputationState)
        if !state.validated
            throw(
                CTBase.PreconditionError(
                    "Cannot compute without validation";
                    reason="validate! not called yet",
                    suggestion="Call validate!(state) before compute!",
                    context="computation",
                ),
            )
        end

        if state.computed
            throw(
                CTBase.PreconditionError(
                    "Computation already performed";
                    reason="compute! can only be called once per computation",
                    suggestion="Create new ComputationState or reset with reset!(state)",
                    context="computation",
                ),
            )
        end

        state.computed = true
        return println("🧮 Computation completed")
    end

    """
    Reset computation state.
    """
    function reset!(state::ComputationState)
        state.data_loaded = false
        state.parameters_set = false
        state.validated = false
        state.computed = false
        return println("🔄 Computation state reset")
    end
end

"""
Demo module for file processing with validation.
"""
module DemoFileProcessor
    using CTBase

    """
    File processing state.
    """
    mutable struct FileProcessingState
        file_opened::Bool
        headers_parsed::Bool
        data_processed::Bool
        results_written::Bool

        FileProcessingState() = new(false, false, false, false)
    end

    """
    Open file (first step).
    """
    function open_file!(state::FileProcessingState, filename::String)
        if state.file_opened
            throw(
                CTBase.PreconditionError(
                    "File already open";
                    reason="open_file! can only be called once per file",
                    suggestion="Close current file or create new FileProcessingState",
                    context="file processing",
                ),
            )
        end

        if !isfile(filename)
            throw(
                CTBase.PreconditionError(
                    "File does not exist";
                    reason="file not found at path",
                    suggestion="Check file path and ensure file exists",
                    context="file opening",
                ),
            )
        end

        state.file_opened = true
        return println("📁 Opened file: $filename")
    end

    """
    Parse headers (requires file open).
    """
    function parse_headers!(state::FileProcessingState, content::String)
        if !state.file_opened
            throw(
                CTBase.PreconditionError(
                    "Cannot parse headers without opening file";
                    reason="open_file! not called yet",
                    suggestion="Call open_file!(state, filename) before parse_headers!",
                    #context="header parsing",
                ),
            )
        end

        if state.headers_parsed
            throw(
                CTBase.PreconditionError(
                    "Headers already parsed";
                    reason="parse_headers! can only be called once per file",
                    suggestion="Create new FileProcessingState or reset with reset!(state)",
                    #context="header parsing",
                ),
            )
        end

        if isempty(content)
            throw(
                CTBase.PreconditionError(
                    "Cannot parse empty content";
                    reason="content string is empty",
                    suggestion="Provide non-empty content to parse",
                    #context="header parsing",
                ),
            )
        end

        state.headers_parsed = true
        return println("📋 Headers parsed")
    end

    """
    Process data (requires headers parsed).
    """
    function process_data!(state::FileProcessingState, data::Vector{String})
        if !state.headers_parsed
            throw(
                CTBase.PreconditionError(
                    "Cannot process data without parsing headers";
                    reason="parse_headers! not called yet",
                    suggestion="Call parse_headers!(state, content) before process_data!",
                    context="data processing",
                ),
            )
        end

        if state.data_processed
            throw(
                CTBase.PreconditionError(
                    "Data already processed";
                    reason="process_data! can only be called once per file",
                    suggestion="Create new FileProcessingState or reset with reset!(state)",
                    context="data processing",
                ),
            )
        end

        if isempty(data)
            throw(
                CTBase.PreconditionError(
                    "Cannot process empty data";
                    reason="data array is empty",
                    suggestion="Provide non-empty data to process",
                    context="data processing",
                ),
            )
        end

        state.data_processed = true
        return println("🔄 Processed $(length(data)) data items")
    end

    """
    Write results (requires data processed).
    """
    function write_results!(state::FileProcessingState, results::String)
        if !state.data_processed
            throw(
                CTBase.PreconditionError(
                    "Cannot write results without processing data";
                    reason="process_data! not called yet",
                    suggestion="Call process_data!(state, data) before write_results!",
                    context="result writing",
                ),
            )
        end

        if state.results_written
            throw(
                CTBase.PreconditionError(
                    "Results already written";
                    reason="write_results! can only be called once per file",
                    suggestion="Create new FileProcessingState or reset with reset!(state)",
                    context="result writing",
                ),
            )
        end

        if isempty(results)
            throw(
                CTBase.PreconditionError(
                    "Cannot write empty results";
                    reason="results string is empty",
                    suggestion="Provide non-empty results to write",
                    context="result writing",
                ),
            )
        end

        state.results_written = true
        return println("💾 Results written")
    end

    """
    Reset file processing state.
    """
    function reset!(state::FileProcessingState)
        state.file_opened = false
        state.headers_parsed = false
        state.data_processed = false
        state.results_written = false
        return println("🔄 File processing state reset")
    end
end

"""
Run PreconditionError examples to demonstrate enriched exception handling.
"""
function test_precondition_error_examples()
    println("🔍 PreconditionError Examples")
    println("="^50)

    # Example 1: System Builder - Correct Order
    println("\n🏗️  Example 1: System Builder - Correct Order")
    println("─"^40)

    system = DemoSystemBuilder.SystemState()
    try
        DemoSystemBuilder.initialize!(system)
        DemoSystemBuilder.configure!(system, Dict("timeout" => 30, "retries" => 3))
        DemoSystemBuilder.build!(system, ["database", "cache", "api"])
        DemoSystemBuilder.finalize!(system)
        println("✅ System built successfully!")
    catch e
        showerror(stdout, e)
        println()
    end

    # Example 2: System Builder - Wrong Order (Initialize Twice)
    println("\n🚫 Example 2: System Builder - Wrong Order (Initialize Twice)")
    println("─"^40)

    system2 = DemoSystemBuilder.SystemState()
    try
        DemoSystemBuilder.initialize!(system2)
        DemoSystemBuilder.initialize!(system2)  # This should fail
        println("✅ Should not reach here")
    catch e
        showerror(stdout, e)
        println()
    end

    # Example 3: System Builder - Missing Precondition (Configure without Initialize)
    println(
        "\n⚠️  Example 3: System Builder - Missing Precondition (Configure without Initialize)",
    )
    println("─"^40)

    system3 = DemoSystemBuilder.SystemState()
    try
        DemoSystemBuilder.configure!(system3, Dict("timeout" => 30))  # This should fail
        println("✅ Should not reach here")
    catch e
        showerror(stdout, e)
        println()
    end

    # Example 4: Math Processor - Complete Workflow
    println("\n🧮  Example 4: Math Processor - Complete Workflow")
    println("─"^40)

    comp_state = DemoMathProcessor.ComputationState()
    try
        DemoMathProcessor.load_data!(comp_state, [1.0, 2.0, 3.0, 4.0, 5.0])
        DemoMathProcessor.set_parameters!(
            comp_state, Dict{Symbol,Any}(:alpha => 0.1, :beta => 0.2)
        )
        DemoMathProcessor.validate!(comp_state)
        DemoMathProcessor.compute!(comp_state)
        println("✅ Computation completed successfully!")
    catch e
        showerror(stdout, e)
        println()
    end

    # Example 5: Math Processor - Wrong Order (Compute without Validation)
    println("\n❌ Example 5: Math Processor - Wrong Order (Compute without Validation)")
    println("─"^40)

    comp_state2 = DemoMathProcessor.ComputationState()
    try
        DemoMathProcessor.load_data!(comp_state2, [1.0, 2.0, 3.0])
        DemoMathProcessor.set_parameters!(comp_state2, Dict{Symbol,Any}(:alpha => 0.1))
        DemoMathProcessor.compute!(comp_state2)  # This should fail
        println("✅ Should not reach here")
    catch e
        showerror(stdout, e)
        println()
    end

    # Example 6: File Processor - Step-by-Step Validation
    println("\n📁 Example 6: File Processor - Step-by-Step Validation")
    println("─"^40)

    file_state = DemoFileProcessor.FileProcessingState()
    try
        # Create a temporary file for demonstration
        temp_file = tempname() * ".txt"
        open(temp_file, "w") do io
            println(io, "Header: Value")
            println(io, "Data1: 100")
            println(io, "Data2: 200")
            println(io, "Data3: 300")
        end

        content = read(temp_file, String)
        DemoFileProcessor.open_file!(file_state, temp_file)
        DemoFileProcessor.parse_headers!(file_state, content)
        DemoFileProcessor.process_data!(
            file_state, ["Data1: 100", "Data2: 200", "Data3: 300"]
        )
        DemoFileProcessor.write_results!(file_state, "Processing completed successfully")

        # Clean up
        rm(temp_file)
        println("✅ File processing completed successfully!")
    catch e
        showerror(stdout, e)
        println()
    end

    # Example 7: File Processor - Empty Data Error
    println("\n📭 Example 7: File Processor - Empty Data Error")
    println("─"^40)

    file_state2 = DemoFileProcessor.FileProcessingState()
    try
        DemoFileProcessor.parse_headers!(file_state2, "")  # Empty content should fail
        println("✅ Should not reach here")
    catch e
        showerror(stdout, e)
        println()
    end

    println("\n" * "="^50)
    println("✅ PreconditionError Examples Completed!")
    println()
    println("💡 Key Features Demonstrated:")
    println("   • Clear precondition validation with specific error messages")
    println("   • Helpful suggestions for fixing the problem")
    println("   • Context information for debugging")
    println("   • Proper error handling with try-catch blocks")
    println("   • State management and reset capabilities")
    println()
    println("🎯 Use Cases for PreconditionError:")
    println("   • System initialization and configuration order")
    println("   • Mathematical computation workflows")
    println("   • File processing pipelines")
    println("   • API call sequence validation")
    println("   • Resource lifecycle management")

    return nothing
end

end # module

# Export for external use
function test_precondition_error_examples()
    return TestPreconditionErrorExamples.test_precondition_error_examples()
end
