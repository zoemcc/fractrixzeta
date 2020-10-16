module FractrixZeta

using LightGraphs
using GeometryBasics
using FileIO
using Dates
using ColorTypes
using VideoIO
using StaticArrays
using Observables
using CUDA
using Zygote
import Makie
import AbstractPlotting.MakieLayout
import AbstractPlotting
using MacroTools

const tau = 2pi
const τ = tau
const TAU = τ

include("conformal_transforms.jl")
include("lantern.jl")
include("state.jl")
include("renderer.jl")
include("inputhandler.jl")
include("config.jl")
include("mandelbrot.jl")
include("game.jl")

function main()
    game = init_game()
    run_game(game)
    #game
end

end


#=


High level organization:

AbstractGameState abstract type 
AbstractPlayerState abstract type 
AbstractWorldState abstract type 
AbstractConformalTransform abstract type 
AbstractLantern abstract type
AbstractRenderer abstract type

GameState struct <: AbstractGameState
    Designed to be a full reproduction of the state of the game.  
    Supports saving and loading.

    PlayerState <: AbstractPlayerState
        Position
        Rotation
        Scale
        Resources,etc,other relevant state
    end

    history of player states

    WorldState <: AbstractWorldState
        Current Transform
        Lantern graph
            history of transforms to warp between spaces
        SimTime
    end
end






=#
