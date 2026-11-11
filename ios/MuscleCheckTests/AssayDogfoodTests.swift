//
//  AssayDogfoodTests.swift
//  MuscleCheckTests
//
//  Plumbing check for using Assay (a local package, ../../Assay) in this test target.
//  The app still deploys to iOS 18; only MuscleCheckTests targets iOS 27, which is
//  Assay's minimum. A fake FoundationModels model backs a real LanguageModelSession
//  inside the hosted test bundle. Assay has no public API yet: importing it proves the
//  package links, and the fake moves into Assay as FakeModel in its M1.
//

import Assay
import FoundationModels
import Testing

@Suite("Assay dogfood: plumbing")
struct AssayDogfoodTests {

    struct FixedExecutor: LanguageModelExecutor {
        typealias Model = FixedModel

        struct Configuration: Hashable, Sendable {
            var text: String
        }

        private let text: String

        init(configuration: Configuration) {
            text = configuration.text
        }

        func prewarm(model: FixedModel, transcript: Transcript) {}

        nonisolated(nonsending) func respond(
            to request: LanguageModelExecutorGenerationRequest,
            model: FixedModel,
            streamingInto channel: LanguageModelExecutorGenerationChannel
        ) async throws {
            await channel.send(.response(action: .appendText(text, tokenCount: 1)))
        }
    }

    struct FixedModel: LanguageModel {
        typealias Executor = FixedExecutor

        var text: String

        var capabilities: LanguageModelCapabilities { .init([]) }

        var executorConfiguration: FixedExecutor.Configuration { .init(text: text) }
    }

    @Test("A fake model answers inside the iOS 18 app's test bundle")
    func fakeModelRunsInHostedTests() async throws {
        let session = LanguageModelSession(model: FixedModel(text: "Push day"))
        let response = try await session.respond(to: "Suggest a day")
        #expect(response.content == "Push day")
    }
}
