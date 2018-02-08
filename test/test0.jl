# 1D Burgers Equation
# u_t+(0.5*u²)_{x}=0

using ConservationLawsDiffEq
include("burgers.jl")

const CFL = 0.5
const Tend = 1.0
const ul = 1.0
const ur = 0.0
const x0 = 0.0
const xl = -3.0
const xr = 3.0

prob1 = RiemannProblem(Burgers(), ul, ur, x0, 0.0)
sol_ana  = get_solution(prob1)

f(::Type{Val{:jac}},u::Vector) = diagm(u)
f(u::Vector) = u.^2/2

function u0_func(xx)
  N = size(xx,1)
  uinit = zeros(N, 1)
  for (i,x) in enumerate(xx)
      uinit[i,1] = (x < x0) ? ul : ur
  end
  return uinit
end

function get_problem(N)
  mesh = Uniform1DFVMesh(N,xl,xr,:DIRICHLET, :DIRICHLET)
  u0 = u0_func(cell_centers(mesh))
  ConservationLawsProblem(u0,f,CFL,Tend,mesh)
end

prob = get_problem(50)
@time sol = solve(prob, FVSKTAlgorithm(); use_threads = false, save_everystep = true)
@test get_L1_errors(sol_ana, sol, Tend, -2.0, 2.0) < 0.095
masa = get_total_u(sol);
@test minimum(masa) ≈ maximum(masa)
@time sol = solve(prob, FVSKTAlgorithm(); use_threads = true, save_everystep = true)
@test get_L1_errors(sol_ana, sol, Tend, -2.0, 2.0) < 0.095
masa = get_total_u(sol);
@test minimum(masa) ≈ maximum(masa)
@time sol1 = fast_solve(prob, FVSKTAlgorithm();use_threads = false, save_everystep = true)
@test get_L1_errors(sol_ana, sol1, Tend, -2.0, 2.0) < 0.0952
masa = get_total_u(sol1);
@test minimum(masa) ≈ maximum(masa)
@time sol1 = fast_solve(prob, FVSKTAlgorithm();use_threads = true, save_everystep = true)
@test get_L1_errors(sol_ana, sol1, Tend, -2.0, 2.0) < 0.0952
masa = get_total_u(sol1);
@test minimum(masa) ≈ maximum(masa)
@time sol2 = solve(prob, LaxFriedrichsAlgorithm();use_threads = false, save_everystep = true)
@test get_L1_errors(sol_ana, sol2, Tend, -2.0, 2.0) < 0.14
masa = get_total_u(sol2);
@test minimum(masa) ≈ maximum(masa)
@time sol2 = solve(prob, LaxFriedrichsAlgorithm();use_threads = true, save_everystep = true)
@test get_L1_errors(sol_ana, sol2, Tend, -2.0, 2.0) < 0.14
masa = get_total_u(sol2);
@test minimum(masa) ≈ maximum(masa)
@time sol3 = solve(prob, LocalLaxFriedrichsAlgorithm();use_threads = false, save_everystep = true)
@test get_L1_errors(sol_ana, sol3, Tend, -2.0, 2.0) < 0.13
masa = get_total_u(sol3);
@test minimum(masa) ≈ maximum(masa)
println("No threaded version of LLF")
@time sol4 = solve(prob, GlobalLaxFriedrichsAlgorithm();use_threads = false, save_everystep = true)
@test get_L1_errors(sol_ana, sol4, Tend, -2.0, 2.0) < 0.14
masa = get_total_u(sol4);
@test minimum(masa) ≈ maximum(masa)
@time sol4 = solve(prob, GlobalLaxFriedrichsAlgorithm();use_threads = true, save_everystep = true)
@test get_L1_errors(sol_ana, sol4, Tend, -2.0, 2.0) < 0.14
masa = get_total_u(sol4);
@test minimum(masa) ≈ maximum(masa)
#@time sol5 = solve(prob, LaxWendroff2sAlgorithm();progress=true, save_everystep = false)
@time sol5 = solve(prob, FVCompWENOAlgorithm();use_threads = false, TimeAlgorithm = SSPRK33(), save_everystep = true)
@test get_L1_errors(sol_ana, sol5, Tend, -2.0, 2.0) < 0.095
masa = get_total_u(sol5);
@test minimum(masa) ≈ maximum(masa)
@time sol5 = solve(prob, FVCompWENOAlgorithm();use_threads = true, TimeAlgorithm = SSPRK33(), save_everystep = true)
@test get_L1_errors(sol_ana, sol5, Tend, -2.0, 2.0) < 0.095
masa = get_total_u(sol5);
@test minimum(masa) ≈ maximum(masa)
@time sol6 = solve(prob, FVCompMWENOAlgorithm();use_threads = false, TimeAlgorithm = SSPRK33(), save_everystep = true)
@test get_L1_errors(sol_ana, sol6, Tend, -2.0, 2.0) < 0.095
masa = get_total_u(sol6);
@test minimum(masa) ≈ maximum(masa)
@time sol6 = solve(prob, FVCompMWENOAlgorithm();use_threads = true, TimeAlgorithm = SSPRK33(), save_everystep = true)
@test get_L1_errors(sol_ana, sol6, Tend, -2.0, 2.0) < 0.095
masa = get_total_u(sol6);
@test minimum(masa) ≈ maximum(masa)
@time sol7 = solve(prob, FVSpecMWENOAlgorithm();use_threads = false, save_everystep = true)
@test get_L1_errors(sol_ana, sol7, Tend, -2.0, 2.0) < 0.095
masa = get_total_u(sol7);
@test minimum(masa) ≈ maximum(masa)
println("No threaded version of FVSpecMWENOAlgorithm")
@time sol8 = solve(prob, FVCUAlgorithm(); use_threads = false, save_everystep = true)
@test get_L1_errors(sol_ana, sol8, Tend, -2.0, 2.0) < 0.095
masa = get_total_u(sol8);
@test minimum(masa) ≈ maximum(masa)
@time sol8 = solve(prob, FVCUAlgorithm(); use_threads = true, save_everystep = true)
@test get_L1_errors(sol_ana, sol8, Tend, -2.0, 2.0) < 0.095
masa = get_total_u(sol8);
@test minimum(masa) ≈ maximum(masa)
@time sol9 = solve(prob, FVDRCUAlgorithm(); use_threads = false, save_everystep = true)
@test get_L1_errors(sol_ana, sol9, Tend, -2.0, 2.0) < 0.095
masa = get_total_u(sol9);
@test minimum(masa) ≈ maximum(masa)
@time sol9 = solve(prob, FVDRCUAlgorithm(); use_threads = true, save_everystep = true)
@test get_L1_errors(sol_ana, sol9, Tend, -2.0, 2.0) < 0.095
masa = get_total_u(sol9);
@test minimum(masa) ≈ maximum(masa)
@time sol10 = solve(prob, FVDRCU5Algorithm(); use_threads = false, save_everystep = true)
@test get_L1_errors(sol_ana, sol10, Tend, -2.0, 2.0) < 0.095
masa = get_total_u(sol10);
@test minimum(masa) ≈ maximum(masa)
@time sol10 = solve(prob, FVDRCU5Algorithm(); use_threads = true, save_everystep = true)
@test get_L1_errors(sol_ana, sol10, Tend, -2.0, 2.0) < 0.095
masa = get_total_u(sol10);
@test minimum(masa) ≈ maximum(masa)
