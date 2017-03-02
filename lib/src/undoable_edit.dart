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
 * An undoable edit in the XML document.
 */
class UndoableEdit {
  static const int INSERT = 0;
  static const int REMOVE = 1;
  static const int ATTRIBUTE = 2;
  static const int ATTRIBUTES = 3;
  static const int COMPOUND = 4;
  
  int operation;
  String title;
  Position pos = null;
  String text = null;
  int length;
  DaxeNode dn = null;
  DaxeNode cutNode = null;
  DaxeAttr attribute = null;
  String oldAttributeValue = null;
  List<DaxeAttr> attributes = null;
  List<UndoableEdit> subEdits = null;
  bool updateDisplay; // update the display the first time doit() is called (default: true)
  
  
  // CONSTRUCTORS
  
  UndoableEdit.insertString(Position pos, String text, {bool updateDisplay: true}) {
    assert(text != null && text != '');
    operation = INSERT;
    title = Strings.get('undo.insert_text');
    this.pos = new Position.clone(pos);
    this.text = text;
    // dn = null, we can't check if a new text node is needed at this point, because of CompoundEdits
    this.updateDisplay = updateDisplay;
  }
  
  UndoableEdit.removeString(Position pos, int length, {bool updateDisplay: true}) {
    assert(length > 0);
    assert(pos.dn.nodeType == DaxeNode.TEXT_NODE);
    operation = REMOVE;
    title = Strings.get('undo.remove_text');
    this.pos = new Position.clone(pos);
    // text = null, we can't extract it at this point, because of CompoundEdits
    this.length = length;
    this.updateDisplay = updateDisplay;
  }
  
  UndoableEdit.insertNode(Position pos, DaxeNode dn, {bool updateDisplay: true}) {
    operation = INSERT;
    title = Strings.get('undo.insert_element');
    this.pos = new Position.clone(pos);
    this.dn = dn;
    this.updateDisplay = updateDisplay;
  }
  
  UndoableEdit.removeNode(DaxeNode dn, {bool updateDisplay: true}) {
    operation = REMOVE;
    title = Strings.get('undo.remove_element');
    this.dn = dn;
    this.updateDisplay = updateDisplay;
  }
  
  UndoableEdit.changeAttribute(DaxeNode dn, DaxeAttr attr, {bool updateDisplay: true}) {
    operation = ATTRIBUTE;
    title = Strings.get('undo.attributes');
    this.dn = dn;
    attribute = attr;
    this.updateDisplay = updateDisplay;
  }
  
  UndoableEdit.changeAttributes(DaxeNode dn, List<DaxeAttr> attributes, {bool updateDisplay: true}) {
    operation = ATTRIBUTES;
    title = Strings.get('undo.attributes');
    this.dn = dn;
    this.attributes = attributes;
    this.updateDisplay = updateDisplay;
  }
  
  UndoableEdit.compound(String title) {
    operation = COMPOUND;
    this.title = title;
    subEdits = new List<UndoableEdit>();
    updateDisplay = true;
  }
  
  
  // METHODS
  
  /**
   * Returns true if the edit has been successfully added to this one
   */
  bool addEdit(UndoableEdit edit) {
    if (operation != edit.operation)
      return(false);
    if (operation == ATTRIBUTE) {
      // single attribute edits: combine when text keeps being added or removed
      if (attribute.name != edit.attribute.name)
        return(false);
      String v1 = oldAttributeValue;
      String v2 = attribute.value;
      String v3 = edit.attribute.value;
      if (v2 == null)
        return(false);
      bool ok = false;
      if (v1 == null || (v2.length > v1.length && v2.substring(0, v1.length) == v1)) {
        if (v3 != null && v3.length > v2.length && v3.substring(0, v2.length) == v2)
          ok = true; // inserting text at the end
      } else if (v1 != null && v1.length > v2.length && v1.substring(0, v2.length) == v2) {
        if (v3 == null || (v2.length > v3.length && v2.substring(0, v3.length) == v3))
          ok = true; // removing text at the end
      }
      if (!ok)
        return(false);
      attribute.value = edit.attribute.value;
      return(true);
    }
    if (operation == INSERT && dn is DNText && edit.text != null &&
        edit.pos.dn == dn && edit.pos.dnOffset + 1 == dn.offsetLength) {
      // insert text node + insert text
      return(true);
    }
    // TODO: handle more text node merges
    // the rest is for text nodes only
    if (text == null || edit.text == null)
      return(false);
    if (dn != edit.dn)
      return(false);
    if ((operation == INSERT && edit.pos.dnOffset == pos.dnOffset + text.length) ||
        (operation == REMOVE && edit.pos.dnOffset == pos.dnOffset)) {
      text = "$text${edit.text}";
      return(true);
    }
    if ((operation == INSERT && edit.pos.dnOffset == pos.dnOffset) ||
        (operation == REMOVE && pos.dnOffset == edit.pos.dnOffset + edit.text.length)) {
      text = "${edit.text}$text";
      if (operation == REMOVE)
        pos = new Position(pos.dn, pos.dnOffset - edit.text.length);
      return(true);
    }
    return(false);
  }
  
