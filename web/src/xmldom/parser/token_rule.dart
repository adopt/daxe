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

typedef void TokenAction(Token);

class TokenRule extends TokenItem {
  String id;
  List<StateCondition> conditions;
  List<StateChange> changes;
  TokenItem content;
  /** Ignore the tokens matched by this rule */
  bool ignore;
  TokenAction action;
  Engine engine; // defined in Engine constructor
  
  TokenRule(this.id, this.content, {this.conditions:null, this.changes:null, this.ignore:false, this.action:null});
  
  MatchResult evaluateString(String doc, int pos) {
    if (!engine.checkConditions(this))
      return(null); // next rule
    MatchResult match = content.evaluateString(doc, pos);
    if (match == null)
      return(null);
    Token token = new Token.characters(id, match.characters, pos);
    if (action != null)
      action(token);
    engine.changeStates(this);
    List<Token> resultTokens;
    if (ignore)
      resultTokens = new List<Token>();
    else
      resultTokens = [token];
    MatchResult result = new MatchResult.tk(match.nbMatched, resultTokens);
    if (!ignore)
      result.characters = token.matchedString;
    return(result);
  }
  
  MatchResult evaluateTokens(List<Token> tokens, int pos) {
    if (!engine.checkConditions(this))
      return(null);
    MatchResult match = content.evaluateTokens(tokens, pos);
    if (match == null)
      return(null);
    Token token = new Token.tokens(id, match.tokens, match.tokens[0].position);
    if (action != null)
      action(token);
    engine.changeStates(this);
    List<Token> resultTokens;
    if (ignore)
      resultTokens = new List<Token>();
    else
      resultTokens = [token];
    MatchResult result = new MatchResult.tk(match.nbMatched, resultTokens);
    return(result);
  }
  
  String toString() {
    return(id);
  }
}
