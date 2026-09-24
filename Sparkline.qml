import QtQuick

// Seven days of price as one line, green or red by where it ended.
Canvas {
  id: root
  property var app
  property var points: []
  property real lineWidth: 1.5

  readonly property bool rising: points && points.length > 1 && points[points.length - 1] >= points[0]

  renderStrategy: Canvas.Cooperative
  onPointsChanged: requestPaint()
  onWidthChanged: requestPaint()
  onHeightChanged: requestPaint()

  onPaint: {
    var ctx = getContext("2d")
    ctx.reset()
    var p = root.points
    if (!p || p.length < 2 || width <= 0 || height <= 0) return
    var lo = Infinity, hi = -Infinity
    for (var i = 0; i < p.length; i++) { lo = Math.min(lo, p[i]); hi = Math.max(hi, p[i]) }
    var span = hi - lo || 1
    var pad = root.lineWidth
    ctx.lineWidth = root.lineWidth
    ctx.lineJoin = "round"
    ctx.strokeStyle = String(root.rising ? root.app.ui.up : root.app.ui.down)
    ctx.beginPath()
    for (var j = 0; j < p.length; j++) {
      var x = j / (p.length - 1) * width
      var y = pad + (1 - (p[j] - lo) / span) * (height - 2 * pad)
      if (j === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y)
    }
    ctx.stroke()
  }
}
