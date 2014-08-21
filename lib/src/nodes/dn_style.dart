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
 * Style node (changes the style without showing tags).
 * Jaxe display type: 'style'.
 * 
 * parameter: `style`: `GRAS` (bold) | `ITALIQUE` (italic) | `EXPOSANT` (superscript) |
 * `INDICE` (subscript) | `SOULIGNE` (underlined) | `BARRE` (strikethrough) |
 * `PCOULEUR[###,###,###]` (text color) | `FCOULEUR[###,###,###]` (background color)
 * (several styles can be combined with a ';')
 * 
 * parameter: 'police' (font)
 * 
 * parameter: 'taille' (size)
 */
class DNStyle extends DaxeNode {
  
  String _style;
  
  DNStyle.fromRef(x.Element elementRef) : super.fromRef(elementRef) {
    _style = doc.cfg.elementParameterValue(elementRef, 'style', null);
  }
  
  DNStyle.fromNode(x.Node node, DaxeNode parent) : super.fromNode(node, parent) {
    _style = doc.cfg.elementParameterValue(ref, 'style', null);
  }
  
  @override
  h.Element html() {
    h.Element span = new h.SpanElement();
    span.id = "$id";
    span.classes.add('dn');
    if (firstChild != null) { // TODO: test for empty sub-styles
      h.SpanElement contents = new h.SpanElement();
      DaxeNode dn = firstChild;
      while (dn != null) {
        contents.append(dn.html());
        dn = dn.nextSibling;
      }
      setStyle(contents);
      span.append(contents);
    } else {
      // let's make this invisible style visible !
      Tag b1 = new Tag(this, Tag.START);
      Tag b2 = new Tag(this, Tag.END);
      span.append(b1.html());
      h.SpanElement contents = new h.SpanElement();
      span.append(contents);
      span.append(b2.html());
    }
    return(span);
  }
  
  @override
  void updateHTMLAfterChildrenChange(List<DaxeNode> changed) {
    super.updateHTML();
  }
  
  @override
  h.Element getHTMLContentsNode() {
    if (firstChild != null)
      return(getHTMLNode().nodes.first);
    else
      return(getHTMLNode().nodes[1]);
  }
  
  @override
  bool get noDelimiter {
    return(true);
  }
  
  void set css(String css) {
    assert(false);
  }
  
  String get css {
    return(null);
  }
  
  bool matches(DNStyle dn) {
    if (this is DNStyleSpan && dn is DNStyleSpan)
      return(css == dn.css);
    if (this is DNStyleSpan || dn is DNStyleSpan)
      return(false);
    return(ref == dn.ref);
  }
  
