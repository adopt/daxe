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
 * Find and Replace dialog.
 */
class FindDialog {
  
  static bool caseSensitive = false;
  static bool backwards = false;
  static String findString = '';
  
  void show() {
    h.DivElement div_find = h.document.getElementById('find_dlg');
    if (div_find != null) {
      h.TextInputElement inputFind = h.document.getElementById('find_dlg_find_field');
      inputFind.focus();
      return;
    }
    h.Element divdoc = h.querySelector("#doc1");
    divdoc.style.bottom = '10.5em';
    div_find = new h.DivElement();
    div_find.id = 'find_dlg';
    div_find.classes.add('find');
    
    h.FormElement form = new h.FormElement();
    h.TableElement table = new h.TableElement();
    h.TableRowElement tr = new h.TableRowElement();
    h.TableCellElement td = new h.TableCellElement();
    td.text = Strings.get('find.find');
    tr.append(td);
    td = new h.TableCellElement();
    h.TextInputElement inputFind = new h.TextInputElement();
    inputFind
      ..id = 'find_dlg_find_field'
      ..name = 'find'
      ..size = 40
      ..value = findString;
    td.append(inputFind);
    tr.append(td);
    table.append(tr);
    tr = new h.TableRowElement();
    td = new h.TableCellElement();
    td.text = Strings.get('find.replace_by');
    tr.append(td);
    td = new h.TableCellElement();
    h.TextInputElement inputReplace = new h.TextInputElement();
    inputReplace
      ..id = 'find_dlg_replace_field'
      ..name = 'replace_by'
      ..size = 40;
    td.append(inputReplace);
    tr.append(td);
    table.append(tr);
    div_find.append(table);
    
    h.DivElement div_options = new h.DivElement();
    div_options.classes.add('options');
    h.CheckboxInputElement cbCaseSensitive = new h.CheckboxInputElement();
    cbCaseSensitive
      ..id = 'find_cb_ignore_case'
      ..checked = caseSensitive
      ..onChange.listen((h.Event event) => caseSensitive = cbCaseSensitive.checked);
    div_options.append(cbCaseSensitive);
    h.LabelElement labelIgnoreCase = new h.LabelElement();
    labelIgnoreCase
      ..htmlFor = 'find_cb_ignore_case'
      ..text = Strings.get("find.case_sensitive");
    div_options.append(labelIgnoreCase);
    h.CheckboxInputElement cbBackwards = new h.CheckboxInputElement();
    cbBackwards
      ..id = 'find_cb_backwards'
      ..checked = backwards
      ..onChange.listen((h.Event event) => backwards = cbBackwards.checked);
    div_options.append(cbBackwards);
    h.LabelElement labelBackwards = new h.LabelElement();
    labelBackwards
      ..htmlFor = 'find_cb_backwards'
      ..text = Strings.get("find.backwards");
    div_options.append(labelBackwards);
    // TODO: option to look at attribute values, XPath search
    form.append(div_options);
    
    h.DivElement div_buttons = new h.DivElement();
    div_buttons.classes.add('buttons');
    h.ButtonElement bClose = new h.ButtonElement();
    bClose
      ..attributes['type'] = 'button'
      ..appendText(Strings.get("button.Close"))
      ..onClick.listen((h.MouseEvent event) => close());
    div_buttons.append(bClose);
    h.ButtonElement bReplace = new h.ButtonElement();
    bReplace
      ..attributes['type'] = 'button'
      ..appendText(Strings.get("find.replace"))
      ..onClick.listen((h.MouseEvent event) => replace());
    div_buttons.append(bReplace);
    h.ButtonElement bReplaceFind = new h.ButtonElement();
    bReplaceFind
      ..attributes['type'] = 'button'
      ..appendText(Strings.get("find.replace_find"))
      ..onClick.listen((h.MouseEvent event) => replaceFind());
    div_buttons.append(bReplaceFind);
    h.ButtonElement bReplaceAll = new h.ButtonElement();
    bReplaceAll
      ..attributes['type'] = 'button'
      ..appendText(Strings.get("find.replace_all"))
      ..onClick.listen((h.MouseEvent event) => replaceAll());
    div_buttons.append(bReplaceAll);
    h.ButtonElement bNext = new h.ButtonElement();
    bNext
      ..attributes['type'] = 'button'
      ..appendText(Strings.get("find.next"))
      ..onClick.listen((h.MouseEvent event) => next());
    div_buttons.append(bNext);
    form.append(div_buttons);
    
    div_find.append(form);
    h.document.body.append(div_find);
    div_find.onKeyDown.listen((h.KeyboardEvent event) {
      if (event.keyCode == h.KeyCode.ESC) {
        close();
      }
    });
    inputFind.focus();
  }
  
