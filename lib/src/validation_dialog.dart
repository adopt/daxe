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
    
    List<DaxeNode> invalid = invalidElements(doc.dndoc);
    if (invalid.length == 0) {
      div3.appendText(Strings.get('validation.no_error'));
    } else {
      h.DivElement div4 = new h.DivElement();
      div4.style.maxHeight = '30em';
      div4.style.overflow = 'auto';
      div4.appendText(Strings.get('validation.errors'));
      h.UListElement ul = new h.UListElement();
      for (DaxeNode dn in invalid) {
        h.LIElement li = new h.LIElement();
        String title;
        if (dn.ref != null)
          title = doc.cfg.elementTitle(dn.ref);
        else
          title = null;
        Position pos = new Position(dn, 0);
        String itemText;
        if (title != null)
          itemText = "$title ${pos.xPath()}";
        else
          itemText = pos.xPath();
        li.appendText(itemText);
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
  }
  
  List<DaxeNode> invalidElements(DaxeNode dn) {
    List<DaxeNode> invalid = new List<DaxeNode>();
    if (dn.nodeType == DaxeNode.ELEMENT_NODE && dn is! DNCData) {
      // note: empty DNForm nodes are ignored unless they are required
      if (dn.parent is DNForm) {
        bool required = doc.cfg.requiredElement(dn.parent.ref, dn.ref);
        if (required && dn.firstChild == null) {
          invalid.add(dn);
          return(invalid);
        } else if (!required && dn.firstChild == null && (dn.attributes == null || dn.attributes.length == 0)) {
          return(invalid);
        }
      }
      if (!doc.cfg.elementIsValid(dn))
        invalid.add(dn);
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
