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
 * Cursor and related operations (such as keyboard input)
 */
class Cursor {
  
  h.TextAreaElement ta;
  h.SpanElement caret;
  Position selectionStart, selectionEnd;
  List<h.SpanElement> spansSelection = new List<h.SpanElement>();
  List<DaxeNode> selectedNodes = new List<DaxeNode>();
  bool visible;
  static const Duration delay = const Duration(milliseconds: 700);
  Timer timer;
  HashMap<int, ActionFunction> shortcuts;
  
  Cursor() {
    ta = h.query("#tacursor");
    caret = h.query("#caret");
    visible = true;
    shortcuts = new HashMap<int, ActionFunction>();
    // FIXME: IE is always intercepting Ctrl-P
    ta.onKeyUp.listen((h.KeyboardEvent event) => keyUp(event));
    ta.onKeyDown.listen((h.KeyboardEvent event) => keyDown(event));
    ta.onBlur.listen((h.Event event) => blur(event));
    newTimer();
  }
  
  void setShortcuts(HashMap<String, ActionFunction> stringShortcuts) {
    HashMap<String, int> mappings = new HashMap<String, int>();
    mappings['A'] = h.KeyCode.A;
    mappings['B'] = h.KeyCode.B;
    mappings['C'] = h.KeyCode.C;
    mappings['D'] = h.KeyCode.D;
    mappings['E'] = h.KeyCode.E;
    mappings['F'] = h.KeyCode.F;
    mappings['G'] = h.KeyCode.G;
    mappings['H'] = h.KeyCode.H;
    mappings['I'] = h.KeyCode.I;
    mappings['J'] = h.KeyCode.J;
    mappings['K'] = h.KeyCode.K;
    mappings['L'] = h.KeyCode.L;
    mappings['M'] = h.KeyCode.M;
    mappings['N'] = h.KeyCode.N;
    mappings['O'] = h.KeyCode.O;
    mappings['P'] = h.KeyCode.P;
    mappings['Q'] = h.KeyCode.Q;
    mappings['R'] = h.KeyCode.R;
    mappings['S'] = h.KeyCode.S;
    mappings['T'] = h.KeyCode.T;
    mappings['U'] = h.KeyCode.U;
    mappings['V'] = h.KeyCode.V;
    mappings['W'] = h.KeyCode.W;
    mappings['X'] = h.KeyCode.X;
    mappings['Y'] = h.KeyCode.Y;
    mappings['Z'] = h.KeyCode.Z;
    for (String key in stringShortcuts.keys) {
      String up = key.toUpperCase();
      if (mappings[up] != null)
        shortcuts[mappings[up]] = stringShortcuts[key];
    }
  }
  
  static Position findPosition(h.MouseEvent event) {
    Position pos1 = doc.findPosition(event.client.x, event.client.y);
    if (pos1 == null)
      return(null);
    pos1.moveInsideTextNodeIfPossible();
    assert(pos1.dn != null);
    /*
     * we can't use window.getSelection in a MouseDown event,
     * we need another way to get the position inside text, see DaxeNode.findPosition
    if (pos1.daxeNode.nodeType == DaxeNode.TEXT_NODE) {
      h.DomSelection selection = h.window.getSelection();
      if (selection.rangeCount != 0) {
        h.Range r = selection.getRangeAt(0);
        if (r.startContainer == r.endContainer && r.startOffset == r.endOffset &&
            r.startContainer.parent.classes.contains('dn')) {
          // with "white-space: pre-wrap", bad position with a click to the right
          // of a newline caused by wrap
          Position pos2 = new Position.fromHTML(r.startContainer, r.startOffset);
          if (pos2.daxeNode == pos1.daxeNode)
            return(pos2);
        }
      }
    }
    */
    return(pos1);
  }
  
