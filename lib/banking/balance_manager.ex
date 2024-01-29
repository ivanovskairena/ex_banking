defmodule ExBanking.Banking.BalanceManager do
  @moduledoc "Manages account balances and transactions."

  use Agent, restart: :temporary

  alias ExBanking.Utils.Validator

  alias ExBanking.Accounts.UserManager
  alias ExBanking.Banking.Transaction

  @enable_user_request_delay Application.compile_env(:ex_banking, :enable_user_request_delay)

  @spec start_link(Validator.user()) ::
          {:ok, Validator.user_pid()} | {:error, {:already_started, Validator.user_pid()} | term}
  def start_link(user) do
    UserManager.initialize_user_request_counter(user)
    Agent.start_link(fn -> [] end, name: via_tuple(user))
  end

  def get_balance(user, currency) do
    enable_user_request_delay()

    Agent.get(user, fn state ->
      balance = find_balance(state, currency)
      {:ok, balance}
    end)
  end

  # Helper function for get_balance
  defp find_balance(state, currency) do
    case Enum.find(state, fn object -> object.currency == currency end) do
      nil -> 0.0
      object -> object.amount
    end
  end

  @spec deposit(Validator.user_pid(), Validator.amount(), Validator.currency()) ::
          {:ok, Validator.amount()}
  def deposit(user, amount, currency) do
    enable_user_request_delay()

    Agent.get_and_update(user, fn state ->
      state
      |> Enum.split_with(&(&1.currency == currency))
      |> case do
        {[], _} ->
          amount = set_precision(amount)
          balance = %Transaction{currency: currency, amount: amount}

          {{:ok, balance.amount}, [balance | state]}

        {[object], remaining_state} ->
          amount = set_precision(object.amount + amount)
          balance = %{object | amount: amount}

          {{:ok, balance.amount}, [balance | remaining_state]}
      end
    end)
  end

  @spec withdraw(Validator.user_pid(), Validator.amount(), Validator.currency()) ::
          {:ok, Validator.amount()} | {:error, :not_enough_money | :currency_not_found}
  def withdraw(user, amount, currency) do
    enable_user_request_delay()

    Agent.get_and_update(user, fn state ->
      case Enum.find(state, &(&1.currency == currency)) do
        nil ->
          {:error, :currency_not_found}

        object when object.amount < amount ->
          {:error, :not_enough_money}

        object ->
          new_amount = set_precision(object.amount - amount)
          balance = %{object | amount: new_amount}
          new_state = update_state(state, balance)
          {{:ok, balance.amount}, new_state}
      end
    end)
  end

  defp update_state(state, updated_balance) do
    Enum.map(state, fn
      object when object.currency == updated_balance.currency ->
        updated_balance

      object ->
        object
    end)
  end

  # defp find_currency(state, currency) do
  #   case Enum.split_with(state, &(&1.currency == currency)) do
  #     {[], _} ->
  #       {:error, :currency_not_found}

  #     {[object], remaining_state} ->
  #       {:ok, object, remaining_state}
  #   end
  # end

  # defp update_balance(object, remaining_state, amount) do
  #   if object.amount < amount do
  #     {:error, :not_enough_money}
  #   else
  #     new_amount = set_precision(object.amount - amount)
  #     balance = %{object | amount: new_amount}
  #     {{:ok, balance.amount}, [balance | remaining_state]}
  #   end
  # end

  @spec set_precision(Validator.amount()) :: float()
  defp set_precision(amount) when is_integer(amount), do: amount + 0.0
  defp set_precision(amount), do: Float.round(amount, 2)

  @spec via_tuple(Validator.user()) :: tuple()
  defp via_tuple(user), do: {:via, Registry, {ExBanking.Accounts.UserManager, user}}

  @spec enable_user_request_delay() :: :ok
  defp enable_user_request_delay do
    if @enable_user_request_delay do
      Process.sleep(100)
    else
      :ok
    end
  end
end