  /**
   * Removes all styles or one style from the current selection
   */
  static EditAndNewPositions removeStylesBetweenEdit(Position start, Position end,
                                               [x.Element styleRef, String cssName]) {
    start = new Position.clone(start);
    end = new Position.clone(end);
    page.cursor.deSelect();
    start.moveInsideTextNodeIfPossible();
    end.moveInsideTextNodeIfPossible();
    assert(start != end);
    UndoableEdit compound = new UndoableEdit.compound(Strings.get('style.remove_styles'));
    // NOTE: even though selections cannot cut elements, there can be selections like <b>1[<i>23</i>45]6</b>
    DaxeNode ancestor = _commonAncestor(start.dn, end.dn);
    DaxeNode pp = ancestor.parent;
    while (pp != null) {
      if (pp is DNStyle && (styleRef == null || _matchingCssName(pp, styleRef, cssName)))
        ancestor = pp;
      pp = pp.parent;
    }
    if (ancestor is DNText) {
      // nothing to do !
      Position newStart = new Position.leftOffsetPosition(start);
      Position newEnd = new Position.rightOffsetPosition(end);
      EditAndNewPositions ep = new EditAndNewPositions(compound, newStart, newEnd);
      return(ep);
    }
    if (ancestor is DNStyle)
      ancestor = ancestor.parent;
    // ancestor is now a common ancestor between start and end, it is not a style and it has no matching style ancestor
    Position p1 = new Position(ancestor, 0); // left of the ancestor
    Position p2 = new Position(ancestor, ancestor.offsetLength); // right of the ancestor
    DaxeNode before;
    if (p1 != start)
      before = doc.cloneCutBetween(ancestor, p1, start); // clone tree before selection
    else
      before = null;
    DaxeNode inside = doc.cloneCutBetween(ancestor, start, end); // clone tree inside selection
    DaxeNode after;
    if (p2 != end)
      after = doc.cloneCutBetween(ancestor, end, p2); // clone tree after selection
    else
      after = null;
    if (styleRef == null)
      _removeStylesInNode(inside);
    else
      _removeStyleInNode(inside, styleRef, cssName:cssName);
    // calculate start and end positions after the edit
    int p1LeftOffset = new Position.leftOffsetPosition(p1).leftOffset;
    int beforeOffsets;
    if (before != null) {
      beforeOffsets = _offsetsInsideNode(before);
      if (before.lastChild is DNText && inside.firstChild is DNText) {
        // the text nodes will be merged, the position should be inside the text node
        beforeOffsets--;
      }
    } else
      beforeOffsets = 0;
    Position newStart = new Position.fromLeft(p1LeftOffset + beforeOffsets);
    int p2RightOffset = new Position.rightOffsetPosition(p2).rightOffset;
    int afterOffsets;
    if (after != null) {
      afterOffsets = _offsetsInsideNode(after);
      if (after.firstChild is DNText && inside.lastChild is DNText) {
        afterOffsets--;
      }
    } else
      afterOffsets = 0;
    Position newEnd = new Position.fromRight(p2RightOffset + afterOffsets);
    compound.addSubEdit(doc.removeBetweenEdit(p1, p2)); // remove everything inside ancestor
    if (after != null)
      compound.addSubEdit(doc.insertChildrenEdit(after, p1, checkValidity: false)); // insert right tree at p1
    compound.addSubEdit(doc.insertChildrenEdit(inside, p1, checkValidity: false)); // insert style-less tree at p1
    if (before != null)
      compound.addSubEdit(doc.insertChildrenEdit(before, p1, checkValidity: false)); // insert left tree at p1
    EditAndNewPositions ep = new EditAndNewPositions(compound, newStart, newEnd);
    return(ep);
  }
  
  /**
   * Returns the two nodes' first common ancestor.
   */
  static DaxeNode _commonAncestor(DaxeNode dn1, DaxeNode dn2) {
    DaxeNode p1 = dn1;
    while (p1 != null) {
      DaxeNode p2 = dn2;
      while (p2 != null) {
        if (p1 == p2) {
          return(p1);
        }
        if (p2.parent == null)
          break;
        p2 = p2.parent;
      }
      if (p1.parent == null)
        break;
      p1 = p1.parent;
    }
    return(null);
  }
  
  /**
   * Removes all style descendants from the parent, keeping their contents
   * (no validity check).
   */
  static _removeStylesInNode(DaxeNode parent) {
    for (DaxeNode dn = parent.firstChild; dn != null; ) {
      if (dn is DNStyle) {
        DaxeNode first = dn.firstChild;
        for (DaxeNode dn2 = dn.firstChild; dn2 != null; ) {
          DaxeNode next = dn2.nextSibling;
          parent.insertBefore(dn2, dn);
          dn2 = next;
        }
        parent.removeChild(dn);
        dn = first;
      } else {
        _removeStylesInNode(dn);
        dn = dn.nextSibling;
      }
    }
    parent.normalize();
  }
  
  /**
   * Removes all style descendants of a style from the parent, keeping their contents
   * (no validity check).
   */
  static _removeStyleInNode(DaxeNode parent, x.Element styleRef, {String cssName, String css}) {
    for (DaxeNode dn = parent.firstChild; dn != null; ) {
      if ((css != null && _matchingCss(dn, styleRef, css)) ||
          _matchingCssName(dn, styleRef, cssName)) {
        DaxeNode first = dn.firstChild;
        for (DaxeNode dn2 = dn.firstChild; dn2 != null; ) {
          DaxeNode next = dn2.nextSibling;
          parent.insertBefore(dn2, dn);
          dn2 = next;
        }
        parent.removeChild(dn);
        dn = first;
      } else {
        _removeStyleInNode(dn, styleRef, cssName:cssName, css:css);
        dn = dn.nextSibling;
      }
    }
    parent.normalize();
  }
  
