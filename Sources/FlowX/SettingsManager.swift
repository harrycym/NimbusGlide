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
        case .llama33_70b:  return "Llama 3.3 70B — Smartest"
        case .llama4_scout: return "Llama 4 Scout 17B"
        case .kimi_k2:      return "Kimi K2"
        case .qwen3_32b:    return "Qwen 3 32B"
        }
    }
}

class SettingsManager: ObservableObject {
    private static let apiKeyKey = "flowx_groq_api_key"
    private static let llmModelKey = "flowx_llm_model"
    private static let hotkeyKey = "flowx_hotkey"

    @Published var apiKey: String? {
        didSet { UserDefaults.standard.set(apiKey, forKey: Self.apiKeyKey) }
    }

    @Published var llmModel: String {
        didSet { UserDefaults.standard.set(llmModel, forKey: Self.llmModelKey) }
    }

    @Published var hotkey: HotkeyChoice {
        didSet { UserDefaults.standard.set(hotkey.rawValue, forKey: Self.hotkeyKey) }
    }

    init() {
        self.apiKey = UserDefaults.standard.string(forKey: Self.apiKeyKey)
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
    }

    var hasValidAPIKey: Bool {
        guard let key = apiKey else { return false }
        return !key.isEmpty && key.hasPrefix("gsk_")
    }
}
