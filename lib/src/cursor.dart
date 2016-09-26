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
  static final String wordDelimiters = "\n \t`~!@#^&*()-+=[{]}|;:'\",<.>/?";

  h.TextAreaElement ta;
  h.SpanElement caret;
  Position selectionStart, selectionEnd;
  List<h.SpanElement> spansSelection = new List<h.SpanElement>();
  List<DaxeNode> selectedNodes = new List<DaxeNode>();
  bool visible;
  static const Duration delay = const Duration(milliseconds: 700);
  Timer timer;
  HashMap<int, ActionFunction> shortcuts;
  bool donePaste;
  int metaKeyCode; // previous keyDown keyCode if event.metaKey was true
  bool shiftOnKeyPress = false; // shift active during keyPress

  Cursor() {
    ta = h.querySelector("#tacursor");
    caret = h.querySelector("#caret");
    visible = true;
    shortcuts = new HashMap<int, ActionFunction>();
    // FIXME: IE is always intercepting Ctrl-P
    ta.onKeyUp.listen((h.KeyboardEvent event) => keyUp(event));
    ta.onKeyPress.listen((h.KeyboardEvent event) => keyPress(event));
    ta.onKeyDown.listen((h.KeyboardEvent event) => keyDown(event));
    ta.onBlur.listen((h.Event event) => blur(event));
    ta.onPaste.listen((h.ClipboardEvent e) {
      // check if current language might understand HTML.
      // If not, onPaste is not useful.
      List<String> hnames = ['p', 'ul', 'a'];
      for (String name in hnames)
        if (doc.cfg.elementReference(name) == null)
          return;
      h.DataTransfer data = e.clipboardData;
      if (data.types.contains('text/html')) {
        pasteHTML(data.getData('text/html'), data.getData('text/plain'));
        e.preventDefault();
        donePaste = true;
      } else if (data.types.contains('Files')) {
        donePaste = pasteImage(data);
        if (donePaste)
          e.preventDefault();
      }
    });
    donePaste = false;
    metaKeyCode = 0;
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
    page.stopSelection();
    donePaste = false;
    bool ctrl = event.ctrlKey || event.metaKey;
    bool shift = event.shiftKey;
    int keyCode = event.keyCode;
    if (event.metaKey) {
      metaKeyCode = keyCode;
      ta.value = ''; // remove content added for Safari
    } else
      metaKeyCode = 0;
    shiftOnKeyPress = false;
    if (keyCode == 91 || keyCode == 93) {
      // for Safari, command key down, put something in the field and select it
      // so that it will not beep and refuse to copy with a command-C
      ta.value = ' ';
      ta.select();
    } else if (ctrl && keyCode == h.KeyCode.X) {
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
        shiftLeft(ctrl);
      else
        left(ctrl);
    } else if (keyCode == h.KeyCode.UP) {
      up();
    } else if (keyCode == h.KeyCode.RIGHT) {
      if (shift)
        shiftRight(ctrl);
      else
        right(ctrl);
    } else if (keyCode == h.KeyCode.DOWN) {
      down();
    } else if (keyCode == h.KeyCode.BACKSPACE) {
      backspace();
    } else if (keyCode == h.KeyCode.DELETE) {
      suppr();
    } else if (keyCode == h.KeyCode.TAB && !ctrl && !shift) {
      tab(event);
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

  void keyPress(h.KeyboardEvent event) {
    // Save the state of shift when a key is pressed,
    // because shift might be released by the time of keyUp,
    // but should still be taken into account.
    if (event.shiftKey)
      shiftOnKeyPress = true;
  }

  void keyUp(h.KeyboardEvent event) {
    // NOTE: on MacOS, keyUp events are not fired when the command key is down
    // see: http://bitspushedaround.com/on-a-few-things-you-may-not-know-about-the-hellish-command-key-and-javascript-events/
    // 2 possible solutions: using keyPress, or keyUp for the command key
    // here keyUp for command key is used (event.metaKey is false because the key is released)
    // pb with this solution: cmd_down, Z, Z, cmd_up will only do a single cmd-Z
    bool ctrl = event.ctrlKey || event.metaKey;
    bool shift = event.shiftKey || shiftOnKeyPress;
    shiftOnKeyPress = false;
    int keyCode = event.keyCode;
    if ((keyCode == 91 || keyCode == 93) && ta.value != '' && metaKeyCode == 0) {
      ta.value = ''; // remove content added for Safari
    }
    if ((keyCode == 224 || keyCode == 91 || keyCode == 93 || keyCode == 17) && metaKeyCode != 0) {
      ctrl = true;
      keyCode = metaKeyCode;
    }
    metaKeyCode = 0;
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
      if (donePaste) {
        return;
      }
      if (ta.value != '') {
        pasteString(ta.value);
        ta.value = '';
        page.updateAfterPathChange();
      }
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
    //pt.x = 0;
    // this does not work when blocks are used (it moves the cursor outside)
    DaxeNode dn = selectionStart.dn;
    if (dn == null)
      return;
    while (!dn.block && dn.parent != null)
      dn = dn.parent;
    h.Element hnode = dn.getHTMLNode();
    h.Rectangle rect = hnode.getBoundingClientRect();
    pt.x = rect.left + 1;
    pt.y += 5;
    Position pos = doc.findPosition(pt.x, pt.y);
    if (pos == null)
      return;
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
    //pt.x += 10000;
    // this does not work when blocks are used (it moves the cursor outside)
    DaxeNode dn = selectionStart.dn;
    if (dn == null)
      return;
    while (!dn.block && dn.parent != null)
      dn = dn.parent;
    h.Element hnode = dn.getHTMLNode();
    h.Rectangle rect = hnode.getBoundingClientRect();
    pt.x = rect.right - 1;
    pt.y += 5;
    Position pos = doc.findPosition(pt.x, pt.y);
    if (pos == null)
      return;
    if (pos != null) {
      moveTo(pos);
      page.updateAfterPathChange();
    }
  }

  /**
   * Action for the left arrow key.
   */
  void left(bool ctrl) {
    deSelect();
    if (ctrl)
      selectionStart = previousWordPosition(selectionStart);
    else
      selectionStart = previousCaretPosition(selectionStart);
    selectionEnd = new Position.clone(selectionStart);
    updateCaretPosition(true);
    page.updateAfterPathChange();
  }

  /**
   * Action for the right arrow key.
   */
  void right(bool ctrl) {
    Position end = new Position.clone(selectionEnd);
    if (ctrl)
      end = nextWordPosition(end);
    else
      end = nextCaretPosition(end);
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
      pt.y = pt.y - 7;
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
      pt.y = pt.y + 14;
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
  void shiftLeft(bool ctrl) {
    Position start = new Position.clone(selectionStart);
    if (ctrl)
      start = previousWordPosition(selectionStart);
    else
      start = previousCaretPosition(start);
    setSelection(start, selectionEnd);
  }

  /**
   * Action for the shift + right arrow keys.
   */
  void shiftRight(bool ctrl) {
    Position end = new Position.clone(selectionEnd);
    if (ctrl)
      end = nextWordPosition(end);
    else
      end = nextCaretPosition(end);
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
      DaxeNode dn = selectionStart.dn;
      int offset = selectionStart.dnOffset;
      if (dn is DNDocument && offset == 0)
        return;
      if (dn is DNText && offset == 0 && dn.parent is DNWItem &&
          dn.previousSibling == null && dn.parent.previousSibling == null) {
        // at the beginning of a WYSIWYG list
        DNWList.riseLevel();
        return;
      }
      // if the cursor is at a newline after a node with an automatic (not DOM) newline,
      // the user probably wants to remove the newline instead of the previous node.
      if (dn is DNText && offset == 0 && dn.nodeValue[0] == '\n' &&
          dn.previousSibling != null && dn.previousSibling.newlineAfter()) {
        removeChar(selectionStart);
        return;
      }
      // same thing for newlineInside
      if (dn is DNText && offset == 0 && dn.nodeValue[0] == '\n' &&
          dn.previousSibling == null && dn.parent.newlineInside()) {
        removeChar(selectionStart);
        return;
      }
      // if this is the beginning of a node with no delimiter, remove something
      // before instead of the node with no delimiter (unless it's empty)
      bool justMovedOutOfBlockWithNoDelimiter = false;
      while (dn != null && dn.noDelimiter && offset == 0 && dn.offsetLength > 0) {
        if (dn.noDelimiter && dn.block)
          justMovedOutOfBlockWithNoDelimiter = true;
        else
          justMovedOutOfBlockWithNoDelimiter = false;
        offset = dn.parent.offsetOf(dn);
        dn = dn.parent;
      }
      if (dn is! DNText && offset > 0) {
        DaxeNode prev = dn.childAtOffset(offset - 1);
        if (justMovedOutOfBlockWithNoDelimiter) {
        // if we're at the beginning of a paragraph and the previous element could
        // go inside, move all the previous elements that can inside the paragraph
          DaxeNode next = dn.childAtOffset(offset);
          assert(next.noDelimiter && next.block);
          if (prev.ref != next.ref && !prev.block &&
              ((prev is DNText && doc.cfg.canContainText(next.ref)) ||
                  (prev.ref != null && doc.cfg.isSubElement(next.ref, prev.ref)))) {
            mergeBlockWithPreviousNodes(next);
            return;
          }
        }
        // if the previous node is a paragraph and the next node can move inside,
        // move all the following non-block nodes that can inside.
        if (prev.noDelimiter && prev.block && offset < dn.offsetLength) {
          DaxeNode next = dn.childAtOffset(offset);
          if (prev.ref != next.ref && !next.block &&
              ((next is DNText && doc.cfg.canContainText(prev.ref)) ||
              (next.ref != null && doc.cfg.isSubElement(prev.ref, next.ref)))) {
            mergeBlockWithNextNodes(prev);
            return;
          }
        }
        // move inside previous node with no delimiter, unless 2 paragraphs need to be merged
        if (prev.noDelimiter && (!prev.block ||
            (offset == dn.offsetLength || dn.childAtOffset(offset).ref != prev.ref))) {
          dn = dn.childAtOffset(offset - 1);
          offset = dn.offsetLength;
          if (dn is! DNText && offset > 0)
            prev = dn.childAtOffset(offset - 1);
          else
            prev = null;
        }
      }
      // if this is the end of a node with no delimiter with a character inside,
      // do not remove the whole node, just the last character (except for text nodes)
      while ((dn is! DNText && dn.noDelimiter) && dn.offsetLength == offset &&
          dn.firstChild != null) {
        dn = dn.lastChild;
        offset = dn.offsetLength;
      }
      selectionStart = new Position(dn, offset);
      selectionEnd = new Position.clone(selectionStart);
      selectionStart.move(-1);
      removeChar(selectionStart);
      if (dn is DNText && offset > 1)
        return; // updateAfterPathChange is not needed in this case
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
      if (selectionStart.dn is DNDocument && selectionStart.dnOffset == selectionStart.dn.offsetLength)
        return;
      DaxeNode dn = selectionStart.dn;
      int offset = selectionStart.dnOffset;
      // if at the end, get out of nodes with no delimiter (unless empty)
      while (dn.noDelimiter && offset == dn.offsetLength && dn.offsetLength > 0) {
        offset = dn.parent.offsetOf(dn) + 1;
        dn = dn.parent;
      }
      if (dn is! DNText && offset > 0 && offset < dn.offsetLength) {
        DaxeNode next = dn.childAtOffset(offset);
        DaxeNode prev = dn.childAtOffset(offset-1);
        // if we're at the end of a paragraph and the next element could
        // go inside, move all the next elements that can inside the paragraph
        if (prev.noDelimiter && prev.block && next.ref != prev.ref && !next.block &&
            ((next is DNText && doc.cfg.canContainText(prev.ref)) ||
                (next.ref != null && doc.cfg.isSubElement(prev.ref, next.ref)))) {
          mergeBlockWithNextNodes(prev);
          return;
        }
        // if the next node is a paragraph and the previous node can move inside,
        // move all the previous non-block nodes that can inside.
        if (next.noDelimiter && next.block && next.ref != prev.ref && !prev.block) {
          if ((prev is DNText && doc.cfg.canContainText(next.ref)) ||
              (prev.ref != null && doc.cfg.isSubElement(next.ref, prev.ref))) {
            mergeBlockWithPreviousNodes(next);
            return;
          }
        }
      }
      // move inside next node with no delimiter unless 2 paragraphs need to be merged
      if (dn is! DNText && offset < dn.offsetLength) {
        DaxeNode next = dn.childAtOffset(offset);
        while (next != null && next.noDelimiter && (!next.block ||
            (offset == 0 || dn.childAtOffset(offset-1).ref != next.ref))) {
          dn = next;
          offset = 0;
          if (dn is! DNText && offset < dn.offsetLength)
            next = dn.childAtOffset(offset);
          else
            next = null;
        }
      }
      selectionStart = new Position(dn, offset);
      selectionEnd = new Position.clone(selectionStart);
      removeChar(selectionStart);
    } else {
      removeSelection();
    }
    page.updateAfterPathChange();
  }

  /**
   * Action for the tab key.
   * Inserts 4 spaces only if spaces are preserved in the element
   * (without looking at parents)
   */
  void tab(h.Event event) {
    if (selectionStart != selectionEnd)
      return;
    DaxeNode parent = selectionStart.dn;
    if (parent is DNText)
      parent = parent.parent;
    if (parent.nodeType != DaxeNode.ELEMENT_NODE)
      return;
    final String xmlspace = parent.getAttribute("xml:space");
    bool spacePreserve = (xmlspace == "preserve");
    if (!spacePreserve && parent.ref != null && xmlspace == null) {
      final List<x.Element> attributes = doc.cfg.elementAttributes(parent.ref);
      for (x.Element attref in attributes) {
        if (doc.cfg.attributeName(attref) == "space" &&
            doc.cfg.attributeNamespace(attref) == "http://www.w3.org/XML/1998/namespace") {
          final String defaut = doc.cfg.defaultAttributeValue(attref);
          if (defaut == "preserve")
            spacePreserve = true;
          else if (defaut == "default")
            spacePreserve = false;
          break;
        }
      }
    }
    if (spacePreserve) {
      doc.insertString(selectionStart, "    ");
      event.preventDefault();
    }
  }

  Position nextCaretPosition(Position pos) {
    if (pos.dn is DNDocument && pos.dnOffset == pos.dn.offsetLength)
      return(pos);
    DaxeNode dn = pos.dn;
    int offset = pos.dnOffset;
    // when at the end, get out of non-block nodes with no delimiter
    while (dn != null && dn.noDelimiter && offset == dn.offsetLength && !dn.block) {
      offset = dn.parent.offsetOf(dn) + 1;
      dn = dn.parent;
    }
    // if the node at offset is a text or style, move inside
    DaxeNode nodeAtOffset;
    if (dn.firstChild != null && offset < dn.offsetLength)
      nodeAtOffset = dn.childAtOffset(offset);
    else
      nodeAtOffset = null;
    while (nodeAtOffset != null && nodeAtOffset.noDelimiter && !nodeAtOffset.block) {
      dn = nodeAtOffset;
      offset = 0;
      if (dn.firstChild != null && offset < dn.offsetLength)
        nodeAtOffset = dn.childAtOffset(offset);
      else
        nodeAtOffset = null;
    }

    // visible change of position
    // consecutive moves between blocks with no delimiter are not considered cursor moves
    bool noDelimiterBlockMove = false;
    if (offset == dn.offsetLength) {
      // get out of the node
      noDelimiterBlockMove = (dn.noDelimiter && dn.block);
      offset = dn.parent.offsetOf(dn) + 1;
      dn = dn.parent;
      while (noDelimiterBlockMove && dn.noDelimiter && dn.block && offset == dn.offsetLength) {
        // get out of other no delimiter block nodes
        offset = dn.parent.offsetOf(dn) + 1;
        dn = dn.parent;
      }
    } else if (dn is DNText) {
      // move in the text
      offset++;
    } else {
      // enter the node
      dn = dn.childAtOffset(offset);
      // when just entering a node, move to the first cursor position inside
      Position first = dn.firstCursorPositionInside();
      if (first != null) {
        dn = first.dn;
        offset = first.dnOffset;
        noDelimiterBlockMove = (dn.noDelimiter && dn.block);
      } else {
        // if there is none, move after this node
        offset = dn.parent.offsetOf(dn) + 1;
        dn = dn.parent;
      }
    }

    // move inside non-block nodes with no delimiter at current offset
    if (dn.firstChild != null && offset < dn.offsetLength)
      nodeAtOffset = dn.childAtOffset(offset);
    else
      nodeAtOffset = null;
    while (nodeAtOffset != null && nodeAtOffset.noDelimiter &&
        (!nodeAtOffset.block || noDelimiterBlockMove)) {
      dn = nodeAtOffset;
      offset = 0;
      if (dn.firstChild != null && offset < dn.offsetLength)
        nodeAtOffset = dn.childAtOffset(offset);
      else
        nodeAtOffset = null;
    }
    return(new Position(dn, offset));
  }

  Position previousCaretPosition(Position pos) {
    if (pos.dn is DNDocument && pos.dnOffset == 0)
      return(pos);
    DaxeNode dn = pos.dn;
    int offset = pos.dnOffset;
    // when at the beginning, get out of non-block nodes with no delimiter
    while (dn != null && dn.noDelimiter && offset == 0 && !dn.block) {
      offset = dn.parent.offsetOf(dn);
      dn = dn.parent;
    }
    // if the node before is a text or style, move inside
    DaxeNode nodeBefore;
    if (dn.firstChild != null && offset > 0)
      nodeBefore = dn.childAtOffset(offset - 1);
    else
      nodeBefore = null;
    while (nodeBefore != null && nodeBefore.noDelimiter && !nodeBefore.block) {
      dn = nodeBefore;
      offset = dn.offsetLength;
      if (dn.firstChild != null && offset > 0)
        nodeBefore = dn.childAtOffset(offset - 1);
      else
        nodeBefore = null;
    }

    // visible change of position
    // consecutive moves between blocks with no delimiter are not considered cursor moves
    bool noDelimiterBlockMove = false;
    if (offset == 0) {
      // get out of the node
      noDelimiterBlockMove = (dn.noDelimiter && dn.block);
      offset = dn.parent.offsetOf(dn);
      dn = dn.parent;
      while (noDelimiterBlockMove && dn.noDelimiter && dn.block && offset == 0) {
        // get out of other no delimiter block nodes
        offset = dn.parent.offsetOf(dn);
        dn = dn.parent;
      }
    } else if (dn is DNText) {
      // move in the text
      offset--;
    } else {
      // enter the node
      dn = dn.childAtOffset(offset-1);
      offset = dn.offsetLength;
      // when just entering a node, move to the last cursor position inside
      Position last = dn.lastCursorPositionInside();
      if (last != null) {
        dn = last.dn;
        offset = last.dnOffset;
        noDelimiterBlockMove = (dn.noDelimiter && dn.block);
      } else {
        // if there is none, move before this node
        offset = dn.parent.offsetOf(dn);
        dn = dn.parent;
      }
    }

    // move inside non-block nodes with no delimiter before current offset
    if (dn.firstChild != null && offset > 0)
      nodeBefore = dn.childAtOffset(offset - 1);
    else
      nodeBefore = null;
    while (nodeBefore != null && nodeBefore.noDelimiter &&
        (!nodeBefore.block || noDelimiterBlockMove)) {
      dn = nodeBefore;
      offset = dn.offsetLength;
      if (dn.firstChild != null && offset > 0)
        nodeBefore = dn.childAtOffset(offset - 1);
      else
        nodeBefore = null;
    }
    return(new Position(dn, offset));
  }

  /**
   * Returns position one word to the left if possible,
   * otherwise returns the previous position.
   */
  Position previousWordPosition(Position pos) {
    if (pos.dn is DNText) {
      int offset = pos.dnOffset;
      String s = pos.dn.nodeValue;
      while (offset-1 >= 0 && wordDelimiters.contains(s[offset-1]))
        offset--;
      while (offset-1 >= 0 && !wordDelimiters.contains(s[offset-1]))
        offset--;
      if (offset != pos.dnOffset)
        return new Position(pos.dn, offset);
    }
    return previousCaretPosition(pos);
  }

  /**
   * Returns position one word to the right if possible,
   * otherwise returns the next position.
   */
  Position nextWordPosition(Position pos) {
    if (pos.dn is DNText) {
      int offset = pos.dnOffset;
      String s = pos.dn.nodeValue;
      while (offset < s.length && wordDelimiters.contains(s[offset]))
        offset++;
      while (offset < s.length && !wordDelimiters.contains(s[offset]))
        offset++;
      if (offset != pos.dnOffset)
        return new Position(pos.dn, offset);
    }
    return nextCaretPosition(pos);
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
      } else {
        if (selectionStart.dn is DNWItem)
          prevBlock = false; // special case for the beginning of a WYSIWYG list item
        else
          prevBlock = true;
      }
      bool nextBlock;
      if (selectionStart.dnOffset < selectionStart.dn.offsetLength) {
        DaxeNode next = selectionStart.dn.childAtOffset(selectionStart.dnOffset);
        h.Element hnext = next.getHTMLNode();
        if (next is DNWItem && selectionStart.dnOffset == 0)
          nextBlock = false; // special case for the beginning of a WYSIWYG list
        else
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
    if (visible)
      show();
    ta.focus();
  }

  /**
   * Clears the hidden field
   */
  void clearField() {
    ta.value = '';
  }

  setSelection(Position start, Position end, {updateUI:true}) {
    if (selectionStart == start && selectionEnd == end) {
      if (start == end) {
        updateCaretPosition(false);
      }
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

    // fix selection start and end for styles (different positions look the same for the user)
    // and to keep only the elements entirely inside the selection
    // move the start and end positions out of text and style if possible
    // exception for hidden paragraphs and list items:
    //   selection is not extended when it is just the line
    while (selectionStart.dn.noDelimiter && selectionStart.dnOffset == 0 &&
        !((selectionStart.dn is DNHiddenP || selectionStart.dn is DNWItem) &&
        selectionEnd <= new Position(selectionStart.dn, selectionStart.dn.offsetLength))) {
      selectionStart = new Position(selectionStart.dn.parent,
          selectionStart.dn.parent.offsetOf(selectionStart.dn));
    }
    while (selectionStart.dn.noDelimiter &&
        selectionStart.dnOffset == selectionStart.dn.offsetLength) {
      selectionStart = new Position(selectionStart.dn.parent,
          selectionStart.dn.parent.offsetOf(selectionStart.dn) + 1);
    }
    while (selectionEnd.dn.noDelimiter &&
        selectionEnd.dnOffset == selectionEnd.dn.offsetLength) {
      selectionEnd = new Position(selectionEnd.dn.parent,
          selectionEnd.dn.parent.offsetOf(selectionEnd.dn) + 1);
    }
    while (selectionEnd.dn.noDelimiter && selectionEnd.dnOffset == 0 &&
        !((selectionEnd.dn is DNHiddenP || selectionEnd.dn is DNWItem) &&
        selectionEnd == selectionStart)) {
      selectionEnd = new Position(selectionEnd.dn.parent,
          selectionEnd.dn.parent.offsetOf(selectionEnd.dn));
    }
    // now move positions closer if possible
    if (selectionStart != selectionEnd) {
      if (selectionStart.dn.noDelimiter &&
          selectionStart.dnOffset == selectionStart.dn.offsetLength) {
        DaxeNode next = selectionStart.dn.nextNode();
        selectionStart = new Position(next.parent, next.parent.offsetOf(next));
      }
      if (selectionEnd.dn.noDelimiter &&
          selectionEnd.dnOffset == 0) {
        DaxeNode prev = selectionEnd.dn.previousNode();
        selectionEnd = new Position(prev.parent, prev.parent.offsetOf(prev) + 1);
      }
      bool cont;
      do {
        cont = false;
        if (selectionStart.dn is! DNText && selectionStart.dnOffset < selectionStart.dn.offsetLength) {
          DaxeNode next = selectionStart.dn.childAtOffset(selectionStart.dnOffset);
          if (new Position(selectionStart.dn, selectionStart.dnOffset + 1) > selectionEnd &&
              new Position(next, 0) < selectionEnd) {
            // next is not included and the end is after the beginning of next
            selectionStart = new Position(next, 0);
            cont = true;
          }
        }
      } while (cont);
      do {
        cont = false;
        if (selectionEnd.dn is! DNText && selectionEnd.dnOffset > 0) {
          DaxeNode prev = selectionEnd.dn.childAtOffset(selectionEnd.dnOffset - 1);
          if (new Position(selectionEnd.dn, selectionEnd.dnOffset - 1) < selectionStart &&
              new Position(prev, prev.offsetLength) > selectionStart) {
            // prev is not included and the start is before the end of prev
            selectionEnd = new Position(prev, prev.offsetLength);
            cont = true;
          }
        }
      } while (cont);
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
    if (updateUI && selectionStart != previousStart)
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
      if (parent == null)
        continue;
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
    DaxeNode toremove;
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
      toremove = next;
      if (toremove.nodeType == DaxeNode.TEXT_NODE && toremove.parent != null &&
          toremove.offsetLength == 1)
        toremove = toremove.parent;
    } else if (pos.dn.nodeType == DaxeNode.TEXT_NODE &&
        pos.dn.offsetLength < pos.dnOffset + 1 &&
        pos.dn.nextSibling == null) {
      // remove pos.dn's parent
      toremove = pos.dn;
      if (toremove.parent != null)
        toremove = toremove.parent;
      if (toremove.noDelimiter && toremove.block) {
        if (toremove.nextSibling.ref == toremove.ref) {
          // merge the blocks with no delimiter
          mergeBlocks(toremove, toremove.nextSibling);
        } else {
          // remove something just after this character
          Position after = new Position.clone(pos);
          after.move(1);
          if (after > pos)
            removeChar(after);
        }
        return;
      }
    } else if (pos.dn.nodeType == DaxeNode.ELEMENT_NODE && pos.dn.offsetLength < pos.dnOffset + 1) {
      // remove pos.dn
      toremove = pos.dn;
      if (toremove.noDelimiter && toremove.block) {
        if (toremove.nextSibling != null && toremove.nextSibling.ref == toremove.ref) {
          // merge the blocks with no delimiter
          mergeBlocks(toremove, toremove.nextSibling);
          return;
        }
      }
    } else if (pos.dn.nodeType == DaxeNode.ELEMENT_NODE ||
        pos.dn.nodeType == DaxeNode.DOCUMENT_NODE) {
      toremove = pos.dn.childAtOffset(pos.dnOffset);
      if (toremove.noDelimiter && toremove.block) {
        if (toremove.previousSibling != null && toremove.previousSibling.ref == toremove.ref) {
          // merge the blocks with no delimiter
          mergeBlocks(toremove.previousSibling, toremove);
          return;
        } else if (toremove.offsetLength > 0) {
          // remove something just before this character
          Position before = new Position.clone(pos);
          before.move(-1);
          if (before < pos)
            removeChar(before);
          return;
        }
      }
      if (toremove == null) {
        h.window.alert("I'm sorry Dave, I'm afraid I can't do that.");
        return;
      }
    } else if (pos.dn.nodeType == DaxeNode.TEXT_NODE &&
        pos.dnOffset == 0 && pos.dn.offsetLength == 1 &&
        pos.dn.parent is DNStyle && pos.dn.parent.offsetLength == 1) {
      // remove the style node
      toremove = pos.dn.parent;
      while (toremove.parent is DNStyle && toremove.parent.offsetLength == 1)
        toremove = toremove.parent;
    } else {
      doc.removeString(pos, 1);
      // merge styles if possible
      EditAndNewPositions ep = DNStyle.mergeAt(selectionStart);
      if (ep != null) {
        doc.doNewEdit(ep.edit);
        doc.combineLastEdits(Strings.get('undo.remove_text'), 2);
        setSelection(ep.start, ep.end);
      }
      return;
    }
    if (toremove is DNWItem && toremove.parent.offsetLength == 1) {
      // remove the whole DNWList when the last DNWItem inside is removed
      toremove = toremove.parent;
    }
    if (!toremove.userCannotRemove) {
      doc.removeNode(toremove);
      // merge styles if possible
      EditAndNewPositions ep = DNStyle.mergeAt(selectionStart);
      if (ep != null) {
        doc.doNewEdit(ep.edit);
        doc.combineLastEdits(Strings.get('undo.remove_element'), 2);
        setSelection(ep.start, ep.end);
      }
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
    if (start.dn is DNWList && start.dn == end.dn && start.dnOffset == 0 &&
        end.dnOffset == end.dn.offsetLength) {
      // all DNWItem will be removed, the whole DNWList must be removed instead
      doc.removeNode(start.dn);
    } else {
      doc.removeBetween(start, end);
      // merge styles if possible
      EditAndNewPositions ep = DNStyle.mergeAt(start);
      if (ep != null) {
        doc.doNewEdit(ep.edit);
        doc.combineLastEdits(Strings.get('undo.remove'), 2);
        setSelection(ep.start, ep.end);
      }
    }
  }

  /**
   * Refresh display
   */
  void refresh() {
    Position start = selectionStart;
    Position end = selectionEnd;
    selectionStart = null;
    selectionEnd = null;
    setSelection(start, end);
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
   * Parses the given String and pastes the XML or text at the current position.
   * Returns true if it was pasted without error.
   */
  void pasteString(String s) {
    s = s.replaceAll(new RegExp(r'<\?xml[^?]*\?>'), ''); // remove doc decl
    x.Document tmpdoc;
    String parse = "<root";
    if (doc.cfg != null) {
      // add namespaces to a root element to get the right references later
      for (String namespace in doc.cfg.namespaceList()) {
        if (namespace != '') {
          String prefix = doc.cfg.namespacePrefix(namespace);
          String attname;
          if (prefix != null && prefix != '')
            attname = "xmlns:$prefix";
          else
            attname = "xmlns";
          parse += ' $attname="$namespace"';
        }
      }
    }
    parse += ">$s</root>";
    try {
      try {
        x.DOMParser dp = new x.DOMParser();
        tmpdoc = dp.parseFromString(parse);
      } on x.DOMException {
        // this is not XML, it is inserted as string if it is possible
        pasteText(s);
        return;
      }
      pasteXML(tmpdoc);
    } on DaxeException catch(ex) {
      h.window.alert(ex.toString());
    }
  }

  /**
   * Pastes the text at the current position (using hidden paragraphs if possible).
   * Throws a DaxeException if it was not valid.
   */
  void pasteText(String s) {
    DaxeNode parent = selectionStart.dn;
    if (parent is DNText)
      parent = parent.parent;
    if (parent == null)
      throw new DaxeException(Strings.get('insert.text_not_allowed'));
    x.Element hiddenp;
    if (parent.ref != null && doc.hiddenParaRefs != null)
      hiddenp = doc.cfg.findSubElement(parent.ref, doc.hiddenParaRefs);
    else
      hiddenp = null;
    bool parentWithText = parent.ref != null && doc.cfg.canContainText(parent.ref);
    bool problem = false;
    if (s.trim() != '') {
      if (parent.nodeType == DaxeNode.DOCUMENT_NODE)
        problem = true;
      else if (!parentWithText && hiddenp == null)
        problem = true;
    }
    if (problem)
      throw new DaxeException(Strings.get('insert.text_not_allowed'));

    // use hidden paragraphs instead of newlines if allowed at current position
    // also use hidden paragraphs if a paragraph is required to insert text
    bool useParagraphs = hiddenp != null && (s.contains('\n') || !parentWithText);
    if (!useParagraphs) {
      if (selectionStart == selectionEnd)
        doc.insertString(selectionStart, s);
      else {
        UndoableEdit edit = new UndoableEdit.compound(Strings.get('undo.paste'));
        // save and move start position so it keeps reliable for insert
        Position start = new Position.clone(selectionStart);
        while ((start.dn is DNText || start.dn is DNStyle) && start.dnOffset == 0)
          start = new Position(start.dn.parent, start.dn.parent.offsetOf(start.dn));
        if (start.dn is! DNText && start.dn.childAtOffset(start.dnOffset-1) is DNText) {
          DNText previous = start.dn.childAtOffset(start.dnOffset-1);
          start = new Position(previous, previous.offsetLength);
        }
        edit.addSubEdit(doc.removeBetweenEdit(selectionStart, selectionEnd));
        edit.addSubEdit(new UndoableEdit.insertString(start, s));
        doc.doNewEdit(edit);
      }
      return;
    }
    x.DOMImplementation domimpl = new x.DOMImplementationImpl();
    x.Document tmpdoc = domimpl.createDocument(null, null, null);
    x.Element root = tmpdoc.createElement('root');
    tmpdoc.appendChild(root);
    List<String> parts = s.split('\n');
    for (String part in parts) {
      x.Element p = tmpdoc.createElementNS(null, doc.cfg.elementName(hiddenp));
      if (part != '')
        p.appendChild(tmpdoc.createTextNode(part));
      root.appendChild(p);
    }
    pasteXML(tmpdoc);
  }

  /**
   * Pastes the XML (without the root element) at the current position.
   * Throws a DaxeException if it was not valid.
   */
  void pasteXML(x.Document tmpdoc) {
    x.Element root = tmpdoc.documentElement;
    if (root.firstChild != null && root.firstChild.nextSibling == null &&
        root.firstChild.nodeType == x.Node.TEXT_NODE) {
      pasteText(root.firstChild.nodeValue);
      return;
    }
    if (selectionStart == selectionEnd && doc.hiddenParaRefs != null &&
        selectionStart.dn is DNText && (selectionStart.dnOffset == 0 ||
        selectionStart.dnOffset == selectionStart.dn.offsetLength)) {
      DaxeNode parent = selectionStart.dn.parent;
      if (parent.parent != null && parent.parent.ref != null &&
          doc.hiddenParaRefs.contains(parent.ref)) {
        // at the beginning or end of a hidden paragraph: move paste position outside
        // if it helps to insert the first node
        // NOTE: we could generalize this behavior when the cursor is elsewhere
        //       and we could test more children
        if (!doc.cfg.isSubElementByName(parent.ref, root.firstChild.nodeName)) {
          if (doc.cfg.isSubElementByName(parent.parent.ref, root.firstChild.nodeName)) {
            if (selectionStart.dnOffset == 0)
              selectionStart = new Position(parent.parent,
                  parent.parent.offsetOf(parent));
            else
              selectionStart = new Position(parent.parent,
                  parent.parent.offsetOf(parent)+1);
            selectionEnd = new Position.clone(selectionStart);
          }
        }
      }
    }
    DaxeNode parent = selectionStart.dn;
    if (parent is DNText)
      parent = parent.parent;
    // to call fixLineBreaks(), we need a real DaxeNode for the "root", with the right ref
    DaxeNode dnRoot;
    if (parent.ref == null)
      dnRoot = new DNDocument();
    else
      dnRoot = NodeFactory.create(parent.ref);
    doc.cfg.addNamespaceAttributes(dnRoot);
    if (root.childNodes != null) {
      for (x.Node n in root.childNodes) {
        DaxeNode dn = NodeFactory.createFromNode(n, dnRoot);
        dnRoot.appendChild(dn);
      }
    }
    dnRoot.fixLineBreaks();
    if (doc.hiddenParaRefs != null) {
      // add or remove hidden paragraphs where necessary
      DNHiddenP.fixFragment(parent, dnRoot);
      doc.removeWhitespaceForHiddenParagraphs(dnRoot);
    }
    UndoableEdit edit = new UndoableEdit.compound(Strings.get('undo.paste'));

    // save and move positions so they keep reliable for insert and merge
    Position start = new Position.clone(selectionStart);
    while ((start.dn is DNText || start.dn is DNStyle) && start.dnOffset == 0)
      start = new Position(start.dn.parent, start.dn.parent.offsetOf(start.dn));
    while ((start.dn is DNText || start.dn is DNStyle) && start.dnOffset == start.dn.offsetLength)
      start = new Position(start.dn.parent, start.dn.parent.offsetOf(start.dn)+1);
    if (start.dn is! DNText && start.dn.childAtOffset(start.dnOffset-1) is DNText) {
      DNText previous = start.dn.childAtOffset(start.dnOffset-1);
      start = new Position(previous, previous.offsetLength);
    }
    Position end = new Position.clone(selectionEnd);
    while ((end.dn is DNText || end.dn is DNStyle) && end.dnOffset == 0)
      end = new Position(end.dn.parent, end.dn.parent.offsetOf(end.dn));
    while ((end.dn is DNText || end.dn is DNStyle) && end.dnOffset == end.dn.offsetLength)
      end = new Position(end.dn.parent, end.dn.parent.offsetOf(end.dn)+1);
    if (end.dn is! DNText && end.dn.childAtOffset(end.dnOffset) is DNText) {
      DNText next = end.dn.childAtOffset(end.dnOffset);
      end = new Position(next, 0);
    }
    end = new Position.rightOffsetPosition(end);

    if (selectionStart != selectionEnd)
      edit.addSubEdit(doc.removeBetweenEdit(selectionStart, selectionEnd));
    edit.addSubEdit(doc.insertChildrenEdit(dnRoot, start, checkValidity:true));
    doc.doNewEdit(edit);
    // merge styles if possible
    EditAndNewPositions ep = DNStyle.mergeAt(start);
    if (ep != null) {
      doc.doNewEdit(ep.edit);
      doc.combineLastEdits(Strings.get('undo.paste'), 2);
    }
    setSelection(end, end);
    ep = DNStyle.mergeAt(end);
    if (ep != null) {
      doc.doNewEdit(ep.edit);
      doc.combineLastEdits(Strings.get('undo.paste'), 2);
      setSelection(ep.end, ep.end);
    }
  }

  /**
   * Try to paste HTML, paste the plain alternative if that does not work.
   */
  void pasteHTML(String html, String plain) {
    // Let the browser and Dart parse and fix some of the syntax before trying to use it
    h.DivElement div = new h.DivElement();
    MyTreeSanitizer sanitizer = new MyTreeSanitizer();
    div.setInnerHtml(html, treeSanitizer:sanitizer);
    String fixed = (new h.XmlSerializer()).serializeToString(div);
    x.Document tmpdoc;
    try {
      x.DOMParser dp = new x.DOMParser();
      tmpdoc = dp.parseFromString(fixed);
      if (tmpdoc.documentElement.getAttribute('xmlns') != '') {
        tmpdoc.documentElement.removeAttribute('xmlns');
        _removeNamespace(tmpdoc.documentElement);
      }
      cleanupHTML(tmpdoc.documentElement);
      // removeWhitespace needs the right references
      DaxeNode parent = selectionStart.dn;
      if (parent is DNText)
        parent = parent.parent;
      tmpdoc.documentElement.nodeName = parent.nodeName;
      tmpdoc.documentElement.namespaceURI = parent.namespaceURI;
      tmpdoc.documentElement.prefix = parent.prefix;
      tmpdoc.documentElement.localName = parent.localName;
      x.Element refGrandParent;
      if (parent.parent == null)
        refGrandParent = null;
      else
        refGrandParent = parent.parent.ref;
      doc._removeWhitespace(tmpdoc.documentElement, refGrandParent, false, true);
      try {
        pasteXML(tmpdoc);
        return;
      } on DaxeException catch(ex) {
        String errmsg = ex.toString();
        if (errmsg != Strings.get('insert.text_not_allowed') &&
            parent.ref != null && doc.cfg.canContainText(parent.ref)) {
          try {
            pasteText(plain);
            errmsg = Strings.get('cursor.pasting_xml_failed') +
                ' (' + errmsg + ')';
          } on DaxeException {
          }
        } else
          errmsg = Strings.get('insert.text_not_allowed');
        // see Blink bug:
        // https://code.google.com/p/chromium/issues/detail?id=299805
        // workaround: using a Timer
        Timer.run(()=>h.window.alert(errmsg));
      }
    } on x.DOMException {
      try {
        pasteText(plain);
      } on DaxeException catch(ex) {
        Timer.run(()=>h.window.alert(ex.toString()));
      }
    }
  }

  void _removeNamespace(x.Element el) {
    el.namespaceURI = null;
    for (x.Node n=el.firstChild; n!=null; n=n.nextSibling) {
      if (n.nodeType == x.Node.ELEMENT_NODE) {
        _removeNamespace(n);
      }
    }
  }

  /**
   * Try to cleanup the HTML, removing all style information and
   * some text processor crap.
   */
  void cleanupHTML(x.Element el) {
    if (el.getAttribute('class') != '')
      el.removeAttribute('class');
    if (el.getAttribute('style') != '')
      el.removeAttribute('style');
    x.Node next;
    for (x.Node n=el.firstChild; n!=null; n=next) {
      next = n.nextSibling;
      if (n.nodeType == x.Node.ELEMENT_NODE) {
        x.Element en = n;
        if (n.prefix != null) {
          el.removeChild(n);
        } else {
          cleanupHTML(n);
          String name = n.nodeName;
          bool replaceByChildren = false;
          if (name == 'center' || name == 'font') {
            replaceByChildren = true;
          } else if (name == 'b' || name == 'i') {
            if (n.firstChild == null)
              el.removeChild(n);
          } else if (name == 'span' || name == 'div') {
            if (n.firstChild == null) {
              el.removeChild(n);
            } else {
              replaceByChildren = true;
            }
          } else if (name == 'p' && n.firstChild != null &&
              (el.nodeName == 'li' || el.nodeName == 'td') &&
              (n.previousSibling == null ||
                (n.previousSibling.nodeType == x.Node.TEXT_NODE &&
                  n.previousSibling.previousSibling == null &&
                  n.previousSibling.nodeValue.trim() == '')) &&
              (n.nextSibling == null ||
                (n.nextSibling.nodeType == x.Node.TEXT_NODE &&
                  n.nextSibling.nextSibling == null &&
                  n.nextSibling.nodeValue.trim() == ''))) {
            // remove useless paragraphs in li and td
            replaceByChildren = true;
          } else if (name == 'img') {
            String src = en.getAttribute('src');
            // TODO: upload data images when possible
            if (src != null && !src.startsWith('data:'))
              en.setAttribute('src', src.split('/').last);
          } else if (name == 'a') {
            String href = en.getAttribute('href');
            if (href != null && href.startsWith('file://')) {
              String last = href.split('/').last;
              if (last.contains('#'))
                last = last.substring(last.indexOf('#'));
              en.setAttribute('href', last);
            }
          }
          if (replaceByChildren) {
            // replace element by its children
            x.Node first = n.firstChild;
            x.Node next2;
            for (x.Node n2=first; n2!=null; n2=next2) {
              next2 = n2.nextSibling;
              n.removeChild(n2);
              if (next == null)
                el.appendChild(n2);
              else
                el.insertBefore(n2, next);
            }
            el.removeChild(n);
            if (first != null)
              next = first;
          }
        }
      } else if (n.nodeType == x.Node.COMMENT_NODE) {
        el.removeChild(n);
      }
    }
    // normalize text
    for (x.Node n=el.firstChild; n!=null; n=n.nextSibling) {
      while (n.nodeType == x.Node.TEXT_NODE && n.nextSibling != null &&
          n.nextSibling.nodeType == x.Node.TEXT_NODE) {
        n.nodeValue = "${n.nodeValue}${n.nextSibling.nodeValue}";
        el.removeChild(n.nextSibling);
      }
    }
  }

  /**
   * Returns true if the image will probably be pasted.
   */
  bool pasteImage(h.DataTransfer data) {
    if (selectionStart == null)
      return false;
    DaxeNode parent = selectionStart.dn;
    if (parent is DNText)
      parent = parent.parent;
    if (parent.ref == null)
      return false;
    List<x.Element> childrenRefs = doc.cfg.subElements(parent.ref);
    x.Element imageRef = null;
    for (x.Element ref in childrenRefs) {
      String type = doc.cfg.elementDisplayType(ref);
      if (type == 'file' || type == 'fichier') {
        imageRef = ref;
        break;
      }
    }
    if (imageRef == null)
      return false;
    h.Blob blob = null;
    if (data.items != null) {
      // Chromium, pasted image (not a file)
      for (int i=0; i<data.items.length; i++) {
        if (data.items[i].type.indexOf('image') == 0) {
          blob = data.items[i].getAsFile();
          break;
        }
      }
    } else if (data.files != null) {
      // pasted file, might work with Firefox or IE
      for (int i=0; i<data.files.length; i++) {
        if (data.files[i].type.indexOf('image') == 0) {
          blob = data.files[i];
          break;
        }
      }
    }
    if (blob == null)
      return false;
    if (doc.saveURL == null) {
      // no server, use data: for src
      h.FileReader reader = new h.FileReader();
      reader.onLoad.listen((h.ProgressEvent e) {
        DNFile img = NodeFactory.create(imageRef);
        img.setSrc(reader.result);
        doc.insertNode(img, selectionStart);
      });
      reader.readAsDataUrl(blob);
    } else {
      // upload the image file
      try {
        _uploadAndCreateImage(blob, imageRef);
      } on DaxeException catch(ex) {
        h.window.alert(Strings.get('save.error') + ': ' + ex.message);
      }
    }
    return true;
  }

  Future _uploadAndCreateImage(h.Blob blob, x.Element imageRef) async {
    String type = blob.type;
    String filename;
    String dirURI = doc.filePath;
    dirURI = dirURI.substring(0, dirURI.lastIndexOf('/')+1);
    if (blob is h.File)
      filename = blob.name;
    else {
      String extension = type;
      if (extension.contains('/'))
        extension = extension.split('/').last;
      // read the directory to find a number to use in the file name
      Uri htmlUri = Uri.parse(h.window.location.toString());
      Uri docUri = Uri.parse(doc.filePath);
      List<String> segments = new List<String>.from(docUri.pathSegments);
      segments.removeLast();
      Uri openDir = docUri.replace(scheme:htmlUri.scheme, host:htmlUri.host,
          port:htmlUri.port, pathSegments:segments);
      List<DirectoryItem> items = await FileChooser.readDirectory(openDir);
      String baseName = 'pasted_image_';
      int newNumber = 1;
      for (DirectoryItem item in items) {
        if (item.type == DirectoryItemType.FILE && item.name.startsWith(baseName)) {
          String noExt = item.name;
          int ind = item.name.indexOf('.');
          if (ind != -1)
            noExt = item.name.substring(0, ind);
          String sNum = noExt.substring(baseName.length);
          int num;
          num = int.parse(sNum, onError: (String s) => null);
          if (num != null && num >= newNumber)
            newNumber = num + 1;
        }
      }
      filename = 'pasted_image_${newNumber}.' + extension;
    }
    String uri = dirURI + filename;
    await doc.uploadFile(uri, blob);
    DNFile img = NodeFactory.create(imageRef);
    img.setSrc(filename);
    doc.insertNode(img, selectionStart);
    return true;
  }

  void mergeBlocks(DaxeNode dn1, DaxeNode dn2) {
    UndoableEdit edit = new UndoableEdit.compound(Strings.get('undo.remove_text'));
    DaxeNode clone;
    Position clonep1 = new Position(dn2, 0);
    Position clonep2 = new Position(dn2, dn2.offsetLength);
    if (clonep2 > clonep1)
      clone = doc.cloneBetween(clonep1, clonep2);
    else
      clone = null;
    edit.addSubEdit(new UndoableEdit.removeNode(dn2));
    if (clone != null)
      edit.addSubEdit(doc.insertChildrenEdit(clone, new Position(dn1, dn1.offsetLength)));
    Position futureCursorPos;
    if (dn1.lastChild is DNText)
      futureCursorPos = new Position(dn1.lastChild, dn1.lastChild.offsetLength);
    else
      futureCursorPos = new Position(dn1, dn1.offsetLength);
    doc.doNewEdit(edit);
    page.moveCursorTo(futureCursorPos);
  }

  void mergeBlockWithPreviousNodes(DaxeNode dn) {
    assert(dn.previousSibling != null);
    int offset = dn.parent.offsetOf(dn);
    UndoableEdit edit = new UndoableEdit.compound(Strings.get('undo.remove_text'));
    // clone the nodes that will move into the paragraph
    int startOffset = offset;
    bool withText = doc.cfg.canContainText(dn.ref);
    while (startOffset > 0) {
      DaxeNode child = dn.parent.childAtOffset(startOffset-1);
      if (child.block || (child is DNText && !withText) ||
          (child.ref != null && !doc.cfg.isSubElement(dn.ref, child.ref)))
        break;
      startOffset--;
    }
    Position pStart = new Position(dn.parent, startOffset);
    Position currentPos = new Position(dn.parent, offset);
    assert (pStart < currentPos);
    DaxeNode cloneLeft = doc.cloneCutBetween(dn.parent, pStart, currentPos);
    edit.addSubEdit(doc.removeBetweenEdit(pStart, currentPos));
    edit.addSubEdit(doc.insertChildrenEdit(cloneLeft, new Position(dn, 0)));
    Position futureCursorPos = new Position(dn, 0);
    futureCursorPos.moveInsideTextNodeIfPossible();
    futureCursorPos = new Position.rightOffsetPosition(futureCursorPos);
    doc.doNewEdit(edit);
    moveTo(futureCursorPos);
    page.updateAfterPathChange();
    return;
  }

  void mergeBlockWithNextNodes(DaxeNode dn) {
    assert(dn.nextSibling != null);
    int offset = dn.parent.offsetOf(dn.nextSibling);
    UndoableEdit edit = new UndoableEdit.compound(Strings.get('undo.remove_text'));
    // clone the nodes that will move into the paragraph
    int endOffset = offset;
    bool withText = doc.cfg.canContainText(dn.ref);
    while (endOffset < dn.parent.offsetLength) {
      DaxeNode child = dn.parent.childAtOffset(endOffset);
      if (child.block || (child is DNText && !withText) ||
          (child.ref != null && !doc.cfg.isSubElement(dn.ref, child.ref)))
        break;
      endOffset++;
    }
    Position pEnd = new Position(dn.parent, endOffset);
    Position currentPos = new Position(dn.parent, offset);
    assert (currentPos < pEnd);
    DaxeNode cloneRight = doc.cloneCutBetween(dn.parent, currentPos, pEnd);
    edit.addSubEdit(doc.removeBetweenEdit(currentPos, pEnd));
    edit.addSubEdit(doc.insertChildrenEdit(cloneRight, new Position(dn, dn.offsetLength)));
    Position futureCursorPos = new Position(dn, dn.offsetLength);
    futureCursorPos.moveInsideTextNodeIfPossible();
    futureCursorPos = new Position.leftOffsetPosition(futureCursorPos);
    doc.doNewEdit(edit);
    moveTo(futureCursorPos);
    page.updateAfterPathChange();
    return;
  }

  /**
   * Copies the current selection to the clipboard when the browser allows it.
   * Otherwise display a message suggesting to use Ctrl-C.
   */
  void clipboardCopy() {
    if (selectionStart == null || selectionStart == selectionEnd)
      return;
    ta.value = copy();
    ta.select();
    bool success;
    try {
      success = h.document.execCommand('copy', false, null);
    } catch(ex) {
      success = false;
    }
    ta.value = '';
    if (!success) {
      h.window.alert(Strings.get('menu.copy_with_keyboard'));
    }
  }

  /**
   * Copies the current selection to the clipboard when the browser allows it.
   * Otherwise display a message suggesting to use Ctrl-C.
   */
  void clipboardCut() {
    if (selectionStart == null || selectionStart == selectionEnd)
      return;
    ta.value = copy();
    ta.select();
    bool success;
    try {
      success = h.document.execCommand('cut', false, null);
    } catch(ex) {
      success = false;
    }
    ta.value = '';
    if (success) {
      removeSelection();
      page.updateAfterPathChange();
    } else {
      h.window.alert(Strings.get('menu.cut_with_keyboard'));
    }
  }
}

class LaxUriPolicy implements h.UriPolicy {
  @override
  bool allowsUri(String uri) => true;
}

/**
 * We need a custom tree sanitizer because Dart's sanitizer removes an entire element content
 * when it is not valid. This sanitizer preserves the children in such a case,
 * which is standard behavior for HTML.
 */
class MyTreeSanitizer implements h.NodeTreeSanitizer {
  h.NodeValidator validator;

  MyTreeSanitizer() {
    h.UriPolicy policy = new LaxUriPolicy();
    validator = new h.NodeValidatorBuilder.common()
          ..allowImages(policy)
          ..allowNavigation(policy);
    // NOTE: we could allow inline style with allowInlineStyles(),
    // but then we will have to clean that up in cleanupHTML().
  }

  void sanitizeTree(h.Node node) {
    h.Node next;
    for (h.Node n=node.firstChild; n != null; n = next) {
      next = n.nextNode;
      if (n.nodeType == h.Node.ELEMENT_NODE) {
        h.Element ne = (n as h.Element);
        if (!validator.allowsElement(ne)) {
          // replace element by its children, except for <style> and <script>
          if (n.nodeName == 'STYLE' || n.nodeName == 'SCRIPT') {
            n.remove();
          } else {
            h.Node first = n.firstChild;
            h.Node next2;
            for (h.Node n2=first; n2!=null; n2=next2) {
              next2 = n2.nextNode;
              n2.remove();
              if (next == null)
                node.append(n2);
              else
                node.insertBefore(n2, next);
            }
            n.remove();
            if (first != null)
              next = first;
          }
        } else {
          Map<String, String> attributes = ne.attributes;
          attributes.forEach((String name, String value) {
            if (!validator.allowsAttribute(ne, name, value))
              ne.attributes.remove(name);
          });
          sanitizeTree(ne);
        }
      }
    }
  }
}
