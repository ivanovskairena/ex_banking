defmodule ExBanking.Banking.Transaction do
  @moduledoc false
  defstruct [:currency, :amount]
  alias ExBanking.Banking.BalanceManager
  alias ExBanking.Utils.Validator

  @spec get_balance(Validator.user_pid(), Validator.currency()) :: {:ok, Validator.amount()}
  def get_balance(user, currency), do: {:ok, BalanceManager.get_balance(user, currency)}

  @spec send(Validator.user_pid(), Validator.user_pid(), Types.amount(), Types.currency()) ::
          {:ok, Validator.amount(), Types.amount()} | {:error, :not_enough_money}
  def send(from_user, to_user, amount, currency) do
    case BalanceManager.withdraw(from_user, amount, currency) do
      {:ok, from_user_balance} ->
        case BalanceManager.deposit(to_user, amount, currency) do
          {:ok, to_user_balance} ->
            {:ok, from_user_balance, to_user_balance}

          {:error, _} = error ->
            error
        end

      {:error, :not_enough_money} ->
        {:error, :withdrawal_failed}

      :error ->
        {:error, :transaction_error}
    end
  end

  @spec can_withdraw_amount(Validator.user_pid(), Validator.amount(), Validator.currency()) ::
          true | {:error, :not_enough_money}
  def can_withdraw_amount(user, amount, currency) do
    with {:ok, balance} <- get_balance(user, currency),
         false <- balance >= amount do
      {:error, :not_enough_money}
    end
  end
end
