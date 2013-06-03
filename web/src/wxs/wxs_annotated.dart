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


abstract class WXSAnnotated implements WXSThing {
  
  WXSAnnotation _annotation = null;
  
  
  WXSAnnotation getAnnotation() {
    return(_annotation);
  }
  
  void _parseAnnotation(final Element el) {
    for (Node n = el.firstChild; n != null; n=n.nextSibling) {
      if (n is Element && n.localName == "annotation") {
        _annotation = new WXSAnnotation(n as Element);
        break;
      }
    }
  }
  
  String getDocumentation() {
    if (_annotation == null)
      return(null);
    return(_annotation.getDocumentation());
  }
}
