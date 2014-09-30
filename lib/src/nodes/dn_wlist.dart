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
 * A WYSIWYG bulleted list, to use with DNWItem.
 * Jaxe display type: 'wlist' (use with item 'witem').
 * 
 * parameter: 'type': ul/ol (unordered, ordered)
 */
class DNWList extends DaxeNode {
  x.Element _itemref;
  String type;
  
  DNWList.fromRef(x.Element elementRef) : super.fromRef(elementRef) {
    init();
    // this is causing problems with item paste, use DNList.withOneEmptyItem instead
    //if (_itemref != null)
    //  appendChild(new DNItem.fromRef(_itemref));
  }
  
  DNWList.fromNode(x.Node node, DaxeNode parent) : super.fromNode(node, parent) {
    init();
    fixLineBreaks();
    // remove spaces between li
    for (DaxeNode dn in childNodes) {
      if (dn is DNText && dn.nodeValue.trim() == '') {
        removeChild(dn);
      }
    }
  }
  
  void init() {
    _itemref = findItemRef(ref);
    type = doc.cfg.elementParameterValue(ref, 'type', 'ul');
  }
  
  @override
  h.Element html() {
    h.DivElement div = new h.DivElement();
    div.id = "$id";
    div.classes.add('dn');
    if (!valid)
      div.classes.add('invalid');
    h.Element list;
    if (type == 'ul')
      list = new h.UListElement();
    else
      list = new h.OListElement();
    list.classes.add('wlist');
    DaxeNode dn = firstChild;
    while (dn != null) {
      list.append(dn.html());
      dn = dn.nextSibling;
    }
    div.append(list);
    return(div);
  }
  
  @override
  Position firstCursorPositionInside() {
    if (firstChild == null) {
      return(null);
    }
    return(new Position(firstChild, 0));
  }
  
  @override
  Position lastCursorPositionInside() {
    if (lastChild == null) {
      return(null);
    }
    return(new Position(lastChild, lastChild.offsetLength));
  }
  
  @override
  h.Element getHTMLContentsNode() {
    return(getHTMLNode().firstChild);
  }
  
  @override
  bool newlineAfter() {
    return(true);
  }
  
  @override
  bool newlineInside() {
    return(true);
  }
  
  static x.Element findItemRef(x.Element listRef) {
    List<x.Element> subElements = doc.cfg.subElements(listRef);
    if (subElements.length > 0)
      return(subElements[0]);
    return(null);
  }
  
