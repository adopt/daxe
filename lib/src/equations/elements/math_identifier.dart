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

part of equations;

/**
 * This class presents a mathematical idenifier, like "x"
 */
class MathIdentifier extends MathText {
  /** The XML element from this class */
  static final String ELEMENT = "mi";

  /** Attribute name of the mathvariant property */
  static final String ATTRIBUTE_MATHVARIANT = "mathvariant"; 

  String _mathvariant = "italic";
  
  
  /**
   * Sets the mathvariant attribute
   *
   * @param mathvariant mathvariant (normal | bold | italic | bold-italic)
   */
  void setMathvariant(final String mathvariant) {
    this._mathvariant = mathvariant;
  }
  
  @override
  void paint(final h.CanvasRenderingContext2D context, final double posX, final double posY) {
    final String s = getText();
    String f;
    if (_mathvariant == 'italic')
      f = getItalicFont();
    else if (_mathvariant == 'bold')
      f = getBoldFont();
    else if (_mathvariant == 'bold-italic')
      f = getBoldItalicFont();
    else
      f = getFont();
    context.font = f;
    context.fillText(s, posX, posY);
  }
  
  @override
  String getFont() {
    if (base != null)
      return base.getFont(fontsize, MathBase.STYLE_ITALIC);
    return null;
  }

}

