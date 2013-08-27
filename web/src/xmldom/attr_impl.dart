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

/*
 * Entity references are not supported by this implementation.
 */
class AttrImpl extends NodeImpl implements Attr {
  bool specified;
  Element ownerElement;
  bool isId;
  
  AttrImpl.clone(final Attr attr) {
    specified = true;
    ownerElement = attr.ownerElement;
    isId = attr.isId;
    
    nodeName = attr.nodeName;
    nodeValue = attr.nodeValue;
    nodeType = attr.nodeType;
    parentNode = null;
    childNodes = null;
    firstChild = null;
    lastChild = null;
    previousSibling = attr.previousSibling;
    nextSibling = attr.nextSibling;
    attributes = null;
    ownerDocument = attr.ownerDocument;
    namespaceURI = attr.namespaceURI;
    prefix = attr.prefix;
    localName = attr.localName;
  }
  
  AttrImpl(final Document doc, final String name) {
    specified = true;
    ownerElement = null;
    isId = false;
    
    nodeName = name;
    nodeValue = null;
    nodeType = Node.ATTRIBUTE_NODE;
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
  
  AttrImpl.NS(final Document doc, final String namespaceURI, final String qualifiedName) {
    specified = true;
    ownerElement = null;
    isId = false;
    
    nodeName = qualifiedName;
    nodeValue = null;
    nodeType = Node.ATTRIBUTE_NODE;
    parentNode = null;
    childNodes = null;
    firstChild = null;
    lastChild = null;
    previousSibling = null;
    nextSibling = null;
    attributes = null;
    ownerDocument = doc;
    this.namespaceURI = namespaceURI;
    int ind = name.indexOf(":");
    if (ind != -1) {
      prefix = name.substring(0, ind);
      localName = name.substring(ind+1);
    } else {
      prefix = null;
      localName = name;
    }
  }
  
  /*
  AttrImpl.fromDH(final Document doc, final String localName, final String value) {
    specified = true;
    ownerElement = null;
    isId = false;
    
    nodeName = localName; // KNOWN BUG: should be name
    nodeValue = value;
    nodeType = Node.ATTRIBUTE_NODE;
    parentNode = null;
    childNodes = null;
    firstChild = null;
    lastChild = null;
    previousSibling = null;
    nextSibling = null;
    attributes = null;
    ownerDocument = doc;
    namespaceURI = null;
    prefix = null; // KNOW BUG, see http://code.google.com/p/dart/issues/detail?id=8521
    this.localName = localName;
  }
  */
  
  Node cloneNode(bool deep) {
    return(new AttrImpl.clone(this));
  }
  
  String get name {
    return(nodeName);
  }
  
  void set name(String name) {
    nodeName = name;
  }
  
  String get value {
    return(nodeValue);
  }
  
  void set value(String value) {
    nodeValue = value;
  }
  
  String toString() {
    return('$nodeName="${NodeImpl._escape(nodeValue)}"');
  }
}
