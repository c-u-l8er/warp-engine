defmodule ServiceWarp.Accounts.Company do
  @moduledoc """
  Company management for ServiceWarp multi-tenancy.
  """

  defstruct [
    :id,
    :name,
    :industry,
    :coordinates,
    :subscription_plan,
    :technician_limit,
    :active_technicians,
    :billing_status,
    :settings,
    :created_at,
    :updated_at
  ]

  @doc """
  Creates a new company with default values.
  """
  def new(attrs \\ %{}) do
    %__MODULE__{
      id: generate_id(),
      name: attrs[:name] || "New Company",
      industry: attrs[:industry] || "General",
      coordinates: attrs[:coordinates] || {0.0, 0.0},
      subscription_plan: attrs[:subscription_plan] || "Starter",
      technician_limit: attrs[:technician_limit] || 10,
      active_technicians: attrs[:active_technicians] || 0,
      billing_status: attrs[:billing_status] || "active",
      settings: attrs[:settings] || %{},
      created_at: DateTime.utc_now(),
      updated_at: DateTime.utc_now()
    }
  end

  @doc """
  Updates the subscription plan of a company.
  """
  def update_subscription(company, new_plan) do
    %{company |
      subscription_plan: new_plan,
      updated_at: DateTime.utc_now()
    }
  end

  @doc """
  Adds a technician to the company.
  """
  def add_technician(company) do
    if can_add_technician?(company) do
      %{company |
        active_technicians: company.active_technicians + 1,
        updated_at: DateTime.utc_now()
      }
    else
      company
    end
  end

  @doc """
  Removes a technician from the company.
  """
  def remove_technician(company) do
    if company.active_technicians > 0 do
      %{company |
        active_technicians: company.active_technicians - 1,
        updated_at: DateTime.utc_now()
      }
    else
      company
    end
  end

  @doc """
  Checks if the company can add more technicians.
  """
  def can_add_technician?(company) do
    company.active_technicians < company.technician_limit
  end

  @doc """
  Checks if the company's subscription is active.
  """
  def subscription_active?(company) do
    company.billing_status == "active"
  end

  @doc """
  Gets the location of the company.
  """
  def location(company) do
    company.coordinates
  end

  @doc """
  Updates company settings.
  """
  def update_settings(company, new_settings) do
    %{company |
      settings: Map.merge(company.settings, new_settings),
      updated_at: DateTime.utc_now()
    }
  end

  @doc """
  Gets a setting value with a default fallback.
  """
  def get_setting(company, key, default \\ nil) do
    Map.get(company.settings, key, default)
  end

  # Private functions

  defp generate_id do
    "company_#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}"
  end
end
