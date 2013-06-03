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

class DNForm extends DaxeNode {
  
  List<x.Element> childrenRefs;
  List<x.Element> attRefs;
  HashMap<String, SimpleTypeControl> attributeControls;
  bool simpleField;
  SimpleTypeControl control; // used for simple fields only
  
  DNForm.fromRef(x.Element elementRef) : super.fromRef(elementRef) {
    init();
  }
  
  DNForm.fromNode(x.Node node, DaxeNode parent) : super.fromNode(node, parent) {
    init();
  }
  
  void init() {
    childrenRefs = doc.cfg.subElements(ref);
    attRefs = doc.cfg.elementAttributes(ref);
    simpleField = (childrenRefs.length == 0 && attRefs.length == 0);
    
    if (!simpleField) {
      // remove all text nodes:
      List<DaxeNode> children = childNodes;
      for (DaxeNode dn in children) {
        if (dn is DNText)
          removeChild(dn);
      }
    }
    
    if (attRefs.length > 0)
      attributeControls = new HashMap<String, SimpleTypeControl>();
    
    addMissingChildren();
  }
  
  void addMissingChildren() {
    DaxeNode currentChild = null;
    for (x.Element childRef in childrenRefs) {
      bool found = false;
      for (DaxeNode dn in childNodes) {
        if (dn.ref == childRef) {
          found = true;
          currentChild = dn;
        } 
      }
      if (!found) {
        DaxeNode dn = NodeFactory.create(childRef);
        // note: this is not undoable, but will not be serialized if no content is added
        if (currentChild != null)
          insertAfter(dn, currentChild);
        else if (firstChild != null)
          insertBefore(dn, firstChild);
        else
          appendChild(dn);
        currentChild = dn;
      }
    }
  }
  
  @override
  h.Element html() {
    h.ButtonElement bHelp = new h.ButtonElement();
    bHelp.attributes['type'] = 'button';
    bHelp.classes.add('help');
    bHelp.value = '?';
    bHelp.text = '?';
    bHelp.onClick.listen((h.Event event) => (new HelpDialog.Element(ref)).show());
    
    if (simpleField) {
      h.TableRowElement tr = new h.TableRowElement();
      tr.id = "$id";
      tr.classes.add('dn');
      
      h.TableCellElement td = new h.TableCellElement();
      td.append(bHelp);
      tr.append(td);
      
      td = new h.TableCellElement();
      td.text = doc.cfg.elementTitle(ref);
      if (doc.cfg.requiredElement(parent.ref, ref))
        td.classes.add('required');
      else
        td.classes.add('optional');
      tr.append(td);
      
      td = new h.TableCellElement();
      /*
      td.classes.add('form_field');
      if (firstChild != null)
        td.append(firstChild.html());
      */
      // with a SimpleTypeControl instead, for validation:
      String value;
      if (firstChild != null)
        value = firstChild.nodeValue;
      else
        value = '';
      control = new SimpleTypeControl.forElement(ref, value, valueChanged: () => changeElementValue());
      td.append(control.html());

      tr.append(td);
      
      if (parent is DNForm)
        (parent as DNForm).addPlusMinusButtons(tr, this);
      
      return(tr);
      
    } else {
      h.DivElement div = new h.DivElement();
      div.id = "$id";
      div.classes.add('dn');
      div.classes.add('form');
      
      h.SpanElement spanTitle = new h.SpanElement();
      spanTitle.classes.add('form_title');
      spanTitle.append(bHelp);
      spanTitle.appendText(' ');
      spanTitle.appendText(doc.cfg.elementTitle(ref));
      if (doc.cfg.requiredElement(parent.ref, ref))
        spanTitle.classes.add('required');
      else
        spanTitle.classes.add('optional');
      div.append(spanTitle);
      
      h.TableElement table = new h.TableElement();
      for (x.Element refAttr in attRefs) {
        table.append(attributeHTML(refAttr));
      }
      for (x.Element childRef in childrenRefs) {
        for (DaxeNode dn in childNodes) {
          if (dn.ref == childRef) {
            dn.userCannotRemove = true;
            addChildHTML(table, dn);
          } 
        }
      }
      div.append(table);
      
      return(div);
    }
  }
  
