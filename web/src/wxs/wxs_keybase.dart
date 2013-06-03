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


abstract class WXSKeybase extends WXSAnnotated {
  
  // (selector, field+)
  WXSSelector _selector = null;
  List<WXSField> _fields;
  String _name = null;
  
  
  void _parse(final Element el) {
    _parseAnnotation(el);
    _fields = new List<WXSField>();
    for (Node n = el.firstChild; n != null; n=n.nextSibling) {
      if (n is Element) {
        if (n.localName == "selector")
          _selector = new WXSSelector(n as Element);
        else if (n.localName == "field")
          _fields.add(new WXSField(n as Element));
      }
    }
    if (el.hasAttribute("name"))
      _name = el.getAttribute("name");
  }
}
