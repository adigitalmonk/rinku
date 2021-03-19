defmodule RinkuTest do
  @moduledoc false

  defmodule Adder do
    @moduledoc false
    def add(input, val2), do: input + val2
    def add2(input, val2, val3), do: input + val2 + val3
  end

  use ExUnit.Case, async: true
  doctest Rinku

  describe "creating a new chain" do
    test "starts with an empty list of links" do
      assert Rinku.new() == %Rinku{links: []}
    end
  end

  describe "adding links" do
    test "accepts a module tuple" do
      chain =
        Rinku.new()
        |> Rinku.link({__MODULE__, :some_func, "val"})

      chain.links
      |> Enum.each(fn %{callback: {some_module, some_func, some_arg}} ->
        assert some_module == __MODULE__
        assert some_func == :some_func
        assert some_arg == "val"
      end)
    end

    test "accepts an anonymous function with arguments" do
      chain =
        Rinku.new()
        |> Rinku.link({fn input -> input end, "val"})

      chain.links
      |> Enum.each(fn %{callback: {func, arg}} ->
        assert is_function(func)
        assert arg == "val"
      end)
    end

    test "accepts an anonymous function" do
      chain =
        Rinku.new()
        |> Rinku.link(fn input -> input end)
        |> Rinku.link(fn input -> input end)
        |> Rinku.link(fn input -> input end)

      chain.links
      |> Enum.each(fn link ->
        assert is_function(link.callback)
      end)
    end
  end

  describe "running a chain" do
    test "returns nil when unprocessed" do
      result =
        Rinku.new()
        |> Rinku.result()

      assert is_nil(result)
    end

    test "steps through each type of argument successfully" do
      result =
        Rinku.new()
        |> Rinku.link({RinkuTest.Adder, :add, 1})
        |> Rinku.link({RinkuTest.Adder, :add2, [1, 2]})
        |> Rinku.link({fn input, val2 -> input + val2 end, 1})
        |> Rinku.link(fn input -> input + 1 end)
        |> Rinku.run(1)
        |> Rinku.result()

      assert result == 7
    end

    test "will end early if an error tuple is returned from a function" do
      result =
        Rinku.new()
        |> Rinku.link(fn _ -> {:error, :test} end)
        |> Rinku.link(fn _ -> raise "This won't happen" end)
        |> Rinku.run()
        |> Rinku.result()

      assert result == {:error, :test}
    end

    test "will end early if an error atom is returned from a function" do
      result =
        Rinku.new()
        |> Rinku.link(fn _ -> :error end)
        |> Rinku.link(fn _ -> raise "This won't happen" end)
        |> Rinku.run()
        |> Rinku.result()

      assert result == :error
    end

    test "will end early if an error atom of any length is returned from a function" do
      [
        {:error, 1},
        {:error, 1, 2},
        {:error, 1, 2, 3},
        {:error, 1, 2, 3, 4},
        {:error, 1, 2, 3, 4, 5},
        {:error, 1, 2, 3, 4, 5, 6},
        {:error, 1, 2, 3, 4, 5, 6, 7}
      ]
      |> Enum.each(fn test_error ->
        result =
          Rinku.new()
          |> Rinku.link(fn _ -> test_error end)
          |> Rinku.link(fn _ -> raise "This won't happen" end)
          |> Rinku.run()
          |> Rinku.result()

        assert result == test_error
      end)
    end
  end

  describe "naming and retrieving results" do
    test "allows you to rename the first step" do
      processed_chain =
        Rinku.new()
        |> Rinku.link(fn input -> input + 1 end, :first)
        |> Rinku.run(1, :test_name)

      assert Rinku.link_result(processed_chain, :test_name) == 1
      assert Rinku.link_result(processed_chain, :first) == 2
      assert Rinku.result(processed_chain) == 2
    end

    test "allows you to retrieve result of an earlier step" do
      processed_chain =
        Rinku.new()
        |> Rinku.link(fn input -> input + 1 end, :first)
        |> Rinku.link(fn input -> input + 1 end, :second)
        |> Rinku.link(fn _ -> {:error, :test} end)
        |> Rinku.link(fn input -> input + 1 end, :third)
        |> Rinku.run(1)

      assert Rinku.link_result(processed_chain, :seed) == 1
      assert Rinku.link_result(processed_chain, :first) == 2
      assert Rinku.link_result(processed_chain, :second) == 3
      assert Rinku.link_result(processed_chain, :third) == nil
      assert Rinku.result(processed_chain) == {:error, :test}

      processed_chain =
        Rinku.new()
        |> Rinku.link(fn _input -> :result1 end, :step1)
        |> Rinku.link(fn _input -> :result2 end, :step2)
        |> Rinku.link(fn _input -> :result3 end, :step3)
        |> Rinku.run(:input_value, :input_name)

      assert processed_chain |> Rinku.link_result(:input_name) == :input_value
      assert processed_chain |> Rinku.link_result(:step1) == :result1
      assert processed_chain |> Rinku.link_result(:step2) == :result2
      assert processed_chain |> Rinku.link_result(:step3) == :result3
    end
  end
end
