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


class WXSAll extends WXSAnnotated implements WithSubElements, Parent {
  
  List<WXSElement> _elements; // (element)*
  int _minOccurs = 1; // 0 | 1
  int _maxOccurs = 1; // 1
  
  Parent _parent; // WXSComplexType | WXSGroup | WXSRestriction | WXSExtension
  
  
  WXSAll(final Element el, final Parent parent, final WXSSchema schema) {
    _parseAnnotation(el);
    _elements = new List<WXSElement>();
    for (Node n = el.firstChild; n != null; n=n.nextSibling) {
      if (n is Element && n.localName == "element")
        _elements.add(new WXSElement(n as Element, this, schema));
    }
    try {
      if (el.hasAttribute("minOccurs"))
        _minOccurs = int.parse(el.getAttribute("minOccurs"));
    } on FormatException {
    }
    this._parent = parent;
  }
  
  // from WithSubElements
  void resolveReferences(final WXSSchema schema, final WXSThing redefine) {
    for (WXSElement element in _elements)
      element.resolveReferences(schema, redefine);
  }
  
  // from WithSubElements
  List<WXSElement> allElements() {
    final List<WXSElement> liste = new List<WXSElement>();
    for (WXSElement element in _elements)
      liste.addAll(element.allElements());
    return(liste);
  }
  
  // from WithSubElements
  List<WXSElement> subElements() {
    final List<WXSElement> liste = new List<WXSElement>();
    for (WXSElement element in _elements)
      liste.addAll(element.matchingElements());
    return(liste);
  }
  
  // from Parent
  List<WXSElement> parentElements() {
    if (_parent != null)
      return(_parent.parentElements());
    return(new List<WXSElement>());
  }
  
  // from WithSubElements
  String regularExpression() {
    final StringBuffer sb = new StringBuffer();
    sb.write('(');
    bool premier = true;
    for (WXSElement element in _elements) {
      final String er = element.regularExpression();
      if (er != null) {
        if (!premier)
          sb.write(" & ");
        premier = false;
        sb.write(er);
      }
    }
    sb.write(')');
    if (_minOccurs == 0)
      sb.write('?');
    return(sb.toString());
  }
  
  // from WithSubElements
  bool requiredChild(final WXSElement child) {
    // renvoie null si l'enfant n'en est pas un
    for (WXSElement element in _elements)
      for (WXSElement elc in element.matchingElements())
        if (elc == child)
          return(_minOccurs > 0 && element.getMinOccurs() > 0);
    return(null);
  }
  
  // from WithSubElements
  bool multipleChildren(final WXSElement child) {
    // renvoie null si l'enfant n'en est pas un
    for (WXSElement element in _elements)
      for (WXSElement elc in element.matchingElements())
        if (elc == child)
          return(false);
    return(null);
  }
  
  // from WithSubElements
  int validate(final List<WXSElement> subElements, final int start, final bool insertion) {
    if (_elements.length == 0)
      return(start);
    List<int> occurences = new List<int>(_elements.length);
    for (int i=0; i<_elements.length; i++)
      occurences[i] = 0;
    int nb = 0;
    for (int i=start; i<subElements.length; i++) {
      final WXSElement sousElement = subElements[i];
      bool trouve = false;
      for (int j=0; j<_elements.length; j++) {
        if (sousElement == _elements[j]) {
          trouve = true;
          occurences[j]++;
          break;
        }
      }
      if (!trouve)
        break;
      nb++;
    }
    for (int i=0; i<_elements.length; i++)
      if (occurences[i] > 1)
        return(start);
    if (!insertion) {
      for (int i=0; i<_elements.length; i++)
        if (occurences[i] == 0 && !_elements[i].isOptionnal())
          return(start);
    }
    return(start + nb);
  }
  
  // from WithSubElements
  bool isOptionnal() {
    if (_elements.length == 0)
      return(true);
    if (_minOccurs == 0)
      return(true);
    for (WXSElement element in _elements) {
      if (!element.isOptionnal())
        return(false);
    }
    return(true);
  }
}
