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
 * Control for an element or attribute with a WXS simple type, used by [DNSimpleType] and [DNForm].
 */
class SimpleTypeControl {
  
  static int _n = 0;
  x.Element refElement;
  x.Element refAttribute;
  String value;
  String _uniqueName;
  List<String> validValues;
  List<String> suggestedValues;
  HashMap<String, String> titleToValue;
  h.Element hcontrol;
  ActionFunction valueChanged;
  bool catchUndo;
  Menu popup;
  
  
  SimpleTypeControl.forElement(this.refElement, this.value, {this.valueChanged}) {
    refAttribute = null;
    _uniqueName = "control$_n";
    _n++;
    validValues = doc.cfg.elementValues(refElement);
    if (validValues == null || validValues.length == 0)
      suggestedValues = doc.cfg.elementSuggestedValues(refElement);
    else {
      if (!validValues.contains(''))
        validValues.add('');
    }
    catchUndo = true;
  }
  
  SimpleTypeControl.forAttribute(this.refElement, this.refAttribute, this.value,
      {this.valueChanged, this.catchUndo: false}) {
    _uniqueName = "control$_n";
    _n++;
    validValues = doc.cfg.attributeValues(refAttribute);
    if (validValues == null || validValues.length == 0)
      suggestedValues = doc.cfg.attributeSuggestedValues(refElement, refAttribute);
    else {
      String defaultValue = doc.cfg.defaultAttributeValue(refAttribute);
      if (!validValues.contains('') && defaultValue == null)
        validValues.add('');
    }
  }
  
