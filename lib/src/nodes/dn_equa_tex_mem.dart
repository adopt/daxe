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
 * An equation using the TeX syntax. The image is encoded in base64
 * and added as text inside the element.
 * Requires a TeX equation server specified in the config file.
 * Jaxe display type: equatexmem, or a plugin with the class `xpages.JEEquaTeXMemoire`.
 * 
 * * parameter: `serveur`: the URL for the tex.php script converting equations into images
 * * parameter: `texteAtt`: the name of the attribute giving the equation text
 * * parameter: `labelAtt`: the name of the attribute giving the image label
 */
class DNEquaTexMem extends DaxeNode {
  h.ImageElement _img;
  String _textAtt;
  String _labelAtt;
  String _server;
  String _data;
  TeXEquationDialog _dlg;
  
  DNEquaTexMem.fromRef(x.Element elementRef) : super.fromRef(elementRef) {
    _textAtt = doc.cfg.elementParameterValue(ref, 'texteAtt', null);
    _labelAtt = doc.cfg.elementParameterValue(ref, 'labelAtt', null);
    _server = doc.cfg.elementParameterValue(ref, 'serveur', null);
  }
  
  DNEquaTexMem.fromNode(x.Node node, DaxeNode parent) : super.fromNode(node, parent, createChildren: false) {
    _textAtt = doc.cfg.elementParameterValue(ref, 'texteAtt', 'texte');
    _server = doc.cfg.elementParameterValue(ref, 'serveur', null);
    if (node.firstChild != null)
      _data = node.firstChild.nodeValue;
    else
      _data = null;
  }
  
  @override
  h.Element html() {
    //assert(doc.filePath != null);
    _img = new h.ImageElement();
    _img.attributes['id'] = "$id";
    _img.attributes['class'] = 'dn';
    if (_data != null) {
      String src = "data:image/png;base64,$_data";
      _img.attributes['src'] = src;
    }
    _img.onLoad.listen((h.Event event) => fixWidth());
    _img.onClick.listen((h.MouseEvent event) => attributeDialog());
    _img.style.verticalAlign = 'middle';
    return(_img);
  }
  
  void fixWidth() {
    if (_img.naturalWidth > 500) {
      _img.width = 500;
    }
  }
  
  @override
  Position firstCursorPositionInside() {
    return(null);
  }
  
  @override
  Position lastCursorPositionInside() {
    return(null);
  }
  
  @override
  void attributeDialog([ActionFunction okfct]) {
    String text = getAttribute(_textAtt);
    String labelValue = getAttribute(_labelAtt);
    _dlg = new TeXEquationDialog(_server, text,
        labelName: _labelAtt, labelValue: labelValue,
        okfct: () => afterAttributeDialog(okfct));
    _dlg.show();
  }
  
  void afterAttributeDialog(ActionFunction okfct) {
    if (okfct != null)
      okfct();
    String text = _dlg.getText();
    String label = _dlg.getLabel();
    if (okfct == null) {
      // existing element
      List<DaxeAttr> new_attributes = new List<DaxeAttr>();
      new_attributes.add(new DaxeAttr(_textAtt, text));
      if (_labelAtt != null && label != '')
        new_attributes.add(new DaxeAttr(_labelAtt, label));
      UndoableEdit edit = new UndoableEdit.changeAttributes(this, new_attributes, updateDisplay:false);
      doc.doNewEdit(edit);
    } else {
      // new element
      setAttribute(_textAtt, text);
      if (_labelAtt != null)
        setAttribute(_labelAtt, label);
    }
    updateData();
  }
  
  @override
  void updateAttributes() {
    updateData();
  }
  
  void updateData() {
    String text = getAttribute(_textAtt);
    getData(text).then((String data) {
      _data = data;
      updateHTML();
      page.moveCursorTo(new Position(parent, parent.offsetOf(this)+1));
    }, onError: (Object error) {
      h.window.alert(error.toString());
    });
  }
  