  void keyDown(h.KeyboardEvent event) {
    if (selectionStart == null)
      return;
    bool ctrl = event.ctrlKey || event.metaKey;
    bool shift = event.shiftKey;
    int keyCode = event.keyCode;
    if (ctrl && keyCode == h.KeyCode.X) {
      ta.value = copy();
      ta.select();
    } else if (ctrl && keyCode == h.KeyCode.C) {
      ta.value = copy();
      ta.select();
    } else if (keyCode == h.KeyCode.PAGE_DOWN) {
      pageDown();
    } else if (keyCode == h.KeyCode.PAGE_UP) {
      pageUp();
    } else if (keyCode == h.KeyCode.END) {
      lineEnd();
    } else if (keyCode == h.KeyCode.HOME) {
      lineStart();
    } else if (keyCode == h.KeyCode.LEFT) {
      if (shift)
        shiftLeft();
      else
        left();
    } else if (keyCode == h.KeyCode.UP) {
      up();
    } else if (keyCode == h.KeyCode.RIGHT) {
      if (shift)
        shiftRight();
      else
        right();
    } else if (keyCode == h.KeyCode.DOWN) {
      down();
    } else if (keyCode == h.KeyCode.BACKSPACE) {
      backspace();
    } else if (keyCode == h.KeyCode.DELETE) {
      suppr();
    } else if (ctrl && shortcuts[keyCode] != null) {
      event.preventDefault();
      return;
    } else if (ta.value != '') {
      // note: the first char will only be in ta.value in keyUp, this part
      // is only for long-pressed keys
      String v = ta.value;
      ta.value = '';
      doc.insertNewString(v, shift);
    } else {
      return;
    }
    newTimer();
  }
  
  void keyUp(h.KeyboardEvent event) {
    bool ctrl = event.ctrlKey || event.metaKey; // does metaKey work on keyUp ?
    bool shift = event.shiftKey;
    int keyCode = event.keyCode;
    if (selectionStart == null)
      return;
    if (ctrl && !shift && keyCode == h.KeyCode.Z) { // Ctrl Z
      doc.undo();
      ta.value = '';
    } else if (ctrl && ((!shift && keyCode == h.KeyCode.Y) ||
        (shift && keyCode == h.KeyCode.Z))) { // Ctrl-Y and Ctrl-Shift-Z
      doc.redo();
      ta.value = '';
    } else if (ctrl && !shift && keyCode == h.KeyCode.X) { // Ctrl-X
      removeSelection();
      ta.value = '';
      page.updateAfterPathChange();
    } else if (ctrl && !shift && keyCode == h.KeyCode.C) { // Ctrl-C
      ta.value = '';
    } else if (ctrl && !shift && keyCode == h.KeyCode.V) { // Ctrl-V
      if (selectionStart != selectionEnd) {
        removeSelection();
      }
      paste(ta.value);
      ta.value = '';
      page.updateAfterPathChange();
    } else if (ctrl && shortcuts[keyCode] != null) {
      event.preventDefault();
      shortcuts[keyCode]();
      page.updateAfterPathChange();
    } else if (ta.value != '') {
      String v = ta.value;
      ta.value = '';
      doc.insertNewString(v, shift);
    } else {
      return;
    }
    newTimer();
  }
  
  void blur(h.Event event) {
    hide();
  }
  
  /**
   * Action for the line start key.
   */
  void lineStart() {
    Point pt = selectionStart.positionOnScreen();
    pt.x = 0;
    pt.y += 5;
    Position pos = doc.findPosition(pt.x, pt.y);
    if (pos == null)
      return(null);
    if (pos != null) {
      moveTo(pos);
      page.updateAfterPathChange();
    }
  }
  
  /**
   * Action for the line end key.
   */
  void lineEnd() {
    Point pt = selectionStart.positionOnScreen();
    pt.x += 10000;
    pt.y += 5;
    Position pos = doc.findPosition(pt.x, pt.y);
    if (pos == null)
      return(null);
    if (pos != null) {
      moveTo(pos);
      page.updateAfterPathChange();
    }
  }
  
  /**
   * Action for the left arrow key.
   */
  void left() {
    deSelect();
    selectionStart.move(-1);
    selectionEnd = new Position.clone(selectionStart);
    updateCaretPosition(true);
    page.updateAfterPathChange();
  }
  
  /**
   * Action for the right arrow key.
   */
  void right() {
    Position end = new Position.clone(selectionEnd);
    end.move(1);
    deSelect();
    selectionStart = new Position.clone(end);
    selectionEnd = new Position.clone(end);
    updateCaretPosition(true);
    page.updateAfterPathChange();
  }
  
