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
 * Generic block element.
 * Attributes can be edited directly in it.
 * Buttons can be used to collapse the element and the attribute fields.
 * 
 * Display type: 'block'.
 */
class DNBlock extends DaxeNode {
  
  List<x.Element> attRefs;
  int state; // 0 = editable attributes, 1 = non-editable attributes, 2 = collapsed element
  HashMap<String, SimpleTypeControl> attributeControls;
  HashMap<DaxeAttr, h.TextInputElement> unknownAttributeFields;
  bool hasContent;
  BlockButton bEditable, bNormal, bCollapsed;
  
  
  DNBlock.fromRef(x.Element elementRef) : super.fromRef(elementRef) {
    state = 0;
    init();
  }
  
  DNBlock.fromNode(x.Node node, DaxeNode parent) : super.fromNode(node, parent) {
    state = 1;
    init();
    fixLineBreaks();
  }
  
  void init() {
    attRefs = doc.cfg.elementAttributes(ref);
    if (attRefs != null && attRefs.length > 0)
      attributeControls = new HashMap<String, SimpleTypeControl>();
    unknownAttributeFields = null;
    hasContent = doc.cfg.canContainText(ref) || doc.cfg.subElements(ref).length > 0;
  }
  
  @override
  h.Element html() {
    h.DivElement div = new h.DivElement();
    div.id = "$id";
    div.classes.add('dn');
    if (!valid)
      div.classes.add('invalid');
    div.classes.add('dnblock');
    
    div.append(createHeaderDiv());
    
    if (state != 2 && hasContent) {
      h.DivElement contents = new h.DivElement();
      contents.id = 'contents-' + id;
      contents.classes.add('indent');
      contents.classes.add('dnblock-content');
      setStyle(contents);
      DaxeNode dn = firstChild;
      while (dn != null) {
        contents.append(dn.html());
        dn = dn.nextSibling;
      }
      if (lastChild == null || lastChild.nodeType == DaxeNode.TEXT_NODE)
        contents.appendText('\n');
      //this kind of conditional HTML makes it hard to optimize display updates:
      //we have to override updateHTMLAfterChildrenChange
      // also, it seems that in IE this adds a BR instead of a text node !
      div.append(contents);
    }
    return(div);
  }
  
  h.DivElement createHeaderDiv() {
    h.DivElement headerDiv = new h.DivElement();
    headerDiv.classes.add('dnblock-header');
    if (state == 2 || !hasContent)
      headerDiv.classes.add('without-content-afterwards');
    
    h.DivElement titleDiv = new h.DivElement();
    h.DivElement buttonBox = new h.DivElement();
    buttonBox.classes.add('dnblock-button-box');
    bCollapsed = new BlockButton(Strings.get('block_collapsed'), 'block_collapsed.png',
        () {
      collapsedView();
    }, selected: (state == 2));
    buttonBox.append(bCollapsed.html());
    bNormal = new BlockButton(Strings.get('block_normal'), 'block_normal.png',
        () {
      normalView();
    }, selected: (state == 1));
    buttonBox.append(bNormal.html());
    bool edEnabled = ((attRefs != null && attRefs.length > 0) || attributes.length > 0);
    bEditable = new BlockButton(Strings.get('block_editable'), 'block_editable.png',
        () {
      editableView();
    }, enabled: edEnabled, selected: (state == 0));
    buttonBox.append(bEditable.html());
    titleDiv.append(buttonBox);
    
    h.SpanElement titleSpan = new h.SpanElement();
    titleSpan.classes.add('dnblock-title');
    String title = doc.cfg.elementTitle(ref);
    if (title == null)
      title = nodeName;
    titleSpan.append(new h.Text(title));
    titleSpan.onDoubleClick.listen((h.Event event) {
      page.selectNode(this);
    });
    setupDrag(titleSpan);
    titleDiv.append(titleSpan);
    
    titleDiv.append(makeHelpButton(ref, null));
    headerDiv.append(titleDiv);
    
    h.Element attHTML = createAttributesHTML();
    if (attHTML != null)
      headerDiv.append(attHTML);
    return headerDiv;
  }
  
