/***************************************************************************************************
 DomainLabelTests.swift
   © 2018,2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 **************************************************************************************************/

@testable import NetworkGear

#if swift(>=6) && canImport(Testing)
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
#else
import XCTest

final class DomainLabelTests: XCTestCase {
  func testInitialization_empty() {
    do {
      let _ = try Domain.Label("")
    } catch Domain.Label.InitializationError.emptyString {
      return
    } catch {
      XCTFail("Unexpected Error.")
      return
    }
    XCTFail("No error is thrown.")
  }
  
  func testInitialization_notNFC() {
    do {
      let _ = try Domain.Label("\u{304B}\u{3099}")
    } catch Domain.Label.InitializationError.invalidNormalization {
      return
    } catch {
      XCTFail("Unexpected Error.")
      return
    }
    XCTFail("No error is thrown.")
  }
  
  func testInitialization_mark() {
    do {
      let _ = try Domain.Label("\u{1D167}abc")
    } catch Domain.Label.InitializationError.firstScalarIsMark {
      return
    } catch {
      XCTFail("Unexpected Error.")
      return
    }
    XCTFail("No error is thrown.")
  }
  
  func testInitialization_hyphens() {
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
      XCTAssertNoThrow(try Domain.Label(oks))
    }
    
    for ngs in ng {
      do {
        let _ = try Domain.Label(ngs)
      } catch Domain.Label.InitializationError.inappropriateHyphen {
        continue
      } catch {
        XCTFail("Unexpected Error.")
        continue
      }
      XCTFail("No error is thrown although \"\(ngs)\" is invalid.")
    }
  }
  
  func testInitialization_bidi() {
    // need tests
  }
  
  func testInitialization_fullStop() {
    do {
      let _ = try Domain.Label("abc.def")
    } catch Domain.Label.InitializationError.containingFullStop {
      return
    } catch {
      XCTFail("Unexpected Error.")
      return
    }
    XCTFail("No error is thrown.")
  }
  
  func testInitialization_idna() {
    do {
      let _ = try Domain.Label("ABC")
    } catch Domain.Label.InitializationError.invalidIDNAStatus {
      return
    } catch {
      XCTFail("Unexpected Error.")
      return
    }
    
    do {
      let _ = try Domain.Label("xn--ab-cd")
    } catch Domain.Label.InitializationError.invalidIDNLabel {
      return
    } catch {
      XCTFail("Unexpected Error.")
      return
    }
    
    XCTFail("No error is thrown.")
  }
  
  func testInitialization_contextJ() {
    // need tests
  }
  
  func testInitialization_contextO() {
    // need tests
  }
  
  func testInitialization_length() {
    do {
      let _ = try Domain.Label("あいうえおかきくけこさしすせそたちつてとなにぬねのはひふへほまみむめもやゆよらりるれろわをん")
    } catch Domain.Label.InitializationError.invalidLength {
      return
    } catch {
      XCTFail("Unexpected Error.")
      return
    }
    XCTFail("No error is thrown.")
  }
  
  func testInitialization() {
    let pairs: [(String,String)] = [
      ("xn--bcher-kva", "xn--bcher-kva"),
      ("bücher", "xn--bcher-kva"),
    ]
    
    for pair in pairs {
      guard let label = try? Domain.Label(pair.0) else {
        XCTFail("Label cannot be initialized with \"\(pair.0)\"")
        return
      }
      XCTAssertEqual(label.description, pair.1)
    }
  }
  
  func test_equatability() throws {
    XCTAssertTrue(try Domain.Label("foo") == "foo")
    XCTAssertTrue(try "foo" == Domain.Label("foo"))
    XCTAssertTrue((try? Domain.Label("foo")) == "foo")
    XCTAssertTrue(Optional<Substring>.some("foo") == (try? Domain.Label("foo")))
    XCTAssertTrue((try? Domain.Label("----------")) == Optional<String>.none)
    XCTAssertTrue(Optional<String>.none == (try? Domain.Label("----------")))
    
    XCTAssertFalse(try Domain.Label("foo") == "bar")
    XCTAssertFalse(try "foo" == Domain.Label("bar"))
    XCTAssertFalse((try? Domain.Label("foo")) == "bar")
    XCTAssertFalse(Optional<Substring>.some("foo") == (try? Domain.Label("bar")))
    XCTAssertFalse((try? Domain.Label("----------")) == Optional<String>.some("bar"))
    XCTAssertFalse(Optional<String>.none == (try? Domain.Label("bar")))
  }
}
#endif
