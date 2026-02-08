import Foundation

struct AzanOption: Identifiable {
    let id: String
    let name: String
    let description: String
    let downloadURL: String
    let fileSize: String  // Display size like "2.1 MB"

    static let all: [AzanOption] = [
        AzanOption(
            id: "silent",
            name: "Tanpa Suara",
            description: "Notifikasi saja",
            downloadURL: "",
            fileSize: "-"
        ),
        AzanOption(
            id: "azan_makkah",
            name: "Masjidil Haram",
            description: "Makkah, Saudi Arabia",
            downloadURL: "https://raw.githubusercontent.com/abodehq/Athan-MP3/master/Sounds/Athan%20Makkah.mp3",
            fileSize: "~2 MB"
        ),
        AzanOption(
            id: "azan_mishary",
            name: "Mishary Alafasi",
            description: "Kuwait",
            downloadURL: "https://raw.githubusercontent.com/abodehq/Athan-MP3/master/Sounds/Athan%20Mishary%20Alafasi.mp3",
            fileSize: "~2 MB"
        ),
        AzanOption(
            id: "azan_nasser",
            name: "Nasser Alqatami",
            description: "Saudi Arabia",
            downloadURL: "https://raw.githubusercontent.com/abodehq/Athan-MP3/master/Sounds/Athan%20Nasser%20Alqatami.mp3",
            fileSize: "~2 MB"
        ),
        AzanOption(
            id: "azan_mansoor",
            name: "Mansoor Az-Zahrani",
            description: "Saudi Arabia",
            downloadURL: "https://raw.githubusercontent.com/abodehq/Athan-MP3/master/Sounds/Athan%20Mansoor%20Az-Zahrani.mp3",
            fileSize: "~2 MB"
        )
    ]

    var isSilent: Bool {
        id == "silent"
    }
}
