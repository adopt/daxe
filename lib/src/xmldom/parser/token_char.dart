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
  
  MatchResult evaluateString(String doc, int pos) {
    String c = doc[pos];
    
    if (character != null) {
      if (c == character)
        return(new MatchResult.ch(1, c));
    } else if (isdigit) {
      if ('0123456789'.contains(c)) {
        return(new MatchResult.ch(1, c));
      }
    } else if (isletter) {
      // FIXME: more letters are acceptable
      if ('abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'.contains(c))
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
