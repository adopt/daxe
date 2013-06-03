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

class DNProcessingInstruction extends DaxeNode {
  Tag _b1, _b2;
  
  DNProcessingInstruction() : super.fromNodeType(DaxeNode.PROCESSING_INSTRUCTION_NODE) {
    _b1 = new Tag(this, Tag.START);
    _b2 = new Tag(this, Tag.END);
  }
  
  DNProcessingInstruction.fromNode(x.Node node, DaxeNode parent) : super.fromNode(node, parent) {
    _b1 = new Tag(this, Tag.START);
    _b2 = new Tag(this, Tag.END);
  }
  
  @override
  h.Element html() {
    h.Element span;
    span = new h.SpanElement();
    span.attributes['id'] = "$id";
    span.attributes['class'] = 'dn';
    span.append(_b1.html());
    DaxeNode dn = firstChild;
    while (dn != null) {
      span.append(dn.html());
      dn = dn.nextSibling;
    }
    span.append(_b2.html());
    return(span);
  }
  
}


