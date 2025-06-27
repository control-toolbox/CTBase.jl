
"""
$(TYPEDEF)

A type representing a tuple of a documentation string and the code that follows it.

# Example

```julia-repl
julia> pairs, remaining_code = extract_docstring_code_pairs("...")
[expected output]
```
"""

function extract_docstring_code_pairs(ai_text::String)
    response = ai_text  # Toujours initialiser avec tout le texte
    start_idx = findfirst("\"\"\"", ai_text)
    if start_idx !== nothing
        response = ai_text[start_idx[1]:end]
    end

    # Regex pour capturer chaque bloc docstring + code qui suit
    pattern = r"\"\"\"\s*(.*?)\s*\"\"\"\s*([\s\S]*?)(?=(\"\"\"|$))"s
    pairs = []
    for m in eachmatch(pattern, response)
        doc = strip(m.captures[1])
        code = strip(m.captures[2])
        push!(pairs, (doc, code))
    end

    reponse = ""
    for (doc, code) in pairs
        reponse *= "\n\"\"\"\n$doc\n\"\"\"\n$code\n"
    end

    # Retire tout ce qui est après le dernier bloc ```
    idx = findlast("```", reponse)
    if idx !== nothing
        reponse = reponse[1:idx[1]-1]
    end
    return pairs, reponse
end

"""
$(TYPESIGNATURES)

Reads the code file and processes it to generate Julia docstrings.

# Arguments

- `path` :: Union{String, AbstractPath} : The path to the code file to process.
- `tests` :: Union{String, Nothing} : Optional test code for the generated docstrings.
- `context` :: Union{String, Nothing} : Optional context code for the generated docstrings.
- `apikey` :: Union{String, Nothing} : Optional API key for the AI used to generate docstrings.

# Returns

- `String` : A string containing the generated docstrings.
"""

function CTBase.docstrings(path::String; tests=nothing, context=nothing, apikey="")
    # Read code file
    code_text = read(path, String)
    # Optionally read tests and doc files
    tests_text = tests !== nothing ? read(tests, String) : ""
    context_text = context !== nothing ? read(context, String) : ""
    url = "https://api.mistral.ai/v1/chat/completions"
    headers = [
        "Authorization" => "Bearer $apikey",
        "Content-Type" => "application/json"
    ]

    # Build a precise prompt for the AI
prompt = """
For each Julia type, function, or exception provided in the code below, generate a complete Julia docstring formatted according to Documenter.jl, following these rules:

- The docstring must be placed **immediately above** the corresponding declaration (type, struct, function, or exception).
- For **types and exceptions**, begin the docstring with `\"\"\"` followed by `\$(TYPEDEF)` on the first line.
- For **functions**, begin the docstring with `\"\"\"` followed by `\$(TYPEDSIGNATURES)` on the first line.
- Provide a **clear and concise** description of what the type, function, or exception does.
- For structs and exceptions, include a `# Fields` section listing each field with its type and a short description.
- For functions, include a `# Arguments` section listing each argument, and a `# Returns` section if applicable.
- Add a `# Example` section showing a usage example inside a \`\`\`julia-repl block.
- **Do not add anything else** beyond the docstrings and the provided code: do not create new types, functions, or examples that are not already in the code.

To ensure consistency, **complete the following template for each documented element** (replace only the blank areas `[...]` accordingly):

For a **type or exception**:
\`\`\`julia
\"\"\"
\$(TYPEDEF)

[One-sentence description of what this type or exception represents.]

# Fields

- `[field_name]::[Type]`: [Short description of the field.]

# Example

\`\`\`julia-repl
julia> [usage example]
[expected output]
\`\`\`
\"\"\"
[struct or exception declaration]
\`\`\`

For a **function**:
\`\`\`julia
\"\"\"
\$(TYPEDSIGNATURES)

[One-sentence description of what this function does.]

# Arguments

- `[arg_name]::[Type]`: [Description of the argument.]

# Returns

- `[return_value]::[Type]`: [Description of what is returned.]

# Example

\`\`\`julia-repl
julia> [usage example]
[expected output]
\`\`\`
\"\"\"
[function declaration]
\`\`\`

IMPORTANT:  
- Only document the code provided below. Do **not** add, modify, or invent new types, functions, or examples.
- Place each docstring immediately above its corresponding declaration, with no text in between.

Here is the code to document:
\\$code_text

\\$(tests !== nothing ? "\nHere are some related tests:\n\\$tests_text" : "")
\\$(context !== nothing ? "\nHere is some additional context to help understand the code:\n\\$context_text" : "")

Strictly follow this format and complete the template above for each type, function, or exception.
"""

    # Prepare the data for the API
    data = Dict(
        "model" => "mistral-tiny",
        "messages" => [
            Dict("role" => "user", "content" => prompt)
        ]
    )

    # Send the request
    response = HTTP.post(
        url,
        headers,
        JSON.json(data)
    )

    sol_str = String(response.body)
    # Parse the response
    result = JSON.parse(sol_str)
    # Extract the AI's answer (assuming Mistral API format)
    ai_text = result["choices"][1]["message"]["content"]
    
    # Ignore tout ce qui précède le premier bloc triple guillemets
    response = extract_docstring_code_pairs(ai_text)
        
    #print(ai_text)
    #print(response)

    return response
