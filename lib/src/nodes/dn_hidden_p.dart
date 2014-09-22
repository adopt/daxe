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
 * Invisible paragraph, inserted automatically when a newline is added
 * at a place where the element is allowed.
 * It must be able to contain text.
 * Jaxe display type: 'hiddenp'.
 */
class DNHiddenP extends DaxeNode {
  String _styleAtt;
  
  DNHiddenP.fromRef(x.Element elementRef) : super.fromRef(elementRef) {
    _styleAtt = doc.cfg.elementParameterValue(ref, 'styleAtt', 'style');
  }
  
  DNHiddenP.fromNode(x.Node node, DaxeNode parent) : super.fromNode(node, parent) {
    _styleAtt = doc.cfg.elementParameterValue(ref, 'styleAtt', 'style');
    
    // remove all newlines, and spaces at the beginning and the end
    DaxeNode next;
    for (DaxeNode dn=firstChild; dn != null; dn=next) {
      next = dn.nextSibling;
      if (dn is DNText) {
        String s = dn.nodeValue;
        if (dn.previousSibling == null)
          while (s.startsWith(' '))
            s = s.substring(1);
        if (dn.nextSibling == null)
          while (s.endsWith(' '))
            s = s.substring(0, s.length-1);
        s = s.replaceAll('\n', '');
        if (s.length == 0)
          removeChild(dn);
        else
          dn.nodeValue = s;
      }
    }
  }
  
  @override
  h.Element html() {
    h.DivElement div = new h.DivElement();
    div.id = "$id";
    div.classes.add('dn');
    if (!valid)
      div.classes.add('invalid');
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
    return(div);
  }
  
