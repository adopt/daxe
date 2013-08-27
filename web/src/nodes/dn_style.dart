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
 * Style node (changes the style without showing tags).
 * Jaxe display type: 'style'.
 * 
 * parameter: `style`: `GRAS` (bold) | `ITALIQUE` (italic) | `EXPOSANT` (superscript) |
 * `INDICE` (subscript) | `SOULIGNE` (underlined) | `BARRE` (strikethrough) |
 * `PCOULEUR[###,###,###]` (text color) | `FCOULEUR[###,###,###]` (background color)
 * (several styles can be combined with a ';')
 */
class DNStyle extends DaxeNode {
  
  String _style;
  
  DNStyle.fromRef(x.Element elementRef) : super.fromRef(elementRef) {
    _style = doc.cfg.elementParameterValue(elementRef, 'style', null);
  }
  
  DNStyle.fromNode(x.Node node, DaxeNode parent) : super.fromNode(node, parent) {
    _style = doc.cfg.elementParameterValue(ref, 'style', null);
  }
  
  @override
  h.Element html() {
    h.Element span = new h.SpanElement();
    span.id = "$id";
    span.classes.add('dn');
    if (firstChild != null) { // TODO: test for empty sub-styles
      h.SpanElement contents = new h.SpanElement();
      DaxeNode dn = firstChild;
      while (dn != null) {
        contents.append(dn.html());
        dn = dn.nextSibling;
      }
      setStyle(contents);
      span.append(contents);
    } else {
      // let's make this invisible style visible !
      Tag b1 = new Tag(this, Tag.START);
      Tag b2 = new Tag(this, Tag.END);
      span.append(b1.html());
      h.SpanElement contents = new h.SpanElement();
      span.append(contents);
      span.append(b2.html());
    }
    return(span);
  }
  
  @override
  void updateHTMLAfterChildrenChange(List<DaxeNode> changed) {
    super.updateHTML();
  }
  
  @override
  h.Element getHTMLContentsNode() {
    if (firstChild != null)
      return(getHTMLNode().nodes.first);
    else
      return(getHTMLNode().nodes[1]);
  }
  
  /**
   * Removes all style from the current selection
   */
  static void selectionToNormal() {
    Position start = new Position.clone(page.getSelectionStart());
    Position end = new Position.clone(page.getSelectionEnd());
    page.cursor.deSelect();
    start.moveInsideTextNodeIfPossible();
    end.moveInsideTextNodeIfPossible();
    if (start == end)
      return;
    UndoableEdit compound = new UndoableEdit.compound(Strings.get('style.remove_styles'));
    // NOTE: even though selections cannot cut elements, there can be selections like <b>1[<i>23</i>45]6</b>
    DaxeNode ancestor = _commonParent(start.dn, end.dn);
    DaxeNode pp = ancestor.parent;
    while (pp != null) {
      if (pp is DNStyle)
        ancestor = pp;
      pp = pp.parent;
    }
    if (ancestor is DNStyle)
      ancestor = ancestor.parent;
    // ancestor is now a common ancestor between start and end, it is not a style and it has no style ancestor
    Position p1 = new Position(ancestor, 0); // left of the ancestor
    Position p2 = new Position(ancestor, ancestor.offsetLength); // right of the ancestor
    DaxeNode before;
    if (p1 != start)
      before =_cloneBetween(ancestor, p1, start); // clone tree before selection
    else
      before = null;
    DaxeNode inside =_cloneBetween(ancestor, start, end); // clone tree inside selection
    DaxeNode after;
    if (p2 != end)
      after =_cloneBetween(ancestor, end, p2); // clone tree after selection
    else
      after = null;
    _removeStyles(inside);
    if (p1.dn == p2.dn && p1.dn is DNText && p1.dnOffset == 0 && p2.dnOffset == p2.dn.offsetLength) {
      // the text node will disappear, we need another reference
      p1 = new Position(p1.dn.parent, p1.dn.parent.offsetOf(p1.dn));
      p2 = new Position(p2.dn.parent, p2.dn.parent.offsetOf(p2.dn) + 1);
    }
    compound.addSubEdit(doc.removeBetweenEdit(p1, p2)); // remove everything inside ancestor
    if (after != null)
      compound.addSubEdit(doc.insertChildrenEdit(after, p1, checkValidity: false)); // insert right tree at p1
    compound.addSubEdit(doc.insertChildrenEdit(inside, p1, checkValidity: false)); // insert style-less tree at p1
    if (before != null)
      compound.addSubEdit(doc.insertChildrenEdit(before, p1, checkValidity: false)); // insert left tree at p1
    doc.doNewEdit(compound);
  }
  
