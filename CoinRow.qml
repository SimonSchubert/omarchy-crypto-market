import QtQuick
import "Api.js" as Api
import "Cols.js" as Cols

// One coin in a list: the markets table, the watchlist, search, trending.
Item {
  id: root
  property var app
  property var coin: ({})
  property bool selected: false
  property bool showStar: true
  property string subtitle: ""
  signal activated()

  readonly property var cols: Cols.layout(width)

  // Rows built from search or trending carry only some figures until their
  // prices arrive; a missing one is a dash, never a zero.
  function n(v) { return v === undefined || v === null ? NaN : v }
  readonly property string cur: app.currency
  readonly property bool starred: { app.store.prefs; return app.store.starred(coin.id) }

  implicitHeight: cols.compact ? 60 : 52
  Accessible.role: Accessible.ListItem
  Accessible.name: (coin.name || "") + " " + Api.price(coin.price, cur)

  Rectangle {
    anchors.fill: parent
    color: root.selected ? root.app.ui.selected : rowMouse.pressed ? root.app.ui.pressed
      : rowMouse.containsMouse ? root.app.ui.hover : "transparent"
  }

  MouseArea {
    id: rowMouse
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.activated()
  }

  Row {
    id: line
    anchors.fill: parent
    anchors.leftMargin: root.showStar ? 0 : 12
    anchors.rightMargin: 12
    spacing: 0

    IconButton {
      visible: root.showStar
      app: root.app
      anchors.verticalCenter: parent.verticalCenter
      glyph: root.starred ? "󰓎" : "󰓒"
      label: root.starred ? "Remove from watchlist" : "Add to watchlist"
      color: root.starred ? root.app.ui.star : root.app.ui.muted
      size: 18
      onClicked: root.app.store.toggleStar(root.coin.id)
    }

    Text {
      visible: root.cols.rank
      width: 40
      anchors.verticalCenter: parent.verticalCenter
      text: isNaN(root.coin.rank) || root.coin.rank === undefined ? "" : root.coin.rank
      color: root.app.ui.muted
      font.family: root.app.ui.font
      font.pixelSize: root.app.ui.fs.sm
      font.features: ({ "tnum": 1 })
    }

    // Name column: whatever is left once the numbers have their room.
    Item {
      id: nameCol
      width: line.width - (root.showStar ? root.app.ui.target : 0) - (root.cols.rank ? 40 : 0)
        - root.cols.price - (root.cols.compact ? 0 : root.cols.pct)
        - (root.cols.h1 ? root.cols.pct : 0) - (root.cols.d7 ? root.cols.pct : 0)
        - (root.cols.vol ? root.cols.money : 0) - (root.cols.mcap ? root.cols.money : 0)
        - (root.cols.spark ? root.cols.sparkW + 12 : 0)
      height: parent.height

      CoinLogo {
        id: logo
        app: root.app
        anchors.verticalCenter: parent.verticalCenter
        size: root.cols.compact ? 30 : 26
        source: root.coin.image || ""
        symbol: root.coin.symbol || ""
      }

      Column {
        anchors.left: logo.right
        anchors.leftMargin: 10
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        spacing: 1

        Row {
          width: parent.width
          spacing: 6
          Text {
            id: primary
            width: Math.min(implicitWidth, parent.width - (secondary.visible ? secondary.implicitWidth + 6 : 0))
            text: root.cols.compact ? (root.coin.symbol || "") : (root.coin.name || "")
            color: root.app.ui.text
            font.family: root.app.ui.font
            font.pixelSize: root.app.ui.fs.md
            font.weight: Font.DemiBold
            elide: Text.ElideRight
          }
          Text {
            id: secondary
            anchors.baseline: primary.baseline
            visible: !root.cols.compact || !isNaN(root.coin.rank)
            text: root.cols.compact ? "#" + root.coin.rank : (root.coin.symbol || "")
            color: root.app.ui.muted
            font.family: root.app.ui.font
            font.pixelSize: root.app.ui.fs.xs
          }
        }
        Text {
          visible: root.cols.compact
          width: parent.width
          text: root.subtitle || root.coin.name || ""
          color: root.app.ui.muted
          font.family: root.app.ui.font
          font.pixelSize: root.app.ui.fs.xs
          elide: Text.ElideRight
          maximumLineCount: 1
        }
      }
    }

    Sparkline {
      visible: root.cols.spark && root.cols.compact
      app: root.app
      width: root.cols.sparkW
      height: 26
      anchors.verticalCenter: parent.verticalCenter
      points: root.coin.spark || []
    }
    Item { visible: root.cols.spark && root.cols.compact; width: 12; height: 1 }

    // Compact: price over the 24h change, right-aligned.
    Column {
      visible: root.cols.compact
      width: root.cols.price
      anchors.verticalCenter: parent.verticalCenter
      spacing: 2
      Text {
        width: parent.width
        horizontalAlignment: Text.AlignRight
        text: Api.price(root.n(root.coin.price), root.cur)
        color: root.app.ui.text
        font.family: root.app.ui.font
        font.pixelSize: root.app.ui.fs.md
        font.weight: Font.Medium
        font.features: ({ "tnum": 1 })
        fontSizeMode: Text.HorizontalFit
        minimumPixelSize: root.app.ui.fs.xs
      }
      Change {
        anchors.right: parent.right
        app: root.app
        value: root.n(root.coin.ch24)
        font.pixelSize: root.app.ui.fs.xs
      }
    }

    // Wide: one figure per column.
    Text {
      visible: !root.cols.compact
      width: root.cols.price
      anchors.verticalCenter: parent.verticalCenter
      horizontalAlignment: Text.AlignRight
      text: Api.price(root.n(root.coin.price), root.cur)
      color: root.app.ui.text
      font.family: root.app.ui.font
      font.pixelSize: root.app.ui.fs.md
      font.weight: Font.Medium
      font.features: ({ "tnum": 1 })
      fontSizeMode: Text.HorizontalFit
      minimumPixelSize: root.app.ui.fs.xs
    }
    Item {
      visible: root.cols.h1
      width: root.cols.pct
      height: parent.height
      Change { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; app: root.app; value: root.n(root.coin.ch1h) }
    }
    Item {
      visible: !root.cols.compact
      width: root.cols.pct
      height: parent.height
      Change { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; app: root.app; value: root.n(root.coin.ch24) }
    }
    Item {
      visible: root.cols.d7
      width: root.cols.pct
      height: parent.height
      Change { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; app: root.app; value: root.n(root.coin.ch7d) }
    }
    Text {
      visible: root.cols.vol
      width: root.cols.money
      anchors.verticalCenter: parent.verticalCenter
      horizontalAlignment: Text.AlignRight
      text: Api.money(root.n(root.coin.vol), root.cur)
      color: root.app.ui.text
      font.family: root.app.ui.font
      font.pixelSize: root.app.ui.fs.sm
      font.features: ({ "tnum": 1 })
    }
    Text {
      visible: root.cols.mcap
      width: root.cols.money
      anchors.verticalCenter: parent.verticalCenter
      horizontalAlignment: Text.AlignRight
      text: Api.money(root.n(root.coin.mcap), root.cur)
      color: root.app.ui.text
      font.family: root.app.ui.font
      font.pixelSize: root.app.ui.fs.sm
      font.features: ({ "tnum": 1 })
    }
    Item { visible: root.cols.spark && !root.cols.compact; width: 12; height: 1 }
    Sparkline {
      visible: root.cols.spark && !root.cols.compact
      app: root.app
      width: root.cols.sparkW
      height: 30
      anchors.verticalCenter: parent.verticalCenter
      points: root.coin.spark || []
    }
  }

  Rectangle {
    anchors.bottom: parent.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.leftMargin: 12
    anchors.rightMargin: 12
    height: 1
    color: root.app.ui.divider
  }
}
