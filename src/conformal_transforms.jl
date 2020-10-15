abstract type AbstractConformalTransform end

struct MobiusTransform{T <: Real} <: AbstractConformalTransform
    a::Complex{T}
    b::Complex{T}
    c::Complex{T}
    d::Complex{T}
end

function identity_mobius()
    MobiusTransform{Float64}(1, 0, 0, 1)
end

function transform()
end
