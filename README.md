# ElixirCollectathon
https://github.com/user-attachments/assets/074c8895-3987-4940-b106-cca1ce29b007

ElixirCollectathon is a real-time multiplayer game built with [Phoenix LiveView](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html). Players compete to collect letters spawning on the map to spell out the word "ELIXIR".

The game features a unique "second screen" experience where the main game board is displayed on a large screen (e.g., a laptop or TV), and players use their mobile devices as controllers by scanning a QR code.

## Features

*   **Real-time Multiplayer:** Support for up to 4 players in a single game instance.
*   **Mobile Controller:** Players join by scanning a QR code, turning their phone into a joystick controller.
*   **High-Performance Game Loop:** Game state is updated at 30Hz (every 33ms) using GenServer and broadcasted via Phoenix PubSub.
*   **Physics Engine:** Custom collision detection and movement resolution for smooth player interactions.
*   **Automatic Cleanup:** Game servers automatically shut down after 10 minutes of inactivity to save resources.

## Tech Stack

*   **Elixir & Phoenix:** The core framework for high-concurrency and fault tolerance.
*   **Phoenix LiveView:** For real-time, server-rendered UI updates without writing complex client-side JavaScript.
*   **Tailwind CSS:** For modern and responsive styling.
*   **GenServer:** Manages the state and logic for each individual game.
*   **Phoenix PubSub:** Handles real-time communication between the game server and connected clients.

## Getting Started

To start your Phoenix server:

1.  Run `mix setup` to install and setup dependencies.
2.  Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`.

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Code Highlights

### The Game Loop
The heart of the game is a `GenServer` that runs a tick every 33ms. It updates player positions, checks for collisions, and broadcasts the new state to all connected clients.

```elixir
# lib/elixir_collectathon/games/server.ex

@impl GenServer
def handle_info(:tick, %Game{is_running: true} = state) do
  %Game{current_letter: current_letter, winner: winner, timer_ref: timer_ref} =
    updated_state =
    Game.update_game_state(state)

  broadcast(updated_state)

  cond do
    winner ->
      :timer.cancel(timer_ref)
      Process.send_after(self(), {:shutdown_game, :normal}, 300)
      {:noreply, updated_state |> Game.stop()}

    is_nil(current_letter) ->
      {:noreply, updated_state |> Game.spawn_letter()}

    true ->
      {:noreply, updated_state}
  end
end
```

### Real-time UI Updates
The `GameLive` view subscribes to the game's topic and updates the UI in real-time as state changes are broadcasted.

```elixir
# lib/elixir_collectathon_web/live/game/game_live.ex

@impl Phoenix.LiveView
def handle_info({:state, %Game{players: players, winner: winner} = state}, socket) do
  {count, sorted_players} = prepare_players(players)

  {
    :noreply,
    socket
    |> assign(player_count: count, winner: winner)
    |> stream(:players, sorted_players, dom_id: &"p-#{&1.name}", reset: true)
    |> push_event("game_update", state)
  }
end
```

### Client-Side Rendering
The client uses a simple JavaScript hook to render the game state onto an HTML5 Canvas. It uses `requestAnimationFrame` for smooth rendering and updates based on the state received from the server.

```javascript
// assets/js/game.js

export default {
  mounted() {
    const canvas = this.el;
    const ctx = canvas.getContext('2d');
    let state = { players: {}, current_letter: null };

    this.handleEvent('game_update', (newState) => {
      state = newState;
    });

    const draw = () => {
      ctx.clearRect(0, 0, canvas.width, canvas.height);

      // Draw Letter
      if (state.current_letter) {
        const { char, position: [x, y] } = state.current_letter;
        ctx.fillStyle = 'white';
        ctx.fillText(char, x + 8, y + 42);
      }

      // Draw Players
      for (const id in state.players) {
        const player = state.players[id];
        const [x, y] = player.position;
        ctx.fillStyle = player.color;
        ctx.fillRect(x, y, 40, 40);
      }

      requestAnimationFrame(draw);
    };

    draw();
  },
};
```

### Player Movement Logic
Movement is calculated on the server side, ensuring a consistent state for all players.

```elixir
# lib/elixir_collectathon/games/game.ex

defp calculate_target_position(player_position, player_velocity) do
  {x, y} = player_position
  {vx, vy} = player_velocity
  {map_x, map_y} = @map_size
  player_size = Player.get_player_size()

  {
    Utils.clamp(trunc(x + vx * @movement_speed), 0, map_x - player_size),
    Utils.clamp(trunc(y + vy * @movement_speed), 0, map_y - player_size)
  }
end
```
