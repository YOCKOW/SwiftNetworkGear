/***************************************************************************************************
 DomainLabelTests.swift
   © 2018 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 **************************************************************************************************/
 
import XCTest
@testable import Network

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
  
  static var allTests = [
    ("testInitialization_empty", testInitialization_empty),
    ("testInitialization_notNFC", testInitialization_notNFC),
    ("testInitialization_mark", testInitialization_mark),
    ("testInitialization_hyphens", testInitialization_hyphens),
    ("testInitialization_bidi", testInitialization_bidi),
    ("testInitialization_fullStop", testInitialization_fullStop),
    ("testInitialization_idna", testInitialization_idna),
    ("testInitialization_contextJ", testInitialization_contextJ),
    ("testInitialization_contextO", testInitialization_contextO),
    ("testInitialization_length", testInitialization_length),
    ("testInitialization", testInitialization),
  ]
}