  /**
   * Action for the up arrow key.
   */
  void up() {
    deSelect();
    Point pt = selectionStart.positionOnScreen();
    if (pt == null)
      return;
    Position pos2 = selectionStart;
    while (pos2 == selectionStart) {
      pt.y = pt.y - 5;
      pos2 = doc.findPosition(pt.x, pt.y);
      pos2.moveInsideTextNodeIfPossible();
    }
    if (pos2 != null) {
      selectionStart = pos2;
      selectionEnd = new Position.clone(selectionStart);
    }
    updateCaretPosition(true);
    page.updateAfterPathChange();
  }
  
  /**
   * Action for the down arrow key.
   */
  void down() {
    deSelect();
    Point pt = selectionStart.positionOnScreen();
    if (pt == null)
      return;
    Position pos2 = selectionStart;
    while (pos2 == selectionStart) {
      pt.y = pt.y + 5;
      pos2 = doc.findPosition(pt.x, pt.y);
      pos2.moveInsideTextNodeIfPossible();
    }
    if (pos2 != null) {
      selectionStart = pos2;
      selectionEnd = new Position.clone(selectionStart);
    }
    updateCaretPosition(true);
    page.updateAfterPathChange();
  }
  
  /**
   * Action for the shift + left arrow keys.
   */
  void shiftLeft() {
    Position start = new Position.clone(selectionStart);
    start.move(-1);
    setSelection(start, selectionEnd);
  }
  
  /**
   * Action for the shift + right arrow keys.
   */
  void shiftRight() {
    Position end = new Position.clone(selectionEnd);
    end.move(1);
    setSelection(selectionStart, end);
  }
  
  /**
   * Action for the page up key.
   */
  void pageUp() {
    Point pt = selectionStart.positionOnScreen();
    if (pt == null)
      return;
    h.DivElement doc1 = h.document.getElementById('doc1'); 
    pt.y -= doc1.offsetHeight;
    Position pos = doc.findPosition(pt.x, pt.y);
    if (pos != null) {
      int initialScroll = doc1.scrollTop;
      moveTo(pos);
      doc1.scrollTop = initialScroll - doc1.offsetHeight;
      page.updateAfterPathChange();
    }
  }
  
  /**
   * Action for the page down key.
   */
  void pageDown() {
    Point pt = selectionStart.positionOnScreen();
    if (pt == null)
      return;
    h.DivElement doc1 = h.document.getElementById('doc1'); 
    pt.y += doc1.offsetHeight;
    Position pos = doc.findPosition(pt.x, pt.y);
    if (pos != null) {
      int initialScroll = doc1.scrollTop;
      moveTo(pos);
      doc1.scrollTop = initialScroll + doc1.offsetHeight;
      page.updateAfterPathChange();
    }
  }
  
  /**
   * Action for the backspace key.
   */
  void backspace() {
    if (selectionStart == selectionEnd) {
      // FIXME: this doesn't work with tables
      selectionStart.move(-1);
      // if this is the end of a style, do not remove the whole node, just the last character
      DaxeNode dn = selectionStart.dn;
      if (dn is DNText && dn.parent is DNStyle && dn.offsetLength > 1 &&
          dn.offsetLength == selectionStart.dnOffset) {
        selectionStart.move(-1);
      }
      selectionEnd = new Position.clone(selectionStart);
      removeChar(selectionStart);
    } else {
      removeSelection();
    }
    page.updateAfterPathChange();
  }
  
  /**
   * Action for the suppr key.
   */
  void suppr() {
    if (selectionStart == selectionEnd) {
      // if this is the beginning of a style, do not remove the whole node, just the first character
      DaxeNode next = null;
      DaxeNode dn = selectionStart.dn;
      int offset = selectionStart.dnOffset;
      if (dn is! DNText && offset < dn.offsetLength)
        next = dn.childNodes[offset];
      else if (dn is DNText && dn.offsetLength == offset &&
          dn.nextSibling != null)
        next = dn.nextSibling;
      if (next is DNStyle && next.firstChild is DNText) {
        selectionStart.move(1);
        selectionEnd = new Position.clone(selectionStart);
      }
      removeChar(selectionStart);
    } else {
      removeSelection();
    }
    page.updateAfterPathChange();
  }
  
