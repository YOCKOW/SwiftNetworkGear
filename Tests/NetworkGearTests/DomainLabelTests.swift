/***************************************************************************************************
 DomainLabelTests.swift
   © 2018,2024,2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 **************************************************************************************************/

@testable import NetworkGear
import Testing

@Suite final class DomainLabelTests {
  @Test func testInitialization_empty() {
    #expect(throws: Domain.Label.InitializationError.emptyString) {
      try Domain.Label("")
    }
  }

  @Test func testInitialization_notNFC() {
    #expect(throws: Domain.Label.InitializationError.invalidNormalization) {
      try Domain.Label("\u{304B}\u{3099}")
    }
  }

  @Test func testInitialization_mark() {
    #expect(throws: Domain.Label.InitializationError.firstScalarIsMark) {
      try Domain.Label("\u{1D167}abc")
    }
  }

  @Test func testInitialization_hyphens() {
    let ok = [
      "a-b-c",
      "ab-c",
      "abc-d"
    ]
    let ng = [
      "-abc",
      "abc-",
      "ab--cde"
    ]

    for oks in ok {
      #expect(throws: Never.self) { try Domain.Label(oks) }
    }

    for ngs in ng {
      #expect(throws: Domain.Label.InitializationError.inappropriateHyphen) {
        try Domain.Label(ngs)
      }
    }
  }

  @Test func testInitialization_bidi() {
    // need tests
  }

  @Test func testInitialization_fullStop() {
    #expect(throws: Domain.Label.InitializationError.containingFullStop) {
      try Domain.Label("abc.def")
    }
  }

  @Test func testInitialization_idna() {
    #expect(throws: Domain.Label.InitializationError.invalidIDNAStatus) {
      try Domain.Label("ABC")
    }
    #expect(throws: Domain.Label.InitializationError.invalidIDNLabel) {
      try Domain.Label("xn--ab-cd")
    }
  }

  @Test func testInitialization_contextJ() {
    // need tests
  }

  @Test func testInitialization_contextO() {
    // need tests
  }

  @Test func testInitialization_length() {
    #expect(throws: Domain.Label.InitializationError.invalidLength) {
      try Domain.Label("あいうえおかきくけこさしすせそたちつてとなにぬねのはひふへほまみむめもやゆよらりるれろわをん")
    }
  }

  @Test func testInitialization() {
    let pairs: [(String,String)] = [
      ("xn--bcher-kva", "xn--bcher-kva"),
      ("bücher", "xn--bcher-kva"),
    ]

    for pair in pairs {
      guard let label = try? Domain.Label(pair.0) else {
        Issue.record("Label cannot be initialized with \"\(pair.0)\"")
        return
      }
      #expect(label.description == pair.1)
    }
  }

  @Test func test_equatability() throws {
    #expect(try Domain.Label("foo") == "foo")
    #expect(try "foo" == Domain.Label("foo"))
    #expect((try? Domain.Label("foo")) == "foo")
    #expect(Optional<Substring>.some("foo") == (try? Domain.Label("foo")))
    #expect((try? Domain.Label("----------")) == Optional<String>.none)
    #expect(Optional<String>.none == (try? Domain.Label("----------")))

    #expect(try Domain.Label("foo") != "bar")
    #expect(try "foo" != Domain.Label("bar"))
    #expect((try? Domain.Label("foo")) != "bar")
    #expect(Optional<Substring>.some("foo") != (try? Domain.Label("bar")))
    #expect((try? Domain.Label("----------")) != Optional<String>.some("bar"))
    #expect(Optional<String>.none != (try? Domain.Label("bar")))
  }
}
