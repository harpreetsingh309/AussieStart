import Foundation

enum AustralianState: String, CaseIterable, Identifiable, Codable, Hashable {
    case vic, nsw, qld, sa, wa, tas, act, nt

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .vic: "Victoria"
        case .nsw: "New South Wales"
        case .qld: "Queensland"
        case .sa: "South Australia"
        case .wa: "Western Australia"
        case .tas: "Tasmania"
        case .act: "Australian Capital Territory"
        case .nt: "Northern Territory"
        }
    }

    var localizationKey: String { "state.\(rawValue)" }

    func localizedName(for language: AppLanguage) -> String {
        L10n.tr(localizationKey, language: language, fallback: displayName)
    }

    var shortName: String {
        switch self {
        case .vic: "VIC"
        case .nsw: "NSW"
        case .qld: "QLD"
        case .sa: "SA"
        case .wa: "WA"
        case .tas: "TAS"
        case .act: "ACT"
        case .nt: "NT"
        }
    }

    var transportCardName: String {
        switch self {
        case .vic: "Myki"
        case .nsw: "Opal"
        case .qld: "go card"
        case .sa: "metroCARD"
        case .wa: "SmartRider"
        case .tas: "Greencard"
        case .act: "MyWay+"
        case .nt: "Tap and Go"
        }
    }
}

enum AppLanguage: String, CaseIterable, Identifiable, Codable {
    case english = "en"
    case hindi = "hi"
    case punjabi = "pa"
    case gujarati = "gu"
    case tamil = "ta"
    case telugu = "te"
    case malayalam = "ml"
    case kannada = "kn"
    case marathi = "mr"
    case bengali = "bn"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .english: "English"
        case .hindi: "हिन्दी (Hindi)"
        case .punjabi: "ਪੰਜਾਬੀ (Punjabi)"
        case .gujarati: "ગુજરાતી (Gujarati)"
        case .tamil: "தமிழ் (Tamil)"
        case .telugu: "తెలుగు (Telugu)"
        case .malayalam: "മലയാളം (Malayalam)"
        case .kannada: "ಕನ್ನಡ (Kannada)"
        case .marathi: "मराठी (Marathi)"
        case .bengali: "বাংলা (Bengali)"
        }
    }

    /// MVP ships English + Hindi + Punjabi UI strings.
    var isMVPReady: Bool {
        self == .english || self == .hindi || self == .punjabi
    }

    var locale: Locale { Locale(identifier: rawValue) }
}

enum UserPersona: String, CaseIterable, Identifiable, Codable {
    case student, worker, family, tourist, pr, citizen

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .student: "Student"
        case .worker: "Worker / Skilled migrant"
        case .family: "Family visa holder"
        case .tourist: "Tourist / Working holiday"
        case .pr: "Permanent resident"
        case .citizen: "Citizen"
        }
    }

    var localizationKey: String { "persona.\(rawValue)" }

    func localizedName(for language: AppLanguage) -> String {
        L10n.tr(localizationKey, language: language)
    }

    var symbolName: String {
        switch self {
        case .student: "graduationcap.fill"
        case .worker: "briefcase.fill"
        case .family: "figure.2.and.child.holdinghands"
        case .tourist: "airplane"
        case .pr: "checkmark.seal.fill"
        case .citizen: "flag.fill"
        }
    }
}

enum ContentCategory: String, CaseIterable, Identifiable, Codable, Hashable {
    case arrival, sim, banking, healthcare, transport, driving
    case taxes, housing, jobs, shopping, family, explore, emergency, students

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .arrival: "Arrival"
        case .sim: "SIM Cards"
        case .banking: "Banking"
        case .healthcare: "Healthcare"
        case .transport: "Transport"
        case .driving: "Driving"
        case .taxes: "Taxes"
        case .housing: "Housing"
        case .jobs: "Jobs"
        case .shopping: "Shopping"
        case .family: "Family"
        case .explore: "Explore"
        case .emergency: "Emergency"
        case .students: "Students"
        }
    }

    var localizationKey: String { "category.\(rawValue)" }

    func localizedName(for language: AppLanguage) -> String {
        L10n.tr(localizationKey, language: language)
    }

    var symbolName: String {
        switch self {
        case .arrival: "airplane.arrival"
        case .sim: "simcard.fill"
        case .banking: "building.columns.fill"
        case .healthcare: "cross.case.fill"
        case .transport: "tram.fill"
        case .driving: "car.fill"
        case .taxes: "doc.text.fill"
        case .housing: "house.fill"
        case .jobs: "briefcase.fill"
        case .shopping: "cart.fill"
        case .family: "figure.2.and.child.holdinghands"
        case .explore: "binoculars.fill"
        case .emergency: "exclamationmark.triangle.fill"
        case .students: "graduationcap.fill"
        }
    }

    var tintHex: String {
        switch self {
        case .arrival: "1B6CA8"
        case .sim: "0F766E"
        case .banking: "1D4ED8"
        case .healthcare: "DC2626"
        case .transport: "7C3AED"
        case .driving: "EA580C"
        case .taxes: "065F46"
        case .housing: "B45309"
        case .jobs: "0369A1"
        case .shopping: "BE185D"
        case .family: "9333EA"
        case .explore: "0E7490"
        case .emergency: "B91C1C"
        case .students: "4338CA"
        }
    }
}

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system, light, dark

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    var localizationKey: String { "settings.theme.\(rawValue)" }

    func localizedName(for language: AppLanguage) -> String {
        L10n.tr(localizationKey, language: language)
    }

    var hintKey: String { "settings.theme.hint.\(rawValue)" }
}
