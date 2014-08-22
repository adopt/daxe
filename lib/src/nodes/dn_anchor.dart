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
 * HTML anchor, assumed to have name and href attributes.
 * Jaxe display type: 'anchor'.
 */
class DNAnchor extends DaxeNode {
  String _nameAtt;
  String _hrefAtt;
  
  DNAnchor.fromRef(x.Element elementRef) : super.fromRef(elementRef) {
    _nameAtt = doc.cfg.elementParameterValue(ref, 'nameAtt', 'name');
    _hrefAtt = doc.cfg.elementParameterValue(ref, 'hrefAtt', 'href');
  }
  
  DNAnchor.fromNode(x.Node node, DaxeNode parent) : super.fromNode(node, parent) {
    _nameAtt = doc.cfg.elementParameterValue(ref, 'nameAtt', 'name');
    _hrefAtt = doc.cfg.elementParameterValue(ref, 'hrefAtt', 'href');
  }
  
  @override
  h.Element html() {
    h.SpanElement span = new h.SpanElement();
    span.id = "$id";
    span.classes.add('dn');
    span.classes.add('anchor');
    if (!valid)
      span.classes.add('invalid');
    if (firstChild == null) {
      h.ImageElement img = new h.ImageElement();
      img.src = 'packages/daxe/images/toolbar/anchor.png';
      img.width = 16;
      img.height = 16;
      if (getAttribute(_nameAtt) != null)
        img.title = getAttribute(_nameAtt);
      img.onClick.listen((h.MouseEvent event) => attributeDialog());
      span.append(img);
    } else {
      if (getAttribute(_hrefAtt) != null)
        span.title = getAttribute(_hrefAtt);
      DaxeNode dn = firstChild;
      while (dn != null) {
        span.append(dn.html());
        dn = dn.nextSibling;
      }
      span.onDoubleClick.listen((h.MouseEvent event) => attributeDialog());
    }
    return(span);
  }
  
  @override
  void updateHTMLAfterChildrenChange(List<DaxeNode> changed) {
    super.updateHTML();
  }
  
  @override
  bool get noDelimiter {
    return(true);
  }
  
  static x.Element aRef() {
    return(doc.cfg.firstElementWithType('anchor'));
  }
  
  /**
   * Adds a link at cursor location.
   */
  static void addLink() {
    Position start = page.getSelectionStart();
    if (start == page.getSelectionEnd()) {
      if (start.dn is DNText) {
        // select word around cursor position
        String text = start.dn.nodeValue;
        int offset = start.dnOffset;
        int p1 = offset;
        if (p1 > 0)
          p1--;
        int p2 = offset;
        while (p1 > 0 && text[p1] != ' ')
          p1--;
        while (p2 < text.length && text[p2] != ' ')
          p2++;
        page.cursor.setSelection(new Position(start.dn, p1), new Position(start.dn, p2));
      }
    }
    doc.insertNewNode(aRef(), 'element');
  }
  
  /**
   * Adds an anchor at cursor location.
   */
  static void addAnchor() {
    doc.insertNewNode(aRef(), 'element');
  }
  
  /**
   * Removes a link at cursor location.
   */
  static void removeLink() {
    Position start = page.getSelectionStart();
    DaxeNode parent = start.dn;
    while (parent != null) {
      if (parent is DNAnchor)
        break;
      parent = parent.parent;
    }
    if (parent == null)
      return;
    DNAnchor anchor = parent;
    if (anchor.firstChild == null) {
      doc.removeNode(anchor);
      return;
    }
    parent = anchor.parent;
    UndoableEdit edit = new UndoableEdit.compound(Strings.get('undo.remove_element'));
    DaxeNode content = doc.cloneBetween(new Position(anchor, 0), new Position(anchor, anchor.offsetLength));
    edit.addSubEdit(new UndoableEdit.removeNode(anchor));
    Position insertPos;
    if (anchor.previousSibling is DNText)
      insertPos = new Position(anchor.previousSibling, anchor.previousSibling.offsetLength);
    else
      insertPos = new Position(parent, parent.offsetOf(anchor));
    edit.addSubEdit(doc.insertChildrenEdit(content, insertPos, checkValidity:false));
    doc.doNewEdit(edit);
    page.updateAfterPathChange();
  }
  
}
