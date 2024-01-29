defmodule ExBanking.Utils.ValidatorTest do
  use ExUnit.Case

  describe "validate_create_user_args/1" do
    test "returns true for valid user names" do
      assert ExBanking.Utils.Validator.validate_create_user_args("valid_user") == true
    end

    test "returns error for non-string user names" do
      assert ExBanking.Utils.Validator.validate_create_user_args(123) ==
               {:error, :wrong_arguments}
    end

    test "returns error for empty user names" do
      assert ExBanking.Utils.Validator.validate_create_user_args("") == {:error, :wrong_arguments}
    end
  end

  describe "validate_deposit_args/3" do
    test "validates correct deposit arguments" do
      assert ExBanking.Utils.Validator.validate_deposit_args("user", 100, "EUR") == true
    end

    test "returns error for invalid user in deposit arguments" do
      assert ExBanking.Utils.Validator.validate_deposit_args(123, 100, "EUR") ==
               {:error, :wrong_arguments}
    end

    test "returns error for negative amount in deposit arguments" do
      assert ExBanking.Utils.Validator.validate_deposit_args("user", -100, "EUR") ==
               {:error, :wrong_arguments}
    end

    test "returns error for invalid currency in deposit arguments" do
      assert ExBanking.Utils.Validator.validate_deposit_args("user", 100, 123) ==
               {:error, :wrong_arguments}
    end
  end

  describe "validate_withdraw_args/3" do
    test "validates correct withdraw arguments" do
      assert ExBanking.Utils.Validator.validate_withdraw_args("user", 50, "USD") == true
    end

    # Similar tests for invalid inputs...
  end

  describe "validate_get_balance/2" do
    test "validates correct get balance arguments" do
      assert ExBanking.Utils.Validator.validate_get_balance("user", "GBP") == true
    end

    # Similar tests for invalid inputs...
  end

  describe "validate_send/4" do
    test "validates correct send arguments" do
      assert ExBanking.Utils.Validator.validate_send("user1", "user2", 20, "JPY") == true
    end

    # Similar tests for invalid inputs...
  end
end
