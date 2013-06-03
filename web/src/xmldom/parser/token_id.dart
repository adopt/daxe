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

class TokenId extends TokenItem {
  
  String id;
  
  TokenId(this.id);
  
  MatchResult evaluateString(String doc, int pos) {
    return(null);
  }
  
  MatchResult evaluateTokens(List<Token> tokens, int pos) {
    if (tokens[pos].id == id)
      return(new MatchResult.tk(1, [tokens[pos]]));
    else
      return(null);
  }
  
}
