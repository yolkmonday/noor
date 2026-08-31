import Foundation

struct AzanOption: Identifiable {
    let id: String
    let name: String
    let description: String

    static let all: [AzanOption] = [
        AzanOption(
            id: "silent",
            name: "Tanpa Suara",
            description: "Notifikasi saja"
        ),
        AzanOption(
            id: "azan_makkah",
            name: "Masjidil Haram",
            description: "Makkah, Saudi Arabia"
        ),
        AzanOption(
            id: "azan_mishary",
            name: "Mishary Alafasi",
            description: "Kuwait"
        ),
        AzanOption(
            id: "azan_abdul_basit",
            name: "Abdul Basit",
            description: "Egypt"
        ),
        AzanOption(
            id: "azan_ahmad_nafees",
            name: "Ahmad Nafees",
            description: "Pakistan"
        ),
        AzanOption(
            id: "azan_subuh",
            name: "Azan Subuh",
            description: "Dengan lafaz Ash-Shalatu Khairun Minan Naum"
        ),
        AzanOption(
            id: "azan_malaysia",
            name: "Malaysia",
            description: "Gaya Malaysia"
        ),
        AzanOption(
            id: "azan_turkey",
            name: "Turkey",
            description: "Gaya Turki"
        ),
        AzanOption(
            id: "azan_pakistan",
            name: "Pakistan",
            description: "Gaya Pakistan"
        ),
        AzanOption(
            id: "azan_bosnia",
            name: "Bosnia",
            description: "Gaya Bosnia"
        ),
        AzanOption(
            id: "azan_egypt",
            name: "Egypt",
            description: "Gaya Mesir"
        )
    ]

    var isSilent: Bool {
        id == "silent"
    }
}
