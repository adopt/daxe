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

library InterfaceSchema;

import 'xmldom/xmldom.dart';


/**
 * Interface for a schema language, such as the W3C one, Relax NG, or Jaxe's simple schemas.
 * This interface is using the notion of "element reference" which corresponds to the schema element
 * defining the XML element (this assumes that schemas are XML trees).
 */
abstract class InterfaceSchema {
  
  /**
   * Returns true if the reference comes from this schema
   */
  bool elementInSchema(final Element elementRef);
  
  /**
   * Returns the reference for the first schema element with the given name.
   */
  Element elementReferenceByName(final String name);
  
  /**
   * Returns the reference for the first schema element with the given name and namespace,
   * and with the parent whose reference is given.
   */
  Element elementReference(final Element el, final Element parentRef);
  
  /**
   * Returns the name of the element.
   */
  String elementName(final Element elementRef);
  
  /**
   * Returns the namespace of the element, or null if it is not defined.
   */
  String elementNamespace(final Element elementRef);
  
  /**
   * Returns the prefix to use to create a new element with the given reference,
   * or null if no prefix should be used.
   */
  String elementPrefix(final Element elementRef);
  
  /**
   * Returns the documentation for an element
   * (in a simple text format, with \n for line breaks).
   */
  String elementDocumentation(final Element elementRef);
  
  /**
   * Returns the list of possible values for an element.
   * Returns null if there are an infinite number of possible values,
   * or if the element does not have a simple type.
   */
  List<String> elementValues(final Element elementRef);
  
  /**
   * Returns a list of values to suggest to the user for an element.
   * This is only useful when there is an infinite number of possible values.
   * Returns null if there is no interesting value to suggest,
   * or if the element does not have a simple type.
   */
  List<String> suggestedElementValues(final Element elementRef);
  
  /**
   * Returns true if the given value is a valid value for the element.
   */
  bool elementValueIsValid(final Element elementRef, final String value);
  
  /**
   * Returns the list of namespaces used by this schema.
   */
  List<String> namespaceList();
  
  /**
   * Returns true if the namespace is defined in this schema.
   */
  bool hasNamespace(final String namespace);
  
  /**
   * Returns a prefix to use for the given namespace, or null if none is found.
   */
  String namespacePrefix(final String ns);
  
  /**
   * Returns the target namespace for the schema.
   * Warning: the concept of a unique target namespace does not exist with Relax NG.
   */
  String getTargetNamespace();
  
  /**
   * Returns the references of the elements which are not in the given namespace.
   */
  List<Element> elementsOutsideNamespace(final String namespace);
  
  /**
   * Returns the references of the elements which are in the given namespaces.
   */
  List<Element> elementsWithinNamespaces(final Set<String> namespaces);
  
  /**
   * Returns the references for all the schema elements.
   */
  List<Element> allElements();
  
  /**
   * Returns the references for all the possible root elements.
   */
  List<Element> rootElements();
  
  /**
   * Returns true if the child is required under the parent.
   */
  bool requiredElement(final Element parentRef, final Element childRef);
  
  /**
   * Returns true if the parent can have multiple children with the given child.
   */
  bool multipleChildren(final Element parentRef, final Element childRef);
  
  /**
   * Returns the references for the children of the given parent.
   */
  List<Element> subElements(final Element parentRef);
  
  /**
   * Regular expression for a given parent element
   * [modevisu]  True to get a regular expression to display to the user
   * [modevalid]  For strict validation instead of checking if an insert is possible
   */
  String regularExpression(final Element parentRef, final bool modevisu, final bool modevalid);
  
  /**
   * Returns the references for an element's possible parents.
   */
  List<Element> parentElements(final Element elementRef);
  
  /**
   * Returns the references for an element's possible attributes.
   */
  List<Element> elementAttributes(final Element elementRef);
  
  /**
   * Returns an attribute name.
   */
  String attributeName(final Element attributeRef);
  
  /**
   * Returns an attribute namespace, or null if none is defined.
   */
  String attributeNamespace(final Element attributeRef);
  
  /**
   * Returns an attribute documentation.
   */
  String attributeDocumentation(final Element attributeRef);
  
  /**
   * Returns an attribute namespace based on its full name.
   */
  String attributeNamespaceByName(final String attributeName);
  
  /**
   * Returns true if the attribute is required under the parent.
   */
  bool attributeIsRequired(final Element refParent, final Element attributeRef);
  
  /**
   * Returns the possible values for an attribute.
   * Returns null if there are an infinity of possible values.
   */
  List<String> attributeValues(final Element attributeRef);
  
  /**
   * Returns a list of values to suggest to the user for an attribute.
   * This is only useful when there is an infinite number of possible values.
   * Returns null if there is no interesting value to suggest.
   */
  List<String> suggestedAttributeValues(final Element attributeRef);
  
  /**
   * Returns an attribute default value.
   */
  String defaultAttributeValue(final Element attributeRef);
  
  /**
   * Returns true if the given value is valid for the attribute.
   */
  attributeIsValid(final Element attributeRef, final String value);
  
  /**
   * Returns the reference to the first possible parent element for a given attribute.
   */
  Element attributeParent(final Element attributeRef);
  
  /**
   * Returns true if the element can contain text.
   */
  bool canContainText(final Element elementRef);
  
}
