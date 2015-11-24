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
 * Dialog with a list of XML validation errors.
 * A click on an error displays the matching element.
 */
class ValidationDialog {
  
  void show() {
    h.DivElement div1 = new h.DivElement();
    div1.id = 'dlg1';
    div1.classes.add('dlg1');
    h.DivElement div2 = new h.DivElement();
    div2.classes.add('dlg2');
    h.DivElement div3 = new h.DivElement();
    div3.classes.add('dlg3');
    h.DivElement title = new h.DivElement();
    title.classes.add('dlgtitle');
    title.text = Strings.get('validation.validation');
    div3.append(title);
    
    List<NodeAndMessage> invalid = invalidElements(doc.dndoc);
    if (invalid.length == 0) {
      div3.appendText(Strings.get('validation.no_error'));
    } else {
      h.DivElement div4 = new h.DivElement();
      div4.classes.add('validation_div');
      div4.appendText(Strings.get('validation.errors'));
      h.UListElement ul = new h.UListElement();
      for (NodeAndMessage nm in invalid) {
        DaxeNode dn = nm.dn;
        h.LIElement li = new h.LIElement();
        if (dn.ref != null)
          li.appendText(doc.cfg.elementTitle(dn.ref) + ' ');
        h.SpanElement span = new h.SpanElement();
        span.classes.add('validation_path');
        Position pos = new Position(dn, 0);
        span.appendText(pos.xPath());
        li.append(span);
        li.appendText('\u00a0:');
        li.append(new h.BRElement());
        li.appendText(nm.message);
        li.onClick.listen((h.MouseEvent event) => select(dn));
        li.style.cursor = 'default';
        ul.append(li);
      }
      div4.append(ul);
      div3.append(div4);
    }
    
    h.DivElement div_buttons = new h.DivElement();
    div_buttons.classes.add('buttons');
    h.ButtonElement bOk = new h.ButtonElement();
    bOk.attributes['type'] = 'submit';
    bOk.appendText(Strings.get("button.Close"));
    bOk.onClick.listen((h.MouseEvent event) => close());
    div_buttons.append(bOk);
    div3.append(div_buttons);
    
    div2.append(div3);
    div1.append(div2);
    h.document.body.append(div1);
    bOk.focus();
  }
  
  List<NodeAndMessage> invalidElements(DaxeNode dn) {
    List<NodeAndMessage> invalid = new List<NodeAndMessage>();
    if (dn.nodeType == DaxeNode.ELEMENT_NODE) {
      // note: empty DNForm nodes are ignored unless they are required
      if (dn.parent is DNForm && dn.ref != null) {
        bool required = doc.cfg.requiredElement(dn.parent.ref, dn.ref);
        if (required && dn.firstChild == null) {
          invalid.add(new NodeAndMessage(dn, Strings.get('validation.required_inside_form')));
          return(invalid);
        } else if (!required && dn.firstChild == null && (dn.attributes == null || dn.attributes.length == 0)) {
          return(invalid);
        }
      }
      try {
        doc.cfg.testValidity(dn);
      } on DaxeException catch(ex) {
        invalid.add(new NodeAndMessage(dn, ex.message));
      }
    }
    for (DaxeNode child=dn.firstChild; child != null; child=child.nextSibling)
      invalid.addAll(invalidElements(child));
    
    return(invalid);
  }
  
  void select(DaxeNode dn) {
    h.DivElement div1 = h.document.getElementById('dlg1');
    div1.remove();
    page.selectNode(dn);
  }
  
  void close() {
    h.DivElement div1 = h.document.getElementById('dlg1');
    div1.remove();
    page.focusCursor();
  }
}

class NodeAndMessage {
  DaxeNode dn;
  String message;
  NodeAndMessage(this.dn, this.message);
}
