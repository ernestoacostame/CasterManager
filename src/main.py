import sys
import os
import signal
import logging

from PyQt6.QtGui import QGuiApplication, QIcon, QColor, QPalette
from PyQt6.QtQml import QQmlApplicationEngine
from PyQt6.QtCore import QUrl, Qt

# Allow Ctrl+C to terminate cleanly
signal.signal(signal.SIGINT, signal.SIG_DFL)

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s"
)

def main():
    app_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.dirname(app_dir)
    sys.path.insert(0, project_root)

    from src.backend.state_manager import StateManager

    app = QGuiApplication(sys.argv)
    app.setApplicationName("CasterManager")
    app.setOrganizationName("CasterManager")
    app.setOrganizationDomain("elav.castermanager")

    # Dark palette matching RØDE hardware aesthetic
    palette = QPalette()
    palette.setColor(QPalette.ColorRole.Window, QColor("#141414"))
    palette.setColor(QPalette.ColorRole.WindowText, QColor("#E0E0E0"))
    palette.setColor(QPalette.ColorRole.Base, QColor("#1D1D1D"))
    palette.setColor(QPalette.ColorRole.AlternateBase, QColor("#262626"))
    palette.setColor(QPalette.ColorRole.ToolTipBase, QColor("#2A2A2A"))
    palette.setColor(QPalette.ColorRole.ToolTipText, QColor("#E0E0E0"))
    palette.setColor(QPalette.ColorRole.Text, QColor("#E0E0E0"))
    palette.setColor(QPalette.ColorRole.Button, QColor("#222222"))
    palette.setColor(QPalette.ColorRole.ButtonText, QColor("#E0E0E0"))
    palette.setColor(QPalette.ColorRole.Highlight, QColor("#CBA158"))  # RØDE gold
    palette.setColor(QPalette.ColorRole.HighlightedText, QColor("#000000"))
    app.setPalette(palette)

    # Initialize backend state manager
    state_manager = StateManager()
    app.aboutToQuit.connect(state_manager.monitor.stop)

    engine = QQmlApplicationEngine()
    engine.rootContext().setContextProperty("stateManager", state_manager)

    qml_file = os.path.join(app_dir, "qml", "Main.qml")
    engine.load(QUrl.fromLocalFile(qml_file))

    if not engine.rootObjects():
        logging.error("Failed to load QML root object!")
        sys.exit(-1)

    sys.exit(app.exec())

if __name__ == "__main__":
    main()