  void addSubEdit(UndoableEdit edit) {
    assert(operation == COMPOUND);
    subEdits.add(edit);
  }
  
  void doit() {
    if (operation == INSERT)
      _insert(updateDisplay);
    else if (operation == REMOVE)
      _remove(updateDisplay);
    else if (operation == ATTRIBUTE)
      _changeAttribute(updateDisplay);
    else if (operation == ATTRIBUTES)
      _changeAttributes(updateDisplay);
    else if (operation == COMPOUND) {
      for (UndoableEdit edit in subEdits) {
        edit.doit();
      }
    }
    updateDisplay = true;
  }
  
  void undo() {
    if (operation == INSERT)
      _remove(updateDisplay);
    else if (operation == REMOVE)
      _insert(updateDisplay);
    else if (operation == ATTRIBUTE)
      _undoChangeAttribute(updateDisplay);
    else if (operation == ATTRIBUTES)
      _changeAttributes(updateDisplay);
    else if (operation == COMPOUND) {
      for (UndoableEdit edit in subEdits.reversed) {
        edit.undo();
      }
    }
  }
  
  void _insert(bool update) {
    if (text != null) {
      // for UndoableEdit.insertString :
      pos.moveInsideTextNodeIfPossible();
      if (pos.dn.nodeType != DaxeNode.TEXT_NODE) {
        // a new text node is required (it turns this edit into an insertNode)
        if (pos.dn.needsSpecialDNText)
          dn = pos.dn.specialDNTextConstructor(text);
        else
          dn = new DNText(text);
        text = null;
      }
    }
    if (text != null) {
      assert(pos.dn.nodeType == DaxeNode.TEXT_NODE);
      (pos.dn as DNText).insertString(pos, text);
      if (update) {
        pos.dn.updateHTML();
        page.moveCursorTo(new Position(pos.dn, pos.dnOffset + text.length));
        if (pos.dn.previousSibling == null && pos.dn.nextSibling == null) {
          // the parent might be a simple type
          // NOTE: this might slow down text input
          pos.dn.parent.updateValidity();
        }
      }
    } else {
      DaxeNode parent = pos.dn;
      DaxeNode parentToUpdate;
      List<DaxeNode> childrenUpdate = new List<DaxeNode>();
      childrenUpdate.add(dn);
      if (parent.nodeType == DaxeNode.TEXT_NODE && dn.nodeType == DaxeNode.TEXT_NODE) {
        String s1 = parent.nodeValue.substring(0, pos.dnOffset);
        String s2 = parent.nodeValue.substring(pos.dnOffset);
        parent.nodeValue = "$s1${dn.nodeValue}$s2";
        parentToUpdate = parent;
      } else if (pos.dnOffset == 0) {
        if (parent.nodeType == DaxeNode.TEXT_NODE) {
          parent.parent.insertBefore(dn, parent);
          parentToUpdate = parent.parent;
        } else {
          parent.insertBefore(dn, parent.firstChild);
          parentToUpdate = parent;
        }
      } else if (parent.offsetLength == pos.dnOffset) {
        if (parent.nodeType == DaxeNode.TEXT_NODE) {
          parent.parent.insertBefore(dn, parent.nextSibling);
          parentToUpdate = parent.parent;
        } else {
          parent.appendChild(dn);
          parentToUpdate = parent;
        }
      } else if (parent.nodeType == DaxeNode.TEXT_NODE) {
        if (cutNode == null)
          cutNode = (parent as DNText).cut(pos.dnOffset);
        else {
          parent.nodeValue = parent.nodeValue.substring(0, pos.dnOffset);
          parent.parent.insertAfter(cutNode, parent);
        }
        parent.parent.insertBefore(dn, cutNode);
        childrenUpdate.add(parent);
        childrenUpdate.add(cutNode);
        parentToUpdate = parent.parent;
      } else {
        DaxeNode next = parent.childAtOffset(pos.dnOffset);
        parent.insertBefore(dn, next);
        parentToUpdate = parent;
      }
      if (dn.namespaceURI != null) {
        // fix prefixes if necessary
        _fixPrefixes(dn, parent);
      }
      if (update) {
        if (dn.nodeType == DaxeNode.ELEMENT_NODE)
          dn.updateValidity();
        parentToUpdate.updateValidity();
        parentToUpdate.updateHTMLAfterChildrenChange(childrenUpdate);
        if (dn is DNText)
          page.moveCursorTo(new Position(dn, dn.nodeValue.length));
        else
          page.moveCursorTo(new Position(dn.parent, dn.parent.offsetOf(dn) + 1));
      }
      dn.callAfterInsert();
    }
  }
  
