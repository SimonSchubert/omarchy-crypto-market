import QtQuick
import Quickshell
import Quickshell.Io
import "Api.js" as Api

// What the app remembers: preferences, the watchlist and the portfolio in
// ~/.local/state, and the last prices it saw in ~/.cache so the first screen
// is never empty, even offline.
//
// Kept in files of its own rather than shell.json: the host lets only bar
// widgets write their settings back, and a watchlist is not a setting.
Item {
  id: root

  readonly property string home: Quickshell.env("HOME") || ""
  readonly property string stateDir: (Quickshell.env("XDG_STATE_HOME") || home + "/.local/state") + "/crypto-market"
  readonly property string cacheDir: (Quickshell.env("XDG_CACHE_HOME") || home + "/.cache") + "/crypto-market"

  readonly property var defaults: ({
    version: 1,
    currency: "usd",
    apiKey: "",
    topN: 100,
    refreshSec: 120,
    watchlist: ["bitcoin", "ethereum", "solana"],
    holdings: {},
    lastTab: "markets"
  })

  property var prefs: defaults
  property bool ready: false

  readonly property string currency: Api.validCurrency(prefs.currency) ? prefs.currency : "usd"
  readonly property string apiKey: typeof prefs.apiKey === "string" ? prefs.apiKey : ""
  readonly property int topN: [100, 250, 500, 1000].indexOf(prefs.topN) >= 0 ? prefs.topN : 100
  readonly property int refreshSec: Math.max(60, Math.min(3600, Number(prefs.refreshSec) || 120))
  readonly property var watchlist: Array.isArray(prefs.watchlist) ? prefs.watchlist : []
  readonly property var holdings: prefs.holdings && typeof prefs.holdings === "object" ? prefs.holdings : ({})

  signal snapshotLoaded(var entries)

  function set(key, value) {
    var s = Object.assign({}, prefs)
    s[key] = value
    prefs = s
    saveTimer.restart()
  }

  function starred(id) { return watchlist.indexOf(id) >= 0 }

  function toggleStar(id) {
    if (!Api.safeId(id)) return
    var w = watchlist.slice()
    var i = w.indexOf(id)
    if (i >= 0) w.splice(i, 1); else w.push(id)
    set("watchlist", w)
  }

  // Holdings are kept per coin with the name and logo beside them, so the
  // portfolio can draw a row before the prices for it have arrived.
  function addTx(coin, tx) {
    if (!coin || !Api.safeId(coin.id)) return
    var h = Object.assign({}, holdings)
    var entry = h[coin.id] ? Object.assign({}, h[coin.id]) : { txs: [] }
    entry.name = coin.name
    entry.symbol = coin.symbol
    entry.image = coin.image || entry.image || ""
    entry.txs = (entry.txs || []).concat([tx])
    h[coin.id] = entry
    set("holdings", h)
  }

  function removeTx(id, ts) {
    var h = Object.assign({}, holdings)
    if (!h[id]) return
    var entry = Object.assign({}, h[id])
    entry.txs = (entry.txs || []).filter(function (t) { return t.ts !== ts })
    if (entry.txs.length) h[id] = entry; else delete h[id]
    set("holdings", h)
  }

  function saveSnapshot(entries) {
    try { snapshotFile.setText(JSON.stringify({ version: 1, entries: entries })) } catch (e) {}
  }

  function clearSnapshot() { saveSnapshot({}) }

  Timer {
    id: saveTimer
    interval: 400
    onTriggered: if (root.ready) stateFile.setText(JSON.stringify(root.prefs, null, 1))
  }

  FileView {
    id: stateFile
    path: root.stateDir + "/prefs.json"
    atomicWrites: true
    printErrors: false
    onLoaded: {
      try {
        var s = JSON.parse(text())
        if (s && typeof s === "object" && s.version === 1) root.prefs = Object.assign({}, root.defaults, s)
      } catch (e) {}
      root.ready = true
    }
    onLoadFailed: root.ready = true
  }

  FileView {
    id: snapshotFile
    path: root.cacheDir + "/snapshot.json"
    atomicWrites: true
    printErrors: false
    onLoaded: {
      try {
        var s = JSON.parse(text())
        if (s && s.version === 1 && s.entries) root.snapshotLoaded(s.entries)
      } catch (e) {}
    }
  }
}
