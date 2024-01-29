defmodule ExBanking.Banking.BalanceManagerTest do
  use ExUnit.Case

  alias ExBanking.Banking.BalanceManager
  alias ExBanking.Accounts.UserManager
  alias ExBanking.Banking.Transaction

  @user "user"
  @amount 10
  @currency "euro"

  setup do
    {:ok, pid} = UserManager.create_user(@user)
    BalanceManager.start_link(pid)

    on_exit(fn ->
      Agent.stop(pid)
    end)

    %{pid: pid}
  end

  describe "can_withdraw_amount/3" do
    test "if user doesn't have enough amount to withdraw, return not enough money error", %{
      pid: pid
    } do
      assert BalanceManager.withdraw(pid, @amount * 2, @currency) == :error
    end

    test "if user has required balance in the account, return true", %{pid: pid} do
      BalanceManager.deposit(pid, @amount, @currency)

      assert Transaction.can_withdraw_amount(pid, @amount, @currency)
    end

    test "if user has more than required balance in the account, return true", %{pid: pid} do
      BalanceManager.deposit(pid, @amount * 2, @currency)

      assert Transaction.can_withdraw_amount(pid, @amount, @currency)
    end
  end

  describe "deposit/3" do
    test "correctly adds the deposit amount to the user's balance", %{pid: pid} do
      assert BalanceManager.deposit(pid, @amount, @currency) == {:ok, @amount}
      assert BalanceManager.get_balance(pid, @currency) == {:ok, @amount}
    end

    test "handles cases where the currency doesn't exist", %{pid: pid} do
      assert BalanceManager.deposit(pid, @amount, "usd") == {:ok, @amount}
      assert BalanceManager.get_balance(pid, "usd") == {:ok, @amount}
    end
  end

  describe "withdraw/3" do
    test "if user doesn't have enough amount to withdraw, return not enough money error", %{
      pid: pid
    } do
      BalanceManager.deposit(pid, @amount / 2, @currency)
      assert BalanceManager.withdraw(pid, @amount, @currency) == :error
    end

    test "if user has required balance in the account, return true", %{pid: pid} do
      BalanceManager.deposit(pid, @amount, @currency)
      assert Transaction.can_withdraw_amount(pid, @amount, @currency)
    end

    test "handles cases where the currency doesn't exist", %{pid: pid} do
      assert BalanceManager.withdraw(pid, @amount, "usd") == :error
    end

    test "handles cases where the user doesn't have enough balance", %{pid: pid} do
      assert BalanceManager.withdraw(pid, @amount * 2, @currency) == :error
    end
  end
end
