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

class DNSimpleType extends DaxeNode {
  SimpleTypeControl control;
  
  DNSimpleType.fromRef(x.Element elementRef) : super.fromRef(elementRef) {
  }
  
  DNSimpleType.fromNode(x.Node node, DaxeNode parent) : super.fromNode(node, parent) {
  }
  
  @override
  h.Element html() {
    h.Element span;
    span = new h.SpanElement();
    span.id = "$id";
    span.classes.add('dn');
    span.classes.add('simple_type');
    List<x.Element> attRefs = doc.cfg.elementAttributes(ref);
    if (attRefs != null && attRefs.length > 0) {
      h.ImageElement img = new h.ImageElement(src:'images/attributes.png', width:16, height:15);
      img.onClick.listen((h.MouseEvent event) => attributeDialog());
      span.append(img);
    }
    String title = doc.cfg.elementTitle(ref);
    span.append(new h.Text(title));
    
    String value;
    if (firstChild != null)
      value = firstChild.nodeValue;
    else
      value = '';
    control = new SimpleTypeControl.forElement(ref, value, valueChanged: () => changeValue());
    span.append(control.html());
    
    span.onDoubleClick.listen((h.MouseEvent event) {
      // select the element
      int offset = parent.offsetOf(this);
      Position start = new Position(parent, offset);
      Position end = new Position(parent, offset+1);
      page.cursor.setSelection(start, end);
      event.preventDefault();
      event.stopPropagation();
    });
    return(span);
  }
  
  void changeValue() {
    String value = control.getValue();
    UndoableEdit edit = new UndoableEdit.compound(Strings.get('form.text_edition'));
    /*if (firstChild is DNText)
      edit.addSubEdit(new UndoableEdit.removeNode(firstChild));
    if (value != '')
      edit.addSubEdit(new UndoableEdit.insertString(new Position(this, 0), value));*/
    // another way of doing it, to avoid updateHTML on this :
    if (value != '')
      edit.addSubEdit(new UndoableEdit.insertString(new Position(this, 0), value));
    if (firstChild is DNText) {
      edit.addSubEdit(new UndoableEdit.removeString(new Position(firstChild, value.length),
          firstChild.nodeValue.length));
    }
    doc.doNewEdit(edit);
    control.focus();
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


