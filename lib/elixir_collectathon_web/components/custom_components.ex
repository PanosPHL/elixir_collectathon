defmodule ElixirCollectathonWeb.Components.CustomComponents do
  use Phoenix.Component

  attr :text_class, :string, required: true

  slot :header
  slot :inner_block, required: true

  def winner(assigns) do
    ~H"""
    <div
      id="game-winner"
      class="flex flex-col items-center gap-4 animate-bounce"
    >
      <%= if @header  do %>
        <h1 class="text-5xl font-bold text-transparent bg-clip-text bg-gradient-to-r from-yellow-400 via-yellow-300 to-yellow-500 text-center drop-shadow-lg">
          {render_slot(@header)}
        </h1>
      <% end %>
      <div class="flex flex-col items-center">
        <span class={@text_class <> " text-center px-8 py-4 align-middle font-black text-white bg-gradient-to-br from-yellow-400 to-yellow-600 rounded-3xl shadow-2xl inline-block animate-pulse"}>
          {render_slot(@inner_block)}
        </span>
      </div>
    </div>
    """
  end
end
