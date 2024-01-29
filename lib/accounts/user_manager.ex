defmodule ExBanking.Accounts.UserManager do
  @moduledoc "Handles user registration and validation."

  alias ExBanking.Utils.Validator
  use DynamicSupervisor

  @spec start_link(any()) :: :ignore | {:error, any()} | {:ok, pid()}
  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @spec init(:ok) ::
          {:ok,
           %{
             extra_arguments: list(),
             intensity: non_neg_integer(),
             max_children: :infinity | non_neg_integer(),
             period: pos_integer(),
             strategy: :one_for_one
           }}
  def init(:ok), do: DynamicSupervisor.init(strategy: :one_for_one)

  @spec create_user(Validator.user()) :: :ok | {:error, :user_already_exists | :wrong_arguments}
  def create_user(user) do
    case Validator.validate_create_user_args(user) do
      true ->
        case check_user_existence(user) do
          {:error, :user_does_not_exist} ->
            {:ok, pid} =
              DynamicSupervisor.start_child(
                ExBanking.Accounts.UserSupervisor,
                {ExBanking.Banking.BalanceManager, user}
              )

            {:ok, pid}

          {:ok, pid} ->
            {:ok, pid}

          {:error, :user_already_exists} ->
            {:error, :user_already_exists}
        end

      {:error, :wrong_arguments} ->
        {:error, :wrong_arguments}
    end
  end

  @spec check_user_existence(Validator.user()) ::
          {:error, :user_does_not_exist | :user_already_exists}
  def check_user_existence(user) do
    case Validator.validate_create_user_args(user) do
      true ->
        case lookup_user(user) do
          {:ok, _pid} -> {:error, :user_already_exists}
          {:error, _reason} -> {:error, :user_does_not_exist}
        end

      {:error, :wrong_arguments} ->
        {:error, :wrong_arguments}
    end
  end

  @spec delete_user(Validator.user_pid() | Validator.user()) :: :ok | {:error, :not_found}
  def delete_user(user) when is_binary(user) do
    case lookup_user(user) do
      {:ok, pid} ->
        # IO.puts("Deleting user with PID: #{inspect(pid)}")
        delete_user(pid)

      {:error, _} ->
        # IO.puts("User not found: #{user}")
        {:error, :not_found}
    end
  end

  def delete_user(pid_or_user) when is_pid(pid_or_user) do
    # IO.puts("Terminating user process: #{inspect(pid_or_user)}")
    DynamicSupervisor.terminate_child(ExBanking.Accounts.UserSupervisor, pid_or_user)
  end

  @spec lookup_user(Validator.user(), atom()) ::
          {:ok, Validator.user_pid()} | {:error, lookup_user_error()}
  def lookup_user(user, type \\ nil) do
    case Registry.lookup(__MODULE__, user) do
      [{pid, _value}] -> {:ok, pid}
      _ -> {:error, lookup_user_error(type)}
    end
  end

  @type lookup_user_error() ::
          :sender_does_not_exist | :receiver_does_not_exist | :user_does_not_exist

  def initialize_user_request_counter(user) do
    create_user_request_counter_table()
    insert_user(user)
  end

  def check_out(user), do: :ets.update_counter(__MODULE__, user, {2, 1})

  def check_in(user), do: :ets.update_counter(__MODULE__, user, {2, -1})

  def get_user_request_count(user) do
    case lookup(user) do
      [{_, count}] ->
        count

      [] ->
        initialize_user_request_counter(user)
        0
    end
  end

  defp create_user_request_counter_table do
    with :undefined <- :ets.whereis(__MODULE__) do
      :ets.new(__MODULE__, [:public, :named_table, read_concurrency: true])
    end
  end

  defp insert_user(user) do
    case lookup(user) do
      [] -> :ets.insert(__MODULE__, {user, 0})
      _ -> :ets.update_counter(__MODULE__, user, {2, 0})
    end
  end

  defp lookup(user), do: :ets.lookup(__MODULE__, user)
  defp lookup_user_error(type)
  defp lookup_user_error(:sender), do: :sender_does_not_exist
  defp lookup_user_error(:receiver), do: :receiver_does_not_exist
  defp lookup_user_error(_), do: :user_does_not_exist
end
