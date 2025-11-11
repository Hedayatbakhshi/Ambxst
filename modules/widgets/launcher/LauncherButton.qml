import QtQuick
import qs.modules.globals
import qs.modules.services
import qs.config
import qs.modules.components

ToggleButton {
    buttonIcon: Config.bar.launcherIcon || Qt.resolvedUrl("../../../assets/ambxst-icon.svg").toString().replace("file://", "")
    iconTint: Config.bar.launcherIconTint
    iconFullTint: Config.bar.launcherIconFullTint
    iconSize: Config.bar.launcherIconSize
    tooltipText: "Open Application Launcher"

    onToggle: function () {
        if (GlobalStates.launcherOpen) {
            GlobalStates.clearLauncherState();
            Visibilities.setActiveModule("");
        } else {
            GlobalStates.launcherCurrentTab = 0;
            Visibilities.setActiveModule("launcher");
        }
    }
}
