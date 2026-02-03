//
//  TextClassifierAdapter.swift
//  ESTiOS5Team1
//
//  Created by 김대현 on 1/22/26.
//

import CoreML
import Foundation

// MARK: - Overview

/// CoreML 텍스트 분류 모델을 MessageGate에서 쓰기 쉬운 형태로 감싸는 어댑터입니다.
///
/// 이 파일의 역할
/// - 모델 로딩(typed model / generic MLModel)을 한 곳에서 처리합니다.
/// - 입력 텍스트를 넣으면 (label, confidence) 형태로 결과를 반환합니다.
/// - 모델 키/출력 포맷 차이를 여기서 흡수해, MessageGate/ViewModel이 CoreML 세부사항을 몰라도 되게 합니다.
///
/// 연동 위치
/// - MessageGate: MessageIntentClassifying 프로토콜로 주입되어 predictLabel(text:)만 호출합니다.
/// - ChatModels.GameDomainLabel / GameIntentLabel: label 문자열을 앱 표준 라벨로 변환해 정책을 결정합니다.
///
/// 구현 선택 이유
/// - typed 모델을 우선: 생성 코드가 단순하고 입력/출력 키를 맞출 필요가 적습니다.
/// - generic fallback: 모델 교체/이름 변경 시에도 input/output key를 탐색해 최대한 동작을 유지합니다.
/// - confidence가 없을 수 있어 -1로 표기: MessageGateConfig.treatMissingConfidenceAsHigh 정책과 연동됩니다.
final class CreateMLTextClassifierAdapter: MessageIntentClassifying {
    /// 외부에서 요청한 모델 이름입니다.
    /// - 디버그/로그에서 “원래 어떤 모델을 쓰려고 했는지” 추적 용도입니다.
    private let requestedModelName: String

    /// 실제 로딩에 사용될 모델 이름입니다.
    /// - 시뮬레이터에서는 대형/특정 포맷 모델이 로딩 실패할 수 있어 baseline으로 치환합니다.
    private let resolvedModelName: String

    /// 실제 예측을 수행하는 백엔드 종류입니다.
    ///
    /// typedBertNonGame / typedBertSort
    /// - 컴파일된 모델 클래스(GameNonGame_bert 등)를 직접 사용합니다.
    /// - 예측은 가능하지만 확률을 노출하지 않는 타입일 수 있어 confidence는 -1로 반환합니다.
    ///
    /// generic
    /// - MLModel로 로드 후, input/output key를 탐색해 예측합니다.
    /// - outputProbKey가 있으면 confidence(확률)까지 계산합니다.
    private enum Backend {
        case typedBertNonGame(GameNonGame_bert)
        case typedBertSort(GameSort_bert)
        case generic(model: MLModel, inputTextKey: String, outputLabelKey: String, outputProbKey: String?)
    }

    /// 초기화 시 로딩한 백엔드입니다.
    /// - 로딩 실패 시 nil이며, 이 경우 Gate는 보수적으로 차단하는 흐름으로 연결됩니다.
    private var backend: Backend?

    /// 지정된 모델 이름으로 분류기를 구성합니다.
    ///
    /// modelName은 “요청 이름”이고, 내부에서 resolveModelName을 통해 실제 로딩 이름을 결정합니다.
    /// - Simulator 환경에서만 모델을 치환하는 이유는, 일부 모델이 시뮬레이터에서 동작하지 않는 케이스를 방어하기 위함입니다.
    init(modelName: String) {
        self.requestedModelName = modelName
        self.resolvedModelName = Self.resolveModelName(requested: modelName)
        self.backend = Self.loadBackend(modelName: self.resolvedModelName)
    }

    /// 입력 텍스트를 분류해 label/confidence를 반환합니다.
    ///
    /// 반환 규칙
    /// - label이 비어 있으면 nil 처리합니다.
    /// - typed 모델은 확률을 제공하지 않을 수 있어 confidence를 -1로 반환합니다.
    ///   이 값은 MessageGateConfig.treatMissingConfidenceAsHigh와 연결되어,
    ///   “확률이 없더라도 label이 game이면 통과” 같은 정책을 가능하게 합니다.
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

    /// 시뮬레이터 환경에서 모델 이름을 치환합니다.
    ///
    /// 의도
    /// - bert 계열 모델이 특정 런타임/아키텍처에서 로딩 실패하는 경우가 있어 baseline 모델로 폴백합니다.
    /// - 디바이스에서는 원래 요청한 모델을 그대로 사용합니다.
    private static func resolveModelName(requested: String) -> String {
        #if targetEnvironment(simulator)
        if requested == "GameNonGame_bert" { return "GameNonGame_baseline" }
        if requested == "GameSort_bert" { return "GameSort_baseline" }
        return requested
        #else
        return requested
        #endif
    }

    /// 모델 이름을 기준으로 백엔드를 로드합니다.
    ///
    /// 로딩 순서
    /// 1) typed 모델 이름이면 해당 클래스로 로드
    /// 2) 아니면 번들에서 mlmodelc를 찾아 generic 로드
    ///
    /// 이렇게 나눈 이유
    /// - typed 모델은 키 추측 없이 바로 prediction이 가능해 안정적입니다.
    /// - generic은 모델 스펙이 바뀌어도 input/output key 후보를 탐색해 동작을 이어갈 수 있습니다.
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

    /// generic 모델에서 input/output key를 탐색해 Backend를 구성합니다.
    ///
    /// 후보 키를 여러 개 두는 이유
    /// - Create ML / 커스텀 모델마다 입력/출력 키 이름이 다를 수 있습니다.
    /// - 여기서만 차이를 흡수하면, 나머지 레이어는 label/confidence만 신경 쓰면 됩니다.
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

    /// 확률 딕셔너리에서 특정 label의 확률을 찾아 Double로 반환합니다.
    ///
    /// dictionaryValue는 키 타입이 AnyHashable로 들어오므로,
    /// String 키로 직접 접근이 실패할 수 있어 두 단계로 탐색합니다.
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
