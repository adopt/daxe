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

library SimpleSchema;

import 'xmldom/xmldom.dart';
import 'interface_schema.dart';
import 'dart:collection';


/**
 * Class implementing InterfaceSchema for Jaxe's simple schemas.
 */
class SimpleSchema implements InterfaceSchema {
  HashMap<String, String> _hashTitles;
  Element _schemaRoot; // config file root element
  HashMap<String, Element> _elementDefCache; // cache for associations element name -> definition
  HashMap<Element, String> _elementNamesCache; // cache for associations definition -> element name
  
  SimpleSchema(Element schemaRoot, HashMap<String, String> hashElementTitles) {
    _schemaRoot = schemaRoot;
    _hashTitles = hashElementTitles;
    _buildElementDefCache();
  }
  
  bool elementInSchema(final Element elementRef) {
    Document domdoc = elementRef.ownerDocument;
    return(domdoc == _schemaRoot.ownerDocument);
  }
  
  Element elementReferenceByName(final String name) {
    return(_elementDefCache[name]);
  }
  
  Element elementReference(final Element el, final Element parentRef) {
    String name;
    if (el.prefix == null)
      name = el.nodeName;
    else
      name = el.localName;
    return(elementReferenceByName(name));
  }
  
  String elementName(final Element elementRef) {
    return(_elementNamesCache[elementRef]);
  }
  
  String elementNamespace(final Element elementRef) {
    return(null);
  }
  
  String elementPrefix(final Element elementRef) {
    return(null);
  }
  
  String elementDocumentation(final Element elementRef) {
    return(null);
  }
  
  List<String> elementValues(final Element elementRef) {
    return(null);
  }
  
  List<String> suggestedElementValues(final Element elementRef) {
    return(null);
  }
  
  bool elementValueIsValid(final Element elementRef, final String value) {
    return(true);
  }
  
  List<String> namespaceList() {
    return(null);
  }
  
  bool hasNamespace(final String namespace) {
    return(namespace == null);
  }
  
  String namespacePrefix(final String ns) {
    return(null);
  }
  
  String getTargetNamespace() {
    return(null);
  }
  
  List<Element> elementsOutsideNamespace(final String namespace) {
    if (namespace == null)
      return(new List<Element>());
    else
      return(allElements());
  }
  
  List<Element> elementsWithinNamespaces(final Set<String> namespaces) {
    return(new List<Element>());
  }
  
  List<Element> allElements() {
    return(new List.from(_elementNamesCache.keys));
  }
  
  List<Element> rootElements() {
    return(allElements());
  }
  
  bool requiredElement(final Element parentRef, final Element childRef) {
    return(false);
  }
  
  bool multipleChildren(final Element parentRef, final Element childRef) {
    return(true);
  }
  
  List<Element> subElements(final Element parentRef) {
    final List<Element> liste = new List<Element>();
    final List<Node> lsousel = parentRef.getElementsByTagName('SOUS-ELEMENT');
    for (int i=0; i<lsousel.length; i++) {
      final Element sousel = lsousel[i] as Element;
      liste.add(_elementDefCache[sousel.getAttribute('element')]);
    }
    final List<Node> lsousens = parentRef.getElementsByTagName('SOUS-ENSEMBLE');
    for (int i=0; i<lsousens.length; i++) {
      final Element sousens = lsousens[i] as Element;
      final String nomens = sousens.getAttribute('ensemble');
      final List<Node> lens = _schemaRoot.getElementsByTagName('ENSEMBLE');
      for (int j=0; j<lens.length; j++) {
        final Element ensemble = lens[j] as Element;
        if (nomens == ensemble.getAttribute('nom'))
          liste.addAll(subElements(ensemble));
      }
    }
    return(liste);
  }
  
  String regularExpression(final Element parentRef, final bool modevisu, final bool modevalid) {
    final List<Element> lsousb = subElements(parentRef);
    final StringBuffer expr = new StringBuffer();
    final int s = lsousb.length;
    for (int i=0; i < s; i++) {
      if (i != 0)
        expr.write('|');
      if (modevisu)
        expr.write(_elementTitle(lsousb[i]));
      else
        expr.write(elementName(lsousb[i]));
      if (!modevisu)
        expr.write(',');
    }
    if (s != 0) {
      //expr.insert(0, '(');
      String s = expr.toString();
      expr.clear();
      expr.write('(');
      expr.write(s);
      expr.write(')*');
    }
    return(expr.toString());
  }
  
