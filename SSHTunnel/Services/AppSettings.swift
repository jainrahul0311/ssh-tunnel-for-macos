import Foundation
import ServiceManagement

@Observable
final class AppSettings {
    var launchAtLogin: Bool {
        didSet { updateLaunchAtLogin() }
    }
    var openManagerOnLaunch: Bool {
        didSet { UserDefaults.standard.set(openManagerOnLaunch, forKey: "openManagerOnLaunch") }
    }

    init() {
        self.openManagerOnLaunch = UserDefaults.standard.bool(forKey: "openManagerOnLaunch")
        self.launchAtLogin = SMAppService.mainApp.status == .enabled
    }

    private func updateLaunchAtLogin() {
        do {
            if launchAtLogin {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Failed to update launch at login: \(error)")
            // Revert on failure
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }
}
