import SwiftUI

struct PaywallView: View {
    @Environment(UserPreferences.self) private var preferences
    @Environment(StoreManager.self) private var store
    @Environment(\.dismiss) private var dismiss

    var highlightedArticleTitle: String? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    if let highlightedArticleTitle {
                        Text(preferences.t("pro.unlock_this", highlightedArticleTitle))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.brandGreen)
                    }
                    benefits
                    legalNote
                    purchaseButtons
                    DisclaimerBanner()
                }
                .padding()
            }
            .background(AppTheme.page.ignoresSafeArea())
            .navigationTitle(preferences.t("pro.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if AppStoreScreenshotScene.current != .paywall {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(preferences.t("common.close")) { dismiss() }
                    }
                }
            }
            .task {
                StoreLog.event("PaywallView appeared — running a background lookup")
                await store.refresh(surfacingErrors: false)
                StoreLog.event("PaywallView background lookup returned · price shown = \(store.displayPrice) · productLoaded = \(store.product != nil)")
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 44))
                .foregroundStyle(AppTheme.brandGold)
            Text(preferences.t("pro.headline"))
                .font(.system(.title, design: .rounded).weight(.bold))
            Text(preferences.t("pro.subtitle", store.displayPrice))
                .font(.body)
                .opacity(0.9)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(
            LinearGradient(
                colors: [AppTheme.brandNavy, AppTheme.brandGreenFixed.opacity(0.9)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
        .foregroundStyle(.white)
    }

    private var benefits: some View {
        VStack(alignment: .leading, spacing: 12) {
            benefit("lock.doc.fill", preferences.t("pro.benefit_guides"))
            benefit("checkmark.shield.fill", preferences.t("pro.benefit_offline"))
            benefit("person.crop.circle.badge.checkmark", preferences.t("pro.benefit_persona"))
            benefit("bell.badge.fill", preferences.t("pro.benefit_reminders"))
            benefit("alarm.fill", preferences.t("pro.benefit_task_reminders"))
        }
    }

    private func benefit(_ symbol: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .foregroundStyle(AppTheme.brandGreen)
                .frame(width: 28)
            Text(text)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var legalNote: some View {
        Text(preferences.t("pro.legal"))
            .font(.caption)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var purchaseButtons: some View {
        VStack(spacing: 10) {
            if let error = store.lastError {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(AppTheme.danger)
                    // Without this a multi-line message can be clipped to one
                    // line, hiding the diagnostic detail.
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else if store.productUnavailable && !store.isLoading {
                Text(preferences.t("pro.checking"))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button {
                // Logged synchronously, before any async work, so a tap that
                // goes nowhere is still visibly a tap.
                StoreLog.event("*** BUY BUTTON TAPPED ***")
                Task { await store.purchase() }
            } label: {
                HStack {
                    if store.isLoading {
                        ProgressView()
                            .tint(.white)
                    }
                    Text(preferences.t("pro.buy", store.displayPrice))
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.brandGreen)
            .disabled(store.isLoading || store.isPro)

            Button(preferences.t("pro.restore")) {
                StoreLog.event("*** RESTORE BUTTON TAPPED ***")
                Task { await store.restore() }
            }
            .disabled(store.isLoading)

            // TEMPORARY — visible in every build configuration while the
            // sandbox purchase is being diagnosed, because a Release build on a
            // device would otherwise hide the one thing we need to read.
            // Re-gate behind `#if DEBUG` before shipping 1.1.0.
            DisclosureGroup("StoreKit diagnostics · \(StoreLog.buildMarker)") {
                Text(store.diagnostics + "\n\n--- event log ---\n" + StoreLog.transcript)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
                    .padding(.top, 6)
            }
            .font(.caption)
            .tint(.secondary)
            .padding(.top, 8)
        }
    }
}

struct ProBadge: View {
    @Environment(UserPreferences.self) private var preferences

    var body: some View {
        Text(preferences.t("pro.badge"))
            .font(.caption2.weight(.bold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(AppTheme.brandGold.opacity(0.2), in: Capsule())
            .foregroundStyle(AppTheme.brandGold)
            .accessibilityLabel(preferences.t("pro.badge"))
    }
}
