import Foundation
import CoreSpotlight
import UIKit

@MainActor
enum SpotlightManager {

    private static func identifier(for bookId: UUID) -> String {
        "com.alperenacar.inkread.book.\(bookId.uuidString)"
    }

    static func indexBook(_ book: Book) {
        let attributes = CSSearchableItemAttributeSet(contentType: .text)
        attributes.title              = book.title
        attributes.contentDescription = book.author
        attributes.thumbnailData      = book.coverImageData

        let item = CSSearchableItem(
            uniqueIdentifier: identifier(for: book.id),
            domainIdentifier: "com.alperenacar.inkread",
            attributeSet: attributes
        )
        item.expirationDate = .distantFuture

        CSSearchableIndex.default().indexSearchableItems([item]) { _ in }
    }

    static func deindexBook(bookId: UUID) {
        CSSearchableIndex.default().deleteSearchableItems(
            withIdentifiers: [identifier(for: bookId)]
        ) { _ in }
    }

    static func indexAll(_ books: [Book]) {
        let items = books.map { book -> CSSearchableItem in
            let attributes = CSSearchableItemAttributeSet(contentType: .text)
            attributes.title              = book.title
            attributes.contentDescription = book.author
            attributes.thumbnailData      = book.coverImageData
            return CSSearchableItem(
                uniqueIdentifier: identifier(for: book.id),
                domainIdentifier: "com.alperenacar.inkread",
                attributeSet: attributes
            )
        }
        CSSearchableIndex.default().indexSearchableItems(items) { _ in }
    }

    static func deindexAll() {
        CSSearchableIndex.default().deleteAllSearchableItems { _ in }
    }

    // Returns bookId UUID if the activity is an Inkread Spotlight result
    static func bookId(from activity: NSUserActivity) -> UUID? {
        guard activity.activityType == CSSearchableItemActionType,
              let id = activity.userInfo?[CSSearchableItemActivityIdentifier] as? String,
              id.hasPrefix("com.alperenacar.inkread.book.") else { return nil }
        let uuidString = String(id.dropFirst("com.alperenacar.inkread.book.".count))
        return UUID(uuidString: uuidString)
    }
}