  /**
   * Fix the prefixes of the given node and descendants,
   * based on the reference.
   */
  void _fixPrefixes(DaxeNode dn, DaxeNode parent) {
    dn.prefix = doc.cfg.elementPrefix(dn.namespaceURI, dn, parent);
    if (dn.ref != null) {
      for (DaxeAttr attr in dn.attributes) {
        if (attr.namespaceURI == 'http://www.w3.org/XML/1998/namespace')
          attr.prefix = 'xml';
        else if (attr.namespaceURI == 'http://www.w3.org/2000/xmlns/' &&
            attr.localName != 'xmlns')
          attr.prefix = 'xmlns';
        else {
          x.Element attref = doc.cfg.attributeReference(dn.ref, attr.localName, attr.namespaceURI);
          attr.prefix = doc.cfg.attributePrefix(dn, attref);
        }
      }
    }
    for (DaxeNode child in dn.childNodes) {
      if (child.nodeType == DaxeNode.ELEMENT_NODE)
        _fixPrefixes(child, dn);
    }
  }
  
  void _remove(bool update) {
    if (dn == null && text == null) {
      // for UndoableEdit.removeString :
      if (pos.dnOffset == 0 && pos.dn.offsetLength == length) {
        // remove the whole text node
        dn = pos.dn;
        pos = new Position(dn.parent, dn.parent.offsetOf(dn));
      } else {
        text = pos.dn.nodeValue.substring(pos.dnOffset, pos.dnOffset + length);
      }
    }
    if (text != null) {
      assert(pos.dn.nodeType == DaxeNode.TEXT_NODE);
      pos.dn.remove(pos, text.length);
      if (update) {
        pos.dn.updateHTML();
        page.moveCursorTo(pos);
        if (pos.dn.previousSibling == null && pos.dn.nextSibling == null) {
          // the parent might be a simple type
          // NOTE: this might slow down text input
          pos.dn.parent.updateValidity();
        }
      }
    } else {
      dn.callBeforeRemove();
      DaxeNode parent = dn.parent;
      assert(parent != null);
      if (pos == null) {
        if (dn.previousSibling != null && dn.previousSibling.nodeType == DaxeNode.TEXT_NODE)
          pos = new Position(dn.previousSibling, dn.previousSibling.offsetLength);
        else
          pos = new Position(parent, parent.offsetOf(dn));
      }
      DaxeNode prev = dn.previousSibling;
      DaxeNode next = dn.nextSibling;
      parent.removeChild(dn);
      List<DaxeNode> childrenUpdate = new List<DaxeNode>();
      // we have to save the merged text node when the element is normalized
      if (prev != null && prev.nodeType == DaxeNode.TEXT_NODE && next != null &&
          next.nodeType == DaxeNode.TEXT_NODE) {
        cutNode = next;
        prev.nodeValue = "${prev.nodeValue}${next.nodeValue}";
        next.parent.removeChild(next);
        childrenUpdate.add(prev);
        childrenUpdate.add(dn);
        childrenUpdate.add(next);
      } else
        childrenUpdate.add(dn);
      if (update) {
        parent.updateValidity();
        parent.updateHTMLAfterChildrenChange(childrenUpdate);
        page.moveCursorTo(pos);
      }
    }
  }
  
  void _changeAttribute(bool update) {
    oldAttributeValue = dn.getAttribute(attribute.name);
    if (attribute.value == null)
      dn.removeAttribute(attribute.name);
    else
      dn.setAttribute(attribute.name, attribute.value);
    if (update) {
      dn.updateValidity();
      dn.updateAttributes();
    }
  }
  
  void _undoChangeAttribute(bool update) {
    if (oldAttributeValue == null)
      dn.removeAttribute(attribute.name);
    else
      dn.setAttribute(attribute.name, oldAttributeValue);
    if (update) {
      dn.updateValidity();
      dn.updateAttributes();
    }
  }
  
  void _changeAttributes(bool update) {
    List<DaxeAttr> oldAttributes = dn.attributes;
    dn.attributes = attributes;
    attributes = oldAttributes;
    if (update) {
      dn.updateValidity();
      dn.updateAttributes();
    }
  }
  
  String toString() {
    StringBuffer sb = new StringBuffer();
    switch(operation) {
      case INSERT: sb.write("Insert "); break;
      case REMOVE: sb.write("Remove "); break;
      case ATTRIBUTE: sb.write("Attribute "); break;
      case ATTRIBUTES: sb.write("Attributes "); break;
      case COMPOUND: sb.write("Compound "); break;
    }
    if (text != null)
      sb.write("text '$text'");
    else if (dn != null)
      sb.write("node ${dn.nodeName}");
    else if (pos != null)
      sb.write("$length chars at $pos");
    return(sb.toString());
  }
}
