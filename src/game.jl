
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
    inputhandler = NoInputHandler()
    Game(gamestate, renderer, inputhandler, config)
end

function run_game(game::Game)
    @time for i in 1:10000
        render_game(game.renderer, game.gamestate)
    end
end

