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

part of equations;

class EquationDialog {
  String _equationText;
  String _labelName;
  String _labelValue;
  ActionFunction _okfct;
  MathBase _base;
  
  
  EquationDialog(String equationText, {String labelName, String labelValue, ActionFunction okfct}) {
    _equationText = equationText;
    _labelName = labelName;
    _labelValue = labelValue;
    _okfct = okfct;
  }
  
  void show() {
    h.DivElement div1 = new h.DivElement();
    div1.id = 'dlg1';
    div1.classes.add('dlg1');
    h.DivElement div2 = new h.DivElement();
    div2.classes.add('dlg2');
    h.DivElement div3 = new h.DivElement();
    div3.classes.add('dlg3');
    h.FormElement form = new h.FormElement();
    
    h.CanvasElement canvas = new h.CanvasElement(width:500, height: 300);
    canvas.id = 'eqcanvas';
    StringMathBuilder sb = new StringMathBuilder(_equationText);
    _base = new MathBase(element:sb.getMathRootElement(), context:canvas.context2D);
    _base.paint(canvas.context2D);
    form.append(canvas);
    
    h.TextAreaElement ta = new h.TextAreaElement();
    ta.id = 'eqtext';
    ta.value = _equationText;
    ta.style.width = '100%';
    ta.style.height = '4em';
    ta.attributes['spellcheck'] = 'false';
    ta.onInput.listen((h.Event event) => updateDisplay());
    form.append(ta);
    
    if (_labelName != null) {
      h.DivElement div_label = new h.DivElement();
      h.SpanElement label_name = new h.SpanElement();
      label_name.text = _labelName;
      div_label.append(label_name);
      div_label.appendText(' ');
      h.TextInputElement input_label = new h.TextInputElement();
      input_label.id = 'eqlabel';
      if (_labelValue != null)
        input_label.value = _labelValue;
      div_label.append(input_label);
      form.append(div_label);
    }
    
    h.DivElement div_buttons = new h.DivElement();
    div_buttons.classes.add('buttons');
    h.ButtonElement bCancel = new h.ButtonElement();
    bCancel.attributes['type'] = 'button';
    bCancel.appendText(Strings.get("button.Cancel"));
    bCancel.onClick.listen((h.MouseEvent event) => div1.remove());
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
    
    ta.focus();
  }
  
  void ok(h.MouseEvent event) {
    h.TextAreaElement ta = h.querySelector('textarea#eqtext');
    _equationText = ta.value;
    if (_labelName != null) {
      h.TextInputElement input_label = h.querySelector('input#eqlabel');
      _labelValue = input_label.value;
    }
    h.querySelector('div#dlg1').remove();
    if (event != null)
      event.preventDefault();
    if (_okfct != null)
      _okfct();
  }
  
  String getText() {
    return(_equationText);
  }
  
  String getData() {
    if (_equationText == '')
      return(null);
    h.CanvasElement canvas2 = new h.CanvasElement(width:_base.getWidth(), height:_base.getHeight());
    StringMathBuilder sb = new StringMathBuilder(_equationText);
    MathBase base2 = new MathBase(element:sb.getMathRootElement(), context:canvas2.context2D);
    base2.paint(canvas2.context2D);
    String dataurl = canvas2.toDataUrl('image/png');
    String data = dataurl.substring('data:image/png;base64,'.length);
    return(data);
  }
  
  String getLabel() {
    return(_labelValue);
  }
  
  void updateDisplay() {
    h.TextAreaElement ta = h.querySelector('textarea#eqtext');
    _equationText = ta.value;
    if (_equationText.length > 0 && _equationText.contains('\n')) {
      ta.value = _equationText.replaceAll('\n', '');
      ok(null);
      return;
    }
    h.CanvasElement canvas = h.querySelector('canvas#eqcanvas');
    StringMathBuilder sb = new StringMathBuilder(_equationText);
    _base.setRootElement(sb.getMathRootElement());
    _base.paint(canvas.context2D);
  }
}
