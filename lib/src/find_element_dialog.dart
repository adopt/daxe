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
 * Dialog to find an element by name, content or attribute value.
 */
class FindElementDialog {

  static String elementName = '';
  static bool caseSensitive = false;

  /**
   * Displays the dialog.
   */
  void show() {
    h.DivElement div_find = h.document.getElementById('find_dlg');
    if (div_find != null)
      div_find.remove();
    h.DivElement findElementDiv = h.document.getElementById('find_element_dlg');
    if (findElementDiv != null) {
      h.TextInputElement elementInput = h.document.getElementById('find_element_dlg_element');
      elementInput.focus();
      elementInput.setSelectionRange(0, elementInput.value.length);
      return;
    }
    h.DivElement divdoc = h.querySelector("#doc1");
    divdoc.style.bottom = '15em';
    findElementDiv = new h.DivElement();
    findElementDiv.id = 'find_element_dlg';
    findElementDiv.classes.add('find_element');
    findElementDiv.style.left = "${divdoc.offsetLeft}px";

    var form = new h.FormElement();
    var table = new h.TableElement();
    var tr = new h.TableRowElement();
    var td = new h.TableCellElement();
    td.text = Strings.get('find.find_element');
    tr.append(td);
    td = new h.TableCellElement();
    var elementInput = new h.TextInputElement();
    elementInput
      ..id = 'find_element_dlg_element'
      ..size = 40
      ..value = elementName;
    elementInput.onKeyDown.listen((h.KeyboardEvent event) {
      if (event.keyCode == h.KeyCode.ENTER) {
        event.preventDefault();
        next();
      }
    });
    elementInput.onInput.listen((h.Event event) {
      updateAttributes();
    });
    List<x.Element> allRefs = doc.cfg.allElementsList();
    var datalist = new h.DataListElement();
    datalist.id = 'find_element_dlg_datalist';
    var names = new List<String>();
    for (x.Element ref in allRefs) {
      String name = doc.cfg.elementName(ref);
      if (!names.contains(name))
        names.add(name);
    }
    names.sort();
    for (String name in names) {
      var option = new h.OptionElement();
      option.value = name;
      datalist.append(option);
    }
    elementInput.attributes['list'] = 'find_element_dlg_datalist';
    td.append(datalist);
    td.append(elementInput);
    tr.append(td);
    table.append(tr);
    tr = new h.TableRowElement();
    td = new h.TableCellElement();
    td.text = Strings.get('find.element_content');
    tr.append(td);
    td = new h.TableCellElement();
    var contentInput = new h.TextInputElement();
    contentInput
      ..id = 'find_element_dlg_content'
      ..size = 40;
    contentInput.onKeyDown.listen((h.KeyboardEvent event) {
      if (event.keyCode == h.KeyCode.ENTER) {
        event.preventDefault();
        next();
      }
    });
    td.append(contentInput);
    tr.append(td);
    td = new h.TableCellElement();
    var contentContainsLabel = new h.LabelElement();
    contentContainsLabel
      ..htmlFor = 'find_element_dlg_content_contains'
      ..text = Strings.get("find.contains");
    td.append(contentContainsLabel);
    var containsCheckbox = new h.CheckboxInputElement();
    containsCheckbox
      ..id = 'find_element_dlg_content_contains'
      ..checked = true;
    td.append(containsCheckbox);
    tr.append(td);
    table.append(tr);
    form.append(table);

    var attributeDiv = new h.DivElement();
    attributeDiv.id = 'find_element_dlg_attributes';
    attributeDiv.appendText(Strings.get('find.attributes'));
    form.append(attributeDiv);

    var buttonDiv = new h.DivElement();
    buttonDiv.classes.add('buttons');
    buttonDiv.style.textAlign = 'left';
    var bClose = new h.ButtonElement();
    bClose
      ..attributes['type'] = 'button'
      ..appendText(Strings.get("button.Close"))
      ..onClick.listen((h.MouseEvent event) => close());
    buttonDiv.append(bClose);
    var bPrevious = new h.ButtonElement();
    bPrevious
      ..id = 'find_element_dlg_previous'
      ..attributes['type'] = 'button'
      ..appendText(Strings.get("find.previous"))
      ..onClick.listen((h.MouseEvent event) => previous());
    buttonDiv.append(bPrevious);
    var bNext = new h.ButtonElement();
    bNext
      ..id = 'find_element_dlg_next'
      ..attributes['type'] = 'button'
      ..appendText(Strings.get("find.next"))
      ..onClick.listen((h.MouseEvent event) => next());
    buttonDiv.append(bNext);
    form.append(buttonDiv);

    findElementDiv.append(form);
    h.document.body.append(findElementDiv);
    findElementDiv.onKeyDown.listen((h.KeyboardEvent event) {
      if (event.keyCode == h.KeyCode.ESC) {
        close();
      }
    });
    h.DivElement pathDiv = h.document.getElementById('path');
    int bottom = findElementDiv.offsetHeight + pathDiv.offsetHeight;
    divdoc.style.bottom = "${bottom}px";
    if (elementName != '')
      updateAttributes();
    elementInput.focus();
    elementInput.setSelectionRange(0, elementInput.value.length);
  }

