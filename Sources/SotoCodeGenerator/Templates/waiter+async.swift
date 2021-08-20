extension Templates {
    static let waiterAsyncTemplate = """
{{%CONTENT_TYPE:TEXT}}
{{>header}}

#if compiler(>=5.5)

import SotoCore

// MARK: Waiters

@available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
extension {{name}} {
{{#waiters}}
    public func waitUntil{{waiterName}}(
        _ input: {{operation.inputShape}},
        maxWaitTime: TimeAmount? = nil,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil
    ) async throws {
        let waiter = AWSClient.Waiter(
            acceptors: [
{{#acceptors}}
{{#matcher.jmesPath}}
                .init(state: .{{state}}, matcher: try! JMESPathMatcher("{{path}}", expected: {{expected}})),
{{/matcher.jmesPath}}
{{#matcher.jmesAnyPath}}
                .init(state: .{{state}}, matcher: try! JMESAnyPathMatcher("{{path}}", expected: {{expected}})),
{{/matcher.jmesAnyPath}}
{{#matcher.jmesAllPath}}
                .init(state: .{{state}}, matcher: try! JMESAllPathMatcher("{{path}}", expected: {{expected}})),
{{/matcher.jmesAllPath}}
{{#matcher.error}}
                .init(state: .{{state}}, matcher: AWSErrorCodeMatcher("{{.}}")),
{{/matcher.error}}
{{#matcher.errorStatus}}
                .init(state: .{{state}}, matcher: AWSErrorStatusMatcher({{.}})),
{{/matcher.errorStatus}}
{{#matcher.success}}
                .init(state: .{{state}}, matcher: AWSSuccessMatcher()),
{{/matcher.success}}
{{/acceptors}}
            ],
{{#minDelayTime}}
            minDelayTime: .seconds({{.}}),
{{/minDelayTime}}
{{#maxDelayTime}}
            maxDelayTime: .seconds({{.}}),
{{/maxDelayTime}}
            command: {{operation.funcName}}
        )
        return try await self.client.waitUntil(input, waiter: waiter, maxWaitTime: maxWaitTime, logger: logger, on: eventLoop)
    }
{{#last()}}

{{/last()}}
{{/waiters}}
}

#endif // compiler(>=5.5)
"""
}