import QtQuick
import qs.Commons
import qs.Ui

Rectangle {
  id: tile

  property var symbolItem: null
  property bool isFav: false
  property color foreground: Color.popups.text
  property color accent: Color.accent

  signal tileClicked()
  signal favoriteToggled()
  signal tileHovered(var item, bool isHovered)

  width: Style.space(44)
  height: Style.space(50)
  radius: Style.cornerRadius > 0 ? Style.space(6) : 0

  readonly property bool isHovered: tileMouse.containsMouse || heartMouse.containsMouse
  color: isHovered ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.04)

  border.width: isHovered ? Style.spacing.hairline * 2 : Style.spacing.hairline
  border.color: isHovered ? accent : Qt.rgba(1, 1, 1, 0.08)

  Behavior on color { ColorAnimation { duration: 80 } }

  // Heart icon at TOP LEFT of the tile
  Item {
    id: heartArea
    width: Style.space(16)
    height: Style.space(16)
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.topMargin: Style.space(2)
    anchors.leftMargin: Style.space(2)
    z: 2

    Text {
      anchors.centerIn: parent
      text: tile.isFav ? "♥" : "♡"
      font.pixelSize: Style.font.caption
      color: tile.isFav ? "#f38ba8" : (heartMouse.containsMouse ? tile.foreground : Qt.darker(tile.foreground, 2.0))
    }

    MouseArea {
      id: heartMouse
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: tile.favoriteToggled()
    }
  }

  // Main Symbol (Center)
  Text {
    anchors.centerIn: parent
    anchors.verticalCenterOffset: -Style.space(2)
    text: tile.symbolItem ? tile.symbolItem.char : ""
    font.family: Style.font.family
    font.pixelSize: Style.space(19)
    color: tile.foreground
  }

  // Unicode Hex Code (Bottom)
  Text {
    anchors.bottom: parent.bottom
    anchors.bottomMargin: Style.space(3)
    anchors.horizontalCenter: parent.horizontalCenter
    text: tile.symbolItem && tile.symbolItem.code ? tile.symbolItem.code.replace("U+", "") : ""
    font.family: Style.font.family
    font.pixelSize: Style.space(8)
    font.bold: true
    color: Qt.darker(tile.foreground, 1.8)
  }

  // Main Tile Click Area (excluding heart)
  MouseArea {
    id: tileMouse
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onEntered: tile.tileHovered(tile.symbolItem, true)
    onExited: tile.tileHovered(tile.symbolItem, false)
    onClicked: tile.tileClicked()
  }
}