  /**
   * Updates the list of attributes based on the chosen element
   * (using the first element in the schema matching the name).
   */
  void updateAttributes() {
    h.DivElement attributeDiv = h.document.getElementById('find_element_dlg_attributes');
    attributeDiv.children.clear();
    attributeDiv.appendText(Strings.get('find.attributes'));
    h.TextInputElement elementInput = h.document.getElementById('find_element_dlg_element');
    String elementName = elementInput.value;
    if (elementName != '') {
      List<x.Element> references = doc.cfg.elementReferences(elementName);
      if (references != null && references.length > 0) {
        x.Element elementRef = references[0];
        List<x.Element> attRefs = doc.cfg.elementAttributes(elementRef);
        var table = new h.TableElement();
        for (x.Element attRef in attRefs) {
          var tr = new h.TableRowElement();
          var td = new h.TableCellElement();
          td.text = doc.cfg.attributeTitle(null, elementRef, attRef);
          tr.append(td);
          td = new h.TableCellElement();
          // NOTE: we can't use SimpleTypeControl for attribute values,
          // because an element name can match several element references
          // with different types for attributes of the same name.
          // However, we can suggest attribute values.
          var attValueInput = new h.TextInputElement();
          String attName = doc.cfg.attributeName(attRef);
          String inputId = 'find_element_dlg_attribute_' + attName;
          attValueInput
            ..id = inputId
            ..size = 40;
          List<String> values = doc.cfg.attributeValues(attRef);
          if (values == null || values.length == 0)
            values = doc.cfg.attributeSuggestedValues(elementRef, attRef);
          if (values != null) {
            var datalist = new h.DataListElement();
            datalist.id = 'find_element_dlg_attribute_' + attName + '_datalist';
            for (String value in values) {
              var option = new h.OptionElement();
              option.value = value;
              datalist.append(option);
            }
            attValueInput.attributes['list'] = datalist.id;
            td.append(datalist);
          }
          td.append(attValueInput);
          tr.append(td);
          td = new h.TableCellElement();
          var containsLabel = new h.LabelElement();
          String checkboxId = 'find_element_dlg_attribute_' + attName + '_contains';
          containsLabel
            ..htmlFor = checkboxId
            ..text = Strings.get("find.contains");
          td.append(containsLabel);
          var containsCheckbox = new h.CheckboxInputElement();
          containsCheckbox
            ..id = checkboxId
            ..checked = true;
          td.append(containsCheckbox);
          tr.append(td);
          table.append(tr);
        }
        attributeDiv.append(table);
      }
    }
  }
  
  /**
   * Returns all the infos related to user selection:
   * 0: element name (String),
   * 1: element content (String),
   * 2: element contains (bool),
   * 3: attribute references (List<x.Element>),
   * 4: attribute values (HashMap<x.Element,String>),
   * 5: attribute contains (HashMap<x.Element,bool>).
   */
  List _getInfos() {
    var infos = new List();
    h.TextInputElement elementInput = h.document.getElementById('find_element_dlg_element');
    elementName = elementInput.value;
    if (elementName == '')
      return null;
    infos.add(elementName);
    h.TextInputElement contentInput = h.document.getElementById('find_element_dlg_content');
    String content = contentInput.value;
    infos.add(content);
    h.CheckboxInputElement containsCheckbox = h.document.getElementById('find_element_dlg_content_contains');
    bool contentContains = containsCheckbox.checked;
    infos.add(contentContains);
    List<x.Element> references = doc.cfg.elementReferences(elementName);
    if (references.length == 0)
      return null;
    x.Element elementRef = references[0];
    List<x.Element> attRefs = doc.cfg.elementAttributes(elementRef);
    infos.add(attRefs);
    var attValues = new HashMap<x.Element,String>();
    var attContains = new HashMap<x.Element,bool>();
    for (x.Element attRef in attRefs) {
      String attName = doc.cfg.attributeName(attRef);
      String inputId = 'find_element_dlg_attribute_' + attName;
      h.TextInputElement attValueInput = h.document.getElementById(inputId);
      attValues[attRef] = attValueInput.value;
      String checkboxId = 'find_element_dlg_attribute_' + attName + '_contains';
      h.CheckboxInputElement containsCheckbox = h.document.getElementById(checkboxId);
      attContains[attRef] = containsCheckbox.checked;
    }
    infos.add(attValues);
    infos.add(attContains);
    return infos;
  }
  
