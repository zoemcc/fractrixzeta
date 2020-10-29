module FractrixZeta

using MacroTools
using LightGraphs
using LinearAlgebra
using GeometryBasics
using FileIO
using Dates
using ColorTypes
using VideoIO
using StaticArrays
using Observables
using CUDA
using StructArrays
using Zygote
using Parameters
import Makie
import AbstractPlotting.MakieLayout
import AbstractPlotting
using MacroTools

const tau = 2pi
const τ = tau
const TAU = τ

include("abstracttypes.jl")
include("conformal_transforms.jl")
include("inputhandler.jl")
include("state.jl")
include("lighthouse.jl")
include("renderer.jl")
include("config.jl")
include("mandelbrot.jl")
include("game.jl")

function main()
    game = init_game()
    run_game(game)
    game
end

end


#=


High level organization:

AbstractGameState abstract type 
AbstractPlayerState abstract type 
AbstractWorldState abstract type 
AbstractConformalTransform abstract type 
AbstractLightHouse abstract type
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
        LightHouse graph
            history of transforms to warp between spaces
        SimTime
    end
end






=#
