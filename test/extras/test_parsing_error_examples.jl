module TestParsingErrorExamples

using Test
using CTBase

"""
Demo module for realistic ParsingError examples.
"""
module DemoConfigParser
    using CTBase
    
    """
    Parse configuration file content.
    """
    function parse_config_file(content::String)
        lines = split(content, '\n')
        config = Dict{String, Any}()
        
        for (line_num, line) in enumerate(lines)
            # Skip empty lines and comments
            line = strip(line)
            if isempty(line) || startswith(line, '#')
                continue
            end
            
            try
                # Parse key=value format
                if occursin('=', line)
                    parts = split(line, '=', limit=2)
                    if length(parts) != 2
                        throw(CTBase.Exceptions.ParsingError(
                            "invalid configuration line format",
                            location="line $line_num: \"$line\"",
                            suggestion="ensure each line contains exactly one '=' separator"
                        ))
                    end
                    
                    key = strip(parts[1])
                    value = strip(parts[2])
                    
                    # Validate key format
                    if isempty(key)
                        throw(CTBase.Exceptions.ParsingError(
                            "empty configuration key",
                            location="line $line_num: \"$line\"",
                            suggestion="provide a valid key before the '=' separator"
                        ))
                    end
                    
                    # Parse value
                    parsed_value = parse_config_value(value, line_num)
                    config[key] = parsed_value
                    
                else
                    throw(CTBase.Exceptions.ParsingError(
                        "unrecognized line format",
                        location="line $line_num: \"$line\"",
                        suggestion="add '=' separator or prefix with '#'"
                    ))
                end
                
            catch e
                if e isa CTBase.Exceptions.ParsingError
                    rethrow()
                else
                    throw(CTBase.Exceptions.ParsingError(
                        "failed to parse configuration value",
                        location="line $line_num: \"$line\"",
                        suggestion="check value format (numbers, strings, booleans, arrays)"
                    ))
                end
            end
        end
        
        return config
    end
    
    """
    Parse individual configuration value.
    """
    function parse_config_value(value::String, line_num::Int)
        value = strip(value)
        
        # Boolean values
        if value == "true"
            return true
        elseif value == "false"
            return false
        end
        
        # Numeric values
        try
            # Try integer first
            return parse(Int, value)
        catch
            try
                # Then try float
                return parse(Float64, value)
            catch
                # Continue to string parsing
            end
        end
        
        # String values (quoted or unquoted)
        if startswith(value, '"') && endswith(value, '"')
            return value[2:end-1]  # Remove quotes
        elseif startswith(value, "'") && endswith(value, "'")
            return value[2:end-1]  # Remove quotes
        else
            return value  # Unquoted string
        end
    end
    
    """
    Parse JSON-like array format.
    """
    function parse_array_value(array_str::String, line_num::Int)
        if !startswith(array_str, '[') || !endswith(array_str, ']')
            throw(CTBase.Exceptions.ParsingError(
                "invalid array format",
                location="array: \"$array_str\"",
                suggestion="use format: [item1, item2, item3]"
            ))
        end
        
        # Remove brackets and split by comma
        content = array_str[2:end-1]
        if isempty(content)
            return String[]
        end
        
        items = split(content, ',')
        return [strip(item) for item in items]
    end
end

function test_parsing_error_examples()
    println("🔍 ParsingError Examples")
    println("="^50)
    
    # Example 1: Invalid line format
    println("\n📄 Example 1: Invalid Configuration Line Format")
    println("─"^40)
    
    invalid_config = """
    # Valid configuration
    timeout = 30
    invalid_line_without_equals
    debug = true
    """
    
    try
        DemoConfigParser.parse_config_file(invalid_config)
    catch e
        showerror(stdout, e)
        println()
    end
    
    # Example 2: Empty key
    println("\n🔑 Example 2: Empty Configuration Key")
    println("─"^40)
    
    empty_key_config = """
    timeout = 30
    = invalid_empty_key
    debug = true
    """
    
    try
        DemoConfigParser.parse_config_file(empty_key_config)
    catch e
        showerror(stdout, e)
        println()
    end
    
    # Example 3: Invalid value format
    println("\n💰 Example 3: Invalid Value Format")
    println("─"^40)
    
    invalid_value_config = """
    timeout = 30
    debug = maybe
    port = 8080
    """
    
    try
        DemoConfigParser.parse_config_file(invalid_value_config)
    catch e
        showerror(stdout, e)
        println()
    end
    
    # Example 4: Invalid array format
    println("\n📊 Example 4: Invalid Array Format")
    println("─"^40)
    
    try
        DemoConfigParser.parse_array_value("item1, item2, item3", 1)
    catch e
        showerror(stdout, e)
        println()
    end
    
    # Example 5: Successful parsing (for comparison)
    println("\n✅ Example 5: Successful Configuration Parsing")
    println("─"^40)
    
    valid_config = """
    # Application configuration
    timeout = 30
    debug = true
    port = 8080
    """
    
    try
        config = DemoConfigParser.parse_config_file(valid_config)
        println("Parsed configuration:")
        for (key, value) in config
            println("  $key = $value ($(typeof(value)))")
        end
    catch e
        showerror(stdout, e)
        println()
    end
    
    return nothing
end

end # module

# Export for external use
test_parsing_error_examples() = TestParsingErrorExamples.test_parsing_error_examples()
