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

part of xmldom;

class ElementImpl extends NodeImpl implements Element {
  String tagName;
  
  ElementImpl.clone(final Element el, final bool deep) {
    tagName = el.tagName;
    
    nodeName = el.nodeName;
    nodeValue = el.nodeValue;
    nodeType = el.nodeType;
    parentNode = null;
    if (deep && el.childNodes != null) {
      childNodes = new List<Node>();
      for (Node n in el.childNodes) {
        childNodes.add(n.cloneNode(deep));
      }
      if (childNodes.length > 0) {
        firstChild = childNodes[0];
        lastChild = childNodes[childNodes.length - 1];
      } else {
        firstChild = null;
        lastChild = null;
      }
    } else {
      childNodes = null;
      firstChild = null;
      lastChild = null;
    }
    previousSibling = null;
    nextSibling = null;
    if (el.attributes == null)
      attributes = null;
    else {
      attributes = new LinkedHashMap<String, Attr>();
      for (String name in el.attributes.keys) {
        attributes[name] = el.attributes[name].cloneNode(deep);
      }
    }
    ownerDocument = el.ownerDocument;
    namespaceURI = el.namespaceURI;
    prefix = el.prefix;
    localName = el.localName;
  }
  
  ElementImpl(final Document doc, final String tagName) {
    this.tagName = tagName;
    nodeName = tagName;
    nodeValue = null;
    nodeType = Node.ELEMENT_NODE;
    parentNode = null;
    childNodes = null;
    firstChild = null;
    lastChild = null;
    previousSibling = null;
    nextSibling = null;
    attributes = null;
    ownerDocument = doc;
    namespaceURI = null;
    prefix = null;
    localName = null;
  }
  
  ElementImpl.NS(final Document doc, final String namespaceURI, final String qualifiedName) {
    tagName = qualifiedName;
    nodeName = qualifiedName;
    nodeValue = null;
    nodeType = Node.ELEMENT_NODE;
    parentNode = null;
    childNodes = null;
    firstChild = null;
    lastChild = null;
    previousSibling = null;
    nextSibling = null;
    attributes = null;
    ownerDocument = doc;
    this.namespaceURI = namespaceURI;
    int ind = qualifiedName.indexOf(":");
    if (ind != -1) {
      prefix = qualifiedName.substring(0, ind);
      localName = qualifiedName.substring(ind+1);
    } else {
      prefix = null;
      localName = qualifiedName;
    }
  }
  
