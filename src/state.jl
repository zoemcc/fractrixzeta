abstract type AbstractGameState end
abstract type AbstractPlayerState end
abstract type AbstractPlayerStateHistory end
abstract type AbstractWorldState end
abstract type AbstractConformalTransform end
abstract type AbstractLantern end


struct GameState{Player <: AbstractPlayerState, 
        PlayerStateHistory <: AbstractPlayerStateHistory, 
        W <: AbstractWorldState} <: AbstractGameState
    player_state::Player
    player_state_history::PlayerStateHistory
    worldstate::W
end

struct PlayerStateNoResource{T <: Real, Point <: AbstractPoint{2, T}} <: AbstractPlayerState
    position::Point
    rotation::T
    scale::T
end

struct PlayerStateHistoryBasic{Player <: AbstractPlayerState} <: AbstractPlayerStateHistory
    history::Array{Player, 1} # possibly make this more general
end

struct WorldStateBasic{T <: Real, 
        ConformalTransform <: AbstractConformalTransform,
        Lantern <: AbstractLantern} <: AbstractWorldState

    current_transform::ConformalTransform
    lantern_storage::Array{ConformalTransform, 1} # possibly make this more general
    lantern_graph::SimpleGraph # do I need to add a type parameter here?
    simtime::T
end




