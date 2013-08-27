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
 * The document node.
 */
class DNDocument extends DaxeNode {
  
  String xmlVersion;
  String xmlEncoding;
  
  DNDocument() : super.fromNodeType(DaxeNode.DOCUMENT_NODE) {
    xmlVersion = '1.0';
    xmlEncoding = 'UTF-8';
  }
  
  DNDocument.fromNode(x.Node node) : super.fromNode(node, null) {
    xmlVersion = (node as x.Document).xmlVersion;
    xmlEncoding = (node as x.Document).xmlEncoding;
  }
  
  @override
  h.Element html() {
    h.DivElement div = new h.DivElement();
    div.id = "$id";
    div.classes.add('dn');
    DaxeNode dn = firstChild;
    while (dn != null) {
      div.append(dn.html());
      dn = dn.nextSibling;
    }
    if (lastChild == null || lastChild.nodeType == DaxeNode.TEXT_NODE)
      div.appendText('\n');
    return(div);
  }
  
  @override
  x.Node toDOMNode(x.Document domDocument) {
    domDocument.xmlVersion = xmlVersion;
    domDocument.xmlEncoding = xmlEncoding;
    for (DaxeNode dn=firstChild; dn != null; dn=dn.nextSibling) {
      domDocument.appendChild(dn.toDOMNode(domDocument));
    }
    return(domDocument);
  }
}
