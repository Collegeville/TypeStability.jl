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

#deploydocs(deps = Deps.pip("mkdocs", "python-markdown-math"),
#           repo = "github.com/Collegeville/TypeStability.jl")

# The following code is a modified copy of deploydocs in Documenter.jl
# Documenter.jl is copyright 2016, Michael Hatherly and is licensed under the MIT "Expat" License
# See LICENSE.md for a copy of the MIT "Expat" License
target_dir = abspath("site")
println("target_dir = $target_dir")

sha = try
        readchomp(`git rev-parse --short HEAD`)
    catch
        "(not-git-repo)"
    end

mktempdir() do temp
    latest_dir = joinpath(temp, "latest")
    stable_dir = joinpath(temp, "stable")

    if tag == nothing
        tagged_dir = joinpath(temp, "unknowntag")
    else
        tagged_dir = joinpath(temp, tag)
    end


    cd(temp) do
        run(`git init`)
        run(`git config user.name "autodocs"`)
        run(`git config user.email "autodocs"`)

        # Fetch from remote and checkout the branch.
        success(`git remote add upstream https://github.com/Collegeville/TypeStability.jl.git`) ||
            error("could not add new remote repo.")

        success(`git fetch upstream`) ||
            error("could not fetch from remote.")

        #if previous tagged versions are present, use them instead
        run(`git checkout upstream/gh-pages`)


        run(`git rm -rf --ignore-unmatch $latest_dir`)
        cp(target_dir, latest_dir)
        Documenter.Writers.HTMLWriter.generate_siteinfo_file(latest_dir, "latest")

        if tag !== nothing
            run(`git rm -rf --ignore-unmatch $stable_dir $tagged_dir`)
            cp(target_dir, stable_dir)
            cp(target_dir, tagged_dir)
            Documenter.Writers.HTMLWriter.generate_siteinfo_file(stable_dir, "stable")
            Documenter.Writers.HTMLWriter.generate_siteinfo_file(tagged_dir, tag)
        end

        Documenter.Writers.HTMLWriter.generate_version_file(temp)

        run(`git add -A .`)
        try run(`git commit -m "build based on $sha"`) end

        success(`git push -q upstream +HEAD:gh-pages`) ||
            error("could not push to remote repo.")
    end
end
