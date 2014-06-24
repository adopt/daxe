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



class WXSSchema implements WXSThing {
  
  List<WXSInclude> _includes;
  List<WXSImport> _imports;
  List<WXSRedefine> _redefines;
  LinkedHashMap<String, WXSSimpleType> _simpleTypes;
  LinkedHashMap<String, WXSComplexType> _complexTypes;
  LinkedHashMap<String, WXSGroup> _groups;
  LinkedHashMap<String, WXSAttributeGroup> _attributeGroups;
  LinkedHashMap<String, WXSElement> _elements;
  LinkedHashMap<String, WXSAttribute> _attributes;
  String _targetNamespace = null;
  String _attributeFormDefault = null;
  String _elementFormDefault = null;
  
  String _url;
  DaxeWXS _jwxs;
  List<WXSSchema> _includedSchemas;
  WXSSchema _parentSchema;
  HashMap<String, String> _namespaceToPrefix; // associations espace de noms -> préfixe
  
  
  WXSSchema(final Element el, final String url, final DaxeWXS jwxs, final WXSSchema schemaParent) {
    this._url = url;
    this._jwxs = jwxs;
    this._parentSchema = schemaParent;
    _includes = new List<WXSInclude>();
    _imports = new List<WXSImport>();
    _redefines = new List<WXSRedefine>();
    _simpleTypes = new LinkedHashMap<String, WXSSimpleType>();
    _complexTypes = new LinkedHashMap<String, WXSComplexType>();
    _groups = new LinkedHashMap<String, WXSGroup>();
    _attributeGroups = new LinkedHashMap<String, WXSAttributeGroup>();
    _elements = new LinkedHashMap<String, WXSElement>();
    _attributes = new LinkedHashMap<String, WXSAttribute>();
    _includedSchemas = new List<WXSSchema>();
    for (Node n = el.firstChild; n != null; n=n.nextSibling) {
      if (n is Element) {
        String localName = n.localName;
        if (localName == "include")
          _includes.add(new WXSInclude(n as Element, this));
        else if (localName == "import")
          _imports.add(new WXSImport(n as Element, this));
        else if (localName == "redefine") {
          final WXSRedefine redefine = new WXSRedefine(n as Element, this);
          _redefines.add(redefine);
          for (WXSThing redefinable in redefine.getRedefinables()) {
            if (redefinable is WXSSimpleType) {
              final WXSSimpleType simpleType = redefinable;
              _simpleTypes[simpleType.getName()] = simpleType;
            } else if (redefinable is WXSComplexType) {
              final WXSComplexType complexType = redefinable;
              _complexTypes[complexType.getName()] = complexType;
            } else if (redefinable is WXSGroup) {
              final WXSGroup group = redefinable;
              _groups[group.getName()] = group;
            } else if (redefinable is WXSAttributeGroup) {
              final WXSAttributeGroup attributeGroup = redefinable;
              _attributeGroups[attributeGroup.getName()] = attributeGroup;
            }
          }
        } else if (localName == "simpleType") {
          final WXSSimpleType simpleType = new WXSSimpleType(n as Element, null, this);
          _simpleTypes[simpleType.getName()] = simpleType;
        } else if (localName == "complexType") {
          final WXSComplexType complexType = new WXSComplexType(n as Element, null, this);
          _complexTypes[complexType.getName()] = complexType;
        } else if (localName == "group") {
          final WXSGroup group = new WXSGroup(n as Element, null, this);
          _groups[group.getName()] = group;
        } else if (localName == "attributeGroup") {
          final WXSAttributeGroup attributeGroup = new WXSAttributeGroup(n as Element, null, this);
          _attributeGroups[attributeGroup.getName()] = attributeGroup;
        } else if (localName == "element") {
          final WXSElement element = new WXSElement(n as Element, null, this);
          _elements[element.getName()] = element;
        } else if (localName == "attribute") {
          final WXSAttribute attribute = new WXSAttribute(n as Element, null, this);
          _attributes[attribute.getName()] = attribute;
        }
      }
    }
    if (el.hasAttribute("targetNamespace")) {
      _targetNamespace = el.getAttribute("targetNamespace");
      if (_targetNamespace == "")
        _targetNamespace = null;
    }
    if (el.hasAttribute("attributeFormDefault"))
      _attributeFormDefault = el.getAttribute("attributeFormDefault");
    if (el.hasAttribute("elementFormDefault"))
      _elementFormDefault = el.getAttribute("elementFormDefault");
    
    _namespaceToPrefix = new HashMap<String, String>();
    if (el.attributes != null) {
      for (Attr att in el.attributes.values) {
        if (att.name.startsWith("xmlns:")) {
          final String prefixe = att.name.substring(6);
          _namespaceToPrefix[att.value] = prefixe;
        }
      }
    }
  }
  
  Future _inclusions() { // can throw a WXSException
    List<Future> futures = new List<Future>();
    for (WXSInclude include in _includes)
      futures.add(include._inclusions(this));
    for (WXSImport imp in _imports)
      futures.add(imp._inclusions(this));
    for (WXSRedefine redefine in _redefines)
      futures.add(redefine._inclusions(this));
    return(Future.wait(futures));
  }
  
  Iterable<WXSElement> getTopElements() {
    return(_elements.values);
  }
  
  Iterable<WXSAttribute> getTopAttributes() {
    return(_attributes.values);
  }
  
  String getTargetNamespace() {
    return(_targetNamespace);
  }
  
  String getAttributeFormDefault() {
    return(_attributeFormDefault);
  }
  
