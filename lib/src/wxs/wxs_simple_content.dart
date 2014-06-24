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



class WXSSimpleContent extends WXSAnnotated {
  
  // (restriction|extension)
  WXSRestriction _restriction = null;
  WXSExtension _extension = null;
  
  
  WXSSimpleContent(final Element el, final WXSSchema schema) {
    _parseAnnotation(el);
    for (Node n = el.firstChild; n != null; n=n.nextSibling) {
      if (n is Element) {
        if (n.localName == "restriction")
          _restriction = new WXSRestriction(n as Element, null, schema);
        else if (n.localName == "extension")
          _extension = new WXSExtension(n as Element, null, schema);
      }
    }
  }
  
  void resolveReferences(final WXSSchema schema, final WXSThing redefine) {
    if (_restriction != null)
      _restriction.resolveReferences(schema, redefine);
    else if (_extension != null)
      _extension.resolveReferences(schema, redefine);
  }
  
  List<String> possibleValues() {
    if (_restriction != null)
      return(_restriction.possibleValues());
    else if (_extension != null)
      return(_extension.possibleValues());
    return(null);
  }
  
  List<WXSAttribute> attributes() {
    if (_restriction != null)
      return(_restriction.attributes());
    else if (_extension != null)
      return(_extension.attributes());
    return(new List<WXSAttribute>());
  }
  
  bool validValue(final String value) {
    if (_restriction != null)
      return(_restriction.validValue(value));
    if (_extension != null)
      return(_extension.validValue(value));
    return(false);
  }
  
}
