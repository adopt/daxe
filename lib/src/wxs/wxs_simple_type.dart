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


class WXSSimpleType extends WXSAnnotated implements WXSType {
  
  // (restriction|list|union)
  WXSRestriction _restriction = null;
  WXSList _list = null;
  WXSUnion _union = null;
  String _name = null;
  
  Parent _parent; // WXSRedefine | WXSElement | WXSRestriction
  WXSSchema _schema;
  
  
  WXSSimpleType(final Element el, final Parent parent, final WXSSchema schema) {
    _parseAnnotation(el);
    for (Node n = el.firstChild; n != null; n=n.nextSibling) {
      if (n is Element) {
        if (n.localName == "restriction")
          _restriction = new WXSRestriction(n as Element, null, schema);
        else if (n.localName == "list")
          _list = new WXSList(n as Element, schema);
        else if (n.localName == "union")
          _union = new WXSUnion(n as Element, schema);
      }
    }
    if (el.hasAttribute("name"))
      _name = el.getAttribute("name");
    
    this._parent = parent;
    this._schema = schema;
  }
  
  // from WXSType
  String getName() {
    return(_name);
  }
  
  // from WXSType
  String getNamespace() {
    return(_schema.getTargetNamespace());
  }
  
  // from WXSType
  Parent getParent() {
    return(_parent);
  }
  
  // from WXSType
  void resolveReferences(final WXSSchema schema, final WXSThing redefine) {
    if (_restriction != null)
      _restriction.resolveReferences(schema, redefine);
    if (_list != null)
      _list.resolveReferences(schema, redefine);
    if (_union != null)
      _union.resolveReferences(schema, redefine);
  }
  
  // from WXSType
  List<String> possibleValues() {
    if (_restriction != null)
      return(_restriction.possibleValues());
    if (_union != null)
      return(_union.possibleValues());
    return(null);
  }
  
  // from WXSType
  List<String> suggestedValues() {
    if (_restriction != null)
      return(_restriction.suggestedValues());
    if (_union != null)
      return(_union.suggestedValues());
    return(null);
  }
  
  // from WXSType
  bool validValue(final String value) {
    if (_restriction != null)
      return(_restriction.validValue(value));
    if (_list != null)
      return(_list.validValue(value));
    if (_union != null)
      return(_union.validValue(value));
    return(false);
  }
  
