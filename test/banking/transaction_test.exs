defmodule ExBanking.Banking.TransactionTest do
  use ExUnit.Case

  alias ExBanking.Banking.Transaction
  alias ExBanking.Banking.BalanceManager
  alias ExBanking.Accounts.UserManager

  @amount 10
  @currency "euro"

  setup do
    unique_user = "user_#{System.unique_integer([:positive])}"
    {:ok, pid} = UserManager.create_user(unique_user)
    BalanceManager.start_link(pid)
    BalanceManager.deposit(pid, @amount, @currency)

    on_exit(fn ->
      Agent.stop(pid)
    end)

    %{pid: pid}
  end

  describe "get_balance/2" do
    test "returns the user's balance", %{pid: pid} do
      assert Transaction.get_balance(pid, @currency) == {:ok, {:ok, @amount}}
    end
  end

  describe "deposit/3" do
    test "correctly adds the deposit amount to the user's balance", %{pid: pid} do
      assert BalanceManager.deposit(pid, @amount, @currency) == {:ok, @amount * 2}
      assert Transaction.get_balance(pid, @currency) == {:ok, {:ok, @amount * 2}}
    end

    test "handles cases where the currency doesn't exist", %{pid: pid} do
      assert BalanceManager.deposit(pid, @amount, "usd") == {:ok, @amount}
      assert Transaction.get_balance(pid, "usd") == {:ok, {:ok, @amount}}
    end
  end

  describe "send/4" do
    test "correctly transfers money between users", %{pid: pid} do
      unique_user2 = "user2_#{System.unique_integer([:positive])}"
      {:ok, pid2} = UserManager.create_user(unique_user2)
      BalanceManager.start_link(pid2)
      BalanceManager.deposit(pid2, 0.0, @currency)

      {:ok, from_user_balance, to_user_balance} =
        Transaction.send(pid, pid2, @amount, @currency)

      assert from_user_balance == 0.0
      assert to_user_balance == @amount
    end

    test "handles cases where the sender doesn't have enough balance", %{pid: pid} do
      {:ok, pid2} = UserManager.create_user("user2")
      BalanceManager.start_link(pid2)
      BalanceManager.deposit(pid2, 0.0, @currency)

      assert Transaction.send(pid, pid2, @amount * 2, @currency) == {:error, :transaction_error}
    end
  end

  describe "can_withdraw_amount/3" do
    test "returns true if the user has enough balance", %{pid: pid} do
      assert Transaction.can_withdraw_amount(pid, @amount, @currency) == true
    end

    test "returns {:error, :not_enough_money} if the user doesn't have enough balance", %{
      pid: pid
    } do
      assert Transaction.can_withdraw_amount(pid, @amount * 2, @currency) == true
    end
  end
end
