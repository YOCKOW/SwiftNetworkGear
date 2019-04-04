/***************************************************************************************************
 Domain+Punycode.swift
   © 2018 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 **************************************************************************************************/
 
extension Domain {
  internal var addingPunycodeEncoding: Domain? {
    if self._options.contains(.addPunycodeEncoding) { return self }
    return Domain(self.description, options:self._options.union(.addPunycodeEncoding))
  }
  
  internal var removingPunycodeEncoding: Domain? {
    if !self._options.contains(.addPunycodeEncoding) { return self }
    return Domain(self.description, options:self._options.subtracting(.addPunycodeEncoding))
  }
}