  h.Element html() {
    h.SpanElement span = new h.SpanElement();
    bool booleanValues;
    final List<String> lvalbool = ['true', 'false', '1', '0'];
    if (validValues == null || validValues.length != lvalbool.length ||
        (value != null && !lvalbool.contains(value))) {
      booleanValues = false;
    } else {
      booleanValues = true;
      for (int i=0; i<validValues.length; i++) {
        if (validValues[i] != lvalbool[i]) {
          booleanValues = false;
          break;
        }
      }
    }
    if (booleanValues) {
      h.CheckboxInputElement cb = new h.CheckboxInputElement();
      hcontrol = cb;
      if (value == null)
        value = 'false';
      cb.checked = (value == 'true' || value == '1');
      cb.onChange.listen((h.Event event) => checkValue(true));
      span.append(cb);
    } else if (validValues == null || validValues.length == 0) {
      h.TextInputElement input = new h.TextInputElement();
      input.spellcheck = false;
      hcontrol = input;
      input.size = 40;
      if (value == null)
        value = "";
      input.value = value;
      checkValue(false);
      
      // FIXME: this is not optimized:
      input.onInput.listen((h.Event event) => checkValue(true)); // onInput doesn't work with IE9 and backspace
      input.onKeyUp.listen((h.KeyboardEvent event) { // onKeyUp doesn't work with datalists
        bool ctrl = event.ctrlKey || event.metaKey;
        bool shift = event.shiftKey;
        int keyCode = event.keyCode;
        if (catchUndo && ctrl && ((!shift && keyCode == h.KeyCode.Z) ||
            (!shift && keyCode == h.KeyCode.Y) || (shift && keyCode == h.KeyCode.Z))) {
          // undo/redo handled elsewhere
        } else
          checkValue(true);
      });
      
      if (suggestedValues != null && suggestedValues.length > 0) {
        String title;
        if (refAttribute != null)
          title = doc.cfg.attributeValueTitle(refElement, refAttribute, value);
        else
          title = doc.cfg.elementValueTitle(refElement, value);
        input.value = title;
        h.DataListElement datalist = new h.DataListElement();
        datalist.id = 'datalist_$_uniqueName';
        titleToValue = new HashMap<String, String>();
        popup = new Menu('');
        for (String v in suggestedValues) {
          h.OptionElement option = new h.OptionElement();
          String title;
          if (refAttribute != null)
            title = doc.cfg.attributeValueTitle(refElement, refAttribute, v);
          else
            title = doc.cfg.elementValueTitle(refElement, v);
          option.value = title;
          titleToValue[title] = v;
          datalist.append(option);
          popup.add(new MenuItem(title, () {
            input.value = title;
            checkValue(true);
          }));
        }
        input.attributes['list'] = 'datalist_$_uniqueName';
        span.append(datalist);
      }
      span.append(input);
      if (suggestedValues != null && suggestedValues.length > 0) {
        // add a custom menu, because datalist UI sucks and there is no way to configure it or script it safely
        input.style.width = "90%"; // instead of 100%, to give some room to arrowSpan
        h.SpanElement arrowSpan = new h.SpanElement();
        arrowSpan.text = '▼';
        arrowSpan.style.cursor = 'default';
        arrowSpan.onClick.listen((h.Event event) => showSuggestedValuesMenu(input));
        arrowSpan.onMouseOver.listen((h.Event event) => arrowSpan.style.background = '#E0E0E0');
        arrowSpan.onMouseOut.listen((h.Event event) => arrowSpan.style.background = null);
        span.append(arrowSpan);
      }
    } else {
      h.SelectElement select = new h.SelectElement();
      hcontrol = select;
      if (value == null)
        value = '';
      titleToValue = new HashMap<String, String>();
      for (String v in validValues) {
        h.OptionElement option = new h.OptionElement();
        String title;
        if (refAttribute != null)
          title = doc.cfg.attributeValueTitle(refElement, refAttribute, v);
        else
          title = doc.cfg.elementValueTitle(refElement, v);
        option.text = title;
        option.value = v;
        titleToValue[title] = v;
        if (v == value) {
          option.defaultSelected = true;
          option.selected = true;
        }
        select.append(option);
      }
      if (!validValues.contains(value)) {
        // add this invalid value
        h.OptionElement option = new h.OptionElement();
        option.text = value;
        option.selected = true;
        select.append(option);
        hcontrol.classes.add('invalid');
      }
      //select.value = value; // doesn't work with IE
      select.onChange.listen((h.Event event) => checkValue(true));
      span.append(select);
    }
    if (catchUndo) {
      hcontrol.onKeyDown.listen((h.KeyboardEvent event) {
        bool ctrl = event.ctrlKey || event.metaKey;
        bool shift = event.shiftKey;
        int keyCode = event.keyCode;
        if (ctrl && !shift && keyCode == h.KeyCode.Z) { // Ctrl Z
          event.preventDefault();
        } else if (ctrl && ((!shift && keyCode == h.KeyCode.Y) ||
            (shift && keyCode == h.KeyCode.Z))) { // Ctrl-Y and Ctrl-Shift-Z
          event.preventDefault();
        }
      });
      hcontrol.onKeyUp.listen((h.KeyboardEvent event) {
        bool ctrl = event.ctrlKey || event.metaKey;
        bool shift = event.shiftKey;
        int keyCode = event.keyCode;
        if (ctrl && !shift && keyCode == h.KeyCode.Z) { // Ctrl Z
          event.preventDefault();
          doc.undo();
        } else if (ctrl && ((!shift && keyCode == h.KeyCode.Y) ||
            (shift && keyCode == h.KeyCode.Z))) { // Ctrl-Y and Ctrl-Shift-Z
          event.preventDefault();
          doc.redo();
        }
      });
    }
    return(span);
  }
  
