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

class CommentImpl extends NodeImpl implements Comment {
  
  CommentImpl.clone(final Comment com) {
    nodeName = "#comment";
    nodeValue = com.nodeValue;
    nodeType = com.nodeType;
    parentNode = null;
    childNodes = null;
    firstChild = null;
    lastChild = null;
    previousSibling = null;
    nextSibling = null;
    attributes = null;
    ownerDocument = com.ownerDocument;
    namespaceURI = com.namespaceURI;
    prefix = null;
    localName = null;
  }
  
  CommentImpl(final Document doc, final String data) {
    nodeName = "#comment";
    nodeValue = data;
    nodeType = Node.COMMENT_NODE;
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
  CommentImpl.fromDH(final Document doc, final h.Comment com) {
    nodeName = "#comment";
    nodeValue = com.nodeValue;
    nodeType = Node.COMMENT_NODE;
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
    return(new CommentImpl.clone(this));
  }
  
  String toString() {
    return("<!--$nodeValue-->");
  }
}

