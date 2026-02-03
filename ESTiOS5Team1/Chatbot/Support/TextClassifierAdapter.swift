//
//  TextClassifierAdapter.swift
//  ESTiOS5Team1
//
//  Created by 김대현 on 1/22/26.
//

import CoreML
import Foundation

final class CreateMLTextClassifierAdapter: MessageIntentClassifying {
    private let requestedModelName: String
    private let resolvedModelName: String

    private enum Backend {
        case typedBertNonGame(GameNonGame_bert)
        case typedBertSort(GameSort_bert)
        case generic(model: MLModel, inputTextKey: String, outputLabelKey: String, outputProbKey: String?)
    }

    private var backend: Backend?

    init(modelName: String) {
        self.requestedModelName = modelName
        self.resolvedModelName = Self.resolveModelName(requested: modelName)
        self.backend = Self.loadBackend(modelName: self.resolvedModelName)
    }

    func predictLabel(text: String) -> (label: String, confidence: Double)? {
        guard let backend else { return nil }

        switch backend {
        case .typedBertNonGame(let model):
            do {
                let out = try model.prediction(text: text)
                let label = out.label.trimmingCharacters(in: .whitespacesAndNewlines)
                guard label.isEmpty == false else { return nil }

                return (label: label, confidence: -1)
            } catch {
                return nil
            }

        case .typedBertSort(let model):
            do {
                let out = try model.prediction(text: text)
                let label = out.label.trimmingCharacters(in: .whitespacesAndNewlines)
                guard label.isEmpty == false else { return nil }

                return (label: label, confidence: -1)
            } catch {
                return nil
            }

        case .generic(let model, let inputTextKey, let outputLabelKey, let outputProbKey):
            do {
                let input = try MLDictionaryFeatureProvider(dictionary: [inputTextKey: text])
                let out = try model.prediction(from: input)

                guard let labelValue = out.featureValue(for: outputLabelKey)?.stringValue else {
                    return nil
                }

                let label = labelValue.trimmingCharacters(in: .whitespacesAndNewlines)
                guard label.isEmpty == false else { return nil }

                var confidence: Double = 1.0

                if let outputProbKey,
                   let probs = out.featureValue(for: outputProbKey)?.dictionaryValue {
                    if let p = Self.probability(for: label, in: probs) {
                        confidence = p
                    }
                }

                return (label: label, confidence: confidence)
            } catch {
                return nil
            }
        }
    }

    private static func resolveModelName(requested: String) -> String {
        #if targetEnvironment(simulator)
        if requested == "GameNonGame_bert" { return "GameNonGame_baseline" }
        if requested == "GameSort_bert" { return "GameSort_baseline" }
        return requested
        #else
        return requested
        #endif
    }

    private static func loadBackend(modelName: String) -> Backend? {
        if modelName == "GameNonGame_bert" {
            do { return .typedBertNonGame(try GameNonGame_bert(configuration: MLModelConfiguration())) } catch { return nil }
        }

        if modelName == "GameSort_bert" {
            do { return .typedBertSort(try GameSort_bert(configuration: MLModelConfiguration())) } catch { return nil }
        }

        guard let url = Bundle.main.url(forResource: modelName, withExtension: "mlmodelc") else {
            return nil
        }

        do {
            let model = try MLModel(contentsOf: url)
            return genericBackend(from: model)
        } catch {
            return nil
        }
    }

    private static func genericBackend(from model: MLModel) -> Backend? {
        let inputKeys = Set(model.modelDescription.inputDescriptionsByName.keys)
        let outputKeys = Set(model.modelDescription.outputDescriptionsByName.keys)

        let inputTextKeyCandidates = ["text", "input", "input_text"]
        let outputLabelKeyCandidates = ["label", "classLabel", "predictedLabel", "output"]
        let outputProbKeyCandidates = ["labelProbability", "classLabelProbs", "probabilities"]

        guard let inputTextKey = inputTextKeyCandidates.first(where: { inputKeys.contains($0) }) else { return nil }
        guard let outputLabelKey = outputLabelKeyCandidates.first(where: { outputKeys.contains($0) }) else { return nil }

        let outputProbKey = outputProbKeyCandidates.first(where: { outputKeys.contains($0) })

        return .generic(
            model: model,
            inputTextKey: inputTextKey,
            outputLabelKey: outputLabelKey,
            outputProbKey: outputProbKey
        )
    }

    private static func probability(for label: String, in probs: [AnyHashable: Any]) -> Double? {
        if let direct = probs[label] as? NSNumber {
            return direct.doubleValue
        }

        for (k, v) in probs {
            guard let keyString = k as? String else { continue }
            guard keyString == label else { continue }
            if let n = v as? NSNumber {
                return n.doubleValue
            }
        }
        return nil
    }
}
