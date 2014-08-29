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
 * This class represents a GUI for an XML node. The subclasses offer differents GUIs.
 */
abstract class DaxeNode {
  static const int ELEMENT_NODE = 1;
  static const int TEXT_NODE = 3;
  //NOTE: cdata, pi and comments are now DaxeNode elements containing a text node
  //static const int CDATA_SECTION_NODE = 4;
  //static const int PROCESSING_INSTRUCTION_NODE = 7;
  //static const int COMMENT_NODE = 8;
  static const int DOCUMENT_NODE = 9;
  
  static const String STYLE_BOLD = 'GRAS';
  static const String STYLE_ITALIC = 'ITALIQUE';
  static const String STYLE_SUPERSCRIPT = 'EXPOSANT';
  static const String STYLE_SUBSCRIPT = 'INDICE';
  static const String STYLE_UNDERLINE = 'SOULIGNE';
  static const String STYLE_STRIKETHROUGH = 'BARRE';
  static const String STYLE_BACKGROUND_COLOR = 'FCOULEUR';
  static const String STYLE_FOREGROUND_COLOR = 'PCOULEUR';
  static const String COLOR_PATTERN = "^.*\\[(x[0-9a-fA-F]{2}|[0-9]{1,3}),(x[0-9a-fA-F]{2}|[0-9]{1,3}),(x[0-9a-fA-F]{2}|[0-9]{1,3})\\]\$";

  x.Element ref; // schema element
  String _id;
  DaxeNode parent;
  int nodeType;
  String _namespaceURI;
  String prefix;
  String localName;
  String nodeValue;
  DaxeNode firstChild;
  DaxeNode nextSibling;
  List<DaxeAttr> attributes;
  bool userCannotRemove = false; // with suppr/del, could be extended to selections...
  bool valid;
  
  
  /**
   * Constructor using a DOM [node] and a DaxeNode [parent].
   * Will create children nodes recursively unless [createChildren] is false.
   */
  DaxeNode.fromNode(x.Node node, DaxeNode parent, {bool createChildren: true}) {
    _id = doc.newId(this);
    this.parent = parent;
    if (node.nodeType == x.Node.ELEMENT_NODE || node.nodeType == x.Node.TEXT_NODE ||
        node.nodeType == x.Node.DOCUMENT_NODE)
      nodeType = node.nodeType;
    else
      nodeType = ELEMENT_NODE;
    _namespaceURI = node.namespaceURI;
    prefix = node.prefix;
    if (node.nodeType == x.Node.PROCESSING_INSTRUCTION_NODE)
      localName = node.nodeName;
    else if (node.nodeType == x.Node.CDATA_SECTION_NODE)
      localName = '#cdata-section';
    else if (node.nodeType == x.Node.COMMENT_NODE)
      localName = '#comment';
    else if (node.nodeType == x.Node.DOCUMENT_NODE)
      localName = '#document';
    else
      localName = node.localName;
    if (nodeType == DaxeNode.TEXT_NODE)
      nodeValue = node.nodeValue;
    attributes = new List<DaxeAttr>();
    LinkedHashMap<String, x.Attr> nm = node.attributes;
    if (nm != null) {
      for (x.Node n in nm.values) {
        attributes.add(new DaxeAttr.fromNode(n));
      }
    }
    if (node is x.Element) {
      ref = doc.cfg.getElementRef(node, parent == null ? null : parent.ref);
      if (ref == null && parent != null) {
        // could not find a reference when taking the parent into account
        // there is probably an error in the document, but we will try to use
        // another reference by ignoring the parent
        ref = doc.cfg.elementReference(localName);
      }
    }
    
    if (createChildren) {
      if (node.childNodes != null) {
        DaxeNode prev = null;
        for (x.Node n in node.childNodes) {
          DaxeNode dn = NodeFactory.createFromNode(n, this);
          if (prev == null)
            firstChild = dn;
          else
            prev.nextSibling = dn;
          prev = dn;
        }
      } else if ((node.nodeType == x.Node.CDATA_SECTION_NODE ||
          node.nodeType == x.Node.PROCESSING_INSTRUCTION_NODE ||
          node.nodeType == x.Node.COMMENT_NODE) &&
          node.nodeValue != null && node.nodeValue != '') {
        appendChild(new DNText(node.nodeValue));
      }
    }
    if (nodeType == DaxeNode.ELEMENT_NODE)
      valid = doc.cfg.elementIsValid(this);
    else
      valid = true;
  }
  
