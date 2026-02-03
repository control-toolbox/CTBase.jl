module TestExtensionErrorExamples

using Test
using CTBase

# Create subtypes to force ExtensionError throws (using fully qualified names)
struct ForceDocumenterError <: CTBase.Extensions.AbstractDocumenterReferenceTag end
struct ForceCoverageError <: CTBase.Extensions.AbstractCoveragePostprocessingTag end
struct ForceTestRunnerError <: CTBase.Extensions.AbstractTestRunnerTag end

"""
Demo module for realistic ExtensionError examples.
"""
module DemoPluginSystem
    using CTBase
    
    """
    Abstract plugin interface.
    """
    abstract type AbstractPlugin end
    
    """
    Documentation plugin (requires external packages).
    """
    struct DocumentationPlugin <: AbstractPlugin
        name::String
        format::String
    end
    
    """
    Visualization plugin (requires plotting libraries).
    """
    struct VisualizationPlugin <: AbstractPlugin
        name::String
        backend::String
    end
    
    """
    Database plugin (requires DB drivers).
    """
    struct DatabasePlugin <: AbstractPlugin
        name::String
        driver::String
    end
    
    """
    Generate documentation using external tools.
    """
    function generate_docs(plugin::DocumentationPlugin, source_files::Vector{String})
        throw(CTBase.Exceptions.ExtensionError(
            :Documenter, :Markdown, :MarkdownAST;
            feature="automatic documentation generation",
            context="DocumentationPlugin.generate_docs - requires Documenter.jl and related packages"
        ))
    end
    
    """
    Create plots using visualization backend.
    """
    function create_plot(plugin::VisualizationPlugin, data)
        if plugin.backend == "plotly"
            throw(CTBase.Exceptions.ExtensionError(
                :PlotlyJS, :PlotlyBase;
                feature="Plotly.js interactive plotting",
                context="VisualizationPlugin with Plotly backend - requires PlotlyJS.jl and PlotlyBase.jl"
            ))
        elseif plugin.backend == "gr"
            throw(CTBase.Exceptions.ExtensionError(
                :GR;
                feature="GR plotting backend",
                context="VisualizationPlugin with GR backend - requires GR.jl package"
            ))
        else
            throw(CTBase.Exceptions.ExtensionError(
                :Plots;
                feature="general plotting functionality",
                context="VisualizationPlugin - requires Plots.jl package"
            ))
        end
    end
    
    """
    Connect to database using specific driver.
    """
    function connect_to_database(plugin::DatabasePlugin, connection_string::String)
        if plugin.driver == "mysql"
            throw(CTBase.Exceptions.ExtensionError(
                :MySQL;
                feature="MySQL database connectivity",
                context="DatabasePlugin with MySQL driver - requires MySQL.jl package"
            ))
        elseif plugin.driver == "postgresql"
            throw(CTBase.Exceptions.ExtensionError(
                :LibPQ;
                feature="PostgreSQL database connectivity", 
                context="DatabasePlugin with PostgreSQL driver - requires LibPQ.jl package"
            ))
        elseif plugin.driver == "sqlite"
            throw(CTBase.Exceptions.ExtensionError(
                :SQLite;
                feature="SQLite database connectivity",
                context="DatabasePlugin with SQLite driver - requires SQLite.jl package"
            ))
        else
            throw(CTBase.Exceptions.ExtensionError(
                :DBInterface;
                feature="generic database interface",
                context="DatabasePlugin - requires DBInterface.jl and appropriate driver packages"
            ))
        end
    end
    
    """
    Advanced analytics plugin (requires multiple packages).
    """
    struct AdvancedAnalyticsPlugin <: AbstractPlugin
        algorithms::Vector{String}
    end
    
    function run_analysis(plugin::AdvancedAnalyticsPlugin, data, algorithm::String)
        if algorithm == "machine_learning"
            throw(CTBase.Exceptions.ExtensionError(
                :MLJ, :Flux, :DecisionTree;
                feature="machine learning algorithms",
                context="AdvancedAnalyticsPlugin - requires MLJ.jl, Flux.jl, or DecisionTree.jl"
            ))
        elseif algorithm == "statistical_analysis"
            throw(CTBase.Exceptions.ExtensionError(
                :StatsBase, :HypothesisTests;
                feature="statistical analysis tools",
                context="AdvancedAnalyticsPlugin - requires StatsBase.jl and HypothesisTests.jl"
            ))
        else
            throw(CTBase.Exceptions.ExtensionError(
                :Optim, :NLopt;
                feature="optimization algorithms",
                context="AdvancedAnalyticsPlugin - requires Optim.jl or NLopt.jl"
            ))
        end
    end
