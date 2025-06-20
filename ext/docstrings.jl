using Pkg
Pkg.activate("tmp")

using HTTP
using JSON

function docstrings(code; tests=nothing, doc=nothing, apikey="")
    # Read code file
    code_text = read(code, String)
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

    return ai_text
end

