using DataTools
using Documenter

makedocs(;
    modules=[DataTools],
    authors="Takafumi Arakaki <aka.tkf@gmail.com> and contributors",
    repo="https://github.com/JuliaFolds/DataTools.jl/blob/{commit}{path}#L{line}",
    sitename="DataTools.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://JuliaFolds.github.io/DataTools.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
    strict = get(ENV, "CI", "false") == "true",
)

deploydocs(;
    repo="github.com/JuliaFolds/DataTools.jl",
    push_preview = true,
)