  /**
   * Constructor using an element reference.
   * This will always create an element node.
   */
  DaxeNode.fromRef(x.Element elementRef) {
    ref = elementRef;
    _id = doc.newId(this);
    parent = null;
    nodeType = ELEMENT_NODE;
    _namespaceURI = doc.cfg.elementNamespace(ref);
    prefix = doc.cfg.elementPrefix(ref);
    localName = doc.cfg.elementName(ref);
    nodeValue = null;
    firstChild = null;
    nextSibling = null;
    attributes = new List<DaxeAttr>();
    valid = true;
  }
  
  /**
   * Constructor using a node type.
   * Useful to create new document, cdata, pi or comment nodes (they don't have a ref).
   * Possible node types are available as constants of this class.
   */
  DaxeNode.fromNodeType(int nodeType) {
    ref = null;
    _id = doc.newId(this);
    parent = null;
    this.nodeType = nodeType;
    _namespaceURI = null;
    prefix = null;
    localName = null;
    nodeValue = null;
    firstChild = null;
    nextSibling = null;
    attributes = new List<DaxeAttr>();
    valid = true;
  }
  
  /**
   * Constructor for a text node with the given [value].
   */
  DaxeNode.text(String value) {
    _id = doc.newId(this);
    parent = null;
    nodeType = DaxeNode.TEXT_NODE;
    _namespaceURI = null;
    this.prefix = null;
    this.localName = null;
    nodeValue = value;
    firstChild = null;
    nextSibling = null;
    attributes = null;
    valid = true;
  }
  
  /**
   * Deep clone constructor, using the DOM serialization.
   */
  factory DaxeNode.clone(DaxeNode dn) {
    x.DOMImplementation domimpl = new x.DOMImplementationImpl();
    x.Document domdoc = domimpl.createDocument(null, null, null);
    x.Node n = dn.toDOMNode(domdoc);
    DaxeNode clone = NodeFactory.createFromNode(n, dn.parent);
    clone.parent = null;
    return(clone);
  }
  
  
  /**
   * Id for the corresponding HTML element.
   */
  String get id {
    return(_id);
  }
  
  /**
   * Returns the corresponding HTML element.
   */
  h.Element getHTMLNode() {
    return(h.document.getElementById(_id));
  }
  
  /**
   * Returns the HTML element in which the contents of the XML element will be displayed.
   * This is used in Position to find where to display the cursor when there is no child.
   */
  h.Element getHTMLContentsNode() {
    h.Element hn = getHTMLNode();
    if (hn != null && !hn.nodes.isEmpty && hn.firstChild is h.Element)
      hn = hn.firstChild;
    return(hn);
  }
  
  String get nodeName {
    if (nodeType == TEXT_NODE)
      return('#text');
    StringBuffer buff = new StringBuffer();
    if (prefix != null) {
      buff.write(prefix);
      buff.write(":");
    }
    buff.write(localName);
    return(buff.toString());
  }
  
  String get namespaceURI {
    return(_namespaceURI);
  }
  
  /**
   * For a text node, the number of characters in the node value.
   * Otherwise, the number of children.
   */
  int get offsetLength {
    if (nodeType == TEXT_NODE)
      return(nodeValue.length);
    int n = 0;
    for (DaxeNode dn=firstChild; dn != null; dn=dn.nextSibling)
      n++;
    return(n);
  }
  
  /**
   * Returns true if this node does not have delimiters such as tags or a box.
   * This affects cursor behavior (for instance, a backspace after a tag removes the node,
   * and 2 blocks with the same ref can be merged when a backspace is used
   * at the beginning of the second block)
   */
  bool get noDelimiter {
    return(false);
  }
  
  /**
   * Returns true if this node is displayed like a block
   * (such as area, division or hiddenp, with line breaks).
   */
  bool get block {
    // this is only a guess, it should be subclassed to be safe
    if (newlineAfter())
      return(true);
    return(getHTMLNode() is h.DivElement);
  }
  
  /**
   * The child nodes in a convenient list.
   */
  List<DaxeNode> get childNodes {
    List<DaxeNode> list = new List<DaxeNode>();
    for (DaxeNode dn=firstChild; dn != null; dn=dn.nextSibling) {
      list.add(dn);
    }
    return(list);
  }
  
