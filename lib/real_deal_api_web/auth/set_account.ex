defmodule RealDealApiWeb.Auth.SetAccount do
  import Plug.Conn

  alias RealDealApiWeb.Auth.ErrorResponse
  alias RealDealApi.Accounts

  def init(_options) do
  end

  def call(conn, _options) do
    if conn.assigns[:account] do
      conn
    else
      account_id = get_session(conn, :account_id)

      if account_id == nil, do: raise(ErrorResponse.Unauthorized)

      account = Accounts.get_full_account(account_id)

      if account_id && account do
        assign(conn, :account, account)
      else
        assign(conn, :account, nil)
      end
    end
  end
end