  List<Element> parentElements(final Element elementRef) {
    final List<Element> liste = new List<Element>();
    if (elementRef.nodeName == 'ELEMENT') {
      final List<Node> lsousel = _schemaRoot.getElementsByTagName('SOUS-ELEMENT');
      for (int i=0; i<lsousel.length; i++) {
        final Element sousel = lsousel[i] as Element;
        if (sousel.getAttribute('element') == elementRef.getAttribute('nom')) {
          final Element parent = sousel.parentNode as Element;
          if (parent.nodeName == 'ELEMENT')
            liste.add(parent);
          else if (parent.nodeName == 'ENSEMBLE')
            liste.addAll(parentElements(parent));
        }
      }
    } else if (elementRef.nodeName == 'ENSEMBLE') {
      final String nomens = elementRef.getAttribute('nom');
      final List<Node> lsousens = _schemaRoot.getElementsByTagName('SOUS-ENSEMBLE');
      for (int i=0; i<lsousens.length; i++) {
        final Element sousens = lsousens[i] as Element;
        if (sousens.getAttribute('ensemble') == nomens) {
          final Element parent = sousens.parentNode as Element;
          if (parent.nodeName == 'ELEMENT')
            liste.add(parent);
          else if (parent.nodeName == 'ENSEMBLE')
            liste.addAll(parentElements(parent));
        }
      }
    }
    return(liste);
  }
  
  List<Element> elementAttributes(final Element elementRef) {
    final List<Node> latt = elementRef.getElementsByTagName('ATTRIBUT');
    final List<Element> l = new List<Element>();
    for (Node n in latt)
      l.add(n as Element);
    return(l);
  }
  
  String attributeName(final Element attributeRef) {
    return(attributeRef.getAttribute('nom'));
  }
  
  String attributeNamespace(final Element attributeRef) {
    return(null);
  }
  
  String attributeDocumentation(final Element attributeRef) {
    return(null);
  }
  
  String attributeNamespaceByName(final String attributeName) {
    return(null);
  }
  
  bool attributeIsRequired(final Element refParent, final Element attributeRef) {
    final String presence = attributeRef.getAttribute('presence');
    return(presence == 'obligatoire');
  }
  
  List<String> attributeValues(final Element attributeRef) {
    final List<Node> lval = attributeRef.getElementsByTagName('VALEUR');
    if (lval.length == 0)
      return(null);
    final List<String> liste = new List<String>();
    for (int i=0; i<lval.length; i++) {
      final Element val = lval[i] as Element;
      final String sval = val.firstChild.nodeValue.trim();
      liste.add(sval);
    }
    return(liste);
  }
  
  List<String> suggestedAttributeValues(final Element attributeRef) {
    return(null);
  }
  
  String defaultAttributeValue(final Element attributeRef) {
    return(null);
  }
  
  attributeIsValid(final Element attributeRef, final String value) {
    final String presence = attributeRef.getAttribute('presence');
    bool required = (presence == 'obligatoire');
    if ((value == null || value == '') && required)
      return(false);
    final List<String> valeurs = attributeValues(attributeRef);
    if (valeurs != null)
      return(valeurs.contains(value));
    return(true);
  }
  
  Element attributeParent(final Element attributeRef) {
    return(attributeRef.parentNode as Element);
  }
  
  bool canContainText(final Element elementRef) {
    final String texte  = elementRef.getAttribute('texte');
    return(texte == 'autorise');
  }
  
  
  /**
   * Builds a cache for element definitions and names
   */
  void _buildElementDefCache() {
    _elementDefCache = new HashMap<String, Element>();
    _elementNamesCache = new HashMap<Element, String>();
    final List<Node> lelements = _schemaRoot.getElementsByTagName('ELEMENT');
    for (int i=0; i<lelements.length; i++) {
      final Element el = lelements[i] as Element;
      final String nom = el.getAttribute('nom');
      _elementDefCache[nom] = el;
      _elementNamesCache[el] = nom;
    }
  }
  
  String _elementTitle(final Element elementRef) {
    String name = _elementNamesCache[elementRef];
    if (_hashTitles[name] != null)
      return(_hashTitles[name]);
    else
      return(name);
  }
}
