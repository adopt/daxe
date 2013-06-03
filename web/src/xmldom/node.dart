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

abstract class Node {
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
  String prefix;
  String localName;
  
  Node insertBefore(Node newChild, Node refChild); // throws DOMException
  Node replaceChild(Node newChild, Node oldChild); // throws DOMException
  Node removeChild(Node oldChild); // throws DOMException
  Node appendChild(Node newChild); // throws DOMException
  bool hasChildNodes();
  Node cloneNode(bool deep);
  bool hasAttributes();
  String lookupPrefix(String namespaceURI);
  String lookupNamespaceURI(String prefix);

  // unsupported features
  
  //String baseURI;
  
  //String textContent;
  
  //void normalize();
  //bool isSupported(String feature, String version);
  // DocumentPosition
  //const int DOCUMENT_POSITION_DISCONNECTED = 0x01;
  //const int DOCUMENT_POSITION_PRECEDING    = 0x02;
  //const int DOCUMENT_POSITION_FOLLOWING    = 0x04;
  //const int DOCUMENT_POSITION_CONTAINS     = 0x08;
  //const int DOCUMENT_POSITION_CONTAINED_BY = 0x10;
  //const int DOCUMENT_POSITION_IMPLEMENTATION_SPECIFIC = 0x20;

  //int compareDocumentPosition(Node other); // throws DOMException

  //bool isSameNode(Node other);
  //bool isDefaultNamespace(String namespaceURI);
  //bool isEqualNode(Node arg);
  //DOMObject getFeature(String feature, String version);
  //DOMUserData setUserData(String key, DOMUserData data, UserDataHandler handler);
  //DOMUserData getUserData(String key);
}