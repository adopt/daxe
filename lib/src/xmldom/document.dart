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

abstract class Document extends Node {
  DOMImplementation implementation;
  Element documentElement;
  String inputEncoding;
  String xmlEncoding;
  bool xmlStandalone;
  String xmlVersion;
  String documentURI;
  DocumentType doctype;
  
  Element createElement(String tagName); // throws DOMException
  DocumentFragment createDocumentFragment();
  Text createTextNode(String data);
  Comment createComment(String data);
  CDATASection createCDATASection(String data); // throws DOMException
  ProcessingInstruction createProcessingInstruction(String target, String data); // throws DOMException
  Attr createAttribute(String name); // throws DOMException
  EntityReference createEntityReference(String name); // throws DOMException
  List<Node> getElementsByTagName(String tagname);
  Node importNode(Node importedNode, bool deep); // throws DOMException
  Element createElementNS(String namespaceURI, String qualifiedName); // throws DOMException
  Attr createAttributeNS(String namespaceURI, String qualifiedName); // throws DOMException
  List<Node> getElementsByTagNameNS(String namespaceURI, String localName);
  Node adoptNode(Node source); // throws DOMException
  
  // unsupported features
  /*
  Element getElementById(String elementId);
  bool strictErrorChecking;
  DOMConfiguration domConfig;
  void normalizeDocument();
  Node renameNode(Node n, String namespaceURI, String qualifiedName); // throws DOMException
  */
}