  /**
   * Adds a list on the current line, or changes the type.
   */
  static void addList(x.Element listRef) {
    x.Element itemRef = findItemRef(listRef);
    Position selectionStart = page.getSelectionStart();
    Position selectionEnd = page.getSelectionEnd();
    UndoableEdit edit = new UndoableEdit.compound(doc.cfg.elementTitle(listRef));
    Position newPos;
    
    DNWItem item = new DNWItem.fromRef(itemRef);
    
    // look for first ancestor list
    DaxeNode firstList = selectionStart.dn;
    while (firstList != null && firstList is! DNWList) {
      firstList = firstList.parent;
    }
    if (firstList is DNWList && firstList.ref != listRef) {
      // we are in a list of a different type, its type will be changed
      newPos = new Position.leftOffsetPosition(selectionStart);
      DNWList list = new DNWList.fromRef(listRef);
      for (DaxeNode child = firstList.firstChild; child != null; child=child.nextSibling) {
        list.appendChild(new DaxeNode.clone(child));
      }
      edit.addSubEdit(new UndoableEdit.insertNode(
          new Position(firstList.parent, firstList.parent.offsetOf(firstList)), list));
      edit.addSubEdit(new UndoableEdit.removeNode(firstList));
      doc.doNewEdit(edit);
      page.moveCursorTo(newPos);
      page.updateAfterPathChange();
      return;
    }
    
    // look for first ancestor paragraph
    DaxeNode p = selectionStart.dn;
    while (p != null && p is! DNHiddenP)
      p = p.parent;
    //TODO: something, if selectionStart != selectionEnd
    if (p is DNHiddenP) {
      //NOTE: items inside a hidden paragraph are assumed to be valid under list item
      for (DaxeNode child = p.firstChild; child != null; child=child.nextSibling)
        item.appendChild(new DaxeNode.clone(child));
      if (p.previousSibling is DNWList && p.nextSibling is DNWList) {
        // merge with the 2 lists around
        edit.addSubEdit(new UndoableEdit.insertNode(
            new Position(p.previousSibling, p.previousSibling.offsetLength), item));
        DaxeNode cloneNext = new DaxeNode.clone(p.nextSibling);
        edit.addSubEdit(doc.insertChildrenEdit(cloneNext,
            new Position(p.previousSibling, p.previousSibling.offsetLength + 1)));
        edit.addSubEdit(new UndoableEdit.removeNode(p.nextSibling));
      } else if (p.previousSibling is DNWList) {
        // merge with preceding list
        edit.addSubEdit(new UndoableEdit.insertNode(
            new Position(p.previousSibling, p.previousSibling.offsetLength), item));
      } else if (p.nextSibling is DNWList) {
        // merge with following list
        edit.addSubEdit(new UndoableEdit.insertNode(
            new Position(p.nextSibling, 0), item));
      } else {
        // new list
        DaxeNode list = new DNWList.fromRef(listRef);
        list.appendChild(item);
        edit.addSubEdit(new UndoableEdit.insertNode(
            new Position(p.parent, p.parent.offsetOf(p)), list));
      }
      edit.addSubEdit(new UndoableEdit.removeNode(p));
      newPos = new Position(item, item.offsetLength);
    } else {
      // we are not in a paragraph :(
      // gather all inline nodes around the cursor that can be put into an item
      DaxeNode textParent = selectionStart.dn;
      int offset = selectionStart.dnOffset;
      while (textParent is DNText || textParent is DNStyle) {
        offset = textParent.parent.offsetOf(textParent);
        textParent = textParent.parent;
      }
      
      int startOffset = offset;
      while (startOffset > 0) {
        DaxeNode child = textParent.childAtOffset(startOffset-1);
        if ((child is! DNText && !doc.cfg.isSubElement(itemRef, child.ref)) ||
            child.newlineAfter())
          break;
        startOffset--;
      }
      Position pStart = new Position(textParent, startOffset);
      
      DaxeNode endParent = selectionStart.dn;
      int endOffset = selectionStart.dnOffset;
      while (endParent is DNText || endParent is DNStyle) {
        endOffset = endParent.parent.offsetOf(endParent) + 1;
        endParent = endParent.parent;
      }
      assert(endParent == textParent); // the selection should not cut an element
      while (endOffset < textParent.offsetLength) {
        DaxeNode child = textParent.childAtOffset(endOffset);
        if ((child is! DNText && !doc.cfg.isSubElement(itemRef, child.ref)) ||
            child.newlineAfter())
          break;
        endOffset++;
      }
      Position pEnd = new Position(textParent, endOffset);
      
      DaxeNode clone;
      if (pStart < pEnd) {
        clone = doc.cloneBetween(pStart, pEnd);
        for (DaxeNode child = clone.firstChild; child != null; child = clone.firstChild) {
          clone.removeChild(child);
          item.appendChild(child);
        }
        // remove possible spaces and \n at the beginning and end
        DaxeNode firstChild = item.childAtOffset(0); 
        if (firstChild is DNText) {
          String text = firstChild.nodeValue.trimLeft();
          if (text == '')
            item.removeChild(firstChild);
          else
            firstChild.nodeValue = text;
        }
        DaxeNode lastChild = item.childAtOffset(item.offsetLength-1); 
        if (lastChild is DNText) {
          String text = lastChild.nodeValue.trimRight();
          if (text == '')
            item.removeChild(lastChild);
          else
            lastChild.nodeValue = text;
        }
      }
      
      DaxeNode previousNode;
      if (pStart.dnOffset > 0)
        previousNode = pStart.dn.childAtOffset(pStart.dnOffset - 1);
      else
        previousNode = null;
      DaxeNode nextNode;
      if (pEnd.dnOffset < pEnd.dn.offsetLength)
        nextNode = pEnd.dn.childAtOffset(pEnd.dnOffset);
      else
        nextNode = null;
      if (previousNode is DNWList && nextNode is DNWList) {
        // merge with the 2 lists around
        edit.addSubEdit(new UndoableEdit.insertNode(
            new Position(previousNode, previousNode.offsetLength), item));
        DaxeNode cloneNext = new DaxeNode.clone(nextNode);
        edit.addSubEdit(doc.insertChildrenEdit(cloneNext,
            new Position(previousNode, previousNode.offsetLength + 1)));
        edit.addSubEdit(new UndoableEdit.removeNode(nextNode));
      } else if (previousNode is DNWList) {
        // merge with preceding list
        edit.addSubEdit(new UndoableEdit.insertNode(
            new Position(previousNode, previousNode.offsetLength), item));
      } else if (nextNode is DNWList) {
        // merge with following list
        edit.addSubEdit(new UndoableEdit.insertNode(
            new Position(nextNode, 0), item));
      } else {
        // new list
        DaxeNode list = new DNWList.fromRef(listRef);
        list.appendChild(item);
        edit.addSubEdit(new UndoableEdit.insertNode(pEnd, list));
      }
      if (pStart < pEnd)
        edit.addSubEdit(doc.removeBetweenEdit(pStart, pEnd));
      newPos = new Position(item, item.offsetLength);
    }
    
    doc.doNewEdit(edit);
    page.moveCursorTo(newPos);
    page.updateAfterPathChange();
  }
  