  /**
   * This node's previous sibling.
   */
  DaxeNode get previousSibling {
    if (parent == null)
      return(null);
    for (DaxeNode dn = parent.firstChild; dn != null; dn = dn.nextSibling) {
      if (dn.nextSibling == this)
        return(dn);
    }
    return(null);
  }
  
  DaxeNode get lastChild {
    for (DaxeNode dn = firstChild; dn != null; dn = dn.nextSibling) {
      if (dn.nextSibling == null)
        return(dn);
    }
    return(null);
  }
  
  DaxeNode childAtOffset(int offset) {
    assert(nodeType != TEXT_NODE);
    int n = 0;
    for (DaxeNode dn=firstChild; dn != null; dn=dn.nextSibling) {
      if (n == offset)
        return(dn);
      n++;
    }
    return(null);
  }
  
  /**
   * Returns the next node in the document (excluding attribute nodes).
   */
  DaxeNode nextNode() {
    if (firstChild != null)
      return(firstChild);
    if (nextSibling != null)
      return(nextSibling);
    DaxeNode p = parent;
    while (p != null) {
      if (p.nextSibling != null)
        return(p.nextSibling);
      p = p.parent;
    }
    return(null);
  }
  
  /**
   * Returns the previous node in the document (excluding attribute nodes).
   */
  DaxeNode previousNode() {
    if (firstChild != null)
      return(lastChild);
    if (previousSibling != null)
      return(previousSibling);
    DaxeNode p = parent;
    while (p != null) {
      if (p.previousSibling != null)
        return(p.previousSibling);
      p = p.parent;
    }
    return(null);
  }
  
  /**
   * Returns the index of the given child node.
   */
  int offsetOf(DaxeNode child) {
    int i = 0;
    for (DaxeNode n=firstChild; n != null; n=n.nextSibling) {
      if (n == child)
        return(i);
      i++;
    }
    assert(false);
    return(-1);
  }
  
  String getAttribute(String name) {
    for (DaxeAttr att in attributes) {
      if (att.localName == name)
        return(att.value);
    }
    return(null);
  }
  
  String getAttributeNS(String namespaceURI, String localName) {
    if (attributes == null)
      return(null);
    for (DaxeAttr att in attributes) {
      if (att.namespaceURI == namespaceURI && att.localName == localName)
        return(att.value);
    }
    return(null);
  }
  
  void setAttribute(String name, String value) {
    for (DaxeAttr att in attributes) {
      if (att.localName == name) {
        att.value = value;
        return;
      }
    }
    attributes.add(new DaxeAttr(name, value));
    return;
  }
  
  void setAttributeNS(String namespaceURI, String qualifiedName, String value) {
    String attPrefix, attLocalName;
    int ind = qualifiedName.indexOf(":");
    if (ind != -1) {
      attPrefix = qualifiedName.substring(0, ind);
      attLocalName = qualifiedName.substring(ind+1);
    } else {
      attPrefix = null;
      attLocalName = qualifiedName;
    }
    DaxeAttr att = getAttributeNodeNS(namespaceURI, attLocalName);
    if (att != null) {
      att.prefix = attPrefix;
      att.value = value;
      return;
    }
    att = new DaxeAttr.NS(namespaceURI, qualifiedName, value);
    attributes.add(att);
  }
  
  DaxeAttr getAttributeNode(String name) {
    for (DaxeAttr att in attributes) {
      if (att.localName == name)
        return(att);
    }
    return(null);
  }
  
  DaxeAttr getAttributeNodeNS(String namespaceURI, String localName) {
    if (attributes == null)
      return(null);
    for (DaxeAttr att in attributes) {
      if (att.namespaceURI == namespaceURI && att.localName == localName) {
        return(att);
      }
    }
    return(null);
  }
  
  LinkedHashMap<String, DaxeAttr> getAttributesMapCopy() {
    LinkedHashMap<String, DaxeAttr> map = new LinkedHashMap<String, DaxeAttr>();
    for (DaxeAttr attr in attributes)
      map[attr.name] = new DaxeAttr.clone(attr);
    return(map);
  }
  
  /**
   * Creates and returns the HTML element for this DaxeNode.
   * This abstract method must be overriden by subclasses.
   */
  h.Element html();
  
  /**
   * Update the display. By default, this recreates all the HTML.
   */
  void updateHTML() {
    h.Element vel = getHTMLNode();
    if (vel == null)
      return;
    h.Element nel = html();
    vel.replaceWith(nel);
  }
  
