using TypeStability
using Base.Test

@testset "TypeStability.jl" begin

    include("StabilityAnalysisTests.jl")
    include("InlineCheckerTests.jl")
    include("Utils.jl")
end
