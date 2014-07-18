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
 * A list element displayed inside a start and end bullets.
 * Jaxe display type: 'item'.
 */
class DNItem extends DaxeNode {
  
  DNItem.fromRef(x.Element elementRef) : super.fromRef(elementRef) {
  }
  
  DNItem.fromNode(x.Node node, DaxeNode parent) : super.fromNode(node, parent) {
    fixLineBreaks();
  }
  
  @override
  h.Element html() {
    h.LIElement li = new h.LIElement();
    li.id = "$id";
    li.classes.add('dn');
    h.ImageElement bullet1 = new h.ImageElement(src: 'packages/daxe/images/bullet1.png', width: 13, height: 13);
    bullet1.classes.add('bullet');
    List<x.Element> attRefs = doc.cfg.elementAttributes(ref);
    if (attRefs != null && attRefs.length > 0)
      bullet1.onClick.listen((h.MouseEvent event) => attributeDialog());
    else {
      bullet1.onDoubleClick.listen((h.MouseEvent event) {
        page.selectNode(this);
        event.preventDefault();
        event.stopPropagation();
      });
    }
    li.append(bullet1);
    h.SpanElement contents = new h.SpanElement();
    DaxeNode dn = firstChild;
    while (dn != null) {
      contents.append(dn.html());
      dn = dn.nextSibling;
    }
    li.append(contents);
    h.ImageElement bullet2 = new h.ImageElement(src: 'packages/daxe/images/bullet2.png', width: 13, height: 13);
    bullet2.classes.add('bullet');
    if (attRefs != null && attRefs.length > 0)
      bullet2.onClick.listen((h.MouseEvent event) => attributeDialog());
    else {
      bullet2.onDoubleClick.listen((h.MouseEvent event) {
        page.selectNode(this);
        event.preventDefault();
        event.stopPropagation();
      });
    }
    li.append(bullet2);
    return(li);
  }
  
  @override
  h.Element getHTMLContentsNode() {
    return(getHTMLNode().nodes[1]);
  }
  
  @override
  bool newlineAfter() {
    return(true);
  }
}
