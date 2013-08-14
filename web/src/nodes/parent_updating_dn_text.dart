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

part of nodes;

/**
 * A DNText which triggers a parent node update for each update.
 * (used by DNForm and DNSimpleType)
 * *Warning*: the parent's updateHTML must not call this updateHTML !
 */
class ParentUpdatingDNText extends DNText {
  
  ParentUpdatingDNText(String s) : super(s) {
  }
  
  ParentUpdatingDNText.fromNode(x.Node node, DaxeNode parent) : super.fromNode(node, parent) {
  }
  
  @override
  void updateHTML() {
    parent.updateHTML();
  }
  
}
