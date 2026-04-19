# Player discovery: start parametric (known K clusters), upgrade to
# Dirichlet Process once the parametric version is stable.
# See tasks.md 3.3 for the staging.

mutable struct ParametricPlayerCluster
    k::Int
    assignments::Vector{Int}
    centroids::Vector  # Player-parameter vectors
end

# Phase 3 stub.
