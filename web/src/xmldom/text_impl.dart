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

class TextImpl extends NodeImpl implements Text {
  
  TextImpl.clone(final Text txt) {
    nodeName = txt.nodeName;
    nodeValue = txt.nodeValue;
    nodeType = txt.nodeType;
    parentNode = null;
    childNodes = null;
    firstChild = null;
    lastChild = null;
    previousSibling = null;
    nextSibling = null;
    attributes = null;
    ownerDocument = txt.ownerDocument;
    namespaceURI = txt.namespaceURI;
    prefix = null;
    localName = null;
  }
  
  TextImpl(final Document doc, final String data) {
    nodeName = "#text";
    nodeValue = data;
    nodeType = Node.TEXT_NODE;
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
  TextImpl.fromDH(final Document doc, final h.Text txt) {
    nodeName = "#text";
    nodeValue = txt.nodeValue;
    nodeType = Node.TEXT_NODE;
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
    return(new TextImpl.clone(this));
  }
  
  String toString() {
    return(NodeImpl._escape(nodeValue));
  }
}

