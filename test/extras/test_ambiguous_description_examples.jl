module TestAmbiguousDescriptionExamples

using Test
using CTBase

"""
Demo module for realistic AmbiguousDescription examples.
"""
module DemoConfigManager
    using CTBase
    
    # Available configuration descriptions
    const AVAILABLE_CONFIGS = (
        (:optimization, :gradient, :descent),
        (:optimization, :gradient, :newton),
        (:optimization, :hessian, :newton),
        (:simulation, :euler, :explicit),
        (:simulation, :runge, :kutta),
        (:control, :linear, :quadratic),
        (:control, :nonlinear, :mpc),
    )
    
    """
    Find matching configuration description.
    """
    function find_config(symbols...; descriptions=AVAILABLE_CONFIGS)
        return CTBase.complete(symbols...; descriptions=descriptions)
    end
    
    """
    Load configuration by description.
    """
    function load_config(partial_symbols...)
        config_desc = find_config(partial_symbols...)
        println("✅ Configuration found: ", config_desc)
        return config_desc
    end
end

function test_ambiguous_description_examples()
    println("🔍 AmbiguousDescription Examples")
    println("="^50)
    
    # Example 1: Empty catalog
    println("\n📂 Example 1: Empty Configuration Catalog")
    println("─"^40)
    
    try
        CTBase.complete(:test; descriptions=())
    catch e
        showerror(stdout, e)
        println()
    end
    
    # Example 2: No matching description
    println("\n🔍 Example 2: No Matching Configuration")
    println("─"^40)
    
    try
        DemoConfigManager.load_config(:invalid, :config)
    catch e
        showerror(stdout, e)
        println()
    end
    
    # Example 3: Partial match with suggestions
    println("\n💡 Example 3: Partial Match with Smart Suggestions")
    println("─"^40)
    
    try
        DemoConfigManager.load_config(:optimization, :invalid_method)
    catch e
        showerror(stdout, e)
        println()
    end
    
    # Example 4: Successful completion (for comparison)
    println("\n✅ Example 4: Successful Configuration Finding")
    println("─"^40)
    
    try
        config = DemoConfigManager.load_config(:optimization, :gradient)
        println("Result: ", config)
    catch e
        println("Error: ", e)
    end
    
    return nothing
end

end # module

# Export for external use
test_ambiguous_description_examples() = TestAmbiguousDescriptionExamples.test_ambiguous_description_examples()
