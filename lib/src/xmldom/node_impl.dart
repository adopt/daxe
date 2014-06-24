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

abstract class NodeImpl implements Node {
  
  static const int ELEMENT_NODE                   = 1;
  static const int ATTRIBUTE_NODE                 = 2;
  static const int TEXT_NODE                      = 3;
  static const int CDATA_SECTION_NODE             = 4;
  static const int ENTITY_REFERENCE_NODE          = 5;
  static const int ENTITY_NODE                    = 6;
  static const int PROCESSING_INSTRUCTION_NODE    = 7;
  static const int COMMENT_NODE                   = 8;
  static const int DOCUMENT_NODE                  = 9;
  static const int DOCUMENT_TYPE_NODE             = 10;
  static const int DOCUMENT_FRAGMENT_NODE         = 11;
  static const int NOTATION_NODE                  = 12;

  String nodeName;
  String nodeValue;
  int  nodeType;
  Node parentNode;
  List<Node> childNodes;
  Node firstChild;
  Node lastChild;
  Node previousSibling;
  Node nextSibling;
  LinkedHashMap<String, Attr> attributes;
  Document ownerDocument;
  String namespaceURI;
  String prefix;//TODO: prefix setter method
  String localName;
  
  Node insertBefore(Node newChild, Node refChild) { // throws DOMException
    if (childNodes == null || !childNodes.contains(refChild))
      throw new DOMException("NOT_FOUND_ERR");
    
    _checkNewChildValid(newChild);
    
    if (nodeType == DOCUMENT_NODE && newChild.nodeType == ELEMENT_NODE &&
        (this as Document).documentElement != null)
      throw new DOMException("HIERARCHY_REQUEST_ERR");
    
    if (childNodes == null)
      childNodes = new List<Node>();
    
    if (newChild.parentNode != null)
      newChild.parentNode.removeChild(newChild);
    
    newChild.parentNode = this;
    if (nodeType == DOCUMENT_NODE && newChild.nodeType == ELEMENT_NODE)
      (this as Document).documentElement = newChild;
    
    if (firstChild == refChild)
      firstChild = newChild;
    newChild.nextSibling = refChild;
    newChild.previousSibling = refChild.previousSibling;
    return(newChild);
  }
  
  Node replaceChild(Node newChild, Node oldChild) { // throws DOMException
    if (childNodes == null || !childNodes.contains(oldChild))
      throw new DOMException("NOT_FOUND_ERR");
    
    _checkNewChildValid(newChild);
    
    if (newChild.parentNode != null)
      newChild.parentNode.removeChild(newChild);
    
    newChild.parentNode = this;
    if (nodeType == DOCUMENT_NODE && newChild.nodeType == ELEMENT_NODE)
      (this as Document).documentElement = newChild;
    
    if (firstChild == oldChild)
      firstChild = newChild;
    if (lastChild == oldChild)
      lastChild = newChild;
    newChild.nextSibling = oldChild.nextSibling;
    newChild.previousSibling = oldChild.previousSibling;
    oldChild.parentNode = null;
    childNodes.remove(oldChild);
    return(oldChild);
  }
  
  Node removeChild(Node oldChild) { // throws DOMException
    if (childNodes == null || !childNodes.contains(oldChild))
      throw new DOMException("NOT_FOUND_ERR");
    
    if (nodeType == DOCUMENT_NODE && oldChild.nodeType == ELEMENT_NODE)
      (this as Document).documentElement = null;
    
    if (firstChild == oldChild)
      firstChild = oldChild.nextSibling;
    if (lastChild == oldChild)
      lastChild = oldChild.previousSibling;
    if (oldChild.previousSibling != null)
      oldChild.previousSibling.nextSibling = oldChild.nextSibling;
    if (oldChild.nextSibling != null)
      oldChild.nextSibling.previousSibling = oldChild.previousSibling;
    oldChild.parentNode = null;
    childNodes.remove(oldChild);
    return(oldChild);
  }
  
  Node appendChild(Node newChild) { // throws DOMException
    
    _checkNewChildValid(newChild);
    
    if (nodeType == DOCUMENT_NODE && newChild.nodeType == ELEMENT_NODE &&
        (this as Document).documentElement != null)
      throw new DOMException("HIERARCHY_REQUEST_ERR");
    
    if (childNodes == null)
      childNodes = new List<Node>();
    
    if (newChild.parentNode != null)
      newChild.parentNode.removeChild(newChild);
    
    newChild.parentNode = this;
    if (nodeType == DOCUMENT_NODE && newChild.nodeType == ELEMENT_NODE)
      (this as Document).documentElement = newChild;
    
    newChild.nextSibling = null;
    
    if (firstChild == null) {
      newChild.previousSibling = null;
      firstChild = newChild;
      lastChild = newChild;
    } else {
      lastChild.nextSibling = newChild;
      newChild.previousSibling = lastChild;
      lastChild = newChild;
    }
    
    childNodes.add(newChild);
    return(newChild);
  }
  
