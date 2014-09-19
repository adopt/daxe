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
 * A WYSIWYG list item to use with DNWList.
 * Jaxe display type: 'witem'.
 */
class DNWItem extends DaxeNode {
  
  DNWItem.fromRef(x.Element elementRef) : super.fromRef(elementRef) {
  }
  
  DNWItem.fromNode(x.Node node, DaxeNode parent) : super.fromNode(node, parent) {
    fixLineBreaks();
  }
  
  @override
  h.Element html() {
    h.LIElement li = new h.LIElement();
    li.id = "$id";
    li.classes.add('dn');
    DaxeNode dn = firstChild;
    while (dn != null) {
      li.append(dn.html());
      dn = dn.nextSibling;
    }
    return(li);
  }
  
  @override
  h.Element getHTMLContentsNode() {
    return(getHTMLNode());
  }
  
  @override
  bool newlineAfter() {
    return(true);
  }
}
