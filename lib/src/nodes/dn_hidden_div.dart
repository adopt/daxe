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
 * Invisible block with CSS style, using only the style attribute.
 * Tags are displayed if the style attribute is empty.
 * 
 * Display type: 'hiddendiv'.
 */
class DNHiddenDiv extends DaxeNode {
  String _styleAtt;
  
  DNHiddenDiv.fromRef(x.Element elementRef) : super.fromRef(elementRef) {
    _styleAtt = doc.cfg.elementParameterValue(ref, 'styleAtt', 'style');
  }
  
  DNHiddenDiv.fromNode(x.Node node, DaxeNode parent) : super.fromNode(node, parent) {
    _styleAtt = doc.cfg.elementParameterValue(ref, 'styleAtt', 'style');
    fixLineBreaks();
  }
  
  @override
  h.Element html() {
    h.DivElement div = new h.DivElement();
    div.id = "$id";
    div.classes.add('dn');
    div.classes.add('block');
    if (!valid)
      div.classes.add('invalid');
    if (noDelimiter) { // TODO: support CSS classes
      if (css != null)
        div.setAttribute('style', css);
      // FIXME: align:justify is incompatible with whitespace:pre-wrap
      for (DaxeNode dn = firstChild; dn != null; ) {
        div.append(dn.html());
        dn = dn.nextSibling;
      }
      if (lastChild == null || lastChild.nodeType == DaxeNode.TEXT_NODE)
        div.appendText('\n');
      //this kind of conditional HTML makes it hard to optimize display updates:
      //we have to override updateHTMLAfterChildrenChange
      // also, it seems that in IE this adds a BR instead of a text node !
    } else {
      Tag b1 = new Tag(this, Tag.START, true);
      Tag b2 = new Tag(this, Tag.END, true);
      div.append(b1.html());
      h.DivElement contents = new h.DivElement();
      contents.classes.add('indent');
      if (css != null)
        contents.setAttribute('style', css);
      DaxeNode dn = firstChild;
      while (dn != null) {
        contents.append(dn.html());
        dn = dn.nextSibling;
      }
      if (lastChild == null || lastChild.nodeType == DaxeNode.TEXT_NODE)
        contents.appendText('\n');
      div.append(contents);
      div.append(b2.html());
    }
    return(div);
  }
  
  @override
  h.Element getHTMLContentsNode() {
    if (noDelimiter)
      return(getHTMLNode());
    else
      return(getHTMLNode().nodes[1]);
  }
  
  @override
  void updateHTMLAfterChildrenChange(List<DaxeNode> changed) {
    super.updateHTMLAfterChildrenChange(changed);
    h.DivElement contents = getHTMLContentsNode();
    if (contents.nodes.length > 0) {
      h.Node hn = contents.nodes.first;
      while (hn != null) {
        h.Node next = hn.nextNode;
        if (hn is h.Text || hn is h.BRElement)
          hn.remove();
        hn = next;
      }
    }
    if (lastChild == null || lastChild.nodeType == DaxeNode.TEXT_NODE)
      contents.appendText('\n');
  }
  
  @override
  void updateAttributes() {
    super.updateHTML();
  }
  
  @override
  bool newlineAfter() {
    return(true);
  }
  
  @override
  bool get noDelimiter {
    return(getAttribute('style') != null);
  }
  
  void set css(String value) {
    setAttribute(_styleAtt, value);
  }
  
  String get css {
    return(getAttribute(_styleAtt));
  }
  
  /**
   * Remove the div without removing its content.
   */
  void removeDiv() {
    UndoableEdit edit = new UndoableEdit.compound(Strings.get('undo.remove_element'));
    DaxeNode content = doc.cloneBetween(new Position(this, 0), new Position(this, offsetLength));
    if (doc.hiddenParaRefs != null) {
      // add or remove hidden paragraphs where necessary
      DNHiddenP.fixFragment(parent, content);
    }
    edit.addSubEdit(new UndoableEdit.removeNode(this));
    edit.addSubEdit(doc.insertChildrenEdit(content, new Position(parent, parent.offsetOf(this)), checkValidity:false));
    doc.doNewEdit(edit);
  }
  
  static void removeStyleFromSelection(String cssName) {
    List<DNHiddenDiv> list = divsInSelection();
    if (list.length == 0)
      return;
    UndoableEdit compound = new UndoableEdit.compound(Strings.get('style.remove_styles'));
    for (DNHiddenDiv dn in list) {
      UndoableEdit edit = _removeStyleFromNodeEdit(dn, cssName);
      if (edit != null)
        compound.addSubEdit(edit);
    }
    doc.doNewEdit(compound);
    page.cursor.refresh();
  }
  
  static UndoableEdit _removeStyleFromNodeEdit(DNHiddenDiv dn, String cssName) {
    if (dn.css == null)
      return(null);
    CSSMap cssMap = new CSSMap(dn.css);
    if (cssMap[cssName] != null) {
      cssMap.remove(cssName);
      String newCss = cssMap.toString();
      DaxeAttr att = dn.getAttributeNode(dn._styleAtt);
      att.value = newCss;
      return(new UndoableEdit.changeAttributes(dn, [att], updateDisplay:true));
    }
    return(null);
  }
  
  static void applyStyleToSelection(String cssName, String cssValue) {
    List<DNHiddenDiv> list = divsInSelection();
    if (list.length == 0)
      return;
    UndoableEdit compound = new UndoableEdit.compound(Strings.get('style.apply_style'));
    for (DNHiddenDiv dn in list) {
      UndoableEdit edit = _applyStyleOnNodeEdit(dn, cssName, cssValue);
      if (edit != null)
        compound.addSubEdit(edit);
    }
    doc.doNewEdit(compound);
    page.cursor.refresh();
  }
  
  static UndoableEdit _applyStyleOnNodeEdit(DNHiddenDiv dn, String cssName, String cssValue) {
    CSSMap cssMap = new CSSMap(dn.css);
    cssMap[cssName] = cssValue;
    String newCss = cssMap.toString();
    DaxeAttr att = dn.getAttributeNode(dn._styleAtt);
    if (att == null)
      att = new DaxeAttr(dn._styleAtt, newCss);
    else
      att.value = newCss;
    return(new UndoableEdit.changeAttributes(dn, [att], updateDisplay:true));
  }
  
  static List<DNHiddenDiv> divsInSelection() {
    List<DNHiddenDiv> list = new List<DNHiddenDiv>();
    Position start = page.getSelectionStart();
    Position end = page.getSelectionEnd();
    DaxeNode parent = start.dn;
    while (parent != null && parent is! DNHiddenDiv)
      parent = parent.parent;
    DaxeNode current;
    if (parent is DNHiddenDiv)
      current = parent;
    else if (start.dn is DNText)
      current = start.dn.parent;
    else if (start.dnOffset < start.dn.offsetLength)
      current = start.dn.childAtOffset(start.dnOffset);
    else if (start.dn.offsetLength == 0)
      current = start.dn;
    else // start.dnOffset == start.dn.offsetLength > 0
      current = start.dn.lastChild.nextNode();
    if (current == null)
      return(list);
    if (current is DNHiddenDiv)
      list.add(current);
    // using DaxeNode.nextNode() to iterate through the nodes between start and end
    if (current.parent == null)
      return(list);
    Position nextPos = new Position(current.parent, current.parent.offsetOf(current)+1);
    while (nextPos < end) {
      current = current.nextNode();
      if (current == null)
        break;
      if (current is DNHiddenDiv)
        list.add(current);
      nextPos = new Position(current.parent, current.parent.offsetOf(current)+1);
    }
    return(list);
  }
  
}
