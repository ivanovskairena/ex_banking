defmodule ExBanking do
  @moduledoc """
  Main interface for the ExBanking application.
  """

  alias ExBanking.Accounts.RequestLimiter
  alias ExBanking.Banking.Transaction
  alias ExBanking.Accounts.UserManager
  alias ExBanking.Banking.BalanceManager
  alias ExBanking.Utils.Validator

  @spec create_user(user :: String.t()) :: :ok | {:error, :wrong_arguments | :user_already_exists}
  def create_user(user) do
    with true <- Validator.validate_create_user_args(user),
         {:error, :user_does_not_exist} <- UserManager.check_user_existence(user),
         {:ok, _pid} <- UserManager.create_user(user) do
      :ok
    else
      {:error, :wrong_arguments} -> {:error, :wrong_arguments}
      {:error, :user_already_exists} -> {:error, :user_already_exists}
      {:error, :user_does_not_exist} -> {:error, :unexpected_error}
    end
  end

  @spec deposit(user :: String.t(), amount :: number, currency :: String.t()) ::
          {:ok, new_balance :: number}
          | {:error, :wrong_arguments | :user_does_not_exist | :too_many_requests_to_user}
  def deposit(user, amount, currency) do
    RequestLimiter.manage_request(user, fn pid ->
      BalanceManager.deposit(pid, amount, currency)
    end)
  end

  @spec withdraw(user :: String.t(), amount :: number, currency :: String.t()) ::
          {:ok, new_balance :: number}
          | {:error,
             :wrong_arguments
             | :user_does_not_exist
             | :not_enough_money
             | :too_many_requests_to_user}

  def withdraw(user, amount, currency) do
    with true <- Validator.validate_withdraw_args(user, amount, currency) do
      RequestLimiter.manage_request(user, fn pid ->
        BalanceManager.withdraw(pid, amount, currency)
      end)
    end
  end

  @spec get_balance(user :: String.t(), currency :: String.t()) ::
          {:ok, balance :: number}
          | {:error, :wrong_arguments | :user_does_not_exist | :too_many_requests_to_user}
  def get_balance(user, currency) do
    with true <- Validator.validate_get_balance(user, currency) do
      RequestLimiter.manage_request(user, fn pid ->
        BalanceManager.get_balance(pid, currency)
      end)
    end
  end

  @spec send(
          from_user :: String.t(),
          to_user :: String.t(),
          amount :: number,
          currency :: String.t()
        ) ::
          {:ok, from_user_balance :: number, to_user_balance :: number}
          | {:error,
             :wrong_arguments
             | :not_enough_money
             | :sender_does_not_exist
             | :receiver_does_not_exist
             | :too_many_requests_to_sender
             | :too_many_requests_to_receiver}
  def send(from_user, to_user, amount, currency) do
    with true <- Validator.validate_send(from_user, to_user, amount, currency) do
      RequestLimiter.manage_request(from_user, to_user, fn sender_pid, receiver_pid ->
        Transaction.send(sender_pid, receiver_pid, amount, currency)
      end)
    end
  end
end