  /**
   * Update the caret position when selectionStart == selectionEnd
   */
  void updateCaretPosition(bool scroll) {
    if (selectionEnd != selectionStart)
      return;
    Point pt = selectionStart.positionOnScreen();
    if (pt == null) {
      visible = false;
    } else {
      visible = true;
      h.DivElement doc1 = h.document.getElementById('doc1'); 
      int doctop = doc1.offset.top;
      int docheight = doc1.offset.height;
      if (pt.y - doctop < 0 || pt.y - doctop > docheight) {
        if (scroll) {
          doc1.scrollTop += pt.y.toInt() - doctop;
          pt = selectionStart.positionOnScreen();
        } else {
          visible = false;
        }
      }
    }
    if (visible) {
      caret.style.visibility = 'visible';
      caret.style.top = "${pt.y}px";
      caret.style.left = "${pt.x}px";
      setCaretStyle();
      // move and focus the textarea
      ta.style.top = "${pt.y}px";
      ta.style.left = "${pt.x}px";
      ta.focus();
    } else {
      caret.style.visibility = 'hidden';
    }
  }
  
  /**
   * Sets the caret style (horizontal or vertical)
   */
  void setCaretStyle() {
    bool horizontal; // horizontal caret between block elements
    h.Element hparent = selectionStart.dn.getHTMLNode();
    bool parentBlock = _isBlock(hparent);
    if (parentBlock && selectionStart.dn.offsetLength > 0) {
      bool prevBlock;
      if (selectionStart.dnOffset > 0) {
        DaxeNode prev = selectionStart.dn.childAtOffset(selectionStart.dnOffset - 1);
        h.Element hprev = prev.getHTMLNode();
        prevBlock = _isBlock(hprev);
      } else
        prevBlock = true;
      bool nextBlock;
      if (selectionStart.dnOffset < selectionStart.dn.offsetLength) {
        DaxeNode next = selectionStart.dn.childAtOffset(selectionStart.dnOffset);
        h.Element hnext = next.getHTMLNode();
        nextBlock = _isBlock(hnext);
      } else
        nextBlock = true;
      horizontal = prevBlock && nextBlock;
    } else
      horizontal = false;
    if (horizontal)
      caret.classes.add('horizontal');
    else if (caret.classes.contains('horizontal'))
      caret.classes.remove('horizontal');
  }
  
  bool _isBlock(h.Element el) {
    return(el is h.DivElement || el is h.TableElement || el is h.UListElement || el is h.LIElement);
  }
  
  /**
   * Moves the caret to the given Position.
   */
  void moveTo(Position pos) {
    deSelect();
    selectionStart = new Position.clone(pos);
    selectionStart.moveInsideTextNodeIfPossible();
    selectionEnd = new Position.clone(selectionStart);
    updateCaretPosition(true);
  }
  
  /**
   * Hides the cursor.
   */
  void hide() {
    visible = false;
    caret.style.visibility = 'hidden';
  }
  
  /**
   * Shows the cursor.
   */
  void show() {
    if (selectionStart != null && selectionStart == selectionEnd) {
      visible = true;
      caret.style.visibility = 'visible';
    }
  }
  
  /**
   * Obtains the focus.
   */
  void focus() {
    show();
    ta.focus();
  }
  
