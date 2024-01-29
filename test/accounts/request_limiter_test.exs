defmodule ExBanking.Accounts.RequestLimiterTest do
  use ExUnit.Case

  alias ExBanking.Banking.{Transaction, BalanceManager}
  alias ExBanking.Accounts.{UserManager, RequestLimiter}

  @user_1 "user_1"
  @user_2 "user_2"
  @currency "euro"
  @amount 10

  setup do
    {:ok, pid} = UserManager.create_user(@user_1)

    on_exit(fn -> UserManager.delete_user(pid) end)
  end

  describe "manage_request/2" do
    test "user exceeding request limit should return error" do
      task_1 =
        Task.async(fn ->
          RequestLimiter.manage_request(@user_1, fn pid ->
            BalanceManager.get_balance(pid, @currency)
          end)
        end)

      task_2 =
        Task.async(fn ->
          RequestLimiter.manage_request(@user_1, fn pid ->
            BalanceManager.get_balance(pid, @currency)
          end)
        end)

      Process.sleep(100)

      task_3 =
        Task.async(fn ->
          RequestLimiter.manage_request(@user_1, fn pid ->
            BalanceManager.get_balance(pid, @currency)
          end)
        end)

      [result_1, result_2, result_3] =
        Enum.map([task_1, task_2, task_3], fn task ->
          case Task.await(task) do
            {:ok, amount} -> {:ok, amount}
            _ -> {:error, :too_many_requests_to_user}
          end
        end)

      assert result_1 == {:ok, 0.0}
      assert result_2 == {:ok, 0.0}
      assert result_3 == {:error, :too_many_requests_to_user}
    end

    test "sender exceeding request limit should return error when limit is 1" do
      Application.put_env(:ex_banking, :maximum_allowed_request, 1)

      task_1 =
        Task.async(fn ->
          RequestLimiter.manage_request(@user_1, fn pid ->
            BalanceManager.deposit(pid, @amount, @currency)
          end)
        end)

      Process.sleep(100)

      task_2 =
        Task.async(fn ->
          RequestLimiter.manage_request(@user_1, @user_2, fn sender_id, receiver_id ->
            Transaction.send(sender_id, receiver_id, @amount, @currency)
          end)
        end)

      [result_1, result_2] =
        Enum.map([task_1, task_2], fn task ->
          case Task.await(task) do
            {:ok, amount} -> {:ok, amount}
            _ -> {:error, :too_many_requests_to_sender}
          end
        end)

      assert result_1 == {:ok, @amount}
      assert result_2 == {:error, :too_many_requests_to_sender}
    end

    test "receiver exceeding request limit should return error when limit is 1" do
      Application.put_env(:ex_banking, :maximum_allowed_request, 1)

      RequestLimiter.manage_request(@user_1, fn pid ->
        BalanceManager.deposit(pid, @amount, @currency)
      end)

      task_1 =
        Task.async(fn ->
          RequestLimiter.manage_request(@user_2, fn pid ->
            BalanceManager.deposit(pid, @amount, @currency)
          end)
        end)

      Process.sleep(200)

      task_2 =
        Task.async(fn ->
          RequestLimiter.manage_request(@user_1, @user_2, fn sender_id, receiver_id ->
            Transaction.send(sender_id, receiver_id, @amount, @currency)
          end)
        end)

      [result_1, result_2] =
        Enum.map([task_1, task_2], fn task ->
          case Task.await(task) do
            {:ok, amount} -> {:ok, amount}
            _ -> {:error, :too_many_requests_to_receiver}
          end
        end)

      assert result_1 == {:error, :too_many_requests_to_receiver}
      assert result_2 == {:error, :too_many_requests_to_receiver}
    end
  end

  describe "manage_request/3" do
    setup do
      {:ok, sender} = UserManager.create_user(@user_2)

      on_exit(fn -> UserManager.delete_user(sender) end)
    end

    test "sender exceeding request limit should return error" do
      task_1 =
        Task.async(fn ->
          RequestLimiter.manage_request(@user_1, fn pid ->
            BalanceManager.deposit(pid, @amount, @currency)
          end)
        end)

      task_2 =
        Task.async(fn ->
          RequestLimiter.manage_request(@user_1, fn pid ->
            BalanceManager.deposit(pid, @amount, @currency)
          end)
        end)

      Process.sleep(100)

      task_3 =
        Task.async(fn ->
          RequestLimiter.manage_request(@user_1, @user_2, fn sender_id, receiver_id ->
            Transaction.send(sender_id, receiver_id, @amount, @currency)
          end)
        end)

      [result_1, result_2, result_3] =
        Enum.map([task_1, task_2, task_3], fn task ->
          case Task.await(task) do
            {:ok, amount} -> {:ok, amount}
            _ -> {:error, :too_many_requests_to_sender}
          end
        end)

      assert result_1 == {:ok, @amount}
      assert result_2 == {:ok, @amount * 2}
      assert result_3 == {:error, :too_many_requests_to_sender}
    end

    test "receiver exceeding request limit should return error" do
      RequestLimiter.manage_request(@user_1, fn pid ->
        BalanceManager.deposit(pid, @amount, @currency)
      end)

      task_1 =
        Task.async(fn ->
          RequestLimiter.manage_request(@user_2, fn pid ->
            BalanceManager.deposit(pid, @amount, @currency)
          end)
        end)

      task_2 =
        Task.async(fn ->
          RequestLimiter.manage_request(@user_2, fn pid ->
            BalanceManager.deposit(pid, @amount, @currency)
          end)
        end)

      Process.sleep(200)

      task_3 =
        Task.async(fn ->
          RequestLimiter.manage_request(@user_1, @user_2, fn sender_id, receiver_id ->
            Transaction.send(sender_id, receiver_id, @amount, @currency)
          end)
        end)

      [result_1, result_2, result_3] =
        Enum.map([task_1, task_2, task_3], fn task ->
          case Task.await(task) do
            {:ok, amount} -> {:ok, amount}
            _ -> {:error, :too_many_requests_to_receiver}
          end
        end)

      assert result_1 == {:ok, @amount}
      assert result_2 == {:ok, @amount * 2}
      assert result_3 == {:error, :too_many_requests_to_receiver}
    end
  end
end
