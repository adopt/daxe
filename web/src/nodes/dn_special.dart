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
 * A symbol using UNICODE characters with a UNICODE font such as STIX.
 * Jaxe display type: 'symbole2'.
 */
class DNSpecial extends DaxeNode {
  
  SpecialDialog _dlg;
  String _character;
  
  
  DNSpecial.fromRef(x.Element elementRef) : super.fromRef(elementRef) {
  }
  
  DNSpecial.fromNode(x.Node node, DaxeNode parent) : super.fromNode(node, parent, createChildren: false) {
    _character = node.firstChild.nodeValue;
  }
  
  @override
  h.Element html() {
    h.Element span = new h.SpanElement();
    span.id = "$id";
    span.classes.add('dn');
    span.classes.add('special');
    span.text = _character;
    return(span);
  }
  
  @override
  void attributeDialog([ActionFunction okfct]) {
    _dlg = new SpecialDialog(_character, okfct:() {
      _character = _dlg.getChar();
      if (okfct != null)
        okfct();
    });
    _dlg.show();
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
  x.Node toDOMNode(x.Document domDocument) {
    x.Element el = domDocument.createElementNS(namespaceURI, nodeName);
    el.appendChild(domDocument.createTextNode(_character));
    return(el);
  }
}


/**
 * Dialog for DNSpecial
 */
class SpecialDialog {
  
  static final List<List<String>> symbols = [
    // uppercase greek
    ["\u0393", "\u0394", "\u0398", "\u039B", "\u039E", "\u03A0", "\u03A3", "\u03A5", "\u03A6", "\u03A7",
     "\u03A8", "\u03A9"],
    // lowercase greek
    ["\u03B1", "\u03B2", "\u03B3", "\u03B4", "\u03B5", "\u03B6", "\u03B7", "\u03B8",
     "\u03B9", "\u03BA", "\u03BB", "\u03BC", "\u03BD", "\u03BE", "\u03BF", "\u03C0", "\u03C1", "\u03C2", "\u03C3",
     "\u03C4", "\u03C5", "\u03C6", "\u03C7", "\u03C8", "\u03C9"],
    // greek symbols
    ["\u03D1", "\u03D5", "\u03D6"],
    // maths
    ["\u00AC", "\u00B1", "\u00D7", "\u2113", "\u2102", "\u2115", "\u211A", "\u211D", "\u2124", "\u212B",
     "\u2190", "\u2192", "\u2194", "\u21D0", "\u21D2", "\u21D4",
     "\u2200", "\u2202", "\u2203", "\u2205", "\u2207", "\u2208", "\u2209", "\u2211",
     "\u221D", "\u221E",
     "\u2227", "\u2228", "\u2229", "\u222A", "\u222B", "\u223C", "\u2248", "\u2260", "\u2261", "\u2264", "\u2265", "\u2282"],
    // uppercase cursive
    ["\u{1D49C}", "\u212C", "\u{1D49E}", "\u{1D49F}", "\u2130", "\u2131", "\u{1D4A2}", "\u210B",
     "\u2110", "\u{1D4A5}", "\u{1D4A6}", "\u2112", "\u2133", "\u{1D4A9}", "\u{1D4AA}",
     "\u{1D4AB}", "\u{1D4AC}", "\u211B", "\u{1D4AE}", "\u{1D4AF}", "\u{1D4B0}",
     "\u{1D4B1}", "\u{1D4B2}", "\u{1D4B3}", "\u{1D4B4}", "\u{1D4B5}"]
  ];
  static final int columns = 13; // number of character per line
  
  String character;
  ActionFunction okfct;
  h.TableCellElement selectedTD;
  
  SpecialDialog(this.character, {this.okfct}) {
    
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
    
    int rows = 0;
    for (int i=0; i<symbols.length; i++)
      rows += (symbols[i].length / columns).ceil();
    h.TableElement table = new h.TableElement();
    table.classes.add('special_dlg');
    int x = 0;
    for (int i=0; i<symbols.length; i++) {
      h.TableRowElement tr = new h.TableRowElement();
      for (int j=0; j<symbols[i].length; j++) {
        h.TableCellElement td = new h.TableCellElement();
        td.text = symbols[i][j];
        td.style.textAlign = 'center';
        if (character == symbols[i][j]) {
          selectedTD = td;
          selectedTD.style.border = '1px solid black';
        }
        tr.append(td);
        x++;
        if (x >= columns) {
          x = 0;
          if (j < symbols[i].length - 1) {
            table.append(tr);
            tr = new h.TableRowElement();
          }
        }
      }
      if (x != 0) {
        for (int k=x; k<columns; k++)
          tr.append(new h.TableCellElement());
        x = 0;
      }
      table.append(tr);
    }
    table.onClick.listen((h.MouseEvent event) => select(event.target));
    table.onDoubleClick.listen((h.MouseEvent event) {
      select(event.target);
      if (selectedTD != null)
        ok(null);
    });
    form.append(table);
    
    h.DivElement div_buttons = new h.DivElement();
    div_buttons.classes.add('buttons');
    h.ButtonElement bCancel = new h.ButtonElement();
    bCancel.attributes['type'] = 'button';
    bCancel.appendText(Strings.get("button.Cancel"));
    bCancel.onClick.listen((h.MouseEvent event) => cancel());
    div_buttons.append(bCancel);
    h.ButtonElement bOk = new h.ButtonElement();
    bOk.id = 'special_ok';
    if (character == null)
      bOk.disabled = true;
    bOk.attributes['type'] = 'submit';
    bOk.appendText(Strings.get("button.OK"));
    bOk.onClick.listen((h.MouseEvent event) => ok(event));
    div_buttons.append(bOk);
    form.append(div_buttons);
    
    div3.append(form);
    div2.append(div3);
    div1.append(div2);
    h.document.body.append(div1);
  }
  
  void select(h.EventTarget target) {
    if (target is! h.Node)
      return;
    h.Node n = target as h.Node;
    if (n is h.TableCellElement) {
      if (selectedTD != null)
        selectedTD.style.border = '';
      selectedTD = n;
    } else if (n.parent is h.TableCellElement) {
      if (selectedTD != null)
        selectedTD.style.border = null;
      selectedTD = n.parent;
    } else
      return;
    selectedTD.style.border = '1px solid black';
    character = selectedTD.text;
    h.ButtonElement bOk = h.querySelector('button#special_ok');
    bOk.disabled = false;
  }
  
  void ok(h.MouseEvent event) {
    h.querySelector('div#dlg1').remove();
    if (event != null)
      event.preventDefault();
    if (okfct != null)
      okfct();
  }
  
  void cancel() {
    h.querySelector('div#dlg1').remove();
    page.focusCursor();
  }
  
  String getChar() {
    return(character);
  }
  
}
