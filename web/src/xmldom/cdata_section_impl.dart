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

class CDATASectionImpl extends NodeImpl implements CDATASection {
  
  CDATASectionImpl.clone(final CDATASection cds) {
    nodeName = cds.nodeName;
    nodeValue = cds.nodeValue;
    nodeType = cds.nodeType;
    parentNode = null;
    childNodes = null;
    firstChild = null;
    lastChild = null;
    previousSibling = null;
    nextSibling = null;
    attributes = null;
    ownerDocument = cds.ownerDocument;
    namespaceURI = cds.namespaceURI;
    prefix = null;
    localName = null;
  }
  
  CDATASectionImpl(final Document doc, final String data) {
    nodeName = "#cdata-section";
    nodeValue = data;
    nodeType = Node.CDATA_SECTION_NODE;
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
  CDATASectionImpl.fromDH(final Document doc, final h.CDataSection cds) {
    nodeName = "#cdata-section";
    nodeValue = cds.nodeValue;
    nodeType = Node.CDATA_SECTION_NODE;
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
    return(new CDATASectionImpl.clone(this));
  }
  
  String toString() {
    String value = nodeValue;
    if (value == null)
      value = '';
    return("<![CDATA[$value]]>");
  }
}

