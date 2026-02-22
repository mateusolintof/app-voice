import Foundation
import SwiftData
import Observation

@MainActor
@Observable
final class OnboardingViewModel {
    var currentStep = 0
    var userName = ""
    var apiKey = ""
    var confrontationLevel: Double = 4
    var initialThought = ""
    var isProcessing = false
    var errorMessage: String?

    let totalSteps = 4

    var canProceed: Bool {
        switch currentStep {
        case 0: return true
        case 1: return !userName.trimmingCharacters(in: .whitespaces).isEmpty
        case 2: return true // API key is optional
        case 3: return true
        default: return true
        }
    }

    var isLastStep: Bool {
        currentStep == totalSteps - 1
    }

    func nextStep() {
        if currentStep < totalSteps - 1 {
            currentStep += 1
        }
    }

    func previousStep() {
        if currentStep > 0 {
            currentStep -= 1
        }
    }

    func completeOnboarding(modelContext: ModelContext) async {
        // Save user name
        UserDefaults.standard.set(userName.trimmingCharacters(in: .whitespaces), forKey: "userName")

        // Save API key if provided
        if !apiKey.isEmpty {
            UserDefaults.standard.set(apiKey, forKey: "openAIKey")
        }

        // Save therapy profile
        let profile = TherapyProfile(
            confrontationLevel: Int(confrontationLevel),
            defaultModes: [.blended, .cbt, .stoic, .logotherapy],
            morningWindow: TherapyProfile.default.morningWindow,
            middayWindow: TherapyProfile.default.middayWindow,
            eveningWindow: TherapyProfile.default.eveningWindow
        )
        TherapyRepository.saveProfile(profile, in: modelContext)

        // If API key and initial thought provided, generate first mission
        let thought = initialThought.trimmingCharacters(in: .whitespacesAndNewlines)
        if !apiKey.isEmpty && !thought.isEmpty {
            isProcessing = true
            do {
                let engine = OpenAITherapyEngine()
                let context = TherapyContext(
                    profile: profile,
                    activeSlot: .morning,
                    currentMission: "",
                    pendingCommitments: [],
                    recentFrictionNotes: []
                )
                let turn = try await engine.runTurn(input: thought, context: context)
                TherapyRepository.storeSession(
                    turn: turn,
                    input: thought,
                    slot: .morning,
                    phase: .intake,
                    in: modelContext
                )
                TherapyRepository.upsertCommitment(
                    turn.contract,
                    slot: .morning,
                    in: modelContext
                )
            } catch {
                errorMessage = error.localizedDescription
            }
            isProcessing = false
        }

        // Mark onboarding complete
        UserDefaults.standard.set(true, forKey: "onboardingCompleted")
    }
}