  setSelection(Position start, Position end) {
    if (selectionStart == start && selectionEnd == end) {
      if (start == end)
        focus();
      return;
    }
    deSelect();
    Position previousStart = selectionStart;
    selectionStart = new Position.clone(start);
    selectionEnd = new Position.clone(end);
    if (selectionStart == selectionEnd) {
      //update(selectionStart);
      updateCaretPosition(false);
      page.updateAfterPathChange();
      return;
    }
    if (selectionStart > selectionEnd) {
      Position temp = selectionStart;
      selectionStart = selectionEnd;
      selectionEnd = temp;
    }
    if (selectionStart.dn == selectionEnd.dn) {
      DaxeNode dn = selectionStart.dn;
      if (dn.nodeType == DaxeNode.TEXT_NODE) {
        selectText(dn, selectionStart.dnOffset, selectionEnd.dnOffset);
      } else {
        for (int i = selectionStart.dnOffset; i < selectionEnd.dnOffset; i++) {
          DaxeNode child = dn.childAtOffset(i);
          child.setSelected(true);
          selectedNodes.add(child);
        }
      }
    } else {
      DaxeNode startParent = selectionStart.dn;
      if (startParent.nodeType == DaxeNode.TEXT_NODE)
        startParent = startParent.parent;
      if (selectionEnd > new Position(startParent, startParent.offsetLength))
        selectionEnd = new Position(startParent, startParent.offsetLength);
      else {
        DaxeNode endParent = selectionEnd.dn;
        if (endParent.nodeType == DaxeNode.TEXT_NODE)
          endParent = endParent.parent;
        if (endParent != startParent) {
          while (endParent.parent != startParent) {
            endParent = endParent.parent;
          }
          selectionEnd = new Position(startParent, startParent.offsetOf(endParent));
        }
      }
      DaxeNode firstNode;
      if (selectionStart.dn.nodeType == DaxeNode.ELEMENT_NODE ||
          selectionStart.dn.nodeType == DaxeNode.DOCUMENT_NODE) {
        firstNode = selectionStart.dn.childAtOffset(selectionStart.dnOffset);
        if (firstNode != null) {
          Position p2 = new Position(selectionStart.dn, selectionStart.dnOffset + 1);
          if (selectionEnd >= p2) {
            firstNode.setSelected(true);
            selectedNodes.add(firstNode);
          }
        }
      } else {
        firstNode = selectionStart.dn;
        selectText(firstNode, selectionStart.dnOffset, firstNode.offsetLength);
      }
      if (firstNode != null) {
        for (DaxeNode next = firstNode.nextSibling; next != null; next = next.nextSibling) {
          Position p1 = new Position(next.parent, next.parent.offsetOf(next));
          if (p1 < selectionEnd) {
            if (next.nodeType != DaxeNode.TEXT_NODE ||
                selectionEnd >= new Position(next.parent, next.parent.offsetOf(next) + 1)) {
              next.setSelected(true);
              selectedNodes.add(next);
            }
          } else
            break;
        }
      }
      if (selectionEnd.dn.nodeType == DaxeNode.TEXT_NODE) {
        selectText(selectionEnd.dn, 0, selectionEnd.dnOffset);
      }
    }
    if (selectionEnd != selectionStart)
      hide();
    if (selectionStart != previousStart)
      page.updateAfterPathChange();
  }
  
  void selectText(DaxeNode dn, int offset1, int offset2) {
    h.Element parent = dn.getHTMLNode();
    if (parent == null)
      return;
    h.Text n = parent.nodes.first;
    h.Node next = n.nextNode;
    hide();
    String s = dn.nodeValue;
    if (offset1 == 0) {
      n.remove();
    } else {
      n.text = s.substring(0, offset1);
    }
    h.SpanElement span = new h.SpanElement();
    spansSelection.add(span);
    span.classes.add('selection');
    //span.appendText(s.substring(offset1, offset2));
    //see comment in deSelect
    span.append(new h.Text(s.substring(offset1, offset2)));
    if (next == null)
      parent.append(span);
    else
      parent.insertBefore(span, next);
    if (offset2 != s.length) {
      h.Text n3 = new h.Text(s.substring(offset2));
      if (span.nextNode == null)
        parent.append(n3);
      else
        parent.insertBefore(n3, span.nextNode);
    }
  }
  
  void deSelect() {
    for (h.SpanElement span in spansSelection) {
      h.Element parent = span.parent;
      StringBuffer sb = new StringBuffer();
      for (h.Node hn in parent.nodes) {
        sb.write(hn.text);
      }
      parent.nodes.clear();
      // parent.appendText(sb.toString());
      // IE9 replaces \n by BR here when appendText is used
      // http://code.google.com/p/dart/issues/detail?id=11180
      parent.append(new h.Text(sb.toString()));
      selectionEnd = new Position.clone(selectionStart);
      visible = true;
    }
    spansSelection.clear();
    for (DaxeNode dn in selectedNodes) {
      dn.setSelected(false);
    }
    selectedNodes.clear();
    /*
    this is causing too many problems (for instance with undo, or text select)
    a better solution is to make invisible styles visible (see DNStyle)
    if (selectionStart != null && selectionStart == selectionEnd &&
        selectionStart.dn is DNStyle &&
        selectionStart.dn.firstChild == null) {
      // remove an empty style element
      DaxeNode toremove = selectionStart.dn;
      if (toremove.parent != null) { // otherwise it's already been removed
        // we can't do it now, because removing the node can cause text nodes to be merged,
        // and this could change the positions passed in a click
        Timer.run(() {
          print('removed $toremove');
          selectionStart = new Position(toremove.parent, toremove.parent.offsetOf(toremove));
          selectionEnd = new Position.clone(selectionStart);
          doc.removeNode(toremove);
          // TODO: automatically undo the creation and removal of the style element
        });
      }
    }
    */
  }
  