end


"""
$(TYPEDEF)

A function that parses and reformats the docstrings for a given source file.

# Example

```julia-repl
julia> docstrings_file("path/to/your/source/file.jl")
"path/to/your/source/file_docstrings.jl"
```
"""

function docstrings_file(path; tests=nothing, context=nothing, apikey="")
    pairs, ai_text = docstrings(path, tests=tests, context=context, apikey=apikey)

    #code_unchanged_check
    original_code = read(path, String)
    code_unchanged_check(pairs, original_code)
    
    # Supprime toutes les lignes qui ne contiennent que ```
    dir, filename = splitdir(path)
    name, ext = splitext(filename)
    outpath = joinpath(dir, "$(name)_docstrings$(ext)")
    open(outpath, "w") do io
        write(io, ai_text)
    end
    return outpath
end

"""
$(TYPEDSIGNATURES)

Checks if the provided code is unchanged after parsing and reformatting the docstrings. Returns 1 if the code has changed, otherwise 0.

# Arguments
- `pairs`: A tuple of pairs containing (docstring, code) couples.
- `original_code`: The original code as a string.
- `display`: A flag that determines whether to display the differences between the original and reformatted code. Default is true.

# Returns
- `Int`: 1 if the code has changed, otherwise 0.

# Example

```julia-repl
julia> code_unchanged_check(pairs, original_code)
1
```
"""

function code_unchanged_check(pairs, original_code::String; display=true)
    # Reconstruit le code à partir des couples (docstring, code)
    reconstructed = join([code for (doc, code) in pairs], "\n\n")
    # Normalise : retire les espaces et retours à la ligne superflus
    norm = s -> join(split(strip(s)))
    orig_norm = norm(original_code)
    recon_norm = norm(reconstructed)
    if orig_norm != recon_norm
        display && println("Le code a changé (différences ignorées : espaces/retours à la ligne).")
        # Affiche les différences ligne à ligne pour aider à localiser
        orig_lines = split(strip(original_code), '\n')
        recon_lines = split(strip(reconstructed), '\n')
        maxlen = max(length(orig_lines), length(recon_lines))
        for i in 1:(maxlen-1)
            orig_line = i <= length(orig_lines) ? orig_lines[i] : ""
            recon_line = i <= length(recon_lines) ? recon_lines[i] : ""
            if (strip(orig_line) != strip(recon_line)) && display
                println("Différence à la ligne $i :")
                println("  original   : ", orig_line)
                println("  généré     : ", recon_line)
            end
        end
        return 1
    else
        return 0
    end
end