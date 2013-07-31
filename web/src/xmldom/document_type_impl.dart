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

class DocumentTypeImpl extends NodeImpl implements DocumentType {
  String name;
  String publicId;
  String systemId;
  
  DocumentTypeImpl.clone(final DocumentType dt) {
    name = dt.name;
    publicId = dt.publicId;
    systemId = dt.systemId;
    
    nodeName = dt.nodeName;
    nodeValue = dt.nodeValue;
    nodeType = dt.nodeType;
    parentNode = null;
    childNodes = null;
    firstChild = null;
    lastChild = null;
    previousSibling = null;
    nextSibling = null;
    attributes = null;
    ownerDocument = dt.ownerDocument;
    namespaceURI = dt.namespaceURI;
    prefix = null;
    localName = null;
  }
  
  DocumentTypeImpl(final String qualifiedName, final String publicId, final String systemId) {
    name = qualifiedName;
    this.publicId = publicId;
    this.systemId = systemId;
    
    nodeName = qualifiedName;
    nodeValue = null;
    nodeType = Node.DOCUMENT_TYPE_NODE;
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
  }
  
  /*
  DocumentTypeImpl.fromDH(final Document doc, final h.DocumentType dt) {
    // BUG: name, publicId, systemId ???
    name = dt.$dom_localName;
    publicId = null;
    systemId = null;
    
    nodeName = name;
    nodeValue = dt.nodeValue;
    nodeType = Node.DOCUMENT_TYPE_NODE;
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
  */
  
  Node cloneNode(bool deep) {
    return(new DocumentTypeImpl.clone(this));
  }
  
  String toString() {
    if (publicId == null && systemId != null)
      return('<!DOCTYPE $name SYSTEM "$systemId">');
    if (publicId != null && systemId != null)
      return('<!DOCTYPE $name PUBLIC "$publicId" "$systemId">');
    if (publicId != null)
      return('<!DOCTYPE $name PUBLIC "$publicId">');
    return('<!DOCTYPE $name>');
  }
}


