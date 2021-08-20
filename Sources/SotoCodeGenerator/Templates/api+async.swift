extension Templates {
    static let apiAsyncTemplate = """
{{%CONTENT_TYPE:TEXT}}
{{>header}}

#if compiler(>=5.5)

import SotoCore

@available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
extension {{ name }} {

    // MARK: Async API Calls
{{#operations}}

{{#comment}}
    /// {{.}}
{{/comment}}
{{#deprecated}}
    @available(*, deprecated, message:"{{.}}")
{{/deprecated}}
    public func {{funcName}}({{#inputShape}}_ input: {{.}}, {{/inputShape}}logger: {{logger}} = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws{{#outputShape}} -> {{.}}{{/outputShape}} {
        return try await self.client.execute(operation: "{{name}}", path: "{{path}}", httpMethod: .{{httpMethod}}, serviceConfig: self.config{{#inputShape}}, input: input{{/inputShape}}{{#hostPrefix}}, hostPrefix: "{{{.}}}"{{/hostPrefix}}, logger: logger, on: eventLoop)
    }
{{/operations}}
{{#first(streamingOperations)}}

    // MARK: Streaming Async API Calls
{{#streamingOperations}}

{{#comment}}
    /// {{.}}
{{/comment}}
{{#deprecated}}
    @available(*, deprecated, message:"{{.}}")
{{/deprecated}}
    public func {{funcName}}Streaming({{#inputShape}}_ input: {{.}}, {{/inputShape}}logger: {{logger}} = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil, _ stream: @escaping ({{streaming}}, EventLoop) -> EventLoopFuture<Void>) async throws{{#outputShape}} -> {{.}}{{/outputShape}} {
        return try await self.client.execute(operation: "{{name}}", path: "{{path}}", httpMethod: .{{httpMethod}}, serviceConfig: self.config{{#inputShape}}, input: input{{/inputShape}}{{#hostPrefix}}, hostPrefix: "{{{.}}}"{{/hostPrefix}}, logger: logger, on: eventLoop, stream: stream)
    }
{{/streamingOperations}}
{{/first(streamingOperations)}}
}

#endif // compiler(>=5.5)
"""
}