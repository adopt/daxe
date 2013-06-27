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

class TokenSequence extends TokenItem {
  
  List<TokenItem> items;
  
  TokenSequence(this.items);
  
  TokenSequence.string(String s) {
    items = new List<TokenItem>();
    for (int i=0; i<s.length; i++)
      items.add(new TokenChar(s[i]));
  }
  
  MatchResult evaluateString(String doc, int pos) {
    StringBuffer sb = null;
    int i = pos;
    for (TokenItem item in items) {
      if (i >= doc.length)
        return(null);
      MatchResult match = item.evaluateString(doc, i);
      if (match == null)
        return(null);
      if (sb == null)
        sb = new StringBuffer();
      sb.write(match.characters);
      i = i + match.nbMatched;
    }
    int nbMatched = i - pos;
    String s;
    if (sb != null)
      s = sb.toString();
    else
      s = '';
    return(new MatchResult.ch(nbMatched, s));
  }
  
  MatchResult evaluateTokens(List<Token> tokens, int pos) {
    List<Token> resultTokens = new List<Token>();
    int i = pos;
    for (TokenItem item in items) {
      if (i >= tokens.length)
        return(null);
      MatchResult match = item.evaluateTokens(tokens, i);
      if (match == null)
        return(null);
      resultTokens.addAll(match.tokens);
      i = i + match.nbMatched;
    }
    int nbMatched = i - pos;
    return(new MatchResult.tk(nbMatched, resultTokens));
  }
  
}