  /**
   * Update the display after children changed (insert/removal/other).
   * This method can be overriden for optimization.
   */
  void updateHTMLAfterChildrenChange(List<DaxeNode> changed) {
    List<DaxeNode> children = childNodes;
    for (DaxeNode child in changed) {
      h.Element hn = child.getHTMLNode();
      if (!children.contains(child)) {
        // removal
        if (hn != null)
          hn.remove();
        else {
          // no reference to the HTML node, only the derived class
          // could know how to remove the child display
          updateHTML();
          return;
        }
      } else if (hn == null) {
        // insert
        DaxeNode next = child.nextSibling;
        h.Node nextHn = null;
        while (nextHn == null && next != null) {
          nextHn = next.getHTMLNode();
          if (nextHn == null)
            next = next.nextSibling;
        }
        DaxeNode prev = child.previousSibling;
        h.Node prevHn = null;
        while (prevHn == null && prev != null) {
          prevHn = prev.getHTMLNode();
          if (prevHn == null)
            prev = prev.previousSibling;
        }
        if (nextHn != null) {
          nextHn.parent.insertBefore(child.html(), nextHn);
        } else if (prevHn != null) {
          // there might be some nodes at the end of the parent that we want
          // to keep at the end (for instance the space at the end of a cell)
          if (prevHn.nextNode != null)
            prevHn.parent.insertBefore(child.html(), prevHn.nextNode);
          else
            prevHn.parent.append(child.html());
        } else {
          // no sibling, there might not even be a content div...
          //TODO getHTMLContentsNode
          updateHTML();
          return;
        }
      } else {
        // change
        child.updateHTML();
      }
    }
  }
  
  /**
   * The attributes have changed, an update might be needed.
   * This method can be overriden for optimization.
   */
  void updateAttributes() {
    updateHTML();
  }
  
  /**
   * Sets whether this node is selected by the user or not.
   */
  void setSelected(bool select) {
    h.Element hn = getHTMLNode();
    if (hn == null)
      return;
    if (select)
      hn.classes.add('selected');
    else
      hn.classes.remove('selected');
  }
  
  void appendChild(DaxeNode dn) {
    DaxeNode last = lastChild;
    if (last != null)
      last.nextSibling = dn;
    else
      firstChild = dn;
    dn.parent = this;
  }
  
  /**
   * Inserts [newdn] as a child of this node before [beforedn].
   * beforedn may be null, in which case it is inserted as the last child.
   */
  void insertBefore(DaxeNode newdn, DaxeNode beforedn) {
    assert(beforedn == null || this == beforedn.parent);
    newdn.parent = this;
    DaxeNode dn = firstChild;
    if (dn == beforedn) {
      DaxeNode save = firstChild;
      firstChild = newdn;
      newdn.nextSibling = save;
    } else {
      while (dn != null && dn.nextSibling != beforedn) {
        dn = dn.nextSibling;
      }
      assert(dn != null);
      assert(dn.nextSibling == beforedn);
      DaxeNode save = dn.nextSibling;
      dn.nextSibling = newdn;
      newdn.nextSibling = save;
    }
  }
  
  void insertAfter(DaxeNode newdn, DaxeNode afterdn) {
    assert(this == afterdn.parent);
    if (afterdn.nextSibling == null)
      appendChild(newdn);
    else
      insertBefore(newdn, afterdn.nextSibling);
  }
  
  void removeChild(DaxeNode dn) {
    if (dn.previousSibling != null)
      dn.previousSibling.nextSibling = dn.nextSibling;
    if (dn == firstChild)
      firstChild = dn.nextSibling;
    dn.parent = null;
    dn.nextSibling = null;
  }
  
  /**
   * Replaces this node by the given node (in the tree).
   */
  void replaceWith(DaxeNode dn) {
    if (parent.firstChild == this)
      parent.firstChild = dn;
    else
      previousSibling.nextSibling = dn;
    dn.parent = parent;
    dn.nextSibling = nextSibling;
    parent = null;
    nextSibling = null;
  }
  
  /**
   * Merges adjacent child text nodes.
   */
  void normalize() {
    for (DaxeNode dn=firstChild; dn != null; dn=dn.nextSibling) {
      while (dn.nodeType == TEXT_NODE && dn.nextSibling != null &&
          dn.nextSibling.nodeType == TEXT_NODE) {
        dn.nodeValue = "${dn.nodeValue}${dn.nextSibling.nodeValue}";
        removeChild(dn.nextSibling);
      }
    }
  }
  
