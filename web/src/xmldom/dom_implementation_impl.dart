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

class DOMImplementationImpl implements DOMImplementation {
  
  DOMImplementationImpl();
  
  bool hasFeature(String feature, String version) {
    return(false);
  }
  
  DocumentType createDocumentType(String qualifiedName, String publicId, String systemId) { // throws DOMException
    return(new DocumentTypeImpl(qualifiedName, publicId, systemId));
  }
  
  Document createDocument(String namespaceURI, String qualifiedName, DocumentType doctype) { // throws DOMException
    return(new DocumentImpl(this, namespaceURI, qualifiedName, doctype));
  }
  
  Document createDocumentFromDH(h.Document doc) {
    return(new DocumentImpl.fromDH(this, doc));
  }
}
