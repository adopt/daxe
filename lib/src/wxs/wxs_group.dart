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


class WXSGroup extends WXSAnnotated implements WithSubElements, Parent {

  // if not ref: (all|choice|sequence)
  WithSubElements _model = null; // (WXSAll | WXSChoice | WXSSequence)
  String _name = null;
  String _ref = null;
  WXSGroup _wxsRef = null;
  int _minOccurs = 1;
  int _maxOccurs = 1;

  Element _domElement;
  Parent _parent; // WXSComplexType | WXSRestriction | WXSExtension | WXSExplicitGroup | WXSRedefine
  WXSSchema _schema;
  List<WXSGroup> _references;


  WXSGroup(final Element el, final Parent parent, final WXSSchema schema) {
    _parseAnnotation(el);
    for (Node n = el.firstChild; n != null; n=n.nextSibling) {
      if (n is Element) {
        if (n.localName == "all")
          _model = new WXSAll(n, this, schema);
        else if (n.localName == "choice")
          _model = new WXSChoice(n, this, schema);
        else if (n.localName == "sequence")
          _model = new WXSSequence(n, this, schema);
      }
    }
    if (el.hasAttribute("name"))
      _name = el.getAttribute("name");
    if (el.hasAttribute("ref"))
      _ref = el.getAttribute("ref");
    try {
      if (el.hasAttribute("minOccurs"))
        _minOccurs = int.parse(el.getAttribute("minOccurs"));
      if (el.hasAttribute("maxOccurs")) {
        if (el.getAttribute("maxOccurs") == "unbounded")
          _maxOccurs = 9007199254740992;
        else
          _maxOccurs = int.parse(el.getAttribute("maxOccurs"));
      }
    } on FormatException {
    }

    _domElement = el;
    this._parent = parent;
    this._schema = schema;
    _references = null;
  }

  String getName() {
    if (_name == null && _wxsRef != null)
      return(_wxsRef.getName());
    return(_name);
  }

  String getNamespace() {
    return(_schema.getTargetNamespace());
  }

  Parent getParent() {
    return(_parent);
  }

  // from WithSubElements
  void resolveReferences(final WXSSchema schema, final WXSThing redefine) {
    if (_model != null)
      _model.resolveReferences(schema, redefine);
    if (_ref != null) {
      final String tns = _domElement.lookupNamespaceURI(DaxeWXS._namePrefix(_ref));
      _wxsRef = schema.resolveGroupReference(DaxeWXS._localValue(_ref), tns, redefine);
      if (_wxsRef != null)
        _wxsRef.addReference(this);
      else
        print("Group reference not found : $_ref");
    }
  }

  void addReference(final WXSGroup group) {
    if (_references == null)
      _references = new List<WXSGroup>();
    _references.add(group);
  }

  // from WithSubElements
  List<WXSElement> allElements() {
    if (_model != null)
      return(_model.allElements());
    return(new List<WXSElement>());
  }

  // from WithSubElements
  List<WXSElement> subElements() {
    if (_wxsRef != null)
      return(_wxsRef.subElements());
    if (_model != null)
      return(_model.subElements());
    return(new List<WXSElement>());
  }

  // from Parent
  List<WXSElement> parentElements() {
    final List<WXSElement> list = new List<WXSElement>();
    if (_parent != null)
      list.addAll(_parent.parentElements());
    if (_references != null) {
      for (WXSGroup groupe in _references)
        list.addAll(groupe.parentElements());
    }
    return(list);
  }

  // from WithSubElements
  String regularExpression() {
    String er;
    if (_wxsRef != null)
      er = _wxsRef.regularExpression();
    else if (_model != null)
      er = _model.regularExpression();
    else
      er = "()";
    if (_minOccurs == 0 && _maxOccurs == 1)
      return("$er?");
    else if (_minOccurs == 0 && _maxOccurs > 1)
      return("$er*");
    else if (_minOccurs > 0 && _maxOccurs > 1)
      return("$er+");
    else
      return(er);
  }

  // from WithSubElements
  bool requiredChild(final WXSElement child) {
    if (_wxsRef != null)
      return(_wxsRef.requiredChild(child));
    // returns null if child is not a child
    bool bb = null;
    if (_model != null)
      bb = _model.requiredChild(child);
    return(bb);
  }

  // from WithSubElements
  bool multipleChildren(final WXSElement child) {
    if (_wxsRef != null)
      return(_wxsRef.multipleChildren(child));
    // returns null if child is not a child
    bool bb = null;
    if (_model != null)
      bb = _model.multipleChildren(child);
    return(bb);
  }

  // from WithSubElements
  int validate(final List<WXSElement> subElements, final int start, final bool insertion) {
    if (!insertion && subElements.length < _minOccurs)
      return(start);
    int nb = 0;
    for (int i=start; i<subElements.length; ) {
      if (nb >= _maxOccurs)
        return(i);
      int pos = i;
      if (_wxsRef != null)
        pos = _wxsRef.validate(subElements, i, insertion);
      else if (_model != null)
        pos = _model.validate(subElements, i, insertion);
      if (pos == i)
        return(i);
      i = pos;
      nb++;
    }
    return(subElements.length);
  }

  // from WithSubElements
  bool isOptionnal() {
    if (_minOccurs == 0)
      return(true);
    if (_wxsRef != null)
      return(_wxsRef.isOptionnal());
    if (_model != null)
      return(_model.isOptionnal());
    return(true);
  }
}