  /**
   * Returns the two nodes' first common ancestor.
   */
  static DaxeNode _commonParent(DaxeNode dn1, DaxeNode dn2) {
    DaxeNode p1 = dn1;
    while (p1 != null) {
      DaxeNode p2 = dn2;
      while (p2 != null) {
        if (p1 == p2) {
          return(p1);
        }
        if (p2.parent == null)
          break;
        p2 = p2.parent;
      }
      if (p1.parent == null)
        break;
      p1 = p1.parent;
    }
    return(null);
  }
  
  /**
   * Returns a cloned node including everything between p1 and p2 (preserving the styles).
   */
  static DaxeNode _cloneBetween(DaxeNode root, Position p1, Position p2) {
    DaxeNode root2 = new DaxeNode.clone(root);
    for (DaxeNode dn = root2.firstChild; dn != null; dn = root2.firstChild)
      root2.removeChild(dn); // could this shallow clone be optimized without requiring another method for several DaxeNodes ?
    int offset = 0;
    for (DaxeNode dn=root.firstChild; dn != null; dn=dn.nextSibling) {
      Position dnstart = new Position(root, offset);
      Position dnend = new Position(root, offset + 1);
      if (dnstart >= p1 && dnend <= p2) {
        DaxeNode dn2 = new DaxeNode.clone(dn);
        root2.appendChild(dn2);
      } else if (dnend <= p1 || dnstart >= p2) {
        // dn is not included at all in the selection
      } else {
        if (dn is DNText) {
          if (dnstart > p1 && dnend > p2) {
            assert(dn == p2.dn);
            if (0 < p2.dnOffset)
              root2.appendChild(new DNText(dn.nodeValue.substring(0, p2.dnOffset)));
          } else if (dnstart < p1 && dnend < p2) {
            assert(dn == p1.dn);
            if (p1.dnOffset < dn.offsetLength)
              root2.appendChild(new DNText(dn.nodeValue.substring(p1.dnOffset, dn.offsetLength)));
          } else {
            // dnstart <= p1 && dnend >= p2
            int offset1;
            if (p1.dn == dn)
              offset1 = p1.dnOffset;
            else
              offset1 = 0;
            int offset2;
            if (p2.dn == dn)
              offset2 = p2.dnOffset;
            else
              offset2 = dn.offsetLength;
            if (offset1 < offset2)
              root2.appendChild(new DNText(dn.nodeValue.substring(offset1, offset2)));
          }
        } else {
          DaxeNode dn2 = _cloneBetween(dn, p1, p2);
          if ((dn2 is! DNStyle && dn2 is! DNText) || _getText(dn2) != '')
            root2.appendChild(dn2);
        }
      }
      offset++;
    }
    return(root2);
  }
  
  /**
   * Returns the concatenated descendant text nodes as a String.
   */
  static String _getText(DaxeNode dn) {
    if (dn is DNText)
      return(dn.nodeValue);
    else if (dn.firstChild != null) {
      StringBuffer sb = new StringBuffer();
      for (DaxeNode n = dn.firstChild; n != null; n = n.nextSibling) {
        sb.write(_getText(n));
      }
      return(sb.toString());
    } else
      return('');
  }
  
  /**
   * Removes all DNStyle descendants from the parent, keeping their contents
   * (no validity check).
   */
  static _removeStyles(DaxeNode parent) {
    for (DaxeNode dn = parent.firstChild; dn != null; ) {
      if (dn is DNStyle) {
        DaxeNode first = dn.firstChild;
        for (DaxeNode dn2 = dn.firstChild; dn2 != null; ) {
          DaxeNode next = dn2.nextSibling;
          parent.insertBefore(dn2, dn);
          dn2 = next;
        }
        parent.removeChild(dn);
        dn = first;
      } else {
        _removeStyles(dn);
        dn = dn.nextSibling;
      }
    }
    parent.normalize();
  }
}
