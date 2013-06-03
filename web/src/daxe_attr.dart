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

part of daxe;

/**
 * An attribute.
 */
class DaxeAttr {
  String namespaceURI;
  String prefix;
  String localName;
  String value;
  
  DaxeAttr.fromNode(x.Attr a) {
    namespaceURI = a.namespaceURI;
    prefix = a.prefix;
    if (a.prefix != null)
      localName = a.localName;
    else
      localName = a.name;
    value = a.nodeValue;
  }
  
  DaxeAttr(String name, String value) {
    namespaceURI = null;
    prefix = null;
    localName = name;
    this.value = value;
  }
  
  DaxeAttr.NS(String namespace, String qualifiedName, String value) {
    namespaceURI = namespace;
    int ind = qualifiedName.indexOf(':');
    if (ind == -1) {
      prefix = null;
      localName = qualifiedName;
    } else {
      prefix = qualifiedName.substring(0, ind);
      localName = qualifiedName.substring(ind + 1);
    }
    this.value = value;
  }
  
  DaxeAttr.clone(DaxeAttr attr) {
    namespaceURI = attr.namespaceURI;
    prefix = attr.prefix;
    localName = attr.localName;
    value = attr.value;
  }
  
  
  String get name {
    if (prefix == null)
      return(localName);
    else
      return("$prefix:$localName");
  }
  
  String toString() {
    StringBuffer sb = new StringBuffer();
    if (prefix != null) {
      sb.write(prefix);
      sb.write(':');
    }
    sb.write(localName);
    sb.write('="');
    sb.write(DaxeNode.escape(value));
    sb.write('"');
    return(sb.toString());
  }
}

