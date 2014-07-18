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
 * An equation using the Jaxe syntax. The image is encoded in base64
 * and added as text inside the element.
 * Jaxe display type: equationmem, or a plugin with the class `xpages.JEEquationMemoire`.
 * 
 * * parameter: `texteAtt`: the name of the attribute giving the equation text
 * * parameter: `labelAtt`: the name of the attribute giving the image label
 */
class DNEquationMem extends DaxeNode {
  h.ImageElement _img;
  String _textAtt;
  String _data;
  EquationDialog _dlg;
  
  
  DNEquationMem.fromRef(x.Element elementRef) : super.fromRef(elementRef) {
    _textAtt = doc.cfg.elementParameterValue(ref, 'texteAtt', 'src');
    MathBase.loadFonts();
  }
  
  DNEquationMem.fromNode(x.Node node, DaxeNode parent) : super.fromNode(node, parent, createChildren: false) {
    _textAtt = doc.cfg.elementParameterValue(ref, 'texteAtt', 'src');
    if (node.firstChild != null)
      _data = node.firstChild.nodeValue.replaceAll('\n', '');
    else
      _data = null;
    MathBase.loadFonts();
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
    if (text == null)
      text = '';
    _dlg = new EquationDialog(text, okfct:() {
      String text = _dlg.getText();
      if (getHTMLNode() != null) {
        DaxeAttr attr = new DaxeAttr(_textAtt, text);
        UndoableEdit edit = new UndoableEdit.changeAttribute(this, attr, updateDisplay:false);
        doc.doNewEdit(edit);
      } else {
        setAttribute(_textAtt, text);
      }
      _data = _dlg.getData();
      if (_img != null) {
        String src = "data:image/png;base64,$_data";
        _img.attributes['src'] = src;
      }
      if (okfct != null)
        okfct();
      
      //delayed cursor update (the image is still loading)
      _img.onLoad.listen((h.Event e) => page.moveCursorTo(new Position(parent, parent.offsetOf(this)+1)));
    });
    _dlg.show();
  }
  
  @override
  void updateAttributes() {
    // this is called whenever the attributes change, for instance after undo/redo,
    // except after attributeDialog because the data and HTML are already updated
    updateData();
    updateHTML();
  }
  
  void updateData() {
    String equationText = getAttribute(_textAtt);
    StringMathBuilder sb = new StringMathBuilder(equationText);
    h.CanvasElement canvas = new h.CanvasElement(width:500, height: 300);
    MathBase _base = new MathBase(element:sb.getMathRootElement(), context:canvas.context2D);
    h.CanvasElement canvas2 = new h.CanvasElement(width:_base.getWidth(), height:_base.getHeight());
    MathBase base2 = new MathBase(element:sb.getMathRootElement(), context:canvas2.context2D);
    base2.paint(canvas2.context2D);
    String dataurl = canvas2.toDataUrl('image/png');
    _data = dataurl.substring('data:image/png;base64,'.length);
  }
  
  @override
  x.Node toDOMNode(x.Document domDocument) {
    x.Element el = domDocument.createElementNS(namespaceURI, nodeName);
    for (DaxeAttr att in attributes)
      el.setAttributeNS(att.namespaceURI, att.name, att.value);
    if (_data != null) {
      StringBuffer sb = new StringBuffer();
      String towrite = _data;
      while (towrite != '') {
        if (towrite.length <= 76) {
          sb.write(towrite);
          towrite = '';
        } else {
          sb.writeln(towrite.substring(0, 76));
          towrite = towrite.substring(76);
        }
      }
      el.appendChild(domDocument.createTextNode(sb.toString()));
    }
    return(el);
  }
}


