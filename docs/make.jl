using Documenter
import TypeStability

if length(ARGS) > 0
    tag = ARGS[1]
else
    tag = nothing
end

makedocs(modules = [TypeStability])

success(`/bin/python -m mkdocs build`) ||
    error("couldn't build docs")

deploydocs(deps = Deps.pip("mkdocs", "python-markdown-math"),
           repo = "github.com/Collegeville/TypeStability.jl",
           julia  = "1.0.0")
