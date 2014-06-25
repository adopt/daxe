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

class DocumentFragmentImpl extends NodeImpl implements DocumentFragment {
  
  DocumentFragmentImpl.clone(final DocumentFragment df, final bool deep) {
    nodeName = df.nodeName;
    nodeValue = df.nodeValue;
    nodeType = df.nodeType;
    parentNode = null;
    if (deep && df.childNodes != null) {
      childNodes = new List<Node>();
      for (Node n in df.childNodes) {
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
    attributes = null;
    ownerDocument = df.ownerDocument;
    namespaceURI = df.namespaceURI;
    prefix = null;
    localName = null;
  }
  
  DocumentFragmentImpl(final Document doc) {
    nodeName = "#document-fragment";
    nodeValue = null;
    nodeType = Node.DOCUMENT_FRAGMENT_NODE;
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
  
  /*
  DocumentFragmentImpl.fromDH(final Document doc, final h.DocumentFragment df) {
    nodeName = "#document-fragment";
    nodeValue = df.nodeValue;
    nodeType = Node.DOCUMENT_FRAGMENT_NODE;
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
    return(new DocumentFragmentImpl.clone(this, deep));
  }
  
  String toString() {
    StringBuffer sb = new StringBuffer();
    for (Node n in childNodes) {
      sb.write(n.toString());
    }
    return(sb.toString());
  }
}

