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

/**
 * Attribute dialog for an element that is not defined in the schema.
 */
class UnknownElementDialog {
  DaxeNode el;
  List<h.InputElement> nameInputs;
  List<h.InputElement> valueInputs;
  ActionFunction okfct;
  
  UnknownElementDialog(this.el, [this.okfct]) {
    nameInputs = new List<h.InputElement>();
    valueInputs = new List<h.InputElement>();
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
    title.text = el.nodeName;
    div3.append(title);
    h.FormElement form = new h.FormElement();
    h.TableElement table = new h.TableElement();
    SimpleTypeControl toFocus = null;
    for (DaxeAttr att in el.attributes) {
      h.TableRowElement tr = new h.TableRowElement();
      h.TableCellElement td = new h.TableCellElement();
      h.InputElement nameInput = _newNameInput(att.name);
      nameInputs.add(nameInput);
      td.append(nameInput);
      tr.append(td);
      
      td = new h.TableCellElement();
      h.InputElement valueInput = _newValueInput(att.value);
      valueInputs.add(valueInput);
      td.append(valueInput);
      tr.append(td);
      
      _addRemoveButton(tr, nameInput);
      table.append(tr);
    }
    form.append(table);
    h.DivElement div_buttons = new h.DivElement();
    div_buttons.classes.add('buttons');
    h.ButtonElement bAdd = new h.ButtonElement();
    bAdd.attributes['type'] = 'button';
    bAdd.appendText(Strings.get("attribute.add"));
    bAdd.onClick.listen((h.MouseEvent event) => _addAttribute());
    div_buttons.append(bAdd);
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
    // save and close dialog
    List<DaxeAttr> attributes = new List<DaxeAttr>();
    for (int i=0; i<nameInputs.length; i++) {
      h.TextInputElement nameInput = nameInputs[i];
      String name = nameInput.value;
      if (!_isAttributeNameOK(name)) {
        event.preventDefault();
        //TODO: check if the bug with .focus() in Firefox is fixed
        nameInput.select();
        nameInput.selectionStart = nameInput.selectionEnd = nameInput.value.length;
        h.window.alert(Strings.get('attribute.invalid_attribute_name'));
        return;
      }
      String value = valueInputs[i].value;
      int ind = name.indexOf(':');
      DaxeAttr attribute;
      String namespace = doc.cfg != null ? doc.cfg.attributeNamespaceByName(name) : null;
      attribute = new DaxeAttr.NS(namespace, name, value);
      attributes.add(attribute);
    }
    h.querySelector('div#attributes_dlg').remove();
    event.preventDefault();
    if (el.getHTMLNode() != null) {
      UndoableEdit edit = new UndoableEdit.changeAttributes(el, attributes);
      doc.doNewEdit(edit);
    } else {
      // this is for a new element
      el.attributes = attributes;
    }
    page.focusCursor();
    if (okfct != null)
      okfct();
  }
  
  void cancel() {
    h.querySelector('div#attributes_dlg').remove();
    page.focusCursor();
  }
  
  void _addRemoveButton(tr, nameInput) {
    h.TableCellElement td = new h.TableCellElement();
    h.ButtonElement bMinus = new h.ButtonElement();
    bMinus.attributes['type'] = 'button';
    bMinus.value = '-';
    bMinus.text = '-';
    bMinus.onClick.listen((h.Event event) => _removeAttribute(nameInput));
    td.append(bMinus);
    tr.append(td);
  }
  
  h.TextInputElement _newNameInput([String name]) {
    h.TextInputElement nameInput = new h.TextInputElement();
    nameInput.spellcheck = false;
    nameInput.value = name != null ? name : "";
    nameInput.size = 20;
    // FIXME: this is not optimized:
    nameInput.onInput.listen((h.Event event) => _checkAttributeName(nameInput)); // onInput doesn't work with IE9 and backspace
    nameInput.onKeyUp.listen((h.KeyboardEvent event) => _checkAttributeName(nameInput)); // onKeyUp doesn't work with datalists
    return(nameInput);
  }
  
  bool _isAttributeNameOK(String name) {
    final RegExp r = new RegExp("^[^<>&#!/?'\",0-9.\\-\\s][^<>&#!/?'\",\\s]*\$"); // should be more restrictive
    return(r.hasMatch(name));
  }
  
  void _checkAttributeName(h.TextInputElement nameInput) {
    String name = nameInput.value;
    if (_isAttributeNameOK(name)) {
      nameInput.classes.add('valid');
      nameInput.classes.remove('invalid');
    } else {
      nameInput.classes.add('invalid');
      nameInput.classes.remove('valid');
    }
  }
  
  h.TextInputElement _newValueInput([String value]) {
    h.TextInputElement valueInput = new h.TextInputElement();
    valueInput.spellcheck = false;
    valueInput.value = value != null ? value : "";
    valueInput.size = 40;
    return(valueInput);
  }
  
  _addAttribute() {
    h.TableElement table = h.document.querySelector("#attributes_dlg table");
    h.TextInputElement nameInput = _newNameInput();
    h.TextInputElement valueInput = _newValueInput();
    nameInputs.add(nameInput);
    valueInputs.add(valueInput);
    h.TableRowElement newtr = new h.TableRowElement();
    h.TableCellElement td = new h.TableCellElement();
    td.append(nameInput);
    newtr.append(td);
    td = new h.TableCellElement();
    td.append(valueInput);
    newtr.append(td);
    _addRemoveButton(newtr, nameInput);
    table.append(newtr);
  }
  
  void _removeAttribute(h.InputElement nameInput) {
    for (int i=0; i<nameInputs.length; i++) {
      if (nameInputs[i] == nameInput) {
        nameInputs.removeAt(i);
        valueInputs.removeAt(i);
        h.TableRowElement tr = h.document.querySelector("#attributes_dlg table tr:nth-child(${i+1})");
        tr.remove();
      }
    }
  }
}
