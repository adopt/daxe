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
 * Left panel to insert elements. It only displays the elements that can be inserted at
 * the cursor position, according to the schema.
 */
class InsertPanel {
  
  void update(DaxeNode parent, List<x.Element> refs, List<x.Element> validRefs) {
    h.Element divInsert = h.document.getElementById('insert');
    for (h.Element child in divInsert.children)
      child.remove();
    Config cfg = doc.cfg;
    if (cfg == null)
      return;
    if (parent.nodeType == DaxeNode.ELEMENT_NODE && parent.ref != null) {
      divInsert.append(_makeHelpButton(parent.ref));
      String name = cfg.elementName(parent.ref);
      h.SpanElement span = new h.SpanElement();
      span.appendText(cfg.menuTitle(name));
      divInsert.append(span);
      divInsert.append(new h.HRElement());
    }
    List<x.Element> toolbarRefs;
    if (page.toolbar != null)
      toolbarRefs = page.toolbar.elementRefs();
    else
      toolbarRefs = null;
    for (x.Element ref in refs) {
      if (toolbarRefs != null && toolbarRefs.contains(ref))
        continue;
      if (doc.hiddenp != null && ref == doc.hiddenp)
        continue;
      divInsert.append(_makeHelpButton(ref));
      h.ButtonElement button = new h.ButtonElement();
      button.attributes['type'] = 'button';
      button.classes.add('insertb');
      String name = cfg.elementName(ref);
      button.value = name;
      button.text = cfg.menuTitle(name);
      if (!validRefs.contains(ref))
        button.disabled = true;
      button.onClick.listen((h.Event event) => insert(ref));
      divInsert.append(button);
      divInsert.append(new h.BRElement());
    }
  }
  
  h.ButtonElement _makeHelpButton(x.Element ref) {
    h.ButtonElement bHelp = new h.ButtonElement();
    bHelp.attributes['type'] = 'button';
    bHelp.classes.add('help');
    bHelp.value = '?';
    bHelp.text = '?';
    String documentation = doc.cfg.documentation(ref);
    if (documentation != null)
      bHelp.title = documentation;
    bHelp.onClick.listen((h.Event event) => help(ref));
    return(bHelp);
  }
  
  void insert(x.Element ref) {
    doc.insertNewNode(ref, 'element');
  }
  
  void help(x.Element ref) {
    HelpDialog dlg = new HelpDialog.Element(ref);
    dlg.show();
  }
}
