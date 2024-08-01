defmodule RealDealApiWeb.AccountController do
  use RealDealApiWeb, :controller

  import RealDealApiWeb.Auth.AuthorizedPlug

  alias RealDealApiWeb.Auth.ErrorResponse.Unauthorized
  alias RealDealApiWeb.Auth.Guardian
  alias RealDealApi.{Accounts, Accounts.Account, Users, Users.User}

  plug :check_authorization when action in [:update, :delete]

  action_fallback RealDealApiWeb.FallbackController

  def index(conn, _params) do
    accounts = Accounts.list_accounts()
    render(conn, :index, accounts: accounts)
  end

  def create(conn, %{"account" => account_params}) do
    with {:ok, %Account{} = account} <- Accounts.create_account(account_params),
         {:ok, %User{} = _user} <- Users.create_user(account, account_params) do
      authorize_account(conn, account.email, account_params["hash_params"])
    end
  end

  def sign_in(conn, %{"email" => email, "hash_password" => hash_password}) do
    authorize_account(conn, email, hash_password)
  end

  defp authorize_account(conn, email, hash_password) do
    case Guardian.authenticate(email, hash_password) do
      {:ok, account, token} ->
        conn
        |> Plug.Conn.put_session(:account_id, account.id)
        |> put_status(:ok)
        |> render(:create, account: account, token: token)

      {:error, :unauthorized} ->
        raise Unauthorized, message: "Email or password incorrect"
    end
  end

  def refresh_session(conn, %{}) do
    token = Guardian.Plug.current_token(conn)
    {:ok, account, new_token} = Guardian.authenticate(token)

    conn
    |> Plug.Conn.put_session(:account_id, account.id)
    |> put_status(:ok)
    |> render(:create, account: account, token: new_token)
  end

  def sign_out(conn, %{}) do
    account = conn.assigns[:account]
    token = Guardian.Plug.current_token(conn)
    Guardian.revoke(token)

    conn
    |> Plug.Conn.clear_session()
    |> put_status(:ok)
    |> render(:create, account: account, token: nil)
  end

  def show(conn, %{"id" => id}) do
    account = Accounts.get_full_account(id)
    render(conn, :full_show, account: account)
  end

  def current_account(conn, %{}) do
    render(conn, :full_show, account: conn.assigns.account)
  end

  def update(conn, %{"current_hash" => current_hash, "account" => account_params}) do
    case Guardian.validate_password(current_hash, conn.assigns.account.hash_password) do
      true ->
        {:ok, account} = Accounts.update_account(conn.assigns.account, account_params)
        render(conn, :show, account: account)

      false ->
        raise Unauthorized, message: "Password incorrect."
    end
  end

  def delete(conn, %{"id" => id}) do
    account = Accounts.get_account!(id)

    with {:ok, %Account{}} <- Accounts.delete_account(account) do
      send_resp(conn, :no_content, "")
    end
  end
end