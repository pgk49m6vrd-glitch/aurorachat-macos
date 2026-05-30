import Foundation
import Observation

// manages the current theme + persists to UserDefaults

@Observable
@MainActor
final class ThemeManager {
    private static let storageKey = "selectedTheme"

    var currentTheme: AppTheme {
        didSet {
            UserDefaults.standard.set(currentTheme.rawValue, forKey: Self.storageKey)
        }
    }

    var availableThemes: [AppTheme] {
        AppTheme.allCases.filter { $0.isAvailable }
    }

    var colors: ThemeColors {
        currentTheme.colors
    }

    var isLiquidGlass: Bool {
        currentTheme == .liquidGlass
    }

    var isAqua: Bool {
        currentTheme == .aqua
    }
    // pick the best theme for this mac on first launch
    init() {
        if let saved = UserDefaults.standard.string(forKey: Self.storageKey),
           let theme = AppTheme(rawValue: saved),
           theme.isAvailable {
            self.currentTheme = theme
        } else {
            self.currentTheme = AppTheme.bestAvailable
        }
    }

    func selectTheme(_ theme: AppTheme) {
        guard theme.isAvailable else { return }
        currentTheme = theme
    }
}
