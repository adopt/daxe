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

class Token {
  
  String id;
  String matchedString;
  List<Token> matchedTokens;
  Object data;
  int position;
  
  
  Token.characters(this.id, this.matchedString, this.position);
  
  Token.tokens(this.id, this.matchedTokens, this.position);
  
  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write("[$id");
    if (matchedString != null)
      sb.write(" $matchedString");
    else {
      for (Token token in matchedTokens) {
        sb.write(' ');
        sb.write(token);
      }
    }
    sb.write(']');
    return(sb.toString());
  }
}
