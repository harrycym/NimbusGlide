import SwiftUI
import AppKit

struct UpgradeView: View {
    @EnvironmentObject var usageTracker: UsageTracker
    @Environment(\.dismiss) var dismiss
    @State private var selectedPlan: PlanOption = .annual
    @State private var isLoading = false
    @State private var errorMessage: String?

    enum PlanOption { case monthly, annual }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Background
            LinearGradient(
                colors: [Color(red: 0.97, green: 0.96, blue: 1.0), Color.white],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                VStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(
                                colors: [Color(red: 0.38, green: 0.20, blue: 0.92), Color(red: 0.62, green: 0.18, blue: 0.95)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ))
                            .frame(width: 60, height: 60)
                            .shadow(color: Color.purple.opacity(0.35), radius: 12, x: 0, y: 6)
                        Image(systemName: "waveform")
                            .font(.system(size: 26, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .padding(.top, 28)

                    Text("Go Pro")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.1, green: 0.05, blue: 0.2))

                    Text("Unlimited dictation.\nNo word limits, ever.")
                        .font(.callout)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                }
                .padding(.bottom, 22)

                // Plan cards
                VStack(spacing: 8) {
                    planCard(option: .annual,  title: "Annual",  price: "$3", period: "/mo", detail: "$36 billed yearly", badge: "Save 40%")
                    planCard(option: .monthly, title: "Monthly", price: "$5", period: "/mo", detail: "Cancel anytime",    badge: nil)
                }
                .padding(.horizontal, 20)

                // Features
                VStack(alignment: .leading, spacing: 5) {
                    featureRow(icon: "infinity",              "Unlimited dictation")
                    featureRow(icon: "sparkles",              "Best AI model")
                    featureRow(icon: "person.text.rectangle", "Custom profiles")
                    featureRow(icon: "bolt.fill",             "Priority processing")
                }
                .padding(.top, 16)
                .frame(maxWidth: .infinity, alignment: .center)

                Spacer()

                // CTA
                VStack(spacing: 8) {
                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }

                    Button(action: handleUpgrade) {
                        HStack(spacing: 8) {
                            if isLoading {
                                ProgressView()
                                    .scaleEffect(0.75)
                                    .progressViewStyle(.circular)
                                    .tint(.white)
                            }
                            Text(isLoading ? "Opening checkout…" : "Continue to Checkout")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(LinearGradient(
                            colors: [Color(red: 0.38, green: 0.20, blue: 0.92), Color(red: 0.55, green: 0.15, blue: 0.98)],
                            startPoint: .leading, endPoint: .trailing
                        ))
                        .foregroundColor(.white)
                        .cornerRadius(13)
                        .shadow(color: Color.purple.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .buttonStyle(.plain)
                    .disabled(isLoading)
                    .padding(.horizontal, 20)

                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.caption2)
                            .foregroundColor(.green)
                        Text("7-day money-back guarantee")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.bottom, 20)
            }

            // Close button
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                    .padding(7)
                    .background(Color.black.opacity(0.07))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .padding(12)
        }
        .frame(width: 360, height: 510)
    }

    private func planCard(option: PlanOption, title: String, price: String, period: String, detail: String, badge: String?) -> some View {
        let isSelected = selectedPlan == option
        return Button(action: { withAnimation(.easeInOut(duration: 0.15)) { selectedPlan = option } }) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .strokeBorder(isSelected ? Color(red: 0.5, green: 0.2, blue: 0.94) : Color.secondary.opacity(0.25), lineWidth: 2)
                        .frame(width: 20, height: 20)
                    if isSelected {
                        Circle()
                            .fill(Color(red: 0.5, green: 0.2, blue: 0.94))
                            .frame(width: 10, height: 10)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(title)
                            .font(.callout.weight(.semibold))
                            .foregroundColor(Color(red: 0.1, green: 0.05, blue: 0.2))
                        if let badge {
                            Text(badge)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(LinearGradient(
                                    colors: [Color(red: 0.38, green: 0.20, blue: 0.92), Color(red: 0.62, green: 0.18, blue: 0.95)],
                                    startPoint: .leading, endPoint: .trailing
                                ))
                                .cornerRadius(5)
                        }
                    }
                    Text(detail)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                HStack(alignment: .firstTextBaseline, spacing: 1) {
                    Text(price).font(.title2.weight(.bold)).foregroundColor(Color(red: 0.1, green: 0.05, blue: 0.2))
                    Text(period).font(.caption).foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color(red: 0.38, green: 0.20, blue: 0.92).opacity(0.06) : Color.white)
                    .shadow(color: Color.black.opacity(isSelected ? 0 : 0.04), radius: 4, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(isSelected ? Color(red: 0.5, green: 0.2, blue: 0.94).opacity(0.55) : Color.secondary.opacity(0.15), lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    private func featureRow(icon: String, _ text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(LinearGradient(
                    colors: [Color(red: 0.38, green: 0.20, blue: 0.92), Color(red: 0.62, green: 0.18, blue: 0.95)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))
                .frame(width: 14, alignment: .center)
            Text(text)
                .font(.caption)
                .foregroundColor(Color(red: 0.3, green: 0.25, blue: 0.4))
        }
    }

    private func handleUpgrade() {
        isLoading = true
        errorMessage = nil

        guard let appDelegate = NSApp.delegate as? AppDelegate else {
            errorMessage = "Something went wrong"
            isLoading = false
            return
        }

        Task {
            do {
                let checkoutURL = try await appDelegate.apiClient.createCheckoutSession()
                await MainActor.run {
                    NSWorkspace.shared.open(checkoutURL)
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Checkout coming soon! Payment is being set up."
                    isLoading = false
                }
            }
        }
    }
}
