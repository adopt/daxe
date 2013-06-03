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



class WXSFacet extends WXSAnnotated {
  
  String _facet; // (minExclusive|minInclusive|maxExclusive|maxInclusive|totalDigits|fractionDigits|length|minLength|maxLength|enumeration|pattern)
  // A FAIRE: ajouter whiteSpace (avant pattern)
  String _value = null;
  bool _fixed = false;
  
  int _iparam = 0;
  
  
  WXSFacet(final Element el) {
    _parseAnnotation(el);
    _facet = el.localName;
    if (el.hasAttribute("value")) {
      _value = el.getAttribute("value");
      _iparam = int.parse(_value, onError:(String source) => 0);
      if (_facet == "pattern") {
        // remplacements très approximatifs de \i, \I, \c et \C
        _value = _value.replaceAll("\\i", "[^<>&#!/?'\",0-9.\\-\\s]");
        _value = _value.replaceAll("\\I", "[^a-zA-Z]");
        _value = _value.replaceAll("\\c", "[^<>&#!/?'\",\\s]");
        _value = _value.replaceAll("\\C", "\\W");
      }
    }
    if (el.hasAttribute("fixed"))
      _fixed = el.getAttribute("fixed") == "true" || el.getAttribute("fixed") == "1";
  }
  
  String getFacet() {
    return(_facet);
  }
  
  String getValue() {
    return(_value);
  }
  
  bool validValue(final String value) {
    if (_facet == "minExclusive") {
      try {
        final double val = double.parse(value);
        return(val > _iparam);
      } on FormatException {
        return(false);
      }
    } else if (_facet == "minInclusive") {
      try {
        final double val = double.parse(value);
        return(val >= _iparam);
      } on FormatException {
        return(false);
      }
    } else if (_facet == "maxExclusive") {
      try {
        final double val = double.parse(value);
        return(val < _iparam);
      } on FormatException {
        return(false);
      }
    } else if (_facet == "maxInclusive") {
      try {
        final double val = double.parse(value);
        return(val <= _iparam);
      } on FormatException {
        return(false);
      }
    } else if (_facet == "totalDigits") {
      int nb = 0;
      for (int i=0; i<value.length; i++)
        if (value[i].compareTo('0') >= 0 && value[i].compareTo('9') <= 0)
          nb++;
      return(nb <= _iparam);
    } else if (_facet =="fractionDigits") {
      int nb = 0;
      bool apres = false;
      for (int i=0; i<value.length; i++) {
        if (!apres) {
          if (value[i] == '.')
            apres = true;
        } else if (value[i].compareTo('0') >= 0 && value[i].compareTo('9') <= 0)
          nb++;
      }
      return(nb <= _iparam);
    } else if (_facet == "length")
      return(value.length == _iparam);
    else if (_facet == "minLength")
      return(value.length >= _iparam);
    else if (_facet == "maxLength")
      return(value.length <= _iparam);
    else if (_facet == "enumeration") {
      return(_value != null && _value == value); // A FAIRE: enumeration basée sur des entiers, par ex. 02 valide pour 2
    } else if (_facet == "whiteSpace") {
      return(true);
      /*
      ?!?
      if ("collapse".equals(_value))
      return(!"replace".equals(valeur) && !"preserve".equals(valeur));
      else if ("replace".equals(_value))
      return(!"preserve".equals(valeur));
      else
      return(true);
       */
    } else if (_facet == "pattern") {
      return(WXSSimpleType._verifExpr(value, _value));
    } else
      return(true);
  }
}
