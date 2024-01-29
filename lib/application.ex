defmodule ExBanking.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Registry, keys: :unique, name: ExBanking.Accounts.UserManager},
      {DynamicSupervisor, name: ExBanking.Accounts.UserSupervisor, strategy: :one_for_one}
    ]

    opts = [strategy: :rest_for_one, name: ExBanking.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
