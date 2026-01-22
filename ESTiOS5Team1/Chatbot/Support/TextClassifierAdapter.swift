//
//  TextClassifierAdapter.swift
//  ESTiOS5Team1
//
//  Created by 김대현 on 1/22/26.
//

import CoreML
import Foundation

final class CreateMLTextClassifierAdapter: MessageIntentClassifying {
    private let modelName: String
    private var model: MLModel?

    init(modelName: String) {
        self.modelName = modelName
        self.model = Self.loadModel(named: modelName)
    }

    func predictLabel(text: String) -> (label: String, confidence: Double)? {
        guard let model else { return nil }

        do {
            let input = try MLDictionaryFeatureProvider(dictionary: ["text": text])
            let out = try model.prediction(from: input)

            let label = out.featureValue(for: "label")?.stringValue

            let probDict = out.featureValue(for: "labelProbability")?.dictionaryValue

            guard let label, let probDict else { return nil }

            let conf = (probDict[label] as? NSNumber)?.doubleValue ?? 0.0
            return (label: label, confidence: conf)
        } catch {
            return nil
        }
    }

    private static func loadModel(named name: String) -> MLModel? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "mlmodelc") else {
            return nil
        }

        do {
            let config = MLModelConfiguration()
            config.computeUnits = .all
            return try MLModel(contentsOf: url, configuration: config)
        } catch {
            return nil
        }
    }
}