  /*
  ElementImpl.fromDH(final Document doc, final h.Element el) {
    tagName = el.tagName;
    nodeName = tagName;
    nodeValue = el.nodeValue;
    nodeType = Node.ELEMENT_NODE;
    parentNode = null;
    childNodes = null;
    firstChild = null;
    lastChild = null;
    previousSibling = null;
    nextSibling = null;
    if (el.attributes.length == 0) {
      attributes = null;
    } else {
      attributes = new LinkedHashMap<String, Attr>();
      /*
      h.NamedNodeMap nm = el.$dom_attributes;
      if (nm != null) {
        for (h.Node n in nm) {
          h.Attr att = n as h.Attr;
          setAttributeNode(new AttrImpl.fromDH(ownerDocument, att)); // BUG name != localName
        }
      }
      */
      // WE ARE MISSING ALL NAMESPACED ATTRIBUTES HERE !!!
      for (String attname in el.attributes.keys) {
        setAttribute(attname, el.attributes[attname]);
      }
    }
    ownerDocument = doc;
    namespaceURI = el.$dom_namespaceUri;
    int ind = tagName.indexOf(":");
    if (ind != -1) {
      prefix = tagName.substring(0, ind);
    } else {
      prefix = null;
    }
    localName = el.localName;
    
    for (h.Node n in el.nodes) {
      Node n2 = null;
      switch (n.nodeType) {
        case Node.ELEMENT_NODE:
          n2 = new ElementImpl.fromDH(ownerDocument, n as h.Element);
          break;
        case Node.ATTRIBUTE_NODE:
          //n2 = new AttrImpl.fromDH(ownerDocument, n as h.Attr);
          // no longer possible, attributes are now added elsewhere
          assert(false);
          break;
        case Node.TEXT_NODE:
          n2 = new TextImpl.fromDH(ownerDocument, n as h.Text);
          break;
        case Node.CDATA_SECTION_NODE:
          n2 = new CDATASectionImpl.fromDH(ownerDocument, n as h.CDataSection);
          break;
        case Node.ENTITY_REFERENCE_NODE:
          //n2 = new EntityReferenceImpl.fromDH(ownerDocument, n as h.EntityReference);
          n2 = null; // h.EntityReference has been removed from the API
          break;
        case Node.PROCESSING_INSTRUCTION_NODE:
          n2 = new ProcessingInstructionImpl.fromDH(ownerDocument, n as h.ProcessingInstruction);
          break;
        case Node.COMMENT_NODE:
          n2 = new CommentImpl.fromDH(ownerDocument, n as h.Comment);
          break;
      }
      if (n2 != null)
        appendChild(n2);
    }
    
    // merge text nodes (useful with Firefox)
    for (Node n = firstChild; n != null; n = n.nextSibling) {
      if (n.nodeType == Node.TEXT_NODE) {
        while (n.nextSibling != null && n.nextSibling.nodeType == Node.TEXT_NODE) {
          n.nodeValue += n.nextSibling.nodeValue;
          removeChild(n.nextSibling);
        }
      }
    }
  }
  */
  
  String getAttribute(String name) {
    if (attributes == null)
      return("");
    Attr att = attributes[name];
    if (att == null)
      return("");
    String v = att.nodeValue;
    if (v == null)
      return("");
    return(v);
  }
  
  void setAttribute(String name, String value) { // throws DOMException
    if (attributes == null)
      attributes = new LinkedHashMap<String, Attr>();
    Attr att = attributes[name];
    if (att == null) {
      att = new AttrImpl(ownerDocument, name);
      att.parentNode = this;
      att.ownerElement = this;
      attributes[name] = att;
    }
    att.nodeValue = value;
  }
  
  void removeAttribute(String name) { // throws DOMException
    attributes.remove(name);
  }
  
  Attr getAttributeNode(String name) {
    if (attributes == null)
      return(null);
    return(attributes[name]);
  }
  
  Attr setAttributeNode(Attr newAttr) { // throws DOMException
    if (ownerDocument != newAttr.ownerDocument)
      throw new DOMException("WRONG_DOCUMENT_ERR");
    
    if (attributes == null)
      attributes = new LinkedHashMap<String, Attr>();
    newAttr.parentNode = this;
    newAttr.ownerElement = this;
    attributes[newAttr.name] = newAttr;
    return(newAttr);
  }
  
  Attr removeAttributeNode(Attr oldAttr) { // throws DOMException
    if (attributes == null || !attributes.containsValue(oldAttr))
      throw new DOMException("NOT_FOUND_ERR");
    
    attributes.remove(oldAttr.name);
    return(oldAttr);
  }
  
  List<Node> getElementsByTagName(String name) {
    List<Node> nodes = new List<Node>();
    if (childNodes == null)
      return(nodes);
    for (Node child in childNodes) {
      if (name == '*' || child.nodeName == name)
        nodes.add(child);
      if (child is Element)
        nodes.addAll(child.getElementsByTagName(name));
    }
    return(nodes);
  }
  
  String getAttributeNS(String namespaceURI, String localName) { // throws DOMException
    if (attributes == null)
      return("");
    for (Attr att in attributes.values) {
      if (att.namespaceURI == namespaceURI && att.localName == localName) {
        if (att.value == null)
          return("");
        return(att.value);
      }
    }
    return("");
  }
  
  void setAttributeNS(String namespaceURI, String qualifiedName, String value) { // throws DOMException
    if (attributes == null)
      attributes = new LinkedHashMap<String, Attr>();
    String attPrefix, attLocalName;
    int ind = qualifiedName.indexOf(":");
    if (ind != -1) {
      attPrefix = qualifiedName.substring(0, ind);
      attLocalName = qualifiedName.substring(ind+1);
    } else {
      attPrefix = null;
      attLocalName = qualifiedName;
    }
    Attr att = getAttributeNodeNS(namespaceURI, attLocalName);
    if (att != null) {
      att.prefix = attPrefix;
      att.nodeValue = value;
      return;
    }
    att = new AttrImpl.NS(ownerDocument, namespaceURI, qualifiedName);
    att.parentNode = this;
    att.ownerElement = this;
    att.nodeValue = value;
    attributes[qualifiedName] = att;
  }
  
  void removeAttributeNS(String namespaceURI, String localName) { // throws DOMException
    Attr att = getAttributeNodeNS(namespaceURI, localName);
    if (att != null)
        attributes.remove(att.name);
  }
  
  Attr getAttributeNodeNS(String namespaceURI, String localName) { // throws DOMException
    if (attributes == null)
      return(null);
    for (Attr att in attributes.values) {
      if (att.namespaceURI == namespaceURI && att.localName == localName) {
        return(att);
      }
    }
    return(null);
  }
  
  Attr setAttributeNodeNS(Attr newAttr) { // throws DOMException
    if (ownerDocument != newAttr.ownerDocument)
      throw new DOMException("WRONG_DOCUMENT_ERR");
    if (newAttr.ownerElement != null)
      throw new DOMException("INUSE_ATTRIBUTE_ERR");
    
    if (attributes == null)
      attributes = new LinkedHashMap<String, Attr>();
    Attr att = getAttributeNodeNS(newAttr.namespaceURI, newAttr.localName);
    if (att != null)
      attributes.remove(att.name);
    attributes[newAttr.name] = newAttr;
    return(att);
  }
  
  List<Node> getElementsByTagNameNS(String namespaceURI, String localName) { // throws DOMException
    List<Node> nodes = new List<Node>();
    if (childNodes == null)
      return(nodes);
    for (Node child in childNodes) {
      if (child.namespaceURI == namespaceURI && child.localName == localName)
        nodes.add(child);
      if (child is Element)
        nodes.addAll(child.getElementsByTagNameNS(namespaceURI, localName));
    }
    return(nodes);
  }
  
  bool hasAttribute(String name) {
    if (attributes == null)
      return(false);
    return(attributes[name] != null);
  }
  
  bool hasAttributeNS(String namespaceURI, String localName) { // throws DOMException
    Attr att = getAttributeNodeNS(namespaceURI, localName);
    return(att != null);
  }
  
  Node cloneNode(bool deep) {
    return(new ElementImpl.clone(this, deep));
  }
  
  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write("<$tagName");
    if (attributes != null) {
      for (Attr att in attributes.values) {
        sb.write(" ");
        sb.write(att.toString());
      }
    }
    if (childNodes != null && childNodes.length > 0) {
      sb.write(">");
      for (Node n in childNodes) {
        sb.write(n.toString());
      }
      sb.write("</$tagName>");
    } else {
      sb.write("/>");
    }
    return(sb.toString());
  }
}



