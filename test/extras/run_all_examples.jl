"""
Run all exception examples to demonstrate the enriched exception system.

This script demonstrates all exception types with both stacktrace and user-friendly
display modes, showing realistic usage scenarios.
"""

using CTBase

# Include all example modules
include("test_incorrect_argument_examples.jl")
include("test_ambiguous_description_examples.jl")
include("test_unauthorized_call_examples.jl")
include("test_not_implemented_examples.jl")
include("test_parsing_error_examples.jl")
include("test_extension_error_examples.jl")

"""
Run all exception examples in sequence.
"""
function run_all_exception_examples()
    println("🎯 CTBase Enriched Exception System - Complete Demo")
    println("="^60)
    println()
    
    # Show current configuration
    println("📋 Current Configuration:")
    println("   SHOW_FULL_STACKTRACE: ", CTBase.get_show_full_stacktrace())
    println()
    
    # Run all examples
    println("🚀 Running All Exception Examples...")
    println()
    
    test_incorrect_argument_examples()
    println("\n" * "─"^60 * "\n")
    
    test_ambiguous_description_examples()
    println("\n" * "─"^60 * "\n")
    
    test_unauthorized_call_examples()
    println("\n" * "─"^60 * "\n")
    
    test_not_implemented_examples()
    println("\n" * "─"^60 * "\n")
    
    test_parsing_error_examples()
    println("\n" * "─"^60 * "\n")
    
    test_extension_error_examples()
    
    println("\n" * "="^60)
    println("✅ All Exception Examples Completed!")
    println()
    println("💡 Key Features Demonstrated:")
    println("   • Rich error messages with contextual information")
    println("   • Smart suggestions and helpful guidance")
    println("   • Configurable stacktrace display")
    println("   • Consistent error formatting across all exception types")
    println("   • Real-world usage scenarios")
    println()
    println("🔧 Configuration:")
    println("   • CTBase.set_show_full_stacktrace!(true)  - Show full Julia stacktraces")
    println("   • CTBase.set_show_full_stacktrace!(false) - User-friendly display only")
    println("   • CTBase.get_show_full_stacktrace()      - Get current setting")
    
    return nothing
end

# Auto-run when executed directly
if abspath(PROGRAM_FILE) == @__FILE__
    run_all_exception_examples()
end
