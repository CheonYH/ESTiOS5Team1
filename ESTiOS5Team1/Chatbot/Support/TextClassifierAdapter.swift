//
//  TextClassifierAdapter.swift
//  ESTiOS5Team1
//
//  Created by 김대현 on 1/22/26.
//

import CoreML
import Foundation
import OSLog

final class CreateMLTextClassifierAdapter: MessageIntentClassifying {
    private let requestedModelName: String

    private let logger = Logger(subsystem: "ESTiOS5Team1", category: "CreateMLTextClassifierAdapter")

    // Simulator/Preview -> baseline 강제
    private let resolvedModelName: String

    // Backend
    private enum Backend {
        case typedBert(GameNonGame_bert)
        case generic(model: MLModel, inputTextKey: String, outputLabelKey: String, outputProbKey: String?)
    }

    private var backend: Backend?

    init(modelName: String) {
        self.requestedModelName = modelName
        self.resolvedModelName = Self.resolveModelName(requested: modelName)

        let config = MLModelConfiguration()
        config.computeUnits = .all

        // iPhone(실물) + bert 요청인 경우: typed model 우선
        if Self.shouldUseTypedBert(modelName: resolvedModelName) {
            do {
                let typed = try GameNonGame_bert(configuration: config)
                self.backend = .typedBert(typed)
                logger.info("[CreateMLAdapter] init modelName=\(self.resolvedModelName, privacy: .public) backend=typedBert loaded=true")
                return
            } catch {
                logger.error("[CreateMLAdapter] typedBert init FAILED modelName=\(self.resolvedModelName, privacy: .public) error=\(String(describing: error), privacy: .public)")
                // typed 실패 시 generic로 폴백 시도
            }
        }

        // 그 외(= simulator/preview 포함): generic MLModel 로드
        guard let model = Self.loadGenericModel(named: resolvedModelName, configuration: config) else {
            logger.error("[CreateMLAdapter] init FAILED modelName=\(self.resolvedModelName, privacy: .public) (mlmodelc not found in bundle)")
            self.backend = nil
            return
        }

        let inKeys = Array(model.modelDescription.inputDescriptionsByName.keys)
        let outKeys = Array(model.modelDescription.outputDescriptionsByName.keys)
        logger.info("[CreateMLAdapter] init modelName=\(self.resolvedModelName, privacy: .public) backend=generic loaded=true")
        logger.info("[CreateMLAdapter] IO inputs=\(String(describing: inKeys), privacy: .public) outputs=\(String(describing: outKeys), privacy: .public)")

        // input key
        let inputTextKey: String = {
            if inKeys.contains("text") { return "text" }
            return inKeys.first ?? "text"
        }()

        let outputDescriptions = model.modelDescription.outputDescriptionsByName

        // label key
        let outputLabelKey: String = {
            if outKeys.contains("label") { return "label" }
            if outKeys.contains("classLabel") { return "classLabel" }
            if let k = outKeys.first(where: { outputDescriptions[$0]?.type == .string }) { return k }
            // 최후 fallback: "label" 고정
            return "label"
        }()

        // probability key (없을 수 있음)
        let outputProbKey: String? = {
            if outKeys.contains("labelProbability") { return "labelProbability" }
            if outKeys.contains("classLabelProbs") { return "classLabelProbs" }
            return outKeys.first(where: { outputDescriptions[$0]?.type == .dictionary })
        }()

        logger.info("[CreateMLAdapter] keys input=\(inputTextKey, privacy: .public) label=\(outputLabelKey, privacy: .public) prob=\((outputProbKey ?? "nil"), privacy: .public)")

        self.backend = .generic(
            model: model,
            inputTextKey: inputTextKey,
            outputLabelKey: outputLabelKey,
            outputProbKey: outputProbKey
        )
    }

    func predictLabel(text: String) -> (label: String, confidence: Double)? {
        logger.info("[CreateMLAdapter] predictLabel called len=\(text.count)")

        guard let backend else {
            logger.error("[CreateMLAdapter] predictLabel aborted: backend=nil")
            return nil
        }

        switch backend {
        case .typedBert(let typed):
            do {
                let out = try typed.prediction(text: text)
                let label = out.label.trimmingCharacters(in: .whitespacesAndNewlines)
                guard label.isEmpty == false else {
                    logger.error("[CreateMLAdapter] typedBert output label empty")
                    return nil
                }
                // bert typed output에 확률이 없으면 conf=1.0로 운용(요청하신 “% 안 써도 바로 작동”)
                logger.info("[CreateMLAdapter] typedBert prediction OK label=\(label, privacy: .public) conf=1.0")
                return (label: label, confidence: 1.0)
            } catch {
                logger.error("[CreateMLAdapter] typedBert prediction FAILED error=\(String(describing: error), privacy: .public)")
                return nil
            }

        case .generic(let model, let inputTextKey, let outputLabelKey, let outputProbKey):
            do {
                let input = try MLDictionaryFeatureProvider(dictionary: [inputTextKey: text])
                let out = try model.prediction(from: input)

                guard let label = out.featureValue(for: outputLabelKey)?.stringValue,
                      label.isEmpty == false else {
                    logger.error("[CreateMLAdapter] generic output missing label key=\(outputLabelKey, privacy: .public)")
                    return nil
                }

                var conf: Double = 1.0
                if let outputProbKey,
                   let dict = out.featureValue(for: outputProbKey)?.dictionaryValue {
                    if let n = dict[label] as? NSNumber {
                        conf = n.doubleValue
                    } else {
                        for (k, v) in dict {
                            if let ks = k as? String, ks == label, let nv = v as? NSNumber {
                                conf = nv.doubleValue
                                break
                            }
                        }
                    }
                }

                logger.info("[CreateMLAdapter] generic prediction OK label=\(label, privacy: .public) conf=\(conf)")
                return (label: label, confidence: conf)
            } catch {
                logger.error("[CreateMLAdapter] generic prediction FAILED error=\(String(describing: error), privacy: .public)")
                return nil
            }
        }
    }

    // MARK: - Helpers

    private static func resolveModelName(requested: String) -> String {
        #if targetEnvironment(simulator)
        return Self.baselineModelName(for: requested)
        #else
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            return Self.baselineModelName(for: requested)
        }
        return requested
        #endif
    }

    private static func shouldUseTypedBert(modelName: String) -> Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            return false
        }
        return modelName == "GameNonGame_bert"
        #endif
    }

    private static func baselineModelName(for requested: String) -> String {
        if requested.contains("GameSort") {
            return "GameSort_baseline"
        }
        if requested.contains("GameNonGame") {
            return "GameNonGame_baseline"
        }
        if requested.lowercased().contains("baseline") {
            return requested
        }
        return requested
    }

    private static func loadGenericModel(named name: String, configuration: MLModelConfiguration) -> MLModel? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "mlmodelc") else {
            return nil
        }
        do {
            return try MLModel(contentsOf: url, configuration: configuration)
        } catch {
            return nil
        }
    }
}
