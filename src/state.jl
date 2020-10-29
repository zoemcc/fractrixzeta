struct GameState{Player <: AbstractPlayerState, 
        PlayerStateHistory <: AbstractPlayerStateHistory, 
        W <: AbstractWorldState} <: AbstractGameState

    player_state::Player
    player_state_history::PlayerStateHistory
    worldstate::W
end

player(gamestate::GameState) = gamestate.player_state
world(gamestate::GameState) = gamestate.worldstate

function init_game_state()
    GameState(init_player_state(), init_player_state_history(), init_world_state())
end

function timestep_game_state(gamestate::GameState, currentintent::Vector{OneIntent}, deltatime::Float64)
    timestep_player_state(gamestate.player_state, currentintent, deltatime)

end

mutable struct PlayerStateNoResource{T <: Real} <: AbstractPlayerState
    position::Complex{T}
    rotation::T
    scale::T
end

position(player::PlayerStateNoResource) = player.position
rotation(player::PlayerStateNoResource) = player.rotation
scale(player::PlayerStateNoResource) = player.scale

function init_player_state()
    T = Float64
    pos = Complex{T}(0, 0)
    rot = T(0)
    scale = T(-3)
    PlayerStateNoResource(pos, rot, scale)
end

function timestep_player_state(playerstate::PlayerStateNoResource{Float64}, currentintent::Vector{OneIntent}, deltatime::Float64)
    numtype = Float64
    expscale = numtype(2 ^ -playerstate.scale)
    cosrot = numtype(cos(playerstate.rotation))
    sinrot = numtype(sin(playerstate.rotation))
    for i in eachindex(currentintent)
        @unpack playerintent, scale, intended = currentintent[i]
        if intended
            # basically a switch statement
            if playerintent == moveforward
                playerstate.position += Complex(-sinrot * scale * expscale * deltatime, 
                                                 cosrot * scale * expscale * deltatime)
            elseif playerintent == movebackward
                playerstate.position -= Complex(-sinrot * scale * expscale * deltatime, 
                                                 cosrot * scale * expscale * deltatime)
            elseif playerintent == moveleft
                playerstate.position -= Complex(cosrot * scale * expscale * deltatime, 
                                                sinrot * scale * expscale * deltatime)
            elseif playerintent == moveright
                playerstate.position += Complex(cosrot * scale * expscale * deltatime, 
                                                sinrot * scale * expscale * deltatime)
            elseif playerintent == zoomout
                playerstate.scale -= scale * deltatime
            elseif playerintent == zoomin
                playerstate.scale += scale * deltatime
            elseif playerintent == rotateleft
                playerstate.rotation += scale * deltatime
            elseif playerintent == rotateright
                playerstate.rotation -= scale * deltatime
            end
        end
    end
end

struct PlayerStateHistoryBasic{Player <: AbstractPlayerState} <: AbstractPlayerStateHistory
    history::Array{Player, 1} # possibly make this more general
end

function init_player_state_history()
    PlayerStateHistoryBasic(Array{PlayerStateNoResource{Float64}, 1}(undef, 0))
end

mutable struct WorldStateBasic{T <: Real, 
        ConformalTransform <: AbstractConformalTransform,
        LightHouse <: AbstractLightHouse} <: AbstractWorldState

    current_transform::ConformalTransform
    lantern_storage::Array{LightHouse, 1} # possibly make this more general
    lantern_graph::SimpleGraph{Int64}
    simtime::T
end

current_transform(world::WorldStateBasic) = world.current_transform

function init_world_state()
    T = Float64
    conformal = basic_rational()
    #conformal = identity_mobius()
    testpoint = transform(conformal, ComplexF64(1, 0))
    lantern_storage = Array{AbstractLightHouse, 1}(undef, 0)
    lantern_graph = SimpleGraph(0)
    simtime = T(0)
    WorldStateBasic(conformal, lantern_storage, lantern_graph, simtime)
end