  /**
   * Returns true if the DaxeNode is matching the criteria given by the
   * following parameters.
   */
  bool _isMatching(DaxeNode dn, String elementName, String content,
      bool contentContains, List<x.Element> attRefs, HashMap<x.Element,String> attValues,
      HashMap<x.Element,bool> attContains) {
    if (elementName.contains(':')) {
      if (dn.nodeName != elementName)
        return false;
    } else {
      if (dn.localName != elementName)
        return false;
    }
    if (content != '') {
      if (!caseSensitive)
        content = content.toLowerCase();
      String testString = '';
      for (DaxeNode child in dn.childNodes) {
        if (child is DNText)
          testString += child.nodeValue;
        else if (child is DNStyle && child.firstChild is DNText)
          testString += child.firstChild.nodeValue;
      }
      if (!caseSensitive)
        testString = testString.toLowerCase();
      if (!((contentContains && testString.contains(content)) ||
          (!contentContains && testString == content))) {
        return false;
      }
    }
    for (x.Element attRef in attRefs) {
      String value = attValues[attRef];
      if (value == '')
        continue;
      if (!caseSensitive)
        value = value.toLowerCase();
      bool contains = attContains[attRef];
      String attNamespace = doc.cfg.attributeNamespace(attRef);
      String attName = doc.cfg.attributeName(attRef);
      String testString = dn.getAttributeNS(attNamespace, attName);
      if (testString == null)
        return false;
      if (!caseSensitive)
        testString = testString.toLowerCase();
      if (!((contains && testString.contains(value)) ||
          (!contains && testString == value))) {
        return false;
      }
    }
    return true;
  }
  
  void next() {
    // get input info
    List infos = _getInfos();
    if (infos == null)
      return;
    String elementName = infos[0];
    String content = infos[1];
    bool contentContains = infos[2];
    List<x.Element> attRefs = infos[3];
    HashMap<x.Element,String> attValues = infos[4];
    HashMap<x.Element,bool> attContains = infos[5];
    // look for first matching element from current position
    Position pos = page.getSelectionStart();
    if (pos == null)
      return;
    DaxeNode parent;
    if (pos.dn is DNText)
      parent = pos.dn.nextNode();
    else if (pos.dnOffset == pos.dn.offsetLength) {
      parent = pos.dn;
      while (parent != null) {
        if (parent.nextSibling != null) {
          parent = parent.nextSibling;
          break;
        }
        parent = parent.parent;
      }
    } else {
      parent = pos.dn.childAtOffset(pos.dnOffset);
      if (page.getSelectionEnd() == new Position(pos.dn, pos.dnOffset + 1))
        parent = parent.nextNode();
    }
    
    for ( ; parent != null; parent = parent.nextNode()) {
      bool matching = _isMatching(parent, elementName, content,
          contentContains, attRefs, attValues, attContains);
      if (!matching)
        continue;
      page.selectNode(parent);
      h.ButtonElement bNext = h.document.getElementById('find_element_dlg_next');
      bNext.focus();
      break;
    }
  }

  void previous() {
    // get input info
    List infos = _getInfos();
    if (infos == null)
      return;
    String elementName = infos[0];
    String content = infos[1];
    bool contentContains = infos[2];
    List<x.Element> attRefs = infos[3];
    HashMap<x.Element,String> attValues = infos[4];
    HashMap<x.Element,bool> attContains = infos[5];
    // look for first matching element from current position
    Position pos = page.getSelectionEnd();
    if (pos == null)
      return;
    DaxeNode parent;
    if (pos.dn is DNText)
      parent = pos.dn.previousNode();
    else if (pos.dnOffset == 0) {
      parent = pos.dn;
      while (parent != null) {
        if (parent.previousSibling != null) {
          parent = parent.previousSibling;
          break;
        }
        parent = parent.parent;
      }
    } else {
      parent = pos.dn.childAtOffset(pos.dnOffset - 1);
      if (page.getSelectionStart() == new Position(pos.dn, pos.dnOffset - 1))
        parent = parent.previousNode();
    }
    
    for ( ; parent != null; parent = parent.previousNode()) {
      bool matching = _isMatching(parent, elementName, content,
          contentContains, attRefs, attValues, attContains);
      if (!matching)
        continue;
      page.selectNode(parent);
      h.ButtonElement bPrevious = h.document.getElementById('find_element_dlg_previous');
      bPrevious.focus();
      break;
    }
  }

  void close() {
    h.DivElement findElementDiv = h.document.getElementById('find_element_dlg');
    findElementDiv.remove();
    h.Element divdoc = h.querySelector("#doc1");
    divdoc.style.bottom = '1.3em';
    page.focusCursor();
  }
}
