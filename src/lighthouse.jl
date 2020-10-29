struct NoLightHouse <: AbstractLightHouse end

struct DistanceGoalLightHouse{T <: Real} <: LossFunctionLightHouse
    startpoint::Complex{T}
    goalpoint::Complex{T}
end


function evolvetransform(lantern::DistanceGoalLightHouse{T}, current_transform::MobiusTransform{T}, playerstate::PlayerStateNoResource) where {T <: Real}
    distfunc = mobius -> complexdistsq(transform(mobius, lantern.startpoint), lantern.goalpoint)
    #@show playerstate
    mapped_orig_player_pos = transform(current_transform, playerstate.position)

    num_steps = 1
    unmapped_player_pos = Vector{Complex{T}}(undef, num_steps + 1)
    unmapped_player_pos[1] = playerstate.position
    lr = 0.005
    for l in 1:num_steps
        distparams = distfunc(current_transform)
        gradmobius = gradient(distfunc, current_transform)[1].x
        gradmobiusSV = SVector(gradmobius...)

        addequals(current_transform, -lr .* gradmobiusSV)
        unmapped_player_pos[l + 1] = inversetransform(current_transform, mapped_orig_player_pos)
    end
    playerstate.position = unmapped_player_pos[end]
    current_transform
end

function evolvetransform(lantern::DistanceGoalLightHouse{T}, current_transform::ComplexRational{T, N}, playerstate::PlayerStateNoResource) where {T <: Real, N}
    distfunc = conformal -> complexdistsq(transform(conformal, lantern.startpoint), lantern.goalpoint)
    #@show playerstate
    mapped_orig_player_pos = transform(current_transform, playerstate.position)

    num_steps = 1
    unmapped_player_pos = Vector{Complex{T}}(undef, num_steps + 1)
    unmapped_player_pos[1] = playerstate.position
    lr = 0.005
    for l in 1:num_steps
        distparams = distfunc(current_transform)
        gradmobius = gradient(distfunc, current_transform)[1]
        #@show typeof(gradmobius)
        #@show gradmobius[:numerator], typeof(gradmobius[:numerator])
        #@show current_transform.numerator - (lr .* gradmobius[:numerator])
        @show norm(gradmobius[:numerator]), norm(gradmobius[:denominator])
        current_transform = ComplexRational(current_transform.numerator - (lr .* gradmobius[:numerator]), 
            current_transform.denominator - (lr .* gradmobius[:denominator]))
        #gradmobiusSV = SVector(gradmobius...)

        #addequals(current_transform, -lr .* gradmobiusSV)
        #unmapped_player_pos[l + 1] = inversetransform(current_transform, mapped_orig_player_pos)
        unmapped_player_pos[l + 1] = playerstate.position
    end
    playerstate.position = unmapped_player_pos[end]
    current_transform
end

