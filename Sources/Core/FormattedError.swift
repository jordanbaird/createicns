//
// FormattedError.swift
// createicns
//

import Foundation

struct ControlCode {
    let rawValue: String

    init(rawValue: String) {
        self.rawValue = rawValue
    }

    init() {
        self.init(rawValue: "")
    }

    init(_ value: UInt8) {
        self.init(rawValue: String(describing: value))
    }

    init(reducing codes: [Self]) {
        self = codes.reduce(into: Self()) { $0.append($1) }
    }

    static let escape = Self(rawValue: "\u{001B}")

    static let bracket = Self(rawValue: "[")

    static let semicolon = Self(rawValue: ";")

    static let close = Self(rawValue: "m")

    static let open = Self(reducing: [.escape, .bracket])

    static func tag(_ value: UInt8) -> Self {
        Self(reducing: [.open, Self(value), .close])
    }

    mutating func append(_ other: Self) {
        self = Self(rawValue: rawValue + other.rawValue)
    }
}

typealias ControlCodes = (on: ControlCode, off: ControlCode)

struct Stack<Element> {
    private var elements: [Element]

    init(elements: [Element] = []) {
        self.elements = elements
    }

    func peek() -> Element? {
        elements.last
    }

    mutating func push(_ element: Element) {
        elements.append(element)
    }

    @discardableResult
    mutating func pop() -> Element? {
        elements.popLast()
    }

    mutating func swap(_ element: inout Element?) {
        let last = pop()
        if let element {
            push(element)
        }
        element = last
    }
}

class FormattingContext {
    private var components: [any FormattingComponent]

    init(components: [any FormattingComponent]) {
        self.components = components
    }

    func format() -> String {
        var codeStack = Stack<ControlCodes>()
        var result = ""
        for component in components {
            component.append(to: &result, codeStack: &codeStack)
        }
        return result
    }
}

protocol FormattingComponent {
    func append(to result: inout String, codeStack: inout Stack<ControlCodes>)
}

extension FormattingComponent {
    func format() -> String {
        FormattingContext(components: [self]).format()
    }
}

private struct StringComponent: FormattingComponent {
    let string: String

    func append(to result: inout String, codeStack _: inout Stack<ControlCodes>) {
        result.append(string)
    }
}

protocol FormattingTag: FormattingComponent {
    var components: [any FormattingComponent] { get }
    init(components: [any FormattingComponent])
}

extension FormattingTag {
    init<C: FormattingComponent>(_ component: C) {
        self.init(components: [component])
    }

    init(_ string: String) {
        self.init(StringComponent(string: string))
    }

    init<S: Sequence>(_ sequence: S) where S.Element == String {
        self.init(components: sequence.map { StringComponent(string: $0) })
    }

    fileprivate func defaultAppend(to result: inout String, on: ControlCode, off: ControlCode, codeStack: inout Stack<ControlCodes>) {
        result.append(on.rawValue)
        codeStack.push((on, off))
        defer {
            result.append(off.rawValue)
            codeStack.pop()
        }
        for component in components {
            component.append(to: &result, codeStack: &codeStack)
        }
    }
}

struct Passthrough: FormattingTag {
    let components: [any FormattingComponent]

    init(components: [any FormattingComponent]) {
        self.components = components
    }

    func append(to result: inout String, codeStack: inout Stack<ControlCodes>) {
        for component in components {
            component.append(to: &result, codeStack: &codeStack)
        }
    }
}

struct Bold: FormattingTag {
    let components: [any FormattingComponent]

    init(components: [any FormattingComponent]) {
        self.components = components
    }

    func append(to result: inout String, codeStack: inout Stack<ControlCodes>) {
        defaultAppend(to: &result, on: .tag(1), off: .tag(22), codeStack: &codeStack)
    }
}

struct Red: FormattingTag {
    let components: [any FormattingComponent]

    init(components: [any FormattingComponent]) {
        self.components = components
    }

    func append(to result: inout String, codeStack: inout Stack<ControlCodes>) {
        defaultAppend(to: &result, on: .tag(31), off: .tag(39), codeStack: &codeStack)
    }
}

struct Green: FormattingTag {
    let components: [any FormattingComponent]

    init(components: [any FormattingComponent]) {
        self.components = components
    }

    func append(to result: inout String, codeStack: inout Stack<ControlCodes>) {
        defaultAppend(to: &result, on: .tag(32), off: .tag(39), codeStack: &codeStack)
    }
}

struct Yellow: FormattingTag {
    let components: [any FormattingComponent]

    init(components: [any FormattingComponent]) {
        self.components = components
    }

    func append(to result: inout String, codeStack: inout Stack<ControlCodes>) {
        defaultAppend(to: &result, on: .tag(33), off: .tag(39), codeStack: &codeStack)
    }
}

struct Blue: FormattingTag {
    let components: [any FormattingComponent]

    init(components: [any FormattingComponent]) {
        self.components = components
    }

    func append(to result: inout String, codeStack: inout Stack<ControlCodes>) {
        defaultAppend(to: &result, on: .tag(34), off: .tag(39), codeStack: &codeStack)
    }
}

struct Cyan: FormattingTag {
    let components: [any FormattingComponent]

    init(components: [any FormattingComponent]) {
        self.components = components
    }

    func append(to result: inout String, codeStack: inout Stack<ControlCodes>) {
        defaultAppend(to: &result, on: .tag(36), off: .tag(39), codeStack: &codeStack)
    }
}

struct StripFormatting: FormattingTag {
    let components: [any FormattingComponent]

    init(components: [any FormattingComponent]) {
        self.components = components
    }

    func append(to result: inout String, codeStack: inout Stack<ControlCodes>) {
        var _codeStack = codeStack
        var (on, off) = (ControlCode(), ControlCode())
        while let last = _codeStack.pop() {
            on.append(last.off)
            off.append(last.on)
        }
        result.append(on.rawValue)
        codeStack.push((on, off))
        defer {
            result.append(off.rawValue)
            codeStack.pop()
        }
        for component in components {
            component.append(to: &result, codeStack: &codeStack)
        }
    }
}

protocol FormattedError: LocalizedError {
    var components: [any FormattingComponent] { get }
}

extension FormattedError {
    var errorDescription: String? {
        FormattingContext(components: components).format()
    }
}