  void newTimer() {
    if (!visible)
      return;
    if (timer != null)
      timer.cancel();
    caret.style.visibility = "visible";
    timer = new Timer.periodic(delay, (Timer t) => caretBlink());
  }
  
  void caretBlink() {
    if (!visible)
      return;
    if (caret.style.visibility == "hidden")
      caret.style.visibility = "visible";
    else if (caret.style.visibility == "visible")
      caret.style.visibility = "hidden";
  }
  
  /**
   * Removes the first character or Daxe node coming after the cursor.
   */
  void removeChar(Position pos) {
    if (pos.dn.nodeType == DaxeNode.TEXT_NODE &&
        pos.dn.offsetLength < pos.dnOffset + 1 &&
        pos.dn.nextSibling != null) {
      // remove the next node
      DaxeNode current = pos.dn;
      DaxeNode next = current.nextSibling;
      while (next == null && current.parent != null) {
        current = current.parent;
        next = current.nextSibling;
      }
      DaxeNode toremove = next;
      if (toremove.nodeType == DaxeNode.TEXT_NODE && toremove.parent != null &&
          toremove.offsetLength == 1)
        toremove = toremove.parent;
      if (!toremove.userCannotRemove)
        doc.removeNode(toremove);
    } else if (pos.dn.nodeType == DaxeNode.TEXT_NODE &&
        pos.dn.offsetLength < pos.dnOffset + 1 &&
        pos.dn.nextSibling == null) {
      // remove pos.dn's parent
      DaxeNode toremove = pos.dn;
      if (toremove.parent != null)
        toremove = toremove.parent;
      //pos.move(-pos.dnOffset - 1);
      if (!toremove.userCannotRemove)
        doc.removeNode(toremove);
    } else if (pos.dn.nodeType == DaxeNode.ELEMENT_NODE && pos.dn.offsetLength < pos.dnOffset + 1) {
      // remove pos.dn
      DaxeNode toremove = pos.dn;
      //pos.move(-pos.dnOffset - 1);
      if (!toremove.userCannotRemove)
        doc.removeNode(toremove);
    } else if (pos.dn.nodeType == DaxeNode.ELEMENT_NODE ||
        pos.dn.nodeType == DaxeNode.DOCUMENT_NODE) {
      DaxeNode toremove = pos.dn.childAtOffset(pos.dnOffset);
      if (toremove == null)
        h.window.alert("I'm sorry Dave, I'm afraid I can't do that.");
      else if (!toremove.userCannotRemove)
        doc.removeNode(toremove);
    } else {
      doc.removeString(pos, 1);
    }
  }
  
  /**
   * Removes everything inside the current selection.
   */
  void removeSelection() {
    if (selectionStart == selectionEnd)
      return;
    Position start = new Position.clone(selectionStart);
    Position end = new Position.clone(selectionEnd);
    deSelect();
    doc.removeBetween(start, end);
  }
  
