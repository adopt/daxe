/*
  This file is part of LONCAPA-Daxe.

  LONCAPA-Daxe is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  LONCAPA-Daxe is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with Daxe.  If not, see <http://www.gnu.org/licenses/>.
*/

part of nodes;

/**
 * HTML horizontal rule
 * Jaxe display type: 'hr'.
 */
class DNHr extends DaxeNode {
  
  DNHr.fromRef(x.Element elementRef) : super.fromRef(elementRef) {
  }
  
  DNHr.fromNode(x.Node node, DaxeNode parent) : super.fromNode(node, parent) {
  }
  
  @override
  h.Element html() {
    h.DivElement div = new h.DivElement();
    div.id = "$id";
    div.classes.add('dn');
    div.classes.add('hr');
    List<x.Element> attRefs = doc.cfg.elementAttributes(ref);
    if (attRefs != null && attRefs.length > 0) {
      div.onClick.listen((h.MouseEvent event) => attributeDialog());
    }
    div.append(new h.HRElement());
    return(div);
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
