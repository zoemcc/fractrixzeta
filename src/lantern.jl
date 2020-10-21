struct NoLantern <: AbstractLantern end

struct DistanceGoalLantern{T <: Real} <: LossFunctionLantern
    startpoint::Complex{T}
    goalpoint::Complex{T}
end


function evolvetransform(lantern::DistanceGoalLantern{T}, current_transform::MobiusTransform{T}, playerstate::AbstractPlayerState) where {T <: Real}
    distfunc = mobius -> complexdistsq(transform(mobius, lantern.startpoint), lantern.goalpoint)
    @show playerstate
    #@show methods(position)
    #@show @which position(playerstate)
    #@show position(playerstate)
    mapped_orig_player_pos = transform(current_transform, playerstate.position)

    num_steps = 1
    unmapped_player_pos = Vector{Complex{T}}(undef, num_steps + 1)
    unmapped_player_pos[1] = playerstate.position
    lr = 0.005
    for l in 1:num_steps
        distparams = distfunc(current_transform)
        gradmobius = gradient(distfunc, current_transform)[1].x
        gradmobiusSV = SVector(gradmobius...)

        #@show current_transform .+ gradmobius
        addequals(current_transform, -lr .* gradmobiusSV)
        unmapped_player_pos[l + 1] = inversetransform(current_transform, mapped_orig_player_pos)
    end
    playerstate.position = unmapped_player_pos[end]
    current_transform
end

