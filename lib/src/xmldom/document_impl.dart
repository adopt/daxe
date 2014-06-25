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

class DocumentImpl extends NodeImpl implements Document {
  DOMImplementation implementation;
  Element documentElement;
  String inputEncoding;
  String xmlEncoding;
  bool xmlStandalone;
  String xmlVersion;
  String documentURI;
  DocumentType doctype;
  
  HashMap<String, Element> _idToElement; // todo: fill this with something !
  
  
  DocumentImpl.clone(final Document doc, final bool deep) {
    implementation = doc.implementation;
    inputEncoding = doc.inputEncoding;
    xmlEncoding = doc.xmlEncoding;
    xmlStandalone = doc.xmlStandalone;
    xmlVersion = doc.xmlVersion;
    documentURI = doc.documentURI;
    doctype = doc.doctype;
    
    _idToElement = new HashMap<String, Element>();
    
    nodeName = doc.nodeName;
    nodeValue = doc.nodeValue;
    nodeType = doc.nodeType;
    parentNode = null;
    documentElement = null;
    if (deep && doc.childNodes != null) {
      childNodes = new List<Node>();
      for (Node n in doc.childNodes) {
        Node n2 = n.cloneNode(deep);
        childNodes.add(n2);
        if (n2 is Element)
          documentElement = n2;
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
    previousSibling = doc.previousSibling;
    nextSibling = doc.nextSibling;
    attributes = null;
    ownerDocument = doc.ownerDocument;
    namespaceURI = doc.namespaceURI;
    prefix = doc.prefix;
    localName = doc.localName;
  }
  
  DocumentImpl(final DOMImplementation implementation, final String namespaceURI,
               final String qualifiedName, final DocumentType doctype) {
    this.implementation = implementation;
    inputEncoding = null;
    xmlEncoding = "UTF-8";
    xmlStandalone = false;
    xmlVersion = "1.0";
    documentURI = null;
    this.doctype = doctype;
    _idToElement = new HashMap<String, Element>();
    
    nodeName = "#document";
    nodeValue = null;
    nodeType = Node.DOCUMENT_NODE;
    parentNode = null;
    childNodes = null;
    firstChild = null;
    lastChild = null;
    previousSibling = null;
    nextSibling = null;
    attributes = null;
    ownerDocument = null;
    this.namespaceURI = null;
    prefix = null;
    localName = null;
    
    if (qualifiedName != null) {
      if (namespaceURI != null)
        documentElement = new ElementImpl.NS(this, namespaceURI, qualifiedName);
      else
        documentElement = new ElementImpl(this, qualifiedName);
      documentElement.parentNode = this;
    }
  }
  
  /*
  DocumentImpl.fromDH(final DOMImplementation implementation, final h.Document doc) {
    // lots of info missing !
    this.implementation = implementation;
    inputEncoding = null;
    xmlEncoding = doc.charset;
    xmlStandalone = false;
    xmlVersion = "1.0";
    documentURI = null;
    doctype = null; // new DocumentTypeImpl.fromDH(this, doc.doctype);
    
    _idToElement = new HashMap<String, Element>();
    
    nodeName = "#document";
    nodeValue = doc.nodeValue;
    nodeType = Node.DOCUMENT_NODE;
    parentNode = null;
    childNodes = null;
    firstChild = null;
    lastChild = null;
    previousSibling = null;
    nextSibling = null;
    attributes = null;
    ownerDocument = null;
    namespaceURI = null;
    prefix = null;
    localName = null;
    
    appendChild(new ElementImpl.fromDH(this, doc.documentElement));
  }
  */
  
  Element createElement(String tagName) { // throws DOMException
    return(new ElementImpl(this, tagName));
  }
  
  DocumentFragment createDocumentFragment() {
    return(new DocumentFragmentImpl(this));
  }
  
  Text createTextNode(String data) {
    return(new TextImpl(this, data));
  }
  
  Comment createComment(String data) {
    return(new CommentImpl(this, data));
  }
  
  CDATASection createCDATASection(String data) { // throws DOMException
    return(new CDATASectionImpl(this, data));
  }
  
  ProcessingInstruction createProcessingInstruction(String target, String data) { // throws DOMException
    return(new ProcessingInstructionImpl(this, target, data));
  }
  
  Attr createAttribute(String name) { // throws DOMException
    return(new AttrImpl(this, name));
  }
  
  EntityReference createEntityReference(String name) { // throws DOMException
    return(new EntityReferenceImpl(this, name));
  }
  
  List<Node> getElementsByTagName(String tagname) {
    List<Node> nodes = new List<Node>();
    for (Node child in childNodes) {
      if (tagname == '*' || child.nodeName == tagname)
        nodes.add(child);
      if (child is Element)
        nodes.addAll(child.getElementsByTagName(tagname));
    }
    return(nodes);
  }
  
  Node importNode(Node importedNode, bool deep) { // throws DOMException
    Node clone = importedNode.cloneNode(deep);
    if (clone.nodeType == Node.ENTITY_NODE || clone.nodeType == Node.NOTATION_NODE) {
      clone.ownerDocument = this;
    } else
      adoptNode(clone);
    return(clone);
  }
  
  Element createElementNS(String namespaceURI, String qualifiedName) { // throws DOMException
    return(new ElementImpl.NS(this, namespaceURI, qualifiedName));
  }
  
  Attr createAttributeNS(String namespaceURI, String qualifiedName) { // throws DOMException
    return(new AttrImpl.NS(this, namespaceURI, qualifiedName));
  }
  
  List<Node> getElementsByTagNameNS(String namespaceURI, String localName) {
    List<Node> nodes = new List<Node>();
    for (Node child in childNodes) {
      if (child.namespaceURI == namespaceURI && child.localName == localName)
        nodes.add(child);
      if (child is Element)
        nodes.addAll(child.getElementsByTagNameNS(namespaceURI, localName));
    }
    return(nodes);
  }
  
  /*
  Element getElementById(String elementId) {
    return(_idToElement[elementId]);
  }
  */
  
  Node adoptNode(Node source) { // throws DOMException
    if (source.nodeType == Node.DOCUMENT_NODE || source.nodeType == Node.DOCUMENT_TYPE_NODE ||
        source.nodeType == Node.ENTITY_NODE || source.nodeType == Node.NOTATION_NODE)
      throw new DOMException("NOT_SUPPORTED_ERR");
    
    if (source.parentNode != null) {
      source.parentNode.removeChild(source);
    }
    
    if (source is Attr) {
      Attr att = source;
      att.ownerElement = null;
      att.specified = true;
    }
    
    _adoptNodeRecursion(source);
    return(source);
  }
  
  void _adoptNodeRecursion(Node source) {
    source.ownerDocument = this;
    if (source.attributes != null) {
      List<String> removeKeys = new List<String>();
      for (Attr att in source.attributes.values) {
        if (att.specified)
          att.ownerDocument = this;
        else
          removeKeys.add(att.name);
      }
      for (String attname in removeKeys) {
        source.attributes.remove(attname);
      }
    }
    if (source.childNodes != null) {
      for (Node n in source.childNodes) {
        if (n.nodeType != Node.DOCUMENT_TYPE_NODE && n.nodeType != Node.ENTITY_NODE &&
            n.nodeType != Node.NOTATION_NODE)
        _adoptNodeRecursion(n);
      }
    }
  }
  
  Node cloneNode(bool deep) {
    return(new DocumentImpl.clone(this, deep));
  }
  
  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write("<?xml");
    if (xmlVersion != null)
      sb.write(' version="$xmlVersion"');
    if (xmlEncoding != null)
      sb.write(' encoding="$xmlEncoding"');
    sb.writeln("?>");
    if (doctype != null)
      sb.write(doctype.toString());
    for (Node n in childNodes) {
      sb.write(n.toString());
    }
    return(sb.toString());
  }
}
