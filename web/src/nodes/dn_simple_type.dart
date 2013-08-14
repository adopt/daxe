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
 * An element with a WXS simple type, displayed according to its type (checkbox, select or input field).
 * Jaxe display type: 'typesimple' (simple type).
 */
class DNSimpleType extends DaxeNode {
  SimpleTypeControl control;
  
  DNSimpleType.fromRef(x.Element elementRef) : super.fromRef(elementRef) {
  }
  
  DNSimpleType.fromNode(x.Node node, DaxeNode parent) : super.fromNode(node, parent, createChildren: false) {
    // manual children addition in order to use ParentUpdatingDNText instead of DNText
    // whenever the text is changed (for instance with find/replace or undo/redo),
    // DNSimpleType.updateHTML is called in order to update the control
    if (node.childNodes != null) {
      DaxeNode prev = null;
      for (x.Node n in node.childNodes) {
        DaxeNode dn;
        if (n.nodeType == x.Node.TEXT_NODE)
          dn = new ParentUpdatingDNText.fromNode(n, this);
        else
          dn = NodeFactory.createFromNode(n, this);
        if (prev == null)
          firstChild = dn;
        else
          prev.nextSibling = dn;
        prev = dn;
      }
    }
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
      page.selectNode(this);
      event.preventDefault();
      event.stopPropagation();
    });
    return(span);
  }
  
  void changeValue() {
    String value = control.getValue();
    UndoableEdit edit = new UndoableEdit.compound(Strings.get('form.text_edition'));
    /* this was causing problems with undo/redo on DNText (the text was not updated)
       (same problem as DNForm.changeElementValue())
       This is solved by using ParentUpdatingDNText
    if (value != '')
      edit.addSubEdit(new UndoableEdit.insertString(new Position(this, 0), value, updateDisplay: false));
    if (firstChild is DNText) {
      edit.addSubEdit(new UndoableEdit.removeString(new Position(firstChild, value.length),
          firstChild.nodeValue.length, updateDisplay: false));
    }
    */
    //this is using ParentUpdatingDNText nodes instead of DNText to avoid the problem
    if (firstChild is DNText)
      edit.addSubEdit(new UndoableEdit.removeNode(firstChild, updateDisplay: false));
    if (value != '')
      edit.addSubEdit(new UndoableEdit.insertNode(new Position(this, 0), new ParentUpdatingDNText(value), updateDisplay: false));
    doc.doNewEdit(edit);
    control.focus();
  }
  
  @override
  void updateHTML() {
    String value;
    if (firstChild != null)
      value = firstChild.nodeValue;
    else
      value = '';
    if (control.getValue() != value)
      control.setValue(value);
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


