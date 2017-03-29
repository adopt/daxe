/*
  This file is part of Daxe.

  Daxe is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  Daxe is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with Daxe.  If not, see <http://www.gnu.org/licenses/>.
*/

part of xmldom;

class TokenChar extends TokenItem {
  
  String character = null;
  bool isdigit = false;
  bool isletter = false;
  bool isany = false;
  List<String> exceptions = null;
  
  TokenChar(this.character);
  
  TokenChar.digit() {
    isdigit = true;
  }
  
  TokenChar.letter() {
    isletter = true;
  }
  
  TokenChar.any() {
    isany = true;
  }
  
  TokenChar.except(this.exceptions);
  
  MatchResult evaluateString(String doc, int pos, int line) {
    String c = doc[pos];
    
    if (character != null) {
      if (c == character)
        return(new MatchResult.ch(1, c));
    } else if (isdigit) {
      if ('0123456789'.contains(c)) {
        return(new MatchResult.ch(1, c));
      }
    } else if (isletter) {
      // see https://www.w3.org/TR/xml/#d0e804
      // (this implementation is not strictly following the spec)
      int code = c.codeUnitAt(0);
      // NOTE: String.codeUnitAt returns a 16bit UTF16 code,
      // range 0x10000 - 0xEFFFF (missing below) cannot be tested like that
      // (we could use c.runes.toList()[0] instead of c.codeUnitAt(0),
      // but it might impact performance).
      if ((code >= 0x41 && code <= 0x5A) || (code >= 0x61 && code <= 0x7A) ||
          (code >= 0xC0 && code <= 0xD6) || (code >= 0xD8 && code <= 0xF6) ||
          (code >= 0xF8 && code <= 0x2FF) || (code >= 0x370 && code <= 0x37D) ||
          (code >= 0x37F && code <= 0x1FFF) || (code >= 0x200C && code <= 0x200D) ||
          (code >= 0x2070 && code <= 0x218F) || (code >= 0x2C00 && code <= 0x2FEF) ||
          (code >= 0x3001 && code <= 0xD7FF) || (code >= 0xF900 && code <= 0xFDCF) ||
          (code >= 0xFDF0 && code <= 0xFFFD))
        return(new MatchResult.ch(1, c));
    } else if (isany) {
      return(new MatchResult.ch(1, c));
    } else if (exceptions != null) {
      for (String s in exceptions) {
        if (pos + s.length <= doc.length && s == doc.substring(pos, pos + s.length))
          return(null);
      }
      return(new MatchResult.ch(1, c));
    }
    
    return(null);
  }
  
  MatchResult evaluateTokens(List<Token> tokens, int pos) {
    return(null);
  }
  
}
