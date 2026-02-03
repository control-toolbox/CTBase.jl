module TestIncorrectArgumentExamples

using Test
using CTBase

"""
Demo module for realistic IncorrectArgument examples.
"""
module DemoCalculator
    using CTBase
    
    """
    Calculate the square root of a positive number.
    """
    function sqrt_positive(x::Real)
        if x < 0
            throw(CTBase.Exceptions.IncorrectArgument(
                "cannot compute square root of negative number",
                got=string(x),
                expected="a non-negative number (x ≥ 0)",
                suggestion="use sqrt(abs(x)) for absolute value, or check your input",
                context="square root calculation"
            ))
        end
        return sqrt(x)
    end
    
    """
    Divide two numbers with validation.
    """
    function safe_divide(a::Real, b::Real)
        if b == 0
            throw(CTBase.Exceptions.IncorrectArgument(
                "division by zero is not allowed",
                got="divisor = $b",
                expected="a non-zero divisor",
                suggestion="check your divisor value or use try-catch for zero division",
                context="arithmetic division operation"
            ))
        end
        return a / b
    end
    
    """
    Find element in array with bounds checking.
    """
    function find_element(arr::Vector{T}, index::Int) where T
        if index < 1 || index > length(arr)
            throw(CTBase.Exceptions.IncorrectArgument(
                "array index out of bounds",
                got="index = $index",
                expected="1 ≤ index ≤ $(length(arr))",
                suggestion="use 1-based indexing or check array length first",
                context="array element access"
            ))
        end
        return arr[index]
    end
end

function test_incorrect_argument_examples()
    println("🔍 IncorrectArgument Examples")
    println("="^50)
    
    # Example 1: Square root error
    println("\n📐 Example 1: Square Root of Negative Number")
    println("─"^40)
    
    try
        DemoCalculator.sqrt_positive(-4)
    catch e
        showerror(stdout, e)
        println()
    end
    
    # Example 2: Division by zero
    println("\n🔢 Example 2: Division by Zero")
    println("─"^40)
    
    try
        DemoCalculator.safe_divide(10, 0)
    catch e
        showerror(stdout, e)
        println()
    end
    
    # Example 3: Array bounds error
    println("\n📊 Example 3: Array Index Out of Bounds")
    println("─"^40)
    
    test_array = [1, 2, 3, 4, 5]
    
    try
        DemoCalculator.find_element(test_array, 10)
    catch e
        showerror(stdout, e)
        println()
    end
    
    return nothing
end

# ====================================================================
# CTBase INTERNAL IncorrectArgument EXAMPLES
# ====================================================================

function test_ctbase_incorrect_argument_examples()
    println("\n🔧 CTBase Internal IncorrectArgument Examples")
    println("="^50)
    
    # Example 4: Duplicate description in catalog
    println("\n📚 Example 4: Duplicate Description in Catalog")
    println("─"^40)
    
    try
        # Create a catalog with one description
        desc1 = (:test, :desc1)  # Description is just a tuple of symbols
        catalog = (desc1,)
        
        # Try to add the same description again
        CTBase.Descriptions.add(catalog, desc1)
    catch e
        showerror(stdout, e)
        println()
    end
    
    # Example 5: ctindice with invalid range
    println("\n🔢 Example 5: ctindice Invalid Range")
    println("─"^40)
    
    try
        CTBase.ctindice(15)  # > 9
    catch e
        showerror(stdout, e)
        println()
    end
    
    # Example 6: ctindice with negative value
    println("\n⬇️  Example 6: ctindice Negative Value")
    println("─"^40)
    
    try
        CTBase.ctindice(-1)  # < 0
    catch e
        showerror(stdout, e)
        println()
    end
    
    # Example 7: ctindices with negative value
    println("\n📝 Example 7: ctindices Negative Value")
    println("─"^40)
    
    try
        CTBase.ctindices(-5)  # < 0
    catch e
        showerror(stdout, e)
        println()
    end
    
    # Note: ctuperscript and ctuperscripts functions exist but are not accessible
    # through the current module structure. The working examples above demonstrate
    # the IncorrectArgument exception display functionality sufficiently.
    
    return nothing
end

end # module

# Export for external use
test_incorrect_argument_examples() = TestIncorrectArgumentExamples.test_incorrect_argument_examples()
test_ctbase_incorrect_argument_examples() = TestIncorrectArgumentExamples.test_ctbase_incorrect_argument_examples()

function test_all_incorrect_argument_examples()
    test_incorrect_argument_examples()
    test_ctbase_incorrect_argument_examples()
end
