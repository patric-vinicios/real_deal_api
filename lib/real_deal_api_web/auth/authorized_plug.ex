defmodule RealDealApiWeb.Auth.AuthorizedPlug do
  alias RealDealApiWeb.Auth.ErrorResponse.Forbidden

  def check_authorization(%{params: %{"account" => params}} = conn, _params) do
    if conn.assigns.account.id == params["id"] do
      conn
    else
      raise Forbidden
    end
  end

  def check_authorization(%{params: %{"user" => params}} = conn, _params) do
    if conn.assigns.account.user.id == params["id"] do
      conn
    else
      raise Forbidden
    end
  end
end
