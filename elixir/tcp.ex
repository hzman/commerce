defmodule Server do
  def absorb(b) do
      Block.add_block(b)
      Block.create_sign
      Block.create_reveal    
  end
  def start(port, type) do
    tcp_options = [:binary, {:packet, 0}, {:active, false}]
    {:ok, socket} = :gen_tcp.listen(port, tcp_options)
    new_peer(socket, type)
  end
  defp connect(host, port) do
    {:ok, s} = :gen_tcp.connect(:erlang.binary_to_list(host), port, [{:active, false}, {:packet, 0}])
    s
  end
  defp new_peer(socket, type) do
    {:ok, conn} = :gen_tcp.accept(socket)
    fun=&(&1)
    cond do
      type == :absorb -> fun=&(absorb(&1))
    end
    spawn(fn -> fun.(listen(conn, "")) end)
    new_peer(socket, type)		
  end
  defp ms(socket, string) do
    IO.puts inspect string
    :ok = :gen_tcp.send(socket, string<>"_")
    string
  end
  def talk(host, port, msg) do
    s=connect(host, port)
    ms(s, msg)
    done_listening?(s, "")
  end
  def ping(host, port) do
    s=connect(host, port)
    ms(s, "ping")
  end
  defp done_listening?(conn, data) do
    ds=String.length(data)
    lc=String.slice(data, ds-1, ds)
    cond do
      lc == "_" -> 
        ms(conn, String.slice(data, 0, ds-1))
      true -> listen(conn, data)
    end
  end
  defp listen(conn, data) do
    case :gen_tcp.recv(conn, 0) do
      {:ok, d} ->
        done_listening?(conn, data<>to_string(d))
      {:error, :closed} ->
        IO.puts "error"
    end
  end
end
