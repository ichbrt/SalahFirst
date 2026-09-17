import Foundation

/// A place the user can pick instead of sharing their location.
public struct City: Identifiable, Hashable, Sendable {
    public let name: String
    public let country: String
    public let latitude: Double
    public let longitude: Double

    public var id: String { "\(country)/\(name)" }
    public var displayName: String { "\(name), \(country)" }

    public var location: PrayerLocation {
        PrayerLocation(latitude: latitude, longitude: longitude, name: name, isAutomatic: false)
    }
}

/// Cities bundled with the app, so choosing a place works with no network and
/// no lookup service — which is the point: a reverse-geocoding call would send
/// the user's coordinates to a third party.
///
/// Coordinates are city centres to two decimal places, roughly a kilometre.
/// Prayer times move by about four seconds per kilometre of longitude, so that
/// is well inside the rounding of the published times themselves.
///
/// To add a city, add a line below and keep the list sorted within its country.
public enum CityDirectory {

    public static let all: [City] = [
        City(name: "Adana", country: "Türkiye", latitude: 37.00, longitude: 35.32),
        City(name: "Adıyaman", country: "Türkiye", latitude: 37.76, longitude: 38.28),
        City(name: "Afyonkarahisar", country: "Türkiye", latitude: 38.76, longitude: 30.54),
        City(name: "Ağrı", country: "Türkiye", latitude: 39.72, longitude: 43.05),
        City(name: "Aksaray", country: "Türkiye", latitude: 38.37, longitude: 34.03),
        City(name: "Amasya", country: "Türkiye", latitude: 40.65, longitude: 35.83),
        City(name: "Ankara", country: "Türkiye", latitude: 39.93, longitude: 32.86),
        City(name: "Antalya", country: "Türkiye", latitude: 36.88, longitude: 30.70),
        City(name: "Ardahan", country: "Türkiye", latitude: 41.11, longitude: 42.70),
        City(name: "Artvin", country: "Türkiye", latitude: 41.18, longitude: 41.82),
        City(name: "Aydın", country: "Türkiye", latitude: 37.85, longitude: 27.84),
        City(name: "Balıkesir", country: "Türkiye", latitude: 39.65, longitude: 27.88),
        City(name: "Bartın", country: "Türkiye", latitude: 41.64, longitude: 32.34),
        City(name: "Batman", country: "Türkiye", latitude: 37.88, longitude: 41.13),
        City(name: "Bayburt", country: "Türkiye", latitude: 40.26, longitude: 40.23),
        City(name: "Bilecik", country: "Türkiye", latitude: 40.14, longitude: 29.98),
        City(name: "Bingöl", country: "Türkiye", latitude: 38.88, longitude: 40.50),
        City(name: "Bitlis", country: "Türkiye", latitude: 38.40, longitude: 42.11),
        City(name: "Bolu", country: "Türkiye", latitude: 40.74, longitude: 31.61),
        City(name: "Burdur", country: "Türkiye", latitude: 37.72, longitude: 30.29),
        City(name: "Bursa", country: "Türkiye", latitude: 40.18, longitude: 29.07),
        City(name: "Çanakkale", country: "Türkiye", latitude: 40.15, longitude: 26.41),
        City(name: "Çankırı", country: "Türkiye", latitude: 40.60, longitude: 33.62),
        City(name: "Çorum", country: "Türkiye", latitude: 40.55, longitude: 34.95),
        City(name: "Denizli", country: "Türkiye", latitude: 37.78, longitude: 29.09),
        City(name: "Diyarbakır", country: "Türkiye", latitude: 37.91, longitude: 40.24),
        City(name: "Düzce", country: "Türkiye", latitude: 40.84, longitude: 31.16),
        City(name: "Edirne", country: "Türkiye", latitude: 41.68, longitude: 26.56),
        City(name: "Elazığ", country: "Türkiye", latitude: 38.68, longitude: 39.22),
        City(name: "Erzincan", country: "Türkiye", latitude: 39.75, longitude: 39.49),
        City(name: "Erzurum", country: "Türkiye", latitude: 39.90, longitude: 41.27),
        City(name: "Eskişehir", country: "Türkiye", latitude: 39.78, longitude: 30.52),
        City(name: "Gaziantep", country: "Türkiye", latitude: 37.07, longitude: 37.38),
        City(name: "Giresun", country: "Türkiye", latitude: 40.91, longitude: 38.39),
        City(name: "Gümüşhane", country: "Türkiye", latitude: 40.46, longitude: 39.48),
        City(name: "Hakkâri", country: "Türkiye", latitude: 37.58, longitude: 43.74),
        City(name: "Hatay", country: "Türkiye", latitude: 36.20, longitude: 36.16),
        City(name: "Iğdır", country: "Türkiye", latitude: 39.92, longitude: 44.04),
        City(name: "Isparta", country: "Türkiye", latitude: 37.76, longitude: 30.55),
        City(name: "İstanbul", country: "Türkiye", latitude: 41.01, longitude: 28.98),
        City(name: "İzmir", country: "Türkiye", latitude: 38.42, longitude: 27.14),
        City(name: "Kahramanmaraş", country: "Türkiye", latitude: 37.58, longitude: 36.93),
        City(name: "Karabük", country: "Türkiye", latitude: 41.20, longitude: 32.63),
        City(name: "Karaman", country: "Türkiye", latitude: 37.18, longitude: 33.22),
        City(name: "Kars", country: "Türkiye", latitude: 40.60, longitude: 43.10),
        City(name: "Kastamonu", country: "Türkiye", latitude: 41.38, longitude: 33.78),
        City(name: "Kayseri", country: "Türkiye", latitude: 38.73, longitude: 35.49),
        City(name: "Kırıkkale", country: "Türkiye", latitude: 39.85, longitude: 33.52),
        City(name: "Kırklareli", country: "Türkiye", latitude: 41.74, longitude: 27.22),
        City(name: "Kırşehir", country: "Türkiye", latitude: 39.15, longitude: 34.16),
        City(name: "Kilis", country: "Türkiye", latitude: 36.72, longitude: 37.12),
        City(name: "Kocaeli", country: "Türkiye", latitude: 40.77, longitude: 29.95),
        City(name: "Konya", country: "Türkiye", latitude: 37.87, longitude: 32.48),
        City(name: "Kütahya", country: "Türkiye", latitude: 39.42, longitude: 29.98),
        City(name: "Malatya", country: "Türkiye", latitude: 38.35, longitude: 38.31),
        City(name: "Manisa", country: "Türkiye", latitude: 38.61, longitude: 27.43),
        City(name: "Mardin", country: "Türkiye", latitude: 37.31, longitude: 40.74),
        City(name: "Mersin", country: "Türkiye", latitude: 36.80, longitude: 34.63),
        City(name: "Muğla", country: "Türkiye", latitude: 37.22, longitude: 28.36),
        City(name: "Muş", country: "Türkiye", latitude: 38.73, longitude: 41.49),
        City(name: "Nevşehir", country: "Türkiye", latitude: 38.62, longitude: 34.71),
        City(name: "Niğde", country: "Türkiye", latitude: 37.97, longitude: 34.68),
        City(name: "Ordu", country: "Türkiye", latitude: 40.98, longitude: 37.88),
        City(name: "Osmaniye", country: "Türkiye", latitude: 37.07, longitude: 36.25),
        City(name: "Rize", country: "Türkiye", latitude: 41.02, longitude: 40.52),
        City(name: "Sakarya", country: "Türkiye", latitude: 40.78, longitude: 30.40),
        City(name: "Samsun", country: "Türkiye", latitude: 41.29, longitude: 36.33),
        City(name: "Siirt", country: "Türkiye", latitude: 37.93, longitude: 41.94),
        City(name: "Sinop", country: "Türkiye", latitude: 42.03, longitude: 35.15),
        City(name: "Sivas", country: "Türkiye", latitude: 39.75, longitude: 37.02),
        City(name: "Şanlıurfa", country: "Türkiye", latitude: 37.16, longitude: 38.79),
        City(name: "Şırnak", country: "Türkiye", latitude: 37.52, longitude: 42.46),
        City(name: "Tekirdağ", country: "Türkiye", latitude: 40.98, longitude: 27.51),
        City(name: "Tokat", country: "Türkiye", latitude: 40.31, longitude: 36.55),
        City(name: "Trabzon", country: "Türkiye", latitude: 41.00, longitude: 39.72),
        City(name: "Tunceli", country: "Türkiye", latitude: 39.11, longitude: 39.55),
        City(name: "Uşak", country: "Türkiye", latitude: 38.68, longitude: 29.41),
        City(name: "Van", country: "Türkiye", latitude: 38.49, longitude: 43.38),
        City(name: "Yalova", country: "Türkiye", latitude: 40.65, longitude: 29.27),
        City(name: "Yozgat", country: "Türkiye", latitude: 39.82, longitude: 34.81),
        City(name: "Zonguldak", country: "Türkiye", latitude: 41.46, longitude: 31.79),
        City(name: "Mecca", country: "Saudi Arabia", latitude: 21.42, longitude: 39.83),
        City(name: "Medina", country: "Saudi Arabia", latitude: 24.47, longitude: 39.61),
        City(name: "Riyadh", country: "Saudi Arabia", latitude: 24.71, longitude: 46.68),
        City(name: "Jeddah", country: "Saudi Arabia", latitude: 21.49, longitude: 39.19),
        City(name: "Jerusalem", country: "Palestine", latitude: 31.78, longitude: 35.22),
        City(name: "Cairo", country: "Egypt", latitude: 30.04, longitude: 31.24),
        City(name: "Alexandria", country: "Egypt", latitude: 31.20, longitude: 29.92),
        City(name: "Amman", country: "Jordan", latitude: 31.95, longitude: 35.93),
        City(name: "Beirut", country: "Lebanon", latitude: 33.89, longitude: 35.50),
        City(name: "Damascus", country: "Syria", latitude: 33.51, longitude: 36.29),
        City(name: "Baghdad", country: "Iraq", latitude: 33.31, longitude: 44.36),
        City(name: "Erbil", country: "Iraq", latitude: 36.19, longitude: 44.01),
        City(name: "Tehran", country: "Iran", latitude: 35.69, longitude: 51.39),
        City(name: "Dubai", country: "United Arab Emirates", latitude: 25.20, longitude: 55.27),
        City(name: "Abu Dhabi", country: "United Arab Emirates", latitude: 24.45, longitude: 54.38),
        City(name: "Doha", country: "Qatar", latitude: 25.29, longitude: 51.53),
        City(name: "Kuwait City", country: "Kuwait", latitude: 29.38, longitude: 47.99),
        City(name: "Manama", country: "Bahrain", latitude: 26.23, longitude: 50.59),
        City(name: "Muscat", country: "Oman", latitude: 23.59, longitude: 58.41),
        City(name: "Sanaa", country: "Yemen", latitude: 15.37, longitude: 44.19),
        City(name: "London", country: "United Kingdom", latitude: 51.51, longitude: -0.13),
        City(name: "Birmingham", country: "United Kingdom", latitude: 52.49, longitude: -1.89),
        City(name: "Manchester", country: "United Kingdom", latitude: 53.48, longitude: -2.24),
        City(name: "Berlin", country: "Germany", latitude: 52.52, longitude: 13.41),
        City(name: "Hamburg", country: "Germany", latitude: 53.55, longitude: 9.99),
        City(name: "Munich", country: "Germany", latitude: 48.14, longitude: 11.58),
        City(name: "Cologne", country: "Germany", latitude: 50.94, longitude: 6.96),
        City(name: "Frankfurt", country: "Germany", latitude: 50.11, longitude: 8.68),
        City(name: "Stuttgart", country: "Germany", latitude: 48.78, longitude: 9.18),
        City(name: "Düsseldorf", country: "Germany", latitude: 51.23, longitude: 6.78),
        City(name: "Paris", country: "France", latitude: 48.86, longitude: 2.35),
        City(name: "Marseille", country: "France", latitude: 43.30, longitude: 5.37),
        City(name: "Lyon", country: "France", latitude: 45.76, longitude: 4.84),
        City(name: "Amsterdam", country: "Netherlands", latitude: 52.37, longitude: 4.90),
        City(name: "Rotterdam", country: "Netherlands", latitude: 51.92, longitude: 4.48),
        City(name: "Brussels", country: "Belgium", latitude: 50.85, longitude: 4.35),
        City(name: "Vienna", country: "Austria", latitude: 48.21, longitude: 16.37),
        City(name: "Zurich", country: "Switzerland", latitude: 47.38, longitude: 8.54),
        City(name: "Stockholm", country: "Sweden", latitude: 59.33, longitude: 18.07),
        City(name: "Gothenburg", country: "Sweden", latitude: 57.71, longitude: 11.97),
        City(name: "Oslo", country: "Norway", latitude: 59.91, longitude: 10.75),
        City(name: "Copenhagen", country: "Denmark", latitude: 55.68, longitude: 12.57),
        City(name: "Helsinki", country: "Finland", latitude: 60.17, longitude: 24.94),
        City(name: "Madrid", country: "Spain", latitude: 40.42, longitude: -3.70),
        City(name: "Barcelona", country: "Spain", latitude: 41.39, longitude: 2.17),
        City(name: "Rome", country: "Italy", latitude: 41.90, longitude: 12.50),
        City(name: "Milan", country: "Italy", latitude: 45.46, longitude: 9.19),
        City(name: "Athens", country: "Greece", latitude: 37.98, longitude: 23.73),
        City(name: "Sofia", country: "Bulgaria", latitude: 42.70, longitude: 23.32),
        City(name: "Bucharest", country: "Romania", latitude: 44.43, longitude: 26.10),
        City(name: "Sarajevo", country: "Bosnia and Herzegovina", latitude: 43.86, longitude: 18.41),
        City(name: "Pristina", country: "Kosovo", latitude: 42.66, longitude: 21.17),
        City(name: "Skopje", country: "North Macedonia", latitude: 41.99, longitude: 21.43),
        City(name: "Tirana", country: "Albania", latitude: 41.33, longitude: 19.82),
        City(name: "Nicosia", country: "Cyprus", latitude: 35.19, longitude: 33.38),
        City(name: "Moscow", country: "Russia", latitude: 55.76, longitude: 37.62),
        City(name: "Kazan", country: "Russia", latitude: 55.79, longitude: 49.11),
        City(name: "Kyiv", country: "Ukraine", latitude: 50.45, longitude: 30.52),
        City(name: "Baku", country: "Azerbaijan", latitude: 40.41, longitude: 49.87),
        City(name: "Tbilisi", country: "Georgia", latitude: 41.72, longitude: 44.79),
        City(name: "Tashkent", country: "Uzbekistan", latitude: 41.30, longitude: 69.24),
        City(name: "Almaty", country: "Kazakhstan", latitude: 43.24, longitude: 76.89),
        City(name: "Astana", country: "Kazakhstan", latitude: 51.17, longitude: 71.45),
        City(name: "Bishkek", country: "Kyrgyzstan", latitude: 42.87, longitude: 74.60),
        City(name: "Dushanbe", country: "Tajikistan", latitude: 38.56, longitude: 68.79),
        City(name: "Kabul", country: "Afghanistan", latitude: 34.53, longitude: 69.17),
        City(name: "Karachi", country: "Pakistan", latitude: 24.86, longitude: 67.01),
        City(name: "Lahore", country: "Pakistan", latitude: 31.55, longitude: 74.34),
        City(name: "Islamabad", country: "Pakistan", latitude: 33.68, longitude: 73.05),
        City(name: "Peshawar", country: "Pakistan", latitude: 34.01, longitude: 71.58),
        City(name: "Delhi", country: "India", latitude: 28.61, longitude: 77.21),
        City(name: "Mumbai", country: "India", latitude: 19.08, longitude: 72.88),
        City(name: "Hyderabad", country: "India", latitude: 17.39, longitude: 78.49),
        City(name: "Kolkata", country: "India", latitude: 22.57, longitude: 88.36),
        City(name: "Dhaka", country: "Bangladesh", latitude: 23.81, longitude: 90.41),
        City(name: "Chittagong", country: "Bangladesh", latitude: 22.36, longitude: 91.78),
        City(name: "Colombo", country: "Sri Lanka", latitude: 6.93, longitude: 79.86),
        City(name: "Malé", country: "Maldives", latitude: 4.17, longitude: 73.51),
        City(name: "Kuala Lumpur", country: "Malaysia", latitude: 3.14, longitude: 101.69),
        City(name: "Singapore", country: "Singapore", latitude: 1.35, longitude: 103.82),
        City(name: "Jakarta", country: "Indonesia", latitude: -6.21, longitude: 106.85),
        City(name: "Surabaya", country: "Indonesia", latitude: -7.25, longitude: 112.75),
        City(name: "Bandung", country: "Indonesia", latitude: -6.92, longitude: 107.61),
        City(name: "Medan", country: "Indonesia", latitude: 3.59, longitude: 98.67),
        City(name: "Manila", country: "Philippines", latitude: 14.60, longitude: 120.98),
        City(name: "Bangkok", country: "Thailand", latitude: 13.76, longitude: 100.50),
        City(name: "Beijing", country: "China", latitude: 39.90, longitude: 116.41),
        City(name: "Ürümqi", country: "China", latitude: 43.83, longitude: 87.62),
        City(name: "Tokyo", country: "Japan", latitude: 35.68, longitude: 139.69),
        City(name: "Seoul", country: "South Korea", latitude: 37.57, longitude: 126.98),
        City(name: "New York", country: "United States", latitude: 40.71, longitude: -74.01),
        City(name: "Chicago", country: "United States", latitude: 41.88, longitude: -87.63),
        City(name: "Los Angeles", country: "United States", latitude: 34.05, longitude: -118.24),
        City(name: "Houston", country: "United States", latitude: 29.76, longitude: -95.37),
        City(name: "Detroit", country: "United States", latitude: 42.33, longitude: -83.05),
        City(name: "Washington", country: "United States", latitude: 38.91, longitude: -77.04),
        City(name: "Minneapolis", country: "United States", latitude: 44.98, longitude: -93.27),
        City(name: "Toronto", country: "Canada", latitude: 43.65, longitude: -79.38),
        City(name: "Montreal", country: "Canada", latitude: 45.50, longitude: -73.57),
        City(name: "Vancouver", country: "Canada", latitude: 49.28, longitude: -123.12),
        City(name: "Casablanca", country: "Morocco", latitude: 33.57, longitude: -7.59),
        City(name: "Rabat", country: "Morocco", latitude: 34.02, longitude: -6.84),
        City(name: "Algiers", country: "Algeria", latitude: 36.75, longitude: 3.06),
        City(name: "Tunis", country: "Tunisia", latitude: 36.81, longitude: 10.18),
        City(name: "Tripoli", country: "Libya", latitude: 32.89, longitude: 13.19),
        City(name: "Khartoum", country: "Sudan", latitude: 15.50, longitude: 32.56),
        City(name: "Lagos", country: "Nigeria", latitude: 6.52, longitude: 3.38),
        City(name: "Kano", country: "Nigeria", latitude: 12.00, longitude: 8.52),
        City(name: "Abuja", country: "Nigeria", latitude: 9.06, longitude: 7.49),
        City(name: "Dakar", country: "Senegal", latitude: 14.72, longitude: -17.47),
        City(name: "Bamako", country: "Mali", latitude: 12.65, longitude: -8.00),
        City(name: "Nairobi", country: "Kenya", latitude: -1.29, longitude: 36.82),
        City(name: "Mogadishu", country: "Somalia", latitude: 2.05, longitude: 45.32),
        City(name: "Addis Ababa", country: "Ethiopia", latitude: 9.01, longitude: 38.76),
        City(name: "Johannesburg", country: "South Africa", latitude: -26.20, longitude: 28.05),
        City(name: "Cape Town", country: "South Africa", latitude: -33.92, longitude: 18.42),
        City(name: "Sydney", country: "Australia", latitude: -33.87, longitude: 151.21),
        City(name: "Melbourne", country: "Australia", latitude: -37.81, longitude: 144.96),
        City(name: "Auckland", country: "New Zealand", latitude: -36.85, longitude: 174.76),
    ]

    /// Diacritic- and case-insensitive search.
    ///
    /// Folding matters more than usual here: a Turkish user typing "sanliurfa"
    /// on an English keyboard should still find "Şanlıurfa", and "istanbul"
    /// should match "İstanbul" despite the dotted capital.
    public static func search(_ query: String) -> [City] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return all }
        let needle = fold(trimmed)
        return all.filter { fold($0.name).contains(needle) || fold($0.country).contains(needle) }
    }

    private static func fold(_ value: String) -> String {
        // Unicode does not consider "ı" (U+0131) a decorated "i", so diacritic
        // folding leaves it alone and "sanliurfa" would never reach "Şanlıurfa".
        // Mapping it explicitly is what makes the list usable from a keyboard
        // without Turkish letters.
        value
            .replacingOccurrences(of: "ı", with: "i")
            .replacingOccurrences(of: "İ", with: "i")
            .folding(options: [.diacriticInsensitive, .caseInsensitive],
                     locale: Locale(identifier: "en_US_POSIX"))
    }
}
