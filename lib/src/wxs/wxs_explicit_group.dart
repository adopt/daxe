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


/**
 * WXSChoice and WXSSequence derive from this class.
 */
abstract class WXSExplicitGroup extends WXSAnnotated implements WithSubElements, Parent {
  
  List<WithSubElements> _nestedParticles; // (element, group, choice, sequence, any)*
  int _minOccurs = 1;
  int _maxOccurs = 1;
  
  Parent _parent; // WXSComplexType | WXSRestriction | WXSExtension | WXSGroup | WXSExplicitGroup
  
  
  void _parse(final Element el, final Parent parent, final WXSSchema schema) {
    _parseAnnotation(el);
    _nestedParticles = new List<WithSubElements>();
    for (Node n = el.firstChild; n != null; n=n.nextSibling) {
      if (n is Element) {
        if (n.localName == "element")
          _nestedParticles.add(new WXSElement(n as Element, this, schema));
        else if (n.localName == "group")
          _nestedParticles.add(new WXSGroup(n as Element, this, schema));
        else if (n.localName == "choice")
          _nestedParticles.add(new WXSChoice(n as Element, this, schema));
        else if (n.localName == "sequence")
          _nestedParticles.add(new WXSSequence(n as Element, this, schema));
        else if (n.localName == "any")
          _nestedParticles.add(new WXSAny(n as Element, this, schema));
      }
    }
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
    
    this._parent = parent;
  }
  
  // from WithSubElements
  void resolveReferences(final WXSSchema schema, final WXSThing redefine) {
    for (WithSubElements nestedParticle in _nestedParticles)
      if (!(nestedParticle is WXSAny))
        nestedParticle.resolveReferences(schema, redefine);
  }
  
  // from WithSubElements
  List<WXSElement> allElements() {
    final List<WXSElement> liste = new List<WXSElement>();
    for (WithSubElements nestedParticle in _nestedParticles)
      liste.addAll(nestedParticle.allElements());
    return(liste);
  }
  
  // from WithSubElements
  List<WXSElement> subElements() {
    final List<WXSElement> liste = new List<WXSElement>();
    for (WithSubElements nestedParticle in _nestedParticles) {
      if (nestedParticle is WXSElement)
        liste.addAll(nestedParticle.matchingElements());
      else
        liste.addAll(nestedParticle.subElements());
    }
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
    if (_nestedParticles.length == 0)
      return(null);
    final String separateur = (this is WXSChoice) ? "|" : ", ";
    StringBuffer sb = new StringBuffer();
    if (_nestedParticles.length > 1 || _minOccurs != 1 || _maxOccurs != 1)
      sb.write('(');
    bool premier = true;
    for (WithSubElements nestedParticle in _nestedParticles) {
      final String er = nestedParticle.regularExpression();
      if (er != null) {
        if (!premier)
          sb.write(separateur);
        premier = false;
        sb.write(er);
      }
    }
    if (_nestedParticles.length > 1 || _minOccurs != 1 || _maxOccurs != 1)
      sb.write(')');
    if (_nestedParticles.length == 1 && sb.length > 2) {
      String ssb = sb.toString();
      if (ssb.substring(0, 2) == "((" && ssb.substring(sb.length - 2, sb.length) == "))") {
        sb = new StringBuffer(ssb.substring(1, ssb.length - 1));
      }
    }
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
    for (WithSubElements nestedParticle in _nestedParticles) {
      if (nestedParticle is WXSElement) {
        for (WXSElement el in nestedParticle.matchingElements())
          if (el == child)
            return((this is WXSSequence || _nestedParticles.length == 1) &&
                _minOccurs != 0 &&
                nestedParticle.getMinOccurs() != 0);
      } else  {
        bool bb = nestedParticle.requiredChild(child);
        if (bb != null)
          return(bb);
      }
    }
    return(null);
  }
  
  // from WithSubElements
  bool multipleChildren(final WXSElement child) {
    for (WithSubElements nestedParticle in _nestedParticles) {
      if (nestedParticle is WXSElement) {
        for (WXSElement el in nestedParticle.matchingElements())
          if (el == child)
            return(nestedParticle.getMaxOccurs() > 1 || _maxOccurs > 1);
      } else  {
        bool bb = nestedParticle.multipleChildren(child);
        if (bb != null && !bb && _maxOccurs > 1)
          bb = true;
        if (bb != null)
          return(bb);
      }
    }
    return(null);
  }
  
}
