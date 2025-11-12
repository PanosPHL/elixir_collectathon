defmodule ElixirCollectathonWeb.HomeLive do
  use ElixirCollectathonWeb, :live_view
  alias ElixirCollectathonWeb.Components.Cards.FeatureCard, as: FeatureCard

  attr :icon_name, :string, required: true
  slot :header, required: true
  slot :inner_block, required: true

  def feature_card(assigns) do
    ~H"""
    <div class="p-6 rounded-lg bg-[#3e4451] border border-gray-700 shadow-xl">
      <.icon class="size-8 mb-2" name={@icon_name} />
      <h4 class="text-xl font-semibold text-white mb-2">{render_slot(@header)}</h4>
      <p class="text-gray-400 text-sm">
        {render_slot(@inner_block)}
      </p>
    </div>
    """
  end

  def mount(_, _, socket) do
    {:ok, socket}
  end
end
