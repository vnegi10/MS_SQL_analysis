### A Pluto.jl notebook ###
# v0.19.26

using Markdown
using InteractiveUtils

# ╔═╡ 0d112a9e-15f0-4b9d-a323-445b7eaf0ef6
using ODBC, DBInterface, DataFrames, JSON, CoinbaseProExchange

# ╔═╡ 5c617b7e-12d5-11ee-2c35-1fed12f104a4
md"
## Load packages
"

# ╔═╡ 8e73b088-9469-4029-9d79-571c964966b9
md"
## Check drivers
"

# ╔═╡ ed1d306b-9488-4fb0-9335-48809d32fbbf
ODBC.drivers()

# ╔═╡ 395feaf0-923f-4dba-a43b-c0a130098051
md"
## Add drivers
"

# ╔═╡ 55b5df7d-059f-40fe-8698-9bf8a0e38177
#ODBC.adddriver("ODBC Driver 18 for SQL Server", "/opt/microsoft/msodbcsql18/lib64/libmsodbcsql-18.2.so.2.1")

# ╔═╡ 770a02bc-f496-493c-ac1f-52d98e1bea86
#ODBC.removedriver("msodbcsql18")

# ╔═╡ b8a615a9-ee9f-4df7-8856-0f94e9254096
md"
## Add connection
"

# ╔═╡ f831873d-728d-48ad-8f1a-f9ed5fcdb763
key = JSON.parsefile("/home/vikas/Documents/MS_SQL_key.json");

# ╔═╡ acad636a-6515-4942-89fb-9d6b0b2be513
pass = key["password"];

