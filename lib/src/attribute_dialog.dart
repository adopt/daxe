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

part of daxe;

class AttributeDialog {
  DaxeNode el;
  x.Element ref;
  List<x.Element> attRefs;
  HashMap<x.Element, SimpleTypeControl> controls;
  ActionFunction okfct;
  
  AttributeDialog(this.el, [this.okfct]) {
    ref = el.ref;
    controls = new HashMap<x.Element, SimpleTypeControl>();
  }
  
  void show() {
    h.DivElement div1 = new h.DivElement();
    div1.id = 'attributes_dlg';
    div1.classes.add('dlg1');
    h.DivElement div2 = new h.DivElement();
    div2.classes.add('dlg2');
    h.DivElement div3 = new h.DivElement();
    div3.classes.add('dlg3');
    h.DivElement title = new h.DivElement();
    title.classes.add('dlgtitle');
    title.text = doc.cfg.elementTitle(ref);
    div3.append(title);
    h.FormElement form = new h.FormElement();
    h.TableElement table = new h.TableElement();
    attRefs = doc.cfg.elementAttributes(ref);
    SimpleTypeControl toFocus = null;
    for (x.Element attref in attRefs) {
      h.TableRowElement tr = new h.TableRowElement();
      h.TableCellElement td = new h.TableCellElement();
      String attdoc = doc.cfg.attributeDocumentation(ref, attref);
      if (attdoc != null) {
        h.ButtonElement bHelp = new h.ButtonElement();
        bHelp.attributes['type'] = 'button';
        bHelp.classes.add('help');
        bHelp.value = '?';
        bHelp.text = '?';
        bHelp.title = attdoc;
        bHelp.onClick.listen((h.Event event) => help(attref, ref));
        td.append(bHelp);
      }
      tr.append(td);
      td = new h.TableCellElement();
      String name = doc.cfg.attributeQualifiedName(ref, attref);
      String title = doc.cfg.attributeTitle(ref, attref);
      td.appendText(title);
      if (doc.cfg.requiredAttribute(ref, attref))
        td.classes.add('required');
      else
        td.classes.add('optional');
      tr.append(td);
      td = new h.TableCellElement();
      String value = el.getAttribute(name);
      String defaultValue = doc.cfg.defaultAttributeValue(attref);
      if (value == null) {
        if (defaultValue != null)
          value = defaultValue;
        else
          value = '';
      }
      SimpleTypeControl control = new SimpleTypeControl.forAttribute(ref, attref, value);
      controls[attref] = control;
      List<String> values = doc.cfg.attributeValues(attref);
      if (values == null || values.length == 0)
        if (toFocus == null)
          toFocus = control;
      td.append(control.html());
      tr.append(td);
      table.append(tr);
    }
    form.append(table);
    h.DivElement div_buttons = new h.DivElement();
    div_buttons.classes.add('buttons');
    h.ButtonElement bCancel = new h.ButtonElement();
    bCancel.attributes['type'] = 'button';
    bCancel.appendText(Strings.get("button.Cancel"));
    bCancel.onClick.listen((h.MouseEvent event) => cancel());
    div_buttons.append(bCancel);
    h.ButtonElement bOk = new h.ButtonElement();
    bOk.attributes['type'] = 'submit';
    bOk.appendText(Strings.get("button.OK"));
    bOk.onClick.listen((h.MouseEvent event) => ok(event));
    div_buttons.append(bOk);
    form.append(div_buttons);
    div3.append(form);
    div2.append(div3);
    div1.append(div2);
    h.document.body.append(div1);
    if (toFocus != null)
      toFocus.focus();
  }
  
  void ok(h.MouseEvent event) {
    // check the required attributes
    for (x.Element attref in controls.keys) {
      SimpleTypeControl control = controls[attref];
      String value = control.getValue();
      bool required = doc.cfg.requiredAttribute(ref, attref);
      if (value == '' && required) {
        event.preventDefault();
        h.window.alert(Strings.get('attribute.missing_required'));
        return;
      }
    }
    
    // save and close dialog
    LinkedHashMap<String, DaxeAttr> attributes = el.getAttributesMapCopy();
    for (x.Element attref in controls.keys) {
      SimpleTypeControl control = controls[attref];
      String name = doc.cfg.attributeQualifiedName(ref, attref);
      String value = control.getValue();
      String namespace = doc.cfg.attributeNamespace(attref);
      String defaultValue = doc.cfg.defaultAttributeValue(attref);
      if ((value == '' && defaultValue == null) || value == defaultValue)
        attributes.remove(name);
      else if (value != '' || defaultValue != null)
        attributes[name] = new DaxeAttr.NS(namespace, name, value);
    }
    h.querySelector('div#attributes_dlg').remove();
    event.preventDefault();
    List<DaxeAttr> attList = new List.from(attributes.values);
    if (el.getHTMLNode() != null) {
      UndoableEdit edit = new UndoableEdit.changeAttributes(el, attList);
      doc.doNewEdit(edit);
    } else {
      // this is for a new element
      el.attributes = attList;
    }
    page.focusCursor();
    if (okfct != null)
      okfct();
  }
  
  void cancel() {
    h.querySelector('div#attributes_dlg').remove();
    page.focusCursor();
  }
  
  void help(x.Element attref, x.Element ref) {
    HelpDialog dlg = new HelpDialog.Attribute(attref, ref);
    dlg.show();
  }
}
