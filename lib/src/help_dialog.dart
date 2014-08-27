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
 * Help dialog for an element or an attribute.
 */
class HelpDialog {
  x.Element elementRef;
  x.Element attributeRef;
  
  HelpDialog.Element(this.elementRef) {
  }
  
  HelpDialog.Attribute(this.attributeRef, this.elementRef) {
  }
  
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
    if (this.attributeRef == null)
      title.text = doc.cfg.elementTitle(elementRef);
    else
      title.text = doc.cfg.attributeTitle(elementRef, attributeRef);
    div3.append(title);
    
    String documentation;
    if (this.attributeRef == null)
      documentation = doc.cfg.documentation(elementRef);
    else
      documentation = doc.cfg.attributeDocumentation(elementRef, attributeRef);
    if (documentation != null) {
      documentation = Config.formatDoc(documentation);
      h.ParagraphElement p = new h.Element.html("<p>$documentation</p>");
      div3.append(p);
    }
    
    if (attributeRef == null) {
      String regexp = doc.cfg.regularExpression(elementRef);
      if (regexp != null) {
        h.DivElement divRegExp = new h.DivElement();
        divRegExp.classes.add('help_regexp');
        divRegExp.text = regexp;
        div3.append(divRegExp);
      }
      h.SpanElement titleParents = new h.SpanElement();
      titleParents.id = 'help_parents';
      titleParents.classes.add('help_list_title');
      titleParents.text = Strings.get('help.parents');
      titleParents.onClick.listen((h.MouseEvent event) => fillParents());
      div3.append(titleParents);
      h.SpanElement titleChildren = new h.SpanElement();
      titleChildren.id = 'help_children';
      titleChildren.classes.add('help_list_title');
      titleChildren.text = Strings.get('help.children');
      titleChildren.onClick.listen((h.MouseEvent event) => fillChildren());
      div3.append(titleChildren);
      h.SpanElement titleAttributes = new h.SpanElement();
      titleAttributes.id = 'help_attributes';
      titleAttributes.classes.add('help_list_title');
      titleAttributes.text = Strings.get('help.attributes');
      titleAttributes.onClick.listen((h.MouseEvent event) => fillAttributes());
      div3.append(titleAttributes);
      h.DivElement divList = new h.DivElement();
      divList.classes.add('help_list_div');
      h.UListElement ul = new h.UListElement();
      ul.id = 'help_list';
      divList.append(ul);
      div3.append(divList);
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
    
    if (attributeRef == null)
      fillChildren();
    
    bOk.focus();
  }
  
  void fillParents() {
    h.SpanElement titleParents = h.document.getElementById('help_parents');
    titleParents.classes.add('selected_tab');
    h.SpanElement titleChildren = h.document.getElementById('help_children');
    titleChildren.classes.remove('selected_tab');
    h.SpanElement titleAttributes = h.document.getElementById('help_attributes');
    titleAttributes.classes.remove('selected_tab');
    h.UListElement ul = h.document.getElementById('help_list');
    ul.nodes.clear();
    List<x.Element> parents = doc.cfg.parentElements(elementRef);
    for (x.Element parentRef in parents) {
      h.LIElement li = new h.LIElement();
      li.text = doc.cfg.elementTitle(parentRef);
      li.onClick.listen((h.MouseEvent event) => switchToElement(parentRef));
      li.classes.add('help_selectable');
      ul.append(li);
    }
  }
  
  void fillChildren() {
    h.SpanElement titleParents = h.document.getElementById('help_parents');
    titleParents.classes.remove('selected_tab');
    h.SpanElement titleChildren = h.document.getElementById('help_children');
    titleChildren.classes.add('selected_tab');
    h.SpanElement titleAttributes = h.document.getElementById('help_attributes');
    titleAttributes.classes.remove('selected_tab');
    h.UListElement ul = h.document.getElementById('help_list');
    ul.nodes.clear();
    List<x.Element> children = doc.cfg.subElements(elementRef);
    if (children == null)
      return;
    for (x.Element childRef in children) {
      h.LIElement li = new h.LIElement();
      li.text = doc.cfg.elementTitle(childRef);
      li.onClick.listen((h.MouseEvent event) => switchToElement(childRef));
      li.classes.add('help_selectable');
      ul.append(li);
    }
  }
  
  void fillAttributes() {
    h.SpanElement titleParents = h.document.getElementById('help_parents');
    titleParents.classes.remove('selected_tab');
    h.SpanElement titleChildren = h.document.getElementById('help_children');
    titleChildren.classes.remove('selected_tab');
    h.SpanElement titleAttributes = h.document.getElementById('help_attributes');
    titleAttributes.classes.add('selected_tab');
    h.UListElement ul = h.document.getElementById('help_list');
    ul.nodes.clear();
    List<x.Element> attributes = doc.cfg.elementAttributes(elementRef);
    for (x.Element attRef in attributes) {
      h.LIElement li = new h.LIElement();
      li.text = doc.cfg.attributeTitle(elementRef, attRef);
      ul.append(li);
    }
  }
  
  void switchToElement(x.Element elementRef) {
    this.elementRef = elementRef;
    attributeRef = null;
    h.DivElement div1 = h.document.getElementById('dlg1');
    div1.remove();
    show();
  }
  
  void close() {
    h.DivElement div1 = h.document.getElementById('dlg1');
    div1.remove();
    page.focusCursor();
  }
}