  /**
   * Reduces the list depth of the item at cursor position.
   */
  static void riseLevel() {
    Position start = page.getSelectionStart();
    DaxeNode dn = start.dn;
    while (dn != null && dn is! DNWItem)
      dn = dn.parent;
    if (dn == null)
      return;
    UndoableEdit edit = new UndoableEdit.compound(Strings.get('toolbar.lower_level'));
    DNWItem item = dn;
    DNWList list = item.parent;
    DaxeNode afterList = null;
    if (item.nextSibling != null) {
      afterList = new DNWList.fromRef(list.ref);
      for (dn = item.nextSibling; dn != null; dn = dn.nextSibling) {
        afterList.appendChild(new DaxeNode.clone(dn));
        edit.addSubEdit(new UndoableEdit.removeNode(dn));
      }
    }
    DaxeNode clone = new DaxeNode.clone(item);
    Position newPos;
    if (list.parent is DNWItem) {
      DNWItem parentItem = list.parent;
      DNWList parentList = parentItem.parent;
      if (afterList != null)
        clone.appendChild(afterList);
      edit.addSubEdit(new UndoableEdit.insertNode(
          new Position(parentList, parentList.offsetOf(parentItem) + 1), clone));
      newPos = new Position(clone, clone.offsetLength);
    } else {
      Position after = new Position(list.parent, list.parent.offsetOf(list) + 1);
      if (afterList != null)
        edit.addSubEdit(new UndoableEdit.insertNode(after, afterList));
      if (doc.hiddenParaRefs != null && doc.cfg.findSubElement(list.parent.ref, doc.hiddenParaRefs) != null) {
        x.Element hiddenp = doc.cfg.findSubElement(list.parent.ref, doc.hiddenParaRefs);
        if (clone.firstChild != null) {
          // add paragraphs wherever possible
          DaxeNode current = clone.firstChild;
          DaxeNode next = null;
          DNHiddenP p = null;
          while (current != null) {
            next = current.nextSibling;
            if (current is DNText || doc.cfg.isSubElement(hiddenp, current.ref)) {
              if (p == null)
                p = new DNHiddenP.fromRef(hiddenp);
              clone.removeChild(current);
              p.appendChild(current);
              clone.insertBefore(p, next);
            } else {
              p = null;
            }
            current = next;
          }
          newPos = after;
          edit.addSubEdit(doc.insertChildrenEdit(clone, after));
        } else {
          // add one empty paragraph to replace the list item
          DNHiddenP p = new DNHiddenP.fromRef(hiddenp);
          edit.addSubEdit(new UndoableEdit.insertNode(after, p));
          newPos = new Position(p, 0);
        }
      } else {
        if (clone.firstChild != null) {
          newPos = after;
          edit.addSubEdit(doc.insertChildrenEdit(clone, after));
        } else {
          newPos = after;
        }
      }
    }
    if (item.previousSibling != null)
      edit.addSubEdit(new UndoableEdit.removeNode(item));
    else
      edit.addSubEdit(new UndoableEdit.removeNode(list));
    doc.doNewEdit(edit);
    page.moveCursorTo(newPos);
    page.updateAfterPathChange();
  }
  
