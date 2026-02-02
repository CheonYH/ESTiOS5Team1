//
//  TextClassifierAdapter.swift
//  ESTiOS5Team1
//
//  Created by 김대현 on 1/22/26.
//

import CoreML
import Foundation

// MessageGate에서 사용하는 분류기 인터페이스
// label은 모델이 내보내는 문자열 라벨
// confidence는 0~1 확률값이 있으면 전달하고, 없으면 음수(-1)로 전달한다.
final class CreateMLTextClassifierAdapter: MessageIntentClassifying {
    private let requestedModelName: String
    private let resolvedModelName: String

    // 실제 예측을 수행하는 백엔드
    // typed 모델은 Swift에서 타입 안정적으로 prediction을 호출할 수 있지만,
    // 모델 출력에 확률값이 포함되지 않는 경우가 많다.
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

                // typed 모델은 확률을 제공하지 않으므로 confidence는 -1로 내려서
                // MessageGate에서 "라벨만으로 판정"하도록 연결한다.
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

                // generic 모델은 확률 딕셔너리를 제공하는 경우가 있다.
                // 제공되면 label에 해당하는 확률을 찾아 사용하고,
                // 제공되지 않으면 1.0(확신)으로 둔다.
                var confidence: Double = 1.0

                if let outputProbKey,
                   let probs = out.featureValue(for: outputProbKey)?.dictionaryValue {
                    // 여기서 probability는 static 메서드이므로 Self.로 호출해야 한다.
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

    // 시뮬레이터에서는 bert typed 모델 로딩이 실패하는 경우가 있어서 baseline으로 대체한다.
    // 디바이스에서는 요청된 모델을 그대로 사용한다.
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

        // baseline 등은 번들에서 mlmodelc로 로드한다.
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

    // generic 모델에서 입력/출력 키를 추론한다.
    // 모델마다 키 이름이 다를 수 있어, 일반적으로 쓰이는 후보 목록을 순회한다.
    private static func genericBackend(from model: MLModel) -> Backend? {
        let inputKeys = Set(model.modelDescription.inputDescriptionsByName.keys)
        let outputKeys = Set(model.modelDescription.outputDescriptionsByName.keys)

        let inputTextKeyCandidates = ["text", "input", "input_text"]

        // 라벨은 문자열로 나오는 키를 우선한다.
        // 확률 딕셔너리 키("classLabelProbs" 등)는 라벨 키 후보에서 제외한다.
        let outputLabelKeyCandidates = ["label", "classLabel", "predictedLabel", "output"]

        // 확률(라벨별 확률값)이 들어있는 딕셔너리 키 후보
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

    // CoreML의 dictionaryValue는 키/값 타입이 상황에 따라 섞일 수 있다.
    // 라벨 문자열과 정확히 매칭되는 확률 값을 찾아 Double로 반환한다.
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
