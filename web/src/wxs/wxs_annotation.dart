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

part of wxs;

class WXSAnnotation implements WXSThing {
  
  // (documentation*)
  List<WXSDocumentation> _documentations;
  
  
  WXSAnnotation(final Element el) {
    _documentations = new List<WXSDocumentation>();
    for (Node n = el.firstChild; n != null; n=n.nextSibling) {
      if (n is Element && n.localName == "documentation") {
        _documentations.add(new WXSDocumentation(n as Element));
        break;
      }
    }
  }
  
  String getDocumentation() {
    if (_documentations == null)
      return(null);
    StringBuffer sb = new StringBuffer();
    for (WXSDocumentation doc in _documentations) {
      if (doc.getValue() != null)
        sb.write(doc.getValue());
    }
    return(sb.toString());
  }
}
