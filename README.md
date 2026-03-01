# Forecast Assessment

This project implements a forecast lookup flow with country + postal/address input, global location resolution, weather retrieval, and cache-aware responses.

## How I approached the problem

I broke the feature into small, testable steps:

- Build the request flow first (`country`, optional `postal_code`, optional `address`) with clear validation.
- Resolve location with a postal-first strategy and an address fallback when needed.
- Isolate external integrations into service classes (`LocationResolver`, `WeatherClient`).
- Add caching and extract reusable logic into dedicated services (`ForecastCacheKeyBuilder`, `WeatherFetcher`).
- Keep request/service specs close to behavior so the decision flow is easy to verify.

## Why these choices

- `Nominatim` was used for global geocoding because it supports country filtering and postal/address queries with a simple API.
- `Open-Meteo` was used for weather because it provides rich current conditions without adding auth complexity for this stage.
- Service classes keep the controller focused on orchestration and make external calls easier to mock in tests.
- Cache key strategy favors `country + postal` when available, with a `country + rounded lat/lon` fallback when postal data is missing.
- Chose browser caching for the cache layer because it's simple and easy to implement as a primary caching method in this case.

## Code quality focus

- Strong params in the controller.
- Explicit validation and user-facing error messages for invalid inputs.
- Small, focused service classes with `.call`.
- Shared `BaseService::Result` pattern for consistent success/error handling.
- Specs for request flow and key service error cases.

## Challenges and tradeoffs

- Autoloading for new service classes caused intermittent constant resolution issues during development; fixed by aligning service naming and namespace usage.
- Country support currently uses a curated ISO list instead of a full ISO dataset.
- Weather and geocoding are network-dependent integrations, so tests mock those boundaries.

## What I would do next with more time

- Expand country list management to a canonical ISO source.
- Add Redis as the secondary cache store for postal/ZIP-based lookups and weather payloads to improve cache hit rate and response time under load.
- Add retries/circuit breaking around external API calls.
- Add observability for geocoding/weather latency and failure rates.
- Improve UI feedback for partial-success cases.
- Add end-to-end tests for the full user flow.
- Improve UI overall (just plain text for now).

## Environment setup

This project uses `dotenv-rails` in development and test.

```bash
cp .env.example .env
```

Then fill in `.env` values for geocoding/weather settings.

## Running the project

### Prerequisites

- Ruby `3.2.2` (see `.ruby-version`)
- Bundler
- SQLite3

### Quick start

From the project root:

```bash
bin/rails server
```

Default URL: [http://localhost:3000](http://localhost:3000)

## Running tests

Run all specs:

```bash
bundle exec rspec
```

Run specific specs:

```bash
bundle exec rspec spec/requests/forecasts_spec.rb
bundle exec rspec spec/services/weather_client_spec.rb
```

## Useful commands

Check routes:

```bash
bin/rails routes -g forecast
```

Run a quick Rails runner check:

```bash
bin/rails runner 'puts ForecastCacheKeyBuilder.call(country: "US", postal_code: "33101", lat: "25.7617", lon: "-80.1918")'
```

## Troubleshooting

- If you hit constant loading issues after moving/renaming classes, restart the Rails server.
- If `bundle exec rspec` fails due missing gems, run `bundle install`.
- If the app boots but no weather data appears, verify `.env` values and outbound network access for Nominatim/Open-Meteo.
