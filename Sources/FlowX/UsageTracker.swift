import Foundation
import SwiftUI

class UsageTracker: ObservableObject {
    private static let wordCountKey = "flowx_total_word_count"
    private static let isPaidKey = "flowx_is_paid"

    static let freeWordLimit = 2_000

    @Published var totalWordsUsed: Int {
        didSet { UserDefaults.standard.set(totalWordsUsed, forKey: Self.wordCountKey) }
    }

    @Published var isPaid: Bool {
        didSet { UserDefaults.standard.set(isPaid, forKey: Self.isPaidKey) }
    }

    init() {
        self.totalWordsUsed = UserDefaults.standard.integer(forKey: Self.wordCountKey)
        self.isPaid = UserDefaults.standard.bool(forKey: Self.isPaidKey)
    }

    var wordsRemaining: Int {
        max(0, Self.freeWordLimit - totalWordsUsed)
    }

    var usageRatio: Double {
        min(1.0, Double(totalWordsUsed) / Double(Self.freeWordLimit))
    }

    var hasReachedLimit: Bool {
        !isPaid && totalWordsUsed >= Self.freeWordLimit
    }

    func recordWords(_ text: String) {
        let count = text.split(separator: " ").count
        DispatchQueue.main.async {
            self.totalWordsUsed += count
        }
    }
}
