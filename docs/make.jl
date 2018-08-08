using Documenter
import TypeStability

if length(ARGS) > 0
    tag = ARGS[1]
else
    tag = nothing
end

makedocs(modules = [TypeStability])

#deploydocs(deps = Deps.pip("mkdocs", "python-markdown-math"),
#           repo = "github.com/Collegeville/TypeStability.jl")

#The following code is a modified copy of deploydocs in Documenter.jl
target_dir = abspath("site")

sha = try
        readchomp(`git rev-parse --short HEAD`)
    catch
        "(not-git-repo)"
    end

mktempdir() do temp
    latest_dir = joinpath(temp, "latest")
    stable_dir = joinpath(temp, "stable")
    tagged_dir = joinpath(temp, tag)


    cd(temp) do
        run(`git init`)
        run(`git config user.name "autodocs"`)
        run(`git config user.email "autodocs"`)

        # Fetch from remote and checkout the branch.
        success(`git remote add upstream git:github.com/Collegeville/TypeStability.jl.git`) ||
            error("could not add new remote repo.")

        success(`git fetch upstream`) ||
            error("could not fetch from remote.")


        if tag == nothing
            # --ignore-unmatch so that we wouldn't get errors if dst does not exist
            run(`git rm -rf --ignore-unmatch $latest_dir`)
            cp(target_dir, latest_dir)
            Writers.HTMLWriter.generate_siteinfo_file(latest_dir, "latest")
        else
            run(`git rm -rf --ignore-unmatch $stable_dir $tagged_dir`)
            cp(target_dir, stable_dir)
            cp(target_dir, tagged_dir)
            Writers.HTMLWriter.generate_siteinfo_file(stable_dir, "stable")
            Writers.HTMLWriter.generate_siteinfo_file(tagged_dir, tag)
        end

         Writers.HTMLWriter.generate_version_file(temp)

        run(`git add -A .`)
        try run(`git commit -m "build based on $sha"`) end

        success(`git push -q upstream HEAD:master`) ||
            error("could not push to remote repo.")
    end
end
