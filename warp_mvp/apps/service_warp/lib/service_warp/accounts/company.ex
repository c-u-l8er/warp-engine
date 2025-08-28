defmodule ServiceWarp.Accounts.Company do
  @moduledoc """
  Represents a company using the ServiceWarp platform.

  Each company has its own technicians, jobs, and settings.
  """

  defstruct [
    :id,
    :name,
    :industry,              # :hvac, :plumbing, :electrical, :appliance, :security, :other
    :address,
    :coordinates,           # {lat, lon} - company headquarters
    :contact_person,
    :contact_email,
    :contact_phone,
    :subscription_plan,     # :starter, :professional, :enterprise
    :technician_limit,      # Max technicians allowed
    :active_technicians,    # Current active technician count
    :billing_status,        # :active, :past_due, :suspended
    :settings,              # Company-specific settings
    :created_at,
    :updated_at
  ]

  @type t :: %__MODULE__{
    id: String.t() | nil,
    name: String.t(),
    industry: :hvac | :plumbing | :electrical | :appliance | :security | :other,
    address: String.t(),
    coordinates: {float(), float()},
    contact_person: String.t(),
    contact_email: String.t(),
    contact_phone: String.t(),
    subscription_plan: :starter | :professional | :enterprise,
    technician_limit: non_neg_integer(),
    active_technicians: non_neg_integer(),
    billing_status: :active | :past_due | :suspended,
    settings: map(),
    created_at: DateTime.t() | nil,
    updated_at: DateTime.t() | nil
  }

  @doc """
  Creates a new company with default values.
  """
  def new(attrs \\ %{}) do
    %__MODULE__{
      id: generate_id(),
      name: "",
      industry: :other,
      address: "",
      coordinates: {0.0, 0.0},
      contact_person: "",
      contact_email: "",
      contact_phone: "",
      subscription_plan: :starter,
      technician_limit: 5,
      active_technicians: 0,
      billing_status: :active,
      settings: %{
        auto_assign_jobs: true,
        require_approval: false,
        customer_notifications: true,
        route_optimization: true,
        ai_assignment: false
      },
      created_at: DateTime.utc_now(),
      updated_at: DateTime.utc_now()
    }
    |> Map.merge(attrs)
  end

  @doc """
  Updates the company's subscription plan.
  """
  def update_subscription(company, new_plan) do
    technician_limit = case new_plan do
      :starter -> 5
      :professional -> :unlimited
      :enterprise -> :unlimited
    end

    %{company |
      subscription_plan: new_plan,
      technician_limit: technician_limit,
      updated_at: DateTime.utc_now()
    }
  end

  @doc """
  Increments the active technician count.
  """
  def add_technician(company) do
    %{company |
      active_technicians: company.active_technicians + 1,
      updated_at: DateTime.utc_now()
    }
  end

  @doc """
  Decrements the active technician count.
  """
  def remove_technician(company) do
    %{company |
      active_technicians: max(0, company.active_technicians - 1),
      updated_at: DateTime.utc_now()
    }
  end

  @doc """
  Checks if the company can add more technicians.
  """
  def can_add_technician?(company) do
    case company.technician_limit do
      :unlimited -> true
      limit -> company.active_technicians < limit
    end
  end

  @doc """
  Checks if the company has an active subscription.
  """
  def subscription_active?(company) do
    company.billing_status == :active
  end

  @doc """
  Gets the company's location for spatial operations.
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
  Gets a specific setting value.
  """
  def get_setting(company, key, default \\ nil) do
    Map.get(company.settings, key, default)
  end

  defp generate_id do
    "comp_#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}"
  end
end
