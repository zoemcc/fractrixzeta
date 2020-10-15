abstract type AbstractRenderer end


struct MakieRenderer <: AbstractRenderer
    scene::AbstractPlotting.Scene
end

