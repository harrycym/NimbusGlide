import Foundation
import SwiftUI

enum GroqModel: String, CaseIterable, Identifiable {
    case llama33_70b = "llama-3.3-70b-versatile"
    case llama4_scout = "meta-llama/llama-4-scout-17b-16e-instruct"
    case kimi_k2 = "moonshotai/kimi-k2-instruct-0905"
    case qwen3_32b = "qwen/qwen3-32b"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .llama33_70b:  return "Llama 3.3 70B"
        case .llama4_scout: return "Llama 4 Scout"
        case .kimi_k2:      return "Kimi K2"
        case .qwen3_32b:    return "Qwen 3 32B"
        }
    }
}

class SettingsManager: ObservableObject {
    private static let llmModelKey       = "flowx_llm_model"
    private static let hotkeyKey         = "flowx_hotkey"
    private static let customKeyCodeKey  = "flowx_custom_key_code"
    private static let customKeyLabelKey = "flowx_custom_key_label"
    private static let autoCopyKey       = "flowx_auto_copy"

    /// Bundled API key loaded from Secrets.plist — never shown to users
    let apiKey: String?

    @Published var llmModel: String {
        didSet { UserDefaults.standard.set(llmModel, forKey: Self.llmModelKey) }
    }

    @Published var hotkey: HotkeyChoice {
        didSet { UserDefaults.standard.set(hotkey.rawValue, forKey: Self.hotkeyKey) }
    }

    /// Raw key code for the custom hotkey (only used when hotkey == .custom)
    @Published var customKeyCode: UInt16 {
        didSet { UserDefaults.standard.set(Int(customKeyCode), forKey: Self.customKeyCodeKey) }
    }

    /// Human-readable label for the custom key (e.g. "F5", "A")
    @Published var customKeyLabel: String {
        didSet { UserDefaults.standard.set(customKeyLabel, forKey: Self.customKeyLabelKey) }
    }

    /// Auto-copy processed text to clipboard
    @Published var autoCopyToClipboard: Bool {
        didSet { UserDefaults.standard.set(autoCopyToClipboard, forKey: Self.autoCopyKey) }
    }

    init() {
        // Load API key from bundled Secrets.plist
        if let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
           let data = try? Data(contentsOf: url),
           let dict = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
           let key = dict["GroqAPIKey"] as? String, !key.isEmpty {
            self.apiKey = key
        } else {
            self.apiKey = UserDefaults.standard.string(forKey: "flowx_groq_api_key")
        }

        let savedModel = UserDefaults.standard.string(forKey: Self.llmModelKey) ?? ""
        if savedModel == "llama-3.1-8b-instant" || savedModel.isEmpty {
            self.llmModel = GroqModel.llama33_70b.rawValue
        } else {
            self.llmModel = savedModel
        }

        if let saved = UserDefaults.standard.string(forKey: Self.hotkeyKey),
           let choice = HotkeyChoice(rawValue: saved) {
            self.hotkey = choice
        } else {
            self.hotkey = .rightOption
        }

        self.customKeyCode  = UInt16(UserDefaults.standard.integer(forKey: Self.customKeyCodeKey))
        self.customKeyLabel = UserDefaults.standard.string(forKey: Self.customKeyLabelKey) ?? "—"
        self.autoCopyToClipboard = UserDefaults.standard.object(forKey: Self.autoCopyKey) as? Bool ?? false
    }

    var hasValidAPIKey: Bool {
        guard let key = apiKey else { return false }
        return !key.isEmpty
    }
}