  /**
   * This can be overriden in subclasses to add fake attributes based on children.
   */
  h.Element createAttributesHTML() {
    if (state == 0) {
      h.TableElement table = new h.TableElement();
      table.classes.add('expand');
      for (x.Element refAttr in attRefs) {
        if (doc.cfg.attributeQualifiedName(this, ref, refAttr) != 'xml:space')
          table.append(attributeHTML(refAttr));
      }
      for (DaxeAttr att in attributes) {
        bool found = false;
        for (x.Element attref in attRefs) {
          if (att.localName == doc.cfg.attributeName(attref) &&
              att.namespaceURI == doc.cfg.attributeNamespace(attref)) {
            found = true;
            break;
          }
        }
        if (!found) {
          table.append(unknownAttributeHTML(att));
        }
      }
      return table;
    } else if (state == 1) {
      h.DivElement attDiv = new h.DivElement();
      attDiv.classes.add('dnblock-attributes');
      for (DaxeAttr att in attributes) {
        attDiv.append(new h.Text(" "));
        h.Element att_name = new h.SpanElement();
        att_name.attributes['class'] = 'attribute_name';
        att_name.text = att.localName;
        attDiv.append(att_name);
        attDiv.append(new h.Text("="));
        h.Element att_val = new h.SpanElement();
        att_val.attributes['class'] = 'attribute_value';
        att_val.text = att.value;
        attDiv.append(att_val);
      }
      attDiv.onClick.listen((h.MouseEvent event) {
        editableView();
      });
      return attDiv;
    }
    return null;
  }
  
  @override
  void updateHTMLAfterChildrenChange(List<DaxeNode> changed) {
    super.updateHTMLAfterChildrenChange(changed);
    if (hasContent && state != 2) {
      h.DivElement contents = getHTMLContentsNode();
      if (contents != null && contents.nodes.length > 0) {
        h.Node hn = contents.nodes.first;
        while (hn != null) {
          h.Node next = hn.nextNode;
          if (hn is h.Text || hn is h.BRElement)
            hn.remove();
          hn = next;
        }
      }
      if (lastChild == null || lastChild.nodeType == DaxeNode.TEXT_NODE)
        contents.appendText('\n');
    }
  }
  
  @override
  void updateAttributes() {
    if (state == 0) {
      for (x.Element refAttr in attRefs) {
        String name = doc.cfg.attributeQualifiedName(this, ref, refAttr);
        String value = getAttribute(name);
        String defaultValue = doc.cfg.defaultAttributeValue(refAttr);
        if (value == null) {
          if (defaultValue != null)
            value = defaultValue;
          else
            value = '';
        }
        SimpleTypeControl control = attributeControls[name];
        if (control != null) { // could be null for xml:space
          control.setValue(value);
          control.checkValue(false);
        }
      }
      if (unknownAttributeFields != null) {
        unknownAttributeFields.forEach((DaxeAttr attr, h.TextInputElement input) {
          String value = getAttribute(attr.name);
          if (value == null)
            value = '';
          input.value = value;
        });
      }
      updateValidity();
    } else if (state == 1) {
      h.Element hel = getHTMLNode();
      if (hel != null && hel.firstChild != null)
        hel.firstChild.replaceWith(createHeaderDiv());
    }
  }
  
  @override
  h.Element getHTMLContentsNode() {
    if (state == 2 || !hasContent)
      return(null);
    return(h.document.getElementById('contents-' + id));
  }
  
  @override
  bool newlineAfter() {
    return(true);
  }
  
  @override
  bool newlineInside() {
    return(firstChild != null && !spacePreserve());
  }
  
  @override
  void newNodeCreationUI(ActionFunction okfct) {
    // do not display an attribute dialog when the node is created
    okfct();
  }
  
  @override
  void attributeDialog([ActionFunction okfct]) {
    // this is called by the contextual menu
    state = 0;
    if (getHTMLContentsNode() != null)
      updateHTML();
    if (okfct != null)
      okfct();
  }
  
  @override
  Position firstCursorPositionInside() {
    if (hasContent)
      return(new Position(this, 0));
    else
      return(null);
  }
  
  @override
  Position lastCursorPositionInside() {
    if (hasContent)
      return(new Position(this, offsetLength));
    else
      return(null);
  }
  
  void editableView() {
    bEditable.select();
    bNormal.deselect();
    bCollapsed.deselect();
    state = 0;
    updateHTML();
    if (attRefs.length > 0) {
      String firstAttName = doc.cfg.attributeQualifiedName(this, ref, attRefs.first);
      attributeControls[firstAttName].focus();
    }
  }
  
  void normalView() {
    bEditable.deselect();
    bNormal.select();
    bCollapsed.deselect();
    state = 1;
    updateHTML();
  }
  
