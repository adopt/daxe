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
 * Represents an element from an XML schema, which can contain sub-elements or point to sub-elements.
 */
abstract class WithSubElements {
  
  /**
   * Resolves the references to other schema elements for all the descendants of this schema element.
   */
  void resolveReferences(final WXSSchema schema, final WXSThing redefine);
  
  /**
   * Returns the list of the elements defined inside this model (including all the descendants, but without using element references).
   */
  List<WXSElement> allElements();
  
  /**
   * Returns the list of all the elements directly inside this model (including the ones using references).
   */
  List<WXSElement> subElements();
  
  /**
   * Returns a regular expression for this model, destined to be read by an end-user (but not usable for anything else).
   */
  String regularExpression();
  
  /**
   * Returns true if the element is a required child in this model.
   * Returns null if the given child is actually not a child of this element.
   */
  bool requiredChild(final WXSElement child);
  
  /**
   * Retuns true if the element passed in parameter can be found several times in this model because of a maxOccurs > 1.
   * Returns null if the given child is actually not a child of this element.
   */
  bool multipleChildren(final WXSElement child);
  
  /**
   * Returns the position in the list as far as validation is possible
   * ([start] if no validation is possible, [subElements].length if everything is validated).
   */
  int validate(final List<WXSElement> subElements, final int start, final bool insertion);
  
  /**
   * Retuns true if everything in this model is optionnal, for instance for a sequence containing only optionnal elements.
   */
  bool isOptionnal();
  
}
