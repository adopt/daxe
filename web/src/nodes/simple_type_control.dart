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

class SimpleTypeControl {
  
  static int _n = 0;
  x.Element refElement;
  x.Element refAttribute;
  String value;
  String _uniqueName;
  List<String> values;
  List<String> suggestedValues;
  h.Element hcontrol;
  ActionFunction valueChanged;
  bool catchUndo;
  
  
  SimpleTypeControl.forElement(this.refElement, this.value, {this.valueChanged}) {
    refAttribute = null;
    _uniqueName = "control$_n";
    _n++;
    values = doc.cfg.elementValues(refElement);
    if (values == null || values.length == 0)
      suggestedValues = doc.cfg.elementSuggestedValues(refElement);
    else {
      if (!values.contains(''))
        values.add('');
    }
    catchUndo = true;
  }
  
  SimpleTypeControl.forAttribute(this.refElement, this.refAttribute, this.value,
      {this.valueChanged, this.catchUndo: false}) {
    _uniqueName = "control$_n";
    _n++;
    values = doc.cfg.attributeValues(refAttribute);
    if (values == null || values.length == 0)
      suggestedValues = doc.cfg.attributeSuggestedValues(refElement, refAttribute);
    else {
      String defaultValue = doc.cfg.defaultAttributeValue(refAttribute);
      if (!values.contains('') && defaultValue == null)
        values.add('');
    }
  }
  
  h.Element html() {
    h.SpanElement span = new h.SpanElement();
    bool booleanValues;
    final List<String> lvalbool = ['true', 'false', '1', '0'];
    if (values == null || values.length != lvalbool.length ||
        (value != null && !lvalbool.contains(value))) {
      booleanValues = false;
    } else {
      booleanValues = true;
      for (int i=0; i<values.length; i++) {
        if (values[i] != lvalbool[i]) {
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
    } else if (values == null || values.length == 0) {
      h.TextInputElement input = new h.TextInputElement();
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
        h.DataListElement datalist = new h.DataListElement();
        datalist.id = 'datalist_$_uniqueName';
        for (String v in suggestedValues) {
          h.OptionElement option = new h.OptionElement();
          option.value = v;
          datalist.append(option);
        }
        input.attributes['list'] = 'datalist_$_uniqueName';
        span.append(datalist);
      }
      span.append(input);
    } else {
      h.SelectElement select = new h.SelectElement();
      hcontrol = select;
      if (value == null)
        value = '';
      for (String v in values) {
        h.OptionElement option = new h.OptionElement();
        option.text = v;
        if (v == value) {
          option.defaultSelected = true;
          option.selected = true;
        }
        select.append(option);
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
    if (/*hcontrol is h.TextInputElement*/ /* pb with JS: bug 10383 */
        hcontrol is h.InputElement && (hcontrol as h.InputElement).type == 'text') {
      value = (hcontrol as h.TextInputElement).value;
    } else if (hcontrol is h.SelectElement)
      value = (hcontrol as h.SelectElement).value;
    else if (/*hcontrol is h.CheckboxInputElement*/
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
      valid = doc.cfg.isElementValueValid(refElement, value);
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
    if (hcontrol is h.TextInputElement)
      (hcontrol as h.TextInputElement).value = value;
    else if (hcontrol is h.SelectElement)
      (hcontrol as h.SelectElement).value = value;
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
    }
  }
}