  static int _offsetsInsideNode(DaxeNode parent) {
    DaxeNode targetDn = parent;
    int targetDnOffset = parent.offsetLength;
    int n = 0;
    DaxeNode dn = parent;
    int dnOffset = 0;
    while (dn != targetDn || dnOffset != targetDnOffset) {
      if (dnOffset == dn.offsetLength) {
        dnOffset = dn.parent.offsetOf(dn) + 1;
        dn = dn.parent;
      } else if (dn is DNText) {
        dnOffset++;
      } else {
        dn = dn.childAtOffset(dnOffset);
        dnOffset = 0;
      }
      n++;
    }
    return(n);
  }
  
  /**
   * Edit to remove the first matching style for the node at given Position
   */
  static UndoableEdit removeStyleAtPositionEdit(Position pos, [x.Element styleRef, String cssName]) {
    DaxeNode parent = pos.dn;
    if (parent is DNText)
      parent = parent.parent;
    for (DaxeNode dn = parent; dn != null; dn = dn.parent) {
      if ((styleRef == null && dn is DNStyle) || _matchingCssName(dn, styleRef, cssName)) {
        UndoableEdit edit = new UndoableEdit.compound(Strings.get('undo.remove_element'));
        DaxeNode clone = new DaxeNode.clone(dn);
        Position after = new Position(dn.parent, dn.parent.offsetOf(dn)+1);
        edit.addSubEdit(doc.insertChildrenEdit(clone, after));
        edit.addSubEdit(new UndoableEdit.removeNode(dn));
        return(edit);
      }
    }
    return(null);
  }
  
  /**
   * Removes the given style from the current selection. If the selection is empty,
   * removes the style from all ancestors of the node at the cursor position.
   */
  static void removeStylesFromSelection([x.Element styleRef, String cssName]) {
    Position start = page.getSelectionStart();
    Position end = page.getSelectionEnd();
    if (start == null)
      return;
    if (start == end) {
      UndoableEdit edit = removeStyleAtPositionEdit(start, styleRef, cssName);
      if (edit != null)
        doc.doNewEdit(edit);
      //TODO: restore position
      page.updateAfterPathChange();
    } else {
      // remove the style only in the selection
      EditAndNewPositions ep = removeStylesBetweenEdit(start, end, styleRef, cssName);
      doc.doNewEdit(ep.edit);
      page.cursor.setSelection(ep.start, ep.end);
      page.updateAfterPathChange();
    }
  }
  
  static bool _matchingCssName(DaxeNode dn, x.Element styleRef, String cssName) {
    if (dn is! DNStyle)
      return(false);
    if (dn.ref != styleRef)
      return(false);
    if (cssName == null)
      return(true);
    if ((dn as DNStyle).css == null)
      return(false);
    return((dn as DNStyle).css.startsWith(cssName + ':'));
  }
  
  static bool _matchingCss(DaxeNode dn, x.Element styleRef, String css) {
    if (dn is! DNStyle)
      return(false);
    if (dn.ref != styleRef)
      return(false);
    if ((dn as DNStyle).css == null)
      return(true);
    return((dn as DNStyle).css == css);
  }
  
  /**
   * Edit to create a new node at Position
   */
  static UndoableEdit newStyleNodeEdit(Position pos, x.Element styleRef, [String css]) {
    DaxeNode styleNode = NodeFactory.create(styleRef, 'element');
    if (css != null)
      (styleNode as DNStyle).css = css;
    return(new UndoableEdit.insertNode(pos, styleNode));
  }
  