  void remove(Position pos, int length) {
    if (nodeType == ELEMENT_NODE) {
      for (int i=pos.dnOffset; i<length; i++) {
        removeChild(childAtOffset(pos.dnOffset));
      }
    } else {
      String v = nodeValue;
      String s1 = v.substring(0, pos.dnOffset);
      String s2 = v.substring(pos.dnOffset + length);
      nodeValue = "$s1$s2";
    }
  }
  
  /**
   * Add a newline after this element when serializing.
   * If it returns true, fixLineBreaks() is usually called in the fromNode constructor.
   */
  bool newlineAfter() {
    return(false);
  }
  
  /**
   * Add a newline after the start tag and if necessary a newline before the end tag
   * in this element when serializing.
   * If it returns true, fixLineBreaks() is usually called in the fromNode constructor.
   */
  bool newlineInside() {
    return(false);
  }
  
  /**
   * Remove newlines that will be added at serialization.
   */
  void fixLineBreaks() {
    if (newlineInside() && firstChild != null && firstChild is DNText) {
      String s = firstChild.nodeValue;
      if (s.startsWith('\n')) {
        if (s.length == 1)
          removeChild(firstChild);
        else
          firstChild.nodeValue = s.substring(1);
      }
    }
    DaxeNode lastNotText = lastChild;
    while (lastNotText != null && lastNotText is DNText)
      lastNotText = lastNotText.previousSibling;
    if (newlineInside() && lastChild is DNText && (lastNotText == null || !lastNotText.newlineAfter())) {
      String s = lastChild.nodeValue;
      if (s.endsWith('\n')) {
        if (s.length == 1)
          removeChild(lastChild);
        else
          lastChild.nodeValue = s.substring(0, s.length - 1);
      }
    }
    for (DaxeNode dn=firstChild; dn != null; dn=dn.nextSibling) {
      if (dn.newlineAfter() && dn.nextSibling is DNText) {
        String s = dn.nextSibling.nodeValue;
        if (s.startsWith('\n')) {
          if (s.length == 1)
            removeChild(dn.nextSibling);
          else
            dn.nextSibling.nodeValue = s.substring(1);
        }
      }
    }
  }
  
  /**
   * DOM serialization. Can be overriden in DaxeNode subclasses.
   */
  x.Node toDOMNode(x.Document domDocument) {
    assert(nodeType == ELEMENT_NODE); // the other types are handled in subclasses DNDocument and DNText
    x.Element el = domDocument.createElementNS(namespaceURI, nodeName);
    for (DaxeAttr att in attributes)
      el.setAttributeNS(att.namespaceURI, att.name, att.value);
    if (newlineInside() || firstChild != null) {
      if (newlineInside())
        el.appendChild(domDocument.createTextNode('\n'));
      for (DaxeNode dn=firstChild; dn != null; dn=dn.nextSibling) {
        el.appendChild(dn.toDOMNode(domDocument));
        if (dn.newlineAfter())
          el.appendChild(domDocument.createTextNode('\n'));
      }
      DaxeNode lastNotText = lastChild;
      while (lastNotText != null && lastNotText is DNText)
        lastNotText = lastNotText.previousSibling;
      if (newlineInside() && lastChild != null && (lastNotText == null || !lastNotText.newlineAfter()))
        el.appendChild(domDocument.createTextNode('\n'));
    }
    return(el);
  }
  
  /**
   * XML serialization. Based on DOM serialization (see [toDOMNode]);
   */
  String toString() {
    x.DOMImplementation domimpl = new x.DOMImplementationImpl();
    x.Document domdoc = domimpl.createDocument(null, null, null);
    x.Node n = toDOMNode(domdoc);
    return(n.toString());
  }
  
  /// escapes XML character entities for serialization
  static String escape(String s) {
    s = s.replaceAll('&', '&amp;');
    s = s.replaceAll('"', '&quot;');
    //s = s.replaceAll("'", '&apos;');
    s = s.replaceAll('<', '&lt;');
    s = s.replaceAll('>', '&gt;');
    return(s);
  }
  
  void updateValidity() {
    valid = doc.cfg.elementIsValid(this);
    h.Element hel = getHTMLNode();
    if (hel == null)
      return;
    if (valid && hel.classes.contains('invalid'))
      hel.classes.remove('invalid');
    else if (!valid && !hel.classes.contains('invalid'))
      hel.classes.add('invalid');
  }
  
