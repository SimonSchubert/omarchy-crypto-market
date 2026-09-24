import QtQuick

// A coin's logo, or its initials on a tinted disc until the logo arrives (or
// when it never does).
Item {
  id: root
  property var app
  property string source: ""
  property string symbol: ""
  property int size: 28

  width: size
  height: size

  Rectangle {
    anchors.fill: parent
    radius: width / 2
    visible: img.status !== Image.Ready
    color: root.app.ui.surfaceHigh
    Text {
      anchors.centerIn: parent
      text: root.symbol.slice(0, root.size >= 40 ? 3 : 2)
      color: root.app.ui.muted
      font.family: root.app.ui.font
      font.pixelSize: Math.max(10, Math.round(root.size * 0.34))
      font.weight: Font.DemiBold
    }
  }

  Image {
    id: img
    anchors.fill: parent
    source: root.source
    asynchronous: true
    cache: true
    smooth: true
    mipmap: true
    fillMode: Image.PreserveAspectFit
    sourceSize.width: root.size * 2
    sourceSize.height: root.size * 2
  }
}