end

function test_extension_error_examples()
    println("🔍 ExtensionError Examples")
    println("="^50)
    
    # Create test plugins
    doc_plugin = DemoPluginSystem.DocumentationPlugin("DocGen", "html")
    plot_plugin = DemoPluginSystem.VisualizationPlugin("PlotMaker", "plotly")
    db_plugin = DemoPluginSystem.DatabasePlugin("DBConnector", "mysql")
    analytics_plugin = DemoPluginSystem.AdvancedAnalyticsPlugin(["ml", "stats"])
    
    # ====================================================================
    # PART 1: Custom examples (created from scratch)
    # ====================================================================
    
    # Example 1: Documentation generation
    println("\n📚 Example 1: Documentation Generation Extension")
    println("─"^40)
    
    source_files = ["file1.jl", "file2.jl"]
    
    try
        DemoPluginSystem.generate_docs(doc_plugin, source_files)
    catch e
        showerror(stdout, e)
        println()
    end
    
    # Example 2: Visualization plugin
    println("\n📊 Example 2: Visualization Extension")
    println("─"^40)
    
    test_data = [1, 2, 3, 4, 5]
    
    try
        DemoPluginSystem.create_plot(plot_plugin, test_data)
    catch e
        showerror(stdout, e)
        println()
    end
    
    # Example 3: Database connection
    println("\n🗄️ Example 3: Database Extension")
    println("─"^40)
    
    connection_string = "mysql://user:pass@localhost/db"
    
    try
        DemoPluginSystem.connect_to_database(db_plugin, connection_string)
    catch e
        showerror(stdout, e)
        println()
    end
    
    # Example 4: Advanced analytics
    println("\n🧠 Example 4: Advanced Analytics Extension")
    println("─"^40)
    
    try
        DemoPluginSystem.run_analysis(analytics_plugin, test_data, "machine_learning")
    catch e
        showerror(stdout, e)
        println()
    end
    
    # Example 5: Multiple dependencies error
    println("\n🔗 Example 5: Multiple Dependencies Extension")
    println("─"^40)
    
    try
        DemoPluginSystem.run_analysis(analytics_plugin, test_data, "statistical_analysis")
    catch e
        showerror(stdout, e)
        println()
    end
    
    # ====================================================================
    # PART 2: CTBase methods that throw ExtensionError
    # ====================================================================
    
    # Example 6: CTBase automatic_reference_documentation (forced)
    println("\n📖 Example 6: CTBase Automatic Reference Documentation")
    println("─"^40)
    
    try
        CTBase.automatic_reference_documentation(ForceDocumenterError(); subdirectory="api")
    catch e
        showerror(stdout, e)
        println()
    end
    
    # Example 7: CTBase postprocess_coverage (forced)
    println("\n📊 Example 7: CTBase Coverage Postprocessing")
    println("─"^40)
    
    try
        CTBase.postprocess_coverage(ForceCoverageError(); generate_report=true, root_dir=pwd(), dest_dir="coverage")
    catch e
        showerror(stdout, e)
        println()
    end
    
    # Example 8: CTBase run_tests (forced)
    println("\n🧪 Example 8: CTBase Test Runner")
    println("─"^40)
    
    try
        CTBase.run_tests(ForceTestRunnerError(); verbose=true)
    catch e
        showerror(stdout, e)
        println()
    end
    
    # Example 9: CTBase run_tests (default - with extension loaded)
    println("\n🧪 Example 9: CTBase Test Runner (Default - Extension Available)")
    println("─"^40)
    
    # Test that the extension is available by checking if we can create the tag
    try
        tag = CTBase.Extensions.TestRunnerTag()
        println("✅ TestRunner extension is available")
        println("   Created tag: ", typeof(tag))
        println("   This means the extension is loaded and no ExtensionError would be thrown")
    catch e
        showerror(stdout, e)
        println()
    end
    
    return nothing
end

end # module

# Export for external use
test_extension_error_examples() = TestExtensionErrorExamples.test_extension_error_examples()