# ╔═╡ 413e5c2d-f697-49f7-a1ea-e481c11905eb
conn = ODBC.Connection("Driver={ODBC Driver 17 for SQL Server};
	                        SERVER=192.168.2.8,1433;
	                        DATABASE=TestDB;
	                        UID=SA;
	                        PWD=$(pass)")

# ╔═╡ c3d7f254-efae-45b3-9eae-ae89d9e64fc6
conn_master = ODBC.Connection("Driver={ODBC Driver 17 for SQL Server};
	                           SERVER=192.168.2.8,1433;
	                           DATABASE=master;
	                           UID=SA;
	                           PWD=$(pass)")

# ╔═╡ 0c328dbd-df17-453c-961a-c5ec446d34c6
md"
## Test connection
"

# ╔═╡ cc188870-a483-4179-aed4-29bf71518ddf
df_inventory = DBInterface.execute(conn, "SELECT * FROM Inventory") |> DataFrame

# ╔═╡ 21334d46-f828-48ec-84b0-a81133fb55a8
df_origin = DBInterface.execute(conn, "SELECT * FROM Origin") |> DataFrame

# ╔═╡ ec4fb85d-8fb1-47df-b811-966ceeba0b25
#stmt = DBInterface.prepare(conn, "INSERT INTO Origin VALUES(?, ?, ?)")

# ╔═╡ 102dbb27-ee69-42ca-8549-714463d10597
#DBInterface.executemany(stmt, ([5, 6], ["watermelon", "lichi"], ["India", "China"]))

# ╔═╡ 7f58ae46-2531-41ba-a43b-456b93bb6c9e
md"
## Interacting with SQL Server
"

# ╔═╡ 5c09ff51-6046-4e1d-913f-c27364ced969
md"
#### List all existing databases
"

# ╔═╡ b2616e09-4396-491f-a37f-a6af4a79d4eb
list_db(conn) = DBInterface.execute(conn, 
	                        "SELECT name FROM master.dbo.sysdatabases") |> DataFrame

# ╔═╡ 1c8c6d32-e960-40d4-ba5b-447e1c6fa998
list_db(conn_master)

# ╔═╡ b5cb39cb-ec94-4349-8bc2-ff388fc623e5
md"
#### Create a new database
"

# ╔═╡ 4a790301-0db2-4370-85f1-d6eff91047b9
"""
    create_db(conn, db_name::String)
"""
function create_db(conn, db_name::String)

	df_db = list_db(conn)

	if db_name ∉ df_db.name
		try
			DBInterface.execute(conn, "CREATE DATABASE $(db_name)")
			@info "Created a new database $(db_name)"
		catch e
			error("Unable to create a new database $(db_name)")
		end		
	else
		@info "$(db_name) already exists!"
	end	

	return nothing

end

# ╔═╡ 543e7024-4a8e-49d3-a568-b820c1aa98e4
create_db(conn_master, "TradesDB")

# ╔═╡ 34800bee-346b-49df-81fa-e30e763ce537
md"
#### Connect to a new database
"

# ╔═╡ 4587b7e0-7509-4534-9a05-b69dee4fd2d9
function connect_db(db_name::String)
	conn_db = ODBC.Connection("Driver={ODBC Driver 17 for SQL Server};
	                           SERVER=192.168.2.8,1433;
	                           DATABASE=$(db_name);
	                           UID=SA;
	                           PWD=$(pass)")

	return conn_db
end

# ╔═╡ 8e81d52e-d4c8-439a-8f82-b79d9a08e54b
md"
#### Create a new table
"

# ╔═╡ 078ae9f1-f29c-4171-8ec7-daacab7ef5f8
function create_trade_table(conn_master, db_name::String, table_name::String)

	create_db(conn_master, db_name)

	conn = connect_db(db_name)

	df_tables = DBInterface.execute(conn, 
		                    "SELECT * FROM information_schema.tables") |> DataFrame

	if table_name ∉ df_tables[!, :TABLE_NAME]
		try
			DBInterface.execute(conn, 
		                        "CREATE TABLE $table_name (
								 Time CHAR(27),
                                 Price FLOAT,
                                 Side VARCHAR(4),
                                 Size FLOAT,
                                 TradeId INT
                                 );")
			
		catch e
			error("Unable to create table $table_name")
		end

	else
		@info("Table $table_name already exists!")
	end	

	return conn

end

# ╔═╡ 32e1a386-604a-467c-bec2-5f6bc8a26913
#create_trade_table(conn_master, "TradesDB", "ETH_EUR")

# ╔═╡ fa73f368-c318-4fb5-8a04-5ff4eab2e324
md"
#### Add to a new table
"

# ╔═╡ 3bbcf312-c153-4d40-a99b-b997244402ab
"""
    add_to_trade_table(conn_master, db_name::String, table_name::String)

Add latest trades to a table with name `table_name` within database `db_name`. 

# Arguments
- `conn_master` : Connection to master database on the SQL server. This is always
                  assumed to be present.
- `db_name` : Name of the database. A new one is created if it doesn't already exist.
- `table_name` : Name of the table. In this case, a valid currency pair is needed, 
                 e.g. "ETH-EUR", "BTC-EUR" etc.
"""
function add_to_trade_table(conn_master, db_name::String, table_name::String)

	conn = create_trade_table(conn_master, db_name, table_name)

	trade_pair = split(table_name, "_")
	trade_pair = join(trade_pair, "-")

	df_trades = show_latest_trades(trade_pair)

	stmt = try
		 DBInterface.prepare(conn, 
		                     "INSERT INTO $(table_name) VALUES(?, ?, ?, ?, ?)")
	catch 
		error("Unable to prepare statement")
	end

	try
		DBInterface.executemany(stmt, 
		                       (df_trades[!, 1], 
							    df_trades[!, 2],
						        df_trades[!, 3],
						        df_trades[!, 4],
						        df_trades[!, 5])
	                            )
	catch
		error("Unable to execute multiple statements")
	finally
		DBInterface.close!(stmt)
		DBInterface.close!(conn)		
	end

	return nothing	

end

# ╔═╡ aa07c21f-bcf6-4231-8947-819d9d8e2601
add_to_trade_table(conn_master, "TradesDB", "ETH_EUR")

# ╔═╡ 91a8c494-ec4f-4b6e-a08f-0f1c1ae04a8b
md"
#### Clean up table
"

# ╔═╡ ff9a32d4-32bc-49e2-8124-acdef1ba7d20
"""
    remove_duplicate_rows(db_name::String, table_name::String)

Clean up table by removing duplicate rows.
"""
function remove_duplicate_rows(db_name::String, table_name::String)

	conn_db = connect_db(db_name)

	# Remove duplicate rows using a common table expression (cte)
	try
		DBInterface.execute(conn_db, 
		            "WITH cte AS (
					SELECT 
                          Time, 
                          Price, 
                          Side,
					      Size,
					      TradeId,
        ROW_NUMBER() OVER (
            PARTITION BY 
                TradeId
            ORDER BY 
                TradeId
					) row_num FROM $table_name ) 
					DELETE FROM cte WHERE row_num > 1" )
		
	catch
		error("Unable to delete rows!")
	finally
		DBInterface.close!(conn_db)	
	end

	return nothing	

end

# ╔═╡ e7223e58-671e-46ec-a598-c290c1e85e65
md"
#### Delete table
"

# ╔═╡ 8306edda-1a92-4890-8e54-1bb92bec595f
"""
    delete_table(db_name::String, table_name::String)

Removes `table_name` from `db_name`.
"""
function delete_table(db_name::String, table_name::String)

	conn_db = connect_db(db_name)

	try
		DBInterface.execute(conn_db, 
			                "DROP TABLE $table_name")
	catch
		error("Unable to delete table $table_name")
	finally
		DBInterface.close!(conn_db)			
	end

	return nothing

end

# ╔═╡ 5c278f63-b614-43c6-ae13-3d8bea8044fa
md"
## Update and clean table
"

# ╔═╡ f8cc7064-7a14-4a90-a573-5570f008e08a
function update_and_clean(db_name::String, table_name::String, cycles::Int64)

	for i = 1:cycles
		add_to_trade_table(conn_master, db_name, table_name)
		remove_duplicate_rows(db_name, table_name)
		sleep(300)
	end

end

# ╔═╡ 33ab6e5d-b8f2-4320-8684-d58f69a46506
md"
## Verify contents
"

# ╔═╡ a1e8772c-abb2-490c-92f8-37bc553060d6
conn_db = connect_db("TradesDB")

# ╔═╡ b2032635-c85b-452d-b283-26ad64b847c8
begin
	df_trade = DBInterface.execute(conn_db, 
			            "SELECT * FROM ETH_EUR") |> DataFrame
	sort(df_trade, :TradeId, rev = true)
end

# ╔═╡ 37cabedf-c062-40fc-bbd9-9a4ed4f460b3
md"
## Close connection
"

# ╔═╡ 42758b31-5a78-433d-8dd8-47bcd6986578
#DBInterface.close!(conn_1)

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
CoinbaseProExchange = "06c3450d-869c-4596-88b4-6f9fb82f72bd"
DBInterface = "a10d1c49-ce27-4219-8d33-6db1a4562965"
DataFrames = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
JSON = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
ODBC = "be6f12e9-ca4f-5eb2-a339-a4f995cc0291"

[compat]
CoinbaseProExchange = "~1.0.0"
DBInterface = "~2.5.0"
DataFrames = "~1.5.0"
JSON = "~0.21.4"
ODBC = "~1.1.2"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.9.1"
manifest_format = "2.0"
project_hash = "335a853748fdf3e1aa4dcd84e6fdc6822cbf7784"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"
version = "1.1.1"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[deps.CSV]]
deps = ["CodecZlib", "Dates", "FilePathsBase", "InlineStrings", "Mmap", "Parsers", "PooledArrays", "SentinelArrays", "Tables", "Unicode", "WeakRefStrings"]
git-tree-sha1 = "49f14b6c56a2da47608fe30aed711b5882264d7a"
uuid = "336ed68f-0bac-5ca0-87d4-7b16caf5d00b"
version = "0.9.11"

[[deps.CodecZlib]]
deps = ["TranscodingStreams", "Zlib_jll"]
git-tree-sha1 = "9c209fb7536406834aa938fb149964b985de6c83"
uuid = "944b1d66-785c-5afd-91f1-9de20f533193"
version = "0.7.1"

[[deps.CoinbaseProExchange]]
deps = ["Base64", "CSV", "DataFrames", "Dates", "HTTP", "JSON", "Nettle", "Query", "Statistics"]
git-tree-sha1 = "decf014e988006a8568476b243c293c9b9311b57"
uuid = "06c3450d-869c-4596-88b4-6f9fb82f72bd"
version = "1.0.0"

[[deps.Compat]]
deps = ["UUIDs"]
git-tree-sha1 = "4e88377ae7ebeaf29a047aa1ee40826e0b708a5d"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "4.7.0"
weakdeps = ["Dates", "LinearAlgebra"]

    [deps.Compat.extensions]
    CompatLinearAlgebraExt = "LinearAlgebra"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "1.0.2+0"

[[deps.Crayons]]
git-tree-sha1 = "249fe38abf76d48563e2f4556bebd215aa317e15"
uuid = "a8cc5b0e-0ffa-5ad4-8c14-923d3ee1735f"
version = "4.1.1"

[[deps.DBInterface]]
git-tree-sha1 = "9b0dc525a052b9269ccc5f7f04d5b3639c65bca5"
uuid = "a10d1c49-ce27-4219-8d33-6db1a4562965"
version = "2.5.0"

[[deps.DataAPI]]
git-tree-sha1 = "8da84edb865b0b5b0100c0666a9bc9a0b71c553c"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.15.0"

[[deps.DataFrames]]
deps = ["Compat", "DataAPI", "Future", "InlineStrings", "InvertedIndices", "IteratorInterfaceExtensions", "LinearAlgebra", "Markdown", "Missings", "PooledArrays", "PrettyTables", "Printf", "REPL", "Random", "Reexport", "SentinelArrays", "SnoopPrecompile", "SortingAlgorithms", "Statistics", "TableTraits", "Tables", "Unicode"]
git-tree-sha1 = "aa51303df86f8626a962fccb878430cdb0a97eee"
uuid = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
version = "1.5.0"

[[deps.DataStructures]]
deps = ["Compat", "InteractiveUtils", "OrderedCollections"]
git-tree-sha1 = "d1fff3a548102f48987a52a2e0d114fa97d730f0"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.18.13"

[[deps.DataValueInterfaces]]
git-tree-sha1 = "bfc1187b79289637fa0ef6d4436ebdfe6905cbd6"
uuid = "e2d170a0-9d28-54be-80f0-106bbe20a464"
version = "1.0.0"

[[deps.DataValues]]
deps = ["DataValueInterfaces", "Dates"]
git-tree-sha1 = "d88a19299eba280a6d062e135a43f00323ae70bf"
uuid = "e7dc6d0d-1eca-5fa6-8ad6-5aecde8b7ea5"
version = "0.4.13"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[deps.DecFP]]
deps = ["DecFP_jll", "Printf", "Random", "SpecialFunctions"]
git-tree-sha1 = "a8269e0a6af8c9d9ae95d15dcfa5628285980cbb"
uuid = "55939f99-70c6-5e9b-8bb0-5071ed7d61fd"
version = "1.3.1"

[[deps.DecFP_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "e9a8da19f847bbfed4076071f6fef8665a30d9e5"
uuid = "47200ebd-12ce-5be5-abb7-8e082af23329"
version = "2.0.3+1"

[[deps.DocStringExtensions]]
deps = ["LibGit2"]
git-tree-sha1 = "2fb1e02f2b635d0845df5d7c167fec4dd739b00d"
uuid = "ffbed154-4ef7-542d-bbb7-c09d3a79fcae"
version = "0.9.3"

[[deps.Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"
version = "1.6.0"

[[deps.FilePathsBase]]
deps = ["Compat", "Dates", "Mmap", "Printf", "Test", "UUIDs"]
git-tree-sha1 = "e27c4ebe80e8699540f2d6c805cc12203b614f12"
uuid = "48062228-2e41-5def-b9a4-89aafe57970f"
version = "0.9.20"

[[deps.FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"

[[deps.Formatting]]
deps = ["Printf"]
git-tree-sha1 = "8339d61043228fdd3eb658d86c926cb282ae72a8"
uuid = "59287772-0a20-5a39-b81b-1366585eb4c0"
version = "0.4.2"

[[deps.Future]]
deps = ["Random"]
uuid = "9fa8497b-333b-5362-9e8d-4d0656e87820"

[[deps.GMP_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "781609d7-10c4-51f6-84f2-b8444358ff6d"
version = "6.2.1+2"

[[deps.HTTP]]
deps = ["Base64", "Dates", "IniFile", "Logging", "MbedTLS", "NetworkOptions", "Sockets", "URIs"]
git-tree-sha1 = "0fa77022fe4b511826b39c894c90daf5fce3334a"
uuid = "cd3eb016-35fb-5094-929b-558a96fad6f3"
version = "0.9.17"

[[deps.IniFile]]
git-tree-sha1 = "f550e6e32074c939295eb5ea6de31849ac2c9625"
uuid = "83e8ac13-25f8-5344-8a64-a9f2b223428f"
version = "0.5.1"

[[deps.InlineStrings]]
deps = ["Parsers"]
git-tree-sha1 = "9cc2baf75c6d09f9da536ddf58eb2f29dedaf461"
uuid = "842dd82b-1e85-43dc-bf29-5d0ee9dffc48"
version = "1.4.0"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[deps.InvertedIndices]]
git-tree-sha1 = "0dc7b50b8d436461be01300fd8cd45aa0274b038"
uuid = "41ab1584-1d38-5bbf-9106-f11c6c58b48f"
version = "1.3.0"

[[deps.IrrationalConstants]]
git-tree-sha1 = "630b497eafcc20001bba38a4651b327dcfc491d2"
uuid = "92d709cd-6900-40b7-9082-c6be49f344b6"
version = "0.2.2"

[[deps.IterableTables]]
deps = ["DataValues", "IteratorInterfaceExtensions", "Requires", "TableTraits", "TableTraitsUtils"]
git-tree-sha1 = "70300b876b2cebde43ebc0df42bc8c94a144e1b4"
uuid = "1c8ee90f-4401-5389-894e-7a04a3dc0f4d"
version = "1.0.0"

[[deps.IteratorInterfaceExtensions]]
git-tree-sha1 = "a3f24677c21f5bbe9d2a714f95dcd58337fb2856"
uuid = "82899510-4779-5014-852e-03e436cf321d"
version = "1.0.0"

[[deps.JLLWrappers]]
deps = ["Preferences"]
git-tree-sha1 = "abc9885a7ca2052a736a600f7fa66209f96506e1"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.4.1"

[[deps.JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "31e996f0a15c7b280ba9f76636b3ff9e2ae58c9a"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.4"

[[deps.LaTeXStrings]]
git-tree-sha1 = "f2355693d6778a178ade15952b7ac47a4ff97996"
uuid = "b964fa9f-0449-5b57-a5c2-d3ea65f4040f"
version = "1.3.0"

[[deps.LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"
version = "0.6.3"

[[deps.LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"
version = "7.84.0+0"

[[deps.LibGit2]]
deps = ["Base64", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"
version = "1.10.2+0"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"

[[deps.Libiconv_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "c7cb1f5d892775ba13767a87c7ada0b980ea0a71"
uuid = "94ce4f54-9a6c-5748-9c1c-f9c7231a4531"
version = "1.16.1+2"

[[deps.LinearAlgebra]]
deps = ["Libdl", "OpenBLAS_jll", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[deps.LogExpFunctions]]
deps = ["DocStringExtensions", "IrrationalConstants", "LinearAlgebra"]
git-tree-sha1 = "c3ce8e7420b3a6e071e0fe4745f5d4300e37b13f"
uuid = "2ab3a3ac-af41-5b50-aa03-7779005ae688"
version = "0.3.24"

    [deps.LogExpFunctions.extensions]
    LogExpFunctionsChainRulesCoreExt = "ChainRulesCore"
    LogExpFunctionsChangesOfVariablesExt = "ChangesOfVariables"
    LogExpFunctionsInverseFunctionsExt = "InverseFunctions"

    [deps.LogExpFunctions.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    ChangesOfVariables = "9e997f8a-9a97-42d5-a9f1-ce6bfc15e2c0"
    InverseFunctions = "3587e190-3f89-42d0-90ee-14403ec27112"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[deps.MacroTools]]
deps = ["Markdown", "Random"]
git-tree-sha1 = "42324d08725e200c23d4dfb549e0d5d89dede2d2"
uuid = "1914dd2f-81c6-5fcd-8719-6d5c9610ff09"
version = "0.5.10"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[deps.MbedTLS]]
deps = ["Dates", "MbedTLS_jll", "MozillaCACerts_jll", "Random", "Sockets"]
git-tree-sha1 = "03a9b9718f5682ecb107ac9f7308991db4ce395b"
uuid = "739be429-bea8-5141-9913-cc70e7f3736d"
version = "1.1.7"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"
version = "2.28.2+0"

[[deps.Missings]]
deps = ["DataAPI"]
git-tree-sha1 = "f66bdc5de519e8f8ae43bdc598782d35a25b1272"
uuid = "e1d29d7a-bbdc-5cf2-9ac0-f12de2c33e28"
version = "1.1.0"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"
version = "2022.10.11"

[[deps.Nettle]]
deps = ["Libdl", "Nettle_jll"]
git-tree-sha1 = "f96a7485d2404f90c7c5c417e64d231f8edc5f08"
uuid = "49dea1ee-f6fa-5aa6-9a11-8816cee7d4b9"
version = "0.5.2"

[[deps.Nettle_jll]]
deps = ["Artifacts", "GMP_jll", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "eca63e3847dad608cfa6a3329b95ef674c7160b4"
uuid = "4c82536e-c426-54e4-b420-14f461c4ed8b"
version = "3.7.2+0"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.2.0"

[[deps.ODBC]]
deps = ["DBInterface", "Dates", "DecFP", "Libdl", "Printf", "Random", "Scratch", "Tables", "UUIDs", "Unicode", "iODBC_jll", "unixODBC_jll"]
git-tree-sha1 = "7fe19bed38551e3169edaec8bb8673354d355681"
uuid = "be6f12e9-ca4f-5eb2-a339-a4f995cc0291"
version = "1.1.2"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.21+4"

[[deps.OpenLibm_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "05823500-19ac-5b8b-9628-191a04bc5112"
version = "0.8.1+0"

[[deps.OpenSpecFun_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "13652491f6856acfd2db29360e1bbcd4565d04f1"
uuid = "efe28fd5-8261-553b-a9e1-b2916fc3738e"
version = "0.5.5+0"

[[deps.OrderedCollections]]
git-tree-sha1 = "d321bf2de576bf25ec4d3e4360faca399afca282"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.6.0"

[[deps.Parsers]]
deps = ["Dates", "PrecompileTools", "UUIDs"]
git-tree-sha1 = "4b2e829ee66d4218e0cef22c0a64ee37cf258c29"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.7.1"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "FileWatching", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
version = "1.9.0"

[[deps.PooledArrays]]
deps = ["DataAPI", "Future"]
git-tree-sha1 = "a6062fe4063cdafe78f4a0a81cfffb89721b30e7"
uuid = "2dfb63ee-cc39-5dd5-95bd-886bf059d720"
version = "1.4.2"

[[deps.PrecompileTools]]
deps = ["Preferences"]
git-tree-sha1 = "9673d39decc5feece56ef3940e5dafba15ba0f81"
uuid = "aea7be01-6a6a-4083-8856-8a6e6704d82a"
version = "1.1.2"

[[deps.Preferences]]
deps = ["TOML"]
git-tree-sha1 = "7eb1686b4f04b82f96ed7a4ea5890a4f0c7a09f1"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.4.0"

[[deps.PrettyTables]]
deps = ["Crayons", "Formatting", "LaTeXStrings", "Markdown", "Reexport", "StringManipulation", "Tables"]
git-tree-sha1 = "213579618ec1f42dea7dd637a42785a608b1ea9c"
uuid = "08abe8d2-0d0c-5749-adfa-8a2ac140af0d"
version = "2.2.4"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[deps.Query]]
deps = ["DataValues", "IterableTables", "MacroTools", "QueryOperators", "Statistics"]
git-tree-sha1 = "a66aa7ca6f5c29f0e303ccef5c8bd55067df9bbe"
uuid = "1a8c2f83-1ff3-5112-b086-8aa67b057ba1"
version = "1.0.0"

[[deps.QueryOperators]]
deps = ["DataStructures", "DataValues", "IteratorInterfaceExtensions", "TableShowUtils"]
git-tree-sha1 = "911c64c204e7ecabfd1872eb93c49b4e7c701f02"
uuid = "2aef5ad7-51ca-5a8f-8e88-e75cf067b44b"
version = "0.9.3"

[[deps.REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[deps.Random]]
deps = ["SHA", "Serialization"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[deps.Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[deps.Requires]]
deps = ["UUIDs"]
git-tree-sha1 = "838a3a4188e2ded87a4f9f184b4b0d78a1e91cb7"
uuid = "ae029012-a4dd-5104-9daa-d747884805df"
version = "1.3.0"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.Scratch]]
deps = ["Dates"]
git-tree-sha1 = "30449ee12237627992a99d5e30ae63e4d78cd24a"
uuid = "6c6a2e73-6563-6170-7368-637461726353"
version = "1.2.0"

[[deps.SentinelArrays]]
deps = ["Dates", "Random"]
git-tree-sha1 = "04bdff0b09c65ff3e06a05e3eb7b120223da3d39"
uuid = "91c51154-3ec4-41a3-a24f-3f23e20d615c"
version = "1.4.0"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[deps.SnoopPrecompile]]
deps = ["Preferences"]
git-tree-sha1 = "e760a70afdcd461cf01a575947738d359234665c"
uuid = "66db9d55-30c0-4569-8b51-7e840670fc0c"
version = "1.0.3"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"

[[deps.SortingAlgorithms]]
deps = ["DataStructures"]
git-tree-sha1 = "c60ec5c62180f27efea3ba2908480f8055e17cee"
uuid = "a2af1166-a08f-5f64-846c-94a0d3cef48c"
version = "1.1.1"

[[deps.SparseArrays]]
deps = ["Libdl", "LinearAlgebra", "Random", "Serialization", "SuiteSparse_jll"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[deps.SpecialFunctions]]
deps = ["IrrationalConstants", "LogExpFunctions", "OpenLibm_jll", "OpenSpecFun_jll"]
git-tree-sha1 = "7beb031cf8145577fbccacd94b8a8f4ce78428d3"
uuid = "276daf66-3868-5448-9aa4-cd146d93841b"
version = "2.3.0"

    [deps.SpecialFunctions.extensions]
    SpecialFunctionsChainRulesCoreExt = "ChainRulesCore"

    [deps.SpecialFunctions.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"

[[deps.Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"
version = "1.9.0"

[[deps.StringManipulation]]
git-tree-sha1 = "46da2434b41f41ac3594ee9816ce5541c6096123"
uuid = "892a3eda-7b42-436c-8928-eab12a02cf0e"
version = "0.3.0"

[[deps.SuiteSparse_jll]]
deps = ["Artifacts", "Libdl", "Pkg", "libblastrampoline_jll"]
uuid = "bea87d4a-7f5b-5778-9afe-8cc45184846c"
version = "5.10.1+6"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
version = "1.0.3"

[[deps.TableShowUtils]]
deps = ["DataValues", "Dates", "JSON", "Markdown", "Test"]
git-tree-sha1 = "14c54e1e96431fb87f0d2f5983f090f1b9d06457"
uuid = "5e66a065-1f0a-5976-b372-e0b8c017ca10"
version = "0.2.5"

[[deps.TableTraits]]
deps = ["IteratorInterfaceExtensions"]
git-tree-sha1 = "c06b2f539df1c6efa794486abfb6ed2022561a39"
uuid = "3783bdb8-4a98-5b6b-af9a-565f29a5fe9c"
version = "1.0.1"

[[deps.TableTraitsUtils]]
deps = ["DataValues", "IteratorInterfaceExtensions", "Missings", "TableTraits"]
git-tree-sha1 = "78fecfe140d7abb480b53a44f3f85b6aa373c293"
uuid = "382cd787-c1b6-5bf2-a167-d5b971a19bda"
version = "1.0.2"

[[deps.Tables]]
deps = ["DataAPI", "DataValueInterfaces", "IteratorInterfaceExtensions", "LinearAlgebra", "OrderedCollections", "TableTraits", "Test"]
git-tree-sha1 = "1544b926975372da01227b382066ab70e574a3ec"
uuid = "bd369af6-aec1-5ad0-b16a-f7cc5008161c"
version = "1.10.1"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"
version = "1.10.0"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[deps.TranscodingStreams]]
deps = ["Random", "Test"]
git-tree-sha1 = "9a6ae7ed916312b41236fcef7e0af564ef934769"
uuid = "3bb67fe8-82b1-5028-8e26-92a6c54297fa"
version = "0.9.13"

[[deps.URIs]]
git-tree-sha1 = "074f993b0ca030848b897beff716d93aca60f06a"
uuid = "5c2747f8-b7ea-4ff2-ba2e-563bfd36b1d4"
version = "1.4.2"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[[deps.WeakRefStrings]]
deps = ["DataAPI", "InlineStrings", "Parsers"]
git-tree-sha1 = "b1be2855ed9ed8eac54e5caff2afcdb442d52c23"
uuid = "ea10d353-3f73-51f8-a26c-33c1cb351aa5"
version = "1.4.2"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"
version = "1.2.13+0"

[[deps.iODBC_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "785395fb370d696d98da91eddedbdde18d43b0e3"
uuid = "80337aba-e645-5151-a517-44b13a626b79"
version = "3.52.15+0"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.8.0+0"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"
version = "1.48.0+0"

[[deps.p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
version = "17.4.0+0"

[[deps.unixODBC_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libiconv_jll", "Pkg"]
git-tree-sha1 = "228f4299344710cf865b3659c51242ecd238c004"
uuid = "1841a5aa-d9e2-579c-8226-32ed2af93ab1"
version = "2.3.9+0"
"""

# ╔═╡ Cell order:
# ╟─5c617b7e-12d5-11ee-2c35-1fed12f104a4
# ╠═0d112a9e-15f0-4b9d-a323-445b7eaf0ef6
# ╟─8e73b088-9469-4029-9d79-571c964966b9
# ╠═ed1d306b-9488-4fb0-9335-48809d32fbbf
# ╟─395feaf0-923f-4dba-a43b-c0a130098051
# ╠═55b5df7d-059f-40fe-8698-9bf8a0e38177
# ╠═770a02bc-f496-493c-ac1f-52d98e1bea86
# ╟─b8a615a9-ee9f-4df7-8856-0f94e9254096
# ╠═f831873d-728d-48ad-8f1a-f9ed5fcdb763
# ╠═acad636a-6515-4942-89fb-9d6b0b2be513
# ╟─413e5c2d-f697-49f7-a1ea-e481c11905eb
# ╟─c3d7f254-efae-45b3-9eae-ae89d9e64fc6
# ╟─0c328dbd-df17-453c-961a-c5ec446d34c6
# ╠═cc188870-a483-4179-aed4-29bf71518ddf
# ╠═21334d46-f828-48ec-84b0-a81133fb55a8
# ╠═ec4fb85d-8fb1-47df-b811-966ceeba0b25
# ╠═102dbb27-ee69-42ca-8549-714463d10597
# ╟─7f58ae46-2531-41ba-a43b-456b93bb6c9e
# ╟─5c09ff51-6046-4e1d-913f-c27364ced969
# ╠═b2616e09-4396-491f-a37f-a6af4a79d4eb
# ╠═1c8c6d32-e960-40d4-ba5b-447e1c6fa998
# ╟─b5cb39cb-ec94-4349-8bc2-ff388fc623e5
# ╟─4a790301-0db2-4370-85f1-d6eff91047b9
# ╠═543e7024-4a8e-49d3-a568-b820c1aa98e4
# ╟─34800bee-346b-49df-81fa-e30e763ce537
# ╟─4587b7e0-7509-4534-9a05-b69dee4fd2d9
# ╟─8e81d52e-d4c8-439a-8f82-b79d9a08e54b
# ╟─078ae9f1-f29c-4171-8ec7-daacab7ef5f8
# ╠═32e1a386-604a-467c-bec2-5f6bc8a26913
# ╟─fa73f368-c318-4fb5-8a04-5ff4eab2e324
# ╟─3bbcf312-c153-4d40-a99b-b997244402ab
# ╠═aa07c21f-bcf6-4231-8947-819d9d8e2601
# ╟─91a8c494-ec4f-4b6e-a08f-0f1c1ae04a8b
# ╟─ff9a32d4-32bc-49e2-8124-acdef1ba7d20
# ╟─e7223e58-671e-46ec-a598-c290c1e85e65
# ╟─8306edda-1a92-4890-8e54-1bb92bec595f
# ╟─5c278f63-b614-43c6-ae13-3d8bea8044fa
# ╠═f8cc7064-7a14-4a90-a573-5570f008e08a
# ╟─33ab6e5d-b8f2-4320-8684-d58f69a46506
# ╠═a1e8772c-abb2-490c-92f8-37bc553060d6
# ╠═b2032635-c85b-452d-b283-26ad64b847c8
# ╟─37cabedf-c062-40fc-bbd9-9a4ed4f460b3
# ╠═42758b31-5a78-433d-8dd8-47bcd6986578
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