  /**
   * Edit to apply style between 2 positions (start < end)
   */
  static EditAndNewPositions applyStyleBetweenEdit(Position start, Position end,
      x.Element styleRef, {String cssName, String css}) {
    assert(start != end);
    UndoableEdit edit = new UndoableEdit.compound(Strings.get('style.apply_style'));
    // p1 and p2 are used to merge with sibling styles
    // newStart and newEnd are ajusted selection positions after the edit
    Position p1 = start;
    Position newStart = new Position.leftOffsetPosition(start);
    Position testStart = new Position.clone(start);
    testStart.moveInsideTextNodeIfPossible();
    if (testStart.dn is DNText && testStart.dnOffset == 0) {
      DaxeNode previous = testStart.dn.previousSibling; 
      if (previous is DNStyle && _matchingCss(previous, styleRef, css)) {
        p1 = new Position(previous.parent, previous.parent.offsetOf(previous));
        newStart = new Position.leftOffsetPosition(testStart);
        newStart.move(-2);
        if (previous.lastChild is DNText)
          newStart.move(-1);
      }
    }
    Position p2 = end;
    Position newEnd = new Position.rightOffsetPosition(end);
    Position testEnd = new Position.clone(end);
    testEnd.moveInsideTextNodeIfPossible();
    if (testEnd.dn is DNText && testEnd.dnOffset == testEnd.dn.offsetLength) {
      DaxeNode next = testStart.dn.nextSibling; 
      if (next is DNStyle && _matchingCss(next, styleRef, css)) {
        p2 = new Position(next.parent, next.parent.offsetOf(next) + 1);
        newEnd = new Position.rightOffsetPosition(testEnd);
        newEnd.move(2);
        if (next.firstChild is DNText)
          newEnd.move(1);
      }
    }
    DaxeNode clone = doc.cloneBetween(p1, p2);
    _removeStyleInNode(clone, styleRef, cssName:cssName, css:css);
    _applyStyleInNode(clone, styleRef, css);
    edit.addSubEdit(doc.insertChildrenEdit(clone, p2, checkValidity:false));
    edit.addSubEdit(doc.removeBetweenEdit(p1, p2));
    return(new EditAndNewPositions(edit, newStart, newEnd));
  }
  
  /**
   * Apply given style to selection, or create a new node if selection is empty.
   * The style must no be already applied to ancestors of the selection nodes
   * (if it can be, removeAndApplyStyleToSelection should be used instead).
   */
  static void applyStyleInsideSelection(x.Element styleRef, {String cssName, String css}) {
    Position start = page.getSelectionStart();
    Position end = page.getSelectionEnd();
    if (start == end) {
      DaxeNode parent = start.dn;
      if (parent is DNText)
        parent = parent.parent;
      DaxeNode styleNode = NodeFactory.create(styleRef, 'element');
      if (css != null)
        (styleNode as DNStyle).css = css;
      bool inserted = false;
      if (doc.hiddenp != null && !doc.cfg.isSubElement(parent.ref, styleRef)) {
        if (doc.cfg.isSubElement(parent.ref, doc.hiddenp) && doc.cfg.isSubElement(doc.hiddenp, styleRef)) {
          // a new paragraph must be created
          DNHiddenP p = new DNHiddenP.fromRef(doc.hiddenp);
          p.appendChild(styleNode);
          doc.insertNode(p, start);
          inserted = true;
        }
      }
      if (!inserted)
        doc.insertNode(styleNode, start);
      Position cursorPos = styleNode.firstCursorPositionInside();
      if (cursorPos != null) {
        page.moveCursorTo(cursorPos);
        page.updateAfterPathChange();
      }
      return;
    }
    EditAndNewPositions ep = applyStyleBetweenEdit(start, end, styleRef,
        cssName:cssName, css:css);
    doc.doNewEdit(ep.edit);
    page.cursor.setSelection(ep.start, ep.end);
    page.updateAfterPathChange();
  }
  
  /**
   * Apply given style inside given parent wherever it is valid.
   */
  static void _applyStyleInNode(DaxeNode parent, x.Element styleRef, String css) {
    if (doc.cfg.isSubElement(parent.ref, styleRef)) {
      DaxeNode styleNode = null;
      for (DaxeNode child=parent.firstChild; child!=null; ) {
        if (child is DNText || doc.cfg.isSubElement(styleRef, child.ref)) {
          DaxeNode next = child.nextSibling;
          parent.removeChild(child);
          if (styleNode == null) {
            styleNode = NodeFactory.create(styleRef, 'element');
            if (css != null)
              (styleNode as DNStyle).css = css;
          }
          styleNode.appendChild(child);
          child = next;
        } else {
          if (styleNode != null) {
            parent.insertBefore(styleNode, child);
            styleNode = null;
          }
          _applyStyleInNode(child, styleRef, css);
          child = child.nextSibling;
        }
      }
      if (styleNode != null)
        parent.appendChild(styleNode);
    } else {
      for (DaxeNode child=parent.firstChild; child!=null; child=child.nextSibling) {
        if (child is! DNText)
          _applyStyleInNode(child, styleRef, css);
      }
    }
  }
  
