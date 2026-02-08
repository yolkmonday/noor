import Foundation
import CoreData

// MARK: - PrayerLog Entity
@objc(PrayerLog)
public class PrayerLog: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID
    @NSManaged public var date: Date
    @NSManaged public var prayerType: String
    @NSManaged public var completed: Bool
    @NSManaged public var completedAt: Date?
}

extension PrayerLog {
    static func entityDescription() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "PrayerLog"
        entity.managedObjectClassName = "PrayerLog"

        let idAttr = NSAttributeDescription()
        idAttr.name = "id"
        idAttr.attributeType = .UUIDAttributeType
        idAttr.isOptional = false

        let dateAttr = NSAttributeDescription()
        dateAttr.name = "date"
        dateAttr.attributeType = .dateAttributeType
        dateAttr.isOptional = false

        let prayerTypeAttr = NSAttributeDescription()
        prayerTypeAttr.name = "prayerType"
        prayerTypeAttr.attributeType = .stringAttributeType
        prayerTypeAttr.isOptional = false

        let completedAttr = NSAttributeDescription()
        completedAttr.name = "completed"
        completedAttr.attributeType = .booleanAttributeType
        completedAttr.isOptional = false
        completedAttr.defaultValue = false

        let completedAtAttr = NSAttributeDescription()
        completedAtAttr.name = "completedAt"
        completedAtAttr.attributeType = .dateAttributeType
        completedAtAttr.isOptional = true

        entity.properties = [idAttr, dateAttr, prayerTypeAttr, completedAttr, completedAtAttr]

        return entity
    }
}

// MARK: - AzanAudio Entity
@objc(AzanAudio)
public class AzanAudio: NSManagedObject, Identifiable {
    @NSManaged public var id: String
    @NSManaged public var name: String
    @NSManaged public var localPath: String
    @NSManaged public var downloadedAt: Date
}

extension AzanAudio {
    static func entityDescription() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "AzanAudio"
        entity.managedObjectClassName = "AzanAudio"

        let idAttr = NSAttributeDescription()
        idAttr.name = "id"
        idAttr.attributeType = .stringAttributeType
        idAttr.isOptional = false

        let nameAttr = NSAttributeDescription()
        nameAttr.name = "name"
        nameAttr.attributeType = .stringAttributeType
        nameAttr.isOptional = false

        let localPathAttr = NSAttributeDescription()
        localPathAttr.name = "localPath"
        localPathAttr.attributeType = .stringAttributeType
        localPathAttr.isOptional = false

        let downloadedAtAttr = NSAttributeDescription()
        downloadedAtAttr.name = "downloadedAt"
        downloadedAtAttr.attributeType = .dateAttributeType
        downloadedAtAttr.isOptional = false

        entity.properties = [idAttr, nameAttr, localPathAttr, downloadedAtAttr]

        return entity
    }
}

// MARK: - Prayer Types
enum PrayerType: String, CaseIterable {
    // Wajib
    case fajr = "fajr"
    case dhuhr = "dhuhr"
    case asr = "asr"
    case maghrib = "maghrib"
    case isha = "isha"

    // Sunnah
    case tahajud = "tahajud"
    case dhuha = "dhuha"

    // Rawatib
    case rawatibFajrBefore = "rawatib_fajr_before"
    case rawatibDhuhrBefore = "rawatib_dhuhr_before"
    case rawatibDhuhrAfter = "rawatib_dhuhr_after"
    case rawatibAsrBefore = "rawatib_asr_before"
    case rawatibMaghribAfter = "rawatib_maghrib_after"
    case rawatibIshaAfter = "rawatib_isha_after"

    var displayName: String {
        switch self {
        case .fajr: return "Subuh"
        case .dhuhr: return "Dzuhur"
        case .asr: return "Ashar"
        case .maghrib: return "Maghrib"
        case .isha: return "Isya"
        case .tahajud: return "Tahajud"
        case .dhuha: return "Dhuha"
        case .rawatibFajrBefore: return "Qabliyah Subuh"
        case .rawatibDhuhrBefore: return "Qabliyah Dzuhur"
        case .rawatibDhuhrAfter: return "Ba'diyah Dzuhur"
        case .rawatibAsrBefore: return "Qabliyah Ashar"
        case .rawatibMaghribAfter: return "Ba'diyah Maghrib"
        case .rawatibIshaAfter: return "Ba'diyah Isya"
        }
    }

    var rakaatCount: Int {
        switch self {
        case .fajr: return 2
        case .dhuhr: return 4
        case .asr: return 4
        case .maghrib: return 3
        case .isha: return 4
        case .tahajud: return 2 // Minimal
        case .dhuha: return 2 // Minimal
        case .rawatibFajrBefore: return 2
        case .rawatibDhuhrBefore: return 4
        case .rawatibDhuhrAfter: return 2
        case .rawatibAsrBefore: return 4
        case .rawatibMaghribAfter: return 2
        case .rawatibIshaAfter: return 2
        }
    }

    var isWajib: Bool {
        switch self {
        case .fajr, .dhuhr, .asr, .maghrib, .isha:
            return true
        default:
            return false
        }
    }

    static var wajibPrayers: [PrayerType] {
        [.fajr, .dhuhr, .asr, .maghrib, .isha]
    }

    static var sunnahPrayers: [PrayerType] {
        [.tahajud, .dhuha]
    }

    static var rawatibPrayers: [PrayerType] {
        [.rawatibFajrBefore, .rawatibDhuhrBefore, .rawatibDhuhrAfter,
         .rawatibAsrBefore, .rawatibMaghribAfter, .rawatibIshaAfter]
    }
}
