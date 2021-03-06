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
 * This class represents a GUI for an XML node. The subclasses offer differents GUIs
 * corresponding to different display types.
 */
abstract class DaxeNode {
  /// type for an XML element, CDATA section, processing instruction or XML comment
  static const int ELEMENT_NODE = 1;
  /// type for a text node
  static const int TEXT_NODE = 3;
  /// type for a document node
  static const int DOCUMENT_NODE = 9;
  
  static const String _COLOR_PATTERN =
    "^.*\\[(x[0-9a-fA-F]{2}|[0-9]{1,3}),(x[0-9a-fA-F]{2}|[0-9]{1,3}),(x[0-9a-fA-F]{2}|[0-9]{1,3})\\]\$";
  
  /// element reference (schema element)
  x.Element ref;
  String _id;
  DaxeNode parent;
  /// There are only 3 different node types: ELEMENT_NODE, TEXT_NODE and DOCUMENT_NODE.
  int nodeType;
  String _namespaceURI;
  String prefix;
  String localName;
  String nodeValue;
  DaxeNode _firstChild;
  DaxeNode _nextSibling;
  List<DaxeAttr> attributes;
  /// Set to true in a subclass to prevent user from removing the node with the
  /// suppr or del keys.
  bool userCannotRemove = false; // with suppr/del, could be extended to selections...
  /// Set to true in a subclass to prevent the user from editing the contents
  /// of this node even when editing is valid (edition inside children is
  /// still possible).
  bool userCannotEdit = false;
  /// node validity set by [Config.elementIsValid] when the node is created or
  /// when [updateValidity] is called.
  bool valid;
  /// used in [DaxeDocument.elementsAllowedUnder] to restrict inserts beyond schema
  List<String> restrictedInserts;
  
  
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
        // also fix the namespace
        _namespaceURI = doc.cfg.elementNamespace(ref);
      }
    }
    
    if (createChildren) {
      if (node.childNodes != null) {
        DaxeNode prev = null;
        for (x.Node n in node.childNodes) {
          DaxeNode dn = NodeFactory.createFromNode(n, this);
          if (prev == null)
            _firstChild = dn;
          else
            prev._nextSibling = dn;
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
    prefix = doc.cfg.elementPrefix(_namespaceURI, null, null);
    localName = doc.cfg.elementName(ref);
    nodeValue = null;
    _firstChild = null;
    _nextSibling = null;
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
    _firstChild = null;
    _nextSibling = null;
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
    _firstChild = null;
    _nextSibling = null;
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
  
  /**
   * Node name (including the prefix when there is one).
   */
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
    for (DaxeNode dn=_firstChild; dn != null; dn=dn._nextSibling)
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
    h.Element hnode = getHTMLNode(); 
    return(hnode is h.DivElement || hnode is h.ParagraphElement || hnode is h.TableElement ||
      hnode is h.TableRowElement || hnode is h.TableCellElement || hnode is h.UListElement ||
      hnode is h.LIElement);
  }
  
  /**
   * Returns true if this node serializes to an XML element
   * (i.e. it has the DaxeNode.ELEMENT_NODE type but is not a DNComment,
   * DNProcessingInstruction or DNCData).
   */
  bool isXMLElement() {
    return(nodeType == DaxeNode.ELEMENT_NODE && this is! DNComment &&
        this is! DNProcessingInstruction && this is! DNCData);
  }
  
  /**
   * The child nodes in a convenient list.
   */
  List<DaxeNode> get childNodes {
    List<DaxeNode> list = new List<DaxeNode>();
    for (DaxeNode dn=_firstChild; dn != null; dn=dn._nextSibling) {
      list.add(dn);
    }
    return(list);
  }
  
  DaxeNode get firstChild {
    return _firstChild;
  }
  
  DaxeNode get nextSibling {
    return _nextSibling;
  }
  
  /**
   * This node's previous sibling.
   */
  DaxeNode get previousSibling {
    if (parent == null)
      return(null);
    for (DaxeNode dn = parent._firstChild; dn != null; dn = dn._nextSibling) {
      if (dn._nextSibling == this)
        return(dn);
    }
    return(null);
  }
  
  DaxeNode get lastChild {
    for (DaxeNode dn = _firstChild; dn != null; dn = dn._nextSibling) {
      if (dn._nextSibling == null)
        return(dn);
    }
    return(null);
  }
  
  DaxeNode childAtOffset(int offset) {
    assert(nodeType != TEXT_NODE);
    int n = 0;
    for (DaxeNode dn=_firstChild; dn != null; dn=dn._nextSibling) {
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
    for (DaxeNode n=_firstChild; n != null; n=n._nextSibling) {
      if (n == child)
        return(i);
      i++;
    }
    assert(false);
    return(-1);
  }
  
  String getAttribute(String name) {
    for (DaxeAttr att in attributes) {
      if (att.name == name)
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
  
  void removeAttribute(String name) {
    for (DaxeAttr att in attributes) {
      if (att.localName == name) {
        attributes.remove(att);
        return;
      }
    }
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
  
  /**
   * Returns a LinkedHashMap attribute name -> attribute node for all
   * the attributes specified in the node.
   */
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
      last._nextSibling = dn;
    else
      _firstChild = dn;
    dn.parent = this;
  }
  
  /**
   * Inserts [newdn] as a child of this node before [beforedn].
   * [beforedn] may be null, in which case it is inserted as the last child.
   */
  void insertBefore(DaxeNode newdn, DaxeNode beforedn) {
    assert(beforedn == null || this == beforedn.parent);
    newdn.parent = this;
    DaxeNode dn = _firstChild;
    if (dn == beforedn) {
      DaxeNode save = _firstChild;
      _firstChild = newdn;
      newdn._nextSibling = save;
    } else {
      while (dn != null && dn._nextSibling != beforedn) {
        dn = dn._nextSibling;
      }
      assert(dn != null);
      assert(dn._nextSibling == beforedn);
      DaxeNode save = dn._nextSibling;
      dn._nextSibling = newdn;
      newdn._nextSibling = save;
    }
  }
  
  /**
   * Inserts [newdn] as a child of this node after [afterdn].
   * [afterdn] may not be null.
   */
  void insertAfter(DaxeNode newdn, DaxeNode afterdn) {
    assert(afterdn != null && this == afterdn.parent);
    if (afterdn._nextSibling == null)
      appendChild(newdn);
    else
      insertBefore(newdn, afterdn._nextSibling);
  }
  
  void removeChild(DaxeNode dn) {
    if (dn.previousSibling != null)
      dn.previousSibling._nextSibling = dn._nextSibling;
    if (dn == _firstChild)
      _firstChild = dn._nextSibling;
    dn.parent = null;
    dn._nextSibling = null;
  }
  
  /**
   * Replaces this node by the given node (in the tree).
   */
  void replaceWith(DaxeNode dn) {
    if (parent._firstChild == this)
      parent._firstChild = dn;
    else
      previousSibling._nextSibling = dn;
    dn.parent = parent;
    dn._nextSibling = _nextSibling;
    parent = null;
    _nextSibling = null;
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
  
  /**
   * For a text node, removes the text starting at `pos.dnOffset` with
   * the given `length`.
   * Otherwise, removes `length` children starting at `pos.dnOffset`.
   */
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
   * Returns true if spaces should be preserved (with a WXS schema, xml:space="preserve").
   * The parent's value is only used if provided as an argument.
   */
  bool spacePreserve([final bool spacePreserveParent=false]) {
    bool spacePreserve;
    final String xmlspace = getAttribute("xml:space");
    if (xmlspace == "preserve")
      spacePreserve = true;
    else if (xmlspace == "default")
      spacePreserve = false;
    else
      spacePreserve = spacePreserveParent;
    if (ref != null && xmlspace == null) {
      final List<x.Element> attributs = doc.cfg.elementAttributes(ref);
      for (x.Element attref in attributs) {
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
    return(spacePreserve);
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
    if (newlineInside() && lastChild is DNText &&
        (lastNotText == null || !lastNotText.newlineAfter())) {
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
      if (newlineInside() && lastChild != null && (lastNotText == null ||
          !lastNotText.newlineAfter()))
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
  
  /**
   * Adds or removes the `invalid` class to the HTML node.
   */
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
  
  /**
   * Displays the attribute dialog for this node. Can be overridden
   * in subclasses for a custom dialog.
   */
  void attributeDialog([ActionFunction okfct]) {
    if (ref != null) {
      AttributeDialog dlg = new AttributeDialog(this, okfct);
      dlg.show();
    } else {
      UnknownElementDialog dlg = new UnknownElementDialog(this, okfct);
      dlg.show();
    }
  }
  
  /**
   * Returns the [Position] matching given mouse coordinates.
   */
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
            hn.firstChild is h.SpanElement &&
            (hn.firstChild as h.SpanElement).classes.contains('start_tag') &&
            hn.lastChild is h.SpanElement &&
            (hn.lastChild as h.SpanElement).classes.contains('end_tag')) {
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
        } else if (hn is h.DivElement || hn is h.ParagraphElement || hn is h.TableCellElement ||
            hn is h.TableRowElement || hn is h.TableElement || hn is h.ImageElement) {
          // block
          // for DivElement: no span to tag the div: we take the entire div into account
          h.Rectangle box = hn.getBoundingClientRect();
          hnx1 = box.left;
          hny1 = box.top;
          if (hn.classes.contains('form')) // FIXME: this is a hack !
            hnx2 = hn.querySelector('table').getBoundingClientRect().right;
          else
            hnx2 = box.right;
          hny2 = box.bottom;
          if (hn is h.TableRowElement) {
            // getBoundingClientRect is wrong for tr containing a td with 
            // rowspan, so we have to check all td
            for (h.Element td in hn.children) {
              if (td.getAttribute('rowspan') != null) {
                h.Rectangle tdBox = td.getBoundingClientRect();
                if (tdBox.containsPoint(new h.Point(x, y))) {
                  if (tdBox.bottom > hny2)
                    hny2 = tdBox.bottom;
                  break;
                }
              }
            }
          }
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
          // NOTE: If there is an image or an inline-block div on the line,
          // the top left might be wrong unless we use vertical-align: top on the span.
          // Changing the style and using getClientRects twice might slow things down a bit.
          // Also, using a Range afterwards to find the position within the text will not work...
          /* this is an experiment to solve the problem:
          hn.style.verticalAlign = 'top';
          List<h.Rectangle> topRects = hn.getClientRects();
          if (topRects.length == 0)
            return(null);
          hn.style.verticalAlign = '';
          h.Rectangle firstTopBox = topRects.first;
          h.Rectangle lastTopBox = topRects.last;
          List<h.Rectangle> bottomRects = hn.getClientRects();
          h.Rectangle firstBottomBox = bottomRects.first;
          h.Rectangle lastBottomBox = bottomRects.last;
          hnx1 = firstTopBox.left;
          hny1 = firstTopBox.top;
          topLineHeight = firstBottomBox.bottom - firstTopBox.top;
          hnx2 = lastTopBox.right;
          hny2 = lastBottomBox.bottom;
          bottomLineHeight = lastBottomBox.bottom - lastTopBox.top;
          */
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
              while (true) {
                h.Node lastTest = lastDescendant.lastChild;
                if (lastTest is h.Text && lastTest.nodeValue == '\n')
                  lastTest = lastTest.previousNode; // case of a hidden paragraph or block inside li
                while (lastTest is h.ScriptElement)
                  lastTest = lastTest.previousNode;
                if (lastTest == null || lastTest is h.Text || lastTest is h.ImageElement)
                  break;
                lastDescendant = lastTest;
              }
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
        if (y < hny1 + topLineHeight && (y < hny1 - 1 || (x < hnx1 + 1 && hn is! h.LIElement &&
            dn is! DNHiddenP))) {
          // position is before this child
          return(pos);
        }
        if ((y > hny2 - bottomLineHeight && (y > hny2 + 1 || (x > hnx2 - 1 && hn is! h.LIElement))) ||
            (hn.style.float == 'right' && x < hnx1 && y > hny1 - 1)) {
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
        // first try to approximate position for long texts
        int i1 = 0;
        int i2 = ht.length - 1;
        if (i2 > 200) {
          int im;
          while (i2 - i1 > 10) {
            im = (i1 + i2) ~/ 2;
            // avoid \n, getBoundingClientRect would return 0
            int im2 = im;
            while (nodeValue[pp + im2] == '\n' && im2 - im < 5)
              im2++;
            if (im2 - im >= 5)
              break; // too many \n, give up on optimizing
            im = im2;
            range.setStart(ht, im);
            range.setEnd(ht, im+1);
            h.Rectangle r = range.getBoundingClientRect();
            if (y < r.top) {
              i2 = im;
            } else if (y > r.bottom) {
              i1 = im;
            } else {
              break;
            }
          }
          i1 = im - 10;
          if (i1 < 0)
            i1 = 0;
          // go back 2 lines to make sure not to miss the right position
          int nbnl = 0;
          while (i1 > 0 && i1 > im - 200 && nbnl < 2) {
            if (nodeValue[pp + i1] == '\n')
              nbnl ++;
            i1--;
          }
        }
        for (int i=i1; i<ht.length; i++) {
          // problem: depending on the browser, the clientrects are not the same
          // for \n or for line-breaking space characters (or for the character before a \n with IE11)...
          if (nodeValue[pp + i] != '\n') {
            range.setStart(ht, i);
            range.setEnd(ht, i+1);
            List<h.Rectangle> rects = range.getClientRects();
            for (h.Rectangle r in rects) {
              if ((h.window.navigator.appVersion.contains("Trident") ||
                  h.window.navigator.appVersion.contains("Edge")) &&
                  pp + i + 1 < nodeValue.length &&
                  nodeValue[pp + i + 1] == '\n' && r.width == 0) {
                // With IE11/Edge, ignore a 0-width rect for the character before a \n
                continue;
              }
              if (i < nodeValue.length - 1 && r.left == r.right &&
                  x < r.left && y < r.bottom) {
                //print("left of line start after newline");
                return(new Position(this, pp + i+1));
              }
              if (x < r.right && y <= r.bottom) {
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
            if (h.window.navigator.appVersion.contains("Trident") ||
                h.window.navigator.appVersion.contains("Edge")) {
              // tested on IE11 and Edge 20
              if (y <= rects.first.bottom) {
                // before the line bottom
                return(new Position(this, pp + i));
              }
            } else {
              // tested on Chromium and Firefox
              for (h.Rectangle r in rects) {
                if (y <= r.bottom) {
                  // before the line bottom
                  return(new Position(this, pp + i));
                }
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
  
  /**
   * Returns the first position inside the node. This is used for caret
   * movements and also to set the cursor inside the node when it is first created.
   * This can overridden by subclasses when the cursor should be set in a child
   * (for instance the cursor should be placed inside the first td for an HTML table).
   */
  Position firstCursorPositionInside() {
    return(new Position(this, 0));
  }
  
  /**
   * Similar to [firstCursorPositionInside], this returns the last position
   * inside the node.
   */
  Position lastCursorPositionInside() {
    return(new Position(this, offsetLength));
  }
  
  /**
   * Sets the CSS style of given HTML element based on the config
   * `style` parameter for this node.
   */
  void setStyle(h.Element hn) {
    String styleParam = doc.cfg.elementParameterValue(ref, 'style', null);
    if (styleParam != null) {
      List<String> styleList = styleParam.split(';');
      for (String style in styleList) {
        if (style == 'BOLD') {
          hn.style.fontWeight = 'bold';
        } else if (style == 'ITALIC') {
          hn.style.fontStyle = 'italic';
        } else if (style == 'SUPERSCRIPT') {
          hn.style.verticalAlign = 'super';
          hn.style.fontSize = '80%';
        } else if (style == 'SUBSCRIPT') {
          hn.style.verticalAlign = 'sub';
          hn.style.fontSize = '80%';
        } else if (style == 'UNDERLINE') {
          hn.style.textDecoration = 'underline';
        } else if (style == 'STRIKETHROUGH') {
          hn.style.textDecoration = 'line-through';
        } else if (style.startsWith('BACKGROUND')) {
          hn.style.background = _getColor(style);
        } else if (style.startsWith('FOREGROUND')) {
          hn.style.color = _getColor(style);
        }
      }
    }
    String fontParam = doc.cfg.elementParameterValue(ref, 'font', null);
    if (fontParam != null) {
      if (fontParam == 'Monospaced')
        fontParam = 'monospace';
      hn.style.fontFamily = fontParam;
    }
    String sizeParam = doc.cfg.elementParameterValue(ref, 'size', null);
    if (sizeParam != null) {
      hn.style.fontSize = sizeParam;
    }
  }
  
  String _getColor(String style) {
    Iterable<Match> matches = _COLOR_PATTERN.allMatches(style);
    for (Match m in matches) {
      final List<int> color = new List<int>(3);
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
   * Called after this node was inserted (after display update). Does nothing by default.
   */
  void afterInsert() {
  }
  
  /**
   * Called before this node is removed. Does nothing by default.
   */
  void beforeRemove() {
  }
  
  /**
   * Returns true if the children should be using ParentUpdatingDNText
   * or another class defined by specialDNTextConstructor instead of DNText.
   * This node's fromNode constructor should make sure to replace any
   * DNText by the special class (this is not done automatically).
   */
  bool get needsSpecialDNText {
    return false;
  }
  
  /**
   * Makes the node draggable using the given HTML element.
   */
  void setupDrag(h.Element hel) {
    page.cursor.setupDrag(hel, this);
  }
  
  /**
   * Only used when needsSpecialDNText is true.
   * Returns a ParentUpdatingDNText by default.
   */
  DNText specialDNTextConstructor(String text) {
    return new ParentUpdatingDNText(text);
  }
}
