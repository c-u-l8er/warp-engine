defmodule WarpWeb.Gettext do
  @moduledoc """
  A module providing Internationalization with a gettext-based API.

  By using [Gettext](https://hexdocs.pm/gettext), your module gains a set of
  macros for internationalization and localization:

  ```elixir
  import WarpWeb.Gettext

  # Simple translation
  gettext("Here is the string to translate")

  # Plural translation
  ngettext("Here is the string to translate",
           "Here are the strings to translate",
           3)

  # Domain-based translation
  dgettext("errors", "Here is the error message to translate")

  # Context-based translation
  pgettext("email", "Here is the string to translate")

  # Context-based plural translation
  dpngettext("errors", "Here is the string to translate",
              "Here are the strings to translate", 3)
  ```

  See the [Gettext Docs](https://hexdocs.pm/gettext) for detailed usage.
  """
  use Gettext, otp_app: :warp_web
end

