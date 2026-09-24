import QtQuick
import Quickshell
import Quickshell.Io
import "Api.mjs" as Api

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
    lastTab: "markets",
    launcher: true,
    launcherAdded: false
  })

  property var prefs: defaults
  property bool ready: false

  readonly property string currency: Api.validCurrency(prefs.currency) ? prefs.currency : "usd"
  readonly property string apiKey: typeof prefs.apiKey === "string" ? prefs.apiKey : ""
  readonly property int topN: [100, 250, 500, 1000].indexOf(prefs.topN) >= 0 ? prefs.topN : 100
  readonly property int refreshSec: Math.max(60, Math.min(3600, Number(prefs.refreshSec) || 120))
  readonly property var watchlist: Array.isArray(prefs.watchlist) ? prefs.watchlist : []
  readonly property var holdings: prefs.holdings && typeof prefs.holdings === "object" ? prefs.holdings : ({})

  // The saved snapshot as text; Gecko parses it on its worker thread.
  signal snapshotLoaded(string text)

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
    if (!secured) return
    try { snapshotFile.setText(JSON.stringify({ version: 1, entries: entries })) } catch (e) {}
  }

  function clearSnapshot() { saveSnapshot({}) }

  Timer {
    id: saveTimer
    interval: 400
    onTriggered: {
      if (!root.ready || !root.secured) { restart(); return }
      stateFile.setText(JSON.stringify(root.prefs, null, 1))
    }
  }

  // prefs.json holds the API key and the portfolio. FileView has no say in
  // permissions: it creates a missing directory 0755 and a file 0644, which
  // any other account on the machine can read. So before the first write,
  // both folders are made private -- created 0700, as the XDG spec asks, or
  // tightened if an older version left them open -- and the files 0600;
  // later atomic saves keep the mode of the file they replace. Nothing is
  // written until this has run. No shell: argument lists, fixed paths.
  property bool secured: false
  property int lockStep: 0

  Process {
    id: lock
    command: root.lockStep === 0
      ? ["install", "-d", "-m", "700", root.stateDir, root.cacheDir]
      : ["chmod", "600", root.stateDir + "/prefs.json", root.cacheDir + "/snapshot.json"]
    onExited: {
      if (root.lockStep === 0) {
        root.lockStep = 1
        Qt.callLater(function () { lock.running = true })
      } else {
        root.secured = true
      }
    }
  }

  Component.onCompleted: if (home) lock.running = true

  // A file that did not exist yet when the chmod ran is created 0644; the
  // first save of each file in a session runs the chmod once more.
  property var chmodded: ({})
  function lockAfterSave(name) {
    if (chmodded[name]) return
    chmodded[name] = true
    if (lock.running) { Qt.callLater(function () { root.chmodded[name] = false; root.lockAfterSave(name) }); return }
    lockStep = 1
    lock.running = true
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
    onSaved: root.lockAfterSave("prefs")
  }

  FileView {
    id: snapshotFile
    path: root.cacheDir + "/snapshot.json"
    atomicWrites: true
    printErrors: false
    onLoaded: root.snapshotLoaded(text())
    onSaved: root.lockAfterSave("snapshot")
  }
}
