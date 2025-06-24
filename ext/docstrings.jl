function extract_docstring_code_pairs(ai_text::String)
    
    start_idx = findfirst("\"\"\"", ai_text)
    if start_idx !== nothing
        response = ai_text[start_idx[1]:end]
    end
    
    # Regex pour capturer chaque bloc docstring + code qui suit
    pattern = r"\"\"\"(.*?)\"\"\"\s*([\s\S]*?)(?=(\"\"\"|$))"
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

    return [pairs, response]
end


#générate an answer from an IA. 
function docstrings(path; tests=nothing, doc=nothing, apikey="")
    # Read code file
    code_text = read(path, String)
    # Optionally read tests and doc files
    tests_text = tests !== nothing ? read(tests, String) : ""
    doc_text = doc !== nothing ? read(doc, String) : ""
    url = "https://api.mistral.ai/v1/chat/completions"
    headers = [
        "Authorization" => "Bearer $apikey",
        "Content-Type" => "application/json"
    ]

    # Build a precise prompt for the AI
       prompt = """
Pour chaque type, fonction ou exception Julia que tu génères, ajoute une docstring complète au format Julia (triple guillemets) juste au-dessus de la déclaration de la fonction et pas dedans.
La docstring doit inclure :

- Une description claire et concise du rôle du type ou de la fonction.
- Une section `# Fields` (pour les structs) listant chaque champ avec son type et une courte description.
- Une section `# Example` montrant un exemple d’utilisation dans un bloc ```julia-repl.

Exemple attendu :

\"\"\"
Exception thrown when a function call is not authorized in the current context
or with the given arguments.

# Fields

- `var::String`: A message explaining why the call is unauthorized.

# Example

```julia-repl
julia> throw(UnauthorizedCall("user does not have permission"))
ERROR: UnauthorizedCall: user does not have permission
\"\"\"


IMPORTANT : Ne documente que le code fourni ci-dessous, sans ajouter, modifier ou inventer de nouveaux types, fonctions ou exemples qui ne sont pas présents dans le code.

Voici le code à documenter :
$code_text

$(tests !== nothing ? "\nVoici les tests associés :\n$tests_text" : "")
$(doc !== nothing ? "\nVoici la documentation existante :\n$doc_text" : "")

Merci de toujours suivre ce format pour chaque type, fonction ou exception générée et de ne rier rajouter de plus que ce que je te demande. Rajoute toujours juste avant la déclaration de lafonction la doc généré et null part d'autres. 


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
    response = extract_docstring_code_pairs(ai_text)[2]
        
    #print(ai_text)
    #print(response)

    return response
end



function docstrings_file(path; tests=nothing, doc=nothing, apikey="")
    ai_text = docstrings(path, tests=tests, doc=doc, apikey=apikey)
    
    dir, filename = splitdir(path)
    name, ext = splitext(filename)
    outpath = joinpath(dir, "$(name)_docstrings$(ext)")
    open(outpath, "w") do io
        write(io, ai_text)
    end
    return outpath
end


