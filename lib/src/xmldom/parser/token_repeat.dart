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

class TokenRepeat extends TokenItem {
  
  static const int ZERO_OR_ONE = 0;
  static const int ZERO_OR_MORE = 1;
  static const int ONE_OR_MORE = 2;
  int repeat;
  TokenItem item;
  
  TokenRepeat.zeroOrOne(this.item) {
    repeat = ZERO_OR_ONE;
  }
  
  TokenRepeat.zeroOrMore(this.item) {
    repeat = ZERO_OR_MORE;
  }
  
  TokenRepeat.oneOrMore(this.item) {
    repeat = ONE_OR_MORE;
  }
  
  MatchResult evaluateString(String doc, int pos) {
    if (repeat == ZERO_OR_ONE) {
      MatchResult match = item.evaluateString(doc, pos);
      if (match == null)
        return(new MatchResult.ch(0, ''));
      else
        return(match);
    }
    StringBuffer sb = null;
    int i = pos;
    while (i < doc.length) {
      MatchResult match = item.evaluateString(doc, i);
      if (match == null)
        break;
      if (sb == null)
        sb = new StringBuffer();
      sb.write(match.characters);
      i = i + match.nbMatched;
    }
    int nbMatched = i - pos;
    if (nbMatched > 0 || repeat == ZERO_OR_MORE) {
      String s;
      if (sb != null)
        s = sb.toString();
      else
        s = '';
      return(new MatchResult.ch(nbMatched, s));
    } else
      return(null);
  }
  
  MatchResult evaluateTokens(List<Token> tokens, int pos) {
    if (repeat == ZERO_OR_ONE) {
      MatchResult match = item.evaluateTokens(tokens, pos);
      if (match == null)
        return(new MatchResult.tk(0, new List<Token>()));
      else
        return(match);
    }
    List<Token> resultTokens = new List<Token>();
    int i = pos;
    while (i < tokens.length) {
      MatchResult match = item.evaluateTokens(tokens, i);
      if (match == null)
        break;
      resultTokens.addAll(match.tokens);
      i = i + match.nbMatched;
    }
    int nbMatched = i - pos;
    if (nbMatched > 0 || repeat == ZERO_OR_MORE)
      return(new MatchResult.tk(nbMatched, resultTokens));
    else
      return(null);
  }
  
}
