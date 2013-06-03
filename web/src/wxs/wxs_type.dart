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
 * Simple or complex type.
 */
abstract class WXSType {
  
  String getName();
  
  String getNamespace();
  
  Parent getParent();
  
  void resolveReferences(final WXSSchema schema, final WXSThing redefine);
  
  /**
   * Returns the list of possible values for this type if it is a simple type or a complex type with simple content.
   * Returns null if the list of possible values is infinite.
   */
  List<String> possibleValues();
  
  /**
   * Returns true if the value is valid for the simple type or the complex type with simple content.
   */
  bool validValue(final String value);
  
}
