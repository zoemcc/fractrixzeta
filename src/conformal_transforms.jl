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

@inline function transform(mobius::MobiusTransform{T}, point::Complex{T})::Complex{T} where {T <: Real}
    (point * mobius.a + mobius.b) / (point * mobius.c + mobius.d)
end

@inline function inversetransform(mobius::MobiusTransform{T}, point::Complex{T})::Complex{T} where {T <: Real}
    (point * mobius.d - mobius.b) / (-point * mobius.c + mobius.a)
end


struct ComplexRational{T <: Real, N} <: AbstractConformalTransform
    numerator::SArray{Tuple{N},Complex{T},1,N} 
    denominator::SArray{Tuple{N},Complex{T},1,N} 
end

function identity_rational()
    num = @SVector ComplexF64[0, 1]
    den = @SVector ComplexF64[1, 0]
    ComplexRational{Float64, 2}(num, den)
end

function basic_rational()
    num = @SVector ComplexF64[0, 1, 1 + 0.1im, 0.1im]
    den = @SVector ComplexF64[1, 0.1 - 0.1im, 0.2, 0.01]
    ComplexRational(num, den)
end

function basic_rational(n)
    num = @SVector ComplexF64[0:n]
    den = @SVector ComplexF64[1, 0.1 - 0.1im, 0.2, 0.01]
    ComplexRational(num, den)
end

function addequals(rational::ComplexRational{T, N}, num::SArray{Tuple{N},Complex{T},1,N}, den::SArray{Tuple{N},Complex{T},1,N}) where {T <: Real, N}
    mobius.a += sv[1]
    mobius.b += sv[2]
    mobius.c += sv[3]
    mobius.d += sv[4]
    mobius
end

@inline function transform(rational::ComplexRational{T, N}, point::Complex{T})::Complex{T} where {T <: Real, N}
    num = evalpoly(point, rational.numerator)
    den = evalpoly(point, rational.denominator)
    num / den
end

