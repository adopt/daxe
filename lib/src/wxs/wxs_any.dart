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


class WXSAny extends WXSAnnotated implements WithSubElements {
  
  String _namespace = "##any"; // ( (##any | ##other) | List of (anyURI | (##targetNamespace | ##local)) )
  String _processContents = "strict"; // (skip|lax|strict)
  int _minOccurs = 1;
  int _maxOccurs = 1;
  
  WXSExplicitGroup _parent;
  WXSSchema _schema;
  List<WXSElement> _elements;
  
  
  WXSAny(final Element el, final WXSExplicitGroup parent, final WXSSchema schema) {
    if (el.hasAttribute("namespace"))
      _namespace = el.getAttribute("namespace");
    if (el.hasAttribute("processContents"))
      _processContents = el.getAttribute("processContents");
    try {
      if (el.hasAttribute("minOccurs"))
        _minOccurs = int.parse(el.getAttribute("minOccurs"));
      if (el.hasAttribute("maxOccurs")) {
        if (el.getAttribute("maxOccurs") == "unbounded")
          _maxOccurs = 9007199254740992; // Integer.MAX_VALUE
        else
          _maxOccurs = int.parse(el.getAttribute("maxOccurs"));
      }
    } on FormatException {
    }
    
    this._parent = parent;
    this._schema = schema;
    _elements = null;
  }
  
  // from WithSubElements
  void resolveReferences(final WXSSchema schema, final WXSThing redefine) {
    // la résolution nécessite que le schéma soit déjà construit, on doit donc la faire plus tard
    _elements = new List<WXSElement>();
    _elements.addAll(schema.anies(_namespace));
    for (WXSElement element in _elements)
      element.addReference(this);
  }
  
  // from WithSubElements
  List<WXSElement> allElements() {
    return(new List<WXSElement>());
  }
  
  // from WithSubElements
  List<WXSElement> subElements() {
    if (_elements == null)
      resolveReferences(_schema, null);
    return(_elements);
  }
  
  List<WXSElement> parentElements() {
    return(_parent.parentElements());
  }
  
  // from WithSubElements
  String regularExpression() {
    if (_elements == null)
      resolveReferences(_schema, null);
    final StringBuffer sb = new StringBuffer();
    sb.write('(');
    for (int i=0; i<_elements.length; i++) {
      sb.write(_schema.elementTitle(_elements[i]));
      if (i != _elements.length - 1)
        sb.write('|');
    }
    sb.write(')');
    if (_minOccurs == 0 && _maxOccurs == 1)
      sb.write('?');
    else if (_minOccurs == 0 && _maxOccurs > 1)
      sb.write('*');
    else if (_minOccurs > 0 && _maxOccurs > 1)
      sb.write('+');
    return(sb.toString());
  }
  
  // from WithSubElements
  bool requiredChild(final WXSElement child) {
    if (_elements == null)
      resolveReferences(_schema, null);
    // renvoie null si l'enfant n'en est pas un
    if (_elements.contains(child))
      return(_minOccurs > 0 && _elements.length == 1);
    else
      return(null);
  }
  
  // from WithSubElements
  bool multipleChildren(final WXSElement child) {
    if (_elements == null)
      resolveReferences(_schema, null);
    // renvoie null si l'enfant n'en est pas un
    if (_elements.contains(child))
      return(_maxOccurs > 1);
    else
      return(null);
  }
  
  // from WithSubElements
  int validate(final List<WXSElement> subElements, final int start, final bool insertion) {
    if (_elements == null)
      resolveReferences(_schema, null);
    if (!insertion && subElements.length < _minOccurs)
      return(start);
    for (int i=start; i<subElements.length; i++) {
      if (i-start >= _maxOccurs)
        return(i);
      if (!_elements.contains(subElements[i])) {
        if (!insertion && i-start < _minOccurs)
          return(start);
        return(i);
      }
    }
    return(subElements.length);
  }
  
  // from WithSubElements
  bool isOptionnal() {
    return(_minOccurs == 0);
  }
}
