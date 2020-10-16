abstract type AbstractConformalTransform end

mutable struct MobiusTransform{T <: Real} <: AbstractConformalTransform
    a::Complex{T}
    b::Complex{T}
    c::Complex{T}
    d::Complex{T}
end

function addequals(mobius::MobiusTransform{T}, sv::SArray{Tuple{4},Complex{Float64},1,4}) where {T <: Real}
    mobius.a += sv[1]
    mobius.b += sv[2]
    mobius.c += sv[3]
    mobius.d += sv[4]
    mobius
end

function identity_mobius()
    MobiusTransform{Float64}(1, 0, 0, 1)
end

function transform(mobius::MobiusTransform{T}, point::Complex{T})::Complex{T} where {T <: Real}
    (point * mobius.a + mobius.b) / (point * mobius.c + mobius.d)
end
