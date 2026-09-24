# Crypto Market

CoinGecko as an Omarchy app: live prices, coin pages, a watchlist and a
portfolio, in one panel that lays itself out for the desktop and for the phone.

![Crypto Market on the desktop](preview.png)

<img src="preview-phone.png" alt="Crypto Market on a phone" width="300">

## What it does

- **Markets**: the top 100, 250, 500 or 1,000 coins by market cap, with price,
  1h/24h/7d change, volume, market cap and a 7-day sparkline. Sort by any
  column. Above the list: total market cap, 24h volume, and BTC and ETH dominance.
- **Coin pages**:
  - a price chart for 24h, 7d, 1M, 3M, 1Y or Max, with a crosshair
  - the change over 1h, 24h, 7d, 30d and 1y
  - the 24h range
  - market cap, fully diluted valuation, volume, and circulating, total and max supply
  - all-time high and low, with dates
  - the project's description, categories and links
- **Watchlist**: star any coin to follow it.
- **Discover**:
  - trending coins on CoinGecko
  - the day's biggest gainers and losers among the top 250 (anything under
    $50K of volume is left out)
  - every category by market cap
- **Search**: find any coin CoinGecko lists.
- **Converter**: coin to currency and back, on every coin page.
- **Portfolio**: record buys and sells to see today's value, the 24h change,
  profit and loss per coin, and an allocation bar.
- **15 currencies**, including BTC, ETH and sats.

It opens instantly and offline with the last prices it saw, and it refreshes
only while it is open.

## Install

```sh
omarchy plugin add https://github.com/SimonSchubert/omarchy-crypto-market.git --enable
```

To open it, bind a key in `~/.config/hypr/bindings.lua`:

```lua
o.bind("SUPER + SHIFT + C", "Crypto Market", "omarchy-shell shell toggle io.github.simonschubert.crypto-market")
```

Or run `omarchy-shell shell toggle io.github.simonschubert.crypto-market` from
anywhere.

On Omarchy Mobile it appears in the app drawer as its own app.

## Keys (desktop)

| Key | Action |
| --- | --- |
| `1`–`4` | Markets, Watchlist, Discover, Portfolio |
| `/` | Search |
| `↑` `↓` `Enter` | Move through a list, open a coin |
| `←` `→` | Chart range on a coin page |
| `f` | Star or unstar the selected coin |
| `r` | Refresh |
| `Esc` | Back, then close |

## Rate limits and the API key

CoinGecko's free public API answers only a few requests a minute. The app
spaces its requests out and caches every answer. When CoinGecko asks it to
slow down, it keeps showing the prices it has and retries by itself.

For more headroom, create a free **Demo** key at
[coingecko.com/en/developers/dashboard](https://www.coingecko.com/en/developers/dashboard)
and paste it into Settings. The key is stored in
`~/.local/state/crypto-market/prefs.json` and is sent only to CoinGecko.

## Privacy and security

- The only network access is HTTPS requests from QML to `api.coingecko.com`,
  plus coin logos from CoinGecko's image CDN.
- It runs no processes and no shell commands, and it writes nothing outside
  its own two files:
  - `~/.local/state/crypto-market/prefs.json`: settings, watchlist and portfolio
  - `~/.cache/crypto-market/snapshot.json`: the last prices, for opening offline
- Project descriptions are shown as plain text. Links open in your browser,
  and only `https:` links are opened.

## Credits

Market data by [CoinGecko](https://www.coingecko.com). This is not financial advice.

MIT licensed.
