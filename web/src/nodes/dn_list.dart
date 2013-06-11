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

class DNList extends DaxeNode {
  Tag _b1, _b2;
  x.Element _itemref;
  
  DNList.fromRef(x.Element elementRef) : super.fromRef(elementRef) {
    init();
    // this is causing problems with paste, appending an item
    // after a new insert would require a new method in DaxeNode...
    //if (_itemref != null)
    //  appendChild(new DNItem.fromRef(_itemref));
  }
  
  DNList.fromNode(x.Node node, DaxeNode parent) : super.fromNode(node, parent) {
    init();
    fixLineBreaks();
  }
  
  void init() {
    _b1 = new Tag(this, Tag.START);
    _b2 = new Tag(this, Tag.END);
    List<x.Element> subElements = doc.cfg.subElements(ref);
    if (subElements.length > 0)
      _itemref = subElements[0];
  }
  
  @override
  h.Element html() {
    h.DivElement div = new h.DivElement();
    div.id = "$id";
    div.classes.add('dn');
    if (!valid)
      div.classes.add('invalid');
    div.append(_b1.html());
    h.UListElement list = new h.UListElement();
    //list.classes.add('indent');
    list.classes.add('list');
    DaxeNode dn = firstChild;
    while (dn != null) {
      list.append(dn.html());
      dn = dn.nextSibling;
    }
    div.append(list);
    div.append(_b2.html());
    return(div);
  }
  
  /*@override
  Position firstCursorPositionInside() {
    if (firstChild == null) {
      return(null);
    }
    return(new Position(firstChild, 0));
  }
  
  @override
  Position lastCursorPositionInside() {
    if (lastChild == null) {
      return(null);
    }
    return(new Position(lastChild, lastChild.offsetLength));
  }*/
  
  @override
  h.Element getHTMLContentsNode() {
    return(getHTMLNode().nodes[1]);
  }
  
  @override
  bool newlineAfter() {
    return(true);
  }
  
  @override
  bool newlineInside() {
    return(true);
  }
}
