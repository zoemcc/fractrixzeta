abstract type AbstractLantern end
abstract type LossFunctionLantern end

struct NoLantern <: AbstractLantern end

struct DistanceGoalLantern{T <: Real} <: LossFunctionLantern
    startpoint::Complex{T}
    goalpoint::Complex{T}
end


function evolvetransform(lantern::DistanceGoalLantern{T}, current_transform::MobiusTransform{T}) where {T <: Real}
    distfunc = mobius -> complexdist(transform(mobius, lantern.startpoint), lantern.goalpoint)
    lr = 0.005
    for l in 1:1
        distparams = distfunc(current_transform)
        gradmobius = gradient(distfunc, current_transform)[1].x
        weight = -lr * distparams
        gradmobiusSV = SVector(gradmobius...)

        #@show current_transform .+ gradmobius
        addequals(current_transform, weight .* gradmobiusSV)
    end
    current_transform
end

