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

/**
 * Text parser engine. Parsing returns a list of token created from an input string or list of tokens
 * by applying a list of rules.
 * The rules can use states (variables) as conditions to execute, and change the states when they are applied.
 * A character in an input string is the equivalent of a token in an input list of tokens:
 * characters could be turned into tokens to simplify the implementation if we didn't worry about performance.
 */
class Engine {
  
  List<TokenRule> rules;
  HashMap<String, bool> states;
  
  Engine(this.rules) {
    for (TokenRule rule in rules)
      rule.engine = this;
  }
  
  List<Token> parseString(String s) {
    List<Token> result = new List<Token>();
    states = new HashMap<String, bool>();
    int pos = 0;
    while (pos < s.length) {
      int pos1 = pos;
      for (TokenRule rule in rules) {
        MatchResult match = rule.evaluateString(s, pos);
        if (match == null)
          continue;
        pos += match.nbMatched;
        if (match.tokens.length > 0) {
          assert(match.nbMatched != 0); // there is a match but no token is consumed by the rule: this could lead to an endless loop
          result.addAll(match.tokens);
          break; // continue with first rule
        }
      }
      if (pos1 == pos) {
        // TODO: add line information
        throw new DOMException("parser blocking at character $pos: ${s.substring(pos, min(pos + 10, s.length))}");
      }
    }
    return(result);
  }
  
  List<Token> parseTokens(List<Token> tokens) {
    List<Token> result = new List<Token>();
    states = new HashMap<String, bool>();
    int pos = 0;
    while (pos < tokens.length) {
      int pos1 = pos;
      for (TokenRule rule in rules) {
        MatchResult match = rule.evaluateTokens(tokens, pos);
        if (match == null)
          continue;
        pos += match.nbMatched;
        if (match.tokens.length > 0) {
          assert(match.nbMatched != 0); // there is a match but no token is consumed by the rule: this is wrong
          result.addAll(match.tokens);
          break; // continue with first rule
        }
      }
      if (pos1 == pos) {
        // TODO: add line information
        throw new DOMException("parser blocking at character ${tokens[pos].position}");
      }
    }
    return(result);
  }
  
  bool checkConditions(TokenRule rule) {
    if (rule.conditions == null)
      return(true);
    bool stop = false;
    for (StateCondition condition in rule.conditions) {
      bool current = states[condition.name];
      if (current == null)
        current = false; // false by default
      if (current != condition.value)
        return(false);
    }
    return(true);
  }
  
  void changeStates(TokenRule rule) {
    if (rule.changes == null)
      return;
    for (StateChange change in rule.changes) {
      states[change.name] = change.value; 
    }
  }
}
