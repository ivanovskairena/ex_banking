# ExBanking

**TODO: Add description**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `ex_banking` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_banking, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/ex_banking>.

## General Acceptance Criteria

* All code is stored in a git repository.

* It's a standard mix project with the application name :ex_banking.

* The main module is ExBanking, and its interface consists of a set of public functions.

* No database or disk storage is used; data is stored in memory.

* Any Elixir or Erlang library can be used, but the app is written in pure Elixir/Erlang/OTP.

# Public Functions

* create_user/1: Registers a new user with a zero balance.

* deposit/3: Increases a user's balance in a given currency.

* withdraw/3: Decreases a user's balance in a given currency.

* get_balance/2: Retrieves the balance for a user in a specific currency.

* send/4: Transfers an amount from one user to another.

Each function is expected to return a success result or an error result.

# API Reference

## User Management
ExBanking.create_user/1: Creates a new user with a zero balance.

```elixir  
ExBanking.create_user("user1") 
```

## Balance Operations
ExBanking.deposit/3: Deposits an amount into a user's account.

```elixir 
ExBanking.deposit("user1", 100.0, "USD") 
```


ExBanking.withdraw/3: Withdraws an amount from a user's account.

```elixir 
ExBanking.withdraw("user1", 50.0, "USD") 
```

ExBanking.get_balance/2: Retrieves the balance of a user's account.

```elixir 
ExBanking.get_balance("user1", "USD") 
```

## Transaction

ExBanking.send/4: Transfers an amount from one user's account to another.

```elixir 
ExBanking.send("user1", "user2", 25.0, "USD") 
```

# Performance

The system should handle 10 or fewer operations for each user at any given moment. Concurrent requests for different users are supported without performance degradation.

# Module Documentation

* ExBanking.Accounts.RequestLimiter

This module manages the request rate limiting per user to ensure the application does not process more than the allowed number of concurrent operations.

* ExBanking.Accounts.UserManager

Responsible for handling user registration and validation within the system.

* ExBanking.Banking.BalanceManager

Manages account balances and transactions, ensuring correct balance updates and concurrency control.

* ExBanking.Banking.Transaction

Internal module for processing transaction logic.

* ExBanking.Utils.Validator

Provides utility functions for validating various types of inputs used throughout the application.

# Examples

# Running Tests
To run the tests for ExBanking, use the following command in the terminal:
 
```elixir 
mix test 
```

 