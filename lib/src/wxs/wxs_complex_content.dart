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



class WXSComplexContent extends WXSAnnotated implements WithSubElements, Parent {
  
  // (restriction|extension)
  WithSubElements _model = null; // WXSRestriction | WXSExtension
  bool _mixed = null;
  
  WXSComplexType _parent;
  
  
  WXSComplexContent(final Element el, final WXSComplexType parent, final WXSSchema schema) {
    _parseAnnotation(el);
    for (Node n = el.firstChild; n != null; n=n.nextSibling) {
      if (n is Element) {
        if (n.localName == "restriction")
          _model = new WXSRestriction(n as Element, this, schema);
        else if (n.localName == "extension")
          _model = new WXSExtension(n as Element, this, schema);
      }
    }
    if (el.hasAttribute("mixed"))
      _mixed = (el.getAttribute("mixed") == "true" || el.getAttribute("mixed") == "1");
    
    this._parent = parent;
  }
  
  // from WithSubElements
  void resolveReferences(final WXSSchema schema, final WXSThing redefine) {
    if (_model != null)
      _model.resolveReferences(schema, redefine);
  }
  
  // from WithSubElements
  List<WXSElement> allElements() {
    if (_model != null)
      return(_model.allElements());
    return(new List<WXSElement>());
  }
  
  // from WithSubElements
  List<WXSElement> subElements() {
    if (_model != null)
      return(_model.subElements());
    return(new List<WXSElement>());
  }
  
  // from WithSubElements
  String regularExpression() {
    if (_model != null)
      return(_model.regularExpression());
    return(null);
  }
  
  // from WithSubElements
  bool requiredChild(final WXSElement child) {
    if (_model != null)
      return(_model.requiredChild(child));
    return(null);
  }
  
  // from WithSubElements
  bool multipleChildren(final WXSElement child) {
    if (_model != null)
      return(_model.multipleChildren(child));
    return(null);
  }
  
  List<WXSAttribute> attributes() {
    if (_model is WXSRestriction)
      return((_model as WXSRestriction).attributes());
    else if (_model is WXSExtension)
      return((_model as WXSExtension).attributes());
    return(new List<WXSAttribute>());
  }
  
  // from Parent
  List<WXSElement> parentElements() {
    return(_parent.parentElements());
  }
  
  // from WithSubElements
  int validate(final List<WXSElement> subElements, final int start, final bool insertion) {
    if (_model != null)
      return(_model.validate(subElements, start, insertion));
    return(start);
  }
  
  // from WithSubElements
  bool isOptionnal() {
    if (_model != null)
      return(_model.isOptionnal());
    return(true);
  }
}
