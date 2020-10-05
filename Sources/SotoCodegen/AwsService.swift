//===----------------------------------------------------------------------===//
//
// This source file is part of the Soto for AWS open source project
//
// Copyright (c) 2017-2020 the Soto project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Soto project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import Foundation
import SotoSmithy

struct AwsService {
    var serviceName: String
    var apiContext: [String: Any]

    init(_ model: SotoSmithy.Model) throws {
        self.serviceName = try Self.getServiceName(model)
        self.apiContext = try Self.generateServiceContext(model, serviceName: self.serviceName)
    }

    static func getTrait<T: Trait>(from shape: SotoSmithy.Shape, trait: T.Type, id: ShapeId) throws -> T {
        guard let trait = shape.trait(type: T.self) else {
            throw Error(reason: "\(id) does not have a \(T.name) trait")
        }
        return trait
    }

    /// Return service name from API
    static func getServiceName(_ model: SotoSmithy.Model) throws -> String {
        guard let serviceEntry = model.shapes(of: SotoSmithy.ServiceShape.self).first else { throw Error(reason: "No service object")}
        let service = serviceEntry.value
        let awsService = try getTrait(from: service, trait: AwsServiceTrait.self, id: serviceEntry.key)

        // port of https://github.com/aws/aws-sdk-go-v2/blob/996478f06a00c31ee7e7b0c3ac6674ce24ba0120/private/model/api/api.go#L105
        //
        let stripServiceNamePrefixes: [String] = ["Amazon", "AWS"]

        var serviceName = awsService.sdkId

        // Strip out prefix names not reflected in service client symbol names.
        for prefix in stripServiceNamePrefixes {
            serviceName.deletePrefix(prefix)
        }
        serviceName.removeCharacterSet(in: CharacterSet.alphanumerics.inverted)
        serviceName.removeWhitespaces()
        serviceName.capitalizeFirstLetter()

        return serviceName
    }

    static func getServiceProtocol(_ service: ServiceShape, serviceName: String) throws -> AwsServiceProtocolTrait {
        if let traits = service.traits {
            for trait in traits {
                if let protocolTrait = trait as? AwsServiceProtocolTrait {
                    return protocolTrait
                }
            }
        }
        throw Error(reason: "\(serviceName) does not have a service protocol trait")
    }

    static func generateServiceContext(_ model: SotoSmithy.Model, serviceName: String) throws -> [String: Any] {
        var context: [String: Any] = [:]
        guard let serviceEntry = model.shapes(of: SotoSmithy.ServiceShape.self).first else { throw Error(reason: "No service object")}
        let service = serviceEntry.value
        let awsService = try getTrait(from: service, trait: AwsServiceTrait.self, id: serviceEntry.key)
        let authSigV4 = try getTrait(from: service, trait: AwsAuthSigV4Trait.self, id: serviceEntry.key)

        context["name"] = serviceName
        context["description"] = service.trait(type: DocumentationTrait.self)?.value.tagStriped()
        // TODO: context["amzTarget"]
        context["endpointPrefix"] = awsService.arnNamespace
        context["signingName"] = authSigV4.name
        context["protocol"] = try getServiceProtocol(service, serviceName: serviceName).output
        context["apiVersion"] = service.version

        return context
    }

    static func generateOperationContext(_ operation: OperationShape, operationName: String) throws -> OperationContext {
        return OperationContext(
            comment: [],
            funcName: "",
            inputShape: nil,
            outputShape: nil,
            name: "",
            path: "",
            httpMethod: "",
            deprecated: nil,
            streaming: nil,
            documentationUrl: nil
        )
    }
}


extension AwsService {
    struct Error: Swift.Error {
        let reason: String
    }

    struct OperationContext {
        let comment: [String.SubSequence]
        let funcName: String
        let inputShape: String?
        let outputShape: String?
        let name: String
        let path: String
        let httpMethod: String
        let deprecated: String?
        let streaming: String?
        let documentationUrl: String?
    }

}