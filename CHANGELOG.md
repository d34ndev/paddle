# Changelog

## 3.0 - 2026-09-27

### Breaking changes

- **Ruby 3.3 or later is required.** Ruby 3.2 has reached end of life.
- **Responses are no longer OpenStructs.** `Paddle::Object` is now a lightweight class, and nested objects are
  `Paddle::Object` rather than `OpenStruct`. Dot access, hash access (`obj[:id]`, `obj["id"]`), setters, `nil` for
  missing attributes, `each_pair` and `update` work as before. Code that checks `is_a?(OpenStruct)` or uses
  OpenStruct-only methods, such as `delete_field` or `to_h` with a block, will need updating. Attributes named after
  built-in methods, such as `hash` or `class`, need to be read with `obj[:hash]`.
- **`to_h` now converts nested objects to hashes too**, rather than only the top level.
- **The `ostruct` and `cgi` dependencies have been removed.** If your app uses either and relied on this gem to install
  it, add it to your Gemfile.
- **Every non-2xx response now raises an error.** Previously only a fixed list of status codes raised, so responses
  like 422, 502 and 504 were returned as if they'd succeeded. Non-JSON error bodies, such as an HTML page from a
  gateway, also raise now rather than causing a `NoMethodError`.
- **The environment is detected from the API key.** Keys starting with `pdl_live_` or `pdl_sdbx_` set the environment
  automatically, so a sandbox key with no environment set now goes to the sandbox rather than production. Setting an
  environment that doesn't match the key raises an `ArgumentError`. Older keys without a prefix behave as before.
- **Config changes take effect straight away.** The connection used to keep the API key, environment, version and
  connection options from the first request, so later changes were ignored.
- **Array query params are sent as comma-separated lists**, e.g. `status=active,past_due`, as Paddle expects. They
  were sent as `status[]=active&status[]=past_due`, which Paddle didn't read as intended.
- `ServiceUnavailableError` (503) now says the API is temporarily unavailable, rather than describing a rate limit.
  Rate limits are raised as `TooManyRequestsError` (429).

### Added

- `Paddle.with_config` to make requests with a different API key, environment or version, such as for another
  Paddle account. It's safe to use in multi-threaded servers and job runners.
- `Paddle::Webhook` for verifying webhook signatures, with `verify!`, `valid?` and `construct_event`.
- `Paddle::Metric` for the metrics API: `monthly_recurring_revenue`, `monthly_recurring_revenue_change`,
  `active_subscribers`, `revenue`, `refunds`, `chargebacks` and `checkout_conversion`.
- The Explore metrics API, with `Metric.explore_entities` and `Metric.explore`.
- `Collection#has_more?`, `next_page` and `auto_paging_each` for paging through results.
- `skip_count: true` on any list method, to skip counting results for faster responses.
- `Subscription.history`, `Subscription.charge_preview` and `Transaction.revise`.
- `Customer.credit_balances` to return the credit balance for every currency.
- `Notification.replay` has been restored.
- `Adjustment.create` no longer needs `items:` when `type: "full"` is given.
- `Simulation.runs` and `SimulationRun.events` accept pagination params.
- `Paddle::Object#to_json`, `as_json`, `dig` and `key?`.

### Changed

- Building response objects is around 20x faster and uses around 20x less memory.
- Faraday 2.14.3 or later is required, for [GHSA-98m9-hrrm-r99r](https://github.com/advisories/GHSA-98m9-hrrm-r99r).
- The repository has moved to [d34ndev/paddle](https://github.com/d34ndev/paddle).
- The Classic API docs have moved to [docs/classic.md](docs/classic.md), and now cover every Classic endpoint.

### Fixed

- `delete_request` passed headers to Faraday as query params.
- Calling `update` on an object whose model doesn't support updating now raises a `NoMethodError`.

## Earlier versions

See the [releases on GitHub](https://github.com/d34ndev/paddle/releases) for versions before 3.0.
