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
    //TODO: handle sub-styles
    Position start = new Position.clone(page.getSelectionStart());
    Position end = new Position.clone(page.getSelectionEnd());
    page.cursor.deSelect();
    start.moveInsideTextNodeIfPossible();
    end.moveInsideTextNodeIfPossible();
    if (start == end)
      return;
    UndoableEdit compound = new UndoableEdit.compound(Strings.get('style.remove_styles'));
    if (start.dn == end.dn && start.dn is DNText) {
      // within a single style
      DaxeNode dn = start.dn;
      if (dn.parent is DNStyle) {
        if (start.dnOffset == 0 && end.dnOffset == dn.offsetLength) {
          String text = dn.nodeValue;
          DaxeNode styleParent = dn.parent.parent;
          int styleOffset = styleParent.offsetOf(dn.parent);
          compound.addSubEdit(new UndoableEdit.insertString(new Position(styleParent, styleOffset), text));
          compound.addSubEdit(new UndoableEdit.removeNode(dn.parent));
        } else {
          String textBefore = dn.nodeValue.substring(0, start.dnOffset);
          String text = dn.nodeValue.substring(start.dnOffset, end.dnOffset);
          String textAfter = dn.nodeValue.substring(end.dnOffset);
          DaxeNode styleParent = dn.parent.parent;
          int offset = styleParent.offsetOf(dn.parent) + 1;
          if (textBefore != '') {
            DNStyle newStyle = NodeFactory.create(dn.parent.ref, 'element');
            newStyle.appendChild(new DNText(textBefore));
            compound.addSubEdit(new UndoableEdit.insertNode(new Position(styleParent, offset), newStyle));
            offset++;
          }
          if (textAfter != '') {
            DNStyle newStyle = NodeFactory.create(dn.parent.ref, 'element');
            newStyle.appendChild(new DNText(textAfter));
            compound.addSubEdit(new UndoableEdit.insertNode(new Position(styleParent, offset), newStyle));
          }
          if (text != '') {
            compound.addSubEdit(new UndoableEdit.insertString(new Position(styleParent, offset), text));
          }
          compound.addSubEdit(new UndoableEdit.removeNode(dn.parent));
        }
      }
    } else {
      /* this cannot be tested yet, because selections are not allowed to cut elements
      // change the beginning
      if (start.dn is DNText && start.dn.parent is DNStyle && start.dnOffset < start.dn.offsetLength) {
        String text = start.dn.nodeValue.substring(start.dnOffset);
        if (start.dnOffset == 0)
          compound.addSubEdit(new UndoableEdit.removeNode(start.dn.parent));
        else
          compound.addSubEdit(new UndoableEdit.removeString(start, text.length));
        DaxeNode styleParent = start.dn.parent.parent;
        int styleOffset = styleParent.offsetOf(start.dn.parent);
        compound.addSubEdit(new UndoableEdit.insertString(new Position(styleParent, styleOffset+1), text));
      }
      // change the end
      if (end.dn is DNText && end.dn.parent is DNStyle && end.dnOffset > 0) {
        String text = end.dn.nodeValue.substring(0, end.dnOffset);
        if (start.dnOffset == start.dn.offsetLength)
          compound.addSubEdit(new UndoableEdit.removeNode(start.dn.parent));
        else
          compound.addSubEdit(new UndoableEdit.removeString(new Position(end.dn, 0), text.length));
        DaxeNode styleParent = end.dn.parent.parent;
        compound.addSubEdit(new UndoableEdit.insertString(new Position(styleParent, 0), text));
      }
      */
      // change the nodes in between
      DaxeNode first;
      if (start.dn is DNText) {
        if (start.dn.parent is DNStyle)
          first = start.dn.parent.nextSibling;
        else
          first = start.dn.nextSibling;
      } else if (start.dn is DNStyle)
        first = start.dn.nextSibling;
      else
        first = start.dn.childNodes[start.dnOffset];
      DaxeNode last;
      if (end.dn is DNText) {
        if (end.dn.parent is DNStyle)
          last = end.dn.parent.previousSibling;
        else
          last = end.dn.previousSibling;
      } else if (end.dn is DNStyle)
        last = end.dn.previousSibling;
      else {
        if (end.dnOffset < end.dn.offsetLength)
          last = end.dn.childNodes[end.dnOffset].previousSibling;
        else
          last = end.dn.lastChild;
      }
      // reverse order to avoid text merge problems
      for (DaxeNode dn = last; dn != null; dn = dn.previousSibling) {
        nodeToNormal(compound, dn);
        if (dn == first)
          break;
      }
    }
    doc.doNewEdit(compound);
  }
  
  static void nodeToNormal(UndoableEdit edit, DaxeNode dn) {
    if (dn is DNStyle) {
      String text = _getText(dn);
      Position pos = new Position(dn.parent, dn.parent.offsetOf(dn));
      if (text != null && text != '')
        edit.addSubEdit(new UndoableEdit.insertString(pos, text));
      edit.addSubEdit(new UndoableEdit.removeNode(dn));
    } else {
      for (DaxeNode child = dn.lastChild; child != null; child = child.previousSibling)
        nodeToNormal(edit, child);
    }
  }
  
  static String _getText(DaxeNode dn) {
    if (dn is DNText)
      return(dn.nodeValue);
    else if (dn.firstChild != null)
      return(_getText(dn.firstChild));
    else
      return('');
  }
}