  Future<String> getData(String text) {
    if (text == null || text == '')
      text = '?';
    Completer<String> completer = new Completer<String>();
    String url = "$_server?${Uri.encodeComponent(text)}";
    // note: setting responseType does not work with synchronous requests
    // warning: arraybuffer is not supported by Internet Explorer before IE10
    h.HttpRequest.request(url, method: 'GET', responseType: 'arraybuffer'
        ).then((h.HttpRequest request) {
      Object response = request.response;
      // note : ByteBuffer and Uint8List are in dart:typed_data
      if (response is ByteBuffer) {
        Uint8List bytes = new Uint8List.view(response);
        String data = CryptoUtils.bytesToBase64(bytes);
        completer.complete(data);
      } else
        completer.completeError(new DaxeException('request response is not a ByteBuffer'));
    }, onError: (Object error) {
      completer.completeError(new DaxeException("Error getting the equation image from the server $_server : $error"));
    });
    return(completer.future);
  }
  
  @override
  x.Node toDOMNode(x.Document domDocument) {
    x.Element el = domDocument.createElementNS(namespaceURI, nodeName);
    for (DaxeAttr att in attributes)
      el.setAttributeNS(att.namespaceURI, att.name, att.value);
    if (_data != null)
      el.appendChild(domDocument.createTextNode(_data));
    return(el);
  }
}


/**
 * Dialog for DNEquaTexMem
 */
class TeXEquationDialog {
  String _equationText;
  String _labelName;
  String _labelValue;
  ActionFunction _okfct;
  String _server;
  String _data;
  
  
  TeXEquationDialog(this._server, String equationText,
      {String labelName, String labelValue, ActionFunction okfct}) {
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
    
    h.ImageElement img = new h.ImageElement();
    img.id = 'eqimg';
    img.src = getImgSrc();
    form.append(img);
    
    h.TextAreaElement ta = new h.TextAreaElement();
    ta.id = 'eqtext';
    if (_equationText != null)
      ta.value = _equationText;
    ta.style.width = '100%';
    ta.style.height = '4em';
    ta.attributes['spellcheck'] = 'false';
    ta.onInput.listen((h.Event event) => checkReturn());
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
    
    h.DivElement div_preview = new h.DivElement();
    h.ButtonElement bPreview = new h.ButtonElement();
    bPreview.appendText(Strings.get("equation.preview"));
    bPreview.onClick.listen((h.MouseEvent event) => preview(event));
    div_preview.append(bPreview);
    form.append(div_preview);
    
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
    // we can't always get the image data synchronously, this will be done later
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
  
  void updateData() {
    if (_equationText == '')
      return(null);
    h.ImageElement img = h.querySelector('img#eqimg');
    h.CanvasElement canvas = new h.CanvasElement(width: img.width, height: img.height);
    h.CanvasRenderingContext2D context = canvas.context2D;
    context.drawImage(img, 0, 0);
    String dataurl = canvas.toDataUrl('image/png');
    _data = dataurl.substring('data:image/png;base64,'.length);
  }
  
  String getLabel() {
    return(_labelValue);
  }
  
  String getImgSrc() {
    String text = _equationText;
    if (text == null || text == '')
      text = '?';
    return("$_server?${Uri.encodeComponent(text)}");
  }
  
  void updateImg() {
    h.ImageElement img = h.querySelector('img#eqimg');
    img.src = getImgSrc();
  }
  
  void preview(h.MouseEvent event) {
    event.preventDefault();
    h.TextAreaElement ta = h.querySelector('textarea#eqtext');
    _equationText = ta.value;
    updateImg();
  }
  
  void checkReturn() {
    h.TextAreaElement ta = h.querySelector('textarea#eqtext');
    String text = ta.value;
    if (text.length > 0 && text.contains('\n')) {
      ta.value = text.replaceAll('\n', '');
      ok(null);
      return;
    }
  }
}



