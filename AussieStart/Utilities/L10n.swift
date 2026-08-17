import Foundation

enum L10n {
    static func tr(_ key: String, language: AppLanguage, _ args: CVarArg...) -> String {
        let primary = bundle(for: language).localizedString(forKey: key, value: key, table: nil)
        let format: String
        if primary == key, language != .english {
            format = bundle(for: .english).localizedString(forKey: key, value: key, table: nil)
        } else {
            format = primary
        }
        guard !args.isEmpty else { return format }
        return String(format: format, locale: Locale(identifier: language.rawValue), arguments: args)
    }

    /// Returns `fallback` when the key is missing from both the selected and English tables.
    static func tr(_ key: String, language: AppLanguage, fallback: String, _ args: CVarArg...) -> String {
        let primary = bundle(for: language).localizedString(forKey: key, value: key, table: nil)
        let format: String
        if primary != key {
            format = primary
        } else if language != .english {
            let english = bundle(for: .english).localizedString(forKey: key, value: key, table: nil)
            format = english == key ? fallback : english
        } else {
            format = fallback
        }
        guard !args.isEmpty else { return format }
        return String(format: format, locale: Locale(identifier: language.rawValue), arguments: args)
    }

    static func bundle(for language: AppLanguage) -> Bundle {
        if let path = Bundle.main.path(forResource: language.rawValue, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return bundle
        }
        if let path = Bundle.main.path(forResource: "en", ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return bundle
        }
        return .main
    }
}

extension UserPreferences {
    func t(_ key: String) -> String {
        L10n.tr(key, language: language)
    }

    func t(_ key: String, _ arg: CVarArg) -> String {
        L10n.tr(key, language: language, arg)
    }

    func t(_ key: String, _ a: CVarArg, _ b: CVarArg) -> String {
        L10n.tr(key, language: language, a, b)
    }
}