  /**
   * Returns the current XML selection as a String.
   */
  String copy() {
    StringBuffer sb = new StringBuffer();
    if (selectionStart.dn == selectionEnd.dn) {
      DaxeNode dn = selectionStart.dn;
      if (dn.nodeType == DaxeNode.TEXT_NODE) {
        sb.write(dn.nodeValue.substring(selectionStart.dnOffset, selectionEnd.dnOffset));
      } else {
        for (int i = selectionStart.dnOffset; i < selectionEnd.dnOffset; i++) {
          DaxeNode child = dn.childAtOffset(i);
          sb.write(child);
        }
      }
    } else {
      DaxeNode firstNode;
      if (selectionStart.dn.nodeType == DaxeNode.ELEMENT_NODE) {
        firstNode = selectionStart.dn.childAtOffset(selectionStart.dnOffset);
        Position p2 = new Position(selectionStart.dn, selectionStart.dnOffset + 1);
        if (selectionEnd >= p2) {
          sb.write(firstNode);
        }
      } else {
        firstNode = selectionStart.dn;
        sb.write(firstNode.nodeValue.substring(selectionStart.dnOffset));
      }
      for (DaxeNode next = firstNode.nextSibling; next != null; next = next.nextSibling) {
        Position p1 = new Position(next.parent, next.parent.offsetOf(next));
        if (p1 < selectionEnd) {
          if (next.nodeType != DaxeNode.TEXT_NODE ||
              selectionEnd >= new Position(next.parent, next.parent.offsetOf(next) + 1)) {
            sb.write(next);
            next.setSelected(true);
          }
        } else
          break;
      }
      if (selectionEnd.dn.nodeType == DaxeNode.TEXT_NODE) {
        sb.write(selectionEnd.dn.nodeValue.substring(0, selectionEnd.dnOffset));
      }
    }
    return(sb.toString());
  }
  
  /**
   * Parses the given String and pastes the XML at the current position.
   */
  bool paste(String s) {
    x.Document tmpdoc;
    try {
      x.DOMParser dp = new x.DOMParser();
      tmpdoc = dp.parseFromString("<root>$s</root>");
    } on x.DOMException catch(ex) {
      // this is not XML, it is inserted as string
      doc.insertString(selectionStart, s);
      return(true);
    }
    DaxeNode parent = selectionStart.dn;
    int offset = selectionStart.dnOffset;
    if (parent is DNText) {
      offset = parent.parent.offsetOf(parent);
      parent = parent.parent;
    }
    UndoableEdit edit = new UndoableEdit.compound("Paste");
    x.Element root = tmpdoc.documentElement;
    // to call fixLineBreaks(), we need a real DaxeNode for the "root", with the right ref
    DaxeNode dnRoot = NodeFactory.create(parent.ref);
    for (x.Node n in root.childNodes) {
      DaxeNode dn = NodeFactory.createFromNode(n, dnRoot);
      dnRoot.appendChild(dn);
    }
    dnRoot.fixLineBreaks();
    // reverse order to always use selectionStart as the insert position
    // problem: the cursor is not at the right position afterwards
    for (DaxeNode dn in dnRoot.childNodes.reversed) {
      if ((parent is DNComment || parent is DNCData || parent is DNProcessingInstruction) &&
          dn is! DNText) {
        String title;
        if (dn.ref == null)
          title = dn.nodeName;
        else
          title = doc.cfg.elementTitle(dn.ref);
        h.window.alert(title + ' ' + Strings.get('insert.not_authorized_here'));
        return(false);
      }
      if (dn is DNText || dn is DNCData) {
        String value = null;
        if (dn is DNText)
          value = dn.nodeValue;
        else if (dn.firstChild != null)
          value = dn.firstChild.nodeValue;
        if (value == null)
          value = '';
        if (value.trim() != '' && !doc.cfg.canContainText(parent.ref)) {
          h.window.alert(Strings.get('insert.text_not_allowed'));
          return(false);
        }
        if (dn is DNText)
          edit.addSubEdit(new UndoableEdit.insertString(selectionStart, dn.nodeValue));
        else
          edit.addSubEdit(new UndoableEdit.insertNode(selectionStart, dn));
      } else {
        if (dn is! DNComment && dn is! DNProcessingInstruction) {
          if (dn.ref == null || !doc.cfg.isSubElement(parent.ref, dn.ref)) {
            String title;
            if (dn.ref == null)
              title = dn.nodeName;
            else
              title = doc.cfg.elementTitle(dn.ref);
            String parentTitle = doc.cfg.elementTitle(parent.ref);
            h.window.alert(title + ' ' + Strings.get('insert.not_authorized_inside') + ' ' + parentTitle);
            return(false);
          }
          if (!doc.cfg.insertIsPossible(parent, offset, offset, dn.ref)) {
            h.window.alert(doc.cfg.elementTitle(dn.ref) + ' ' + Strings.get('insert.not_authorized_here'));
            return(false);
          }
        }
        edit.addSubEdit(new UndoableEdit.insertNode(selectionStart, dn));
      }
    }
    doc.doNewEdit(edit);
    return(true);
  }
}
