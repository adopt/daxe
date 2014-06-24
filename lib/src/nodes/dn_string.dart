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
 * A short text area displayed within a start and end tags.
 * Jaxe display type: 'string'.
 * 
 * * parameter: `style`: as in DNStyle
 */
class DNString extends DaxeNode {
  Tag _b1, _b2;
  
  DNString.fromRef(x.Element elementRef) : super.fromRef(elementRef) {
    _b1 = new Tag(this, Tag.START);
    _b2 = new Tag(this, Tag.END);
  }
  
  DNString.fromNode(x.Node node, DaxeNode parent) : super.fromNode(node, parent) {
    _b1 = new Tag(this, Tag.START);
    _b2 = new Tag(this, Tag.END);
  }
  
  @override
  h.Element html() {
    h.SpanElement span = new h.SpanElement();
    span.id = "$id";
    span.classes.add('dn');
    if (!valid)
      span.classes.add('invalid');
    span.append(_b1.html());
    h.SpanElement contents = new h.SpanElement();
    DaxeNode dn = firstChild;
    while (dn != null) {
      contents.append(dn.html());
      dn = dn.nextSibling;
    }
    setStyle(contents);
    span.append(contents);
    span.append(_b2.html());
    return(span);
  }
  
  @override
  h.Element getHTMLContentsNode() {
    return(getHTMLNode().nodes[1]);
  }
}
