import Foundation

extension Bundle {
    func urlForContent(named name: String, ext: String) -> URL? {
        url(forResource: name, withExtension: ext)
            ?? url(forResource: name, withExtension: ext, subdirectory: "Content")
            ?? url(forResource: name, withExtension: ext, subdirectory: "articles")
    }
}

extension Date {
    static var startOfToday: Date {
        Calendar.current.startOfDay(for: .now)
    }
}
