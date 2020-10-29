@with_kw mutable struct OneIntent
    playerintent::PLAYERINTENT
    keybutton::AbstractPlotting.Keyboard.Button
    scale::Float64 = 1.0
    intended::Bool = false
end

struct NoInputHandler <: AbstractInputHandler end

struct InputHandler <: AbstractInputHandler
    currentintent::Vector{OneIntent} # does this need to be a parameter for speed?
    playerintentindex::Dict{PLAYERINTENT, Int64}
    callback::Observables.Observable{Nothing}
end


numtype = Float64
movementscale = numtype(0.2)
zoomscale = numtype(1.0)
rotscale = numtype(1.0)


defaultkeyboardmapping() = [
                            OneIntent(playerintent=moveforward, keybutton=Makie.Keyboard.w, scale=movementscale),
                            OneIntent(playerintent=movebackward, keybutton=Makie.Keyboard.s, scale=movementscale),
                            OneIntent(playerintent=moveleft, keybutton=Makie.Keyboard.a, scale=movementscale),
                            OneIntent(playerintent=moveright, keybutton=Makie.Keyboard.d, scale=movementscale),
                            OneIntent(playerintent=zoomout, keybutton=Makie.Keyboard.j, scale=zoomscale),
                            OneIntent(playerintent=zoomin, keybutton=Makie.Keyboard.k, scale=zoomscale),
                            OneIntent(playerintent=rotateleft, keybutton=Makie.Keyboard.q, scale=rotscale),
                            OneIntent(playerintent=rotateright, keybutton=Makie.Keyboard.e, scale=rotscale),
                            OneIntent(playerintent=plantlighthouse, keybutton=Makie.Keyboard.l),
                            OneIntent(playerintent=stoprenderloop, keybutton=Makie.Keyboard.p),
                            ]

function generate_input_handler(events::AbstractPlotting.Events, currentintent::Vector{OneIntent})


    # input processor
    callback = Makie.lift(events.keyboardbuttons) do but
        #@show but
        for i in eachindex(currentintent)
            @unpack keybutton = currentintent[i]
            currentintent[i].intended = keybutton in but
        end
        #@show currentintent
        nothing
    end

    playerintentindex = Dict([oneindex.playerintent => i for (i, oneindex) in enumerate(currentintent)])

    @show typeof(callback), callback
    handler = InputHandler(currentintent, playerintentindex, callback)


    handler
end


true

#=

    Makie.lift(image.events.keyboardbuttons) do but
        #@show but

        wdown = Makie.Keyboard.w in but
        adown = Makie.Keyboard.a in but
        sdown = Makie.Keyboard.s in but
        ddown = Makie.Keyboard.d in but

        jdown = Makie.Keyboard.j in but
        kdown = Makie.Keyboard.k in but

        udown = Makie.Keyboard.u in but
        idown = Makie.Keyboard.i in but

        endscene = Makie.Keyboard.left_control in but

        nothing
    end
        expscale = numtype(2.0 ^ -scalefactor)
        yrangeextent = numtype(expscale)
        xrangeextent = numtype(expscale * aspectratio)
        xstart = numtype(-xrangeextent / 2)
        ystart = numtype(-yrangeextent / 2)

        cosrot = numtype(cos(rotation))
        sinrot = numtype(sin(rotation))

        if wdown
            centerxlocal += -sinrot * movementscale * expscale * deltatime
            centerylocal += cosrot * movementscale * expscale * deltatime
            #@show centerxlocal
            #@show centerylocal
        end
        if adown
            centerxlocal -= cosrot * movementscale * expscale * deltatime
            centerylocal -= sinrot * movementscale * expscale * deltatime
            #@show centerxlocal
            #@show centerylocal
        end
        if sdown
            centerxlocal -= -sinrot * movementscale * expscale * deltatime
            centerylocal -= cosrot * movementscale * expscale * deltatime
            #@show centerxlocal
            #@show centerylocal
        end
        if ddown
            centerxlocal += cosrot * movementscale * expscale * deltatime
            centerylocal += sinrot * movementscale * expscale * deltatime
            #@show centerxlocal
            #@show centerylocal
        end

        # note: scale factor for Float32 is approximately capped at 32
        if jdown
            scalefactor -= zoomscale * deltatime
            expscale = numtype(2.0 ^ -scalefactor)
            yrangeextent = numtype(expscale)
            xrangeextent = numtype(expscale * aspectratio)
            xstart = numtype(-xrangeextent / 2)
            ystart = numtype(-yrangeextent / 2)
            #@show scalefactor
        end
        if kdown
            scalefactor += zoomscale * deltatime
            expscale = numtype(2.0 ^ -scalefactor)
            yrangeextent = numtype(expscale)
            xrangeextent = numtype(expscale * aspectratio)
            xstart = numtype(-xrangeextent / 2)
            ystart = numtype(-yrangeextent / 2)
            #@show scalefactor
        end

        if udown
            rotation -= rotscale * deltatime
            cosrot = numtype(cos(rotation))
            sinrot = numtype(sin(rotation))
            #@show rotation
        end
        if idown
            rotation += rotscale * deltatime
            cosrot = numtype(cos(rotation))
            sinrot = numtype(sin(rotation))
            #@show rotation
        end

        if curtime - mobiuswalktime > 3
            lambdaangletarget, adisktarget = randomdiskmobius()
            mobiuswalktime = curtime
        end

=#

