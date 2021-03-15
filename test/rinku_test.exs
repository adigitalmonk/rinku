defmodule RinkuTest do
  defmodule Adder do
    def add(input, val2), do: input + val2
    def add2(input, val2, val3), do: input + val2 + val3
  end

  use ExUnit.Case
  doctest Rinku

  describe "creating a new chain" do
    test "starts with the initial input" do
      assert Rinku.new("test") == %Rinku{input: "test", links: []}
    end

    test "doesn't require an initial value" do
      assert Rinku.new() == %Rinku{input: nil, links: []}
    end
  end

  describe "adding links" do
    test "accepts a module tuple" do
      chain =
        Rinku.new()
        |> Rinku.link({__MODULE__, :some_func, "val"})
        |> Rinku.link({__MODULE__, :some_func, "val"})
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
        |> Rinku.link({fn input -> input end, "val"})
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
    test "steps through each type of argument successfully" do
      result =
        1
        |> Rinku.new()
        |> Rinku.link({RinkuTest.Adder, :add, 1})
        |> Rinku.link({RinkuTest.Adder, :add2, [1, 2]})
        |> Rinku.link({fn input, val2 -> input + val2 end, 1})
        |> Rinku.link(fn input -> input + 1 end)
        |> Rinku.run()

      assert result == 7
    end

    test "will end early if an error tuple is returned from a function" do
      result =
        Rinku.new()
        |> Rinku.link(fn _ -> {:error, :test} end)
        |> Rinku.link(fn _ -> raise "This won't happen" end)
        |> Rinku.run()

      assert result == {:error, :test}
    end
  end
end