  void collapsedView() {
    bEditable.deselect();
    bNormal.deselect();
    bCollapsed.select();
    state = 2;
    updateHTML();
  }
  
  h.TableRowElement attributeHTML(x.Element refAttr) {
    String name = doc.cfg.attributeQualifiedName(this, ref, refAttr);
    h.TableRowElement tr = new h.TableRowElement();
    
    h.TableCellElement td = new h.TableCellElement();
    td.classes.add('shrink');
    h.ButtonElement bHelp = makeHelpButton(ref, refAttr);
    td.append(bHelp);
    tr.append(td);
    
    td = new h.TableCellElement();
    td.classes.add('shrink');
    td.text = doc.cfg.attributeTitle(this, ref, refAttr);
    if (doc.cfg.requiredAttribute(ref, refAttr))
      td.classes.add('required');
    else
      td.classes.add('optional');
    tr.append(td);
    
    td = new h.TableCellElement();
    td.classes.add('expand');
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
    h.Element ht = attributeControl.html();
    if (ht.firstChild is h.TextInputElement)
      (ht.firstChild as h.TextInputElement).classes.add('form_field');
    else if (ht.firstChild is h.DataListElement && ht.firstChild.nextNode is h.TextInputElement)
      (ht.firstChild.nextNode as h.TextInputElement).classes.add('form_field');
    td.append(ht);
    tr.append(td);
    
    td = new h.TableCellElement();
    td.classes.add('shrink');
    tr.append(td);
    
    return(tr);
  }
  
  h.TableRowElement unknownAttributeHTML(DaxeAttr att) {
    if (unknownAttributeFields == null)
      unknownAttributeFields = new HashMap<DaxeAttr, h.TextInputElement>();
    h.TextInputElement input = new h.TextInputElement();
    input.spellcheck = false;
    input.size = 40;
    input.value = att.value;
    input.classes.add('invalid');
    input.onInput.listen((h.Event event) => changeUnknownAttributeValue(att, input)); // onInput doesn't work with IE9 and backspace
    input.onKeyUp.listen((h.KeyboardEvent event) => changeUnknownAttributeValue(att, input)); // so we use onKeyUp too
    unknownAttributeFields[att] = input;
    
    h.TableRowElement tr = new h.TableRowElement();
    h.TableCellElement td = new h.TableCellElement();
    td.classes.add('shrink');
    tr.append(td);
    
    td = new h.TableCellElement();
    td.classes.add('shrink');
    td.appendText(att.name);
    tr.append(td);
    
    td = new h.TableCellElement();
    td.classes.add('expand');
    td.append(input);
    tr.append(td);
    
    td = new h.TableCellElement();
    td.classes.add('shrink');
    tr.append(td);
    
    return(tr);
  }
  
  void changeAttributeValue(x.Element refAttr, SimpleTypeControl attributeControl) {
    String value = attributeControl.getValue();
    String name = doc.cfg.attributeQualifiedName(this, ref, refAttr);
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
    updateValidity();
  }
  
  void changeUnknownAttributeValue(DaxeAttr att, h.TextInputElement input) {
    String value = input.value;
    if (getAttributeNS(att.namespaceURI, att.localName) != value) {
      String name = att.name;
      DaxeAttr attr;
      if (value == '')
        attr = new DaxeAttr(name, null); // remove the attribute
      else
        attr = new DaxeAttr(name, value);
      doc.doNewEdit(new UndoableEdit.changeAttribute(this, attr, updateDisplay: false));
      updateValidity();
    }
  }
  
  static h.ButtonElement makeHelpButton(final x.Element elementRef, final x.Element attributeRef) {
    h.ButtonElement bHelp = new h.ButtonElement();
    bHelp.attributes['type'] = 'button';
    bHelp.classes.add('help');
    bHelp.value = '?';
    bHelp.text = '?';
    if (attributeRef == null) {
      String title = doc.cfg.documentation(elementRef);
      if (title != null)
        bHelp.title = title;
      bHelp.onClick.listen((h.Event event) => (new HelpDialog.Element(elementRef)).show());
    } else {
      String title = doc.cfg.attributeDocumentation(elementRef, attributeRef);
      if (title != null)
        bHelp.title = title;
      bHelp.onClick.listen((h.Event event) => (new HelpDialog.Attribute(attributeRef, elementRef)).show());
    }
    return(bHelp);
  }
}
