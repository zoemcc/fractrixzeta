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

tau = 2pi
τ = tau
TAU = τ

include("state.jl")
include("renderer.jl")
include("mandelbrot.jl")

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