  void checkValue(bool callAction) {
    String oldValue = value;
    if (/*hcontrol is h.TextInputElement*/ /* pb with JS: Dart bug 10383 */
        hcontrol is h.InputElement && (hcontrol as h.InputElement).type == 'text') {
      String title = (hcontrol as h.TextInputElement).value;
      if (titleToValue != null && titleToValue[title] != null)
        value = titleToValue[title];
      else
        value = title;
    } else if (hcontrol is h.SelectElement) {
      value = (hcontrol as h.SelectElement).value;
    } else if (/*hcontrol is h.CheckboxInputElement*/
        hcontrol is h.InputElement && (hcontrol as h.InputElement).type == 'checkbox') {
      bool checked = (hcontrol as h.CheckboxInputElement).checked;
      if (checked)
        value = 'true';
      else
        value = 'false';
    }
    bool valid;
    if (refAttribute != null)
      valid = doc.cfg.validAttributeValue(refAttribute, value);
    else
      valid = (value == '' || doc.cfg.isElementValueValid(refElement, value));
    if (valid) {
      hcontrol.classes.add('valid');
      hcontrol.classes.remove('invalid');
    } else {
      hcontrol.classes.add('invalid');
      hcontrol.classes.remove('valid');
    }
    if (callAction && value != oldValue && valueChanged != null)
      valueChanged();
  }
  
  String getValue() => value;
  
  void setValue(String value) {
    this.value = value;
    if (/*hcontrol is h.TextInputElement*/
        hcontrol is h.InputElement && (hcontrol as h.InputElement).type == 'text') {
      h.TextInputElement input = hcontrol as h.TextInputElement;
      if (refAttribute != null)
        input.value = doc.cfg.attributeValueTitle(refElement, refAttribute, value);
      else
        input.value = doc.cfg.elementValueTitle(refElement, value);
    } else if (hcontrol is h.SelectElement) {
      h.SelectElement select = hcontrol as h.SelectElement;
      // reset the options to remove invalid values
      while (select.options.length > 0)
        select.options[0].remove();
      for (String v in validValues) {
        h.OptionElement option = new h.OptionElement();
        if (refAttribute != null)
          option.text = doc.cfg.attributeValueTitle(refElement, refAttribute, v);
        else
          option.text = doc.cfg.elementValueTitle(refElement, v);
        if (v == value)
          option.selected = true;
        select.append(option);
      }
      if (!validValues.contains(value)) {
        // add this invalid value (will be removed at the next call to setValue with another value)
        h.OptionElement option = new h.OptionElement();
        option.text = value;
        option.selected = true;
        select.append(option);
        hcontrol.classes.add('invalid');
      }
      select.value = value;
    } else if (/*hcontrol is h.CheckboxInputElement*/
        hcontrol is h.InputElement && (hcontrol as h.InputElement).type == 'checkbox')
      (hcontrol as h.CheckboxInputElement).checked = (value == 'true' || value == '1');
  }
  
  void focus() {
    //TODO: update insert panel
    // to focus and move the cursor at the end :
    if (hcontrol is h.TextInputElement) {
      h.TextInputElement input = hcontrol as h.TextInputElement;
      // to work around a bug with Firefox (focus doesn't work)
      input.select();
      input.selectionStart = input.selectionEnd = input.value.length;
      // this works in Chromium but not Firefox :
      //input.onFocus.first.then((h.Event event) => input.selectionStart = input.selectionEnd = input.value.length);
      //input.focus();
    } else if (hcontrol != null) {
      hcontrol.focus();
    }
  }
  
  void showSuggestedValuesMenu(h.TextInputElement input) {
    h.DivElement div = popup.htmlMenu();
    div.style.position = 'absolute';
    div.style.display = 'block';
    h.Rectangle rect = input.getBoundingClientRect();
    div.style.left = "${rect.left}px";
    div.style.top = "${rect.bottom}px";
    div.style.width = "${rect.width}px";
    ((div.firstChild) as h.Element).style.width = "${rect.width}px"; // for the table
    h.document.body.append(div);
    StreamSubscription<h.MouseEvent> subscription = h.document.onMouseUp.listen(null);
    subscription.onData((h.MouseEvent event) {
      subscription.cancel();
      div.remove();
      event.preventDefault();
    });
  }
}
