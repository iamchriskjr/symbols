import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "Model.js" as Model

Panel {
  id: root

  moduleName: "iamchriskjr.symbols"
  ipcTarget: "iamchriskjr.symbols"

  property var anchorItem: null
  property var hostWidget: null

  // --- State & Settings ----------------------------------------------------
  property var allSymbols: Model.defaultSymbols
  property var categories: Model.getCategories(Model.defaultSymbols)
  property string selectedCategory: "All"
  property string searchQuery: ""
  property bool autoPaste: true

  property var favorites: []
  property var recent: []
  property var frequency: ({})
  property var hoveredSymbol: null

  readonly property var filteredSymbols: Model.filterSymbols(
    selectedCategory === "All" ? allSymbols : allSymbols.filter(function(s) { return s.category === selectedCategory }),
    searchQuery
  )

  readonly property var favoriteSymbols: Model.getFavoriteSymbols(favorites, allSymbols)
  readonly property var frequentSymbols: Model.getTopFrequent(frequency, allSymbols, 10, favorites)
  readonly property var recentSymbols: Model.getRecentSymbols(recent, allSymbols, 10, favorites)

  readonly property color foreground: Color.popups.text
  readonly property color accent: Color.accent
  readonly property color muted: Color.muted

  // --- Lifecycle & Actions -------------------------------------------------

  function open() {
    root.hoveredSymbol = null
    loadState()
    root.controller.show()
  }

  function close() {
    root.hoveredSymbol = null
    root.controller.hide()
  }

  function toggle() {
    if (root.opened) root.close()
    else root.open()
  }

  function toggleFavorite(symbolChar) {
    var list = favorites.slice()
    var idx = list.indexOf(symbolChar)
    if (idx !== -1) {
      list.splice(idx, 1)
    } else {
      list.push(symbolChar)
    }
    favorites = list
    saveState()
  }

  function isFavorite(symbolChar) {
    return favorites.indexOf(symbolChar) !== -1
  }

  function selectSymbol(item) {
    if (!item || !item.char) return
    var symbolChar = item.char

    // Update frequency
    var freq = Object.assign({}, frequency)
    freq[symbolChar] = (freq[symbolChar] || 0) + 1
    frequency = freq

    // Update recent
    var rec = recent.filter(function(c) { return c !== symbolChar })
    rec.unshift(symbolChar)
    if (rec.length > 20) rec = rec.slice(0, 20)
    recent = rec

    saveState()

    // Copy to clipboard
    var safeChar = String(symbolChar).replace(/\\/g, "\\\\").replace(/"/g, "\\\"")
    if (root.autoPaste) {
      root.close()
      Quickshell.execDetached([
        "bash", "-c",
        "printf %s \"" + safeChar + "\" | wl-copy && sleep 0.08 && wtype \"" + safeChar + "\""
      ])
    } else {
      Quickshell.execDetached([
        "bash", "-c",
        "printf %s \"" + safeChar + "\" | wl-copy"
      ])
      root.close()
    }
  }

  function loadState() {
    loadStateProc.running = true
  }

  function saveState() {
    var stateObj = {
      favorites: root.favorites,
      recent: root.recent,
      frequency: root.frequency,
      autoPaste: root.autoPaste
    }
    var jsonStr = JSON.stringify(stateObj, null, 2)
    var escapedJson = jsonStr.replace(/'/g, "'\\''")
    Quickshell.execDetached([
      "bash", "-c",
      "mkdir -p /home/iamchriskjr/.local/state/omarchy/plugins && printf '%s' '" + escapedJson + "' > /home/iamchriskjr/.local/state/omarchy/plugins/symbols.json"
    ])
  }

  Component.onCompleted: {
    loadState()
  }

  Process {
    id: loadStateProc
    command: ["cat", "/home/iamchriskjr/.local/state/omarchy/plugins/symbols.json"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try {
          var data = JSON.parse(text)
          if (data) {
            if (Array.isArray(data.favorites)) root.favorites = data.favorites
            if (Array.isArray(data.recent)) root.recent = data.recent
            if (data.frequency && typeof data.frequency === "object") root.frequency = data.frequency
            if (typeof data.autoPaste === "boolean") root.autoPaste = data.autoPaste
          }
        } catch (e) {}
      }
    }
  }

  // --- Dropdown Panel Window -----------------------------------------------

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.hostWidget || root
    bar: root.bar
    open: root.opened
    focusTarget: searchInput
    centerOnBar: false

    contentWidth: panel.fittedContentWidth(Style.space(520))
    contentHeight: panel.fittedContentHeight(Style.space(660), Style.space(700))

    ColumnLayout {
      id: mainLayout
      anchors.fill: parent
      spacing: Style.spacing.sm

      // 1. Header Row: Title + Auto-paste Toggle
      RowLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: Style.space(30)

        Text {
          text: "Symbols"
          color: root.foreground
          font.family: Style.font.family
          font.pixelSize: Style.font.subtitle
          font.bold: true
        }

        Item {
          Layout.fillWidth: true
        }

        RowLayout {
          spacing: Style.spacing.sm

          Text {
            text: "Auto-paste"
            color: root.autoPaste ? root.foreground : Qt.darker(root.foreground, 1.6)
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
            font.bold: true
          }

          ToggleSwitch {
            checked: root.autoPaste
            rounded: true
            interactive: true
            onToggled: {
              root.autoPaste = !root.autoPaste
              root.saveState()
            }
          }
        }
      }

      // 2. Search Bar
      TextField {
        id: searchInput
        Layout.fillWidth: true
        placeholderText: "Search symbol, name, or unicode (e.g. pipe, arrow, 007)..."
        text: root.searchQuery
        onTextChanged: root.searchQuery = text

        Keys.onEscapePressed: {
          if (text !== "") text = ""
          else root.close()
        }
      }

      // 3. Category Tabs (when not searching)
      Flickable {
        visible: root.searchQuery === ""
        Layout.fillWidth: true
        Layout.preferredHeight: visible ? Style.space(28) : 0
        contentWidth: categoryRow.width
        boundsBehavior: Flickable.StopAtBounds
        clip: true

        Row {
          id: categoryRow
          spacing: Style.spacing.xs

          Repeater {
            model: root.categories

            Rectangle {
              required property string modelData
              readonly property bool isSelected: root.selectedCategory === modelData

              width: catText.implicitWidth + Style.space(16)
              height: Style.space(26)
              radius: Style.cornerRadius > 0 ? Style.space(13) : 0
              color: isSelected
                ? root.accent
                : (catMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent")

              border.width: isSelected ? 0 : Style.spacing.hairline
              border.color: isSelected ? "transparent" : Qt.rgba(1, 1, 1, 0.12)

              Text {
                id: catText
                anchors.centerIn: parent
                text: modelData
                color: isSelected
                  ? Color.accentForeground
                  : (catMouse.containsMouse ? root.foreground : Qt.darker(root.foreground, 1.4))
                font.family: Style.font.family
                font.pixelSize: Style.font.caption
                font.bold: isSelected
              }

              MouseArea {
                id: catMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.selectedCategory = modelData
              }
            }
          }
        }
      }

      // 4. Pinned Section: Favorites (when present and not searching)
      Column {
        visible: root.searchQuery === "" && root.favoriteSymbols.length > 0
        Layout.fillWidth: true
        spacing: Style.spacing.xs

        PanelSectionHeader {
          text: "FAVORITES (" + root.favoriteSymbols.length + ")"
        }

        Grid {
          columns: 10
          spacing: Style.space(4)
          width: parent.width

          Repeater {
            model: root.favoriteSymbols

            SymbolTile {
              required property var modelData
              symbolItem: modelData
              isFav: true
              onTileClicked: root.selectSymbol(symbolItem)
              onFavoriteToggled: root.toggleFavorite(symbolItem.char)
              onTileHovered: function(item, hovered) {
                root.hoveredSymbol = hovered ? item : null
              }
            }
          }
        }
      }

      // 5. Pinned Section: Frequently Used (when present and not searching, favorites excluded)
      Column {
        visible: root.searchQuery === "" && root.frequentSymbols.length > 0
        Layout.fillWidth: true
        spacing: Style.spacing.xs

        PanelSectionHeader {
          text: "FREQUENTLY USED (" + root.frequentSymbols.length + ")"
        }

        Grid {
          columns: 10
          spacing: Style.space(4)
          width: parent.width

          Repeater {
            model: root.frequentSymbols

            SymbolTile {
              required property var modelData
              symbolItem: modelData
              isFav: false
              onTileClicked: root.selectSymbol(symbolItem)
              onFavoriteToggled: root.toggleFavorite(symbolItem.char)
              onTileHovered: function(item, hovered) {
                root.hoveredSymbol = hovered ? item : null
              }
            }
          }
        }
      }

      // 6. Pinned Section: Recently Used (when present and not searching, favorites excluded)
      Column {
        visible: root.searchQuery === "" && root.recentSymbols.length > 0
        Layout.fillWidth: true
        spacing: Style.spacing.xs

        PanelSectionHeader {
          text: "RECENTLY USED (" + root.recentSymbols.length + ")"
        }

        Grid {
          columns: 10
          spacing: Style.space(4)
          width: parent.width

          Repeater {
            model: root.recentSymbols

            SymbolTile {
              required property var modelData
              symbolItem: modelData
              isFav: false
              onTileClicked: root.selectSymbol(symbolItem)
              onFavoriteToggled: root.toggleFavorite(symbolItem.char)
              onTileHovered: function(item, hovered) {
                root.hoveredSymbol = hovered ? item : null
              }
            }
          }
        }
      }

      // 7. Section Header with dynamic count
      PanelSectionHeader {
        Layout.fillWidth: true
        text: (root.searchQuery !== ""
          ? "SEARCH RESULTS (" + root.filteredSymbols.length + ")"
          : (root.selectedCategory === "All" ? "ALL SYMBOLS" : root.selectedCategory.toUpperCase() + " SYMBOLS") + " (" + root.filteredSymbols.length + ")")
      }

      // 8. Virtualized GridView Container
      Item {
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true

        GridView {
          id: symbolGrid
          anchors.fill: parent
          model: root.filteredSymbols
          cellWidth: Style.space(48)
          cellHeight: Style.space(54)
          clip: true
          boundsBehavior: Flickable.StopAtBounds

          ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
            anchors.right: symbolGrid.right
          }

          delegate: SymbolTile {
            required property var modelData
            symbolItem: modelData
            isFav: root.isFavorite(symbolItem.char)
            onTileClicked: root.selectSymbol(symbolItem)
            onFavoriteToggled: root.toggleFavorite(symbolItem.char)
            onTileHovered: function(item, hovered) {
              root.hoveredSymbol = hovered ? item : null
            }
          }
        }

        Text {
          visible: root.filteredSymbols.length === 0
          text: "No matching symbols found"
          color: Qt.darker(root.foreground, 1.6)
          font.family: Style.font.family
          font.pixelSize: Style.font.body
          anchors.centerIn: parent
        }
      }

      // 9. Live Hover Detail Footer Bar
      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: Style.space(28)
        radius: Style.cornerRadius > 0 ? Style.space(4) : 0
        color: Qt.rgba(1, 1, 1, 0.05)
        border.width: Style.spacing.hairline
        border.color: Qt.rgba(1, 1, 1, 0.08)

        RowLayout {
          anchors.fill: parent
          anchors.leftMargin: Style.space(8)
          anchors.rightMargin: Style.space(8)
          spacing: Style.space(8)

          Text {
            visible: root.hoveredSymbol !== null
            text: root.hoveredSymbol ? root.hoveredSymbol.char : ""
            color: root.accent
            font.family: Style.font.family
            font.pixelSize: Style.space(16)
            font.bold: true
          }

          Text {
            Layout.fillWidth: true
            elide: Text.ElideRight
            text: root.hoveredSymbol
              ? root.hoveredSymbol.name + " (" + root.hoveredSymbol.code + ")"
              : "Hover a symbol to preview name · Click to copy/paste"
            color: root.hoveredSymbol ? root.foreground : Qt.darker(root.foreground, 1.8)
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
          }

          Text {
            visible: root.hoveredSymbol !== null
            text: root.hoveredSymbol ? root.hoveredSymbol.category : ""
            color: Qt.darker(root.foreground, 1.5)
            font.family: Style.font.family
            font.pixelSize: Style.space(9)
          }
        }
      }
    }
  }
}
