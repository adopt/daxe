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
 * Form field.
 * Jaxe display type: 'champ' (field).
 */
class DNFormField extends DaxeNode {
  bool simpleField;
  SimpleTypeControl control; // used for simple fields only
  
  DNFormField.fromRef(x.Element elementRef) : super.fromRef(elementRef) {
    List<x.Element> childrenRefs = doc.cfg.subElements(ref);
    simpleField = (childrenRefs.length == 0);
  }
  
  DNFormField.fromNode(x.Node node, DaxeNode parent) : super.fromNode(node, parent, createChildren: false) {
    List<x.Element> childrenRefs = doc.cfg.subElements(ref);
    simpleField = (childrenRefs.length == 0);
    // manual children addition in order to use ParentUpdatingDNText instead of DNText
    // whenever the text is changed (for instance with find/replace or undo/redo),
    // DNSimpleType.updateHTML is called in order to update the control
    if (node.childNodes != null) {
      DaxeNode prev = null;
      for (x.Node n in node.childNodes) {
        DaxeNode dn;
        if (simpleField && n.nodeType == x.Node.TEXT_NODE)
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
    h.ButtonElement bHelp = DNForm.makeHelpButton(ref, null);
    
    h.TableRowElement tr = new h.TableRowElement();
    tr.id = "$id";
    tr.classes.add('dn');
    
    h.TableCellElement td = new h.TableCellElement();
    td.classes.add('shrink');
    td.append(bHelp);
    tr.append(td);
    
    td = new h.TableCellElement();
    td.classes.add('shrink');
    td.text = doc.cfg.elementTitle(ref);
    if (doc.cfg.requiredElement(parent.ref, ref))
      td.classes.add('required');
    else
      td.classes.add('optional');
    tr.append(td);
    
    td = new h.TableCellElement();
    td.classes.add('expand');
    if (simpleField) {
      String value;
      if (firstChild != null)
        value = firstChild.nodeValue;
      else
        value = '';
      control = new SimpleTypeControl.forElement(ref, value, valueChanged: () => changeElementValue());
      h.Element ht = control.html();
      ht.id = "content_$id";
      h.TextInputElement input = ht.querySelector('input');
      if (input != null)
        input.classes.add('form_field');
      td.append(ht);
    } else {
      h.DivElement div = new h.DivElement();
      div.id = "content_$id";
      div.classes.add('form_field');
      DaxeNode dn = firstChild;
      while (dn != null) {
        div.append(dn.html());
        dn = dn.nextSibling;
      }
      td.append(div);
    }
    tr.append(td);
    
    if (parent is DNForm)
      (parent as DNForm).addPlusMinusButtons(tr, this);
    
    return(tr);
  }
  
  @override
  h.Element getHTMLContentsNode() {
    return(h.document.getElementById("content_$id"));
  }
  
  void changeElementValue() {
    String value = control.getValue();
    UndoableEdit edit = new UndoableEdit.compound(Strings.get('form.text_edition'));
    if (firstChild is DNText)
      edit.addSubEdit(new UndoableEdit.removeNode(firstChild, updateDisplay: false));
    if (value != '')
      edit.addSubEdit(new UndoableEdit.insertNode(new Position(this, 0), new ParentUpdatingDNText(value), updateDisplay: false));
    doc.doNewEdit(edit);
    updateButtons();
  }
  
  @override
  void updateHTMLAfterChildrenChange(List<DaxeNode> changed) {
    updateHTML();
  }
  
  void updateButtons() {
    if (parent is DNForm) {
      // update plus/minus buttons
      h.TableRowElement tr = getHTMLNode();
      tr.nodes.last.remove();
      (parent as DNForm).addPlusMinusButtons(tr, this);
    }
  }
  
}