  void next() {
    //FIXME: does not work with DNForm and DNSimpleType: selection is not visible
    //  (but then, how could we select a part of a select element anyway ?)
    findString = ((h.document.getElementById('find_dlg_find_field')) as h.TextInputElement).value;
    if (findString == '')
      return;
    Position pos;
    if (!backwards) {
      Position end = page.getSelectionEnd();
      if (end == null)
        end = new Position(doc.dndoc, 0);
      pos = nextAt(end);
    } else {
      Position start = page.getSelectionStart();
      if (start == null)
        start = new Position(doc.dndoc, doc.dndoc.offsetLength);
      pos = previousAt(start);
    }
    if (pos != null) {
      page.moveCursorTo(pos);
      page.cursor.setSelection(pos, new Position(pos.dn, pos.dnOffset + findString.length));
    }
  }
  
  Position nextAt(Position pos) {
    DaxeNode parent = pos.dn;
    int offset = pos.dnOffset;
    if (parent is! DNText) {
      parent = parent.childAtOffset(offset);
      offset = 0;
    }
    while (parent != null) {
      if (parent is DNText) {
        int index;
        if (!caseSensitive)
          index = parent.nodeValue.toLowerCase().indexOf(findString.toLowerCase(), offset);
        else
          index = parent.nodeValue.indexOf(findString, offset);
        if (index != -1)
          return(new Position(parent, index));
      }
      parent = parent.nextNode();
      offset = 0;
    }
    return(null);
  }
  
  Position previousAt(Position pos) {
    DaxeNode parent = pos.dn;
    int offset = pos.dnOffset;
    if (parent is! DNText) {
      if (offset > 0)
        parent = parent.childAtOffset(offset-1);
      else {
        DaxeNode p = parent;
        parent = null;
        while (p != null) {
          if (p.previousSibling != null) {
            parent = p.previousSibling;
            break;
          }
          p = p.parent;
        }
      }
      if (parent != null)
        offset = parent.offsetLength;
    }
    while (parent != null) {
      if (parent is DNText) {
        int index;
        if (!caseSensitive)
          index = parent.nodeValue.toLowerCase().substring(0, offset).lastIndexOf(findString.toLowerCase());
        else
          index = parent.nodeValue.substring(0, offset).lastIndexOf(findString);
        if (index != -1)
          return(new Position(parent, index));
      }
      parent = parent.previousNode();
      if (parent != null)
        offset = parent.offsetLength;
    }
    return(null);
  }
  
  void replace() {
    Position start = new Position.clone(page.getSelectionStart());
    Position end = new Position.clone(page.getSelectionEnd());
    if (start == null || start.dn is! DNText)
      return;
    String replaceString = ((h.document.getElementById('find_dlg_replace_field')) as h.TextInputElement).value;
    UndoableEdit edit = new UndoableEdit.compound(Strings.get('find.replace'));
    // we should not remove the whole string before inserting the new one, because this might
    // cause the text node referenced by pos to disappear, and the insert won't work
    // -> we do the insert first to make sure not to remove a text node
    if (replaceString != '')
      edit.addSubEdit(new UndoableEdit.insertString(end, replaceString));
    if (start != end && start.dn == end.dn)
      edit.addSubEdit(new UndoableEdit.removeString(start, end.dnOffset - start.dnOffset));
    doc.doNewEdit(edit);
    page.cursor.setSelection(start, new Position(start.dn, start.dnOffset + replaceString.length));
  }
  
  void replaceFind() {
    replace();
    next();
  }
  
  void replaceAll() {
    findString = ((h.document.getElementById('find_dlg_find_field')) as h.TextInputElement).value;
    if (findString == '')
      return;
    String replaceString = ((h.document.getElementById('find_dlg_replace_field')) as h.TextInputElement).value;
    Position pos = previousAt(new Position(doc.dndoc, doc.dndoc.offsetLength));
    // we are going backwards in order to be able to combine edits
    UndoableEdit edit = new UndoableEdit.compound(Strings.get('find.replace_all'));
    while (pos != null) {
      if (replaceString != '')
        edit.addSubEdit(new UndoableEdit.insertString(new Position(pos.dn, pos.dnOffset + findString.length),
            replaceString));
      edit.addSubEdit(new UndoableEdit.removeString(pos, findString.length));
      pos = previousAt(pos);
    }
    doc.doNewEdit(edit);
  }
  
  void close() {
    h.DivElement div_find = h.document.getElementById('find_dlg');
    div_find.remove();
    h.Element divdoc = h.querySelector("#doc1");
    divdoc.style.bottom = '1.5em';
    page.focusCursor();
  }
}