  /**
   * Remove any style matching cssName in the selection, and apply the css style to it,
   * or create a new style node if the selection is empty.
   * An ancestor of the selection nodes may match cssName.
   */
  static void removeAndApplyStyleToSelection(x.Element styleRef, String cssName, String css) {
    Position start = page.getSelectionStart();
    Position end = page.getSelectionEnd();
    if (start == end) {
      DNStyle.applyStyleInsideSelection(styleRef, cssName:cssName, css:css);
    } else {
      EditAndNewPositions ep1 = DNStyle.removeStylesBetweenEdit(start, end, styleRef, cssName);
      doc.doNewEdit(ep1.edit);
      EditAndNewPositions ep2 = applyStyleBetweenEdit(ep1.start, ep1.end, styleRef,
          cssName:cssName, css:css);
      doc.doNewEdit(ep2.edit);
      doc.combineLastEdits(Strings.get('style.apply_style'), 2);
      page.cursor.setSelection(ep2.start, ep2.end);
      page.updateAfterPathChange();
    }
  }
  
  /**
   * Merge the styles at Position if possible, or returns null.
   */
  static EditAndNewPositions mergeAt(Position pos) {
    DNStyle leftStyle = null, rightStyle = null;
    if (pos.dn is DNStyle && pos.dnOffset == pos.dn.offsetLength)
      leftStyle = pos.dn;
    else if (pos.dn is DNText && pos.dnOffset == pos.dn.offsetLength && pos.dn.parent is DNStyle &&
        pos.dn.parent.offsetOf(pos.dn) == pos.dn.parent.offsetLength)
      leftStyle = pos.dn.parent;
    else if (pos.dn is! DNText && pos.dnOffset > 0 && pos.dn.offsetLength > 0 &&
        pos.dn.childAtOffset(pos.dnOffset - 1) is DNStyle)
      leftStyle = pos.dn.childAtOffset(pos.dnOffset - 1);
    if (pos.dn is DNStyle && pos.dnOffset == 0)
      rightStyle= pos.dn;
    else if (pos.dn is DNText && pos.dnOffset == 0 && pos.dn.parent is DNStyle &&
        pos.dn.parent.offsetOf(pos.dn) == 0)
      rightStyle = pos.dn.parent;
    else if (pos.dn is! DNText && pos.dnOffset < pos.dn.offsetLength && pos.dn.offsetLength > 0 &&
        pos.dn.childAtOffset(pos.dnOffset) is DNStyle)
      rightStyle = pos.dn.childAtOffset(pos.dnOffset);
    if (leftStyle == null || rightStyle == null)
      return(null);
    if (!leftStyle.matches(rightStyle))
      return(null);
    Position newPos;
    if (leftStyle.lastChild is DNText && rightStyle.firstChild is DNText)
      newPos = new Position(leftStyle.lastChild, leftStyle.lastChild.offsetLength);
    else
      newPos = new Position(leftStyle, leftStyle.offsetLength);
    UndoableEdit edit = new UndoableEdit.compound('merge');
    edit.addSubEdit(new UndoableEdit.removeNode(rightStyle));
    DaxeNode clone = new DaxeNode.clone(rightStyle);
    edit.addSubEdit(doc.insertChildrenEdit(clone, new Position(leftStyle, leftStyle.offsetLength)));
    return(new EditAndNewPositions(edit, newPos, new Position.clone(newPos)));
  }
}

class EditAndNewPositions {
  UndoableEdit edit;
  Position start, end;
  
  EditAndNewPositions(this.edit, this.start, this.end);
}
