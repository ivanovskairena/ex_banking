defmodule ExBankingTest do
  use ExUnit.Case

  alias ExBanking.Accounts.UserManager

  @user_1 "user_1"
  @user_2 "user_2"

  @currency "euro"
  @amount 10.75

  describe "create_user/1" do
    test "create user" do
      assert :ok = ExBanking.create_user(@user_1)

      {:ok, pid} = UserManager.lookup_user(@user_1)
      UserManager.delete_user(pid)
    end
  end

  describe "deposit/3" do
    setup do
      {:ok, pid} = UserManager.create_user(@user_1)

      on_exit(fn -> UserManager.delete_user(pid) end)
    end

    test "deposit amount into user account" do
      assert {:ok, 10.75} == ExBanking.deposit(@user_1, @amount, @currency)
    end
  end

  describe "withdraw/3" do
    setup do
      {:ok, pid} = UserManager.create_user(@user_1)

      ExBanking.deposit(@user_1, @amount, @currency)

      on_exit(fn -> UserManager.delete_user(pid) end)
    end

    test "withdraw amount from the account" do
      {:ok, new_balance} = ExBanking.withdraw(@user_1, 5, @currency)
      assert new_balance == 5.75
    end
  end

  describe "get_balance/2" do
    setup do
      {:ok, pid} = UserManager.create_user(@user_1)

      on_exit(fn -> UserManager.delete_user(pid) end)
    end

    test "get account balance" do
      assert {:ok, 0.0} == ExBanking.get_balance(@user_1, @currency)
    end
  end

  describe "send/4" do
    setup do
      {:ok, sender_pid} = UserManager.create_user(@user_1)
      {:ok, receiver_pid} = UserManager.create_user(@user_2)

      ExBanking.deposit(@user_1, @amount, @currency)

      on_exit(fn ->
        UserManager.delete_user(sender_pid)
        UserManager.delete_user(receiver_pid)
      end)
    end

    test "send amount from one account to another account" do
      {:ok, from_user_balance, to_user_balance} = ExBanking.send(@user_1, @user_2, 5, @currency)
      assert from_user_balance == 5.75
      assert to_user_balance == 5.0
    end
  end
end
