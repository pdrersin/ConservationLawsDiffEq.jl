using ConservationLawsDiffEq
using Test

@time @testset "1D Scalar Algorithms" begin include("test0.jl") end
@time @testset "1D Sytems Algorithms" begin include("test2.jl") end
@time @testset "1D Diffusion System Algorithms" begin include("test4.jl") end
@time @testset "1D Scalar Diffusion Algorithms: Mass conservation" begin include("test5.jl") end