  void changeElementValue() {
    String value = control.getValue();
    UndoableEdit edit = new UndoableEdit.compound(Strings.get('form.text_edition'));
    /*
    To avoid updateHTML() on this node at undo, use :
    (problem: the DNText cannot be updated at undo)
    if (value != '')
      edit.addSubEdit(new UndoableEdit.insertString(new Position(this, 0), value, updateDisplay: false));
    if (firstChild is DNText) {
      edit.addSubEdit(new UndoableEdit.removeString(new Position(firstChild, value.length),
          firstChild.nodeValue.length, updateDisplay: false));
    }*/
    if (firstChild is DNText)
      edit.addSubEdit(new UndoableEdit.removeNode(firstChild, updateDisplay: false));
    if (value != '')
      edit.addSubEdit(new UndoableEdit.insertNode(new Position(this, 0), new DNText(value), updateDisplay: false));
    doc.doNewEdit(edit);
    updateButtons();
  }
  
  @override
  h.Element getHTMLContentsNode() {
    if (simpleField) {
      return(getHTMLNode().nodes[2]); // 3rd td
    } else {
      return(getHTMLNode().nodes[1]); // the table
    }
  }
  
  h.TableRowElement attributeHTML(x.Element refAttr) {
    String name = doc.cfg.attributeQualifiedName(ref, refAttr);
    h.TableRowElement tr = new h.TableRowElement();
    
    h.TableCellElement td = new h.TableCellElement();
    h.ButtonElement bHelp = new h.ButtonElement();
    bHelp.attributes['type'] = 'button';
    bHelp.classes.add('help');
    bHelp.value = '?';
    bHelp.text = '?';
    bHelp.onClick.listen((h.Event event) => (new HelpDialog.Attribute(refAttr, ref)).show());
    td.append(bHelp);
    tr.append(td);
    
    td = new h.TableCellElement();
    td.text = doc.cfg.attributeTitle(ref, refAttr);
    if (doc.cfg.requiredAttribute(ref, refAttr))
      td.classes.add('required');
    else
      td.classes.add('optional');
    tr.append(td);
    
    td = new h.TableCellElement();
    String value = getAttribute(name);
    String defaultValue = doc.cfg.defaultAttributeValue(refAttr);
    if (value == null) {
      if (defaultValue != null)
        value = defaultValue;
      else
        value = '';
    }
    SimpleTypeControl attributeControl;
    attributeControl = new SimpleTypeControl.forAttribute(ref, refAttr, value,
        valueChanged: () => changeAttributeValue(refAttr, attributeControl), catchUndo: true);
    attributeControls[name] = attributeControl;
    td.append(attributeControl.html());
    tr.append(td);
    
    td = new h.TableCellElement();
    tr.append(td);
    
    return(tr);
  }
  
  void changeAttributeValue(x.Element refAttr, SimpleTypeControl attributeControl) {
    String value = attributeControl.getValue();
    String name = doc.cfg.attributeQualifiedName(ref, refAttr);
    String defaultValue = doc.cfg.defaultAttributeValue(refAttr);
    DaxeAttr attr;
    if ((value == '' && defaultValue == null) || value == defaultValue)
      attr = new DaxeAttr(name, null); // remove the attribute
    else if (value != '' || defaultValue != null)
      attr = new DaxeAttr(name, value);
    else
      attr = null;
    if (attr != null)
      doc.doNewEdit(new UndoableEdit.changeAttribute(this, attr, updateDisplay: false));
  }
  
