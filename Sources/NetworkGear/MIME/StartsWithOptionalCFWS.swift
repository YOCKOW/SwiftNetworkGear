/* *************************************************************************************************
 StartsWithOptionalCFWS.swift
   © 2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

internal protocol _StartsWithOptionalCFWS {
  var leadingComments: [MIMEComment]? { get set }
}

internal protocol _SandwichedByOptionalCFWS: _StartsWithOptionalCFWS {
  var trailingComments: [MIMEComment]? { get set }
}

internal protocol _StartsWithOptionalCFWSParserConfiguration {
  var cfwsParserConfiguration: CFWSParserConfiguration { get }
}

internal protocol _SandwichedByOptionalCFWSParserConfiguration: _StartsWithOptionalCFWSParserConfiguration {}

internal protocol _StartsWithOptionalCFWSParser: _InputAccessibleParser,
                                                 _ConfigurationAccessibleParser
where Self.Output: _StartsWithOptionalCFWS,
      Self.Configuration: _StartsWithOptionalCFWSParserConfiguration,
      Self.RemainingParser: StringParser,
      Self.RemainingParser.Input == Self.Input.SubSequence,
      Self.RemainingParser.Output == Self.Output,
      Self.RemainingParser.Configuration == Self.Configuration
{
  associatedtype RemainingParser
}

internal struct _FollowedByOptionalCFWSParser<Input, CoreParser>: StringParser
where Input: StringProtocol,
      CoreParser: StringParser,
      CoreParser.Input == Input,
      CoreParser.Output: _SandwichedByOptionalCFWS,
      CoreParser.Configuration: _SandwichedByOptionalCFWSParserConfiguration
{
  typealias Output = CoreParser.Output

  typealias Configuration = CoreParser.Configuration

  let input: Input
  var configuration: Configuration?

  init(input: Input, configuration: Configuration?) {
    self.input = input
    self.configuration = configuration
  }

  mutating func parse() -> (output: Output, endIndex: Input.Index)? {
    var coreParser = CoreParser(input: input, configuration: configuration)
    guard let coreResult = coreParser.parse() else {
      return nil
    }

    var currentIndex = coreResult.endIndex
    var trailingComments: [MIMEComment]? = nil
    if let trailingCFWS = CFWSParser<Input.SubSequence>.parse(
      input,
      from: &currentIndex,
      configuration: configuration?.cfwsParserConfiguration
    ) {
      trailingComments = trailingCFWS
    }

    var core = coreResult.output
    core.trailingComments = trailingComments

    return (
      output: core,
      endIndex: currentIndex
    )
  }
}

internal protocol _SandwichedByOptionalCFWSParser: _StartsWithOptionalCFWSParser
where Self.Output: _SandwichedByOptionalCFWS,
      Self.Configuration: _SandwichedByOptionalCFWSParserConfiguration,
      Self.CoreParser: StringParser,
      Self.CoreParser.Input == Self.Input.SubSequence,
      Self.CoreParser.Output == Self.Output,
      Self.CoreParser.Configuration == Self.Configuration
{
  associatedtype CoreParser
  associatedtype RemainingParser = _FollowedByOptionalCFWSParser<Input.SubSequence, CoreParser>
}

extension _StartsWithOptionalCFWSParser {
  @inlinable
  mutating func _parseOptionalLeadingCFWS() -> (leadingComments: [MIMEComment]?, endIndex: Input.Index)? {
    var leadingCFWSParser = CFWSParser<Input>(
      input: input,
      configuration: self.configuration.cfwsParserConfiguration
    )
    return leadingCFWSParser.parse() as ([MIMEComment]?, Input.Index)?
  }

  @inlinable
  mutating func _parseRemaining(from index: inout Input.Index) -> Output? {
    return RemainingParser.parse(input, from: &index, configuration: self.configuration)
  }

  @inlinable
  mutating func _parseWhole() -> (output: Output, endIndex: Input.Index)? {
    var currentIndex = self.input.startIndex

    var leadingComments: [MIMEComment]? = nil
    if let leadingCFWSResult = _parseOptionalLeadingCFWS() {
      leadingComments = leadingCFWSResult.leadingComments
      currentIndex = leadingCFWSResult.endIndex
    }

    guard var remaining = _parseRemaining(from: &currentIndex) else {
      return nil
    }

    remaining.leadingComments = leadingComments

    return (output: remaining, endIndex: currentIndex)
  }
}

internal enum _Either<Left, Right> {
  case left(Left)
  case right(Right)

  @inlinable
  func get(as type: Left.Type) -> Left? {
    guard case .left(let left) = self else {
      return nil
    }
    return left
  }

  @inlinable
  func get(as type: Right.Type) -> Right? {
    guard case .right(let right) = self else {
      return nil
    }
    return right
  }
}

extension _Either: Sendable where Left: Sendable, Right: Sendable {}

extension _Either: _StartsWithOptionalCFWS
where Left: _StartsWithOptionalCFWS, Right: _StartsWithOptionalCFWS {
  var leadingComments: [MIMEComment]? {
    get {
      switch self {
      case .left(let left): return left.leadingComments
      case .right(let right): return right.leadingComments
      }
    }
    set {
      switch self {
      case .left(var left):
        left.leadingComments = newValue
        self = .left(left)
      case .right(var right):
        right.leadingComments = newValue
        self = .right(right)
      }
    }
  }
}

extension _Either: _SandwichedByOptionalCFWS
where Left: _SandwichedByOptionalCFWS, Right: _SandwichedByOptionalCFWS {
  var trailingComments: [MIMEComment]? {
    get {
      switch self {
      case .left(let left):
        return left.trailingComments
      case .right(let right):
        return right.trailingComments
      }
    }
    set {
      switch self {
      case .left(var left):
        left.trailingComments = newValue
        self = .left(left)
      case .right(var right):
        right.trailingComments = newValue
        self = .right(right)
      }
    }
  }
}

internal protocol _EitherMappable {
  associatedtype _Left
  associatedtype _Right

  init(_: _Left)
  init(_: _Right)
}

extension _Either: _EitherMappable {
  typealias _Left = Left
  typealias _Right = Right

  init(_ left: Left) {
    self = .left(left)
  }

  init(_ right: Right) {
    self = .right(right)
  }

  @inlinable
  func map<T>(type: T.Type) -> T where T: _EitherMappable, T._Left == Left, T._Right == Right {
    switch self {
    case .left(let left):
      return type.init(left)
    case .right(let right):
      return type.init(right)
    }
  }

  @inlinable
  func map<T>(type: T.Type) -> T where T: _EitherMappable, T._Left == Right, T._Right == Left {
    switch self {
    case .left(let left):
      return type.init(left)
    case .right(let right):
      return type.init(right)
    }
  }
}

internal struct _EitherOfTypesStartingWithOptionalCFWSParser<
  Input,
  LeftParser,
  RightParser
>: StringParser, _StartsWithOptionalCFWSParser
where Input: StringProtocol,
      LeftParser: _StartsWithOptionalCFWSParser,
      LeftParser.RemainingParser.Input == Input.SubSequence.SubSequence,
      RightParser: _StartsWithOptionalCFWSParser,
      RightParser.RemainingParser.Input == Input.SubSequence.SubSequence
{
  typealias Output = _Either<LeftParser.Output, RightParser.Output>

  struct Configuration: _StartsWithOptionalCFWSParserConfiguration {
    var leftParserConfiguration: LeftParser.Configuration?
    var rightParserConfiguration: RightParser.Configuration?

    init(
      leftParserConfiguration: LeftParser.Configuration?,
      rightParserConfiguration: RightParser.Configuration?
    ) {
      self.leftParserConfiguration = leftParserConfiguration
      self.rightParserConfiguration = rightParserConfiguration
    }

    var cfwsParserConfiguration: CFWSParserConfiguration {
      return (
        leftParserConfiguration?.cfwsParserConfiguration ??
        rightParserConfiguration?.cfwsParserConfiguration
      ) ?? .default
    }

    static var `default`: Configuration {
      .init(
        leftParserConfiguration: nil,
        rightParserConfiguration: nil
      )
    }
  } // /Configuration

  typealias RemainingInput = Input.SubSequence
  typealias RemainingOutput = Output
  struct RemainingParser: StringParser {
    typealias Input = RemainingInput
    typealias Output = RemainingOutput

    let input: RemainingInput
    var configuration: Configuration

    init(input: RemainingInput, configuration: Configuration?) {
      self.input = input
      self.configuration = configuration ?? .default
    }

    mutating func parse() -> (output: RemainingOutput, endIndex: RemainingInput.Index)? {
      var currentIndex = self.input.startIndex

      if let leftOutput = LeftParser.RemainingParser.parse(
        input,
        from: &currentIndex,
        configuration: configuration.leftParserConfiguration
      ) {
        return (.left(leftOutput), currentIndex)
      }

      if let rightOutput = RightParser.RemainingParser.parse(
        input,
        from: &currentIndex,
        configuration: configuration.rightParserConfiguration
      ) {
        return (.right(rightOutput), currentIndex)
      }

      return nil
    }
  } // /RemainingParser

  let input: Input
  var configuration: Configuration

  init(input: Input, configuration: Configuration? = nil) {
    self.input = input
    self.configuration = configuration ?? .default
  }

  mutating func parse() -> (output: Output, endIndex: Input.Index)? {
    return _parseWhole()
  }
}
