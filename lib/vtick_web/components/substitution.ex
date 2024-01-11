defmodule VtickWeb.Components.Substitution do
  use Phoenix.Component

  def lower_third(assigns) do
    ~H"""
    <div
      id={@id}
      class="current absolute bottom-16 w-full flex justify-center font-display"
      phx-hook="timeout"
      data-timeout="8000"
      data-removal="9000"
    >
      <div class="flex">
        <div class="logocontainer w-32 h-32 bg-vbldarkblue relative">
          <img class="icon absolute inset-4 w-24 h-24" src="/images/substitution.svg" />
          <img class="logo absolute inset-4 w-24 h-24" src={@player_out["team"]["logoImage200"]} />
        </div>
        <div class="mask h-32">
          <div class="namecontainer">
            <div class="playerout">
              <div class="name h-16 bg-vbldarkblue text-white flex items-center text-2xl">
                <strong class="mx-6"><%= @player_out["jerseyNumber"] %></strong>
                <span class="mr-8">
                  <%= @player_out["firstName"] %> <%= @player_out["lastName"] %>
                </span>
              </div>
              <div class="position h-16 bg-vblgray text-vbldarkblue flex items-center text-2xl">
                <span class="ml-6 mr-8">
                  <%= if Map.has_key?(@position_names, @player_out["position"]),
                    do: @position_names[@player_out["position"]],
                    else: @player_out["team"]["name"] %>
                </span>
              </div>
            </div>
            <div class="playerin">
              <div class="h-16 bg-vblgreen text-white flex items-center text-2xl">
                <strong class="mx-6"><%= @player_in["jerseyNumber"] %></strong>
                <span class="mr-8">
                  <%= @player_in["firstName"] %> <%= @player_in["lastName"] %>
                </span>
              </div>
              <div class="h-16 bg-vblgray text-vbldarkblue flex items-center text-2xl">
                <span class="ml-6 mr-8">
                  <%= if Map.has_key?(@position_names, @player_in["position"]),
                    do: @position_names[@player_in["position"]],
                    else: @player_in["team"]["name"] %>
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>
      <script>
        setTimeout(() => {
          const el = document.getElementById("<%= @id %>");
          el.classList.add("remove");
          }, 8000);
      </script>
    </div>
    """
  end
end
