searchNodes=[{"doc":"A pattern for composing functions to execute in a chain. Execution will stop when all links in the chain have been resolved, or any link in the chain returns an error.The initial input will be provided as the first argument in the chain. The result of each link in the chain will be supplied to the next link in the chain.The input will always be the first argument provided to the next link in the chain.","ref":"Rinku.html","title":"Rinku","type":"module"},{"doc":"Add a new link to the Rinku chain.","ref":"Rinku.html#link/3","title":"Rinku.link/3","type":"function"},{"doc":"Get the result for a specific named execution step.iex&gt; Rinku.new() |&gt; Rinku.link(fn _ -&gt; 1 end, :step1) |&gt; Rinku.link(fn _ -&gt; 2 end, :step2) |&gt; Rinku.run() |&gt; Rinku.link_result(:step1) 1","ref":"Rinku.html#link_result/2","title":"Rinku.link_result/2","type":"function"},{"doc":"Create a new Rinku chain.iex&gt; Rinku.new() %Rinku{ links: [], resolved: [ %Rinku.Resolved{ name: :seed, result: nil } ], result: nil }","ref":"Rinku.html#new/2","title":"Rinku.new/2","type":"function"},{"doc":"Get the result from a processed chain.iex&gt; Rinku.new() |&gt; Rinku.link(fn _ -&gt; 1 end) |&gt; Rinku.run() |&gt; Rinku.result() 1","ref":"Rinku.html#result/1","title":"Rinku.result/1","type":"function"},{"doc":"Execute a built rinku chain.","ref":"Rinku.html#run/1","title":"Rinku.run/1","type":"function"},{"doc":"","ref":"Rinku.html#t:link_callback/0","title":"Rinku.link_callback/0","type":"type"},{"doc":"","ref":"Rinku.html#t:t/0","title":"Rinku.t/0","type":"type"},{"doc":"Structure of a link in a Rinku chain.","ref":"Rinku.Link.html","title":"Rinku.Link","type":"module"},{"doc":"","ref":"Rinku.Link.html#new/2","title":"Rinku.Link.new/2","type":"function"},{"doc":"","ref":"Rinku.Link.html#t:t/0","title":"Rinku.Link.t/0","type":"type"},{"doc":"Structure of a resolved link","ref":"Rinku.Resolved.html","title":"Rinku.Resolved","type":"module"},{"doc":"","ref":"Rinku.Resolved.html#t:t/0","title":"Rinku.Resolved.t/0","type":"type"},{"doc":"RinkuRinku is a simple abstraction to enable linking a series of steps.To begin a new Rinku.new/2 chain is created with some initial value (nil by default). Then, multiple links / function calls are added together using Rinku.link/2. Once we've built the chain, the Rinku.run/1 function resolve the links in the order they were added. The first argument to a link is always the result of the previous link's execution.At the end of a function's execution, the result is passed the first argument for the next. The chain will end immediately if any function returns a tuple with :error as the first element. Once the chain exhausts all of it's links, the Rinku.result/1 function will extract the final result.3 = 1 |&gt; Rinku.new() |&gt; Rinku.link(fn input -&gt; input + 1 end) |&gt; Rinku.link(fn input -&gt; input + 1 end) |&gt; Rinku.run() |&gt; Rinku.result()You can provide extra arguments to individual steps (from a number of ways) instead of just feeding data through the chain.previous_result = 1 |&gt; Rinku.new() |&gt; Rinku.link({fn input, four -&gt; input + four end, 4}) |&gt; Rinku.run() |&gt; Rinku.result() assert previous_result == 5 new_result = 5 |&gt; Rinku.new() |&gt; Rinku.link(fn input -&gt; input + previous_result end) |&gt; Rinku.run() |&gt; Rinku.result() assert new_result == 10Additional arguments are provided to module calls using the common tuple format, {SomeModule, :function, [:one, :two]}. The input from the previous step will always be injected as the first argument, other arguments will be added subsequently.defmodule SomeMod do def combine(init, a, b), do: init + a + b end 5 = 1 |&gt; Rinku.new() |&gt; Rinku.link({SomeMod, :combine, [2, 2]}) |&gt; Rinku.run() |&gt; Rinku.result()If a function returns an :error along the way, it'll halt execution. Errors can be either just the atom :error, or an error tuple of any length. E.g., {:error, :thing}, {:error, :thing, :other}, {:error, :thing, :other, :more}.{:error, :oh_no} = Rinku.new() |&gt; Rinku.link(fn _ -&gt; {:error, :oh_no} end) |&gt; Rinku.link(fn _input -&gt; 10 end) |&gt; Rinku.run() |&gt; Rinku.result()If for some reason you need to recover an earlier result, you can name your steps and recover the results that way. You can name the input as well, if you have a need or desire to do that. Naming is optional, but you'll need a unique name to get the correct result for a step.processed_chain = Rinku.new(:input_value, :input_name) |&gt; Rinku.link(fn _input -&gt; :result1 end, :step1) |&gt; Rinku.link(fn _input -&gt; :result2 end, :step2) |&gt; Rinku.link(fn _input -&gt; :result3 end, :step3) |&gt; Rinku.run() assert processed_chain |&gt; Rinku.link_result(:input_name) == :input_value assert processed_chain |&gt; Rinku.link_result(:step1) == :result1 assert processed_chain |&gt; Rinku.link_result(:step2) == :result2 assert processed_chain |&gt; Rinku.link_result(:step3) == :result3 assert processed_chain |&gt; Rinku.result() == :result3A completed chain can also be appended and re-run if necessary. All steps are re-run, not just the newly added ones.chain = 1 |&gt; Rinku.new() |&gt; Rinku.link(fn input -&gt; input + 1 end) value = chain |&gt; Rinku.run() |&gt; Rinku.result() assert value == 2 other_value = chain |&gt; Rinku.link(fn input -&gt; input + 1 end) |&gt; Rinku.run() |&gt; Rinku.result() assert other_value == 3See Practical Examples for a few realistic use cases.","ref":"readme.html","title":"Rinku","type":"extras"},{"doc":"For the Elixir/Erlang versions, please refer to the supplied .tool-versions (compatible with asdf).","ref":"readme.html#developing","title":"Rinku - Developing","type":"extras"},{"doc":"A scenario where we want to accept an arbitrary map, convert it into an Ecto schema, then save it to a database. In the SomeContext module, there are three functions showcasing the same logic. One function uses a with chain, the other two use a Rinku chain.defmodule SomeSchema do @callback changeset(params :: map()) :: Ecto.Changeset.t() @callback coerce(changeset :: Ecto.Changeset.t()) :: t() | {:error, Ecto.Changeset.t()} @callback save(t(), access_token) :: {:ok, t()} | {:error, :forbidden} end defmodule SomeContext do def create_via_with(record_params, access_token) do with {:ok, changeset} &lt;- SomeSchema.changeset(record_params), {:ok, struct} &lt;- SomeSchema.coerce(changeset), {:ok, result} = result &lt;- SomeSchema.save(struct, access_token) do result else {:error, %Ecto.Changeset{} = error_changeset} -&gt; {:error, :invalid_params, error_changeset} {:error, :forbidden} -&gt; {:error, :not_allowed_to_save} end end def create_via_rinku(record_params, access_token) do record_params |&gt; Rinku.new() |&gt; Rinku.link({SomeSchema, :changeset, []}) |&gt; Rinku.link({SomeSchema, :coerce, []}) |&gt; Rinku.link({SomeSchema, :save, access_token}) |&gt; Rinku.run() |&gt; Rinku.result() |&gt; case do {:error, %Ecto.Changeset{} = error_changeset} -&gt; {:error, :invalid_params, error_changeset} {:error, :forbbiden} -&gt; {:error, :not_allowed_to_save} {:ok, _result} = result -&gt; result end end def create_via_rinku_alt(record_params, access_token) do record_params |&gt; Rinku.new() |&gt; Rinku.link(fn params -&gt; SomeSchema.changeset(params) end) |&gt; Rinku.link(fn changeset -&gt; case SomeSchema.coerce(changeset) do {:error, changeset} -&gt; {:error, :invalid_params, changeset} instance -&gt; {:ok, instance} end end) |&gt; Rinku.link(fn {:ok, instance} -&gt; case SomeSchema.save(instance) do {:ok, _result} = result -&gt; result {:error, :forbidden} -&gt; {:error, :not_allowed_to_save} end end) |&gt; Rinku.run() |&gt; Rinku.result() end end","ref":"readme.html#practical-examples","title":"Rinku - Practical Examples","type":"extras"},{"doc":"Rinku is not in Hex. You can install it directly via Git. def deps do [ {:rink, github: &quot;adigitalmonk/rinku&quot;, branch: &quot;master&quot;} ] end","ref":"readme.html#installation","title":"Rinku - Installation","type":"extras"}]