  @override
  h.Element getHTMLContentsNode() {
    return(getHTMLNode());
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
  bool get noDelimiter {
    return(true);
  }
  
  @override
  bool newlineAfter() {
    return(true);
  }
  
  void set css(String value) {
    setAttribute(_styleAtt, value);
  }
  
  String get css {
    return(getAttribute(_styleAtt));
  }
  
  static void removeStyleFromSelection(String cssName) {
    List<DNHiddenP> list = paragraphsInSelection();
    if (list.length == 0)
      return;
    UndoableEdit compound = new UndoableEdit.compound(Strings.get('style.remove_styles'));
    for (DNHiddenP p in list) {
      UndoableEdit edit = _removeStyleFromNodeEdit(p, cssName);
      if (edit != null)
        compound.addSubEdit(edit);
    }
    doc.doNewEdit(compound);
    page.cursor.refresh();
  }
  
  static UndoableEdit _removeStyleFromNodeEdit(DNHiddenP p, String cssName) {
    if (p.css == null)
      return(null);
    List<String> cssArray = p.css.split(';');
    for (String cssEntry in cssArray) {
      if (cssEntry.startsWith("${cssName}:")) {
        cssArray.remove(cssEntry);
        DaxeAttr att = p.getAttributeNode(p._styleAtt);
        att.value = cssArray.join(';');
        return(new UndoableEdit.changeAttributes(p, [att], updateDisplay:true));
      }
    }
    return(null);
  }
  
  static void applyStyleToSelection(String cssName, String css) {
    List<DNHiddenP> list = paragraphsInSelection();
    if (list.length == 0)
      return;
    UndoableEdit compound = new UndoableEdit.compound(Strings.get('style.apply_style'));
    for (DNHiddenP p in list) {
      UndoableEdit edit = _applyStyleOnNodeEdit(p, cssName, css);
      if (edit != null)
        compound.addSubEdit(edit);
    }
    doc.doNewEdit(compound);
    page.cursor.refresh();
  }
  
  static UndoableEdit _applyStyleOnNodeEdit(DNHiddenP p, String cssName, String css) {
    List<String> cssArray;
    if (p.css == null)
      cssArray = new List<String>();
    else
      cssArray = p.css.split(';');
    String matchingEntry = null;
    for (String cssEntry in cssArray) {
      if (cssEntry.startsWith("${cssName}:")) {
        matchingEntry = cssEntry;
        break;
      }
    }
    if (matchingEntry != null)
      cssArray.remove(matchingEntry);
    cssArray.add(css);
    DaxeAttr att = p.getAttributeNode(p._styleAtt);
    if (att == null)
      att = new DaxeAttr(p._styleAtt, cssArray.join(';'));
    else
      att.value = cssArray.join(';');
    return(new UndoableEdit.changeAttributes(p, [att], updateDisplay:true));
  }
  
  static List<DNHiddenP> paragraphsInSelection() {
    List<DNHiddenP> list = new List<DNHiddenP>();
    Position start = page.getSelectionStart();
    Position end = page.getSelectionEnd();
    DaxeNode parent = start.dn;
    while (parent != null && parent is! DNHiddenP)
      parent = parent.parent;
    DaxeNode current;
    if (parent is DNHiddenP)
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
    if (current is DNHiddenP)
      list.add(current);
    // using DaxeNode.nextNode() to iterate through the nodes between start and end
    if (current.parent == null)
      return(list);
    Position nextPos = new Position(current.parent, current.parent.offsetOf(current)+1);
    while (nextPos < end) {
      current = current.nextNode();
      if (current == null)
        break;
      if (current is DNHiddenP)
        list.add(current);
      nextPos = new Position(current.parent, current.parent.offsetOf(current)+1);
    }
    return(list);
  }
  
  /**
   * Called by DaxeDocument when a newline character is inserted.
   * Creates additional paragraphs as necessary.
   * Returns true if the event was handled.
   */
  static bool handleNewlineOnSelection() {
    Position selectionStart = page.getSelectionStart();
    Position selectionEnd = page.getSelectionEnd();
    // note: it is assumed that DNStyle and DNText are allowed in DNHiddenP and
    // DNHiddenP is not allowed in DNStyle.
    // paragraph cuts are only done inside text or style nodes
    DaxeNode textParent = selectionStart.dn;
    int offset = selectionStart.dnOffset;
    while (textParent is DNText || textParent is DNStyle) {
      offset = textParent.parent.offsetOf(textParent);
      textParent = textParent.parent;
    }
    if (textParent is DNHiddenP) {
      // We are in a paragraph, and will need to create another one after the current one,
      // with the fragment to the right of the cursor inside the paragraph.
      UndoableEdit edit = new UndoableEdit.compound(Strings.get('undo.insert_text'));
      DNHiddenP p = textParent;
      Position ppos = new Position(p.parent, p.parent.offsetOf(p));
      Position pstart = new Position(p, 0);
      Position pend = new Position(p, p.offsetLength);
      assert(selectionEnd <= pend); // the selection should not cut the paragraph
      DaxeNode cloneLeft = doc.cloneCutBetween(p, pstart, selectionStart);
      DaxeNode cloneRight = doc.cloneCutBetween(p, selectionEnd, pend);
      edit.addSubEdit(new UndoableEdit.removeNode(p));
      edit.addSubEdit(new UndoableEdit.insertNode(ppos, cloneRight));
      edit.addSubEdit(new UndoableEdit.insertNode(ppos, cloneLeft));
      doc.doNewEdit(edit);
      page.moveCursorTo(new Position(cloneRight, 0));
      page.updateAfterPathChange();
      return(true);
    }
    if (selectionStart.dn != selectionEnd.dn)
      return(false);
    if (textParent.ref == null)
      return(false);
    if (textParent is DNHiddenP)
      return(false);
    x.Element hiddenp = doc.cfg.findSubElement(textParent.ref, doc.hiddenParaRefs);
    if (hiddenp == null)
      return(false);
    if (!doc.cfg.insertIsPossible(textParent, offset, offset, hiddenp))
      return(false);
    
    // There is no paragraph, we need to create one or two.
    // Enclose all possible text and markup to the left of selectionStart
    // in a new hidden paragraph,
    // and create another one afterwards with what can be moved inside
    // from the right of selectionStart.
    UndoableEdit edit = new UndoableEdit.compound(Strings.get('undo.insert_text'));
    
    // clone the nodes that will be in the first paragraph
    int startOffset = offset;
    while (startOffset > 0) {
      DaxeNode child = textParent.childAtOffset(startOffset-1);
      if (child is! DNText && !doc.cfg.isSubElement(hiddenp, child.ref))
        break;
      startOffset--;
    }
    Position pStart = new Position(textParent, startOffset);
    DaxeNode cloneLeft = null;
    if (pStart < selectionStart)
      cloneLeft = doc.cloneCutBetween(textParent, pStart, selectionStart);
    
    // clone the nodes that will be in the second paragraph
    DaxeNode endParent = selectionEnd.dn;
    int endOffset = selectionEnd.dnOffset;
    while (endParent is DNText || endParent is DNStyle) {
      endOffset = endParent.parent.offsetOf(endParent) + 1;
      endParent = endParent.parent;
    }
    assert(endParent == textParent);
    while (endOffset < textParent.offsetLength) {
      DaxeNode child = textParent.childAtOffset(endOffset);
      if (child is! DNText && !doc.cfg.isSubElement(hiddenp, child.ref))
        break;
      endOffset++;
    }
    Position pEnd = new Position(textParent, endOffset);
    DaxeNode cloneRight = null;
    if (pEnd > selectionEnd) {
      cloneRight = doc.cloneCutBetween(textParent, selectionEnd, pEnd);
      // remove possible \n at the end
      DaxeNode lastChild = cloneRight.childAtOffset(cloneRight.offsetLength-1); 
      if (lastChild is DNText) {
        String text = lastChild.nodeValue;
        if (text.length > 0 && text[text.length-1] == '\n') {
          if (text.length == 1)
            cloneRight.removeChild(lastChild);
          else
            lastChild.nodeValue = text.substring(0, text.length - 1);
        }
      }
    }
    
    if (pStart < pEnd) {
      // remove everything moved and the selection
      edit.addSubEdit(doc.removeBetweenEdit(pStart, pEnd));
    }
    
    int p2offset = startOffset;
    
    // create the first paragraph if necessary
    if (cloneLeft != null) {
      DNHiddenP p1 = NodeFactory.create(hiddenp);
      edit.addSubEdit(new UndoableEdit.insertNode(pStart, p1));
      edit.addSubEdit(doc.insertChildrenEdit(cloneLeft, new Position(p1, 0)));
      p2offset++;
    }
    
    // create the second paragraph
    DNHiddenP p2 = NodeFactory.create(hiddenp);
    edit.addSubEdit(new UndoableEdit.insertNode(
        new Position(textParent, p2offset), p2));
    if (cloneRight != null)
      edit.addSubEdit(doc.insertChildrenEdit(cloneRight, new Position(p2, 0)));
    
    doc.doNewEdit(edit);
    page.moveCursorTo(new Position(p2, 0));
    page.updateAfterPathChange();
    return(true);
  }
  
  /**
   * Adjust hidden paragraphs in fragment before insert
   */
  static void fixFragment(DaxeNode parent, DaxeNode fragment) {
    if (doc.hiddenParaRefs == null)
      return;
    // do not put a hidden paragraph where it is not allowed (remove one level)
    DaxeNode next;
    for (DaxeNode dn2=fragment.firstChild; dn2 != null; dn2=next) {
      next = dn2.nextSibling;
      if (dn2 is DNHiddenP && !doc.cfg.isSubElement(parent.ref, dn2.ref)) {
        DaxeNode next2;
        for (DaxeNode dn3=dn2.firstChild; dn3 != null; dn3=next2) {
          next2 = dn3.nextSibling;
          dn2.removeChild(dn3);
          fragment.insertBefore(dn3, dn2);
        }
        fragment.removeChild(dn2);
      }
    }
    x.Element hiddenp = doc.cfg.findSubElement(parent.ref, doc.hiddenParaRefs);
    if (hiddenp != null) {
      // add hidden paragraphs if necessary
      for (DaxeNode dn2=fragment.firstChild; dn2 != null; dn2=next) {
        next = dn2.nextSibling;
        if (dn2.ref != hiddenp &&
            ((dn2 is DNText && !doc.cfg.canContainText(parent.ref)) ||
            (!doc.cfg.isSubElement(parent.ref, dn2.ref) &&
                doc.cfg.isSubElement(hiddenp, dn2.ref)))) {
          fragment.removeChild(dn2);
          if (dn2.previousSibling != null && dn2.previousSibling.ref == hiddenp) {
            dn2.previousSibling.appendChild(dn2);
          } else {
            DNHiddenP p = new DNHiddenP.fromRef(hiddenp);
            p.appendChild(dn2);
            fragment.insertBefore(p, next);
          }
        }
      }
    }
  }
}
