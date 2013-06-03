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

class EntityReferenceImpl extends NodeImpl implements EntityReference {
  
  EntityReferenceImpl.clone(final EntityReference er) {
    nodeName = er.nodeName;
    nodeValue = er.nodeValue;
    nodeType = er.nodeType;
    parentNode = null;
    childNodes = null;
    firstChild = null;
    lastChild = null;
    previousSibling = null;
    nextSibling = null;
    attributes = null;
    ownerDocument = er.ownerDocument;
    namespaceURI = er.namespaceURI;
    prefix = null;
    localName = null;
  }
  
  EntityReferenceImpl(final Document doc, final String name) {
    nodeName = name;
    nodeValue = null;
    nodeType = Node.ENTITY_REFERENCE_NODE;
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
  
  /* h.EntityReference has been removed from the API
  EntityReferenceImpl.fromDH(final Document doc, final h.EntityReference er) {
    // not implemented in Mozilla
    nodeName = er.localName; // BUG
    nodeValue = er.nodeValue;
    nodeType = Node.ENTITY_REFERENCE_NODE;
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
    return(new EntityReferenceImpl.clone(this));
  }
  
  String toString() {
    return("&$nodeName;");
  }
}
