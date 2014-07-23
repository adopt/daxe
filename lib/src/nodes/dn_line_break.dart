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
 * WYSIWYG line break element (like HTML's br).
 * Jaxe display type: 'br' .
 */
class DNLineBreak extends DaxeNode {
  Tag _b1;
  
  DNLineBreak.fromRef(x.Element elementRef) : super.fromRef(elementRef) {
  }
  
  DNLineBreak.fromNode(x.Node node, DaxeNode parent) : super.fromNode(node, parent) {
  }
  
  @override
  h.Element html() {
    h.Element span;
    span = new h.SpanElement();
    span.id = "$id";
    span.classes.add('dn');
    span.append(new h.BRElement());
    return(span);
  }
  
  @override
  Position firstCursorPositionInside() {
    return(null);
  }
  
  @override
  Position lastCursorPositionInside() {
    return(null);
  }
}
