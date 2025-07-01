import SwiftUI
import Feature
import CoreData
import AppIntents

@main
struct MainApp: App {
//    @UIApplicationDelegateAdaptor var delegate: AppDelegate
    let shared = PersistenceStorage.shared
    
    init() {
        // Register App Shortcuts Provider
        LapsShortcuts.updateAppShortcutParameters()
    }

    var body: some Scene {
        WindowGroup {
            ContentView(context: shared.container.viewContext)
                .environment(\.managedObjectContext, shared.container.viewContext)
                .onOpenURL { url in
                    handleURL(url)
                }
        }
    }
    
    private func handleURL(_ url: URL) {
        if url.scheme == "mylaps" && url.host == "start-running" {
            NotificationCenter.default.post(name: .startRunningFromSiri, object: nil)
        }
    }
}
