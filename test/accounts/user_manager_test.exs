defmodule ExBanking.Accounts.UserManagerTest do
  use ExUnit.Case

  alias ExBanking.Accounts.UserManager

  describe "create_user/1" do
    test "creates a new user successfully" do
      {:ok, pid} = UserManager.create_user("new_user")
      assert is_pid(pid)
    end

    test "returns an error when creating an existing user" do
      UserManager.create_user("existing_user")
      assert UserManager.create_user("existing_user") == {:error, :user_already_exists}
    end

    test "fails to create a user with invalid input" do
      assert UserManager.create_user(123) == {:error, :wrong_arguments}
      assert UserManager.create_user("") == {:error, :wrong_arguments}
    end
  end

  describe "delete_user/1" do
    setup do
      user = "test_user_#{:os.system_time()}"
      {:ok, user: user}
    end

    test "if user existed, delete it", %{user: user} do
      {:ok, _} = UserManager.create_user(user)
      {:ok, pid} = UserManager.lookup_user(user)
      :ok = UserManager.delete_user(pid)

      Process.monitor(pid)

      receive do
        {:DOWN, ^pid, :process, _object, _reason} -> :ok
      after
        5000 -> :timeout
      end

      assert UserManager.lookup_user(user) == {:error, :user_does_not_exist}
    end

    test "fails to delete a non-existing user" do
      non_existent_user = "non_existent_user_#{:os.system_time()}"
      assert UserManager.delete_user(non_existent_user) == {:error, :not_found}
    end
  end

  describe "lookup_user/1" do
    test "finds an existing user" do
      UserManager.create_user("test_user")
      assert {:ok, _pid} = UserManager.lookup_user("test_user")
    end

    test "fails to find a non-existing user" do
      assert UserManager.lookup_user("non_existent_user") == {:error, :user_does_not_exist}
    end
  end

  describe "check_user_existence/1" do
    test "confirms existence of a user" do
      UserManager.create_user("test_user")
      assert UserManager.check_user_existence("test_user") == {:error, :user_already_exists}
    end

    test "reports non-existence of a user" do
      assert UserManager.check_user_existence("non_existent_user") ==
               {:error, :user_does_not_exist}
    end

    test "fails to check existence for invalid input" do
      assert UserManager.check_user_existence(123) == {:error, :wrong_arguments}
      assert UserManager.check_user_existence("") == {:error, :wrong_arguments}
    end
  end

  describe "user request counts" do
    test "increments and decrements user request count correctly" do
      unique_user = "request_user_#{:os.system_time()}"
      UserManager.create_user(unique_user)
      UserManager.check_out(unique_user)
      assert UserManager.get_user_request_count(unique_user) > 0
      UserManager.check_in(unique_user)
      assert UserManager.get_user_request_count(unique_user) == 0
    end
  end
end
