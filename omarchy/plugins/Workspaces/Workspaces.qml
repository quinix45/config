import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import qs.Commons
import qs.Ui

BarWidget {
    id: root
    moduleName: "workspaces"

    readonly property var specials: [["acomms", "󰭹"], ["bnotes", "󱇧"], ["cmedia", "󰎇"]]

    function workspaceById(id) {
        var values = Hyprland.workspaces.values;
        for (var i = 0; i < values.length; i++) {
            if (values[i].id === id)
                return values[i];
        }

        return null;
    }

    function specialByName(name) {
        var values = Hyprland.workspaces.values;
        for (var i = 0; i < values.length; i++) {
            if (values[i].id < 0 && values[i].name === "special:" + name)
                return values[i];
        }

        return null;
    }

    function workspaceIds() {
        var ids = [1, 2, 3, 4, 5];
        var values = Hyprland.workspaces.values;

        for (var i = 0; i < values.length; i++) {
            var id = values[i].id;
            if (id > 0 && id <= 9 && ids.indexOf(id) === -1)
                ids.push(id);
        }

        ids.sort(function (left, right) {
            return left - right;
        });
        return ids;
    }

    function focusWorkspace(id) {
        if (!root.bar)
            return;
        root.bar.run("hyprctl dispatch " + Util.shellQuote("hl.dsp.focus({ workspace = \"" + id + "\" })"));
    }

    function toggleSpecial(name) {
        if (!root.bar)
            return;
        root.bar.run("hyprctl dispatch " + Util.shellQuote("hl.dsp.workspace.toggle_special(\"" + name + "\")"));
    }

    readonly property real trailingGap: root.vertical ? 0 : Style.spaceReal(1.5)

    implicitWidth: grid.implicitWidth + trailingGap
    implicitHeight: grid.implicitHeight

    GridLayout {
        id: grid
        anchors.fill: parent
        anchors.rightMargin: root.trailingGap
        columns: root.vertical ? 1 : root.workspaceIds().length + root.specials.length
        columnSpacing: root.vertical ? 0 : Style.space(1)
        rowSpacing: root.vertical ? Style.space(2) : 0

        Repeater {
            model: root.workspaceIds()

            WidgetButton {
                required property int modelData

                readonly property var workspace: root.workspaceById(modelData)
                readonly property bool occupied: workspace !== null && workspace.toplevels.values.length > 0
                readonly property bool focused: Hyprland.focusedWorkspace !== null && Hyprland.focusedWorkspace.id === modelData

                bar: root.bar
                // effect of focused workspace
                text: focused ? "\uDB85\uDCFB" : (modelData === 10 ? "0" : String(modelData))
                opacity: occupied || focused ? 1 : 0.5
                horizontalMargin: 6
                verticalPadding: 6
                fixedWidth: root.vertical ? root.barSize : Style.space(20)
                fixedHeight: root.barSize
                onPressed: function () {
                    root.focusWorkspace(modelData);
                }
            }
        }

        Repeater {
            model: root.specials

            WidgetButton {
                required property var modelData

                readonly property string name: modelData[0]
                readonly property string label: modelData[1]
                readonly property bool occupied: root.specialByName(name) !== null
                readonly property bool focused: Hyprland.focusedWorkspace !== null && Hyprland.focusedWorkspace.name === "special:" + name

                bar: root.bar
                visible: occupied || focused
                text: focused ? "\uDB85\uDCFB" : label
                opacity: occupied || focused ? 1 : 0.5
                horizontalMargin: 6
                verticalPadding: 6
                fixedWidth: root.vertical ? root.barSize : Style.space(20)
                fixedHeight: root.barSize
                onPressed: function () {
                    root.toggleSpecial(name);
                }
            }
        }
    }
}
