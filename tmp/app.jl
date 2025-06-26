using HTTP
using JSON

html = """
<!DOCTYPE html>
<html lang='fr'>
<head>
    <meta charset='UTF-8'>
    <title>Générateur de docstrings Julia</title>
    <style>
        body {
            background: #23272f;
            color: #ececf1;
            font-family: 'Segoe UI', Arial, sans-serif;
            margin: 0;
            padding: 0;
        }
        .container {
            max-width: 900px;
            margin: 40px auto;
            background: #2d333b;
            border-radius: 12px;
            box-shadow: 0 4px 24px #0006;
            padding: 2em 2.5em 2em 2.5em;
        }
        h2 {
            text-align: center;
            font-weight: 600;
            margin-bottom: 1.5em;
            color: #10a37f;
            letter-spacing: 1px;
        }
        label {
            font-weight: 500;
            color: #ececf1;
        }
        .api {
            margin-bottom: 1em;
        }
        .flex-row {
            display: flex;
            gap: 1em;
        }
        .flex-col {
            flex: 1;
            display: flex;
            flex-direction: column;
        }
        input[type="password"], textarea {
            width: 100%;
            background: #23272f;
            color: #ececf1;
            border: 1px solid #444950;
            border-radius: 6px;
            padding: 0.7em;
            margin-top: 0.3em;
            margin-bottom: 1em;
            font-size: 1em;
            resize: none;
            transition: border 0.2s;
            min-height: 60px;
            max-height: 600px;
            overflow-y: auto;
        }
        input[type="password"]:focus, textarea:focus {
            border: 1.5px solid #10a37f;
            outline: none;
        }
        button {
            background: #10a37f;
            color: #fff;
            border: none;
            border-radius: 6px;
            padding: 0.7em 1.5em;
            font-size: 1.1em;
            font-weight: 600;
            cursor: pointer;
            transition: background 0.2s;
            margin-top: 0.5em;
        }
        button:hover {
            background: #13c08a;
        }
        .output {
            margin-top: 1.5em;
            background: #23272f;
            border: 1px solid #444950;
            border-radius: 8px;
            padding: 1.2em;
            white-space: pre-wrap;
            font-family: 'Fira Mono', 'Consolas', monospace;
            font-size: 1em;
            color: #ececf1;
            min-height: 80px;
            max-height: 800px;
            overflow-y: auto;
        }
        @media (max-width: 900px) {
            .flex-row { flex-direction: column; }
        }
    </style>
</head>
<body>
    <div class="container">
        <h2>Générateur de docstrings Julia</h2>
        <div class="api">
            <label for="apikey">Clé API Mistral :</label>
            <input type="password" id="apikey" placeholder="Entrez votre clé API ici" required>
        </div>
        <form id="form">
            <label for="input">Code Julia</label>
            <textarea id="input" placeholder="Colle ici ton code Julia"></textarea>
            <div class="flex-row">
                <div class="flex-col">
                    <label for="tests">Tests Julia (optionnel)</label>
                    <textarea id="tests" placeholder="Colle ici tes tests Julia"></textarea>
                </div>
                <div class="flex-col">
                    <label for="doc">Documentation existante (optionnel)</label>
                    <textarea id="doc" placeholder="Colle ici la documentation existante"></textarea>
                </div>
            </div>
            <button type="submit">Générer la documentation</button>
        </form>
        <div class="output" id="output"></div>
    </div>
    <script>
        // Fonction pour ajuster dynamiquement la hauteur des textarea
        function autoResizeTextarea(el) {
            el.style.height = 'auto';
            el.style.height = (el.scrollHeight) + 'px';
        }
        // Applique l'ajustement sur tous les textarea à l'input
        document.querySelectorAll('textarea').forEach(function(textarea) {
            textarea.addEventListener('input', function() {
                autoResizeTextarea(this);
            });
            // Ajuste à l'initialisation si du texte est déjà présent
            autoResizeTextarea(textarea);
        });

        document.getElementById('form').onsubmit = async function(e) {
            e.preventDefault();
            const input = document.getElementById('input').value;
            const tests = document.getElementById('tests').value;
            const doc = document.getElementById('doc').value;
            const apikey = document.getElementById('apikey').value;
            if (!apikey) {
                document.getElementById('output').textContent = "Merci de renseigner votre clé API.";
                return;
            }
            document.getElementById('output').textContent = "Génération en cours...";
            const resp = await fetch('/run', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({ code: input, tests: tests, doc: doc, apikey: apikey })
            });
            const text = await resp.text();
            document.getElementById('output').textContent = text;
            // Ajuste la hauteur de la div output si besoin (optionnel)
            // document.getElementById('output').style.height = 'auto';
        };
    </script>
</body>
</html>
"""

function handle(req)
    if req.target == "/"
        return HTTP.Response(200, ["Content-Type" => "text/html"], html)
    elseif req.target == "/run" && req.method == "POST"
        data = JSON.parse(String(req.body))
        user_code = data["code"]
        user_tests = get(data, "tests", "")
        user_doc = get(data, "doc", "")
        user_apikey = data["apikey"]
        if isempty(user_apikey)
            return HTTP.Response(401, ["Content-Type" => "text/plain"], "Clé API requise.")
        end
        codefile = tempname() * ".jl"
        open(codefile, "w") do io
            write(io, user_code)
        end
        testsfile = nothing
        if !isempty(user_tests)
            testsfile = tempname() * ".jl"
            open(testsfile, "w") do io
                write(io, user_tests)
            end
        end
        docfile = nothing
        if !isempty(user_doc)
            docfile = tempname() * ".jl"
            open(docfile, "w") do io
                write(io, user_doc)
            end
        end
        commented = ""
        try
            commented = docstrings(codefile; tests=testsfile, doc=docfile, apikey=user_apikey)
        catch err
            commented = "Erreur lors de la génération : $(err)"
        end
        return HTTP.Response(200, ["Content-Type" => "text/plain"], commented)
    else
        return HTTP.Response(404, ["Content-Type" => "text/plain"], "Not found")
    end
end

println("Ouvre http://localhost:8080 dans ton navigateur")
HTTP.serve(handle, "127.0.0.1", 8080)