# Semidiscrete KT Scheme: Second-Order
# Based on:
# Kurganov, Tadmor. New High Resolution Central Schemes for Non Linear Conservation
# Laws and Convection-Difussion Equations. Journal of Comp Physics 160, pp 241-282. 2000

struct FVSKTAlgorithm{ltype <: AbstractSlopeLimiter} <: AbstractFVAlgorithm
  slopeLimiter :: ltype
end

function FVSKTAlgorithm(;slopeLimiter=GeneralizedMinmodLimiter())
  FVSKTAlgorithm(slopeLimiter)
end

function inner_loop!(hh,j,u,∇u,mesh,Flux, alg::FVSKTAlgorithm)
    # Local speeds of propagation
    uminus=cellval_at_left(j,u,mesh)+0.5*cellval_at_left(j,∇u,mesh)
    uplus=cellval_at_right(j,u,mesh)-0.5*cellval_at_right(j,∇u,mesh)
    ul = cellval_at_left(j,u,mesh)
    ur = cellval_at_right(j,u,mesh)
    aa = max(fluxρ(uminus,Flux),fluxρ(uplus,Flux))
    # Numerical Fluxes
    hh[j,:] = 0.5*(Flux(uplus)+Flux(uminus)) - aa/2*(uplus - uminus)
end

"""
compute_fluxes!(hh, Flux, u, mesh, dt, M, alg::FVSKTAlgorithm, ::Type{Val{true}})
Numerical flux of Kurkanov Tadmor scheme in 1D
"""
function compute_fluxes!(hh, Flux, u, mesh, dt, M, alg::FVSKTAlgorithm, ::Type{Val{true}})
    slopeLimiter = alg.slopeLimiter
    #update vector
    # 1. slopes
    ∇u = compute_slopes(u, mesh, slopeLimiter, M, Val{true})

    Threads.@threads for j in edge_indices(mesh)
        inner_loop!(hh,j,u,∇u,mesh,Flux, alg)
    end
end

function compute_fluxes!(hh, Flux, u, mesh, dt, M, alg::FVSKTAlgorithm, ::Type{Val{false}})
    slopeLimiter = alg.slopeLimiter
    #update vector
    # 1. slopes
    ∇u = compute_slopes(u, mesh, slopeLimiter, M, Val{false})

    for j in edge_indices(mesh)
        inner_loop!(hh,j,u,∇u,mesh,Flux, alg)
    end
end

function inner_loop!(hh,j,u,∇u,mesh,Flux, DiffMat, alg::FVSKTAlgorithm)
    # Local speeds of propagation
    uminus=cellval_at_left(j,u,mesh)+0.5*cellval_at_left(j,∇u,mesh)
    uplus=cellval_at_right(j,u,mesh)-0.5*cellval_at_right(j,∇u,mesh)
    ul = cellval_at_left(j,u,mesh)
    ur = cellval_at_right(j,u,mesh)
    aa = max(fluxρ(uminus,Flux),fluxρ(uplus,Flux))
    # Numerical Fluxes
    @inbounds hh[j,:] = 0.5*(Flux(uplus)+Flux(uminus)) - aa/2*(uplus - uminus) - 0.5*(DiffMat(ur)+DiffMat(ul))*cellval_at_left(j,∇u,mesh)/mesh.Δx
end

function compute_Dfluxes!(hh, Flux, DiffMat, u, mesh, dt, M, alg::FVSKTAlgorithm, ::Type{Val{true}})
    slopeLimiter = alg.slopeLimiter
    #update vector
    # 1. slopes
    ∇u = compute_slopes(u, mesh, slopeLimiter, M, Val{true})

    Threads.@threads for j in edge_indices(mesh)
        inner_loop!(hh,j,u,∇u,mesh,Flux, DiffMat, alg)
    end
end

function compute_Dfluxes!(hh, Flux, DiffMat, u, mesh, dt, M, alg::FVSKTAlgorithm, ::Type{Val{false}})
    slopeLimiter = alg.slopeLimiter
    #update vector
    # 1. slopes
    ∇u = compute_slopes(u, mesh, slopeLimiter, M, Val{false})

    for j in edge_indices(mesh)
        inner_loop!(hh,j,u,∇u,mesh,Flux, DiffMat, alg)
    end
end
