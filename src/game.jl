
struct Game{GameState <: AbstractGameState, Renderer <: AbstractRenderer, InputHandler <: AbstractInputHandler, Config <: AbstractConfig}
    gamestate::GameState
    renderer::Renderer
    inputhandler::InputHandler
    config::Config
end

function init_game()
    # do basic shit first
    config = NoConfig()
    gamestate = init_game_state()
    renderer = init_renderer()
    inputhandler = generate_input_handler(scene(renderer).events, defaultkeyboardmapping())
    Game(gamestate, renderer, inputhandler, config)
end

function run_game(game::Game)
    newlantern = DistanceGoalLantern(Complex(-1.4, 0.0), Complex(0.7, 0.7))
    lasttime = time()
    
    stoprenderloopindex = game.inputhandler.playerintentindex[stoprenderloop]
    plantlanternindex = game.inputhandler.playerintentindex[plantlantern]
    while true
        if game.inputhandler.currentintent[stoprenderloopindex].intended
            break
        else
            if game.inputhandler.currentintent[plantlanternindex].intended
                newlantern = DistanceGoalLantern(Complex(-1.4, 0.0), Complex(randn(Float64, 2)...))
            end
            nowtime = time()
            deltatime = nowtime - lasttime
            lasttime = nowtime
            timestep_game_state(game.gamestate, game.inputhandler.currentintent, deltatime)

            render_game(game.renderer, game.gamestate) 
            new_transform = evolvetransform(newlantern, game.gamestate.worldstate.current_transform)
        end
    end
    game
end