  bool hasChildNodes() {
    return(firstChild != null);
  }
  
  Node cloneNode(bool deep);
  
  bool hasAttributes() {
    return(attributes != null && attributes.length > 0);
  }
  
  String lookupPrefix(String namespaceURI) {
    // based on https://developer.mozilla.org/en-US/docs/Code_snippets/LookupPrefix
    if (namespaceURI == null || namespaceURI == '') {
      return(null);
    }
    switch (nodeType) {
        case ELEMENT_NODE:
            return(_lookupNamespacePrefix(namespaceURI));
        case DOCUMENT_NODE:
            return(((this as Document).documentElement as ElementImpl)._lookupNamespacePrefix(namespaceURI));
        case ENTITY_NODE:
        case NOTATION_NODE:
        case DOCUMENT_FRAGMENT_NODE:
        case DOCUMENT_TYPE_NODE:
            return(null);
        case ATTRIBUTE_NODE:
            if ((this as Attr).ownerElement != null) {
                return(((this as Attr).ownerElement as ElementImpl)._lookupNamespacePrefix(namespaceURI));
            }
            return null;
        default:
            if (parentNode != null) {
                return((parentNode as ElementImpl)._lookupNamespacePrefix(namespaceURI));
            }
            return(null);
     }
  }
  
  _lookupNamespacePrefix(final String namespaceURI) {
      final RegExp xmlnsPattern = new RegExp(r"/^xmlns:(.*)$/");
      if (namespaceURI != null && this.namespaceURI == namespaceURI &&
              prefix != null && lookupNamespaceURI(prefix) == namespaceURI) {
          return(prefix);
      }
      if (attributes != null) {
          for (Attr att in attributes.values) {
              if (xmlnsPattern.hasMatch(att.name) && att.value == namespaceURI &&
                  lookupNamespaceURI(att.localName) == namespaceURI) {
                return(localName);
              }
          }
      }
      if (parentNode != null) {
          return((parentNode as ElementImpl)._lookupNamespacePrefix(namespaceURI));
      }
      return null;
  }
  
  String lookupNamespaceURI(String prefix) {
    // cf http://www.w3.org/TR/DOM-Level-3-Core/namespaces-algorithms.html#lookupNamespaceURIAlgo
    switch (nodeType) {
      case ELEMENT_NODE:
        if (namespaceURI != null && this.prefix == prefix)  {
          return(namespaceURI);
        }
        if (attributes != null) {
          for (Attr att in attributes.values) {
            if (att.prefix == 'xmlns' && att.localName == prefix) {
              if (att.value != null && att.value != '') {
                return(att.value);
              }
              return(null);
            } else if (att.localName == 'xmlns' && prefix == null) {
              if (att.value != null && att.value != '') {
                return(att.value);
              }
              return(null);
            }
          }
        }
        if (parentNode != null && parentNode.nodeType != DOCUMENT_NODE) {
          return parentNode.lookupNamespaceURI(prefix);
        }
        return null;
      case DOCUMENT_NODE:
        return((this as Document).documentElement.lookupNamespaceURI(prefix));
      case ENTITY_NODE:
      case NOTATION_NODE:
      case DOCUMENT_TYPE_NODE:
      case DOCUMENT_FRAGMENT_NODE:
        return(null);
      case ATTRIBUTE_NODE:
        if (parentNode != null)
          return(parentNode.lookupNamespaceURI(prefix));
        return(null);
      default:
        if (parentNode != null)
          return(parentNode.lookupNamespaceURI(prefix));
        return(null);
    }
  }
  
  _checkNewChildValid(Node newChild) { // throws DOMException
    if (nodeType != DOCUMENT_NODE && ownerDocument != newChild.ownerDocument)
      throw new DOMException("WRONG_DOCUMENT_ERR");
    
    if (nodeType == DOCUMENT_NODE && this != newChild.ownerDocument)
      throw new DOMException("WRONG_DOCUMENT_ERR");
    
    if (nodeType != ELEMENT_NODE && nodeType != DOCUMENT_NODE)
      throw new DOMException("HIERARCHY_REQUEST_ERR");
    
    if (newChild.nodeType == DOCUMENT_NODE)
      throw new DOMException("HIERARCHY_REQUEST_ERR");
    
    if (nodeType != DOCUMENT_NODE && newChild.nodeType == ATTRIBUTE_NODE)
      throw new DOMException("HIERARCHY_REQUEST_ERR");
    
    // etc...
    
    Node ancestor = this;
    while (ancestor != null) {
      if (newChild == ancestor)
        throw new DOMException("HIERARCHY_REQUEST_ERR");
      ancestor = ancestor.parentNode;
    }
  }
  
  /// escapes XML character entities for serialization
  static String _escape(String s) {
    s = s.replaceAll('&', '&amp;');
    s = s.replaceAll('"', '&quot;');
    //s = s.replaceAll("'", '&apos;');
    s = s.replaceAll('<', '&lt;');
    s = s.replaceAll('>', '&gt;');
    return(s);
  }
}