  void addChildHTML(h.TableElement table, DaxeNode dn) {
    h.Element childHTML = dn.html();
    h.TableRowElement tr;
    if (childHTML is h.TableRowElement)
      tr = childHTML;
    else {
      tr = new h.TableRowElement();
      h.TableCellElement td;
      int colspan;
      if (dn is! DNForm) {
        td = new h.TableCellElement();
        h.ButtonElement bHelp = new h.ButtonElement();
        bHelp.attributes['type'] = 'button';
        bHelp.classes.add('help');
        bHelp.value = '?';
        bHelp.text = '?';
        bHelp.onClick.listen((h.Event event) => (new HelpDialog.Element(dn.ref)).show());
        td.append(bHelp);
        tr.append(td);
        colspan = 2;
      } else
        colspan = 3;
      td = new h.TableCellElement();
      td.colSpan = colspan;
      td.append(childHTML);
      tr.append(td);
      addPlusMinusButtons(tr, dn);
    }
    table.append(tr);
  }
  
  void addPlusMinusButtons(h.TableRowElement tr, DaxeNode dn) {
    h.TableCellElement td = new h.TableCellElement();
    if (doc.cfg.getSchema().multipleChildren(ref, dn.ref)) {
      if (dn.nextSibling == null || dn.nextSibling.ref != dn.ref) { // last node with this reference
        if (dn.firstChild != null || dn is! DNForm) {
          h.ButtonElement bPlus = new h.ButtonElement();
          bPlus.attributes['type'] = 'button';
          bPlus.value = '+';
          bPlus.text = '+';
          bPlus.onClick.listen((h.Event event) => addFormChild(dn));
          td.append(bPlus);
        }
      }
      // - minus button only if there is another similar sibling
      if ((dn.previousSibling != null && dn.previousSibling.ref == dn.ref) ||
          (dn.nextSibling != null && dn.nextSibling.ref == dn.ref)) {
        h.ButtonElement bMinus = new h.ButtonElement();
        bMinus.attributes['type'] = 'button';
        bMinus.value = '-';
        bMinus.text = '-';
        bMinus.onClick.listen((h.Event event) => doc.removeNode(dn));
        td.append(bMinus);
      }
    }
    tr.append(td);
  }
  
  void addFormChild(DaxeNode prev) {
    DaxeNode dn = NodeFactory.create(prev.ref);
    doc.insertNode(dn, new Position(this, offsetOf(prev) + 1));
  }
  
  @override
  void attributeDialog([ActionFunction okfct]) {
    if (okfct != null)
      okfct();
  }
  
  @override
  void updateHTML() {
    if (!simpleField) {
      super.updateHTML();
      return;
    }
    
    String value;
    if (firstChild != null)
      value = firstChild.nodeValue;
    else
      value = '';
    if (control.getValue() != value)
      control.setValue(value);
    
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
  
  @override
  void updateAttributes() {
    h.DivElement div = getHTMLNode();
    h.TableElement table = h.query("#$_id>table");
    int i = 0;
    for (x.Element refAttr in attRefs) {
      String name = doc.cfg.attributeQualifiedName(ref, refAttr);
      String value = getAttribute(name);
      String defaultValue = doc.cfg.defaultAttributeValue(refAttr);
      if (value == null) {
        if (defaultValue != null)
          value = defaultValue;
        else
          value = '';
      }
      attributeControls[name].setValue(value);
      i++;
    }
  }

  @override
  bool newlineAfter() {
    return(childrenRefs.length != 0);
  }
  
  @override
  String toString() {
    if (childrenRefs.length == 0)
      return(super.toString());
    
    StringBuffer sb = new StringBuffer();
    sb.write('<');
    if (prefix != null) {
      sb.write(prefix);
      sb.write(':');
    }
    sb.write(localName);
    for (DaxeAttr att in attributes) {
      sb.write(' ');
      sb.write(att.toString());
    }
    sb.write('>');
    sb.write('\n');
    for (DaxeNode dn=firstChild; dn != null; dn=dn.nextSibling) {
      // important change here (empty elements are ignored):
      if (dn.firstChild != null || (dn.attributes != null && dn.attributes.length > 0)) {
        sb.write(dn.toString());
        if (!dn.newlineAfter())
          sb.write('\n');
      }
    }
    sb.write('</');
    if (prefix != null) {
      sb.write(prefix);
      sb.write(':');
    }
    sb.write(localName);
    sb.write('>');
    sb.write('\n');
    return(sb.toString());
  }
}