  /**
   * This method is called when the user creates a new node, before it is inserted.
   * By default, it displays the attribute dialog when there are attributes.
   */
  void newNodeCreationUI(ActionFunction okfct) {
    if (ref != null && doc.cfg.elementAttributes(ref).length > 0)
      attributeDialog(() => okfct());
    else
      okfct();
  }
  
  void attributeDialog([ActionFunction okfct]) {
    if (ref != null) {
      AttributeDialog dlg = new AttributeDialog(this, okfct);
      dlg.show();
    } else {
      UnknownElementDialog dlg = new UnknownElementDialog(this, okfct);
      dlg.show();
    }
  }
  
  Position findPosition(num x, num y) {
    // we assume the click was in this element
    
    /*
     I wish I could use Range, like this:
     if (document.caretRangeFromPoint) {
       range = document.caretRangeFromPoint(e.pageX, e.pageY);
     } else if (e.rangeParent) {
       range = document.createRange();
       range.setStart(e.rangeParent, e.rangeOffset);
     }
     but caretRangeFromPoint does not work in Firefox, and rangeParent/rangeOffset
     do not exist in Dart...
     cf http://stackoverflow.com/q/3189812/438970
     and http://code.google.com/p/dart/issues/detail?id=9227
     and http://code.google.com/p/dart/issues/detail?id=11723
     */
    Position pos = new Position(this, 0);
    
    if (nodeType == ELEMENT_NODE || nodeType == DOCUMENT_NODE) {
      for (DaxeNode dn=firstChild; dn != null; dn=dn.nextSibling) {
        // hnx1, hny1, lineHeight: first char in HTML element
        // hnx2, hny2, lineHeight: last char
        h.Element hn = dn.getHTMLNode();
        if (hn == null)
          continue;
        double hnx1, hny1, hnx2, hny2;
        double topLineHeight, bottomLineHeight;
        // NOTE: the main problem here is to avoid adding spans to find the position
        if (hn is h.DivElement && hn.nodes.length > 0 &&
            hn.firstChild is h.SpanElement && (hn.firstChild as h.SpanElement).classes.contains('start_tag') &&
            hn.lastChild is h.SpanElement&& (hn.lastChild as h.SpanElement).classes.contains('end_tag')) {
          // the spans are tags
          h.Element span_test = hn.firstChild;
          h.Rectangle box = span_test.getBoundingClientRect();
          hnx1 = box.left;
          hny1 = box.top;
          topLineHeight = span_test.offset.height.toDouble();
          span_test = hn.lastChild;
          box = span_test.getBoundingClientRect();
          hnx2 = box.right;
          hny2 = box.bottom;
          bottomLineHeight = span_test.offset.height.toDouble();
        } else if (hn is h.DivElement || hn is h.TableCellElement || hn is h.TableRowElement ||
            hn is h.TableElement || hn is h.ImageElement || hn.classes.contains('form')) {
          // block
          // for DivElement: no span to tag the div: we take the entire div into account
          h.Rectangle box = hn.getBoundingClientRect();
          // FIXME: box is not good for a tr containing a td using rowspan
          hnx1 = box.left;
          hny1 = box.top;
          if (hn.classes.contains('form')) // FIXME: this is a hack !
            hnx2 = hn.querySelector('table').getBoundingClientRect().right;
          else
            hnx2 = box.right;
          hny2 = box.bottom;
          topLineHeight = bottomLineHeight = box.height;
        } else if (hn is h.SpanElement && hn.nodes.length == 1 && hn.firstChild is h.Text &&
            !hn.firstChild.nodeValue.endsWith('\n')) {
          // text node that does not end with \n
          List<h.Rectangle> rects = hn.getClientRects();
          if (rects.length == 0)
            return(null);
          h.Rectangle box = rects.first;
          hnx1 = box.left;
          hny1 = box.top;
          topLineHeight = box.height * 1.4;
          box = rects.last;
          hnx2 = box.right;
          hny2 = box.bottom;
          bottomLineHeight = box.height * 1.4;
        } else if (hn.firstChild is h.Element && hn.lastChild is h.SpanElement &&
            hn.lastChild.lastChild is h.Text &&
            !hn.lastChild.lastChild.nodeValue.endsWith('\n')) {
          // span with a text node at the end which does not end with \n
          // note: possibles selections on the text make the tests a bit complex...
          h.Element span_test = hn.firstChild;
          List<h.Rectangle> rects = span_test.getClientRects();
          if (rects.length == 0)
            return(null);
          h.Rectangle box = rects.first;
          hnx1 = box.left;
          hny1 = box.top;
          topLineHeight = box.height * 1.3;
          span_test = hn.lastChild;
          rects = span_test.getClientRects();
          if (rects.length == 0)
            return(null);
          box = rects.last;
          hnx2 = box.right;
          hny2 = box.bottom;
          bottomLineHeight = box.height * 1.3;
        } else {
          // NOTE: for a span, getBoundingClientRect and getClientRects return a wrong bottom when
          // there are \n inside (except maybe with IE), so we can't even use them on hn to avoid
          // appending spans (and bec. it depends on browsers we can't just add a \n).
          // Using an empty span does not work.
          // FIXME: adding a span with text can change a table layout with Firefox,
          // causing wrong results and side effects
          // -> TODO: test WORD JOINER ("\u2060") instead of "|"
          h.Element span_test = new h.Element.tag('span');
          span_test.append(new h.Text("|"));
          if (hn.nodes.length == 1 && hn.firstChild is h.BRElement) {
            hn.append(span_test);
            h.Rectangle box = span_test.getBoundingClientRect();
            hnx1 = -1.0;
            hny1 = box.top;
            topLineHeight = bottomLineHeight = span_test.offset.height.toDouble() * 1.4;
            hnx2 = -1.0;
            hny2 = box.bottom;
            span_test.remove();
          } else {
            if (hn.nodes.isEmpty)
              hn.append(span_test);
            else
              hn.insertBefore(span_test, hn.firstChild);
            h.Rectangle box = span_test.getBoundingClientRect();
            hnx1 = box.left;
            hny1 = box.top;
            // note: maybe we should use CSS line-height here, but it is hard to get the value
            topLineHeight = span_test.offset.height.toDouble() * 1.4;
            span_test.remove();
            if (hn is h.LIElement) {
              h.Node lastDescendant = hn;
              while (lastDescendant.firstChild != null && lastDescendant.lastChild is! h.Text &&
                  lastDescendant.lastChild is! h.ImageElement)
                lastDescendant = lastDescendant.lastChild;
              lastDescendant.append(span_test);
            } else
              hn.append(span_test);
            box = span_test.getBoundingClientRect();
            hnx2 = box.left;
            hny2 = box.bottom;
            bottomLineHeight = span_test.offset.height.toDouble() * 1.4;
            span_test.remove();
          }
        }
        if ((y < hny1 + topLineHeight && (y < hny1 - 1 || (x < hnx1 + 1 && hn is! h.LIElement &&
            dn is! DNHiddenP)))) {
          // position is before this child
          return(pos);
        }
        if (y > hny2 - bottomLineHeight && (y > hny2 + 1 || (x > hnx2 - 1 && hn is! h.LIElement))) {
          // position is after this child
          pos = new Position(this, offsetOf(dn) + 1);
        } else {
          // position is within this child
          pos = dn.findPosition(x, y);
          return(pos);
        }
      }
    } else if (nodeType == TEXT_NODE) {
      /* doesn't work with other browsers than Chrome...
      h.Range range = h.document.$dom_caretRangeFromPoint(x, y);
      h.Element hn = getHTMLNode();
      if (range.startContainer == hn || range.startContainer == hn.$dom_firstChild)
        return(new Position(this, range.startOffset));
      */
      int pp = 0; // position in the XML node
      for (h.Node hn in getHTMLNode().nodes) {
        h.Text ht;
        if (hn is h.Text)
          ht = hn;
        else if (hn is h.Element) // selection span
          ht = hn.firstChild;
        else
          continue;
        h.Range range = new h.Range();
        for (int i=0; i<ht.length; i++) {
          // problem: depending on the browser, the clientrects are not the same
          // for \n or for line-breaking space characters...
          if (nodeValue[pp + i] != '\n') {
            range.setStart(ht, i);
            range.setEnd(ht, i+1);
            List<h.Rectangle> rects = range.getClientRects();
            for (h.Rectangle r in rects) {
              if (i < nodeValue.length - 1 && r.left == r.right &&
                  x < r.left && y < r.bottom) {
                //print("left of line start after newline");
                return(new Position(this, pp + i+1));
              } if (x < r.right && y <= r.bottom) {
                if (x < (r.left + r.right) / 2)
                  return(new Position(this, pp + i));
                else
                  return(new Position(this, pp + i+1));
              } else if (y < r.top - 5) {
                //print("line above");
                // the point is on the line above
                if (pp+i == 0 || nodeValue[pp+i] == ' ')
                  return(new Position(this, pp + i));
                else
                  return(new Position(this, pp + i - 1));
              }
            }
          } else {
            // ranges are not reliable for positions of newline characters
            // FIXME: adding text can change a table layout with Firefox, causing wrong results
            String s = ht.text;
            ht.text = "${s.substring(0, i)}|${s.substring(i)}";
            range.setStart(ht, i);
            range.setEnd(ht, i+1);
            List<h.Rectangle> rects = range.getClientRects();
            ht.text = s;
            for (h.Rectangle r in rects) {
              /*
              if (x > r.left && y <= r.bottom) {
                //print("right of \\n");
                // to the right of the last character on the line
                return(new Position(this, pp + i));
              }
              */
              // changed for Chromium, TODO: check with Firefox and IE
              if (y <= r.bottom) {
                // before the line bottom
                return(new Position(this, pp + i));
              }
            }
          }
        }
        pp += ht.length;
      }
      // not found...
      //print("position not found");
    }
    return(new Position(this, offsetLength));
  }
  