  /**
   * Increases the list depth of the item at cursor position.
   */
  static void lowerLevel() {
    Position start = page.getSelectionStart();
    DaxeNode dn = start.dn;
    while (dn != null && dn is! DNWItem)
      dn = dn.parent;
    if (dn == null)
      return;
    DNWItem item = dn;
    DNWItem previousItem = item.previousSibling;
    if (previousItem == null)
      return;
    UndoableEdit edit = new UndoableEdit.compound(Strings.get('toolbar.rise_level'));
    edit.addSubEdit(new UndoableEdit.removeNode(item));
    DaxeNode newItem = new DaxeNode.clone(item);
    if (previousItem.lastChild is DNWList) {
      // merge with previous list
      DNWList previousList = previousItem.lastChild;
      edit.addSubEdit(new UndoableEdit.insertNode(
          new Position(previousList, previousList.offsetLength), newItem));
    } else {
      // create a new list
      DaxeNode newList = new DNWList.fromRef(item.parent.ref);
      newList.appendChild(newItem);
      edit.addSubEdit(new UndoableEdit.insertNode(
          new Position(previousItem, previousItem.offsetLength), newList));
    }
    doc.doNewEdit(edit);
    page.moveCursorTo(new Position(newItem, newItem.offsetLength));
    page.updateAfterPathChange();
  }
  
  /**
   * Called when a newline character is inserted within an item and a new item should be created.
   */
  static void newlineInItem(Position selectionStart) {
    // the newline can be inserted within a style within a hidden paragraph,
    // so the item has to be split with DaxeDocument.cloneCutBetween.
    DNWItem item;
    DaxeNode dn = selectionStart.dn;
    while (dn != null && dn is! DNWItem)
      dn = dn.parent;
    assert(dn != null);
    if (dn == null)
      return;
    item = dn;
    Position beforeItem = new Position(item.parent, item.parent.offsetOf(item));
    Position afterItem = new Position(item.parent, item.parent.offsetOf(item) + 1);
    DaxeNode firstNewItem = doc.cloneCutBetween(item, beforeItem, selectionStart);
    DaxeNode secondNewItem = doc.cloneCutBetween(item, selectionStart, afterItem);
    UndoableEdit edit = new UndoableEdit.compound(Strings.get('undo.insert_text'));
    edit.addSubEdit(new UndoableEdit.insertNode(beforeItem, firstNewItem));
    beforeItem = new Position(item.parent, item.parent.offsetOf(item)+1);
    edit.addSubEdit(new UndoableEdit.insertNode(beforeItem, secondNewItem));
    edit.addSubEdit(new UndoableEdit.removeNode(item));
    doc.doNewEdit(edit);
    page.moveCursorTo(new Position(secondNewItem, 0));
    page.updateAfterPathChange();
  }
  
  static List<x.Element> ulRefs() {
    List<x.Element> list = new List<x.Element>();
    List<x.Element> wlist = doc.cfg.elementsWithType('wlist');
    for (x.Element ref in wlist)
      if (doc.cfg.elementParameterValue(ref, 'type', 'ul') == 'ul')
        list.add(ref);
    return(list);
  }
  
  static List<x.Element> olRefs() {
    List<x.Element> list = new List<x.Element>();
    List<x.Element> wlist = doc.cfg.elementsWithType('wlist');
    for (x.Element ref in wlist)
      if (doc.cfg.elementParameterValue(ref, 'type', 'ul') == 'ol')
        list.add(ref);
    return(list);
  }
  
}