  /**
   * Validation of a value by a simple type (the type must not have a prefix).
   */
  static bool validateTypeValue(final String type, final String value) {
    if (type == "string")
      return(true);
    else if (type == "normalizedString")
      return(_verifExpr(value, "[^\\t\\r\\n]*"));
    else if (type == "token") {
      if (value.indexOf('\n') != -1 || value.indexOf('\r') != -1 ||
          value.indexOf('\t') != -1 || value.indexOf("  ") != -1)
        return(false);
      return(!value.startsWith(" ") && !value.endsWith(" "));
    } else if (type == "base64Binary")
      return(_verifExpr(value, "(([a-zA-Z0-9+/=]\\s?){4})*"));
    else if (type == "hexBinary")
      return(_verifExpr(value, "(([0-9a-fA-F]){2})*"));
    else if (type == "integer")
      return(_verifExpr(value, "[+\\-]?\\d+"));
    else if (type == "positiveInteger")
      return(_verifExpr(value, "\\+?0*[1-9]\\d*"));
    else if (type == "negativeInteger")
      return(_verifExpr(value, "-0*[1-9]\\d*"));
    else if (type == "nonNegativeInteger")
      return(_verifExpr(value, "(-0+)|(\\+?\\d+)"));
    else if (type == "nonPositiveInteger")
      return(_verifExpr(value, "(\\+?0+)|(-\\d+)"));
    else if (type == "long") {
      if (!_verifExpr(value, "[+\\-]?\\d+"))
        return(false);
      try {
        final int big = int.parse(value);
        final int max = int.parse("9223372036854775807");
        final int min = int.parse("-9223372036854775808");
        if (big.compareTo(max) > 0)
          return(false);
        if (big.compareTo(min) < 0)
          return(false);
        return(true);
      } on FormatException catch(ex) {
        print("validerValeur(String, String) - FormatException $ex");
        return(false);
      }
    } else if (type == "unsignedLong") {
      if (!_verifExpr(value, "\\d+"))
        return(false);
      try {
        final int big = int.parse(value);
        final int max = int.parse("18446744073709551615");
        return(big.compareTo(max) <= 0);
      } on FormatException catch(ex) {
        print("validerValeur(String, String) - FormatException $ex");
        return(false);
      }
    } else if (type == "int") {
      if (!_verifExpr(value, "[+\\-]?\\d+"))
        return(false);
      String v2 = value;
      if (v2.startsWith("+"))
        v2 = v2.substring(1);
      try {
        final int val = int.parse(v2);
        return(val <= 2147483647 && val >= -2147483648);
      } on FormatException catch(ex) {
        print("validerValeur(String, String) - FormatException $ex");
        return(false);
      }
    } else if (type == "unsignedInt") {
      if (!_verifExpr(value, "\\d+"))
        return(false);
      try {
        final int val = int.parse(value);
        return(val <= 4294967295 && val >= 0);
      } on FormatException catch(ex) {
        print("validerValeur(String, String) - FormatException $ex");
        return(false);
      }
    } else if (type == "short") {
      if (!_verifExpr(value, "[+\\-]?\\d+"))
        return(false);
      String v2 = value;
      if (v2.startsWith("+"))
        v2 = v2.substring(1);
      try {
        final int val = int.parse(v2);
        return(val <= 32767 && val >= -32768);
      } on FormatException catch(ex) {
        print("validerValeur(String, String) - FormatException $ex");
        return(false);
      }
    } else if (type == "unsignedShort") {
      if (!_verifExpr(value, "\\d+"))
        return(false);
      try {
        final int val = int.parse(value);
        return(val <= 65535 && val >= 0);
      } on FormatException catch(ex) {
        print("validerValeur(String, String) - FormatException $ex");
        return(false);
      }
    } else if (type == "byte") {
      if (!_verifExpr(value, "[+\\-]?\\d+"))
        return(false);
      String v2 = value;
      if (v2.startsWith("+"))
        v2 = v2.substring(1);
      try {
        final int val = int.parse(v2);
        return(val <= 127 && val >= -128);
      } on FormatException catch(ex) {
        print("validerValeur(String, String) - FormatException $ex");
        return(false);
      }
    } else if (type == "unsignedByte") {
      if (!_verifExpr(value, "\\d+"))
        return(false);
      try {
        final int val = int.parse(value);
        return(val <= 255 && val >= 0);
      } on FormatException catch(ex) {
        print("validerValeur(String, String) - FormatException $ex");
        return(false);
      }
    } else if (type == "decimal") {
      return(_verifExpr(value, "[+\\-]?\\d+\\.?\\d*"));
    } else if (type == "float") {
      if (!_verifExpr(value, "(-?INF)|(NaN)|([+\\-]?\\d+\\.?\\d*([eE][+\\-]?\\d{1,3})?)"))
        return(false);
      if (value == "INF" || value == "-INF") // "Infinity" en Java
        return(true);
      try {
        double f = double.parse(value);
        if (log(f.abs())/LN2 > 127)
          return(false);
        if (log(f.abs())/LN2 < -126)
          return(false);
        return(true);
      } on FormatException {
        return(false);
      }
    } else if (type == "double") {
      if (!_verifExpr(value, "(-?INF)|(NaN)|([+\\-]?\\d+\\.?\\d*([eE][+\\-]?\\d{1,3})?)"))
        return(false);
      if (value == "INF" || value == "-INF")
        return(true);
      try {
        double.parse(value);
        return(true);
      } on FormatException {
        return(false);
      }
    } else if (type == "boolean")
      return(_verifExpr(value, "(true)|(false)|1|0"));
    else if (type == "duration")
      return(_verifExpr(value, "-?P(\\d{1,4}Y)?(\\d{1,2}M)?(\\d{1,2}D)?(T(\\d{1,2}H)?(\\d{1,2}M)?(\\d{1,2}(\\.\\d+)?S)?)?")); // en fait plus restrictif ("P" invalide par ex.)
    else if (type == "dateTime")
      return(_verifExpr(value, "-?\\d{4}-[01]\\d-[0-3]\\dT[0-2]\\d:[0-5]\\d:[0-5]\\d(\\.\\d+)?(([+\\-][01]\\d:\\d{2})|Z)?"));
    else if (type == "date")
      return(_verifExpr(value, "-?\\d{4}-[01]\\d-[0-3]\\d(([+\\-][01]\\d:\\d{2})|Z)?"));
    else if (type == "time")
      return(_verifExpr(value, "[0-2]\\d:[0-5]\\d:[0-5]\\d(\\.\\d+)?(([+\\-][01]\\d:\\d{2})|Z)?"));
    else if (type == "gYear")
      return(_verifExpr(value, "-?\\d{4}(([+\\-][01]\\d:\\d{2})|Z)?"));
    else if (type == "gYearMonth")
      return(_verifExpr(value, "-?\\d{4}-[01]\\d(([+\\-][01]\\d:\\d{2})|Z)?"));
    else if (type == "gMonth")
      return(_verifExpr(value, "--[01]\\d(([+\\-][01]\\d:\\d{2})|Z)?"));
    else if (type == "gMonthDay")
      return(_verifExpr(value, "--[01]\\d-[0-3]\\d(([+\\-][01]\\d:\\d{2})|Z)?"));
    else if (type == "gDay")
      return(_verifExpr(value, "---[0-3]\\d(([+\\-][01]\\d:\\d{2})|Z)?"));
    else if (type == "Name")
      return(_verifExpr(value, "[^<>&#!/?'\",0-9.\\-\\s][^<>&#!/?'\",\\s]*")); // en fait plus restrictif: \i\c*
    else if (type == "QName")
      return(_verifExpr(value, "[^<>&#!/?'\",0-9.\\-\\s][^<>&#!/?'\",\\s]*")); // en fait plus restrictif
    else if (type == "NCName")
      return(_verifExpr(value, "[^<>&#!/?'\",0-9.\\-\\s:][^<>&#!/?'\",:\\s]*")); // en fait plus restrictif: [\i-[:]][\c-[:]]*
    else if (type == "anyURI")
      return(true);
    //return(verifExpr(valeur, "([^:/?#]+:)?(//[^/?#]*)?[^?#]*(\\?[^#]*)?(#.*)?"));
    // pb: cette expression autorise tout!
    // (mais les RFC 2396 et 2732 ne restreignent rien)
    else if (type == "language")
      return(_verifExpr(value, "[a-zA-Z]{1,8}(-[a-zA-Z0-9]{1,8})*"));
    else if (type == "ID")
      return(_verifExpr(value, "[^<>&#!/?'\",0-9.\\-\\s:][^<>&#!/?'\",:\\s]*")); // comme NCName
    else if (type == "IDREF")
      return(_verifExpr(value, "[^<>&#!/?'\",0-9.\\-\\s:][^<>&#!/?'\",:\\s]*")); // comme NCName
    else if (type == "IDREFS")
      return(_verifExpr(value, "[^<>&#!/?'\",0-9.\\-\\s:][^<>&#!/?'\",:]*"));
    else if (type == "ENTITY")
      return(_verifExpr(value, "[^<>&#!/?'\",0-9.\\-\\s:][^<>&#!/?'\",:\\s]*")); // comme NCName
    else if (type == "ENTITIES")
      return(_verifExpr(value, "[^<>&#!/?'\",0-9.\\-\\s:][^<>&#!/?'\",:]*")); // comme IDREFS
    else if (type == "NOTATION")
      return(_verifExpr(value, "[^0-9.\\-\\s][^\\s]*(\\s[^0-9.\\-\\s][^\\s]*)*"));
    // la facette enumeration est obligatoire -> contrainte supplémentaire
    else if (type == "NMTOKEN")
      return(_verifExpr(value, "[^<>&#!/?'\",\\s]+")); // en fait plus restrictif: \c+
    else if (type == "NMTOKENS")
      return(_verifExpr(value, "[^<>&#!/?'\",]+")); // en fait plus restrictif
    else
      return(true);
  }
  
  static bool _verifExpr(final String value, final String regexp) {
    // un cache serait-il utile ici ? (attention aux fuites de mémoire si c'est static)
    final RegExp r = new RegExp("^${regexp}\$");
    return(r.hasMatch(value));
  }
  
}
