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
 * This math element presents a mathematical fraction
 */
class MathFrac extends MathElement {
  
  /** The XML element from this class */
  static final String ELEMENT = "mfrac";

  /** Attribute name of the linethickness property */
  static final String ATTRIBUTE_LINETHICKNESS = "linethickness"; 

  int _linethickness = 1;

  
  MathFrac() : super();
  
  
  /**
   * Sets the thickness of the fraction line
   *
   * @param linethickness Thickness
   */
  void setLineThickness(final int linethickness) {
    if (linethickness >= 0)
      this._linethickness = linethickness;
  }

  @override
  void paint(final h.CanvasRenderingContext2D context, final double posX, final double posY) {
    final MathElement e1 = getMathElement(0);
    final MathElement e2 = getMathElement(1);

    final double middle = posY - getMiddleShift();

    final double width = getWidth(true);

    e1.paint(context, posX + (width - e1.getWidth(true)) / 2,
        middle - e1.getDescentHeight(true) - 1);
    
    context.lineWidth = _linethickness;
    context.beginPath();
    double y = middle - _linethickness / 2;
    if (_linethickness == 1)
      y = y.floorToDouble() + 0.5;
    context.moveTo(posX + 1, y);
    context.lineTo(posX + width - 1, y);
    context.stroke();
    context.lineWidth = 1;

    e2.paint(context, posX + (width - e2.getWidth(true)) / 2,
        middle + e2.getAscentHeight(true) + 1);
  }

  @override
  double getWidth(final bool dynamicParts) {
    return max(getMathElement(0).getWidth(dynamicParts), getMathElement(1).getWidth(dynamicParts)) + 4;
  }

  @override
  double getHeight(final bool dynamicParts) {
    return getAscentHeight(true) + getDescentHeight(true);
  }

  @override
  double getAscentHeight(final bool dynamicParts) {
    return getMathElement(0).getHeight(true) + 1 + _linethickness / 2 + getMiddleShift();
  }

  @override
  double getDescentHeight(final bool dynamicParts) {
    return max(0, getMathElement(1).getHeight(true) + 1 + _linethickness / 2 - getMiddleShift());
  }
  
}