  Position firstCursorPositionInside() {
    return(new Position(this, 0));
  }
  
  Position lastCursorPositionInside() {
    return(new Position(this, offsetLength));
  }
  
  void setStyle(h.Element hn) {
    String styleParam = doc.cfg.elementParameterValue(ref, 'style', null);
    if (styleParam != null) {
      List<String> styleList = styleParam.split(';');
      for (String style in styleList) {
        if (style == STYLE_BOLD) {
          hn.style.fontWeight = 'bold';
        } else if (style == STYLE_ITALIC) {
          hn.style.fontStyle = 'italic';
        } else if (style == STYLE_SUPERSCRIPT) {
          hn.style.verticalAlign = 'super';
          hn.style.fontSize = '80%';
        } else if (style == STYLE_SUBSCRIPT) {
          hn.style.verticalAlign = 'sub';
          hn.style.fontSize = '80%';
        } else if (style == STYLE_UNDERLINE) {
          hn.style.textDecoration = 'underline';
        } else if (style == STYLE_STRIKETHROUGH) {
          hn.style.textDecoration = 'line-through';
        } else if (style.startsWith(STYLE_BACKGROUND_COLOR)) {
          hn.style.background = _getColor(style);
        } else if (style.startsWith(STYLE_FOREGROUND_COLOR)) {
          hn.style.color = _getColor(style);
        }
      }
    }
    String fontParam = doc.cfg.elementParameterValue(ref, 'police', null);
    if (fontParam != null) {
      if (fontParam == 'Monospaced')
        fontParam = 'monospace';
      hn.style.fontFamily = fontParam;
    }
    String sizeParam = doc.cfg.elementParameterValue(ref, 'taille', null);
    if (sizeParam != null) {
      hn.style.fontSize = sizeParam;
    }
  }
  
  String _getColor(String style) {
    Iterable<Match> matches = COLOR_PATTERN.allMatches(style);
    for (Match m in matches) {
      final List<int> color = new List<int>();
      for (int j = 0; j < 3; j++) {
        String value = m.group(j + 1);
        if (value.startsWith("x"))
          color[j] = int.parse(value.substring(1), radix: 16);
        else
          color[j] = int.parse(value);
      }
      return("rgb(${color[0]}, ${color[1]}, ${color[2]})");
    }
    return(null);
  }
  
  /**
   * Calls afterInsert for this node and all its descendants.
   */
  void callAfterInsert() {
    afterInsert();
    for (DaxeNode dn=firstChild; dn != null; dn=dn.nextSibling) {
      dn.callAfterInsert();
    }
  }
  
  /**
   * Calls beforeRemove for this node and all its descendants.
   */
  void callBeforeRemove() {
    beforeRemove();
    for (DaxeNode dn=firstChild; dn != null; dn=dn.nextSibling) {
      dn.callBeforeRemove();
    }
  }
  
  /**
   * Called after this node was inserted. Does nothing by default.
   */
  void afterInsert() {
  }
  
  /**
   * Called before this node is removed. Does nothing by default.
   */
  void beforeRemove() {
  }
  
}