  String getElementFormDefault() {
    return(_elementFormDefault);
  }
  
  String getURL() {
    return(_url);
  }
  
  Future<WXSSchema> newIncludedSchema(final String schemaLocation,
      final String importNamespace, final WXSSchema parentSchema) { // can throw a WXSException
    Completer completer = new Completer();
    _jwxs._newIncludedSchema(_url, schemaLocation, importNamespace, parentSchema).then((WXSSchema schemaInclu) {
      if (schemaInclu != null && !_includedSchemas.contains(schemaInclu))
        _includedSchemas.add(schemaInclu);
      completer.complete(schemaInclu);
    }, onError: (WXSException ex) {
      completer.completeError(ex);
    });
    return(completer.future);
  }
  
  void _resolveReferences() {
    for (WXSSimpleType simpleType in _simpleTypes.values)
      simpleType.resolveReferences(this, simpleType.getParent() is WXSRedefine ? simpleType : null);
    for (WXSComplexType complexType in _complexTypes.values)
      complexType.resolveReferences(this, complexType.getParent() is WXSRedefine ? complexType : null);
    for (WXSGroup group in _groups.values)
      group.resolveReferences(this, group.getParent() is WXSRedefine ? group : null);
    for (WXSAttributeGroup attributeGroup in _attributeGroups.values)
      attributeGroup.resolveReferences(this, attributeGroup.getParent() is WXSRedefine ? attributeGroup : null);
    for (WXSElement element in _elements.values)
      element.resolveReferences(this, null);
    for (WXSAttribute attribute in _attributes.values)
      attribute.resolveReferences(this);
  }
  
  String namespacePrefix(final String ns) {
    return(_namespaceToPrefix[ns]);
  }
  
  String prefixNamespace(final String prefixe) {
    if (prefixe == null)
      return(null);
    for (String espace in _namespaceToPrefix.keys) {
      if (prefixe == _namespaceToPrefix[espace])
        return(espace);
    }
    return(null);
  }
  
  List<WXSElement> allElements() {
    final List<WXSElement> liste = new List<WXSElement>();
    for (WXSComplexType complexType in _complexTypes.values)
      liste.addAll(complexType.allElements());
    for (WXSGroup group in _groups.values)
      liste.addAll(group.allElements());
    for (WXSElement element in _elements.values)
      liste.addAll(element.allElements());
    return(liste);
  }
  
  List<WXSElement> anies(final String namespace) {
    return(_jwxs._anies(namespace, _targetNamespace));
  }
  
  WXSElement resolveElementReference(final String localName, final String namespace) {
    return(_resolveReference(localName, namespace, null, null, 'WXSElement') as WXSElement);
  }
  
  WXSType resolveTypeReference(final String localName, final String namespace, final WXSThing redefine) {
    return(_resolveReference(localName, namespace, null, redefine, 'WXSType') as WXSType);
  }
  
  WXSGroup resolveGroupReference(final String localName, final String namespace, final WXSThing redefine) {
    return(_resolveReference(localName, namespace, null, redefine, 'WXSGroup') as WXSGroup);
  }
  
  WXSAttributeGroup resolveAttributeGroupReference(final String localName, final String namespace, final WXSThing redefine) {
    return(_resolveReference(localName, namespace, null, redefine, 'WXSAttributeGroup') as WXSAttributeGroup);
  }
  
  WXSAttribute resolveAttributeReference(final String localName, final String namespace) {
    return(_resolveReference(localName, namespace, null, null, 'WXSAttribute') as WXSAttribute);
  }
  
  WXSThing _resolveReference(final String localName, final String namespace, final HashSet<WXSSchema> exclure, final WXSThing redefine, final String classe) {
    if (localName == null)
      return(null);
    HashSet<WXSSchema> exclure2 = null;
    if (_parentSchema != null && (exclure == null || !exclure.contains(_parentSchema))) {
      if (exclure2 == null) {
        if (exclure == null)
          exclure2 = new HashSet<WXSSchema>();
        else
          exclure2 = exclure;
        exclure2.add(this);
      }
      final WXSThing thing = _parentSchema._resolveReference(localName, namespace, exclure2, redefine, classe);
      if (thing != null)
        return(thing);
    }
    if ((namespace == null && _targetNamespace == null) || (namespace != null && namespace == _targetNamespace)) {
      WXSThing thing;
      if (classe == 'WXSElement')
        thing = _elements[localName];
      else if (classe == 'WXSType') {
        thing = _complexTypes[localName];
        if (thing != null && thing != redefine)
          return(thing);
        thing = _simpleTypes[localName];
      } else if (classe == 'WXSGroup')
        thing = _groups[localName];
      else if (classe == 'WXSAttributeGroup')
        thing = _attributeGroups[localName];
      else if (classe == 'WXSAttribute')
        thing = _attributes[localName];
      else
        thing = null;
      if (thing != null && thing != redefine)
        return(thing);
    }
    for (WXSSchema schemaInclu in _includedSchemas) {
      if (exclure == null || !exclure.contains(schemaInclu)) {
        if (exclure2 == null) {
          if (exclure == null)
            exclure2 = new HashSet<WXSSchema>();
          else
            exclure2 = exclure;
          exclure2.add(this);
        }
        final WXSThing thing = schemaInclu._resolveReference(localName, namespace, exclure2, redefine, classe);
        if (thing  != null)
          return(thing);
      }
    }
    return(null);
  }
  
  String elementTitle(final WXSElement el) {
    return(_jwxs._elementTitle(el));
  }
  
}
