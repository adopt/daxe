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
 * XML comment
 */
class DNComment extends DaxeNode {
  Tag _b1, _b2;
  
  DNComment() : super.fromNodeType(DaxeNode.ELEMENT_NODE) {
    _b1 = new Tag(this, Tag.START);
    _b2 = new Tag(this, Tag.END);
  }
  
  DNComment.fromNode(x.Node node, DaxeNode parent) : super.fromNode(node, parent) {
    _b1 = new Tag(this, Tag.START);
    _b2 = new Tag(this, Tag.END);
  }
  
  @override
  h.Element html() {
    h.SpanElement span = new h.SpanElement();
    span.id = "$id";
    span.classes.add('dn');
    span.append(_b1.html());
    h.SpanElement contents = new h.SpanElement();
    DaxeNode dn = firstChild;
    while (dn != null) {
      contents.append(dn.html());
      dn = dn.nextSibling;
    }
    span.append(contents);
    span.append(_b2.html());
    span.style.color = "#808080";
    return(span);
  }
  
  @override
  h.Element getHTMLContentsNode() {
    return(getHTMLNode().nodes[1]);
  }
  
  @override
  x.Node toDOMNode(x.Document domDocument) {
    String data = null;
    if (firstChild != null)
      data = firstChild.nodeValue;
    return(domDocument.createComment(data));
  }
}
