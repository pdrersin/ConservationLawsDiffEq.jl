# Mass conservation test

@testset "1D Scalar Diffusion Algorithms: Mass conservation" begin

using ConservationLawsDiffEq
using LinearAlgebra

#FastGaussQuadrature
t_nodes = [0.06943184420297371,0.33000947820757187, 0.6699905217924281,0.9305681557970262]
weights = [0.34785484513745385,0.6521451548625462,0.6521451548625462,0.34785484513745385]

# Parameters:
ρc = 880.0 #Kg/m³
ρd = 1090.0 #Kg/m³
L = 20.0e-3  #m
μc = 6.5e-3 #Pa
D0 = 1.0e-7 #m²/s
nrz = 2.0#4.65
M = 1
di = 1e-6*[140.2] #mm# #m1e-6*
u₀ = 1e-2*[0.6410]
τ = 1e-16
κ = 1e-16
grv = 9.81 #m/s²
wc = 40.0
Vmx = (ρd-ρc)*grv*di.^2/(18*μc)

function Jf(ϕ::AbstractVector)
  M = size(ϕ,1)
  F = fill(zero(eltype(ϕ)),M,M)
  Vϕ = VV(sum(ϕ))
  VPϕ = VP(sum(ϕ))
  for i =  1:M
    for j = 1:M
      F[i,j]=Vmx[i]*(((i==j) ? Vϕ : zero(Vϕ)) + ϕ[i]*VPϕ)
    end
  end
  F
end

f(ϕ::AbstractVector) = VV(sum(ϕ))*ϕ.*Vmx
β(ϕ::Number) = D0*VV(ϕ)
VV(ϕ::Number) = ϕ<1 ? (1.0-ϕ)^nrz : zero(ϕ)
VP(ϕ::Number) = ϕ<1 ? -nrz*(1.0-ϕ)^(nrz-1) : zero(ϕ)

function BB(ϕ::AbstractArray)
    M = size(ϕ,1)
    B = β(sum(ϕ))*Diagonal(ones(M))
    B
end
f0(x) = x < L/2 ? 1.0 : 0.0

 ######################### COMP-GLF Scheme ###################
 function αf(u,f)
     α = zero(eltype(u))
     N = size(u,1)
     for i in 1:N
       ui = u[i,:]
       M1 = Vmx[end]*VV(sum(ui)) + VP(sum(ui))*sum(Vmx.*ui)
       M2 = Vmx[1]*VV(sum(ui))
       α = max(α,max(abs(M1),abs(M2)))
     end
     α
 end

##################################### Entropy stable Problem -15 + 0.7*log(1/Vmx[i])
function vl(u::AbstractVector)
  w = fill!(similar(u),zero(eltype(u)))
  for (i,ui) in enumerate(u)
    w[i] = ui < 0.0 ? -wc : max(log(ui),-wc)
  end
  w
end
ve(u::Vector) = vl(u)./Vmx
vei(v::Vector) = exp.(v.*Vmx)

function kv(v::AbstractVector)
  M = size(v,1)
  w = sum(vei(v))
  K = β(w)*Matrix(Diagonal(Vmx.*exp.(Vmx.*v)))
  K
end
function Nediff(vl::AbstractVector, vr::AbstractVector)
    ul = vei(vl); ur = vei(vr)
    if (sum(ul) < 1.0)
        kv(0.5*(vl+vr))
    else
        ny = size(vl,1)
        return fill(zero(eltype(ny)),ny,ny)
    end
end

function cons_integral(vl,vr)
    F = fill!(similar(vl),zero(eltype(vl)))
    ueps = fill!(similar(vl),zero(eltype(vl)))
    for i in 1:size(t_nodes,1)
        @. ueps = exp((vl + t_nodes[i]*(vr-vl))*Vmx)
        if sum(ueps) > 1.0
            F = fill!(similar(vl),zero(eltype(vl)))
            break
        end
        F = F + 0.5*weights[i]*f(ueps)
    end
    return F
end

function get_problem(N, CFL=0.3, Tend=300.0)
  mesh = Uniform1DFVMesh(N,0.0,L,:ZERO_FLUX,:ZERO_FLUX)
  return ConservationLawsWithDiffusionProblem(f0,f,BB,CFL,Tend,mesh;jac = Jf)
end
function run_test(prob;α=1.0e-13, ses = false, ut = false)
  ϵ = α*prob.mesh.Δx
  return fast_solve(prob, FVESJPAlgorithm(cons_integral,Nediff;ϵ=ϵ,ve=ve);progress=true,
                save_everystep = ses, use_threads = ut)
end

prob = get_problem(50, 0.4, 300.0)
@time sol = run_test(prob;α = 1.0e-13, ut = false,ses = true)
masa = get_total_u(sol);
@test minimum(masa) ≈ maximum(masa)
@time sol = run_test(prob;α = 1.0e-13, ut = true,ses = true)
masa = get_total_u(sol);
@test minimum(masa) ≈ maximum(masa)
@time sol1 = fast_solve(prob, FVSKTAlgorithm();progress=false, save_everystep = true, use_threads=false)
masa = get_total_u(sol1);
@test minimum(masa) ≈ maximum(masa)
@time sol1 = fast_solve(prob, FVSKTAlgorithm();progress=false, save_everystep = true, use_threads=true)
masa = get_total_u(sol1);
@test minimum(masa) ≈ maximum(masa)
@time sol2 = solve(prob, LI_IMEX_RK_Algorithm();progress=false, save_everystep = true, use_threads=false)
masa = get_total_u(sol2);
@test minimum(masa) ≈ maximum(masa)
@time sol2 = solve(prob, LI_IMEX_RK_Algorithm();progress=false, save_everystep = true, use_threads=true)
masa = get_total_u(sol2);
@test minimum(masa) ≈ maximum(masa)
@time sol3 = solve(prob, FVCUAlgorithm();progress=false, save_everystep = true, use_threads=false)
masa = get_total_u(sol3);
@test minimum(masa) ≈ maximum(masa)
@time sol3 = solve(prob, FVCUAlgorithm();progress=false, save_everystep = true, use_threads=true)
masa = get_total_u(sol3);
@test minimum(masa) ≈ maximum(masa)
@time sol4 = solve(prob, FVDRCUAlgorithm();progress=false, save_everystep = true, use_threads=false)
masa = get_total_u(sol4);
@test minimum(masa) ≈ maximum(masa)
@time sol4 = solve(prob, FVDRCUAlgorithm();progress=false, save_everystep = true, use_threads=true)
masa = get_total_u(sol4);
@test minimum(masa) ≈ maximum(masa)
@time sol5 = solve(prob, FVDRCU5Algorithm();progress=false, save_everystep = true, use_threads=false)
masa = get_total_u(sol5);
@test minimum(masa) ≈ maximum(masa)
@time sol5 = solve(prob, FVDRCU5Algorithm();progress=false, save_everystep = true, use_threads=true)
masa = get_total_u(sol5);
@test minimum(masa) ≈ maximum(masa)
@time sol6 = solve(prob, COMP_GLF_Diff_Algorithm();progress=false, save_everystep = true, use_threads=false)
masa = get_total_u(sol6);
@test minimum(masa) ≈ maximum(masa)
@time sol6 = solve(prob, COMP_GLF_Diff_Algorithm();progress=false, save_everystep = true, use_threads=true)
masa = get_total_u(sol6);
@test minimum(masa) ≈ maximum(masa)

end
