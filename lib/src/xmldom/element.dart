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

abstract class Element extends Node {
  String tagName;
  
  String getAttribute(String name);
  void setAttribute(String name, String value); // throws DOMException
  void removeAttribute(String name); // throws DOMException
  Attr getAttributeNode(String name);
  Attr setAttributeNode(Attr newAttr); // throws DOMException
  Attr removeAttributeNode(Attr oldAttr); // throws DOMException
  List<Node> getElementsByTagName(String name);
  String getAttributeNS(String namespaceURI, String localName); // throws DOMException
  void setAttributeNS(String namespaceURI, String qualifiedName, String value); // throws DOMException
  void removeAttributeNS(String namespaceURI, String localName); // throws DOMException
  Attr getAttributeNodeNS(String namespaceURI, String localName); // throws DOMException
  Attr setAttributeNodeNS(Attr newAttr); // throws DOMException
  List<Node> getElementsByTagNameNS(String namespaceURI, String localName); // throws DOMException
  bool hasAttribute(String name);
  bool hasAttributeNS(String namespaceURI, String localName); // throws DOMException
  
  /*
  TypeInfo schemaTypeInfo;
  void setIdAttribute(String name, bool isId); // throws DOMException
  void setIdAttributeNS(String namespaceURI, String localName, bool isId); // throws DOMException
  void setIdAttributeNode(Attr idAttr, bool isId); // throws DOMException
  */
}

